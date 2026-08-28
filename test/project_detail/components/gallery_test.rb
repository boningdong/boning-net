# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../test_helper"
require_relative "../../../_plugins/project_detail"

class GalleryTest < TinyTestCase
  def test_one_image_directs_the_author_to_plain_markdown
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(gallery("![Only image](/only.png)"))
    end

    assert_includes error.message, "gallery requires at least two images"
    assert_includes error.message, "use a plain Markdown image instead"
  end

  def test_item_count_selects_an_explicit_layout
    expected_layouts = {
      2 => "two",
      3 => "three",
      4 => "four",
      5 => "masonry",
      6 => "masonry"
    }

    expected_layouts.each do |count, expected_layout|
      result = compile(gallery(image_paragraphs(count)))
      block = result.blocks.values.first

      assert_equal "gallery", block.fetch("type")
      assert_equal expected_layout, block.fetch("layout")
      assert_equal count, block.fetch("items").length
    end
  end

  def test_empty_gallery_fails
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(gallery(""))
    end

    assert_includes error.message, "gallery must contain standalone Markdown images"
  end

  def test_non_image_children_fail
    invalid_bodies = {
      "prose" => "![First](/first.png)\n\nSupporting prose.\n\n![Second](/second.png)",
      "heading" => "![First](/first.png)\n\n## Detail\n\n![Second](/second.png)",
      "comment" => "![First](/first.png)\n\n<!-- note -->\n\n![Second](/second.png)"
    }

    invalid_bodies.each_value do |body|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile(gallery(body))
      end
      assert_includes error.message, "gallery may contain only standalone Markdown images"
    end
  end

  def test_inline_and_trailing_comments_beside_images_fail
    invalid_bodies = [
      "<!-- before -->![First](/first.png)\n\n![Second](/second.png)",
      "![First](/first.png)<!-- after -->\n\n![Second](/second.png)"
    ]

    invalid_bodies.each do |body|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile(gallery(body))
      end
      assert_includes error.message, "gallery may contain only standalone Markdown images"
    end
  end

  def test_hard_break_beside_an_image_fails
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(gallery("![First](/first.png)  \n<!-- after break -->\n\n![Second](/second.png)"))
    end

    assert_includes error.message, "gallery may contain only standalone Markdown images"
  end

  def test_invisible_whitespace_text_beside_an_image_fails
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(gallery("![First](/first.png) <!-- after space -->\n\n![Second](/second.png)"))
    end

    assert_includes error.message, "gallery may contain only standalone Markdown images"
  end

  def test_images_must_be_separated_by_blank_lines
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(gallery("![First](/first.png)\n![Second](/second.png)"))
    end

    assert_includes error.message, "gallery may contain only standalone Markdown images"
    assert_includes error.message, "separated by blank lines"
  end

  def test_each_image_preserves_figure_data_and_gets_a_heading_local_label
    result = compile(<<~MARKDOWN)
      # Industrial Design

      ::: gallery
      ![Machined top](/top.png "Top enclosure.")

      ![Machined bottom](/bottom.png "Bottom enclosure.")
      :::
    MARKDOWN

    assert_equal(
      [
        {
          "type" => "figure",
          "image" => { "src" => "/top.png", "alt" => "Machined top" },
          "caption" => {
            "label" => "INDUSTRIAL DESIGN / 01",
            "text" => "Top enclosure."
          }
        },
        {
          "type" => "figure",
          "image" => { "src" => "/bottom.png", "alt" => "Machined bottom" },
          "caption" => {
            "label" => "INDUSTRIAL DESIGN / 02",
            "text" => "Bottom enclosure."
          }
        }
      ],
      result.blocks.values.first.fetch("items")
    )
  end

  def test_caption_titles_are_optional_but_still_advance_the_figure_sequence
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: gallery
      ![No caption](/plain.png)

      ![Captioned](/captioned.png "Captioned board.")
      :::
    MARKDOWN

    first, second = result.blocks.values.first.fetch("items")
    refute(first.key?("caption"))
    assert_equal "HARDWARE / 02", second.fetch("caption").fetch("label")
  end

  def test_blank_alt_text_fails_at_the_image_source_line
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(<<~MARKDOWN, source_line_offset: 7)
        # Hardware

        ::: gallery
        ![](/missing-alt.png)

        ![Valid](/valid.png)
        :::
      MARKDOWN
    end

    assert_includes error.message, "_projects/example.md:11"
    assert_includes error.message, "figure alt text is required"
  end

  def test_unknown_directive_attributes_fail
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(<<~MARKDOWN)
        # Hardware

        ::: gallery columns=2
        ![First](/first.png)

        ![Second](/second.png)
        :::
      MARKDOWN
    end

    assert_includes error.message, 'gallery does not accept attribute "columns"'
  end

  def test_image_inline_attributes_fail
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(gallery("![First](/first.png){: width=\"10\"}\n\n![Second](/second.png)"))
    end

    assert_includes error.message, "gallery images do not allow inline attribute lists"
  end

  def test_production_include_renders_collection_items_with_media_frames_and_captions
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: gallery
      ![Board top](/top.png "Top side.")

      ![Board bottom](/bottom.png "Bottom side.")
      :::
    MARKDOWN
    output = render_compiled(result)

    assert_includes output,
                    '<ul class="project-gallery project-collection project-collection--two"'
    assert_includes output, 'data-gallery-layout="two"'
    assert_equal 2, output.scan('class="project-gallery-item project-collection-item"').length
    assert_equal 2, output.scan('<li class="project-gallery-item project-collection-item">').length
    assert_equal 2, output.scan('<figure class="project-gallery-content">').length
    assert_equal 2, output.scan('class="project-media-frame"').length
    assert_includes output, '<img src="/top.png" alt="Board top"'
    assert_includes output, '<span class="project-caption-label">HARDWARE / 01</span>'
    assert_includes output, '<span class="project-caption-text">Bottom side.</span>'
  end

  def test_production_include_uses_figure_only_for_captioned_gallery_items
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: gallery
      ![Board without caption](/plain.png)

      ![Board with caption](/captioned.png "Captioned board.")
      :::
    MARKDOWN
    output = render_compiled(result)

    assert_equal 1, output.scan('<figure class="project-gallery-content">').length
    assert_equal 1, output.scan('<div class="project-gallery-content">').length
    assert_equal 1, output.scan('<figcaption class="project-caption">').length
    assert(
      output.match?(
        /<li class="project-gallery-item project-collection-item">\s*<div class="project-gallery-content">\s*<div class="project-media-frame"><img src="\/plain\.png" alt="Board without caption"\s*\/?>/
      ),
      "expected captionless gallery media to use a neutral container inside its list item"
    )
    assert(
      output.match?(
        /<li class="project-gallery-item project-collection-item">\s*<figure class="project-gallery-content">.*?<figcaption class="project-caption">/m
      ),
      "expected captioned gallery media to use figure and figcaption inside its list item"
    )
  end

  def test_gallery_image_metadata_entities_are_decoded_once_before_rendering
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: gallery
      ![Board &amp; &#65;](/board&amp;&#45;top.png "Top &copy; &#169;")

      ![Literal &amp;copy;](/bottom.png)
      :::
    MARKDOWN
    first, second = result.blocks.values.first.fetch("items")

    assert_equal({ "src" => "/board&-top.png", "alt" => "Board & A" }, first.fetch("image"))
    assert_equal "Top © ©", first.fetch("caption").fetch("text")
    assert_equal "Literal &copy;", second.fetch("image").fetch("alt")

    output = render_compiled(result)
    assert_includes output, '<img src="/board&amp;-top.png" alt="Board &amp; A"'
    assert_includes output, '<span class="project-caption-text">Top © ©</span>'
    assert_includes output, 'alt="Literal &amp;copy;"'
    refute_includes output, "&amp;amp;"
  end

  private

  def compile(markdown, source_line_offset: 0)
    BoningNet::ProjectDetail::Compiler.new(
      markdown: markdown,
      config: {},
      frontmatter: { "title" => "Example" },
      source_path: "_projects/example.md",
      source_line_offset: source_line_offset,
      kramdown_options: { "input" => "GFM" },
      registry: BoningNet::ProjectDetail.registry
    ).call
  end

  def gallery(body)
    "# Hardware\n\n::: gallery\n#{body}\n:::\n"
  end

  def image_paragraphs(count)
    (1..count).map { |number| "![Image #{number}](/image-#{number}.png)" }.join("\n\n")
  end

  def render_compiled(result)
    Dir.mktmpdir("project-detail-gallery") do |source|
      includes_root = File.join(source, "_includes/pages/project-detail/blocks")
      layout_path = File.join(source, "_layouts/test.html")
      FileUtils.mkdir_p(File.join(includes_root, "primitives"))
      FileUtils.mkdir_p(File.dirname(layout_path))

      %w[gallery.html primitives/media-frame.html primitives/caption.html].each do |relative_path|
        FileUtils.cp(
          File.expand_path("../../../_includes/pages/project-detail/blocks/#{relative_path}", __dir__),
          File.join(includes_root, relative_path)
        )
      end
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

TinyTestRunner.run(GalleryTest)
