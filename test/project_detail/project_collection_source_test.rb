# frozen_string_literal: true

require "date"
require "yaml"
require_relative "test_helper"

class ProjectCollectionSourceTest < TinyTestCase
  ROOT = File.expand_path("../..", __dir__)
  PROJECT_PATHS = Dir[File.join(ROOT, "_projects", "*.md")].sort.freeze
  PROJECT_PRESERVATION = {
    "ar_domino" => {
      media: [
        "https://youtu.be/WEThYat87RQ",
        "/assets/img/projects/ar_domino/domino_storytelling.jpg"
      ],
      intro_links: ["https://github.com/boningdong/AR-Domino"]
    },
    "areusafe" => {
      media: [
        "/assets/img/projects/areusafe/areusafe_1.jpg",
        "/assets/img/projects/areusafe/areusafe_2.jpg"
      ],
      main_links: ["https://play.google.com/store/apps/details?id=edu.ucsb.boning.jsontest"],
      facts: ["Tian Gao proposed the idea", "UI/UX design and Android client development"]
    },
    "chatbot" => {
      media: [
        "/assets/img/projects/chatbot/chatbot_demo_1.jpg",
        "/assets/img/projects/chatbot/chatbot_demo_2.jpg",
        "/assets/img/projects/chatbot/chatbot_demo_4.jpg",
        "/assets/img/projects/chatbot/chatbot_demo_3.jpg"
      ]
    },
    "drsstc" => {
      media: [
        "/assets/img/projects/drsstc/teslacoil_2.jpg",
        "/assets/img/projects/drsstc/teslacoil_3.jpg",
        "/assets/img/projects/drsstc/cover.jpg",
        "https://youtu.be/fd-R-8HahTA",
        "/assets/img/projects/drsstc/teslacoil_6.jpg",
        "/assets/img/projects/drsstc/teslacoil_1.jpg",
        "/assets/img/projects/drsstc/teslacoil_5.jpg"
      ],
      intro_links: ["https://github.com/boningdong/DRSSTC"],
      facts: [
        "UCSB IEEE team project from Spring 2018",
        "personal experience with and interest in Tesla coils",
        "introduced the idea to IEEE and led our members"
      ]
    },
    "ecosystem" => {
      media: [
        "/assets/img/projects/ecosystem/ecosystem_1.gif",
        "/assets/img/projects/ecosystem/ecosystem_2.gif"
      ],
      intro_links: ["https://github.com/boningdong/JavaEcoSimulator"],
      facts: ["Tian Gao inspired the project"]
    },
    "kossel_printer" => {
      media: [
        "/assets/img/projects/kossel_printer/kossel_1.jpg",
        "/assets/img/projects/kossel_printer/kossel_9.jpg",
        "/assets/img/projects/kossel_printer/kossel_2.jpg",
        "/assets/img/projects/kossel_printer/kossel_4.jpg",
        "/assets/img/projects/kossel_printer/kossel_5.jpg",
        "/assets/img/projects/kossel_printer/kossel_3.jpg",
        "/assets/img/projects/kossel_printer/kossel_7.jpg",
        "/assets/img/projects/kossel_printer/kossel_6.jpg"
      ]
    },
    "msp430_dev" => {
      media: [
        "/assets/img/projects/msp430_dev/msp430_devboard_3.jpg",
        "/assets/img/projects/msp430_dev/msp430_devboard_2.jpg",
        "/assets/img/projects/msp430_dev/cover.jpg"
      ],
      facts: ["Tsinghua University", "Smart Lamp hardware and firmware"]
    },
    "nes_emulator" => {
      media: [
        "/assets/img/projects/nes_emulator/nes_emulator_5.jpg",
        "/assets/img/projects/nes_emulator/nes_emulator_4.jpg",
        "/assets/img/projects/nes_emulator/nes_emulator_2.jpg",
        "/assets/img/projects/nes_emulator/cover.jpg"
      ],
      intro_links: ["https://github.com/boningdong/STM32-NES-Console-Hardware"],
      facts: [
        "Jeff and I designed and built",
        "Jeff originated the idea",
        "still need bug fixes and further testing",
        "Updated 07/28/2019"
      ]
    },
    "simplewatch" => {
      media: [
        "/assets/img/projects/simplewatch/smartwatch_2.jpg",
        "/assets/img/projects/simplewatch/smartwatch_3.jpg",
        "/assets/img/projects/simplewatch/smartwatch_4.jpg",
        "/assets/img/projects/simplewatch/smartwatch_5.jpg"
      ],
      intro_links: ["https://github.com/boningdong/SimpleWatch"],
      facts: ["The project remained unfinished"]
    },
    "smartlamp" => {
      media: [
        "/assets/img/projects/smartlamp/smartlamp_5.jpg",
        "/assets/img/projects/smartlamp/smartlamp_3.jpg",
        "/assets/img/projects/smartlamp/smartlamp_6.jpg",
        "/assets/img/projects/smartlamp/smartlamp_1.jpg",
        "/assets/img/projects/smartlamp/smartlamp_4.jpg"
      ],
      intro_links: ["https://github.com/boningdong/Smart-Lamp"],
      facts: ["Dr. Lintao Tang", "Tsinghua University"]
    },
    "spl_visualization" => {
      media: [
        "/assets/img/projects/spl_visualization/spl_visualization_5.png",
        "/assets/img/projects/spl_visualization/spl_visualization_2.png",
        "/assets/img/projects/spl_visualization/cover.png",
        "/assets/img/projects/spl_visualization/spl_visualization_4.png",
        "/assets/img/projects/spl_visualization/spl_visualization_3.png"
      ],
      intro_links: ["https://github.com/boningdong/MAT259-3D-Visualization"],
      main_links: ["https://editor.p5js.org/boningUCSB/full/EsJxpC1m"]
    }
  }.freeze

  def assert_equal(expected, actual, message = nil)
    super(expected, actual)
  rescue AssertionFailure
    raise AssertionFailure, message || "expected #{expected.inspect}, got #{actual.inspect}"
  end

  def test_every_project_uses_the_project_detail_authoring_contract
    PROJECT_PATHS.each do |path|
      frontmatter, body = parse_project(path)
      assert_equal "project-detail", frontmatter.fetch("layout"), path
      refute body.match?(%r{</?[A-Za-z][^>]*>}), path
      refute body.match?(/\{[{%].*?[}%]\}/m), path
      assert body.match?(/\A\s*\S.*?^#\s+\S/m), "expected Intro and Main Content in #{path}"
    end
  end

  def test_every_authored_media_item_has_accessible_copy
    PROJECT_PATHS.each do |path|
      _frontmatter, body = parse_project(path)
      authored_image_lines(body).each do |line|
        match = line.match(/^\s*!\[([^\]]+)\]\([^\s)]+\s+"([^\"]+)"\)\s*$/)
        assert(match, line)
        assert match[1].match?(/\S/), line
        assert match[2].match?(/\S/), line
        refute match[2].match?(/[.!?]\z/), line
      end
    end
  end

  def test_every_legacy_project_preserves_its_authored_media_sequence
    PROJECT_PRESERVATION.each do |slug, preservation|
      assert_equal preservation.fetch(:media), authored_media_sources(project_body(slug)), slug
    end
  end

  def test_media_ledger_rejects_a_missing_required_media_item
    mutated_body = project_body("ar_domino").sub("domino_storytelling.jpg", "removed.jpg")

    assert_raises(AssertionFailure) do
      assert_equal PROJECT_PRESERVATION.fetch("ar_domino").fetch(:media), authored_media_sources(mutated_body)
    end
  end

  def test_preserved_destinations_remain_in_their_required_authoring_regions
    PROJECT_PRESERVATION.each do |slug, preservation|
      intro, main_content = intro_and_main_content(project_body(slug))

      preservation.fetch(:intro_links, []).each do |destination|
        assert featured_link_contains?(intro, destination), "expected #{destination} in #{slug} Intro featured link"
        refute main_content.include?(destination), "expected #{destination} only in #{slug} Intro"
      end

      preservation.fetch(:main_links, []).each do |destination|
        assert main_content.include?(destination), "expected #{destination} after the first H1 in #{slug}"
        refute featured_link_contains?(intro, destination), "expected #{destination} outside the #{slug} Intro featured link"
      end
    end
  end

  def test_preserves_required_attribution_and_status_facts
    PROJECT_PRESERVATION.each do |slug, preservation|
      preservation.fetch(:facts, []).each do |fact|
        assert_includes project_body(slug), fact
      end
    end
  end

  private

  def parse_project(path)
    source = File.read(path)
    match = source.match(/\A---\n(?<yaml>.*?)\n---\n(?<body>.*)\z/m)
    assert(match, "expected #{path} to contain valid frontmatter fences")

    frontmatter = YAML.safe_load(
      match[:yaml],
      permitted_classes: [Date],
      aliases: true
    )
    [frontmatter, match[:body]]
  end

  def project_body(slug)
    _frontmatter, body = project_parts(slug)
    body
  end

  def project_parts(slug)
    parse_project(File.join(ROOT, "_projects", "#{slug}.md"))
  end

  def authored_image_lines(body)
    body.scan(/^\s*!\[[^\n]+\]\([^\n]+\)\s*$/)
  end

  def authored_media_sources(body)
    body.scan(/!\[[^\]]+\]\(([^\s)]+)(?:\s+"[^\"]+")?\)|::: video-embed\s*\n\[[^\]]+\]\(([^\s)]+)/m).map do |image_source, video_source|
      image_source || video_source
    end
  end

  def intro_and_main_content(body)
    match = body.match(/^#\s+\S/m)
    assert(match, "expected a first H1")
    [body[...match.begin(0)], body[match.begin(0)..]]
  end

  def featured_link_contains?(intro, destination)
    intro.match?(%r{::: featured-link\s*\n.*?\]\(#{Regexp.escape(destination)}\)\s*\n:::\s*$}m)
  end
end

TinyTestRunner.run(ProjectCollectionSourceTest)
