# frozen_string_literal: true

require "jekyll"
require_relative "project_detail/errors"
require_relative "project_detail/chapter_compiler"
require_relative "project_detail/directive_parser"
require_relative "project_detail/component_registry"
require_relative "project_detail/components/base"
require_relative "project_detail/components/narrative_title"
require_relative "project_detail/components/callout"
require_relative "project_detail/components/featured_link"
require_relative "project_detail/components/gallery"
require_relative "project_detail/components/videos"
require_relative "project_detail/components/people"
require_relative "project_detail/render_context"
require_relative "project_detail/compiler"

module BoningNet
  module ProjectDetail
    module_function

    def registry
      @registry ||= ComponentRegistry.new
        .register(Components::NarrativeTitle)
        .register(Components::Callout)
        .register(Components::FeaturedLink)
        .register(Components::Gallery)
        .register(Components::Videos)
        .register(Components::People)
    end

    def compile_document(document)
      config = document.data["project_detail"]
      if document.data.key?("project_detail") && !config.is_a?(Hash)
        raise ConfigurationError,
              "#{document.relative_path}: project_detail must be a mapping; received #{config.class}"
      end
      config ||= {}
      result = Compiler.new(
        markdown: document.content,
        config: config,
        frontmatter: document.data,
        source_path: document.relative_path,
        source_line_offset: source_line_offset(document),
        kramdown_options: document.site.config.fetch("kramdown", {}),
        registry: registry
      ).call

      document.data["project_detail_generated"] = {
        "intro_markdown" => result.intro_markdown,
        "chapters" => result.chapters,
        "navigation_enabled" => result.navigation_enabled,
        "intro_style" => result.intro_style,
        "blocks" => result.blocks,
        "intro_parts" => result.intro_parts
      }
      document.content = result.content
    end

    def source_line_offset(document)
      return 0 unless document.respond_to?(:path) && File.file?(document.path)

      lines = File.readlines(document.path)
      return 0 unless lines.first&.strip == "---"

      closing_index = lines.drop(1).index { |line| line.strip == "---" }
      closing_index ? closing_index + 2 : 0
    end
  end
end

Jekyll::Hooks.register :documents, :pre_render do |document|
  next unless document.data["layout"] == "project-detail"

  BoningNet::ProjectDetail.compile_document(document)
end
