# frozen_string_literal: true

require "open3"
require "rbconfig"

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
