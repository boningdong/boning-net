require "date"
require "fileutils"
require "tmpdir"
require "yaml"

ROOT = File.expand_path("..", __dir__)

RETIRED_PATHS = %w[
  _layouts/project-post.html
  _layouts/default.html
  _includes/header.html
].freeze

RETIRED_PATH_FAMILIES = {
  "showcase includes" => "_includes/showcase/**/*",
  "showcase stylesheet entries" => "assets/css/showcase/**/*",
  "showcase Sass partials" => "_sass/showcase/**/*"
}.freeze

LEGACY_SOURCE_PATTERNS = {
  "project-post layout" => /(?:^|\n)[ \t]*layout:[ \t]*["']?project-post["']?[ \t]*(?:#.*)?(?:\n|\z)/,
  "default layout" => /(?:^|\n)[ \t]*layout:[ \t]*["']?default["']?[ \t]*(?:#.*)?(?:\n|\z)/,
  "project-post Liquid branch" => /(?:page\.layout[^\n]*["']project-post["']|["']project-post["'][^\n]*page\.layout)/,
  "default Liquid branch" => /(?:page\.layout[^\n]*["']default["']|["']default["'][^\n]*page\.layout)/,
  "showcase include" => /\{%[ \t]*include[ \t]+showcase\//,
  "showcase stylesheet" => %r{(?:/)?assets/css/showcase/|@(?:use|import)[ \t]+["'][^"']*showcase/},
  "Bootstrap dependency" => /(?:bootstrap(?:\.min)?\.(?:css|js)|bootstrapcdn|@(?:use|import)[ \t]+["'][^"']*bootstrap)/i,
  "jQuery dependency" => /(?:jquery(?:-[\d.]+)?(?:\.min)?\.js|code\.jquery\.com|@(?:use|import)[ \t]+["'][^"']*jquery)/i,
  "Popper dependency" => /(?:popper(?:\.min)?\.js|cdnjs\.cloudflare\.com\/ajax\/libs\/popper|@(?:use|import)[ \t]+["'][^"']*popper)/i,
  "project posts stylesheet" => /project-posts\.css/
}.freeze

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

def production_source_paths(root = ROOT)
  config = YAML.safe_load(File.read(File.join(root, "_config.yml")), permitted_classes: [Date, Time], aliases: true)
  collection_names = config.fetch("collections", {}).keys
  excluded_root_files = config.fetch("exclude", []).select { |path| !path.include?("/") }
  source_paths = Dir[File.join(root, "*.{html,md,markdown}")]
  source_paths.reject! { |path| excluded_root_files.include?(File.basename(path)) }
  source_paths.concat(Dir[File.join(root, "_layouts", "**", "*.{html,md,markdown}")])
  source_paths.concat(Dir[File.join(root, "_includes", "**", "*.{html,liquid,md,markdown}")])
  source_paths.concat(Dir[File.join(root, "_plugins", "**", "*.{rb,html,liquid}")])
  source_paths.concat(Dir[File.join(root, "_data", "**", "*.{yml,yaml,json}")])
  source_paths.concat(Dir[File.join(root, "_sass", "**", "*.{scss,sass,css}")])
  source_paths.concat(Dir[File.join(root, "assets", "css", "**", "*.{scss,sass,css}")])
  source_paths.concat(Dir[File.join(root, "assets", "js", "**", "*.{js,mjs,cjs}")])
  source_paths << File.join(root, "_config.yml")
  collection_names.each do |collection_name|
    source_paths.concat(Dir[File.join(root, "_#{collection_name}", "**", "*.{html,md,markdown}")])
  end
  source_paths.select { |path| File.file?(path) }.sort.uniq
end

def frontmatter_layout(path)
  source = File.read(path)
  match = source.match(/\A---[ \t]*\r?\n(?<frontmatter>.*?)^---[ \t]*\r?\n/m)
  return unless match

  frontmatter = YAML.safe_load(match[:frontmatter], permitted_classes: [Date, Time], aliases: true) || {}
  frontmatter.fetch("layout", nil)
end

def legacy_source_references(path)
  source = File.read(path)
  LEGACY_SOURCE_PATTERNS.filter_map do |name, pattern|
    name if source.match?(pattern)
  end
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
      assert(legacy_source_references(path).empty?, "expected prose not to create a legacy source reference")

      empty_frontmatter_path = File.join(directory, "empty-frontmatter.scss")
      File.write(empty_frontmatter_path, "---\n---\n.page { color: inherit; }\n")
      assert(frontmatter_layout(empty_frontmatter_path).nil?, "expected empty frontmatter to have no layout")
    end
  end,
  "production source graph excludes historical design prose" => lambda do
    Dir.mktmpdir("production-source-graph") do |source_root|
      historical_path = File.join(source_root, "docs", "designs", "historical-note.md")
      include_path = File.join(source_root, "_includes", "active.html")
      FileUtils.mkdir_p(File.dirname(historical_path))
      FileUtils.mkdir_p(File.dirname(include_path))
      File.write(File.join(source_root, "_config.yml"), "collections: {}\nexclude: []\n")
      File.write(historical_path, %({% if page.layout == "default" %}\nHistorical design note.\n{% endif %}\n))
      File.write(include_path, "<main>Active production include</main>\n")

      source_paths = production_source_paths(source_root)
      assert(source_paths.include?(include_path), "expected active includes in the production graph")
      refute(source_paths.include?(historical_path), "expected historical design prose outside the production graph")
    end
  end,
  "legacy source matcher recognizes retired layout Liquid branches" => lambda do
    cases = {
      "left-hand double quotes" => ['{% if page.layout == "default" %}', true],
      "left-hand single quotes" => ["{%if page.layout=='default'%}", true],
      "left-hand spaced comparison" => ["{% if page.layout    ==    'default' %}", true],
      "right-hand double quotes" => ['{% if "default" == page.layout %}', true],
      "right-hand single quotes" => ["{%if'default'==page.layout%}", true],
      "project-post left-hand double quotes" => ['{% if page.layout == "project-post" %}', true],
      "project-post left-hand single quotes" => ["{%if page.layout=='project-post'%}", true],
      "project-post left-hand spaced comparison" => ["{% if page.layout    ==    'project-post' %}", true],
      "project-post right-hand double quotes" => ['{% if "project-post" == page.layout %}', true],
      "project-post right-hand single quotes" => ["{%if'project-post'==page.layout%}", true],
      "generic default prose" => ["Use the default configuration for new project pages.", false],
      "generic project-post prose" => ["The project-post migration is documented elsewhere.", false]
    }

    Dir.mktmpdir("legacy-layout-matcher") do |directory|
      cases.each do |name, (source, expected_match)|
        path = File.join(directory, "#{name.tr(' ', '-')}.html")
        File.write(path, "#{source}\n")
        references = legacy_source_references(path)
        actual_match = references.include?("default Liquid branch") || references.include?("project-post Liquid branch")
        assert(actual_match == expected_match, "expected #{name} to match=#{expected_match}, got #{actual_match}")
      end
    end
  end,
  "production source retires the legacy project page stack" => lambda do
    RETIRED_PATHS.each do |path|
      refute File.exist?(File.join(ROOT, path)), "expected #{path} to be retired"
    end

    RETIRED_PATH_FAMILIES.each do |family, pattern|
      matches = Dir[File.join(ROOT, pattern)].select { |path| File.file?(path) }
      assert(matches.empty?, "expected retired #{family} to be absent: #{matches.join(", ")}")
    end

    references = production_source_paths.flat_map do |path|
      layout = frontmatter_layout(path)
      matches = legacy_source_references(path)
      matches << "frontmatter layout #{layout.inspect}" if %w[default project-post].include?(layout)
      matches.map { |match| "#{path.delete_prefix("#{ROOT}/")}: #{match}" }
    end
    assert(references.empty?, "expected no production references to the retired project stack: #{references.join(", ")}")
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
  "homepage defaults to Artwork and keeps disabled Notes out of the page" => lambda do
    html = built("index.html")
    hero_html = html[0..html.index("</header>")]
    artwork_tab_position = html.index('id="artwork-tab"')
    projects_tab_position = html.index('id="projects-tab"')

    assert_includes html, "Explore with wonder"
    assert_includes html, "Create with care"
    assert_includes html, "Engineering"
    assert_includes html, "Art"
    assert_includes hero_html, "<span>Notes</span>"
    assert_includes html, "Engineer, Programmer, Artist"
    assert_includes html, "I now work as an engineer in Silicon Valley."
    assert_includes html, 'class="work-switcher"'
    assert(html.scan('class="work-tab').length == 2, "expected Projects and Artwork work tabs")
    assert(artwork_tab_position && projects_tab_position && artwork_tab_position < projects_tab_position, "expected Artwork before Projects")
    assert_includes html, 'class="work-tab active" id="artwork-tab" type="button" role="tab" aria-selected="true"'
    assert_includes html, 'class="work-panel active" id="artwork-panel" role="tabpanel" aria-labelledby="artwork-tab"'
    refute_includes html, 'class="home-notes design-section"'
    assert_includes html, "03 / 03"
    assert_includes html, 'class="text-link" href="/resume.html">View all experiences</a>'
    assert_includes html, 'class="portrait" src="/assets/img/index/me.jpeg"'
    assert File.file?(File.join(ROOT, "assets/img/index/me.jpeg")), "expected the new square portrait asset"
    refute_includes html, "As engineers, we were going to be in a position to change the world"
  end,
  "homepage renders configured selected work in declared order" => lambda do
    html = built("index.html")
    artwork_start = html.index('id="artwork-panel"')
    projects_start = html.index('id="projects-panel"')
    artwork_html = html[artwork_start...projects_start]
    projects_html = html[projects_start..]

    assert(artwork_html.scan('class="portfolio-item').length == 3, "expected three selected Artwork cards")
    assert(projects_html.scan('class="portfolio-item').length == 3, "expected three selected Project cards")

    artwork_titles = ["Snow Scene", "The Elder Scroll V", "Watercolor Scenery"]
    artwork_positions = artwork_titles.map { |title| artwork_html.index("<strong>#{title}</strong>") }
    assert(artwork_positions.all? && artwork_positions == artwork_positions.sort, "expected configured Artwork order")
    artwork_meta = artwork_html.scan(/<div class="portfolio-meta">.*?<\/a>/m)
    assert(artwork_meta.length == 3 && artwork_meta.none? { |card| card.include?("<span>") }, "expected Artwork cards to omit subtitles")

    project_titles = ["Scopen", "AR Domino", "Smart Lamp"]
    project_positions = project_titles.map { |title| projects_html.index("<strong>#{title}</strong>") }
    assert(project_positions.all? && project_positions == project_positions.sort, "expected configured Project order")
    project_meta = projects_html.scan(/<div class="portfolio-meta">.*?<\/a>/m)
    assert(project_meta.length == 3 && project_meta.none? { |card| card.include?("<span>") }, "expected Project cards to omit subtitles")
    assert_includes projects_html, "/generated/assets/img/projects/scopen/cover-logo-flat-v2-"
    assert_includes projects_html, "/generated/assets/img/projects/smartlamp/cover-product-cool-v3-"
  end,
  "Projects page is collection backed" => lambda do
    html = built("projects.html")
    hero_html = html[0..html.index("</header>")]

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
    assert_includes hero_html, '<span class="projects-hero-index">2016—2022</span>'
    refute_includes hero_html, "Selected work /"
  end,
  "Artwork page uses the modern collection-backed shell" => lambda do
    html = built("artwork.html")

    assert_includes html, '<body class="modern-page artwork-page">'
    assert_includes html, '/assets/css/main.css'
    assert_includes html, 'data-navigation'
    assert_includes html, 'href="/artwork.html" class="active" aria-current="page">Artwork</a>'
    assert_includes html, 'data-artwork-page'
    assert(html.scan("data-collection-artwork-card").length == 15, "expected 15 collection-backed artwork cards")
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
    assert_includes hero_html, '<span class="artwork-hero-index">2015—2026</span>'
    refute_includes hero_html, "works /"
    assert(highlights_position && collection_position && highlights_position < collection_position, "expected Highlights before The Collection")
    assert(html.scan('data-highlight-artwork-card').length == 5, "expected five interactive Highlights cards")
    assert(html.scan('data-highlight-artwork-duplicate').length == 10, "expected previous and next duplicate sets around the interactive cards")
    assert(html.scan('data-highlight-artwork-duplicate aria-hidden="true"').length == 10, "expected every duplicated rail card to be hidden from assistive technology")
    assert(html.scan('data-highlight-artwork-copy="previous"').length == 5, "expected five previous-cycle cards")
    assert(html.scan('data-highlight-artwork-copy="next"').length == 5, "expected five next-cycle cards")
    previous_cycle_position = html.index('data-highlight-artwork-copy="previous"')
    original_cycle_position = html.index('data-highlight-artwork-card')
    next_cycle_position = html.index('data-highlight-artwork-copy="next"')
    assert(previous_cycle_position < original_cycle_position && original_cycle_position < next_cycle_position, "expected previous, interactive, and next rail cycles in order")
    assert_includes html, '<div class="artwork-rail-shell" data-artwork-rail-shell>'
    assert_includes html, '<div class="artwork-collection-grid" data-artwork-collection-grid>'
    shell_position = html.index('data-artwork-rail-shell')
    rail_position = html.index('data-artwork-rail tabindex="0"')
    track_position = html.index('data-artwork-track')
    assert(shell_position < rail_position && rail_position < track_position, "expected shell to wrap the accessible rail and track")
    assert_includes html, 'role="region" aria-label="Highlighted artwork"'
    assert_includes html, "Snow Scene"
    assert_includes html, "Terminator"
    assert_includes html, "Watercolor Scenery"
    assert_includes highlights_html, "Forest Sunset II"
    assert_includes highlights_html, "The Elder Scroll V"
    refute_includes highlights_html, "Captain America"
    refute_includes highlights_html, 'loading="lazy"'
    assert_includes html[collection_position..], 'loading="lazy"'
  end,
  "Artwork filters and viewer expose accessible state" => lambda do
    html = built("artwork.html")
    filter_source = File.read(File.join(ROOT, "_includes/pages/artwork/filters.html"))

    assert_includes html, 'role="group" aria-label="Filter artwork by medium"'
    assert(html.scan('data-artwork-filter').length == 6, "expected six medium filters")
    assert_includes html, 'data-filter="all" aria-pressed="true"'
    assert_includes html, 'data-filter="oil-pastel" aria-pressed="false">Oil Pastel</button>'
    assert_includes html, 'data-filter="pen-drawing" aria-pressed="false">Pen Drawing</button>'
    assert_includes html, 'data-medium="oil-pastel" data-full="/assets/img/artwork/jellyfish.jpg" data-title="Jellyfish" data-meta="Oil Pastel · 2024"'
    assert_includes html, '<span>Oil Pastel<br>2024</span>'
    assert_includes html, 'data-medium="pen-drawing" data-full="/assets/img/artwork/sf_streetview.jpg" data-title="SF Street View" data-meta="Pen Drawing · 2025"'
    assert_includes html, '<span>Pen Drawing<br>2025</span>'
    assert_includes html, 'data-medium="oil-pastel" data-full="/assets/img/artwork/forest_sunset.jpg" data-title="Forest Sunset" data-meta="Oil Pastel · 2026"'
    assert_includes html, '<span>Oil Pastel<br>2026</span>'
    assert_includes html, 'data-medium="oil-pastel" data-full="/assets/img/artwork/lake_sunset_view.jpg" data-title="Lake Sunset View" data-meta="Oil Pastel · 2026"'
    assert_includes html, 'data-medium="oil-pastel" data-full="/assets/img/artwork/forest_sunset_2.jpg" data-title="Forest Sunset II" data-meta="Oil Pastel · 2026"'
    assert_includes html, 'role="status" aria-live="polite"'
    assert_includes html, '<dialog class="artwork-viewer" id="artwork-viewer"'
    assert_includes html, 'aria-labelledby="artwork-viewer-title"'
    assert_includes html, 'aria-describedby="artwork-viewer-description"'
    assert_includes html, 'data-artwork-viewer-image'
    assert_includes html, 'data-artwork-viewer-close>Close viewer</button>'
    refute_includes html, '<img src=""'
    assert_includes filter_source, 'site.tags | sort: "filter-order"'
    assert_includes filter_source, "artwork.tags contains tag.tag-id"
    %w[pencil charcoal watercolor].each do |tag_id|
      assert File.file?(File.join(ROOT, "_tags", "#{tag_id}.md")), "expected #{tag_id} in the shared tag registry"
    end
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
    assert_includes css, ".artwork-collection-grid{--artwork-collection-gap: var(--card-gap);display:grid;grid-template-columns:repeat(var(--artwork-collection-columns), minmax(0, 1fr));gap:var(--artwork-collection-gap)}"
    assert_includes css, ".artwork-collection-grid.is-masonry-ready{position:relative;display:block}"
    assert_includes css, ".artwork-collection-grid.is-masonry-ready .artwork-collection-card{position:absolute;top:0;left:0;margin:0;transition:transform 280ms ease}"
    assert_includes css, ".artwork-collection-card .artwork-card-media,.artwork-collection-card img{width:100%;height:auto}"
    assert_includes css, "@media(max-width: 850px){.artwork-page{--artwork-collection-columns: 2}"
    assert_includes css, "@media(max-width: 640px){.artwork-page{--artwork-collection-columns: 1}"
    assert_includes css, ".artwork-collection-grid{--artwork-collection-gap: var(--mobile-card-gap);gap:var(--artwork-collection-gap)}"
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
    hero_html = html[0..html.index("</header>")]
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
    assert_includes hero_html, '<span class="experiences-hero-index">2017—Now</span>'
    refute_includes hero_html, "Career archive /"
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
