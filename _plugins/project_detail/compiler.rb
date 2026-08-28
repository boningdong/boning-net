# frozen_string_literal: true

require "kramdown"
require_relative "chapter_compiler"
require_relative "component_registry"
require_relative "directive_parser"
require_relative "render_context"

module BoningNet
  module ProjectDetail
    class Compiler
      NAVIGATION_VALUES = %w[auto none].freeze
      INTRO_STYLE_VALUES = %w[featured plain].freeze
      BLOCK_TYPE = /\A[A-Za-z][A-Za-z0-9-]*\z/

      Result = Struct.new(
        :content,
        :intro_markdown,
        :chapters,
        :navigation_enabled,
        :intro_style,
        :blocks,
        :intro_parts,
        keyword_init: true
      )

      def initialize(
        markdown:,
        config:,
        source_path:,
        kramdown_options:,
        frontmatter: {},
        registry: ComponentRegistry.new,
        source_line_offset: 0
      )
        @markdown = markdown
        @config = config.is_a?(Hash) ? config : {}
        @frontmatter = frontmatter || {}
        @source_path = source_path
        @source_line_offset = source_line_offset
        @kramdown_options = kramdown_options || {}
        @registry = registry
      end

      def call
        navigation = validated_option("navigation", NAVIGATION_VALUES, "auto")
        intro_style = validated_option("intro_style", INTRO_STYLE_VALUES, "featured")
        context = RenderContext.new(
          source_path: @source_path,
          frontmatter: @frontmatter,
          kramdown_options: @kramdown_options,
          source_line_offset: @source_line_offset
        )

        reject_author_html!(context)
        transformed_markdown, includes = compile_directives(context)
        chapter_result = ChapterCompiler.new(
          markdown: transformed_markdown,
          navigation: navigation,
          intro_style: intro_style,
          source_path: @source_path,
          kramdown_options: @kramdown_options
        ).call

        Result.new(
          content: replace_sentinels(chapter_result.content, includes),
          intro_markdown: replace_sentinels(chapter_result.intro_markdown, includes),
          chapters: chapter_result.chapters,
          navigation_enabled: chapter_result.navigation_enabled,
          intro_style: chapter_result.intro_style,
          blocks: context.blocks,
          intro_parts: intro_parts(chapter_result.intro_markdown, includes)
        )
      end

      private

      def validated_option(key, allowed, default)
        value = @config.fetch(key, default).to_s
        return value if allowed.include?(value)

        choices = allowed.map { |choice| %("#{choice}") }.join(" or ")
        raise ConfigurationError,
              "#{@source_path}: #{key} must be #{choices}; received #{value.inspect}"
      end

      def reject_author_html!(context)
        document = Kramdown::Document.new(@markdown, @kramdown_options)
        html = each_element(document.root).find { |element| element.type == :html_element }
        return unless html

        context.error!("raw HTML is not allowed in project detail content", line: html.options.fetch(:location))
      end

      def compile_directives(context)
        nodes = DirectiveParser.new(
          markdown: @markdown,
          source_path: @source_path,
          source_line_offset: @source_line_offset
        ).call
        headings = source_headings
        prefix = sentinel_prefix
        includes = {}

        replacements = nodes.map do |node|
          heading = heading_before(headings, node.start_line)
          context.use_heading(
            label: heading&.fetch(:label, nil),
            location: heading&.fetch(:location, nil)
          )
          component_class = @registry.fetch(
            node.name,
            source_path: @source_path,
            line: physical_line(node.start_line)
          )
          block = component_class.new.compile(node, context)
          validate_block!(block, context, node)
          id = context.store_block(block)
          sentinel = "#{prefix}_#{id.tr("-", "_").upcase}"
          includes[sentinel] = {
            "block_id" => id,
            "block_type" => block.fetch("type"),
            "include" => include_reference(block.fetch("type"), id)
          }
          [node, sentinel]
        end

        lines = @markdown.lines
        replacements.reverse_each do |node, sentinel|
          lines[(node.start_line - 1)..(node.end_line - 1)] = ["\n#{sentinel}\n\n"]
        end

        [lines.join, includes]
      end

      def validate_block!(block, context, node)
        type = block["type"] if block.is_a?(Hash)
        return if type.is_a?(String) && type.match?(BLOCK_TYPE)

        context.error!("component must compile to a block with a valid type", line: node.start_line)
      end

      def include_reference(type, id)
        %({% include pages/project-detail/blocks/#{type}.html block_id="#{id}" %})
      end

      def replace_sentinels(source, includes)
        return source if source.nil?

        includes.reduce(source) do |content, (sentinel, reference)|
          content.gsub(sentinel, reference.fetch("include"))
        end
      end

      def intro_parts(source, includes)
        return nil if source.nil?
        return [{ "kind" => "markdown", "markdown" => source }] if includes.empty?

        source.split(/(#{Regexp.union(includes.keys)})/).filter_map do |part|
          next if part.empty?

          reference = includes[part]
          if reference
            {
              "kind" => "block",
              "block_id" => reference.fetch("block_id"),
              "block_type" => reference.fetch("block_type")
            }
          else
            { "kind" => "markdown", "markdown" => part }
          end
        end
      end

      def sentinel_prefix
        prefix = "PROJECT_DETAIL_INTERNAL"
        prefix += "_" while @markdown.include?(prefix)
        prefix
      end

      def source_headings
        document = Kramdown::Document.new(@markdown, @kramdown_options)
        each_element(document.root).select do |element|
          element.type == :header && element.options.fetch(:level) <= 2
        end.map do |heading|
          {
            location: heading.options.fetch(:location),
            label: heading.options.fetch(:raw_text)
          }
        end
      end

      def heading_before(headings, line)
        headings.reverse_each.find { |heading| heading.fetch(:location) < line }
      end

      def each_element(root)
        [root, *root.children.flat_map { |child| each_element(child) }]
      end

      def physical_line(content_line)
        content_line + @source_line_offset
      end
    end
  end
end
