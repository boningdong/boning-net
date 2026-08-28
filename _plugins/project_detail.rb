# frozen_string_literal: true

require "jekyll"
require_relative "project_detail/errors"
require_relative "project_detail/chapter_compiler"
require_relative "project_detail/directive_parser"
require_relative "project_detail/component_registry"
require_relative "project_detail/components/base"

module BoningNet
  module ProjectDetail
    NAVIGATION_VALUES = %w[auto none].freeze
    INTRO_STYLE_VALUES = %w[featured plain].freeze

    class Compiler
      def initialize(markdown:, config:, source_path:, kramdown_options:)
        @markdown = markdown
        @config = config || {}
        @source_path = source_path
        @kramdown_options = kramdown_options || {}
      end

      def call
        navigation = validated_option("navigation", NAVIGATION_VALUES, "auto")
        intro_style = validated_option("intro_style", INTRO_STYLE_VALUES, "featured")
        ChapterCompiler.new(
          markdown: @markdown,
          navigation: navigation,
          intro_style: intro_style,
          source_path: @source_path,
          kramdown_options: @kramdown_options
        ).call
      end

      private

      def validated_option(key, allowed, default)
        value = @config.fetch(key, default).to_s
        return value if allowed.include?(value)

        choices = allowed.map { |choice| %("#{choice}") }.join(" or ")
        raise ConfigurationError,
              "#{@source_path}: #{key} must be #{choices}; received #{value.inspect}"
      end

    end

    module_function

    def compile_document(document)
      config = document.data["project_detail"]
      config = {} unless config.is_a?(Hash)
      result = Compiler.new(
        markdown: document.content,
        config: config,
        source_path: document.relative_path,
        kramdown_options: document.site.config.fetch("kramdown", {})
      ).call

      document.data["project_detail_generated"] = {
        "intro_markdown" => result.intro_markdown,
        "chapters" => result.chapters,
        "navigation_enabled" => result.navigation_enabled,
        "intro_style" => result.intro_style
      }
      document.content = result.content
    end
  end
end

Jekyll::Hooks.register :documents, :pre_render do |document|
  next unless document.data["layout"] == "project-detail"

  BoningNet::ProjectDetail.compile_document(document)
end
