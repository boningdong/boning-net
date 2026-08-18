# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "date"
require "yaml"

class ResponsiveImagesTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def self.ensure_site_built
    return if defined?(@site_built) && @site_built

    stdout, stderr, status = Open3.capture3(
      { "JEKYLL_ENV" => "production" },
      "bundle",
      "exec",
      "jekyll",
      "build",
      chdir: ROOT
    )
    raise "Jekyll build failed:\n#{stdout}\n#{stderr}" unless status.success?

    @site_built = true
  end

  def setup
    self.class.ensure_site_built
  end

  def test_scoped_pages_render_responsive_card_images
    %w[index.html projects.html artwork.html].each do |page|
      html = File.read(File.join(ROOT, "_site", page))

      assert_includes html, "<picture", "#{page} should contain picture markup"
      assert_match(/<source[^>]+type=["']image\/webp["']/, html, "#{page} should offer WebP")
      assert_match(/srcset=["'][^"']+\s\d+w/, html, "#{page} should emit width-based srcsets")
      assert_match(/sizes=["'][^"']+/, html, "#{page} should describe rendered image sizes")
      assert_match(/<img[^>]+width=["']\d+["'][^>]+height=["']\d+["']/, html, "#{page} should emit intrinsic dimensions")
      assert_match(/<img[^>]+loading=["']lazy["'][^>]+decoding=["']async["']/, html, "#{page} should lazy-decode cards")
    end
  end

  def test_verification_code_is_not_published
    refute_path_exists File.join(ROOT, "_site", "test")
  end

  def test_artwork_cards_use_the_full_resolution_viewer_source
    Dir.glob(File.join(ROOT, "_artwork", "*.md")).sort.each do |path|
      artwork = frontmatter(path)

      assert_equal artwork.fetch("location"), artwork.fetch("cover"), "#{File.basename(path)} should reuse its full-resolution source"
      assert File.file?(File.join(ROOT, artwork.fetch("cover").delete_prefix("/"))), "#{File.basename(path)} cover should exist"
    end
  end

  def test_artwork_highlights_load_before_the_hidden_rail_is_revealed
    html = File.read(File.join(ROOT, "_site", "artwork.html"))
    highlights_start = html.index('id="artwork-highlights-title"')
    collection_start = html.index('id="artwork-collection-title"')
    highlights_html = html[highlights_start...collection_start]
    collection_html = html[collection_start..]

    refute_match(/<img[^>]+loading=["']lazy["']/, highlights_html)
    assert_match(/<img[^>]+loading=["']lazy["']/, collection_html)
  end

  def test_scopen_primary_highlight_uses_the_generated_cover_full_bleed
    scopen = frontmatter(File.join(ROOT, "_projects", "scopen.md"))
    projects_html = File.read(File.join(ROOT, "_site", "projects.html"))
    css = File.read(File.join(ROOT, "_site", "assets", "css", "main.css"))
    primary_card = projects_html[/<a class="highlight-card highlight-card--primary".*?<\/a>/m]

    assert_match %r{\A/assets/img/projects/scopen/cover(?:-(?:logo|product|blueprint))?\.png\z}, scopen.fetch("cover")
    assert_operator image_width(File.join(ROOT, scopen.fetch("cover").delete_prefix("/"))), :>=, 1600
    generated_name = File.basename(scopen.fetch("cover"), ".png")
    assert_includes primary_card, "/generated/assets/img/projects/scopen/#{generated_name}-"
    assert_match(/\.highlight-card img\{[^}]*object-fit:cover/, css)
    refute_match(/\.highlight-card--primary img\{[^}]*(?:padding:4%|object-fit:contain)/, css)
    assert_match(/@media\(max-width: 640px\)\{.*?\.highlights-grid\{grid-template-columns:1fr;grid-template-rows:240px 220px 220px/m, css)
  end

  def test_projects_own_their_assets
    failures = Dir.glob(File.join(ROOT, "_projects", "*.md")).sort.filter_map do |path|
      slug = File.basename(path, ".md")
      cover = frontmatter(path).fetch("cover")
      next if cover.start_with?("/assets/img/projects/#{slug}/") && File.file?(File.join(ROOT, cover.delete_prefix("/")))

      "#{slug} does not own #{cover}"
    end

    assert_empty failures, failures.join("\n")
    assert_empty Dir.glob(File.join(ROOT, "assets/img/projects/*")).select { |path| File.file?(path) }
    refute_path_exists File.join(ROOT, "assets/img/projects", "covers-hd")
  end

  def test_project_image_references_resolve_to_existing_files
    missing = Dir.glob(File.join(ROOT, "_projects", "*.md")).sort.flat_map do |path|
      File.read(path).scan(%r{/assets/img/projects/[^\s"')]+}).uniq.filter_map do |reference|
        next if File.file?(File.join(ROOT, reference.delete_prefix("/")))

        "#{File.basename(path)} references missing #{reference}"
      end
    end

    assert_empty missing, missing.join("\n")
  end

  def test_home_and_projects_cards_share_a_translucent_overlay
    css = File.read(File.join(ROOT, "_site", "assets", "css", "main.css"))
    home_gradient = css[/\.portfolio-item::after\{[^}]*background:([^;}]+)/, 1]
    projects_gradient = css[/\.highlight-card::after\{[^}]*background:([^;}]+)/, 1]

    refute_nil home_gradient
    assert_equal home_gradient, projects_gradient
    assert_includes home_gradient, "rgba(8, 16, 20, 0.56)"
    refute_match(/\.portfolio-meta\{[^}]*background:/, css)
    refute_includes css, "rgba(6, 12, 15, 0.78)"
  end

  def test_project_highlights_reuse_the_home_bento_caption_scale
    css = File.read(File.join(ROOT, "_site", "assets", "css", "main.css"))
    home_title = css_declarations(css, ".portfolio-meta strong")
    project_title = css_declarations(css, ".highlight-info h3")
    home_subtitle = css_declarations(css, ".portfolio-meta span")
    project_subtitle = css_declarations(css, ".highlight-info p")
    home_meta = css_declarations(css, ".portfolio-meta em")
    project_meta = css_declarations(css, ".highlight-info small")

    %w[font-family font-size font-weight line-height letter-spacing].each do |property|
      assert_equal home_title.fetch(property), project_title.fetch(property), "title #{property} should match the homepage Bento cards"
    end
    %w[color font-size line-height].each do |property|
      assert_equal home_subtitle.fetch(property), project_subtitle.fetch(property), "subtitle #{property} should match the homepage Bento cards"
    end
    %w[color font letter-spacing].each do |property|
      assert_equal home_meta.fetch(property), project_meta.fetch(property), "metadata #{property} should match the homepage Bento cards"
    end
    assert_equal css_declarations(css, ".portfolio-meta").fetch("padding"), css_declarations(css, ".highlight-info").fetch("padding")
    refute_match(/\.highlight-card--primary \.highlight-info h3\{/, css)
  end

  def test_project_card_sources_are_large_enough_for_their_slots
    projects = Dir.glob(File.join(ROOT, "_projects", "*.md")).map do |path|
      [path, frontmatter(path)]
    end
    failures = projects.filter_map do |path, project|
      cover = File.join(ROOT, project.fetch("cover").delete_prefix("/"))
      width = image_width(cover)
      required_width = 1280
      next if width >= required_width

      "#{File.basename(path)} uses a #{width}px cover; expected at least #{required_width}px"
    end

    assert_empty failures, failures.join("\n")
  end

  private

  def frontmatter(path)
    yaml = File.read(path).match(/\A---\s*\n(.*?)\n---/m)[1]
    YAML.safe_load(yaml, permitted_classes: [Date])
  end

  def image_width(path)
    stdout, stderr, status = Open3.capture3("vipsheader", "-f", "width", path)
    raise "Unable to read #{path}: #{stderr}" unless status.success?

    Integer(stdout)
  end

  def css_declarations(css, selector)
    body = css[/#{Regexp.escape(selector)}\{([^}]*)\}/, 1]
    raise "Missing CSS selector #{selector}" unless body

    body.split(";").filter_map do |declaration|
      property, value = declaration.split(":", 2)
      [property, value] if value
    end.to_h
  end
end
