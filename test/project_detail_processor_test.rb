# frozen_string_literal: true

require "jekyll"
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
end

TinyTestRunner.run(ProjectDetailProcessorTest)
