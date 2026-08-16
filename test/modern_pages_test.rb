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

def built(path)
  full_path = File.join(ROOT, "_site", path)
  assert(File.file?(full_path), "expected generated file #{path}")
  File.read(full_path)
end

tests = {
  "homepage uses the dependency-free modern shell" => lambda do
    html = built("index.html")

    assert_includes html, '<body class="modern-page home-page">'
    assert_includes html, '/assets/css/main.css'
    assert_includes html, 'data-navigation'
    assert_includes html, 'data-home-tabs'
    assert_includes html, '/assets/img/index/banner.jpg'
    refute_includes html, 'bootstrap.min.css'
    refute_includes html, 'jquery'
  end,
  "modern shell versions browser assets per build" => lambda do
    html = built("index.html")
    asset_urls = html.scan(%r{(?:href|src)="([^"]+(?:main\.css|navigation\.js|home\.js)[^"]*)"}).flatten

    assert(asset_urls.length == 3, "expected the modern stylesheet and two scripts")
    assert(asset_urls.all? { |url| url.match?(%r{\?v=\d+\z}) }, "expected every modern asset URL to include a build version")
    assert(asset_urls.map { |url| url.split("?v=").last }.uniq.length == 1, "expected one build version across modern assets")
  end,
  "homepage renders the revised copy and preview Notes section" => lambda do
    html = built("index.html")

    assert_includes html, "Explore with wonder"
    assert_includes html, "Create with care"
    assert_includes html, "Engineering"
    assert_includes html, "Art"
    assert_includes html, "Notes"
    assert_includes html, "Engineer, Programmer, Artist"
    assert_includes html, "I now work as an engineer in Silicon Valley."
    assert_includes html, 'class="work-switcher"'
    assert(html.scan('class="work-tab').length == 2, "expected Projects and Artwork work tabs")
    assert_includes html, 'class="home-notes design-section"'
    assert_includes html, "04 / 04"
    refute_includes html, "As engineers, we were going to be in a position to change the world"
  end,
  "Projects page is collection backed" => lambda do
    html = built("projects.html")

    assert(html.scan("data-project-card").length == 12, "expected 12 collection-backed project cards")
    assert_includes html, 'data-project-filters'
    assert_includes html, 'data-tags="hardware system-design firmware embedded c pcb java"'
    assert_includes html, 'href="/projects/scopen"'
    assert_includes html, '/assets/img/projects/scopen_cover.png'
  end,
  "modern pages omit mock paths and design-lab tools" => lambda do
    html = [built("index.html"), built("projects.html")].join("\n")

    refute_includes html, "/files/"
    assert(!html.match?(/>Tune<|Import JSON|Export JSON|Save default|Reset tuning/), "expected no design-lab controls")
  end
}

failures = []
tests.each do |name, test|
  test.call
  puts "PASS #{name}"
rescue AssertionFailure => error
  failures << [name, error.message]
  warn "FAIL #{name}: #{error.message}"
end

puts "#{tests.length - failures.length} passed, #{failures.length} failed"
exit(failures.empty? ? 0 : 1)
