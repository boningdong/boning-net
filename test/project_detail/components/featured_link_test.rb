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
