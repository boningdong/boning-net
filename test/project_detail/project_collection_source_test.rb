# frozen_string_literal: true

require "date"
require "yaml"
require_relative "test_helper"

class ProjectCollectionSourceTest < TinyTestCase
  ROOT = File.expand_path("../..", __dir__)
  PROJECT_PATHS = Dir[File.join(ROOT, "_projects", "*.md")].sort.freeze

  def assert_equal(expected, actual, message = nil)
    super(expected, actual)
  rescue AssertionFailure
    raise AssertionFailure, message || "expected #{expected.inspect}, got #{actual.inspect}"
  end

  def test_every_project_uses_the_project_detail_authoring_contract
    PROJECT_PATHS.each do |path|
      frontmatter, body = parse_project(path)
      assert_equal "project-detail", frontmatter.fetch("layout"), path
      refute body.match?(%r{</?[A-Za-z][^>]*>}), path
      refute body.match?(/\{[{%].*?[}%]\}/m), path
      assert body.match?(/\A\s*\S.*?^#\s+\S/m), "expected Intro and Main Content in #{path}"
    end
  end

  def test_every_authored_media_item_has_accessible_copy
    PROJECT_PATHS.each do |path|
      _frontmatter, body = parse_project(path)
      body.lines.grep(/^!\[/).each do |line|
        assert line.match?(/^!\[[^\]]+\]\([^\s)]+\s+"[^\".!?]+"\)\s*$/), line
      end
    end
  end

  private

  def parse_project(path)
    source = File.read(path)
    match = source.match(/\A---\n(?<yaml>.*?)\n---\n(?<body>.*)\z/m)
    assert(match, "expected #{path} to contain valid frontmatter fences")

    frontmatter = YAML.safe_load(
      match[:yaml],
      permitted_classes: [Date],
      aliases: true
    )
    [frontmatter, match[:body]]
  end
end

TinyTestRunner.run(ProjectCollectionSourceTest)
