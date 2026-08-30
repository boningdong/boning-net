# frozen_string_literal: true

require_relative "test_helper"
require_relative "../../_plugins/project_detail"

class DocumentationTest < TinyTestCase
  ROOT = File.expand_path("../..", __dir__)
  COMPONENTS_DIRECTORY = File.join(ROOT, "docs/project-detail/components")
  REQUIRED_COMPONENT_HEADINGS = [
    "Purpose",
    "Syntax",
    "Options",
    "Content Contract",
    "Behavior",
    "Generated Semantics",
    "Validation",
    "Examples",
    "Related Components"
  ].freeze

  def test_component_files_match_the_production_registry_plus_figure
    expected = (BoningNet::ProjectDetail.registry.types + ["figure"]).sort
    documented = Dir[File.join(COMPONENTS_DIRECTORY, "*.md")]
      .map { |path| File.basename(path, ".md") }
      .reject { |name| name == "README" }
      .sort

    assert_equal expected, documented
  end

  def test_component_index_links_every_public_component_and_only_those_components
    expected = (BoningNet::ProjectDetail.registry.types + ["figure"])
      .map { |type| "#{type}.md" }
      .sort
    index = read("docs/project-detail/components/README.md")
    linked = index.scan(/\]\(([^)]+\.md)\)/)
      .flatten
      .select { |target| !target.include?("/") }
      .sort

    assert_equal expected, linked
  end

  def test_every_component_document_has_the_required_sections
    component_paths.each do |path|
      headings = without_fenced_code(File.read(path)).scan(/^## (.+)$/).flatten

      assert_equal REQUIRED_COMPONENT_HEADINGS, headings
    end
  end

  def test_author_guide_documents_the_page_structure_and_html_boundary
    guide = read("docs/project-detail/README.md")

    ["Project Intro", "H1 Chapters", "Navigation", "Raw HTML Policy"].each do |heading|
      assert_includes guide, "## #{heading}"
    end
  end

  def test_permanent_guides_are_cross_linked_from_existing_documentation
    assert_includes read("docs/project-detail/README.md"), "](architecture.md)"
    assert_includes read("docs/project-detail/architecture.md"), "](README.md)"
    assert_includes read("docs/content-schema.md"), "](project-detail/README.md)"
    assert_includes read("docs/architecture/frontend.md"), "](../project-detail/architecture.md)"
    assert_includes read("docs/designs/08-26-2026/project-detail-architecture.md"),
                    "](../../project-detail/README.md)"
  end

  private

  def component_paths
    Dir[File.join(COMPONENTS_DIRECTORY, "*.md")]
      .reject { |path| File.basename(path) == "README.md" }
      .sort
  end

  def read(path)
    File.read(File.join(ROOT, path))
  end

  def without_fenced_code(markdown)
    fence = nil

    markdown.each_line.reject do |line|
      marker = line[/\A\s*(`{3,}|~{3,})/, 1]
      if fence
        fence = nil if marker&.start_with?(fence[0]) && marker.length >= fence.length
        true
      elsif marker
        fence = marker
        true
      else
        false
      end
    end.join
  end

end

TinyTestRunner.run(DocumentationTest)
