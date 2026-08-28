# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../test_helper"
require_relative "../../../_plugins/project_detail"

class VideosTest < TinyTestCase
  def test_youtube_urls_normalize_to_privacy_enhanced_embeds
    urls = [
      "https://www.youtube.com/watch?v=4xJvWEb1Kwo",
      "https://youtu.be/fFWyjB_XNrE?t=12",
      "https://www.youtube.com/embed/ieGTWUUsJ_8",
      "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"
    ]
    result = compile(videos(urls.each_with_index.map do |url, index|
      "[Demonstration #{index + 1}](#{url})"
    end.join("\n\n")))

    items = result.blocks.values.first.fetch("items")
    assert_equal(
      [
        "https://www.youtube-nocookie.com/embed/4xJvWEb1Kwo",
        "https://www.youtube-nocookie.com/embed/fFWyjB_XNrE",
        "https://www.youtube-nocookie.com/embed/ieGTWUUsJ_8",
        "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"
      ],
      items.map { |item| item.fetch("embed_url") }
    )
    assert_equal(
      ["Demonstration 1", "Demonstration 2", "Demonstration 3", "Demonstration 4"],
      items.map { |item| item.fetch("title") }
    )
  end

  def test_link_title_becomes_an_optional_visible_caption
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: videos
      [Hardware demonstration](https://youtu.be/4xJvWEb1Kwo "Pocket lab demonstration")

      [Software demonstration](https://youtu.be/fFWyjB_XNrE)
      :::
    MARKDOWN

    first, second = result.blocks.values.first.fetch("items")
    assert_equal(
      { "label" => "HARDWARE / 01", "text" => "Pocket lab demonstration" },
      first.fetch("caption")
    )
    refute(second.key?("caption"))
  end

  def test_whitespace_only_link_title_is_treated_as_no_caption
    result = compile(videos(
      '[Hardware demonstration](https://youtu.be/4xJvWEb1Kwo "   ")'
    ))

    item = result.blocks.values.first.fetch("items").first
    refute item.key?("caption")
  end

  def test_caption_entities_are_normalized_once_before_liquid_escaping
    result = compile(videos(
      '[Entity demo](https://youtu.be/4xJvWEb1Kwo "Named &amp; decimal &#38; hex &#x26; ordinary &")'
    ))
    caption = result.blocks.values.first.fetch("items").first.fetch("caption")

    assert_equal "Named & decimal & hex & ordinary &", caption.fetch("text")

    output = render_compiled(result)
    assert_includes output,
                    '<span class="project-caption-text">Named &amp; decimal &amp; hex &amp; ordinary &amp;</span>'
    refute_includes output, "&amp;amp;"
    refute_includes output, "&amp;#38;"
    refute_includes output, "&amp;#x26;"
  end

  def test_accessible_title_flattens_inline_markdown_and_typographic_entities
    result = compile(videos(
      "[A **bold** &amp; expanding... demo](https://youtu.be/4xJvWEb1Kwo)"
    ))

    assert_equal(
      "A bold & expanding… demo",
      result.blocks.values.first.fetch("items").first.fetch("title")
    )
  end

  def test_item_count_selects_full_two_or_two_column_grid_layout
    expected_layouts = {
      1 => "full",
      2 => "two",
      3 => "grid",
      4 => "grid"
    }

    expected_layouts.each do |count, expected_layout|
      body = (1..count).map do |number|
        "[Video #{number}](https://youtu.be/#{video_id(number)})"
      end.join("\n\n")
      block = compile(videos(body)).blocks.values.first

      assert_equal "videos", block.fetch("type")
      assert_equal expected_layout, block.fetch("layout")
      assert_equal count, block.fetch("items").length
    end
  end

  def test_unsupported_hosts_and_malformed_ids_fail
    invalid_urls = [
      "https://vimeo.com/4xJvWEb1Kwo",
      "https://youtube.example/watch?v=4xJvWEb1Kwo",
      "https://www.youtube.com/watch?v=short",
      "https://youtu.be/4xJvWEb1Kwo/extra",
      "https://www.youtube.com/embed/"
    ]

    invalid_urls.each do |url|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile(videos("[Invalid video](#{url})"))
      end
      assert_includes error.message, "videos supports only valid YouTube video URLs"
    end
  end

  def test_empty_body_fails
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(videos(""))
    end

    assert_includes error.message, "videos must contain standalone Markdown links"
  end

  def test_non_link_children_and_links_without_blank_lines_fail
    invalid_bodies = [
      "Supporting prose.",
      "[First](https://youtu.be/4xJvWEb1Kwo)\n[Second](https://youtu.be/fFWyjB_XNrE)",
      "[First](https://youtu.be/4xJvWEb1Kwo) trailing text",
      "<!-- note -->\n\n[First](https://youtu.be/4xJvWEb1Kwo)"
    ]

    invalid_bodies.each do |body|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile(videos(body))
      end
      assert_includes error.message,
                      "videos may contain only standalone Markdown links separated by blank lines"
    end
  end

  def test_blank_accessible_title_fails
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(videos("[](https://youtu.be/4xJvWEb1Kwo)"))
    end

    assert_includes error.message, "videos link text is required for the iframe title"
  end

  def test_unsafe_urls_and_inline_attributes_fail
    unsafe_url_error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(videos("[Unsafe](javascript:alert(1))"))
    end
    assert_includes unsafe_url_error.message,
                    "videos link URL must be relative or use http, https, mailto, or tel"

    attribute_error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(videos("[Attributed](https://youtu.be/4xJvWEb1Kwo){: target=\"_blank\"}"))
    end
    assert_includes attribute_error.message, "videos does not allow inline attribute lists"
  end

  def test_unknown_directive_attributes_fail
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Hardware\n\n::: videos columns=2\n[Video](https://youtu.be/4xJvWEb1Kwo)\n:::\n")
    end

    assert_includes error.message, 'videos does not accept attribute "columns"'
  end

  def test_production_include_renders_accessible_lazy_privacy_enhanced_iframes
    result = compile(<<~MARKDOWN)
      # Hardware

      ::: videos
      [Hardware demonstration](https://www.youtube.com/watch?v=4xJvWEb1Kwo "Pocket lab demonstration")

      [Software demonstration](https://youtu.be/fFWyjB_XNrE)
      :::
    MARKDOWN
    output = render_compiled(result)

    assert_includes output,
                    '<ul class="project-videos project-collection project-collection--two"'
    assert_includes output, 'data-videos-layout="two"'
    assert_equal 2, output.scan('class="project-video-item project-collection-item"').length
    assert_includes output, 'src="https://www.youtube-nocookie.com/embed/4xJvWEb1Kwo"'
    assert_includes output, 'title="Hardware demonstration"'
    assert_includes output, 'loading="lazy"'
    assert_includes output,
                    'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"'
    assert_includes output, "allowfullscreen"
    assert_includes output, '<span class="project-caption-text">Pocket lab demonstration</span>'
    assert_equal 1, output.scan('<figure class="project-video-content">').length
    assert_equal 1, output.scan('<div class="project-video-content">').length
  end

  def test_captionless_video_renders_a_neutral_container_instead_of_figure
    output = render_compiled(compile(videos(
      "[Software demonstration](https://youtu.be/fFWyjB_XNrE)"
    )))

    assert_includes output, '<div class="project-video-content">'
    refute_includes output, '<figure class="project-video-content">'
    refute_includes output, '<figcaption'
  end

  def test_three_item_render_uses_grid_layout_with_spacing_that_persists_on_tablet
    body = (1..3).map do |number|
      "[Video #{number}](https://youtu.be/#{video_id(number)})"
    end.join("\n\n")
    output = render_compiled(compile(videos(body)))
    css = render_styles

    assert_includes output,
                    '<ul class="project-videos project-collection project-collection--grid" data-videos-layout="grid">'
    assert_equal 3, output.scan('class="project-video-item project-collection-item"').length
    assert(
      css.match?(/\.project-videos\.project-collection--grid\{gap:24px 18px\}/),
      "expected the three-plus Videos modifier to use the shared collection gap"
    )
    assert(
      css.match?(/@media\(max-width:\s*899px\)\{\.project-videos\.project-collection\{grid-template-columns:minmax\(0,\s*1fr\)\}\}/),
      "expected the grid to become one column without overriding its inherited gap"
    )
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

  def videos(body)
    "# Hardware\n\n::: videos\n#{body}\n:::\n"
  end

  def video_id(number)
    format("video%06d", number)
  end

  def render_compiled(result)
    Dir.mktmpdir("project-detail-videos") do |source|
      includes_root = File.join(source, "_includes/pages/project-detail/blocks")
      layout_path = File.join(source, "_layouts/test.html")
      FileUtils.mkdir_p(File.join(includes_root, "primitives"))
      FileUtils.mkdir_p(File.dirname(layout_path))

      %w[videos.html primitives/video-item.html primitives/caption.html].each do |relative_path|
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

  def render_styles
    Dir.mktmpdir("project-detail-videos-styles") do |source|
      partial_dir = File.join(source, "_sass/pages/project-detail/components")
      stylesheet_dir = File.join(source, "assets/css")
      FileUtils.mkdir_p(partial_dir)
      FileUtils.mkdir_p(stylesheet_dir)
      FileUtils.cp(
        File.expand_path("../../../_sass/pages/project-detail/components/_videos.scss", __dir__),
        File.join(partial_dir, "_videos.scss")
      )
      File.write(
        File.join(stylesheet_dir, "videos.scss"),
        "---\n---\n@use \"pages/project-detail/components/videos\";\n"
      )

      destination = File.join(source, "_site")
      site = Jekyll::Site.new(
        Jekyll.configuration(
          "source" => source,
          "destination" => destination,
          "quiet" => true,
          "sass" => { "style" => "compressed" }
        )
      )
      site.process
      File.read(File.join(destination, "assets/css/videos.css"))
    end
  end
end

TinyTestRunner.run(VideosTest)
