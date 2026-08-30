# frozen_string_literal: true

require "date"
require "yaml"
require_relative "test_helper"

class ScopenSourceTest < TinyTestCase
  ROOT = File.expand_path("../..", __dir__)
  SOURCE_PATH = File.join(ROOT, "_projects/scopen.md")

  def test_source_uses_components_without_author_html_or_legacy_classes
    refute(
      body.match?(%r{</?[A-Za-z][^>]*>}),
      "expected Scopen authoring to contain no raw HTML tags"
    )

    %w[project-media-grid project-video-grid project-team-grid project-team-card].each do |class_name|
      refute_includes body, class_name
    end

    assert_equal 1, body.scan(/^::: featured-link$/).length
    assert_equal 1, body.scan(/^::: video-embed$/).length
    assert_equal 0, body.scan(/^::: videos$/).length
    assert_equal 0, body.scan(/^::: gallery$/).length
    assert_equal 1, body.scan(/^::: people source=team$/).length
    assert_equal 4, body.scan(/^::: narrative-title$/).length
    assert_equal 1, body.scan(/^::: callout$/).length
    refute_includes body, "# Future Improvements"
  end

  def test_frontmatter_defines_the_complete_team_data_source
    team = frontmatter.fetch("people").fetch("team")

    assert_equal ["Byron Aguilar", "Boning Dong", "Cesar Gonzalez"],
                 team.map { |person| person.fetch("name") }
    assert_equal ["Electrical Engineer", "Computer Engineer", "Electrical Engineer"],
                 team.map { |person| person.fetch("role") }
    assert_equal(
      [
        "/assets/img/people/byron.png",
        "/assets/img/people/boning.png",
        "/assets/img/people/cesar.png"
      ],
      team.map { |person| person.fetch("image") }
    )
    assert_equal(
      [
        nil,
        "https://www.linkedin.com/in/boning-dong",
        "https://www.linkedin.com/in/cesar-gonzalez-0098341b0/"
      ],
      team.map { |person| person["url"] }
    )
  end

  def test_standalone_figures_remain_captioned_markdown_images
    expected_sources = %w[
      scopen_poster.jpg
      scopen_afe.jpg
      scopen_mcu.jpg
      scopen_pcb_top.png
      scopen_pcb_bottom.png
      scopen_pcb_6_layers.png
      scopen_firmware_stack.png
      scopen_adc_sampling.jpg
      scopen_thread_manage.png
      scopen_esp.jpg
      scopen_software_stack.png
      scopen_software_interface.jpg
      scopen_id_blue.png
    ]

    authored_images = body.lines.grep(/^!\[/)

    expected_sources.each do |filename|
      image = authored_images.find { |line| line.include?(filename) }
      assert(image, "expected a Markdown image for #{filename}")
      assert(
        image.match?(/\]\([^\s]+\s+"[^"]+"\)\s*$/),
        "expected #{filename} to provide a title caption"
      )
    end
  end

  def test_media_titles_do_not_end_with_sentence_punctuation
    media_titles = body.scan(/\]\([^\n]*\s+"([^"]+)"\)/).flatten

    assert_equal 14, media_titles.length
    media_titles.each do |title|
      refute(
        title.match?(/[.!?]\z/),
        "expected media title #{title.inspect} not to end like a sentence"
      )
    end
  end

  def test_featured_link_is_authored_in_project_intro
    intro, main_content = body.split(/^# Context\s*$/, 2)

    assert(intro, "expected content before the first H1")
    assert(main_content, "expected Context to begin Main Content")
    assert_includes intro, "::: featured-link"
    assert_includes intro, "[Watch the presentation]"
    refute_includes main_content, "::: featured-link"
  end

  private

  def source
    @source ||= File.read(SOURCE_PATH)
  end

  def source_parts
    @source_parts ||= begin
      match = source.match(/\A---\n(?<yaml>.*?)\n---\n(?<body>.*)\z/m)
      assert(match, "expected Scopen source to contain valid frontmatter fences")
      match
    end
  end

  def frontmatter
    @frontmatter ||= YAML.safe_load(
      source_parts[:yaml],
      permitted_classes: [Date],
      aliases: true
    )
  end

  def body
    source_parts[:body]
  end
end

TinyTestRunner.run(ScopenSourceTest)
