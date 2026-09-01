# Scopen Project Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the approved Markdown-first Project Detail design on Scopen while leaving every legacy project unchanged.

**Architecture:** A local Jekyll pre-render processor uses the existing Kramdown AST to split Project Intro from Main Content, derive level-one chapters, validate the two author options, and inject semantic chapter wrappers before Jekyll performs its normal Markdown conversion. A new `project-detail` layout layers on the existing modern shell; Liquid renders the complete Hero, featured Intro, desktop chapter navigation, and mobile Corner Navigation, while a focused vanilla JavaScript module only handles active state and Corner interaction.

**Tech Stack:** Jekyll 4.4.1, Ruby 3.3, Kramdown 2.5.1, Liquid, SCSS, vanilla JavaScript, Minitest, Node's built-in test runner

**Spec:** `docs/designs/08-26-2026/project-detail-architecture.md`

## Global Constraints

- Initial production rollout is Scopen only; all documents retaining `layout: project-post` must render unchanged.
- `layout: project-detail` is the sole architecture opt-in; do not introduce `project_detail_version` or plugin-specific booleans.
- Public configuration is exactly `project_detail.navigation: auto | none` and `project_detail.intro_style: featured | plain`.
- Both configuration defaults are `auto` and `featured` respectively.
- Project Intro is visible Markdown before the first level-one heading; no visible pre-heading content means no Intro output.
- The first level-one heading and everything after it is Main Content; only level-one headings become chapters.
- No level-one heading means the entire Markdown document is ordinary Main Content with no extracted Intro and no navigation.
- `navigation: auto` renders responsive navigation only when at least two chapters exist; `none` renders neither Desktop nor Corner Navigation.
- Use the existing Kramdown dependency and a local `_plugins` implementation; install no new gem or third-party Jekyll plugin.
- JavaScript must not parse Markdown, create article structure, or move Intro content.
- Hero 04 is the global Project Detail fallback, rendered with `object-fit: cover`; a page-provided `hero` overrides it.
- Featured Intro uses the approved Bridge design; Mobile uses the approved Corner Navigation and hides it until Main Content reaches the reveal threshold.
- Reuse the modern site's Instrument Sans, Source Sans 3, IBM Plex Mono, colors, radii, glass mixin, shadows, and responsive widths.
- Do not modify, delete, stage, or commit unrelated untracked assets, design mocks, or tests already present in the worktree.

---

## File Structure

### Build and data contract

- Create `_plugins/project_detail.rb`: validate author configuration, parse Kramdown, split Intro, derive IDs and chapter metadata, inject semantic chapter wrappers, and register the Jekyll pre-render hook.
- Create `test/project_detail_processor_test.rb`: isolated processor contract and validation tests.

### Rendering

- Create `_layouts/project-detail.html`: compose the production page and inherit the modern shell.
- Create `_includes/pages/project-detail/hero.html`: default/custom Hero, title, description, date, and existing tag metadata.
- Create `_includes/pages/project-detail/intro.html`: featured Project Intro only.
- Create `_includes/pages/project-detail/chapter-navigation.html`: one shared chapter dataset rendered as Desktop links and Corner controls.
- Modify `_layouts/modern.html`: allow nested layouts to provide body class, active navigation, compact footer, and scripts without duplicating the modern document shell.
- Modify `_config.yml`: define the fallback Hero 04 path only; author behavior defaults remain in the processor.

### Presentation and interaction

- Create `_sass/pages/_project-detail.scss`: scoped Hero, Bridge, article, media, desktop rail, Corner glass, dialog, and responsive rules.
- Modify `assets/css/main.scss`: compile the Project Detail page module.
- Create `assets/js/pages/project-detail.js`: active-chapter tracking, Corner reveal, dialog behavior, and anchor selection.
- Create `test/javascript/project-detail.test.js`: pure helper and module contract tests without a DOM dependency.

### Scopen rollout

- Modify `_projects/scopen.md`: opt into the new layout, correct metadata, add the approved Intro, and reorganize all useful legacy material into five level-one chapters.
- Create `assets/img/showcase/project-detail-defaults/night-instrument-expanded.png`: preserve the approved expanded Hero 04 artwork at 3840 by 1280.
- Create `test/project_detail_rendering_test.rb`: production build assertions for Scopen, navigation modes, modern-shell isolation, asset selection, and legacy-project regression.

---

### Task 1: Build-Time Project Detail Processor

**Files:**
- Create: `_plugins/project_detail.rb`
- Create: `test/project_detail_processor_test.rb`

**Interfaces:**
- Consumes: raw Markdown `String`, page config `Hash`, source path `String`, and Kramdown options `Hash`.
- Produces: `BoningNet::ProjectDetail::Result` with `content`, `intro_markdown`, `chapters`, `navigation_enabled`, and `intro_style` readers.
- Produces in Jekyll document data: `project_detail_generated` with string keys `intro_markdown`, `chapters`, `navigation_enabled`, and `intro_style`.

- [ ] **Step 1: Write processor contract tests**

Create `test/project_detail_processor_test.rb` with these Minitest cases:

```ruby
# frozen_string_literal: true

require "minitest/autorun"
require "jekyll"
require_relative "../_plugins/project_detail"

class ProjectDetailProcessorTest < Minitest::Test
  def compile(markdown, config = {})
    BoningNet::ProjectDetail::Compiler.new(
      markdown: markdown,
      config: config,
      source_path: "_projects/example.md",
      kramdown_options: {}
    ).call
  end

  def test_featured_intro_and_level_one_chapters
    result = compile("A short intro.\n\n# Context\nBody\n\n## Detail\nNested\n\n# Hardware\nBoard\n")

    assert_equal "A short intro.", result.intro_markdown.strip
    assert_equal ["Context", "Hardware"], result.chapters.map { |chapter| chapter.fetch("title") }
    assert_equal ["context", "hardware"], result.chapters.map { |chapter| chapter.fetch("id") }
    assert result.navigation_enabled
    assert_includes result.content, 'data-project-chapter="context"'
    refute_includes result.content, "A short intro."
  end

  def test_plain_intro_stays_in_content
    result = compile("A short intro.\n\n# Context\nBody\n", "intro_style" => "plain")

    assert_equal "A short intro.", result.intro_markdown.strip
    assert_includes result.content, "A short intro."
    refute result.navigation_enabled
  end

  def test_document_without_level_one_heading_is_ordinary_content
    markdown = "Paragraph.\n\n## Detail\nNested.\n"
    result = compile(markdown)

    assert_nil result.intro_markdown
    assert_empty result.chapters
    assert_equal markdown, result.content
    refute result.navigation_enabled
  end

  def test_explicit_ids_are_preserved
    result = compile("# Industrial Design {#industrial-design}\nBody\n\n# Team\nPeople\n")
    assert_equal ["industrial-design", "team"], result.chapters.map { |chapter| chapter.fetch("id") }
  end

  def test_navigation_none_suppresses_ui_state_but_keeps_chapters
    result = compile("# Context\nBody\n\n# Hardware\nBoard\n", "navigation" => "none")
    assert_equal 2, result.chapters.length
    refute result.navigation_enabled
    assert_includes result.content, 'data-project-chapter="context"'
  end

  def test_invalid_values_name_the_source_and_allowed_values
    error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
      compile("# Context\nBody\n", "navigation" => "automatic")
    end
    assert_includes error.message, "_projects/example.md"
    assert_includes error.message, 'navigation must be "auto" or "none"'
  end
end
```

Add these concrete test methods to the same class:

```ruby
def test_empty_and_comment_only_preface_does_not_create_intro
  result = compile("<!-- editorial note -->\n\n# Context\nBody\n")
  assert_nil result.intro_markdown
end

def test_one_chapter_does_not_enable_navigation
  result = compile("# Context\nBody\n")
  assert_equal 1, result.chapters.length
  refute result.navigation_enabled
end

def test_duplicate_explicit_ids_fail
  error = assert_raises(BoningNet::ProjectDetail::ConfigurationError) do
    compile("# Context {#same}\nBody\n\n# Hardware {#same}\nBoard\n")
  end
  assert_includes error.message, 'duplicate chapter id "same"'
end

def test_repeated_generated_titles_receive_kramdown_suffixes
  result = compile("# Test\nOne\n\n# Test\nTwo\n")
  assert_equal ["test", "test-1"], result.chapters.map { |chapter| chapter.fetch("id") }
end

def test_nested_headings_do_not_enter_navigation
  result = compile("# Context\nBody\n\n## Detail\nNested\n\n# Hardware\nBoard\n")
  assert_equal ["Context", "Hardware"], result.chapters.map { |chapter| chapter.fetch("title") }
end

def test_defaults_are_auto_and_featured
  result = compile("Intro.\n\n# Context\nBody\n\n# Team\nPeople\n")
  assert_equal "featured", result.intro_style
  assert result.navigation_enabled
end
```

- [ ] **Step 2: Run the processor tests and verify failure**

Run:

```bash
bundle exec ruby test/project_detail_processor_test.rb
```

Expected: FAIL because `_plugins/project_detail.rb` and `BoningNet::ProjectDetail::Compiler` do not exist.

- [ ] **Step 3: Implement the compiler and hook**

Implement `_plugins/project_detail.rb` with these concrete units and method flow:

```ruby
module BoningNet
  module ProjectDetail
    NAVIGATION_VALUES = %w[auto none].freeze
    INTRO_STYLE_VALUES = %w[featured plain].freeze

    class ConfigurationError < StandardError; end

    Result = Struct.new(
      :content,
      :intro_markdown,
      :chapters,
      :navigation_enabled,
      :intro_style,
      keyword_init: true
    )

    class Compiler
      def initialize(markdown:, config:, source_path:, kramdown_options:)
        @markdown = markdown
        @config = config || {}
        @source_path = source_path
        @kramdown_options = kramdown_options || {}
      end

      def call
        navigation = validated_option("navigation", NAVIGATION_VALUES, "auto")
        intro_style = validated_option("intro_style", INTRO_STYLE_VALUES, "featured")
        document = Kramdown::Document.new(@markdown, @kramdown_options)
        headings = document.root.children.select do |element|
          element.type == :header && element.options[:level] == 1
        end

        return ordinary_result(intro_style) if headings.empty?

        toc_root, = Kramdown::Converter::Toc.convert(document.root, document.options)
        toc_nodes = flatten_toc(toc_root).select do |node|
          node.value.options[:level] == 1
        end
        chapters = toc_nodes.each_with_index.map do |node, index|
          {
            "index" => index + 1,
            "id" => node.attr.fetch(:id),
            "title" => node.value.options.fetch(:raw_text)
          }
        end

        reject_duplicate_explicit_ids!(chapters, headings)
        intro_source, main_source = split_source(headings.first.options.fetch(:location))
        visible_intro = visible_markdown?(intro_source) ? intro_source : nil
        wrapped_main = wrap_chapters(main_source, chapters, headings)
        output = intro_style == "plain" && visible_intro ? intro_source + wrapped_main : wrapped_main

        Result.new(
          content: output,
          intro_markdown: visible_intro,
          chapters: chapters,
          navigation_enabled: navigation == "auto" && chapters.length >= 2,
          intro_style: intro_style
        )
      end
    end
  end
end
```

Define the private helpers used above with these exact contracts:

- `validated_option(key, allowed, default)` returns the default for a missing value and raises `ConfigurationError` with `@source_path`, key, accepted values, and received value otherwise.
- `ordinary_result(intro_style)` returns unchanged Markdown, nil Intro, an empty chapter array, disabled navigation, and the resolved Intro style.
- `flatten_toc(root)` recursively returns every `:toc` descendant in document order.
- `split_source(first_heading_line)` uses the one-based Kramdown source location and preserves final newlines in both fragments.
- `visible_markdown?(source)` parses the fragment with Kramdown and returns false when all root children are `:blank` or `:xml_comment`.
- `reject_duplicate_explicit_ids!(chapters, headings)` checks repeated IDs only when the corresponding source heading supplied `element.attr["id"]`; generated duplicate titles such as `test` and `test-1` remain valid.
- `wrap_chapters(main_source, chapters, headings)` converts each heading location to an offset relative to the first heading, inserts `<section class="project-chapter" data-project-chapter="ID" markdown="1">` immediately before it, inserts `</section>` before the next chapter, and closes the last section at EOF.

Use `Kramdown::Document` plus `Kramdown::Converter::Toc` so generated anchors use Kramdown's own ID algorithm. Select only TOC nodes whose wrapped header has `options[:level] == 1`. Use each header's `options[:location]` to split source lines; never regex-match headings or rendered HTML.

Inject wrappers into Main Content as Kramdown-enabled raw blocks:

```html
<section class="project-chapter" data-project-chapter="context" markdown="1">
# Context
...
</section>
```

Register `Jekyll::Hooks.register :documents, :pre_render`. Return immediately unless `document.data["layout"] == "project-detail"`. Put the generated hash in `document.data["project_detail_generated"]` and replace `document.content` with `result.content` before Jekyll's normal Liquid and Markdown phases.

- [ ] **Step 4: Run processor tests and verify pass**

Run:

```bash
bundle exec ruby test/project_detail_processor_test.rb
```

Expected: all processor tests PASS.

- [ ] **Step 5: Commit the processor**

```bash
git add _plugins/project_detail.rb test/project_detail_processor_test.rb
git commit -m "feat: compile project detail markdown structure"
```

---

### Task 2: Production Layout and Build Contract

**Files:**
- Create: `_layouts/project-detail.html`
- Create: `_includes/pages/project-detail/hero.html`
- Create: `_includes/pages/project-detail/intro.html`
- Create: `_includes/pages/project-detail/chapter-navigation.html`
- Modify: `_layouts/modern.html`
- Modify: `_config.yml`
- Create: `test/project_detail_rendering_test.rb`

**Interfaces:**
- Consumes: `page.project_detail_generated`, `page.hero`, `site.project_detail.default_hero`, ordinary project metadata, and converted `content`.
- Produces: `[data-project-detail]`, `[data-project-main]`, `[data-project-chapter-link]`, `[data-project-corner]`, and a complete semantic article.

- [ ] **Step 1: Write failing build assertions**

Create `test/project_detail_rendering_test.rb` using `Open3.capture3` once per class to run a Jekyll production build, then assert that `_site/projects/scopen.html` contains:

```ruby
assert_includes html, '<body class="modern-page project-detail-page">'
assert_includes html, 'data-project-detail'
assert_includes html, 'data-project-main'
assert_includes html, 'aria-label="Project chapters"'
assert_includes html, 'data-project-corner'
assert_includes html, '/assets/js/pages/project-detail.js'
assert_includes html, '/assets/img/showcase/project-detail-defaults/night-instrument-expanded.png'
refute_includes html, 'bootstrap.min.css'
refute_includes html, 'jquery'
```

Also assert that `_site/projects/areusafe.html` still contains the legacy `project-post` assets and does not contain `data-project-detail`.

- [ ] **Step 2: Run the rendering test and verify failure**

Run:

```bash
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: FAIL because Scopen still uses `project-post` and the new layout does not exist.

- [ ] **Step 3: Add nested-layout defaults to the modern shell**

At the top of `_layouts/modern.html`, resolve values from the page first and the inner layout second:

```liquid
{% assign resolved_body_class = page.body_class | default: layout.body_class %}
{% assign resolved_nav_active = page.nav_active | default: layout.nav_active %}
{% assign resolved_footer_variant = page.footer_variant | default: layout.footer_variant %}
{% assign resolved_scripts = page.scripts | default: layout.scripts %}
```

Use those resolved values for the body class, navigation include, footer include, and script loop. Existing modern pages must produce byte-equivalent semantic structure apart from asset-version timestamps.

- [ ] **Step 4: Create focused Liquid includes and layout**

Create `_layouts/project-detail.html` with layout metadata:

```yaml
---
layout: modern
body_class: project-detail-page
nav_active: projects
footer_variant: compact
scripts:
  - /assets/js/pages/project-detail.js
---
```

Compose the page as:

```liquid
<main class="project-detail" data-project-detail>
  {% include pages/project-detail/hero.html %}
  {% include pages/project-detail/intro.html %}
  <div class="project-reading design-wrap">
    {% include pages/project-detail/chapter-navigation.html variant="desktop" %}
    <article class="project-main" data-project-main>{{ content }}</article>
  </div>
  {% include pages/project-detail/chapter-navigation.html variant="corner" %}
</main>
```

The Hero include resolves `page.hero | default: site.project_detail.default_hero`, always uses a real `<img>` with descriptive alt text, links back to `/projects.html`, and derives its compact metadata line from the year plus at most three existing project tags. Render no tag capsules.

The Intro include returns no markup when generated Intro is nil/blank or style is `plain`. For `featured`, render a `Project Intro` utility label and pass `intro_markdown` through `markdownify` inside the approved Bridge container.

The navigation include returns no markup unless `navigation_enabled` is true. Desktop links and Corner links loop over the exact same generated `chapters` array. Use `aria-current="location"` on the first links, a native `<dialog>` for the Corner contents panel, and a button whose accessible name includes the current chapter position.

- [ ] **Step 5: Add the global fallback Hero**

Add only this site-level default to `_config.yml`:

```yaml
project_detail:
  default_hero: /assets/img/showcase/project-detail-defaults/night-instrument-expanded.png
```

Do not duplicate `navigation` or `intro_style` defaults in `_config.yml`; those authoring defaults belong to the processor contract.

- [ ] **Step 6: Temporarily opt Scopen into the layout for the build test**

Change only `layout: project-post` to `layout: project-detail` in `_projects/scopen.md`. Full content cleanup occurs in Task 5, but this step allows the production markup contract to be exercised.

- [ ] **Step 7: Run rendering and modern-page regression tests**

Run:

```bash
bundle exec jekyll build
bundle exec ruby test/project_detail_rendering_test.rb
ruby test/modern_pages_test.rb
```

Expected: the new layout assertions pass; all existing modern-page assertions pass; legacy project assertions pass.

- [ ] **Step 8: Commit the layout contract**

```bash
git add _layouts/project-detail.html _layouts/modern.html _includes/pages/project-detail _config.yml _projects/scopen.md test/project_detail_rendering_test.rb
git commit -m "feat: render project detail pages in the modern shell"
```

---

### Task 3: Approved Project Detail Visual System

**Files:**
- Create: `_sass/pages/_project-detail.scss`
- Modify: `assets/css/main.scss`
- Modify: `test/project_detail_rendering_test.rb`

**Interfaces:**
- Consumes: the markup/data attributes from Task 2 and shared variables/mixins from `_sass/foundation`.
- Produces: scoped `.project-detail-page` visual behavior at wide desktop, desktop, tablet, and mobile widths.

- [ ] **Step 1: Add failing compiled-CSS assertions**

Extend `test/project_detail_rendering_test.rb` to read `_site/assets/css/main.css` and require compiled selectors for:

```ruby
assert_includes css, ".project-detail-page"
assert_includes css, ".project-hero"
assert_includes css, ".project-intro--featured"
assert_includes css, ".project-chapter-nav"
assert_includes css, ".project-corner"
assert_includes css, ".project-media-grid"
assert_includes css, "object-fit:cover"
assert_includes css, "backdrop-filter:blur"
```

- [ ] **Step 2: Run the CSS assertion and verify failure**

Run `bundle exec ruby test/project_detail_rendering_test.rb`.

Expected: FAIL because the page stylesheet is not compiled.

- [ ] **Step 3: Implement the scoped SCSS module**

Create `_sass/pages/_project-detail.scss` using `@use "../foundation/mixins";` and scope all rules under `.project-detail-page` or `.project-detail`.

Implement these approved behaviors:

- Hero uses `min-height: clamp(620px, 76svh, 840px)`, the shared 1120px content width, a bottom/left content alignment, `object-fit: cover`, and a right-biased focal point that shifts across desktop/tablet/mobile without changing the source image.
- Hero overlay protects white title readability without washing out the blueprint subject; top navigation remains the shared component.
- Featured Intro uses the Bridge geometry, one purposeful separator between Project Intro and Main Content, no repeated rule lines inside metadata.
- Desktop reading grid uses a narrow sticky chapter rail and a readable article column; chapter separators represent chapter boundaries only.
- Plain Intro inherits article prose styles and stays immediately before the first chapter.
- All lone Markdown images receive the same white/glass frame, `--card-radius`, border, and shadow vocabulary as modern cards; contain images fill the frame without an extra blue or white inset.
- `.project-media-grid` supports two equal media cells on desktop and one column on mobile.
- Iframes use a responsive 16:9 wrapper and the shared radius.
- Team list becomes a restrained three-column card group and collapses cleanly on mobile.
- Desktop chapter rail disappears below 900px; Corner Navigation is available only below 900px.
- Corner indicator sits at the bottom-right safe area, uses `mixins.glass-surface`, and never spans the full viewport width.
- The native dialog opens as a calm rounded bottom sheet with clear active state, but retains a visible margin from viewport edges.
- Mobile typography, spacing, media radii, and shadows reuse shared tokens instead of mock-only constants.
- Forced-colors and reduced-motion rules preserve focus and remove nonessential movement.

Import it from `assets/css/main.scss` with:

```scss
@use "pages/project-detail";
```

- [ ] **Step 4: Build and verify CSS tests pass**

Run:

```bash
bundle exec jekyll build
bundle exec ruby test/project_detail_rendering_test.rb
git diff --check
```

Expected: compiled-CSS and rendering tests PASS with no whitespace errors.

- [ ] **Step 5: Commit the visual module**

```bash
git add _sass/pages/_project-detail.scss assets/css/main.scss test/project_detail_rendering_test.rb
git commit -m "feat: style the approved project detail system"
```

---

### Task 4: Chapter Tracking and Corner Navigation

**Files:**
- Create: `assets/js/pages/project-detail.js`
- Create: `test/javascript/project-detail.test.js`

**Interfaces:**
- Consumes DOM attributes from Task 2.
- Produces exported pure helpers `shouldRevealCorner(mainTop, viewportHeight)` and `activeChapterIndex(positions, viewportHeight)` plus browser `init()`.

- [ ] **Step 1: Write failing JavaScript tests**

Create `test/javascript/project-detail.test.js`:

```javascript
const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');

const modulePath = path.resolve(__dirname, '../../assets/js/pages/project-detail.js');

test('Corner Navigation appears only when Main Content reaches 70 percent of the viewport', () => {
  const { shouldRevealCorner } = require(modulePath);
  assert.equal(shouldRevealCorner(701, 1000), false);
  assert.equal(shouldRevealCorner(700, 1000), true);
  assert.equal(shouldRevealCorner(-20, 1000), true);
});

test('active chapter selects the last heading above the reading line', () => {
  const { activeChapterIndex } = require(modulePath);
  assert.equal(activeChapterIndex([120, 620, 1120], 1000), 0);
  assert.equal(activeChapterIndex([-500, 120, 620], 1000), 1);
  assert.equal(activeChapterIndex([-1000, -400, 120], 1000), 2);
});
```

- [ ] **Step 2: Run Node tests and verify failure**

Run:

```bash
node --test test/javascript/project-detail.test.js
```

Expected: FAIL because the module does not exist.

- [ ] **Step 3: Implement the UMD-style interaction module**

Follow the export/auto-init pattern already used by `assets/js/components/navigation.js`.

`init()` must:

1. Return immediately if `[data-project-detail]`, generated navigation, or chapter nodes are absent.
2. Build no chapter data; read the server-rendered links and `[data-project-chapter]` nodes.
3. Use `IntersectionObserver` for Main Content reveal and active chapter changes; do not attach a scroll handler.
4. Keep Desktop links, Corner links, the current label, and `NN / TT` counter synchronized.
5. Open the native dialog with `showModal()`, close it from the close button or a chapter selection, and restore focus to the Corner trigger.
6. Preserve native Escape behavior, close the dialog when crossing above 900px, and prevent hidden Corner controls from retaining focus.
7. Use `scrollIntoView({ behavior: reducedMotion ? "auto" : "smooth" })` and update the URL hash without creating a second history entry.
8. Add and remove the visible class only when `shouldRevealCorner` says Main Content has reached 70 percent of the viewport.

- [ ] **Step 4: Run JavaScript and build tests**

Run:

```bash
node --test test/javascript/*.test.js
bundle exec jekyll build
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: all JavaScript tests and production markup assertions PASS.

- [ ] **Step 5: Commit the interaction module**

```bash
git add assets/js/pages/project-detail.js test/javascript/project-detail.test.js
git commit -m "feat: add responsive project chapter navigation"
```

---

### Task 5: Migrate Scopen and Preserve Approved Hero 04

**Files:**
- Modify: `_projects/scopen.md`
- Create: `assets/img/showcase/project-detail-defaults/night-instrument-expanded.png`
- Modify: `test/project_detail_rendering_test.rb`

**Interfaces:**
- Consumes: the authoring contract and layout from Tasks 1-4.
- Produces: five chapters with IDs `context`, `hardware`, `firmware`, `software`, and `team`; one featured Project Intro; and the production Hero asset.

- [ ] **Step 1: Add failing Scopen content assertions**

Extend `test/project_detail_rendering_test.rb` to require exactly five generated chapter links and the corrected content contract:

```ruby
assert_equal 10, html.scan('data-project-chapter-link').length # five Desktop + five Corner links
%w[context hardware firmware software team].each do |id|
  assert_includes html, "data-project-chapter=\"#{id}\""
end
assert_includes html, "A lab instrument that fits in your pocket."
assert_includes html, "2.45 × 0.73 in"
assert_includes html, "FreeRTOS"
assert_includes html, "Java Swing"
assert_includes html, "Byron Aguilar"
refute_includes html, "# Concep"
refute_includes html, 'class="row justify-content-center"'
```

Also read the Hero PNG header and assert dimensions are exactly `3840 × 1280`.

- [ ] **Step 2: Run the content assertions and verify failure**

Run `bundle exec ruby test/project_detail_rendering_test.rb`.

Expected: FAIL because the legacy content and final Hero asset are not migrated.

- [ ] **Step 3: Preserve the approved expanded Hero 04**

Copy the already-approved expanded source:

```text
/Users/boning/.codex/generated_images/01a0184a-fccf-7011-a7e6-517b52ba847d/exec-fd951d84-fc55-4821-a1eb-feb51fc25d18.png
```

to:

```text
assets/img/showcase/project-detail-defaults/night-instrument-expanded.png
```

Resize the copied file to exactly 3840 by 1280 without changing its 3:1 composition. Do not regenerate or reinterpret the approved artwork.

- [ ] **Step 4: Rewrite Scopen into the authoring contract**

Use this frontmatter shape:

```yaml
---
layout: project-detail
title: Scopen
subtitle: A wireless oscilloscope designed to make circuit debugging portable.
date: 2020-06-15
cover: /assets/img/projects/scopen/cover-logo.png
featured: true
featured-order: 1
tags:
  - hardware
  - system-design
  - firmware
  - embedded
  - c
  - pcb
  - java
---
```

Do not add `project_detail` because Scopen uses both defaults. Put this Intro before the first level-one heading:

```markdown
A lab instrument that fits in your pocket.
```

Organize the preserved and proofread material under exactly:

```markdown
# Context
# Hardware
# Firmware
# Software
# Team
```

Within those chapters:

- Context contains the project motivation, scope, poster, presentation link, and two product videos.
- Hardware preserves AFE/MCU architecture, the `2.45 × 0.73 in` six-layer board result, both PCB sides, and the layer diagram.
- Firmware preserves STM32/ESP32 architecture, HRTIM-triggered ADC/DMA sampling, FreeRTOS tasks/semaphores, and SPI/UART wireless transport.
- Software preserves Java Swing MVC, the desktop UI, Fusion 360/printed enclosure as an `## Industrial Design` subsection, and a concise `## What we would improve` subsection.
- Team preserves the three linked members and acknowledgements using semantic Markdown/HTML without Bootstrap classes.

Use descriptive alt text for every image. Use `.project-media-grid` only where paired images materially benefit from side-by-side comparison. White-background diagrams occupy their entire glass frame; do not add a second tinted inset.

- [ ] **Step 5: Build and verify the complete Scopen contract**

Run:

```bash
bundle exec jekyll build
bundle exec ruby test/project_detail_processor_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
ruby test/modern_pages_test.rb
node --test test/javascript/*.test.js
```

Expected: all tests PASS; Scopen uses the modern page and all other projects remain legacy.

- [ ] **Step 6: Commit the Scopen migration**

```bash
git add _projects/scopen.md assets/img/showcase/project-detail-defaults/night-instrument-expanded.png test/project_detail_rendering_test.rb
git commit -m "feat: migrate Scopen to the project detail system"
```

---

### Task 6: Responsive and Regression Verification

**Files:**
- Modify only files from Tasks 1-5 when a verified defect requires correction.

**Interfaces:**
- Consumes: the complete built site.
- Produces: passing automated checks and visual evidence across representative viewports.

- [ ] **Step 1: Run the full automated suite**

Run:

```bash
bundle exec jekyll clean
JEKYLL_ENV=production bundle exec jekyll build
bundle exec ruby test/project_detail_processor_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
ruby test/modern_pages_test.rb
bundle exec ruby test/responsive_images_test.rb
bundle exec ruby test/project_detail_mock_test.rb
node --test test/javascript/*.test.js
git diff --check
```

Expected: every command exits zero. If the pre-existing untracked mock test targets obsolete mock-only files, report it separately rather than weakening production assertions.

- [ ] **Step 2: Serve the production build**

Run a local Jekyll server and open `/projects/scopen.html`. Verify the browser receives `main.css`, `navigation.js`, and `project-detail.js` without 404 responses.

- [ ] **Step 3: Verify representative viewports**

Inspect at least:

- 3840 × 2160: Hero 04 covers the Hero without exposed edges and retains the right-side instrument subject.
- 1440 × 1000: title, subtitle, Hero metadata, Bridge Intro, and sticky Desktop chapters match the approved hierarchy.
- 1024 × 900: layout transitions cleanly without crossed separators or clipped media.
- 390 × 844: Desktop chapters are absent; Corner indicator is initially hidden, appears when Main Content reaches the threshold, opens the dialog, selects chapters, and restores focus.
- 320 × 700: no horizontal overflow; Corner safe-area spacing and long chapter labels remain usable.

- [ ] **Step 4: Verify interaction and accessibility**

Using keyboard only, verify site navigation, Desktop chapter links, Corner trigger, dialog links, close button, Escape, focus restoration, and visible focus rings. Enable reduced motion and confirm scrolling/transitions become immediate. Confirm all meaningful images have useful alt text and the dialog has an accessible name.

- [ ] **Step 5: Verify legacy isolation and URLs**

Open at least `/projects/areusafe.html` and `/projects/drsstc.html`. Confirm their old layout still loads and the Projects listing still points to `/projects/scopen` correctly. Confirm explicit chapter deep links such as `/projects/scopen.html#hardware` land below the fixed site navigation.

- [ ] **Step 6: Review the final diff and commit verified corrections**

Run:

```bash
git status --short
git diff --stat
git diff --check
```

Stage only files named by this plan. If verification required corrections, commit them as:

```bash
git commit -m "fix: complete Scopen project detail verification"
```

Do not stage the unrelated pre-existing untracked design assets, old mock directory, or mock test.
