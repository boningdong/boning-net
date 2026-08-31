require "date"
require "tmpdir"
require "yaml"

ROOT = File.expand_path("..", __dir__)

class AssertionFailure < StandardError; end

def assert(condition, message)
  raise AssertionFailure, message unless condition
end

def refute(condition, message)
  assert(!condition, message)
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

def production_page_and_layout_sources
  config = YAML.safe_load(File.read(File.join(ROOT, "_config.yml")), permitted_classes: [Date, Time], aliases: true)
  collection_names = config.fetch("collections", {}).keys
  source_paths = Dir[File.join(ROOT, "*.{html,md,markdown}")]
  source_paths.concat(Dir[File.join(ROOT, "_layouts", "**", "*.html")])
  collection_names.each do |collection_name|
    source_paths.concat(Dir[File.join(ROOT, "_#{collection_name}", "**", "*.{html,md,markdown}")])
  end
  source_paths.sort
end

def frontmatter_layout(path)
  source = File.read(path)
  match = source.match(/\A---[ \t]*\r?\n(?<frontmatter>.*?)^---[ \t]*\r?\n/m)
  return unless match

  YAML.safe_load(match[:frontmatter], permitted_classes: [Date, Time], aliases: true).fetch("layout", nil)
end

tests = {
  "legacy layout scan reads YAML frontmatter without matching prose" => lambda do
    Dir.mktmpdir("legacy-layout-guard") do |directory|
      path = File.join(directory, "fixture.md")
      File.write(
        path,
        <<~MARKDOWN
          ---
          layout: project-detail
          summary: |
            The retired layout: project-post is mentioned here as prose.
          ---

          The project detail layout is the active contract.
        MARKDOWN
      )

      assert(frontmatter_layout(path) == "project-detail", "expected only the YAML layout field to be read")
    end
  end,
  "production source retires the legacy project page stack" => lambda do
    %w[_layouts/project-post.html _layouts/default.html _includes/header.html].each do |path|
      refute File.exist?(File.join(ROOT, path)), "expected #{path} to be retired"
    end

    production_page_and_layout_sources.each do |path|
      layout = frontmatter_layout(path)
      refute %w[default project-post].include?(layout), "expected #{path} not to use retired layout #{layout.inspect}"
    end
  end,
  "homepage uses the dependency-free modern shell" => lambda do
    html = built("index.html")

    assert_includes html, '<body class="modern-page home-page">'
    assert_includes html, '/assets/css/main.css'
    assert_includes html, 'data-navigation'
    assert_includes html, 'data-home-tabs'
    assert_includes html, '/assets/img/index/banner-hd-v2.jpg'
    refute_includes html, '/assets/img/index/banner.jpg'
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

    assert_includes html, "Projects</span>"
    assert_includes html, "Ideas made tangible"
    assert_includes html, "Hardware"
    assert_includes html, "Software"
    assert_includes html, "Experiments"
    assert_includes html, 'class="projects-hero-separator" aria-hidden="true">-</span>'
    assert(html.scan("data-project-card").length == 12, "expected 12 collection-backed project cards")
    assert_includes html, 'data-project-filters'
    assert_includes html, 'data-tags="hardware system-design firmware embedded c pcb java"'
    assert_includes html, 'href="/projects/scopen"'
    assert_includes html, '/generated/assets/img/projects/scopen/cover-'
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
    hero_html = html[0..html.index("</header>")]
    highlights_position = html.index('id="artwork-highlights-title"')
    collection_position = html.index('id="artwork-collection-title"')
    highlights_html = html[highlights_position...collection_position]

    assert_includes html, "Artwork</span>"
    assert_includes html, "The world as I see it"
    assert_includes html, "Drawing"
    assert_includes html, "Painting"
    assert_includes html, "Mixed media"
    assert_includes html, 'class="artwork-hero-separator" aria-hidden="true">-</span>'
    refute_includes hero_html, "Studies in light &amp; character"
    refute_includes hero_html, "Graphite"
    refute_includes hero_html, "Charcoal"
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
    assert_includes css, ".artwork-page{--artwork-highlight-height: 330px;--artwork-collection-columns: 3"
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
    assert_includes css, ".artwork-collection-grid{columns:var(--artwork-collection-columns);column-gap:var(--card-gap)}"
    assert_includes css, ".artwork-collection-card .artwork-card-media,.artwork-collection-card img{width:100%;height:auto}"
    assert_includes css, "@media(max-width: 850px){.artwork-page{--artwork-collection-columns: 2}"
    assert_includes css, "@media(max-width: 640px){.artwork-page{--artwork-collection-columns: 1}"
    assert_includes css, ".artwork-collection-grid{column-gap:var(--mobile-card-gap)}"
    assert_includes css, "@media(prefers-reduced-motion: reduce){.artwork-rail{overflow-x:auto;touch-action:pan-x pan-y}}"
    assert_includes css, "@media(forced-colors: active){.artwork-rail:focus-visible{outline:2px solid CanvasText;outline-offset:-2px;background:none}}"
    assert_includes css, ".artwork-viewer"
  end,
  "Experiences page uses the modern collection-backed shell" => lambda do
    html = built("resume.html")

    assert_includes html, '<body class="modern-page experiences-page">'
    assert_includes html, 'href="/resume.html" class="active" aria-current="page">Experiences</a>'
    assert_includes html, "/assets/js/pages/experiences.js"
    assert(html.scan("data-experience-card").length == 5, "expected five visible work entries")
    assert(html.scan("data-education-card").length == 2, "expected two education entries")
    refute_includes html, "bootstrap.min.css"
    refute_includes html, "jquery"
  end,
  "Experiences page preserves the approved hierarchy and readable details" => lambda do
    html = built("resume.html")
    work_position = html.index('id="work-experience-title"')
    education_position = html.index('id="education-title"')
    role_cards = html.scan(/<article class="role-card is-open" data-experience-card>(.*?)<\/article>/m).flatten
    apple_description = "Work under Apple Core OS Embedded Sensors team to support software development work for various Apple products, including iPhone iPad, Mac, etc."
    apple_summary, apple_details = role_cards.first.split('<div class="role-details"', 2)
    rendered_roles = role_cards.map do |card|
      company = card[/<span class="role-company">([^<]+)<\/span>/, 1]
      date = card[/<span class="role-date">([^<]+)<\/span>/, 1]
      [company, date]
    end
    expected_roles = [
      ["Apple", "Aug 2021—Now"],
      ["Microsoft", "Jun 2020—Sep 2020"],
      ["Microsoft", "Jun 2019—Sep 2019"],
      ["Karl Storz", "Jun 2018—Dec 2018"],
      ["Transphorm", "Jul 2017—Sep 2017"]
    ]
    relationships = html.scan(/<button class="role-toggle" id="([^"]+)"[^>]*aria-controls="([^"]+)"/)

    assert_includes html, "Experiences</span>"
    assert_includes html, "The journey so far"
    assert_includes html, "Education"
    assert_includes html, "Career"
    assert_includes html, "Growth"
    assert_includes html, 'class="experiences-hero-separator" aria-hidden="true">-</span>'
    refute_includes html, "Embedded systems"
    refute_includes html, "Product craft"
    assert(work_position && education_position && work_position < education_position, "expected Work Experience before Education")
    assert(rendered_roles == expected_roles, "expected complete reverse chronological work order")
    assert(relationships.length == 5, "expected five accordion trigger relationships")
    assert(relationships.flatten.uniq.length == 10, "expected unique accordion trigger and panel IDs")
    relationships.each do |trigger_id, panel_id|
      assert_includes html, "id=\"#{panel_id}\" role=\"region\" aria-labelledby=\"#{trigger_id}\""
    end
    assert_includes apple_summary, %(<p class="role-description">#{apple_description}</p>)
    assert_includes apple_details, %(<p class="role-detail-description">#{apple_description}</p>)
    refute_includes apple_summary, "Support SoC bringups and driver integrations"
    assert_includes apple_details, "Support SoC bringups and driver integrations"
    assert_includes html, "Master’s degree"
    assert_includes html, "Bachelor’s degree"
    assert_includes html, "GPA 3.88"
    assert_includes html, "GPA 3.95"
    refute_includes html, "IEEE Student Branch"
    assert_includes html, 'aria-expanded="true"'
    assert_includes html, 'aria-controls="experience-details-1"'
    assert_includes html, 'id="experience-details-1"'
    refute_includes html, "Microsof<"
    refute_includes html, "AIRTIST"
    refute_includes html, "Career Path"
    refute_includes html, "Awards"
    refute_includes html, "Tune"
    refute_includes html, "preset"
    refute_includes html, "Detail Dock"
  end,
  "content-list heroes and Experiences timeline compile approved geometry" => lambda do
    css = built("assets/css/main.css")

    assert_includes css, ".experiences-page"
    assert_includes css, "--experience-summary-height: 148px"
    assert_includes css, "--experience-card-gap: 20px"
    assert(css.match?(/\.projects-hero\{[^}]*min-height:400px/), "expected Projects hero to compile at 400px")
    assert(css.match?(/\.artwork-hero\{[^}]*min-height:400px/), "expected Artwork hero to compile at 400px")
    assert(css.match?(/\.experiences-hero\{[^}]*min-height:400px/), "expected Experiences hero to compile at 400px")
    assert_includes css, "top:calc(var(--experience-summary-height)/2 - 10px)"
    assert_includes css, ".role-card:not(:last-child)::after"
    assert_includes css, "bottom:calc(-1*(var(--experience-card-gap) + var(--experience-summary-height)/2))"
    assert_includes css, ".role-card:hover:not(:last-child)::after"
    assert_includes css, ".role-card:has(+.role-card:hover)::after"
    refute_includes css, ".experience-timeline::before{"
  end,
  "modern pages omit mock paths and design-lab tools" => lambda do
    html = [built("index.html"), built("projects.html"), built("artwork.html"), built("resume.html")].join("\n")

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
