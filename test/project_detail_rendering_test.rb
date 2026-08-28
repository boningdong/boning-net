# frozen_string_literal: true

require "open3"
require "rbconfig"
require "sass-embedded"

ROOT = File.expand_path("..", __dir__)

class AssertionFailure < StandardError; end

def assert(condition, message)
  raise AssertionFailure, message unless condition
end

def assert_includes(text, value)
  assert(text.include?(value), "expected output to include #{value.inspect}")
end

def refute_includes(text, value)
  assert(!text.include?(value), "expected output not to include #{value.inspect}")
end

def assert_equal(expected, actual)
  assert(expected == actual, "expected #{expected.inspect}, got #{actual.inspect}")
end

def built(path)
  full_path = File.join(ROOT, "_site", path)
  assert(File.file?(full_path), "expected generated file #{path}")
  File.read(full_path)
end

def compiled_project_detail_css
  Sass.compile_string(
    '@use "pages/project-detail";',
    load_paths: [File.join(ROOT, "_sass")],
    style: :compressed
  ).css
end

def assert_selector_follows(css, later_selector, earlier_selector)
  earlier_index = css.index(earlier_selector)
  later_index = css.index(later_selector)

  assert(earlier_index, "expected compiled CSS to include #{earlier_selector.inspect}")
  assert(later_index, "expected compiled CSS to include #{later_selector.inspect}")
  assert(
    later_index > earlier_index,
    "expected #{later_selector.inspect} to follow #{earlier_selector.inspect} in the cascade"
  )
end

stylesheet_tests = {
  "project detail stylesheet delegates ownership to partials" => lambda do
    entry = File.read(File.join(ROOT, "_sass/pages/_project-detail.scss"))
    expected_uses = [
      '@use "project-detail/shell";',
      '@use "project-detail/article";',
      '@use "project-detail/navigation";',
      '@use "project-detail/primitives/caption";',
      '@use "project-detail/primitives/collection";',
      '@use "project-detail/primitives/media-frame";',
      '@use "project-detail/components/callout";',
      '@use "project-detail/components/featured-link";',
      '@use "project-detail/components/gallery";',
      '@use "project-detail/components/videos";',
      '@use "project-detail/components/people";',
      '@use "project-detail/components/narrative-title";'
    ]

    assert_equal expected_uses, entry.lines.map(&:strip).reject(&:empty?)
  end,
  "project detail partials compile the complete visual contract" => lambda do
    css = compiled_project_detail_css

    %w[
      .project-detail-page
      .project-hero
      .project-intro--featured
      .project-reading
      .project-main
      .project-chapter-nav
      .project-corner
      .project-callout
      .project-featured-link
      .project-gallery
      .project-videos.project-collection
      .project-people
      .project-narrative-title
      .project-caption
      .project-collection
      .project-media-frame
    ].each { |selector| assert_includes css, selector }

    %w[
      .project-media-grid
      .project-media{
      .project-video-grid
      .project-video{
      .project-team-grid
      .project-team-card
    ].each do |selector|
      refute_includes css, selector
    end

    assert(css.match?(/\.project-hero\{[^}]*min-height:520px/), "expected the approved desktop Hero height")
    assert(
      css.match?(/@media\s*\(min-width:\s*1600px\)\{\.project-hero\{min-height:clamp\(600px,28vw,780px\)\}/),
      "expected the approved ultrawide Hero height"
    )
    assert(
      css.match?(/@media\s*\(max-width:\s*640px\)\{[^}]*\.project-hero\{min-height:470px\}/),
      "expected the approved mobile Hero height"
    )
    assert(css.match?(/\.project-intro--featured\{padding:78px 0 84px\}/), "expected the approved Bridge spacing")
    assert(
      css.match?(/\.project-intro-copy\{[^}]*grid-template-columns:minmax\(150px,\s*0?\.36fr\) minmax\(0,\s*1\.64fr\)/),
      "expected the approved Bridge grid"
    )
    assert(
      css.match?(/\.project-intro-copy p:first-of-type\{[^}]*font-size:clamp\(36px,4\.5vw,52px\)/),
      "expected the approved Bridge lead type"
    )
    assert(
      css.match?(/\.project-reading\{[^}]*grid-template-columns:176px minmax\(0,\s*1fr\)[^}]*border-top:1px solid var\(--line\)/),
      "expected the approved reading rail"
    )
    assert(
      css.match?(/\.project-reading--no-navigation\{grid-template-columns:minmax\(0,\s*1fr\)\}/),
      "expected Main Content to use the full reading width when navigation is disabled"
    )
    assert(css.match?(/\.project-chapter\{[^}]*padding:78px 0 94px/), "expected the approved chapter rhythm")
    assert(
      css.match?(/\.project-main h1\{[^}]*font-size:clamp\(36px,4\.3vw,52px\)/),
      "expected the approved chapter heading scale"
    )
    assert(
      css.match?(/\.project-chapter-nav\{[^}]*position:sticky[^}]*top:86px[^}]*padding:78px 0/),
      "expected the approved desktop chapter navigation"
    )
    assert(css.match?(/\.project-corner\{display:none\}/), "expected Corner to remain hidden on desktop")
    assert(
      css.match?(/@media\s*\(max-width:\s*899px\)\{.*?\.project-corner\{[^}]*display:block[^}]*visibility:hidden/m),
      "expected Corner to remain available but hidden by default below desktop"
    )
    assert(
      css.match?(/\.project-corner-trigger\{[^}]*min-width:108px[^}]*min-height:52px/),
      "expected the approved Corner indicator geometry"
    )
    assert(
      css.match?(/\.project-corner-dialog\{[^}]*width:min\(272px,(?:calc\()?100% - 28px\)?\)/),
      "expected the approved Corner menu footprint"
    )
  end,
  "project detail component media and person cards override prose defaults" => lambda do
    css = compiled_project_detail_css

    assert_selector_follows(
      css,
      ".project-main .project-gallery:not(.project-collection--masonry) .project-media-frame>img",
      ".project-main img{"
    )
    assert_selector_follows(css, ".project-main .project-person-card img", ".project-main img{")
    assert_selector_follows(
      css,
      ".project-main .project-person-copy :where(h3,strong)",
      ".project-main h3{"
    )
  end
}

stylesheet_passed = 0
stylesheet_tests.each do |name, test|
  test.call
  puts "PASS #{name}"
  stylesheet_passed += 1
rescue StandardError => error
  warn "FAIL #{name}: #{error.message}"
end

stylesheet_failed = stylesheet_tests.length - stylesheet_passed
puts "#{stylesheet_passed} stylesheet tests passed, #{stylesheet_failed} failed"
exit(1) unless stylesheet_failed.zero?
exit(0) if ENV["PROJECT_DETAIL_STYLESHEET_ONLY"] == "true"

jekyll = Gem.bin_path("jekyll", "jekyll")
stdout, stderr, status = Open3.capture3(
  { "JEKYLL_ENV" => "production" },
  RbConfig.ruby,
  jekyll,
  "build",
  chdir: ROOT
)
abort("Jekyll build failed:\n#{stdout}\n#{stderr}") unless status.success?

tests = {
  "Scopen uses the modern project detail contract" => lambda do
    html = built("projects/scopen.html")

    assert_includes html, '<body class="modern-page project-detail-page">'
    assert_includes html, "data-project-detail"
    assert_includes html, "data-project-main"
    assert_includes html, 'aria-label="Project chapters"'
    assert_includes html, "data-project-corner"
    assert_includes html, "/assets/js/pages/project-detail.js"
    assert_includes html,
                    '<img class="project-hero-image" src="/assets/img/showcase/project-detail-defaults/night-instrument-expanded.png"'
    refute_includes html, "bootstrap.min.css"
    refute_includes html, "jquery"
  end,
  "legacy project pages remain on their existing shell" => lambda do
    html = built("projects/areusafe.html")

    assert_includes html, "bootstrap.min.css"
    assert_includes html, "jquery"
    refute_includes html, "data-project-detail"
  end,
  "project detail visual system is compiled" => lambda do
    css = built("assets/css/main.css")

    assert_includes css, ".project-detail-page"
    assert_includes css, ".project-hero"
    assert_includes css, ".project-intro--featured"
    assert_includes css, ".project-chapter-nav"
    assert_includes css, ".project-corner"
    assert_includes css, ".project-gallery"
    assert_includes css, ".project-videos"
    assert_includes css, ".project-people"
    assert_includes css, "object-fit:cover"
    assert_includes css, "backdrop-filter:blur"
    assert(
      css.match?(/\.project-gallery-item \.project-media-frame\{margin:0/),
      "expected gallery media frames to reset their margin"
    )
    %w[.project-media-grid .project-video-grid .project-team-grid].each do |selector|
      refute_includes css, selector
    end
  end,
  "project detail matches the approved final mock geometry" => lambda do
    html = built("projects/scopen.html")
    css = built("assets/css/main.css")

    assert_includes html, 'class="project-intro-shell"'
    assert_includes html, 'class="project-intro-copy"'
    refute_includes html, 'class="project-intro-marker"'
    assert(
      html.match?(/<h1>\s*Scopen\s*<span class="project-hero-description">/),
      "expected the Hero subtitle to use the approved nested hierarchy"
    )
    assert(
      css.match?(/\.project-hero\{[^}]*min-height:520px/),
      "expected the default Project Hero to be 520px tall"
    )
    assert(
      css.match?(/\.project-hero-image\{[^}]*object-fit:cover/),
      "expected the approved Hero artwork to retain cover behavior"
    )
    assert(
      css.match?(/@media\s*\(min-width:\s*1600px\)\{\.project-hero\{min-height:clamp\(600px,28vw,780px\)\}/),
      "expected the approved ultrawide Project Hero height"
    )
    assert(
      css.match?(/@media\s*\(max-width:\s*640px\)\{[^}]*\.project-hero\{min-height:470px\}/),
      "expected the approved mobile Project Hero height"
    )
    assert(
      css.match?(/\.project-intro--featured\{padding:78px 0 84px\}/),
      "expected the approved Bridge section spacing"
    )
    assert(
      css.match?(/\.project-intro-copy\{[^}]*grid-template-columns:minmax\(150px,\s*0?\.36fr\) minmax\(0,\s*1\.64fr\)/),
      "expected the approved two-column Bridge geometry"
    )
    assert(
      css.match?(/\.project-intro-copy p:first-of-type\{[^}]*font-size:clamp\(36px,4\.5vw,52px\)/),
      "expected the approved Bridge lead scale"
    )
    assert(
      !css.include?(".project-intro-shell{min-height:310px}"),
      "Bridge should size to a one-sentence or short-paragraph Intro"
    )
  end,
  "project detail reading flow matches the approved final mock" => lambda do
    css = built("assets/css/main.css")

    assert(
      css.match?(/\.project-reading\{[^}]*grid-template-columns:176px minmax\(0,\s*1fr\)[^}]*border-top:1px solid var\(--line\)/),
      "expected the approved chapter rail and Main Content separator"
    )
    assert(
      css.match?(/\.project-chapter\{[^}]*padding:78px 0 94px/),
      "expected the approved chapter rhythm"
    )
    assert(
      css.match?(/\.project-main h1\{[^}]*font-size:clamp\(36px,4\.3vw,52px\)/),
      "expected the approved chapter heading scale"
    )
    assert(
      css.match?(/\.project-corner-trigger\{[^}]*min-width:108px[^}]*min-height:52px/),
      "expected the approved Corner indicator geometry"
    )
    assert(
      css.match?(/\.project-corner-dialog\{[^}]*width:min\(272px,(?:calc\()?100% - 28px\)?\)/),
      "expected the approved Corner menu footprint"
    )
    assert(
      css.match?(/@media\s*\(max-width:\s*899px\)\{\.project-hero-image\{[^}]*\}\.project-intro-copy\{[^}]*grid-template-columns:minmax\(120px,\s*0?\.3fr\) minmax\(0,\s*1\.7fr\)[^}]*column-gap:34px/),
      "expected the approved tablet Bridge geometry"
    )
  end,
  "project detail glass belongs to media surfaces, not nested images" => lambda do
    css = built("assets/css/main.css")

    assert(
      css.match?(/\.project-main \.project-chapter>p>img:only-child,[^{]*\{[^}]*backdrop-filter:blur/),
      "expected standalone Markdown images to retain the glass surface"
    )
    assert(
      !css.match?(/\.project-main img,[^{]*\{[^}]*backdrop-filter:blur/),
      "nested media images should not create a second glass compositing layer"
    )
  end,
  "Scopen renders the authored component set without syntax or legacy markup leaks" => lambda do
    html = built("projects/scopen.html")

    assert_includes html, '<a class="project-featured-link" href="https://youtu.be/ieGTWUUsJ_8">'
    assert_includes html, "Watch the Scopen presentation"

    assert_includes html, 'class="project-videos project-collection project-collection--two"'
    assert_includes html, 'src="https://www.youtube-nocookie.com/embed/4xJvWEb1Kwo"'
    assert_includes html, 'title="Scopen hardware demonstration"'
    assert_includes html, 'src="https://www.youtube-nocookie.com/embed/fFWyjB_XNrE"'
    assert_includes html, 'title="Scopen software demonstration"'
    assert_includes html, "Physical prototype and signal capture demonstration."
    assert_includes html, "Desktop interface and wireless workflow demonstration."

    assert_equal 3, html.scan('class="project-gallery project-collection project-collection--two"').length
    assert_equal 6, html.scan('class="project-gallery-item project-collection-item"').length
    assert_includes html, "Analog front end: isolation, gain control, and differential conversion."
    assert_includes html, "Bottom side with supporting components and interconnects."
    assert_includes html, "Assembled product study with probe, controls, and display window."
    assert_includes html, '<span class="project-caption-label">HARDWARE / 01</span>'
    assert_includes html, '<span class="project-caption-label">HARDWARE / 05</span>'
    assert_includes html, '<span class="project-caption-label">INDUSTRIAL DESIGN / 02</span>'

    assert(
      html.match?(/<div class="project-narrative-title" data-project-narrative-title(?:="")?>/),
      "expected Hardware to render its Narrative Title"
    )
    assert_includes html, "Two systems, one very narrow board."
    assert_includes html, '<aside class="project-callout">'
    assert_includes html, "2.45 × 0.73 in"

    assert_includes html, '<ul class="project-people" data-people-source="team">'
    ["Byron Aguilar", "Boning Dong", "Cesar Gonzalez"].each do |name|
      assert_includes html, "<strong>#{name}</strong>"
    end
    assert_equal 3, html.scan("<span>Computer Engineer</span>").length

    refute_includes html, ":::"
    refute_includes html, "source=team"
    %w[project-media-grid project-video-grid project-team-grid project-team-card].each do |class_name|
      refute_includes html, class_name
    end
  end,
  "Scopen follows the five chapter authoring contract" => lambda do
    html = built("projects/scopen.html")

    assert_equal 10, html.scan("data-project-chapter-link").length
    {
      "context" => "Context",
      "hardware" => "Hardware",
      "firmware" => "Firmware",
      "software" => "Software",
      "team" => "Team"
    }.each do |id, title|
      assert_includes html, %(data-project-chapter="#{id}")
      assert_equal 2, html.scan(%(href="##{id}" data-project-chapter-link="#{id}")).length
      assert_includes html, title
    end
    assert_includes html, "A lab instrument that fits in your pocket."
    assert_includes html, "Scopen began with a practical frustration"
    assert_includes html, "UCSB Computer Engineering capstone"
    assert_includes html, "analog front end isolates and scales the incoming signal"
    assert_includes html, "2.45 × 0.73 in"
    assert_includes html, "FreeRTOS"
    assert_includes html, "High Resolution Timer triggers the ADCs in hardware"
    assert_includes html, "UDP and TCP connections"
    assert_includes html, "Model View Controller"
    assert_includes html, "Java Swing"
    assert_includes html, "Replace the Java Swing desktop client"
    assert_includes html, "Byron Aguilar"
    assert_includes html, "Professor Yogananda Isukapalli"
    refute_includes html, "# Concep"
    refute_includes html, 'class="row justify-content-center"'
    refute_includes html, "—"
  end,
  "default project detail Hero uses the approved 3 to 1 asset" => lambda do
    path = File.join(
      ROOT,
      "assets/img/showcase/project-detail-defaults/night-instrument-expanded.png"
    )
    assert(File.file?(path), "expected approved Hero asset")
    signature, width, height = File.binread(path, 24).unpack("A8x8NN")

    assert_equal "\x89PNG\r\n\x1A\n".b, signature.b
    assert_equal [3840, 1280], [width, height]
  end
}

passed = 0
tests.each do |name, test|
  test.call
  puts "PASS #{name}"
  passed += 1
rescue StandardError => error
  warn "FAIL #{name}: #{error.message}"
end

failed = tests.length - passed
puts "#{passed} passed, #{failed} failed"
exit(failed.zero? ? 0 : 1)
