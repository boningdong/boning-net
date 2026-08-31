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
      intro_links: ["https://github.com/boningdong/AR-Domino"],
      facts: ["placement and chain reaction", "Unity and ARKit", "tracked physical objects as platforms"]
    },
    "areusafe" => {
      media: [
        "/assets/img/projects/areusafe/areusafe_1.jpg",
        "/assets/img/projects/areusafe/areusafe_2.jpg"
      ],
      main_links: ["https://play.google.com/store/apps/details?id=edu.ucsb.boning.jsontest"],
      facts: ["first Android app", "Tian Gao proposed the idea", "UI/UX design and Android client development"]
    },
    "chatbot" => {
      media: [
        "/assets/img/projects/chatbot/chatbot_demo_1.jpg",
        "/assets/img/projects/chatbot/chatbot_demo_2.jpg",
        "/assets/img/projects/chatbot/chatbot_demo_4.jpg",
        "/assets/img/projects/chatbot/chatbot_demo_3.jpg"
      ],
      facts: ["Two friends and I developed a 3D chatbot", "ChatGPT API", "self-trained models", "Unity and C#"]
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
        "introduced the idea to IEEE and led our members",
        "1.3-meter-long arc"
      ]
    },
    "ecosystem" => {
      media: [
        "/assets/img/projects/ecosystem/ecosystem_1.gif",
        "/assets/img/projects/ecosystem/ecosystem_2.gif"
      ],
      intro_links: ["https://github.com/boningdong/JavaEcoSimulator"],
      facts: ["predator–prey patterns", "Tian Gao inspired the project", "object-oriented design patterns", "multithreading"]
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
      ],
      facts: ["linear rails", "custom dual-fan effector", "self-replicating"]
    },
    "msp430_dev" => {
      media: [
        "/assets/img/projects/msp430_dev/msp430_devboard_3.jpg",
        "/assets/img/projects/msp430_dev/msp430_devboard_2.jpg",
        "/assets/img/projects/msp430_dev/cover.jpg"
      ],
      facts: ["MSP430F2132", "Tsinghua University", "Smart Lamp hardware and firmware", "RGB LED controller"]
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
      facts: ["color LCD screen", "capacitive touch interface", "heart-rate tracking", "The project remained unfinished"]
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
      facts: ["high-school friends and teachers", "Dr. Lintao Tang", "Tsinghua University", "capacitive touch interface and Bluetooth"]
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
      main_links: ["https://editor.p5js.org/boningUCSB/full/EsJxpC1m"],
      facts: ["MAT 259", "Seattle Public Library checkout data", "interactive 3D visualization", "W, A, S, and D keys"]
    }
  }.freeze
  PROJECT_METADATA = {
    "ar_domino" => {
      "title" => "AR Domino",
      "subtitle" => "An augmented-reality domino game built with Unity.",
      "date" => Date.new(2021, 5, 1),
      "cover" => "/assets/img/projects/ar_domino/cover.jpg",
      "external-link" => "https://github.com/boningdong/AR-Domino",
      "tags" => %w[unity ar game software]
    },
    "areusafe" => {
      "title" => "AreUSafe",
      "subtitle" => "An Android app for exploring city safety information.",
      "date" => Date.new(2017, 5, 1),
      "cover" => "/assets/img/projects/areusafe/cover.png",
      "tags" => %w[software java android]
    },
    "chatbot" => {
      "title" => "AI Chatbot Avatar",
      "subtitle" => "A 3D AI avatar for interactive story creation.",
      "date" => Date.new(2022, 4, 21),
      "cover" => "/assets/img/projects/chatbot/cover.png",
      "tags" => %w[unity ai game software]
    },
    "drsstc" => {
      "title" => "Dual Resonant Solid State Tesla Coil",
      "subtitle" => "A high-frequency, high-voltage transformer that plays music with lightning.",
      "date" => Date.new(2018, 5, 21),
      "cover" => "/assets/img/projects/drsstc/cover.jpg",
      "external-link" => "https://github.com/boningdong/DRSSTC",
      "featured" => true,
      "featured-order" => 2,
      "tags" => %w[hardware pcb]
    },
    "ecosystem" => {
      "title" => "Java Ecosystem Simulator",
      "subtitle" => "An ecosystem simulator for exploring individual and group behavior.",
      "date" => Date.new(2018, 7, 24),
      "cover" => "/assets/img/projects/ecosystem/cover.png",
      "external-link" => "https://github.com/boningdong/JavaEcoSimulator",
      "tags" => %w[software java]
    },
    "kossel_printer" => {
      "title" => "Kossel 3D Printer",
      "subtitle" => "A self-built, high-precision delta 3D printer.",
      "date" => Date.new(2016, 8, 18),
      "cover" => "/assets/img/projects/kossel_printer/cover.jpg",
      "tags" => %w[hardware 3dprinter mechanical]
    },
    "msp430_dev" => {
      "title" => "MSP430 Development Board",
      "subtitle" => "A custom MSP430 development board for embedded prototyping.",
      "date" => Date.new(2016, 4, 24),
      "cover" => "/assets/img/projects/msp430_dev/cover.jpg",
      "tags" => %w[hardware firmware embedded c pcb]
    },
    "nes_emulator" => {
      "title" => "NES Emulator Project",
      "subtitle" => "A custom game console that runs NES software on an STM32.",
      "date" => Date.new(2019, 5, 8),
      "cover" => "/assets/img/projects/nes_emulator/cover.jpg",
      "external-link" => "https://github.com/boningdong/STM32-NES-Console-Hardware",
      "tags" => %w[hardware system-design firmware embedded c pcb]
    },
    "simplewatch" => {
      "title" => "Simple Watch",
      "subtitle" => "A compact smartwatch designed from circuit board to firmware.",
      "date" => Date.new(2018, 8, 25),
      "cover" => "/assets/img/projects/simplewatch/cover.jpg",
      "external-link" => "https://github.com/boningdong/SimpleWatch",
      "tags" => %w[hardware system-design firmware embedded c pcb]
    },
    "smartlamp" => {
      "title" => "Smart Lamp",
      "subtitle" => "A Bluetooth-controlled smart lamp designed from hardware to enclosure.",
      "date" => Date.new(2016, 7, 21),
      "cover" => "/assets/img/projects/smartlamp/cover-product.png",
      "external-link" => "https://github.com/boningdong/Smart-Lamp",
      "tags" => %w[hardware system-design firmware embedded c pcb]
    },
    "spl_visualization" => {
      "title" => "Programming Languages Trend",
      "subtitle" => "A visualization of Seattle Public Library checkout data.",
      "date" => Date.new(2020, 2, 12),
      "cover" => "/assets/img/projects/spl_visualization/cover.png",
      "featured" => true,
      "featured-order" => 3,
      "tags" => %w[software ar]
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
      assert_accessible_image_lines(body)
    end
  end

  def test_every_legacy_project_preserves_its_frontmatter_contract
    PROJECT_METADATA.each do |slug, expected|
      frontmatter, _body = project_parts(slug)
      expected.each do |key, value|
        assert_equal value, frontmatter.fetch(key), "#{slug} #{key}"
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

  def test_accessibility_contract_rejects_an_empty_image_alt
    mutated_body = project_body("ar_domino").sub("![Annotated AR Domino placement interface]", "![]")

    failure = capture_assertion_failure do
      assert_accessible_image_lines(mutated_body)
    end
    assert failure, "expected an empty image alt to fail the accessibility contract"
  end

  def test_accessibility_contract_rejects_an_inline_markdown_image
    mutated_body = project_body("ar_domino").sub(
      "\n![Annotated AR Domino placement interface]",
      "\nThe interface is shown in ![Annotated AR Domino placement interface]"
    )

    failure = capture_assertion_failure do
      assert_accessible_image_lines(mutated_body)
    end
    assert failure, "expected an inline Markdown image to fail the figure contract"
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
    body.lines.select { |line| line.match?(/!\[[^\]]*\]\([^\n]*\)/) }
  end

  def assert_accessible_image_lines(body)
    authored_image_lines(body).each do |line|
      match = line.match(/^\s*!\[([^\]]+)\]\([^\s)]+\s+"([^\"]+)"\)\s*$/)
      assert(match, line)
      assert match[1].match?(/\S/), line
      assert match[2].match?(/\S/), line
      refute match[2].match?(/[.!?]\z/), line
    end
  end

  def capture_assertion_failure
    yield
    nil
  rescue AssertionFailure => error
    error
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
