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
        keyword_init: true
      )

      def initialize(
        markdown:,
        config:,
        source_path:,
        kramdown_options:,
        frontmatter: {},
        registry: ComponentRegistry.new
      )
        @markdown = markdown
        @config = config.is_a?(Hash) ? config : {}
        @frontmatter = frontmatter || {}
        @source_path = source_path
        @kramdown_options = kramdown_options || {}
        @registry = registry
      end

      def call
        navigation = validated_option("navigation", NAVIGATION_VALUES, "auto")
        intro_style = validated_option("intro_style", INTRO_STYLE_VALUES, "featured")
        context = RenderContext.new(
          source_path: @source_path,
          frontmatter: @frontmatter,
          kramdown_options: @kramdown_options
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
          blocks: context.blocks
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
        nodes = DirectiveParser.new(markdown: @markdown, source_path: @source_path).call
        headings = source_headings
        prefix = sentinel_prefix
        includes = {}

        replacements = nodes.map do |node|
          context.current_heading_label = heading_label_before(headings, node.start_line)
          component_class = @registry.fetch(
            node.name,
            source_path: @source_path,
            line: node.start_line
          )
          block = component_class.new.compile(node, context)
          validate_block!(block, context, node)
          id = context.store_block(block)
          sentinel = "#{prefix}_#{id.tr("-", "_").upcase}"
          includes[sentinel] = include_reference(block.fetch("type"), id)
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

        includes.reduce(source) do |content, (sentinel, include_reference)|
          content.gsub(sentinel, include_reference)
        end
      end

      def sentinel_prefix
        prefix = "PROJECT_DETAIL_INTERNAL"
        prefix += "_" while @markdown.include?(prefix)
        prefix
      end

      def source_headings
        document = Kramdown::Document.new(@markdown, @kramdown_options)
        each_element(document.root).select { |element| element.type == :header }.map do |heading|
          [heading.options.fetch(:location), heading.options.fetch(:raw_text)]
        end
      end

      def heading_label_before(headings, line)
        headings.reverse_each do |heading_line, label|
          return label if heading_line < line
        end
        nil
      end

      def each_element(root)
        [root, *root.children.flat_map { |child| each_element(child) }]
      end
    end
  end
end
