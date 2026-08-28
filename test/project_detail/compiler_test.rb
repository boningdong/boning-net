# frozen_string_literal: true

require "fileutils"
require "tmpdir"
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

  class ContextComponent < BoningNet::ProjectDetail::Components::Base
    register_as "context"

    def compile(_node, context)
      {
        "type" => "context",
        "heading" => context.current_heading_label,
        "figure_number" => context.next_figure_number
      }
    end
  end

  class NonSerializableComponent < BoningNet::ProjectDetail::Components::Base
    register_as "nonserializable"

    def compile(_node, _context)
      {
        "type" => "nonserializable",
        "items" => [{ "value" => Object.new }]
      }
    end
  end

  def compile(
    markdown,
    config: {},
    frontmatter: { "title" => "Example" },
    source_line_offset: 0
  )
    registry = BoningNet::ProjectDetail::ComponentRegistry.new
    registry.register(FakeComponent)
    registry.register(ContextComponent)
    registry.register(NonSerializableComponent)

    BoningNet::ProjectDetail::Compiler.new(
      markdown: markdown,
      config: config,
      frontmatter: frontmatter,
      source_path: "_projects/example.md",
      source_line_offset: source_line_offset,
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

  def test_rejects_nonserializable_values_nested_in_component_blocks
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Hardware\n\n::: nonserializable\n:::\n")
    end

    assert_includes error.message, "component block data must be JSON-like"
    assert_includes error.message, "_projects/example.md:3"
  end

  def test_replaces_double_digit_block_sentinels_without_prefix_collisions
    directives = (1..12).map do |number|
      "::: fake\nBlock #{number}.\n:::"
    end.join("\n\n")
    result = compile("# Hardware\n\n#{directives}\n")

    assert_equal 12, result.blocks.length
    assert_equal 12, result.content.scan("{% include pages/project-detail/blocks/fake.html").length
    (1..12).each do |number|
      assert_includes result.content,
                      %(block_id="project-detail-block-#{number}")
    end
    refute_includes result.content, "PROJECT_DETAIL_INTERNAL"
  end

  def test_splits_double_digit_featured_intro_sentinels_without_prefix_collisions
    directives = (1..12).map do |number|
      "::: fake\nIntro block #{number}.\n:::"
    end.join("\n\n")
    result = compile("#{directives}\n\n# Hardware\nBody.\n")
    block_parts = result.intro_parts.select { |part| part.fetch("kind") == "block" }

    assert_equal 12, block_parts.length
    assert_equal(
      (1..12).map { |number| "project-detail-block-#{number}" },
      block_parts.map { |part| part.fetch("block_id") }
    )
    refute_includes result.intro_markdown, "PROJECT_DETAIL_INTERNAL"
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

  def test_featured_intro_components_render_through_trusted_includes
    result = compile(<<~MARKDOWN)
      Before *text*.

      ::: fake
      Intro block.
      :::

      After.

      # Context
      Body.
    MARKDOWN

    output = render_featured_intro(result)

    assert_includes output, "<p>Before <em>text</em>.</p>"
    assert_includes output, '<aside data-fake="true">Intro block.</aside>'
    assert_includes output, "<p>After.</p>"
    refute_includes output, "{% include"
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

  def test_applies_source_line_offset_to_compiler_errors
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(
        "# Context\nText with <span>raw markup</span>.\n",
        source_line_offset: 17
      )
    end

    assert_includes error.message, "_projects/example.md:19"
  end

  def test_applies_source_line_offset_to_registry_errors
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("Paragraph.\n\n::: unknown\n:::\n", source_line_offset: 8)
    end

    assert_includes error.message, "_projects/example.md:11"
    assert_includes error.message, 'unknown directive "unknown"'
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

  def test_figure_context_ignores_h3
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: context
      :::

      ### Detail

      ::: context
      :::

    MARKDOWN

    blocks = result.blocks.values
    assert_equal ["Hardware", "Hardware"], blocks.map { |block| block.fetch("heading") }
    assert_equal [1, 2], blocks.map { |block| block.fetch("figure_number") }
  end

  def test_figure_context_resets_for_repeated_h1_and_h2_titles
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: context
      :::

      ::: context
      :::

      # Hardware


      ::: context
      :::

      ::: context
      :::

      ## Detail

      ::: context
      :::

      ::: context
      :::

      ## Detail

      ::: context
      :::

      ::: context
      :::
    MARKDOWN

    blocks = result.blocks.values
    assert_equal ["Hardware", "Hardware", "Hardware", "Hardware", "Detail", "Detail", "Detail", "Detail"],
                 blocks.map { |block| block.fetch("heading") }
    assert_equal [1, 2, 1, 2, 1, 2, 1, 2],
                 blocks.map { |block| block.fetch("figure_number") }
  end

  private

  def render_featured_intro(result)
    Dir.mktmpdir("project-detail-render") do |source|
      intro_path = File.join(source, "_includes/pages/project-detail/intro.html")
      fake_path = File.join(source, "_includes/pages/project-detail/blocks/fake.html")
      layout_path = File.join(source, "_layouts/test.html")
      FileUtils.mkdir_p(File.dirname(intro_path))
      FileUtils.mkdir_p(File.dirname(fake_path))
      FileUtils.mkdir_p(File.dirname(layout_path))
      FileUtils.cp(
        File.expand_path("../../_includes/pages/project-detail/intro.html", __dir__),
        intro_path
      )
      File.write(
        fake_path,
        <<~LIQUID
          {% assign block = page.project_detail_generated.blocks[include.block_id] %}
          <aside data-fake="true">{{ block.body }}</aside>
        LIQUID
      )
      File.write(layout_path, "{% include pages/project-detail/intro.html %}\n")

      generated = {
        "intro_markdown" => result.intro_markdown,
        "intro_parts" => result.respond_to?(:intro_parts) ? result.intro_parts : nil,
        "intro_style" => result.intro_style,
        "blocks" => result.blocks
      }
      File.write(
        File.join(source, "index.html"),
        { "layout" => "test", "project_detail_generated" => generated }.to_yaml + "---\n"
      )
      destination = File.join(source, "_site")
      site = Jekyll::Site.new(
        Jekyll.configuration(
          "source" => source,
          "destination" => destination,
          "quiet" => true
        )
      )
      site.process
      File.read(File.join(destination, "index.html"))
    end
  end
end

TinyTestRunner.run(CompilerTest)
