# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../test_helper"
require_relative "../../../_plugins/project_detail"

class CalloutTest < TinyTestCase
  def test_emphasized_lead_and_allowed_markdown_compile_to_sanitized_html
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: callout
      **2.45 × 0.73 in**

      The [six-layer board](https://example.com/board) is narrow.

      - Isolated acquisition
      - Wireless control
      :::
    MARKDOWN

    assert_equal 1, result.blocks.length
    block = result.blocks.values.first
    assert_equal "callout", block.fetch("type")
    assert_includes block.fetch("html"), "<p><strong>2.45 × 0.73 in</strong></p>"
    assert_includes block.fetch("html"), '<a href="https://example.com/board">six-layer board</a>'
    assert_includes block.fetch("html"), "<ul>"
    assert_includes block.fetch("html"), "<li>Wireless control</li>"
  end

  def test_emphasis_is_also_a_valid_lead
    result = compile("# Hardware\n\n::: callout\n*Field note*\n\nSupporting copy.\n:::\n")

    assert_includes result.blocks.values.first.fetch("html"), "<p><em>Field note</em></p>"
  end

  def test_internal_include_renders_a_semantic_callout
    result = compile("# Hardware\n\n::: callout\n**Key dimension**\n\nSupporting copy.\n:::\n")
    output = render_compiled(result)

    assert_includes output, '<aside class="project-callout">'
    assert_includes output, "<p><strong>Key dimension</strong></p>"
    assert_includes output, "<p>Supporting copy.</p>"
  end

  def test_rejects_empty_or_non_emphasized_leads
    invalid_bodies = {
      "empty" => "",
      "plain lead" => "Key dimension.\n\nSupporting copy.",
      "mixed lead" => "**Key dimension** is compact.\n\nSupporting copy."
    }

    invalid_bodies.each do |label, body|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Hardware\n\n::: callout\n#{body}\n:::\n")
      end
      assert_includes error.message, "callout must begin with one paragraph containing only a strong or emphasis lead"
    end
  end

  def test_rejects_disallowed_child_content
    invalid_bodies = {
      "heading" => "**Lead**\n\n## Heading",
      "media" => "**Lead**\n\n![Board](/board.png)",
      "raw HTML" => "**Lead**\n\n<div>Unsafe</div>",
      "nested directive" => "**Lead**\n\n::: featured-link\n[Watch](https://example.com)\n:::"
    }

    invalid_bodies.each do |label, body|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Hardware\n\n::: callout\n#{body}\n:::\n")
      end
      expected = case label
                 when "raw HTML" then "raw HTML is not allowed"
                 when "nested directive" then "nested directive is not allowed"
                 else "callout may contain only paragraphs, lists, and links"
                 end
      assert_includes error.message, expected
    end
  end

  def test_rejects_paragraph_inline_attribute_lists
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(<<~MARKDOWN)
        # Hardware

        ::: callout
        **Lead**
        {: onclick="alert(1)"}
        :::
      MARKDOWN
    end

    assert_includes error.message, "callout does not allow inline attribute lists"
  end

  def test_rejects_emphasis_inline_attribute_lists
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Hardware\n\n::: callout\n**Lead**{: onclick=\"alert(1)\"}\n:::\n")
    end

    assert_includes error.message, "callout does not allow inline attribute lists"
  end

  def test_rejects_link_inline_attribute_lists
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(<<~MARKDOWN)
        # Hardware

        ::: callout
        **Lead**

        [Details](https://example.com){: onclick="alert(1)"}
        :::
      MARKDOWN
    end

    assert_includes error.message, "callout does not allow inline attribute lists"
  end

  def test_rejects_unsafe_link_schemes
    %w[javascript:alert(1) data:text/html,payload].each do |url|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Hardware\n\n::: callout\n**Lead**\n\n[Details](#{url})\n:::\n")
      end
      assert_includes error.message,
                      "callout link URL must be relative or use http, https, mailto, or tel"
    end
  end

  def test_rejects_slash_like_network_paths_and_control_obfuscation
    [
      "//example.com",
      "/\\example.com",
      "\\/example.com",
      "\\\\example.com",
      "&#47;&#92;example.com",
      "&#92;&#47;example.com",
      "/&#x09;/example.com",
      "/&bsol;example.com",
      "&bsol;/example.com",
      "&sol;&bsol;example.com",
      "&bsol;&sol;example.com",
      "/&Tab;/example.com",
      "/&NewLine;/example.com",
      "javascript&colon;alert(1)"
    ].each do |url|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Hardware\n\n::: callout\n**Lead**\n\n[Details](#{url})\n:::\n")
      end
      assert_includes error.message,
                      "callout link URL must be relative or use http, https, mailto, or tel"
    end
  end

  def test_rejects_unknown_attributes
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Hardware\n\n::: callout kind=metric\n**Lead**\n:::\n")
    end

    assert_includes error.message, 'callout does not accept attribute "kind"'
  end

  private

  def compile(markdown)
    BoningNet::ProjectDetail::Compiler.new(
      markdown: markdown,
      config: {},
      frontmatter: { "title" => "Example" },
      source_path: "_projects/example.md",
      kramdown_options: { "input" => "GFM" },
      registry: BoningNet::ProjectDetail.registry
    ).call
  end

  def render_compiled(result)
    Dir.mktmpdir("project-detail-callout") do |source|
      includes_root = File.join(source, "_includes/pages/project-detail/blocks")
      layout_path = File.join(source, "_layouts/test.html")
      FileUtils.mkdir_p(includes_root)
      FileUtils.mkdir_p(File.dirname(layout_path))
      FileUtils.cp(
        File.expand_path("../../../_includes/pages/project-detail/blocks/callout.html", __dir__),
        File.join(includes_root, "callout.html")
      )
      File.write(layout_path, "{{ content }}\n")
      File.write(
        File.join(source, "index.md"),
        {
          "layout" => "test",
          "project_detail_generated" => { "blocks" => result.blocks }
        }.to_yaml + "---\n" + result.content
      )

      destination = File.join(source, "_site")
      site = Jekyll::Site.new(
        Jekyll.configuration("source" => source, "destination" => destination, "quiet" => true)
      )
      site.process
      File.read(File.join(destination, "index.html"))
    end
  end
end

TinyTestRunner.run(CalloutTest)
