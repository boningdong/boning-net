# frozen_string_literal: true

require "minitest/autorun"

class ProjectDetailMockTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  HTML_PATH = File.join(ROOT, "docs/designs/08-18-2026/scopen-calibrated-a1-signal-rail.html")
  CSS_PATH = File.join(ROOT, "docs/designs/08-18-2026/calibrated-case-study.css")
  FINAL_MOCK_DIR = File.join(ROOT, "docs/designs/08-20-2026")
  FINAL_HTML_PATH = File.join(FINAL_MOCK_DIR, "scopen-expanded-full-page.html")
  FINAL_CSS_PATH = File.join(FINAL_MOCK_DIR, "calibrated-case-study.css")
  FINAL_NAV_JS_PATH = File.join(FINAL_MOCK_DIR, "chapter-nav-visibility.js")
  HERO_DIR = File.join(ROOT, "assets/img/showcase/project-detail-defaults")
  SELECTED_HEROES = %w[
    blueprint-night.png
    light-field.png
    light-optics.png
    light-rocket.png
    light-wearable-instrument.png
    night-field-coil.png
    night-gyroscope.png
    night-instrument-expanded.png
    night-pcb.png
  ].freeze

  def test_nav_surface_is_controlled_by_scroll_sentinel_for_both_hero_tones
    html = File.read(HTML_PATH)
    css = File.read(CSS_PATH)

    assert_includes html, "data-nav-sentinel"
    assert_includes html, "new IntersectionObserver"
    refute_includes html, 'window.addEventListener("scroll", updateNav'
    refute_match(/\.site-nav\.surface-visible,\s*\.light-hero \.site-nav/, css)
    light_nav_rule = css[/\.signal-page\[data-hero-variant\^="light"\] \.site-nav:not\(\.surface-visible\) \{[^}]*\}/]
    refute_nil light_nav_rule
    refute_includes light_nav_rule, "background:"
  end

  def test_chapter_tracking_uses_observers_instead_of_scroll_handlers
    html = File.read(HTML_PATH)

    refute_includes html, 'window.addEventListener("scroll"'
    assert_operator html.scan("new IntersectionObserver").length, :>=, 2
  end

  def test_selected_hero_art_is_ultrawide
    SELECTED_HEROES.each do |filename|
      width, height = png_dimensions(File.join(HERO_DIR, filename))
      ratio = width.fdiv(height)

      assert_operator ratio, :>=, 2.4, "#{filename} must remain an ultrawide banner"
    end
  end

  def test_mock_copy_has_no_em_or_en_dash_characters
    html = File.read(HTML_PATH)

    refute_match(/[—–]/, html)
  end

  def test_recovered_final_mock_uses_approved_defaults
    html = File.read(FINAL_HTML_PATH)

    assert_includes html, 'data-hero-variant="night-instrument"'
    assert_includes html, 'data-hero-fit="cover"'
    assert_includes html, 'data-mobile-nav="corner"'
    assert_includes html, 'data-intro-variant="compact"'
    assert_includes html, "night-instrument-expanded.png"
    assert_includes html, 'setHeroVariant(initialUrl.searchParams.get("hero") || "night-instrument", false)'
    assert_includes html, 'setHeroFit(initialUrl.searchParams.get("fit") || "cover", false)'
    assert_includes html, 'setMobileNavVariant(initialUrl.searchParams.get("nav") || "corner", false)'
  end

  def test_recovered_final_mock_has_no_browser_extension_artifacts
    html = File.read(FINAL_HTML_PATH)

    refute_match(/diigo|grammarly|chrome-extension|dummybodyid/i, html)
  end

  def test_recovered_final_mock_keeps_corner_navigation_behavior
    html = File.read(FINAL_HTML_PATH)
    css = File.read(FINAL_CSS_PATH)
    nav_js = File.read(FINAL_NAV_JS_PATH)

    assert_includes html, 'data-signal-trigger'
    assert_includes html, 'data-signal-close'
    assert_includes html, "chapterNavVisibility.shouldRevealChapterNavigation"
    assert_includes css, '[data-mobile-nav="corner"]'
    assert_includes css, ".chapter-nav-visible"
    assert_includes nav_js, "REVEAL_LINE = 0.7"
  end

  private

  def png_dimensions(path)
    header = File.binread(path, 24)
    raise "Not a PNG: #{path}" unless header.start_with?("\x89PNG\r\n\x1A\n".b)

    header.byteslice(16, 8).unpack("NN")
  end
end
