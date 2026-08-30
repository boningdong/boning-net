# frozen_string_literal: true

require "jekyll"
require "tmpdir"
require_relative "project_detail/test_helper"
require_relative "../_plugins/project_detail"

class ProjectDetailProcessorTest < TinyTestCase
  def compile(markdown, config = {})
    BoningNet::ProjectDetail::Compiler.new(
      markdown: markdown,
      config: config,
      source_path: "_projects/example.md",
      kramdown_options: { "input" => "GFM" }
    ).call
  end

  def test_configured_navigation_and_intro_style_reach_the_chapter_compiler
    result = compile(
      "A short intro.\n\n# Context\nBody\n\n# Hardware\nBoard\n",
      "navigation" => "none",
      "intro_style" => "plain"
    )

    assert_equal 2, result.chapters.length
    refute result.navigation_enabled
    assert_includes result.content, 'data-project-chapter="context"'
    assert_includes result.content, "A short intro."
  end

  def test_invalid_values_name_the_source_and_allowed_values
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Context\nBody\n", "navigation" => "automatic")
    end

    assert_includes error.message, "_projects/example.md"
    assert_includes error.message, 'navigation must be "auto" or "none"'
  end

  def test_defaults_are_auto_and_featured
    result = compile("Intro.\n\n# Context\nBody\n\n# Team\nPeople\n")

    assert_equal "featured", result.intro_style
    assert result.navigation_enabled
  end

  def test_document_adapter_reports_physical_lines_after_frontmatter
    Dir.mktmpdir("project-detail-source") do |directory|
      path = File.join(directory, "example.md")
      File.write(path, <<~MARKDOWN)
        ---
        layout: project-detail
        title: Example
        ---
        # Context
        <div>Author HTML</div>
      MARKDOWN
      site = Struct.new(:config).new({ "kramdown" => { "input" => "GFM" } })
      document = Struct.new(:data, :content, :relative_path, :path, :site).new(
        { "layout" => "project-detail", "title" => "Example" },
        "# Context\n<div>Author HTML</div>\n",
        "_projects/example.md",
        path,
        site
      )

      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        BoningNet::ProjectDetail.compile_document(document)
      end

      assert_includes error.message, "_projects/example.md:6"
    end
  end

  def test_document_adapter_rejects_present_non_mapping_configuration
    ["auto", ["auto"], nil].each do |config|
      document = project_document("project_detail" => config)

      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        BoningNet::ProjectDetail.compile_document(document)
      end

      assert_includes error.message, "_projects/example.md"
      assert_includes error.message, "project_detail must be a mapping"
    end
  end

  def test_document_adapter_rejects_unknown_configuration_keys
    document = project_document(
      "project_detail" => { "navigation" => "auto", "navigaton" => "none" }
    )

    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      BoningNet::ProjectDetail.compile_document(document)
    end

    assert_includes error.message, "_projects/example.md"
    assert_includes error.message, 'unknown project_detail key "navigaton"'
  end

  def test_document_adapter_accepts_absent_and_valid_configuration
    default_document = project_document
    BoningNet::ProjectDetail.compile_document(default_document)
    default_generated = default_document.data.fetch("project_detail_generated")
    assert_equal "featured", default_generated.fetch("intro_style")
    assert default_generated.fetch("navigation_enabled")

    configured_document = project_document(
      "project_detail" => { "navigation" => "none", "intro_style" => "plain" }
    )
    BoningNet::ProjectDetail.compile_document(configured_document)
    configured_generated = configured_document.data.fetch("project_detail_generated")
    assert_equal "plain", configured_generated.fetch("intro_style")
    refute configured_generated.fetch("navigation_enabled")
  end

  private

  def project_document(extra_data = {})
    site = Struct.new(:config).new({ "kramdown" => { "input" => "GFM" } })
    data = {
      "layout" => "project-detail",
      "title" => "Example"
    }.merge(extra_data)
    Struct.new(:data, :content, :relative_path, :site).new(
      data,
      "Intro.\n\n# Context\nBody.\n\n# Team\nPeople.\n",
      "_projects/example.md",
      site
    )
  end
end

TinyTestRunner.run(ProjectDetailProcessorTest)
