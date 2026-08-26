# frozen_string_literal: true

require "jekyll"
require_relative "../_plugins/project_detail"

class AssertionFailure < StandardError; end

class TinyTestCase
  def assert(condition, message = "expected condition to be truthy")
    raise AssertionFailure, message unless condition
  end

  def refute(condition, message = "expected condition to be falsey")
    assert(!condition, message)
  end

  def assert_equal(expected, actual)
    assert(expected == actual, "expected #{expected.inspect}, got #{actual.inspect}")
  end

  def assert_nil(actual)
    assert(actual.nil?, "expected nil, got #{actual.inspect}")
  end

  def assert_empty(actual)
    assert(actual.empty?, "expected #{actual.inspect} to be empty")
  end

  def assert_includes(actual, expected)
    assert(actual.include?(expected), "expected #{actual.inspect} to include #{expected.inspect}")
  end

  def refute_includes(actual, expected)
    refute(actual.include?(expected), "expected #{actual.inspect} not to include #{expected.inspect}")
  end

  def assert_raises(error_class)
    yield
    raise AssertionFailure, "expected #{error_class} to be raised"
  rescue error_class => error
    error
  end
end

class ProjectDetailProcessorTest < TinyTestCase
  def compile(markdown, config = {})
    BoningNet::ProjectDetail::Compiler.new(
      markdown: markdown,
      config: config,
      source_path: "_projects/example.md",
      kramdown_options: { "input" => "GFM" }
    ).call
  end

  def test_featured_intro_and_level_one_chapters
    result = compile("A short intro.\n\n# Context\nBody\n\n## Detail\nNested\n\n# Hardware\nBoard\n")

    assert_equal "A short intro.", result.intro_markdown.strip
    assert_equal ["Context", "Hardware"], result.chapters.map { |chapter| chapter.fetch("title") }
    assert_equal ["context", "hardware"], result.chapters.map { |chapter| chapter.fetch("id") }
    assert result.navigation_enabled
    assert_includes result.content, 'data-project-chapter="context"'
    refute_includes result.content, "A short intro."
  end

  def test_plain_intro_stays_in_content
    result = compile("A short intro.\n\n# Context\nBody\n", "intro_style" => "plain")

    assert_equal "A short intro.", result.intro_markdown.strip
    assert_includes result.content, "A short intro."
    refute result.navigation_enabled
  end

  def test_document_without_level_one_heading_is_ordinary_content
    markdown = "Paragraph.\n\n## Detail\nNested.\n"
    result = compile(markdown)

    assert_nil result.intro_markdown
    assert_empty result.chapters
    assert_equal markdown, result.content
    refute result.navigation_enabled
  end

  def test_explicit_ids_are_preserved
    result = compile("# Industrial Design {#industrial-design}\nBody\n\n# Team\nPeople\n")

    assert_equal ["industrial-design", "team"], result.chapters.map { |chapter| chapter.fetch("id") }
  end

  def test_navigation_none_suppresses_ui_state_but_keeps_chapters
    result = compile("# Context\nBody\n\n# Hardware\nBoard\n", "navigation" => "none")

    assert_equal 2, result.chapters.length
    refute result.navigation_enabled
    assert_includes result.content, 'data-project-chapter="context"'
  end

  def test_invalid_values_name_the_source_and_allowed_values
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Context\nBody\n", "navigation" => "automatic")
    end

    assert_includes error.message, "_projects/example.md"
    assert_includes error.message, 'navigation must be "auto" or "none"'
  end

  def test_empty_and_comment_only_preface_does_not_create_intro
    result = compile("<!-- editorial note -->\n\n# Context\nBody\n")

    assert_nil result.intro_markdown
  end

  def test_one_chapter_does_not_enable_navigation
    result = compile("# Context\nBody\n")

    assert_equal 1, result.chapters.length
    refute result.navigation_enabled
  end

  def test_duplicate_explicit_ids_fail
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Context {#same}\nBody\n\n# Hardware {#same}\nBoard\n")
    end

    assert_includes error.message, 'duplicate chapter id "same"'
  end

  def test_repeated_generated_titles_receive_kramdown_suffixes
    result = compile("# Test\nOne\n\n# Test\nTwo\n")

    assert_equal ["test", "test-1"], result.chapters.map { |chapter| chapter.fetch("id") }
  end

  def test_nested_headings_do_not_enter_navigation
    result = compile("# Context\nBody\n\n## Detail\nNested\n\n# Hardware\nBoard\n")

    assert_equal ["Context", "Hardware"], result.chapters.map { |chapter| chapter.fetch("title") }
  end

  def test_level_one_heading_after_a_list_uses_kramdown_toc_order
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

  def test_defaults_are_auto_and_featured
    result = compile("Intro.\n\n# Context\nBody\n\n# Team\nPeople\n")

    assert_equal "featured", result.intro_style
    assert result.navigation_enabled
  end
end

tests = ProjectDetailProcessorTest.instance_methods(false).grep(/^test_/).sort
passed = 0

tests.each do |test_name|
  ProjectDetailProcessorTest.new.public_send(test_name)
  label = test_name.to_s.delete_prefix("test_").tr("_", " ")
  puts "PASS #{label}"
  passed += 1
rescue StandardError => error
  label = test_name.to_s.delete_prefix("test_").tr("_", " ")
  warn "FAIL #{label}: #{error.message}"
end

failed = tests.length - passed
puts "#{passed} passed, #{failed} failed"
exit(failed.zero? ? 0 : 1)
