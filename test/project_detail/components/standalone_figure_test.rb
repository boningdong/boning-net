# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../test_helper"
require_relative "../../../_plugins/project_detail"

class StandaloneFigureTest < TinyTestCase
  def compile(markdown, source_line_offset: 0)
    BoningNet::ProjectDetail::Compiler.new(
      markdown: markdown,
      config: {},
      frontmatter: { "title" => "Example" },
      source_path: "_projects/example.md",
      source_line_offset: source_line_offset,
      kramdown_options: { "input" => "GFM" },
      registry: BoningNet::ProjectDetail::ComponentRegistry.new
    ).call
  end

  def test_standalone_markdown_image_becomes_a_figure_block
    result = compile(<<~MARKDOWN)
      # Hardware

      ![Board](/image.png "Top side with primary control circuitry.")
    MARKDOWN

    assert_equal 1, result.blocks.length
    block_id, block = result.blocks.first
    assert_equal(
      {
        "type" => "figure",
        "image" => { "src" => "/image.png", "alt" => "Board" },
        "caption" => {
          "label" => "HARDWARE / 01",
          "text" => "Top side with primary control circuitry."
        }
      },
      block
    )
    assert_includes result.content,
                    %({% include pages/project-detail/blocks/figure.html block_id="#{block_id}" %})
    refute_includes result.content, "![Board]"
  end

  def test_inline_prose_image_stays_ordinary_markdown
    result = compile("# Hardware\n\nRead ![status icon](/status.png) inline.\n")

    assert_empty result.blocks
    assert_includes result.content, "Read ![status icon](/status.png) inline."
  end

  def test_captionless_image_preserves_image_data_without_a_caption
    result = compile("# Hardware\n\n![Board underside](/underside.png)\n")

    assert_equal(
      {
        "type" => "figure",
        "image" => { "src" => "/underside.png", "alt" => "Board underside" }
      },
      result.blocks.values.first
    )
  end

  def test_missing_alt_text_fails_at_the_image_source_line
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Hardware\n\n![](/image.png \"Board\")\n", source_line_offset: 8)
    end

    assert_includes error.message, "_projects/example.md:11"
    assert_includes error.message, "alt text is required"
  end

  def test_nearest_h1_or_h2_heading_labels_figures_and_h3_does_not_reset_sequence
    result = compile(<<~MARKDOWN)
      # Hardware

      ![Top](/top.png "Top side.")

      ![Bottom](/bottom.png "Bottom side.")

      ## Industrial Design

      ![Enclosure](/enclosure.png "Machined enclosure.")

      ### Detail

      ![Controls](/controls.png "Control layout.")
    MARKDOWN

    assert_equal(
      [
        "HARDWARE / 01",
        "HARDWARE / 02",
        "INDUSTRIAL DESIGN / 01",
        "INDUSTRIAL DESIGN / 02"
      ],
      result.blocks.values.map { |block| block.fetch("caption").fetch("label") }
    )
  end

  def test_sequence_resets_for_a_repeated_heading_at_a_new_source_location
    result = compile(<<~MARKDOWN)
      # Hardware

      ![First](/first.png "First board.")

      # Hardware

      ![Second](/second.png "Second board.")
    MARKDOWN

    assert_equal(
      ["HARDWARE / 01", "HARDWARE / 01"],
      result.blocks.values.map { |block| block.fetch("caption").fetch("label") }
    )
  end

  def test_internal_include_renders_one_semantic_media_surface_and_caption
    output = render_figure(
      {
        "type" => "figure",
        "image" => { "src" => "/image.png", "alt" => "Board" },
        "caption" => { "label" => "HARDWARE / 01", "text" => "Top side." }
      }
    )

    assert_includes output, '<figure class="project-figure">'
    assert_includes output, '<div class="project-media-frame">'
    assert_includes output, '<img src="/image.png" alt="Board">'
    assert_includes output, '<figcaption class="project-caption">'
    assert_includes output, '<span class="project-caption-label">HARDWARE / 01</span>'
    assert_includes output, '<span class="project-caption-text">Top side.</span>'
    assert_equal 1, output.scan('class="project-media-frame"').length
  end

  def test_internal_include_omits_figure_and_caption_markup_without_a_title
    output = render_figure(
      {
        "type" => "figure",
        "image" => { "src" => "/image.png", "alt" => "Board" }
      }
    )

    assert_includes output, '<div class="project-media-frame">'
    assert_includes output, '<img src="/image.png" alt="Board">'
    refute_includes output, "<figure"
    refute_includes output, "<figcaption"
  end

  private

  def render_figure(block)
    Dir.mktmpdir("project-detail-figure") do |source|
      includes_root = File.join(source, "_includes/pages/project-detail/blocks")
      layout_path = File.join(source, "_layouts/test.html")
      FileUtils.mkdir_p(File.join(includes_root, "primitives"))
      FileUtils.mkdir_p(File.dirname(layout_path))

      %w[figure.html primitives/media-frame.html primitives/caption.html].each do |relative_path|
        FileUtils.cp(
          File.expand_path("../../../_includes/pages/project-detail/blocks/#{relative_path}", __dir__),
          File.join(includes_root, relative_path)
        )
      end
      File.write(layout_path, "{{ content }}\n")

      generated = { "blocks" => { "project-detail-block-1" => block } }
      File.write(
        File.join(source, "index.html"),
        {
          "layout" => "test",
          "project_detail_generated" => generated
        }.to_yaml + "---\n" +
          "{% include pages/project-detail/blocks/figure.html block_id=\"project-detail-block-1\" %}\n"
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

TinyTestRunner.run(StandaloneFigureTest)
