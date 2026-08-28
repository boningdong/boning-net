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

  def test_blockquote_image_only_paragraph_becomes_a_figure_inside_the_quote
    result = compile(<<~MARKDOWN)
      # Hardware

      > ![Quoted board](/quote.png "Quoted figure.")
    MARKDOWN

    assert_equal 1, result.blocks.length
    block_id = result.blocks.keys.first
    assert_includes result.content,
                    %(> {% include pages/project-detail/blocks/figure.html block_id="#{block_id}" %})

    output = render_compiled(result)
    assert(
      output.match?(
        /<blockquote>\s*<figure class="project-figure">\s*<div class="project-media-frame">/
      ),
      "expected the generated media frame to remain inside the blockquote"
    )
  end

  def test_list_image_only_paragraph_becomes_a_figure_inside_the_list_item
    result = compile(<<~MARKDOWN)
      # Hardware

      - ![Listed board](/list.png "Listed figure.")
    MARKDOWN

    assert_equal 1, result.blocks.length
    block_id = result.blocks.keys.first
    assert_includes result.content,
                    %(- {% include pages/project-detail/blocks/figure.html block_id="#{block_id}" %})

    output = render_compiled(result)
    assert(
      output.match?(
        /<li>\s*<figure class="project-figure">\s*<div class="project-media-frame">/
      ),
      "expected the generated media frame to remain inside the list item"
    )
  end

  def test_inline_images_inside_blockquotes_and_lists_stay_ordinary_markdown
    result = compile(<<~MARKDOWN)
      # Hardware

      > Read ![quoted status](/quote-status.png) inline.

      - Read ![listed status](/list-status.png) inline.
    MARKDOWN

    assert_empty result.blocks
    assert_includes result.content, "> Read ![quoted status](/quote-status.png) inline."
    assert_includes result.content, "- Read ![listed status](/list-status.png) inline."
  end

  def test_reference_figure_preserves_other_definitions_and_later_links_resolve
    result = compile(<<~MARKDOWN)
      # Hardware

      ![Board][board]

      [board]: /board.png "Reference figure."
      [docs]: https://example.com/docs

      Read the [documentation][docs].
    MARKDOWN

    assert_equal 1, result.blocks.length
    assert_includes result.content, "[board]: /board.png \"Reference figure.\""
    assert_includes result.content, "[docs]: https://example.com/docs"

    rendered_markdown = Kramdown::Document.new(
      result.content,
      { "input" => "GFM" }
    ).to_html
    assert_includes rendered_markdown,
                    '<a href="https://example.com/docs">documentation</a>'
  end

  def test_figure_conversion_preserves_adjacent_markdown_and_comments
    result = compile(<<~MARKDOWN)
      # Hardware

      Context before the figure.

      ![Board](/board.png "Board figure.")
      <!-- keep this editorial note -->

      Context after the figure.
    MARKDOWN

    assert_equal 1, result.blocks.length
    assert_includes result.content, "Context before the figure."
    assert_includes result.content, "<!-- keep this editorial note -->"
    assert_includes result.content, "Context after the figure."
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

  def test_image_metadata_entities_are_decoded_once_before_liquid_escaping
    result = compile(
      '# Hardware' + "\n\n" +
      '![Board &amp; &#65; &#x42;](/images/board&amp;&#45;detail.png "Caption &copy; &#169; &#xA9; &amp;copy;")' +
      "\n"
    )
    block = result.blocks.values.first

    assert_equal(
      { "src" => "/images/board&-detail.png", "alt" => "Board & A B" },
      block.fetch("image")
    )
    assert_equal "Caption © © © &copy;", block.fetch("caption").fetch("text")

    output = render_compiled(result)
    assert_includes output, '<img src="/images/board&amp;-detail.png" alt="Board &amp; A B"'
    assert_includes output, '<span class="project-caption-text">Caption © © © &amp;copy;</span>'
    refute_includes output, "&amp;amp;"
    refute_includes output, "&amp;#169;"
  end

  def test_entity_normalization_does_not_enable_unsafe_image_schemes
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Hardware\n\n![Unsafe](javascript&#58;alert(1))\n", source_line_offset: 5)
    end

    assert_includes error.message, "_projects/example.md:8"
    assert_includes error.message, "figure image source must be relative or use http or https"
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
    render_content(
      "{% include pages/project-detail/blocks/figure.html block_id=\"project-detail-block-1\" %}\n",
      { "project-detail-block-1" => block },
      extension: "html"
    )
  end

  def render_compiled(result)
    render_content(result.content, result.blocks, extension: "md")
  end

  def render_content(content, blocks, extension:)
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

      generated = { "blocks" => blocks }
      File.write(
        File.join(source, "index.#{extension}"),
        {
          "layout" => "test",
          "project_detail_generated" => generated
        }.to_yaml + "---\n" + content
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
