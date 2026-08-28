# frozen_string_literal: true

require_relative "test_helper"
require_relative "../../_plugins/project_detail"

class CompilerTest < TinyTestCase
  class FakeComponent < BoningNet::ProjectDetail::Components::Base
    register_as "fake"

    def compile(node, context)
      {
        "type" => "fake",
        "body" => node.body.strip,
        "project" => context.frontmatter.fetch("title"),
        "heading" => context.current_heading_label
      }
    end
  end

  def compile(markdown, config: {}, frontmatter: { "title" => "Example" })
    registry = BoningNet::ProjectDetail::ComponentRegistry.new
    registry.register(FakeComponent)

    BoningNet::ProjectDetail::Compiler.new(
      markdown: markdown,
      config: config,
      frontmatter: frontmatter,
      source_path: "_projects/example.md",
      kramdown_options: { "input" => "GFM" },
      registry: registry
    ).call
  end

  def test_preserves_configuration_defaults
    result = compile("Intro.\n\n# Context\nBody\n\n# Team\nPeople\n")

    assert_equal "featured", result.intro_style
    assert result.navigation_enabled
    assert_empty result.blocks
  end

  def test_rejects_invalid_configuration_values
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Context\nBody\n", config: { "intro_style" => "hero" })
    end

    assert_includes error.message, "_projects/example.md"
    assert_includes error.message, 'intro_style must be "featured" or "plain"'
  end

  def test_dispatches_directives_and_stores_generated_blocks
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: fake
      Board details.
      :::
    MARKDOWN

    assert_equal 1, result.blocks.length
    block_id, block = result.blocks.first
    assert_includes block_id, "block"
    assert_equal(
      {
        "type" => "fake",
        "body" => "Board details.",
        "project" => "Example",
        "heading" => "Hardware"
      },
      block
    )
    assert_includes result.content,
                    %({% include pages/project-detail/blocks/fake.html block_id="#{block_id}" %})
    refute_includes result.content, "::: fake"
  end

  def test_converts_directives_in_featured_intro_after_chapter_compilation
    result = compile(<<~MARKDOWN)
      ::: fake
      Intro block.
      :::

      # Context
      Body.
    MARKDOWN

    block_id = result.blocks.keys.first
    assert_includes result.intro_markdown,
                    %({% include pages/project-detail/blocks/fake.html block_id="#{block_id}" %})
    refute_includes result.intro_markdown, "PROJECT_DETAIL_INTERNAL"
  end

  def test_accepts_html_comments
    result = compile("<!-- editorial note -->\n\n# Context\nBody.\n")

    assert_equal ["Context"], result.chapters.map { |chapter| chapter.fetch("title") }
  end

  def test_rejects_inline_author_html_with_path_and_line
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Context\nText with <span>raw markup</span>.\n")
    end

    assert_includes error.message, "_projects/example.md:2"
    assert_includes error.message, "raw HTML is not allowed"
  end

  def test_rejects_block_author_html_with_path_and_line
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Context\n\n<div class=\"legacy\">\nBody\n</div>\n")
    end

    assert_includes error.message, "_projects/example.md:3"
    assert_includes error.message, "raw HTML is not allowed"
  end

  def test_allows_html_examples_inside_fenced_code
    result = compile("# Context\n\n```html\n<div>Example</div>\n```\n")

    assert_includes result.content, "<div>Example</div>"
  end

  def test_hook_leaves_legacy_layouts_untouched
    document = Struct.new(:data, :content).new(
      { "layout" => "project-post" },
      "<div class=\"legacy\">Legacy HTML remains allowed.</div>"
    )

    Jekyll::Hooks.trigger(:documents, :pre_render, document)

    assert_equal "<div class=\"legacy\">Legacy HTML remains allowed.</div>", document.content
    refute document.data.key?("project_detail_generated")
  end

  def test_document_compilation_places_blocks_only_in_generated_data
    site = Struct.new(:config).new({ "kramdown" => { "input" => "GFM" } })
    document = Struct.new(:data, :content, :relative_path, :site).new(
      { "layout" => "project-detail", "title" => "Example" },
      "# Context\nBody.\n",
      "_projects/example.md",
      site
    )

    BoningNet::ProjectDetail.compile_document(document)

    assert_equal({}, document.data.fetch("project_detail_generated").fetch("blocks"))
    refute document.data.key?("blocks")
  end
end

TinyTestRunner.run(CompilerTest)
