# frozen_string_literal: true

require "kramdown"
require "cgi"
require_relative "errors"

module BoningNet
  module ProjectDetail
    Result = Struct.new(
      :content,
      :intro_markdown,
      :chapters,
      :navigation_enabled,
      :corner_navigation_enabled,
      :intro_style,
      keyword_init: true
    )

    class ChapterCompiler
      EXPLICIT_ID = /\A[A-Za-z][A-Za-z0-9_-]*\z/

      def initialize(
        markdown:,
        navigation:,
        intro_style:,
        source_path:,
        kramdown_options:,
        source_line_offset: 0
      )
        @markdown = markdown
        @navigation = navigation
        @intro_style = intro_style
        @source_path = source_path
        @kramdown_options = kramdown_options || {}
        @source_line_offset = source_line_offset
      end

      def call
        document = Kramdown::Document.new(@markdown, @kramdown_options)
        source_headings = level_one_headings(document.root)

        return ordinary_result if source_headings.empty?

        explicit_headings = source_headings.filter_map do |heading|
          id = explicit_id_for(heading)
          [heading, id] if id
        end
        validate_explicit_ids!(explicit_headings)
        reject_duplicate_explicit_ids!(explicit_headings)

        toc_root, = Kramdown::Converter::Toc.convert(document.root, document.options)
        toc_nodes = flatten_toc(toc_root).select do |node|
          node.value.options[:level] == 1
        end
        headings = toc_nodes.map(&:value)
        chapters = toc_nodes.each_with_index.map do |node, index|
          {
            "index" => index + 1,
            "id" => node.attr.fetch(:id),
            "title" => node.value.options.fetch(:raw_text)
          }
        end

        first_heading_line = headings.first.options.fetch(:location)
        intro_source, main_source = split_source(first_heading_line)
        visible_intro = visible_markdown?(intro_source) ? intro_source : nil
        wrapped_main = wrap_chapters(main_source, chapters, headings, first_heading_line)
        output = @intro_style == "plain" && visible_intro ? intro_source + wrapped_main : wrapped_main

        Result.new(
          content: output,
          intro_markdown: visible_intro,
          chapters: chapters,
          navigation_enabled: @navigation == "auto" && chapters.any?,
          corner_navigation_enabled: @navigation == "auto" && chapters.length >= 2,
          intro_style: @intro_style
        )
      end

      private

      def ordinary_result
        Result.new(
          content: @markdown,
          intro_markdown: nil,
          chapters: [],
          navigation_enabled: false,
          corner_navigation_enabled: false,
          intro_style: @intro_style
        )
      end

      def flatten_toc(root)
        root.children.each_with_object([]) do |child, nodes|
          next unless child.type == :toc

          nodes << child
          nodes.concat(flatten_toc(child))
        end
      end

      def level_one_headings(root)
        root.children.each_with_object([]) do |child, headings|
          headings << child if child.type == :header && child.options[:level] == 1
          headings.concat(level_one_headings(child)) unless child.children.empty?
        end
      end

      def split_source(first_heading_line)
        lines = @markdown.lines
        [lines.first(first_heading_line - 1).join, lines.drop(first_heading_line - 1).join]
      end

      def visible_markdown?(source)
        fragment = Kramdown::Document.new(source, @kramdown_options)
        fragment.root.children.any? do |element|
          !%i[blank xml_comment].include?(element.type)
        end
      end

      def explicit_id_for(heading)
        ial = heading.options[:ial]
        return ial.fetch("id") if ial&.key?("id")

        source_line = @markdown.lines.fetch(heading.options.fetch(:location) - 1, "").chomp
        source_line[/\{#([^}]+)\}[ \t]*#*[ \t]*\z/, 1]
      end

      def validate_explicit_ids!(headings)
        headings.each do |heading, id|
          next if id.match?(EXPLICIT_ID)

          error!(
            "explicit chapter id must start with a letter and contain only letters, " \
            "numbers, underscores, and hyphens; received #{id.inspect}",
            heading.options.fetch(:location)
          )
        end
      end

      def reject_duplicate_explicit_ids!(headings)
        seen = {}
        headings.each do |heading, id|
          error!(%(duplicate chapter id "#{id}"), heading.options.fetch(:location)) if seen[id]
          seen[id] = true
        end
      end

      def wrap_chapters(main_source, chapters, headings, first_heading_line)
        lines = main_source.lines

        chapters.each_with_index.map do |chapter, index|
          start_line = headings[index].options.fetch(:location) - first_heading_line
          next_line = headings[index + 1]&.options&.fetch(:location)
          end_line = next_line ? next_line - first_heading_line : lines.length
          chapter_source = lines[start_line...end_line].join
          chapter_source += "\n" unless chapter_source.end_with?("\n")

          <<~MARKDOWN
            <section class="project-chapter" data-project-chapter="#{CGI.escapeHTML(chapter.fetch("id"))}" markdown="1">
            #{chapter_source}</section>
          MARKDOWN
        end.join
      end

      def error!(message, content_line)
        raise ConfigurationError,
              "#{@source_path}:#{content_line + @source_line_offset}: #{message}"
      end
    end
  end
end
