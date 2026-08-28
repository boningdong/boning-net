# frozen_string_literal: true

require_relative "test_helper"
require_relative "../../_plugins/project_detail"

class DirectiveParserTest < TinyTestCase
  SOURCE_PATH = "_projects/example.md"

  def parse(markdown)
    BoningNet::ProjectDetail::DirectiveParser.new(
      markdown: markdown,
      source_path: SOURCE_PATH
    ).call
  end

  def test_parses_empty_body_directives
    node = parse("::: people source=team\n:::\n").fetch(0)

    assert_equal "people", node.name
    assert_equal({ "source" => "team" }, node.attributes)
    assert_equal "", node.body
    assert_equal 1, node.start_line
    assert_equal 2, node.end_line
  end

  def test_preserves_body_and_source_lines
    node = parse("Intro\n\n# Team\n::: people source=\"project team\"\nAda\nGrace\n:::\n").fetch(0)

    assert_equal "people", node.name
    assert_equal({ "source" => "project team" }, node.attributes)
    assert_equal "Ada\nGrace\n", node.body
    assert_equal 4, node.start_line
    assert_equal 7, node.end_line
  end

  def test_returns_directives_in_source_order
    nodes = parse("::: gallery\nOne\n:::\n\n::: videos\nTwo\n:::\n")

    assert_equal %w[gallery videos], nodes.map(&:name)
    assert_equal [1, 5], nodes.map(&:start_line)
  end

  def test_parses_unquoted_and_quoted_attributes
    node = parse("::: videos layout=wide caption=\"Hardware demonstration\"\nLink\n:::\n").fetch(0)

    assert_equal({ "layout" => "wide", "caption" => "Hardware demonstration" }, node.attributes)
  end

  def test_rejects_malformed_attributes_at_the_opening_line
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      parse("::: gallery columns\n:::\n")
    end

    assert_includes error.message, "_projects/example.md:1"
    assert_includes error.message, "malformed directive attribute"
  end

  def test_applies_source_line_offset_to_parser_errors
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      BoningNet::ProjectDetail::DirectiveParser.new(
        markdown: "Paragraph\n:::\n",
        source_path: SOURCE_PATH,
        source_line_offset: 4
      ).call
    end

    assert_includes error.message, "_projects/example.md:6"
    assert_includes error.message, "stray closing marker"
  end

  def test_rejects_missing_closing_markers_at_the_opening_line
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      parse("::: gallery\nImage\n")
    end

    assert_includes error.message, "_projects/example.md:1"
    assert_includes error.message, "missing closing marker"
  end

  def test_rejects_nested_directives_at_the_nested_line
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      parse("::: gallery\n::: callout\nText\n:::\n:::\n")
    end

    assert_includes error.message, "_projects/example.md:2"
    assert_includes error.message, "nested directive"
  end

  def test_rejects_stray_closing_markers
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      parse("Paragraph\n:::\n")
    end

    assert_includes error.message, "_projects/example.md:2"
    assert_includes error.message, "stray closing marker"
  end

  def test_leaves_directive_markers_inside_fenced_code_as_markdown
    nodes = parse(<<~MARKDOWN)
      ```markdown
      ::: gallery
      image
      :::
      ```

      ::: people
      Ada
      :::
    MARKDOWN

    assert_equal ["people"], nodes.map(&:name)
    assert_equal 7, nodes.fetch(0).start_line
  end

  def test_returns_immutable_nodes
    node = parse("::: people source=team\n:::\n").fetch(0)

    assert node.frozen?
    assert node.name.frozen?
    assert node.attributes.frozen?
    assert node.attributes.fetch("source").frozen?
    assert node.body.frozen?
  end
end

TinyTestRunner.run(DirectiveParserTest)
