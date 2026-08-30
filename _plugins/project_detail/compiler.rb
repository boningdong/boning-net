# frozen_string_literal: true

require "kramdown"
require_relative "chapter_compiler"
require_relative "component_registry"
require_relative "components/standalone_figure"
require_relative "directive_parser"
require_relative "render_context"

module BoningNet
  module ProjectDetail
    class Compiler
      NAVIGATION_VALUES = %w[auto none].freeze
      INTRO_STYLE_VALUES = %w[featured plain].freeze
      CONFIGURATION_KEYS = %w[navigation intro_style].freeze
      BLOCK_TYPE = /\A[A-Za-z][A-Za-z0-9-]*\z/
      LIQUID_OPENING = /\{\{|\{%/
      FENCE_OPENING = /\A[ \t]*(`{3,}|~{3,})[^\n]*\z/
      FENCED_LIQUID_ESCAPES = {
        "{{" => '{{ "{{" }}',
        "{%" => '{{ "{%" }}'
      }.freeze

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
        @config = config.nil? ? {} : config
        @frontmatter = frontmatter || {}
        @source_path = source_path
        @source_line_offset = source_line_offset
        @kramdown_options = kramdown_options || {}
        @registry = registry
      end

      def call
        validate_configuration!
        navigation = validated_option("navigation", NAVIGATION_VALUES, "auto")
        intro_style = validated_option("intro_style", INTRO_STYLE_VALUES, "featured")
        context = RenderContext.new(
          source_path: @source_path,
          frontmatter: @frontmatter,
          kramdown_options: @kramdown_options,
          source_line_offset: @source_line_offset
        )

        reject_author_html!(context)
        reject_author_liquid!(context)
        @markdown = protect_fenced_liquid_examples(@markdown)
        transformed_markdown, includes = compile_blocks(context)
        chapter_result = ChapterCompiler.new(
          markdown: transformed_markdown,
          navigation: navigation,
          intro_style: intro_style,
          source_path: @source_path,
          kramdown_options: @kramdown_options,
          source_line_offset: @source_line_offset
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

      def validate_configuration!
        unless @config.is_a?(Hash)
          raise ConfigurationError,
                "#{@source_path}: project_detail must be a mapping; received #{@config.class}"
        end

        unknown = @config.keys - CONFIGURATION_KEYS
        return if unknown.empty?

        key = unknown.first
        raise ConfigurationError,
              "#{@source_path}: unknown project_detail key #{key.inspect}; " \
              "allowed keys are #{CONFIGURATION_KEYS.join(', ')}"
      end

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

      def reject_author_liquid!(context)
        fence = nil

        @markdown.each_line.with_index(1) do |line, line_number|
          text = line.chomp
          if fence
            fence = nil if closing_fence?(text, fence)
            next
          end

          if (opening = FENCE_OPENING.match(text))
            fence = opening[1]
            next
          end

          next unless LIQUID_OPENING.match?(line)

          context.error!("author-written Liquid is not allowed in project detail content", line: line_number)
        end
      end

      def protect_fenced_liquid_examples(markdown)
        fence = nil

        markdown.each_line.map do |line|
          text = line.chomp
          if fence
            protected_line = escape_liquid_openings(line)
            fence = nil if closing_fence?(text, fence)
            protected_line
          elsif (opening = FENCE_OPENING.match(text))
            fence = opening[1]
            escape_liquid_openings(line)
          else
            line
          end
        end.join
      end

      def escape_liquid_openings(line)
        line.gsub(LIQUID_OPENING, FENCED_LIQUID_ESCAPES)
      end

      def closing_fence?(text, fence)
        marker = Regexp.escape(fence[0])
        text.match?(Regexp.new("\\A[ \\t]*#{marker}{#{fence.length},}[ \\t]*\\z"))
      end

      def compile_blocks(context)
        line_offsets = source_line_offsets
        directive_nodes = DirectiveParser.new(
          markdown: @markdown,
          source_path: @source_path,
          source_line_offset: @source_line_offset
        ).call
        nodes = directive_nodes.map do |node|
          {
            start_line: node.start_line,
            end_line: node.end_line,
            source_start: line_offsets.fetch(node.start_line - 1),
            source_end: line_offsets.fetch(node.end_line, @markdown.length),
            directive: node
          }
        end
        nodes.concat(standalone_figure_nodes(directive_nodes, line_offsets))
        nodes.sort_by! { |node| node.fetch(:source_start) }

        headings = source_headings
        prefix = sentinel_prefix
        includes = {}

        replacements = nodes.map do |node|
          start_line = node.fetch(:start_line)
          heading = heading_before(headings, start_line)
          context.use_heading(
            label: heading&.fetch(:label, nil),
            location: heading&.fetch(:location, nil),
            level: heading&.fetch(:level, nil),
            first_visible: first_visible_after_heading?(heading, node)
          )
          block = compile_block(node, context)
          validate_block!(block, context, start_line)
          id = context.store_block(block)
          sentinel = "#{prefix}_#{id.tr("-", "_").upcase}"
          includes[sentinel] = {
            "block_id" => id,
            "block_type" => block.fetch("type"),
            "include" => include_reference(block.fetch("type"), id)
          }
          replacement = node.key?(:directive) ? "\n#{sentinel}\n\n" : sentinel
          [node.fetch(:source_start), node.fetch(:source_end), replacement]
        end

        transformed_markdown = @markdown.dup
        replacements.reverse_each do |source_start, source_end, replacement|
          transformed_markdown[source_start...source_end] = replacement
        end

        [transformed_markdown, includes]
      end

      def compile_block(node, context)
        paragraph = node[:figure]
        return Components::StandaloneFigure.new(paragraph: paragraph, context: context).compile if paragraph

        directive = node.fetch(:directive)
        component_class = @registry.fetch(
          directive.name,
          source_path: @source_path,
          line: physical_line(directive.start_line)
        )
        component_class.new.compile(directive, context)
      end

      def standalone_figure_nodes(directives, line_offsets)
        document = Kramdown::Document.new(@markdown, @kramdown_options)

        each_element(document.root).filter_map do |element|
          next unless Components::StandaloneFigure.match?(element)

          start_line = element.options.fetch(:location)
          next if within_directive?(start_line, directives)

          source_start, source_end = source_image_range(element, line_offsets)

          {
            start_line: start_line,
            source_start: source_start,
            source_end: source_end,
            figure: element
          }
        end
      end

      def source_image_range(element, line_offsets)
        start_line = element.options.fetch(:location)
        line_start = line_offsets.fetch(start_line - 1)
        line_end = line_offsets.fetch(start_line, @markdown.length)
        image_start = find_image_start(line_start, line_end)
        image_end = image_start && markdown_image_end(image_start)
        return [image_start, image_end] if image_end

        raise ConfigurationError,
              "#{@source_path}:#{physical_line(start_line)}: unable to locate standalone image source"
      end

      def find_image_start(line_start, line_end)
        offset = @markdown.index("![", line_start)
        while offset && offset < line_end
          return offset unless escaped_source_character?(offset)

          offset = @markdown.index("![", offset + 2)
        end
        nil
      end

      def markdown_image_end(image_start)
        alt_end = matching_delimiter(image_start + 1, "[", "]")
        return nil unless alt_end

        cursor = alt_end + 1
        reference_start = cursor
        reference_start += 1 while [" ", "\t"].include?(@markdown[reference_start])
        if @markdown[reference_start] == "["
          reference_end = matching_delimiter(reference_start, "[", "]")
          return reference_end && reference_end + 1
        end

        return cursor unless @markdown[cursor] == "("

        inline_end = matching_delimiter(cursor, "(", ")", recognize_title_quotes: true)
        inline_end && inline_end + 1
      end

      def matching_delimiter(open_offset, open_character, close_character, recognize_title_quotes: false)
        depth = 1
        offset = open_offset + 1
        quote = nil

        while offset < @markdown.length
          character = @markdown[offset]
          if character == "\\"
            offset += 2
            next
          end

          if quote
            quote = nil if character == quote
          elsif recognize_title_quotes && ["\"", "'"].include?(character) &&
                whitespace_character?(@markdown[offset - 1])
            quote = character
          elsif character == open_character
            depth += 1
          elsif character == close_character
            depth -= 1
            return offset if depth.zero?
          end
          offset += 1
        end
        nil
      end

      def escaped_source_character?(offset)
        backslashes = 0
        offset -= 1
        while offset >= 0 && @markdown[offset] == "\\"
          backslashes += 1
          offset -= 1
        end
        backslashes.odd?
      end

      def whitespace_character?(character)
        [" ", "\t", "\n", "\r"].include?(character)
      end

      def source_line_offsets
        @markdown.each_line.each_with_object([0]) do |line, offsets|
          offsets << offsets.last + line.length
        end
      end

      def within_directive?(line, directives)
        directives.any? { |node| line.between?(node.start_line, node.end_line) }
      end

      def validate_block!(block, context, line)
        type = block["type"] if block.is_a?(Hash)
        unless type.is_a?(String) && type.match?(BLOCK_TYPE)
          context.error!("component must compile to a block with a valid type", line: line)
        end
        return if json_like?(block)

        context.error!("component block data must be JSON-like", line: line)
      end

      def json_like?(value, ancestors = [])
        case value
        when Hash
          return false if ancestors.include?(value.object_id)

          next_ancestors = ancestors + [value.object_id]
          value.all? do |key, child|
            key.is_a?(String) && json_like?(child, next_ancestors)
          end
        when Array
          return false if ancestors.include?(value.object_id)

          next_ancestors = ancestors + [value.object_id]
          value.all? { |child| json_like?(child, next_ancestors) }
        when String, Integer, TrueClass, FalseClass, NilClass
          true
        when Float
          value.finite?
        else
          false
        end
      end

      def include_reference(type, id)
        %({% include pages/project-detail/blocks/#{type}.html block_id="#{id}" %})
      end

      def replace_sentinels(source, includes)
        return source if source.nil?

        source.gsub(sentinel_pattern(includes)) do |sentinel|
          includes.fetch(sentinel).fetch("include")
        end
      end

      def intro_parts(source, includes)
        return nil if source.nil?
        return [{ "kind" => "markdown", "markdown" => source }] if includes.empty?

        source.split(/(#{sentinel_pattern(includes)})/).filter_map do |part|
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

      def sentinel_pattern(includes)
        Regexp.union(includes.keys.sort_by { |sentinel| -sentinel.length })
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
            level: heading.options.fetch(:level),
            label: heading.options.fetch(:raw_text)
          }
        end
      end

      def first_visible_after_heading?(heading, node)
        return false unless heading

        lines = @markdown.lines
        source = lines[heading.fetch(:location)...(node.fetch(:start_line) - 1)].join
        document = Kramdown::Document.new(source, @kramdown_options)
        document.root.children.none? do |element|
          !%i[blank xml_comment].include?(element.type)
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
