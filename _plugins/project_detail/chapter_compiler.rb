# frozen_string_literal: true

require "kramdown"
require_relative "errors"

module BoningNet
  module ProjectDetail
    Result = Struct.new(
      :content,
      :intro_markdown,
      :chapters,
      :navigation_enabled,
      :intro_style,
      keyword_init: true
    )

    class ChapterCompiler
      def initialize(markdown:, navigation:, intro_style:, source_path:, kramdown_options:)
        @markdown = markdown
        @navigation = navigation
        @intro_style = intro_style
        @source_path = source_path
        @kramdown_options = kramdown_options || {}
      end

      def call
        document = Kramdown::Document.new(@markdown, @kramdown_options)
        source_headings = level_one_headings(document.root)

        return ordinary_result if source_headings.empty?

        explicit_ids = source_headings.each_with_object({}) do |heading, ids|
          ids[heading.object_id] = heading.attr["id"] if heading.attr.key?("id")
        end

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

        reject_duplicate_explicit_ids!(headings, explicit_ids)
        first_heading_line = headings.first.options.fetch(:location)
        intro_source, main_source = split_source(first_heading_line)
        visible_intro = visible_markdown?(intro_source) ? intro_source : nil
        wrapped_main = wrap_chapters(main_source, chapters, headings, first_heading_line)
        output = @intro_style == "plain" && visible_intro ? intro_source + wrapped_main : wrapped_main

        Result.new(
          content: output,
          intro_markdown: visible_intro,
          chapters: chapters,
          navigation_enabled: @navigation == "auto" && chapters.length >= 2,
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

      def reject_duplicate_explicit_ids!(headings, explicit_ids)
        ids = headings.filter_map { |heading| explicit_ids[heading.object_id] }
        duplicate = ids.tally.find { |_id, count| count > 1 }&.first
        return unless duplicate

        raise ConfigurationError, %(#{@source_path}: duplicate chapter id "#{duplicate}")
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
            <section class="project-chapter" data-project-chapter="#{chapter.fetch("id")}" markdown="1">
            #{chapter_source}</section>
          MARKDOWN
        end.join
      end
    end
  end
end
