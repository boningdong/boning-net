# frozen_string_literal: true

require "fileutils"
require "jekyll"
require "tmpdir"
require_relative "test_helper"

class HeroTest < TinyTestCase
  ROOT = File.expand_path("../..", __dir__)

  def test_explicit_hero_alt_renders_exactly_as_authored
    html = render_hero(title: "Layout fixture", hero_alt: "Handheld measurement instrument")

    assert_equal "Handheld measurement instrument", rendered_hero_alt(html)
  end

  def test_omitted_hero_alt_uses_the_title_based_fallback
    html = render_hero(title: "Layout fixture")

    assert_equal "Layout fixture project illustration", rendered_hero_alt(html)
  end

  private

  def render_hero(title:, hero_alt: nil)
    Dir.mktmpdir("project-detail-hero") do |source|
      include_path = File.join(source, "_includes/pages/project-detail/hero.html")
      FileUtils.mkdir_p(File.dirname(include_path))
      FileUtils.cp(File.join(ROOT, "_includes/pages/project-detail/hero.html"), include_path)
      File.write(
        File.join(source, "_config.yml"),
        "project_detail:\n  default_hero: /assets/default-hero.png\nplugins: []\n"
      )

      page_data = { "title" => title }
      page_data["hero_alt"] = hero_alt unless hero_alt.nil?
      File.write(
        File.join(source, "index.html"),
        page_data.to_yaml + "---\n{% include pages/project-detail/hero.html %}\n"
      )

      destination = File.join(source, "_site")
      site = Jekyll::Site.new(
        Jekyll.configuration(
          "source" => source,
          "destination" => destination,
          "quiet" => true,
          "disable_disk_cache" => true
        )
      )
      site.process
      File.read(File.join(destination, "index.html"))
    end
  end

  def rendered_hero_alt(html)
    html[/<img class="project-hero-image"[^>]* alt="([^"]*)"/, 1]
  end
end

TinyTestRunner.run(HeroTest)
