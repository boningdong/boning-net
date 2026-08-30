# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../test_helper"
require_relative "../../../_plugins/project_detail"

class PeopleTest < TinyTestCase
  def test_source_resolves_a_validated_copy_of_frontmatter_people
    frontmatter = {
      "title" => "Example",
      "people" => {
        "team" => [
          {
            "name" => "Byron Aguilar",
            "role" => "Computer Engineer",
            "image" => "/assets/img/people/byron.png",
            "url" => "https://example.com/byron"
          },
          {
            "name" => "Ada Lovelace",
            "role" => "Software Engineer",
            "image" => "/assets/img/people/ada.png"
          }
        ]
      }
    }
    result = compile(people, frontmatter: frontmatter)
    items = result.blocks.values.first.fetch("items")

    assert_equal(
      [
        {
          "name" => "Byron Aguilar",
          "role" => "Computer Engineer",
          "image" => {
            "src" => "/assets/img/people/byron.png",
            "alt" => "Portrait of Byron Aguilar"
          },
          "url" => "https://example.com/byron"
        },
        {
          "name" => "Ada Lovelace",
          "role" => "Software Engineer",
          "image" => {
            "src" => "/assets/img/people/ada.png",
            "alt" => "Portrait of Ada Lovelace"
          }
        }
      ],
      items
    )
    frontmatter.fetch("people").fetch("team").first["name"] = "Changed later"
    assert_equal "Byron Aguilar", items.first.fetch("name")
  end

  def test_source_is_required_and_is_the_only_attribute
    missing_error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Team\n\n::: people\n:::\n", frontmatter: valid_frontmatter)
    end
    assert_includes missing_error.message, "people requires a nonblank source attribute"

    unknown_error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Team\n\n::: people source=team columns=3\n:::\n", frontmatter: valid_frontmatter)
    end
    assert_includes unknown_error.message, 'people does not accept attribute "columns"'
  end

  def test_unknown_non_array_and_empty_sources_fail
    cases = [
      [{ "people" => {} }, 'people source "team" was not found'],
      [{ "people" => { "team" => "Byron" } }, 'people source "team" must be a nonempty array'],
      [{ "people" => { "team" => [] } }, 'people source "team" must be a nonempty array'],
      [{ "people" => [] }, "people frontmatter must be a mapping"]
    ]

    cases.each do |people_data, expected_message|
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile(people, frontmatter: { "title" => "Example" }.merge(people_data))
      end
      assert_includes error.message, expected_message
    end
  end

  def test_entries_reject_wrong_types_unknown_keys_and_missing_values
    invalid_entries = [
      ["Byron", "people entries must be mappings"],
      [
        {
          "name" => "Byron",
          "role" => "Engineer",
          "image" => "/byron.png",
          "bio" => "Extra"
        },
        'people entry does not accept key "bio"'
      ],
      [{ "role" => "Engineer", "image" => "/byron.png" }, 'people entry requires "name"'],
      [{ "name" => " ", "role" => "Engineer", "image" => "/byron.png" },
       'people entry "name" must be a nonblank string'],
      [{ "name" => "Byron", "role" => 42, "image" => "/byron.png" },
       'people entry "role" must be a nonblank string'],
      [{ "name" => "Byron", "role" => "Engineer", "image" => nil },
       'people entry "image" must be a nonblank string'],
      [{ "name" => "Byron", "role" => "Engineer", "image" => "/byron.png", "url" => "" },
       'people entry "url" must be a nonblank string']
    ]

    invalid_entries.each do |entry, expected_message|
      frontmatter = { "people" => { "team" => [entry] } }
      error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
        compile(people, frontmatter: frontmatter)
      end
      assert_includes error.message, expected_message
    end
  end

  def test_person_url_uses_safe_link_rules
    frontmatter = valid_frontmatter
    frontmatter.fetch("people").fetch("team").first["url"] = "javascript:alert(1)"

    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile(people, frontmatter: frontmatter)
    end

    assert_includes error.message,
                    "people link URL must be relative or use http, https, mailto, or tel"
  end

  def test_body_content_fails_instead_of_being_ignored
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Team\n\n::: people source=team\nIgnored prose.\n:::\n", frontmatter: valid_frontmatter)
    end

    assert_includes error.message, "people does not accept body content"
  end

  def test_production_include_omits_links_for_unlinked_people
    frontmatter = {
      "people" => {
        "team" => [
          {
            "name" => "Linked Person",
            "role" => "Engineer",
            "image" => "/linked.png",
            "url" => "/people/linked"
          },
          {
            "name" => "Unlinked Person",
            "role" => "Designer",
            "image" => "/unlinked.png"
          }
        ]
      }
    }
    output = render_compiled(compile(people, frontmatter: frontmatter))

    assert_includes output, '<ul class="project-people" data-people-source="team">'
    assert_equal 1, output.scan('class="project-person-card project-media-link"').length
    assert_includes output, 'href="/people/linked"'
    assert_includes output, '<article class="project-person-card">'
    refute_includes output, 'href=""'
    assert_includes output, 'alt="Portrait of Linked Person"'
    assert_includes output, '<h3>Unlinked Person</h3>'
    assert_includes output, '<p>Designer</p>'
  end

  private

  def compile(markdown, frontmatter:)
    BoningNet::ProjectDetail::Compiler.new(
      markdown: markdown,
      config: {},
      frontmatter: frontmatter,
      source_path: "_projects/example.md",
      kramdown_options: { "input" => "GFM" },
      registry: BoningNet::ProjectDetail.registry
    ).call
  end

  def people
    "# Team\n\n::: people source=team\n:::\n"
  end

  def valid_frontmatter
    {
      "people" => {
        "team" => [
          {
            "name" => "Byron Aguilar",
            "role" => "Computer Engineer",
            "image" => "/assets/img/people/byron.png"
          }
        ]
      }
    }
  end

  def render_compiled(result)
    Dir.mktmpdir("project-detail-people") do |source|
      includes_root = File.join(source, "_includes/pages/project-detail/blocks")
      layout_path = File.join(source, "_layouts/test.html")
      FileUtils.mkdir_p(File.join(includes_root, "primitives"))
      FileUtils.mkdir_p(File.dirname(layout_path))

      %w[people.html primitives/person-card.html].each do |relative_path|
        FileUtils.cp(
          File.expand_path("../../../_includes/pages/project-detail/blocks/#{relative_path}", __dir__),
          File.join(includes_root, relative_path)
        )
      end
      File.write(layout_path, "{{ content }}\n")
      File.write(
        File.join(source, "index.md"),
        {
          "layout" => "test",
          "project_detail_generated" => { "blocks" => result.blocks }
        }.to_yaml + "---\n" + result.content
      )

      destination = File.join(source, "_site")
      site = Jekyll::Site.new(
        Jekyll.configuration("source" => source, "destination" => destination, "quiet" => true)
      )
      site.process
      File.read(File.join(destination, "index.html"))
    end
  end
end

TinyTestRunner.run(PeopleTest)
