# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../test_helper"
require_relative "../../../_plugins/project_detail"

class FeaturedLinkTest < TinyTestCase
  def test_exactly_one_standalone_link_preserves_url_and_inline_label_markdown
    result = compile(<<~MARKDOWN)
      # Software

      ::: featured-link
      [Watch *the presentation*](https://example.com/watch)
      :::
    MARKDOWN

    assert_equal(
      {
        "type" => "featured-link",
        "url" => "https://example.com/watch",
        "label_html" => "Watch <em>the presentation</em>"
      },
      result.blocks.values.first
    )
  end

  def test_internal_include_renders_one_link_without_a_new_window_target
    result = compile("# Software\n\n::: featured-link\n[Watch the presentation](https://example.com/watch)\n:::\n")
    output = render_compiled(result)

    assert_includes output, '<a class="project-featured-link" href="https://example.com/watch">'
    assert_includes output, '<span class="project-featured-link-label">Watch the presentation</span>'
    assert_equal 1, output.scan("<a ").length
    refute_includes output, "target=\"_blank\""
  end

  def test_rejects_empty_multiple_link_and_prose_plus_link_bodies
    invalid_bodies = {
      "empty" => "",
      "multiple links" => "[First](https://example.com/first) [Second](https://example.com/second)",
      "prose plus link" => "Watch [the presentation](https://example.com/watch).",
      "multiple paragraphs" => "[First](https://example.com/first)\n\n[Second](https://example.com/second)"
    }

    invalid_bodies.each do |label, body|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Software\n\n::: featured-link\n#{body}\n:::\n")
      end
      assert_includes error.message, "featured-link must contain exactly one standalone Markdown link"
    end
  end

  def test_rejects_xml_comments_in_the_strict_single_link_body
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(<<~MARKDOWN)
        # Software

        ::: featured-link
        <!-- editorial note -->
        [Watch](https://example.com/watch)
        :::
      MARKDOWN
    end

    assert_includes error.message, "_projects/example.md:3"
    assert_includes error.message, "featured-link must contain exactly one standalone Markdown link"
  end

  def test_rejects_empty_or_whitespace_only_accessible_labels
    ["", "   ", "&nbsp;"].each do |label|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Software\n\n::: featured-link\n[#{label}](https://example.com/watch)\n:::\n")
      end

      assert_includes error.message, "featured-link link text is required for accessibility"
    end
  end

  def test_rejects_media_heading_and_unknown_attributes
    invalid_documents = {
      "media" => "::: featured-link\n[![Preview](/preview.png)](https://example.com)\n:::\n",
      "heading" => "::: featured-link\n# [Watch](https://example.com)\n:::\n",
      "attribute" => "::: featured-link style=primary\n[Watch](https://example.com)\n:::\n"
    }

    invalid_documents.each do |label, directive|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Software\n\n#{directive}")
      end
      expected = label == "attribute" ? 'featured-link does not accept attribute "style"' :
        "featured-link must contain exactly one standalone Markdown link"
      assert_includes error.message, expected
    end
  end

  def test_rejects_paragraph_inline_attribute_lists
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(<<~MARKDOWN)
        # Software

        ::: featured-link
        [Watch](https://example.com)
        {: onclick="alert(1)"}
        :::
      MARKDOWN
    end

    assert_includes error.message, "featured-link does not allow inline attribute lists"
  end

  def test_rejects_emphasis_inline_attribute_lists
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(<<~MARKDOWN)
        # Software

        ::: featured-link
        [Watch *now*{: onclick="alert(1)"}](https://example.com)
        :::
      MARKDOWN
    end

    assert_includes error.message, "featured-link does not allow inline attribute lists"
  end

  def test_rejects_link_inline_attribute_lists
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Software\n\n::: featured-link\n[Watch](https://example.com){: onclick=\"alert(1)\"}\n:::\n")
    end

    assert_includes error.message, "featured-link does not allow inline attribute lists"
  end

  def test_rejects_unsafe_and_protocol_relative_links
    ["javascript:alert(1)", "data:text/html,payload", "//example.com/watch"].each do |url|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Software\n\n::: featured-link\n[Watch](#{url})\n:::\n")
      end
      assert_includes error.message,
                      "featured-link link URL must be relative or use http, https, mailto, or tel"
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
        compile("# Software\n\n::: featured-link\n[Watch](#{url})\n:::\n")
      end
      assert_includes error.message,
                      "featured-link link URL must be relative or use http, https, mailto, or tel"
    end
  end

  def test_accepts_relative_fragment_and_allowed_scheme_links
    [
      "/projects/scopen",
      "../presentation",
      "#demonstration",
      "https://example.com/watch",
      "http://example.com/watch",
      "mailto:hello@example.com",
      "tel:+15551234567",
      "/%5Cexample.com",
      "%5C/example.com",
      "%2F%2Fexample.com"
    ].each do |url|
      result = compile("# Software\n\n::: featured-link\n[Watch](#{url})\n:::\n")
      assert_equal url, result.blocks.values.first.fetch("url")
    end
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
    Dir.mktmpdir("project-detail-featured-link") do |source|
      includes_root = File.join(source, "_includes/pages/project-detail/blocks")
      layout_path = File.join(source, "_layouts/test.html")
      FileUtils.mkdir_p(includes_root)
      FileUtils.mkdir_p(File.dirname(layout_path))
      FileUtils.cp(
        File.expand_path("../../../_includes/pages/project-detail/blocks/featured-link.html", __dir__),
        File.join(includes_root, "featured-link.html")
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

TinyTestRunner.run(FeaturedLinkTest)
