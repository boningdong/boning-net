# frozen_string_literal: true

require_relative "test_helper"
require_relative "../../_plugins/project_detail"

class ChapterCompilerTest < TinyTestCase
  def compile(markdown, navigation: "auto", intro_style: "featured")
    BoningNet::ProjectDetail::ChapterCompiler.new(
      markdown: markdown,
      navigation: navigation,
      intro_style: intro_style,
      source_path: "_projects/example.md",
      kramdown_options: { "input" => "GFM" }
    ).call
  end

  def test_extracts_intro_and_wraps_each_chapter
    result = compile("A short intro.\n\n# Context\nBody\n\n# Hardware\nBoard\n")

    assert_equal "A short intro.", result.intro_markdown.strip
    assert_equal ["Context", "Hardware"], result.chapters.map { |chapter| chapter.fetch("title") }
    assert_equal ["context", "hardware"], result.chapters.map { |chapter| chapter.fetch("id") }
    assert_includes result.content, 'data-project-chapter="context"'
    assert_includes result.content, 'data-project-chapter="hardware"'
    refute_includes result.content, "A short intro."
  end

  def test_keeps_visible_intro_in_plain_content
    result = compile("A short intro.\n\n# Context\nBody\n", intro_style: "plain")

    assert_equal "A short intro.", result.intro_markdown.strip
    assert_includes result.content, "A short intro."
  end

  def test_ignores_comment_only_preface
    result = compile("<!-- editorial note -->\n\n# Context\nBody\n")

    assert_nil result.intro_markdown
  end

  def test_leaves_content_without_level_one_headings_ordinary
    markdown = "Paragraph.\n\n## Detail\nNested.\n"
    result = compile(markdown)

    assert_nil result.intro_markdown
    assert_empty result.chapters
    assert_equal markdown, result.content
    refute result.navigation_enabled
  end

  def test_preserves_explicit_ids_and_generates_missing_ids
    result = compile("# Industrial Design {#industrial-design}\nBody\n\n# Team\nPeople\n")

    assert_equal ["industrial-design", "team"], result.chapters.map { |chapter| chapter.fetch("id") }
  end

  def test_rejects_duplicate_explicit_ids
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Context {#same}\nBody\n\n# Hardware {#same}\nBoard\n")
    end

    assert_includes error.message, 'duplicate chapter id "same"'
  end

  def test_suffixes_repeated_generated_titles
    result = compile("# Test\nOne\n\n# Test\nTwo\n")

    assert_equal ["test", "test-1"], result.chapters.map { |chapter| chapter.fetch("id") }
  end

  def test_excludes_level_two_headings_from_chapters
    result = compile("# Context\nBody\n\n## Detail\nNested\n\n# Hardware\nBoard\n")

    assert_equal ["Context", "Hardware"], result.chapters.map { |chapter| chapter.fetch("title") }
  end

  def test_uses_toc_order_for_level_one_headings_after_a_list
    result = compile(<<~MARKDOWN)
      # Context
      - We can rewrite the front-end software in JavaScript using React and Electron framework to improve the design and make it portable to different platforms.
      - Current the sampling accuracy is not high and the resolution is not high enough (8 bit). We probably can tweak the parameters to sacrifice a portion of the speed to improve the accuracy, probably by enabling oversampling or simply increasing the sampling period.
      - The touch sensor works from a prove-of-concept perspective but not good enough; it's not sensitive enough to respond to the user input.
      # Team
      People
    MARKDOWN

    assert_equal ["Context", "Team"], result.chapters.map { |chapter| chapter.fetch("title") }
  end

  def test_disables_navigation_for_zero_chapters
    result = compile("Paragraph only.\n")

    refute result.navigation_enabled
  end

  def test_disables_navigation_for_one_chapter
    result = compile("# Context\nBody\n")

    refute result.navigation_enabled
  end

  def test_enables_navigation_for_multiple_chapters
    result = compile("# Context\nBody\n\n# Hardware\nBoard\n")

    assert result.navigation_enabled
  end
end

TinyTestRunner.run(ChapterCompilerTest)
