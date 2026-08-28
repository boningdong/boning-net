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

    # Task 9 reverses these assertions once Scopen no longer renders the legacy contract.
    %w[.project-media-grid .project-video-grid .project-team-grid].each do |selector|
      assert_includes css, selector
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

    assert_selector_follows(css, ".project-media img{", ".project-main img{")
    assert_selector_follows(css, ".project-team-card img{", ".project-main img{")
    assert_selector_follows(css, ".project-team-card h3{", ".project-main h3{")
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
    assert_includes html, "/assets/img/showcase/project-detail-defaults/night-instrument-expanded.png"
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
    assert_includes css, ".project-media-grid"
    assert_includes css, "object-fit:cover"
    assert_includes css, "backdrop-filter:blur"
    assert(
      css.match?(/\.project-media\{[^}]*margin:0/),
      "expected project media figures to reset the browser margin"
    )
  end,
  "Scopen follows the five chapter authoring contract" => lambda do
    html = built("projects/scopen.html")

    assert_equal 10, html.scan("data-project-chapter-link").length
    %w[context hardware firmware software team].each do |id|
      assert_includes html, %(data-project-chapter="#{id}")
    end
    assert_includes html, "A lab instrument that fits in your pocket."
    assert_includes html, "2.45 × 0.73 in"
    assert_includes html, "FreeRTOS"
    assert_includes html, "Java Swing"
    assert_includes html, "Byron Aguilar"
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
