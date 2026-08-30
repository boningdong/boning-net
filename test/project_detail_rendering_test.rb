# frozen_string_literal: true

require "fileutils"
require "jekyll"
require "open3"
require "rbconfig"
require "sass-embedded"
require "tmpdir"

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

def render_project_detail_layout(navigation_enabled:, chapters: nil)
  Dir.mktmpdir("project-detail-layout") do |source|
    destination = File.join(source, "_site")
    layouts = File.join(source, "_layouts")
    includes = File.join(source, "_includes/pages/project-detail")
    FileUtils.mkdir_p(layouts)
    FileUtils.mkdir_p(includes)

    FileUtils.cp(
      File.join(ROOT, "_layouts/project-detail.html"),
      File.join(layouts, "project-detail.html")
    )
    %w[hero.html intro.html chapter-navigation.html].each do |include_name|
      FileUtils.cp(
        File.join(ROOT, "_includes/pages/project-detail", include_name),
        File.join(includes, include_name)
      )
    end
    File.write(File.join(layouts, "modern.html"), "---\n---\n{{ content }}\n")

    chapters ||= [{ "id" => "context", "index" => 1, "title" => "Context" }]
    page_data = {
      "layout" => "project-detail",
      "title" => "Layout fixture",
      "project_detail_generated" => {
        "navigation_enabled" => navigation_enabled,
        "chapters" => chapters,
        "blocks" => {},
        "intro_style" => "plain"
      }
    }
    File.write(
      File.join(source, "index.html"),
      page_data.to_yaml + "---\n<section data-project-chapter=\"context\">Context</section>\n"
    )

    config = Jekyll::Configuration.from(
      "source" => source,
      "destination" => destination,
      "quiet" => true,
      "disable_disk_cache" => true
    )
    Jekyll::Site.new(config).process
    File.read(File.join(destination, "index.html"))
  end
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
      '@use "project-detail/primitives/media-frame";',
      '@use "project-detail/components/callout";',
      '@use "project-detail/components/featured-link";',
      '@use "project-detail/components/video-embed";',
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
      .project-video-embed
      .project-people
      .project-narrative-title
      .project-caption
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
      css.match?(/\.project-reading--without-navigation\{grid-template-columns:minmax\(0,\s*1fr\)\}/),
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
  "project detail layout emits the reading modifier only without navigation" => lambda do
    without_navigation = render_project_detail_layout(navigation_enabled: false)
    with_navigation = render_project_detail_layout(navigation_enabled: true)

    assert_includes(
      without_navigation,
      'class="project-reading design-wrap project-reading--without-navigation"'
    )
    refute_includes with_navigation, "project-reading--without-navigation"
    assert_includes with_navigation, 'class="project-reading design-wrap"'
  end,
  "chapter navigation escapes hostile generated metadata at final render boundaries" => lambda do
    hostile_id = 'context" onclick="alert(1)><img src=x onerror=alert(2)>'
    hostile_title = "Context <img src=x onerror=alert(3)>"
    html = render_project_detail_layout(
      navigation_enabled: true,
      chapters: [{ "id" => hostile_id, "index" => 1, "title" => hostile_title }]
    )

    assert_includes html, 'href="#context&quot; onclick=&quot;alert(1)&gt;&lt;img src=x onerror=alert(2)&gt;"'
    assert_includes html, 'data-project-chapter-link="context&quot; onclick=&quot;alert(1)&gt;&lt;img src=x onerror=alert(2)&gt;"'
    assert_includes html, "Context &lt;img src=x onerror=alert(3)&gt;"
    refute_includes html, 'onclick="alert(1)"'
    refute_includes html, "<img src=x onerror=alert(2)>"
    refute_includes html, "<img src=x onerror=alert(3)>"
  end,
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
    assert_includes css, ".project-video-embed"
    assert_includes css, ".project-people"
    assert_includes css, "object-fit:cover"
    assert_includes css, "backdrop-filter:blur"
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
    assert_includes html, "Watch the presentation"
    assert(
      html.index("project-featured-link") < html.index('data-project-chapter="context"'),
      "expected the featured link to render inside Project Intro"
    )

    assert_includes html, 'class="project-video-embed" data-video-embed'
    assert_equal 2, html.scan('class="project-video-embed-item"').length
    assert_includes html, 'src="https://www.youtube-nocookie.com/embed/fFWyjB_XNrE"'
    assert_includes html, 'title="Working prototype demo"'
    assert_includes html, 'src="https://www.youtube-nocookie.com/embed/4xJvWEb1Kwo"'
    assert_includes html, 'title="Rendered product video"'

    refute_includes html, "project-gallery"
    refute_includes html, "project-videos"
    assert_equal 12, html.scan('<figure class="project-figure">').length
    assert_includes html, "Analog front-end architecture"
    assert_includes html, "Bottom side PCB - SRAM, AFE and debug interface"
    refute_includes html, "Product poster"
    refute_includes html, "Assembled product study with probe, controls, and display window"
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
      assert_includes html, ">#{name}<"
    end
    assert_equal 1, html.scan(">Computer Engineer<").length
    assert_equal 2, html.scan(">Electrical Engineer<").length

    refute_includes html, ":::"
    refute_includes html, "source=team"
    %w[project-media-grid project-video-grid project-team-grid project-team-card].each do |class_name|
      refute_includes html, class_name
    end
  end,
  "project figures follow the approved mock caption and glass geometry" => lambda do
    css = built("assets/css/main.css")

    assert(
      css.match?(/\.project-figure\{[^}]*width:100%[^}]*margin:42px 0/),
      "expected standalone figures to fill the Main Content column"
    )
    assert(
      css.match?(/\.project-caption\{[^}]*display:flex[^}]*justify-content:space-between[^}]*gap:20px[^}]*margin-top:12px[^}]*font:500 9px\/1\.45 var\(--font-utility\)[^}]*text-transform:uppercase/),
      "expected the approved edge-aligned utility caption row"
    )
    assert(
      css.match?(/\.project-caption-text\{[^}]*max-width:58ch[^}]*text-align:right/),
      "expected the authored caption to align to the far right"
    )
    assert(
      css.match?(/\.project-media-frame\{[^}]*border:1px solid [^;]+;[^}]*border-radius:var\(--card-radius\)[^}]*box-shadow:[^}]*backdrop-filter:blur\(12px\) saturate\(1\.02\)/),
      "expected the approved glass media surface"
    )
  end,
  "video embeds occupy the same full content width as standalone figures" => lambda do
    css = built("assets/css/main.css")

    assert(
      css.match?(/\.project-main \.project-chapter>\.project-video-embed\{[^}]*width:100%[^}]*max-width:none[^}]*margin:42px 0/),
      "expected Video Embed to override the prose-list width and rhythm caps"
    )
  end,
  "reading width applies only to authored prose and never to component roots" => lambda do
    css = built("assets/css/main.css")

    assert(css.match?(/--project-prose-width:\s*720px/), "expected the Mock reading-width token")
    assert(
      css.match?(/\.project-main \.project-chapter>p,\.project-main \.project-chapter>ul:not\(\[class\]\),\.project-main \.project-chapter>ol:not\(\[class\]\)\{max-width:var\(--project-prose-width\)\}/),
      "expected the Mock reading width to target paragraphs and classless Markdown lists"
    )
    assert(
      !css.include?(".project-main .project-chapter>:where(p,ul,ol){max-width:720px}"),
      "component roots must not inherit a generic prose width cap"
    )
  end,
  "people cards match the compact horizontal mock geometry" => lambda do
    css = built("assets/css/main.css")

    assert(
      css.match?(/\.project-person-card\{[^}]*display:grid[^}]*grid-template-columns:58px minmax\(0,\s*1fr\)[^}]*align-items:center[^}]*gap:15px[^}]*border-radius:18px[^}]*padding:14px/),
      "expected the Mock's compact horizontal member card"
    )
    assert(
      css.match?(/\.project-main \.project-person-card img,[^{]*\{[^}]*width:58px[^}]*height:58px[^}]*aspect-ratio:1[^}]*border-radius:50%/),
      "expected the Mock's 58px circular portraits"
    )
    assert(
      css.match?(/\.project-person-copy\{[^}]*gap:5px[^}]*padding:0[^}]*text-align:left/),
      "expected member copy to align beside the portrait"
    )
    assert(
      css.match?(/\.project-main \.project-chapter>\.project-people\{[^}]*width:100%[^}]*max-width:none/),
      "expected the Team grid to fill the same content rail as the Mock"
    )
  end,
  "project detail subordinate color and mobile scale match the mock" => lambda do
    css = built("assets/css/main.css")

    assert(css.match?(/--ink-faint:\s*#829198/), "expected the Mock's subordinate ink token")
    assert(
      css.match?(/@media\s*\(max-width:\s*640px\)\{[^}]*\.project-main\{font-size:16px;line-height:1\.68/),
      "expected the Mock's mobile reading scale"
    )
    assert(
      css.match?(/@media\s*\(max-width:\s*640px\)\{.*?\.project-media-frame\{[^}]*border-radius:20px/m),
      "expected the Mock's reduced mobile media radius"
    )
  end,
  "callout and featured link follow the approved mock hierarchy" => lambda do
    css = built("assets/css/main.css")

    assert(
      css.match?(/\.project-callout\{[^}]*display:grid[^}]*grid-template-columns:minmax\(180px,\s*0?\.42fr\) minmax\(0,\s*1fr\)[^}]*gap:34px[^}]*margin:38px 0 42px[^}]*padding:10px 0 4px/),
      "expected the unboxed two-column mock callout"
    )
    assert(
      css.match?(/\.project-featured-link\{[^}]*display:inline-flex[^}]*margin-top:28px[^}]*border-bottom:1px solid var\(--steel\)[^}]*font:600 10px\/1 var\(--font-utility\)[^}]*text-transform:uppercase/),
      "expected the compact underlined Intro link"
    )
    assert(
      css.match?(/\.project-intro-copy \.project-featured-link\{[^}]*justify-self:start/),
      "expected the Intro link underline to fit its label"
    )
    assert(
      !css.match?(/\.project-featured-link\{[^}]*background:var\(--ink\)/),
      "featured link must not render as a dark CTA card"
    )
  end,
  "Scopen follows the revised six chapter narrative contract" => lambda do
    html = built("projects/scopen.html")

    assert_equal 12, html.scan("data-project-chapter-link").length
    {
      "context" => "Context",
      "hardware" => "Hardware",
      "firmware" => "Firmware",
      "software" => "Software",
      "industrial-design" => "Industrial Design",
      "team" => "Team"
    }.each do |id, title|
      assert_includes html, %(data-project-chapter="#{id}")
      assert_equal 2, html.scan(%(href="##{id}" data-project-chapter-link="#{id}")).length
      assert_includes html, title
    end
    assert_includes html, "A lab instrument that fits in your pocket."
    assert_includes html, "Scopen began with a practical frustration"
    assert_includes html, "UCSB Computer Engineering capstone"
    assert_includes html, "isolated analog front end"
    assert_includes html, "2.45 × 0.73 in"
    assert_includes html, "FreeRTOS"
    assert_includes html, "High Resolution Timer triggers the ADCs in hardware"
    assert_includes html, "UDP and TCP connections"
    assert_includes html, "Model View Controller"
    assert_includes html, "Java Swing"
    assert_includes html, "Byron Aguilar"
    assert_includes html, "Professor Yogananda Isukapalli"
    assert_includes html, "Turn the board into a handheld instrument."
    refute_includes html, "# Concep"
    refute_includes html, 'class="row justify-content-center"'
    refute_includes html, "—"
    refute_includes html, "Future Improvements"
    refute_includes html, 'data-project-chapter="future-improvements"'
  end,
  "Scopen follows the approved Hardware and Firmware story order" => lambda do
    html = built("projects/scopen.html")

    hardware_start = html.index('data-project-chapter="hardware"')
    firmware_start = html.index('data-project-chapter="firmware"')
    hardware = html[hardware_start...firmware_start]

    expected_order = [
      "2.45 × 0.73 in",
      "Top side PCB - main controller and signal circuitry",
      "Bottom side PCB - SRAM, AFE and debug interface",
      "Six-layer PCB stack",
      "Analog front-end architecture",
      "Controller subsystems"
    ]
    positions = expected_order.map { |text| hardware.index(text) }
    assert(positions.all?, "expected every Hardware story beat to render")
    assert_equal positions.sort, positions

    assert_includes html, "Keep sampling deterministic. Move everything else around it."
    assert_includes html, "Make the system feel like an instrument."
    [
      "Deterministic Acquisition",
      "Task Orchestration",
      "Wireless Bridge",
      "Instrument Interface"
    ].each do |heading|
      assert_includes html, ">#{heading}</h2>"
    end
    refute_includes html, ">System Architecture</h2>"
    refute_includes html, ">Application Architecture</h2>"
  end,
  "Scopen uses the prototype demo for Context and the rendered video for Industrial Design" => lambda do
    html = built("projects/scopen.html")

    context_start = html.index('data-project-chapter="context"')
    hardware_start = html.index('data-project-chapter="hardware"')
    software_start = html.index('data-project-chapter="software"')
    industrial_start = html.index('data-project-chapter="industrial-design"')
    team_start = html.index('data-project-chapter="team"')

    context = html[context_start...hardware_start]
    software = html[software_start...industrial_start]
    industrial = html[industrial_start...team_start]

    assert_equal 1, context.scan('class="project-video-embed-item"').length
    assert_includes context, "Working prototype demo"
    refute_includes context, "scopen_poster.jpg"
    refute_includes software, "project-video-embed"
    assert_equal 1, industrial.scan('class="project-video-embed-item"').length
    assert_includes industrial, "Rendered product video"
    assert(
      industrial.index("scopen_id_blue.png") < industrial.index("project-video-embed"),
      "expected the enclosure study to lead into the physical product video"
    )
    refute_includes html, "scopen_id_render.png"
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
