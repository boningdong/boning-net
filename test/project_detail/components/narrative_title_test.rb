# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../test_helper"
require_relative "../../../_plugins/project_detail"

class NarrativeTitleTest < TinyTestCase
  def test_first_visible_block_after_h1_compiles_inline_markdown
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: narrative-title
      Two **systems**, [one narrow board](https://example.com/board).
      :::

      Supporting copy.
    MARKDOWN

    assert_equal 1, result.blocks.length
    assert_equal(
      {
        "type" => "narrative-title",
        "html" => "<p>Two <strong>systems</strong>, <a href=\"https://example.com/board\">one narrow board</a>.</p>\n",
        "marks_chapter" => true
      },
      result.blocks.values.first
    )
    assert_equal "Hardware", result.chapters.first.fetch("title")
  end

  def test_rendered_title_marks_chapter_without_adding_a_heading
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: narrative-title
      Two systems, one narrow board.
      :::
    MARKDOWN
    output = render_compiled(result)

    assert_includes output, '<section class="project-chapter" data-project-chapter="hardware">'
    assert_includes output, "<h1 id=\"hardware\">Hardware</h1>"
    assert(
      output.match?(/<div class="project-narrative-title" data-project-narrative-title(?:="")?>/),
      "expected the rendered Narrative Title to mark its chapter relationship"
    )
    assert_includes output, "<p>Two systems, one narrow board.</p>"
    assert_equal 1, output.scan(/<h[1-6][ >]/).length
  end

  def test_rejects_use_without_an_immediately_preceding_h1
    invalid_documents = {
      "before any chapter" => "::: narrative-title\nTitle.\n:::\n",
      "after visible prose" => "# Hardware\n\nContext.\n\n::: narrative-title\nTitle.\n:::\n",
      "after an h2" => "# Hardware\n\n## Detail\n\n::: narrative-title\nTitle.\n:::\n"
    }

    invalid_documents.each do |label, markdown|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) { compile(markdown) }
      assert_includes error.message, "narrative-title must be the first visible block after an H1"
    end
  end

  def test_rejects_block_content_and_media
    invalid_bodies = {
      "heading" => "## Nested heading",
      "multiple paragraphs" => "First paragraph.\n\nSecond paragraph.",
      "media" => "![Board](/board.png)"
    }

    invalid_bodies.each do |label, body|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Hardware\n\n::: narrative-title\n#{body}\n:::\n")
      end
      assert_includes error.message, "narrative-title must contain exactly one inline Markdown paragraph"
    end
  end

  def test_rejects_paragraph_inline_attribute_lists
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(<<~MARKDOWN)
        # Hardware

        ::: narrative-title
        Title.
        {: onclick="alert(1)"}
        :::
      MARKDOWN
    end

    assert_includes error.message, "narrative-title does not allow inline attribute lists"
  end

  def test_rejects_emphasis_inline_attribute_lists
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Hardware\n\n::: narrative-title\n*Title*{: onclick=\"alert(1)\"}\n:::\n")
    end

    assert_includes error.message, "narrative-title does not allow inline attribute lists"
  end

  def test_rejects_link_inline_attribute_lists
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Hardware\n\n::: narrative-title\n[Title](https://example.com){: onclick=\"alert(1)\"}\n:::\n")
    end

    assert_includes error.message, "narrative-title does not allow inline attribute lists"
  end

  def test_rejects_unsafe_link_schemes
    %w[javascript:alert(1) data:text/html,payload].each do |url|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile("# Hardware\n\n::: narrative-title\n[Title](#{url})\n:::\n")
      end
      assert_includes error.message,
                      "narrative-title link URL must be relative or use http, https, mailto, or tel"
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
        compile("# Hardware\n\n::: narrative-title\n[Title](#{url})\n:::\n")
      end
      assert_includes error.message,
                      "narrative-title link URL must be relative or use http, https, mailto, or tel"
    end
  end

  def test_rejects_footnotes_that_expand_beyond_the_inline_paragraph
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(<<~MARKDOWN)
        # Hardware

        ::: narrative-title
        Title with note[^1].

        [^1]: Expanded block.
        :::
      MARKDOWN
    end

    assert_includes error.message, "narrative-title must contain exactly one inline Markdown paragraph"
  end

  def test_rejects_unknown_attributes
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Hardware\n\n::: narrative-title tone=loud\nTitle.\n:::\n")
    end

    assert_includes error.message, 'narrative-title does not accept attribute "tone"'
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
    Dir.mktmpdir("project-detail-narrative-title") do |source|
      includes_root = File.join(source, "_includes/pages/project-detail/blocks")
      layout_path = File.join(source, "_layouts/test.html")
      FileUtils.mkdir_p(includes_root)
      FileUtils.mkdir_p(File.dirname(layout_path))
      FileUtils.cp(
        File.expand_path("../../../_includes/pages/project-detail/blocks/narrative-title.html", __dir__),
        File.join(includes_root, "narrative-title.html")
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

TinyTestRunner.run(NarrativeTitleTest)
