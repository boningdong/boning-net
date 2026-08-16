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
  "Artwork page uses the modern collection-backed shell" => lambda do
    html = built("artwork.html")

    assert_includes html, '<body class="modern-page artwork-page">'
    assert_includes html, '/assets/css/main.css'
    assert_includes html, 'data-navigation'
    assert_includes html, 'href="/artwork.html" class="active" aria-current="page">Artwork</a>'
    assert_includes html, 'data-artwork-page'
    assert(html.scan("data-collection-artwork-card").length == 10, "expected 10 collection-backed artwork cards")
    assert_includes html, 'data-full="/assets/img/artwork/snow_scene.jpg"'
    refute_includes html, 'masonry.pkgd.min.js'
    refute_includes html, 'bootstrap.min.css'
    refute_includes html, 'jquery'
  end,
  "Artwork page preserves the approved hierarchy and content data" => lambda do
    html = built("artwork.html")
    highlights_position = html.index('id="artwork-highlights-title"')
    collection_position = html.index('id="artwork-collection-title"')
    highlights_html = html[highlights_position...collection_position]

    assert_includes html, "Artwork</span>"
    assert_includes html, "Studies in light &amp; character"
    assert_includes html, "Graphite"
    assert_includes html, "Charcoal"
    assert_includes html, "Watercolor"
    assert_includes html, "10 works / 2015—2020"
    assert(highlights_position && collection_position && highlights_position < collection_position, "expected Highlights before The Collection")
    assert(html.scan('data-highlight-artwork-card').length == 4, "expected four interactive Highlights cards")
    assert(html.scan('data-highlight-artwork-duplicate').length == 8, "expected previous and next duplicate sets around the interactive cards")
    assert(html.scan('data-highlight-artwork-duplicate aria-hidden="true"').length == 8, "expected every duplicated rail card to be hidden from assistive technology")
    assert(html.scan('data-highlight-artwork-copy="previous"').length == 4, "expected four previous-cycle cards")
    assert(html.scan('data-highlight-artwork-copy="next"').length == 4, "expected four next-cycle cards")
    previous_cycle_position = html.index('data-highlight-artwork-copy="previous"')
    original_cycle_position = html.index('data-highlight-artwork-card')
    next_cycle_position = html.index('data-highlight-artwork-copy="next"')
    assert(previous_cycle_position < original_cycle_position && original_cycle_position < next_cycle_position, "expected previous, interactive, and next rail cycles in order")
    assert_includes html, '<div class="artwork-rail-shell" data-artwork-rail-shell>'
    shell_position = html.index('data-artwork-rail-shell')
    rail_position = html.index('data-artwork-rail tabindex="0"')
    track_position = html.index('data-artwork-track')
    assert(shell_position < rail_position && rail_position < track_position, "expected shell to wrap the accessible rail and track")
    assert_includes html, 'role="region" aria-label="Highlighted artwork"'
    assert_includes html, "Snow Scene"
    assert_includes html, "Terminator"
    assert_includes html, "Watercolor Scenery"
    assert_includes html, "Captain America"
    refute_includes highlights_html, 'loading="lazy"'
    assert_includes html[collection_position..], 'loading="lazy"'
  end,
  "Artwork filters and viewer expose accessible state" => lambda do
    html = built("artwork.html")

    assert_includes html, 'role="group" aria-label="Filter artwork by medium"'
    assert(html.scan('data-artwork-filter').length == 4, "expected four medium filters")
    assert_includes html, 'data-filter="all" aria-pressed="true"'
    assert_includes html, 'role="status" aria-live="polite"'
    assert_includes html, '<dialog class="artwork-viewer" id="artwork-viewer"'
    assert_includes html, 'aria-labelledby="artwork-viewer-title"'
    assert_includes html, 'aria-describedby="artwork-viewer-description"'
    assert_includes html, 'data-artwork-viewer-image'
    assert_includes html, 'data-artwork-viewer-close>Close viewer</button>'
    refute_includes html, '<img src=""'
  end,
  "Artwork visual module is compiled into the modern stylesheet" => lambda do
    css = built("assets/css/main.css")

    assert_includes css, ".artwork-page"
    assert_includes css, ".artwork-rail-card"
    assert_includes css, ".artwork-rail{position:relative;width:100%;overflow-x:hidden"
    assert_includes css, "padding:12px 0 80px;margin-bottom:-46px"
    assert_includes css, ".artwork-rail::-webkit-scrollbar{display:none}"
    assert_includes css, ".artwork-rail:focus-visible"
    assert_includes css, ".artwork-rail-shell::before,.artwork-rail-shell::after{position:absolute;z-index:1;top:0;bottom:0;width:clamp(72px,10vw,168px);content:\"\";pointer-events:none}"
    assert_includes css, ".artwork-rail-shell::before{left:0;background:linear-gradient(90deg, var(--mist), transparent)}"
    assert_includes css, ".artwork-rail-shell::after{right:0;background:linear-gradient(270deg, var(--mist), transparent)}"
    assert_includes css, ".artwork-rail-track{display:flex;visibility:hidden"
    assert_includes css, "padding-inline:max(clamp(72px,10vw,168px),(100vw - 1120px)/2)"
    assert_includes css, ".artwork-rail-track{gap:var(--mobile-card-gap);padding-inline:56px}"
    assert_includes css, ".artwork-rail[data-artwork-rail-ready] .artwork-rail-track{visibility:visible}"
    assert_includes css, "@media(prefers-reduced-motion: reduce){.artwork-rail{overflow-x:auto;touch-action:pan-x pan-y}}"
    assert_includes css, "@media(forced-colors: active){.artwork-rail:focus-visible{outline:2px solid CanvasText;outline-offset:-2px;background:none}}"
    assert_includes css, ".artwork-collection-grid"
    assert_includes css, ".artwork-viewer"
  end,
  "modern pages omit mock paths and design-lab tools" => lambda do
    html = [built("index.html"), built("projects.html"), built("artwork.html")].join("\n")

    refute_includes html, "/files/"
    assert(!html.match?(/>Tune<|Tune Artwork|Import JSON|Export JSON|View JSON|Download JSON|Save default|Reset tuning/), "expected no design-lab controls")
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
