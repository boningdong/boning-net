# frozen_string_literal: true

require "jekyll"
require_relative "project_detail/errors"
require_relative "project_detail/chapter_compiler"
require_relative "project_detail/directive_parser"
require_relative "project_detail/component_registry"
require_relative "project_detail/components/base"
require_relative "project_detail/render_context"
require_relative "project_detail/compiler"

module BoningNet
  module ProjectDetail
    module_function

    def registry
      @registry ||= ComponentRegistry.new
    end

    def compile_document(document)
      config = document.data["project_detail"]
      config = {} unless config.is_a?(Hash)
      result = Compiler.new(
        markdown: document.content,
        config: config,
        frontmatter: document.data,
        source_path: document.relative_path,
        kramdown_options: document.site.config.fetch("kramdown", {}),
        registry: registry
      ).call

      document.data["project_detail_generated"] = {
        "intro_markdown" => result.intro_markdown,
        "chapters" => result.chapters,
        "navigation_enabled" => result.navigation_enabled,
        "intro_style" => result.intro_style,
        "blocks" => result.blocks
      }
      document.content = result.content
    end
  end
end

Jekyll::Hooks.register :documents, :pre_render do |document|
  next unless document.data["layout"] == "project-detail"

  BoningNet::ProjectDetail.compile_document(document)
end
