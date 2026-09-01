# Project Detail Content Components Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` to implement this plan task by task. Each task must be implemented test-first, then reviewed for specification compliance and code quality before moving to the next task.

**Goal:** Replace author-written structural HTML in Project Detail Markdown with an extensible typed-directive compiler and documented component library, then migrate Scopen without changing its approved Hero, Bridge Intro, chapter navigation, or Corner Navigation design.

**Architecture:** Keep `_plugins/project_detail.rb` as a thin Jekyll hook, split the current compiler into source-aware parsing, chapter compilation, registry, render context, component classes, and shared primitives. Components return serializable block hashes; trusted internal Liquid includes render those hashes; Kramdown continues to render ordinary Markdown. SCSS is decomposed by shell, navigation, public component, and shared media primitive. No new gems or component JavaScript are introduced.

**Tech Stack:** Jekyll 4.4.1, Ruby, Kramdown, Liquid includes, SCSS/Sass, existing vanilla JavaScript chapter navigation, dependency-free Ruby test harness.

**Design Specification:** `docs/superpowers/specs/2026-08-27-project-detail-content-components-design.md`

---

## Task 1: Establish Shared Test Infrastructure and Preserve Chapter Behavior

**Files:**

- Create: `test/project_detail/test_helper.rb`
- Create: `test/project_detail/chapter_compiler_test.rb`
- Create: `_plugins/project_detail/errors.rb`
- Create: `_plugins/project_detail/chapter_compiler.rb`
- Modify: `_plugins/project_detail.rb`
- Modify: `test/project_detail_processor_test.rb`

### Step 1: Write the failing chapter compiler tests

Create a reusable assertion runner in `test/project_detail/test_helper.rb` that provides the current `assert`, `refute`, `assert_equal`, `assert_empty`, `assert_nil`, `assert_includes`, `refute_includes`, and `assert_raises` behavior without adding Minitest.

Move chapter-focused cases into `test/project_detail/chapter_compiler_test.rb` and instantiate the planned interface:

```ruby
result = BoningNet::ProjectDetail::ChapterCompiler.new(
  markdown: markdown,
  navigation: "auto",
  intro_style: "featured",
  source_path: "_projects/example.md",
  kramdown_options: {}
).call
```

The tests must preserve:

- Intro extraction and plain Intro retention.
- No-H1 ordinary content.
- Generated and explicit IDs.
- Duplicate explicit-ID errors.
- Repeated generated-title suffixes.
- H2 exclusion from chapter navigation.
- Zero/one/multiple chapter navigation behavior.
- Chapter wrappers and `data-project-chapter` values.

### Step 2: Run the test and confirm the expected failure

Run:

```bash
bundle exec ruby test/project_detail/chapter_compiler_test.rb
```

Expected: failure because `ChapterCompiler` does not exist.

### Step 3: Extract error and chapter classes with no behavior change

Define:

```ruby
module BoningNet
  module ProjectDetail
    class ConfigurationError < StandardError; end
  end
end
```

Move the existing chapter parsing implementation into `ChapterCompiler`. Keep its result keys and behavior stable. Make `_plugins/project_detail.rb` require the new files and keep the current `Compiler`/hook working through `ChapterCompiler`.

### Step 4: Run focused and legacy tests

Run:

```bash
bundle exec ruby test/project_detail/chapter_compiler_test.rb
bundle exec ruby test/project_detail_processor_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: all pass; rendered Scopen and legacy project behavior remain unchanged.

### Step 5: Commit the extraction

```bash
git add _plugins/project_detail.rb _plugins/project_detail/errors.rb _plugins/project_detail/chapter_compiler.rb test/project_detail/test_helper.rb test/project_detail/chapter_compiler_test.rb test/project_detail_processor_test.rb
git commit -m "refactor: isolate project detail chapter compiler"
```

---

## Task 2: Add the Source-Aware Directive Parser and Component Registry

**Files:**

- Create: `_plugins/project_detail/directive_parser.rb`
- Create: `_plugins/project_detail/component_registry.rb`
- Create: `_plugins/project_detail/components/base.rb`
- Create: `test/project_detail/directive_parser_test.rb`
- Create: `test/project_detail/component_registry_test.rb`
- Modify: `_plugins/project_detail.rb`

### Step 1: Write failing parser tests

Test this public parse result shape:

```ruby
node = parser.call.fetch(0)
assert_equal "people", node.name
assert_equal({ "source" => "project team" }, node.attributes)
assert_equal 4, node.start_line
assert_equal 6, node.end_line
```

Cover:

- Empty-body directives.
- Body preservation and source lines.
- Multiple directives in source order.
- Unquoted and quoted `key=value` attributes.
- Malformed attribute failures.
- Missing closing marker failures.
- Nested directive failures.
- Stray closing marker failures.
- Ordinary `:::` text inside fenced code remaining ordinary Markdown.

Errors must include `_projects/example.md:<line>` and a concise diagnosis.

### Step 2: Write failing registry tests

Define the intended API:

```ruby
registry = ComponentRegistry.new
registry.register(FakeComponent)
assert_equal FakeComponent, registry.fetch("fake", source_path: path, line: 3)
assert_equal ["fake"], registry.types
```

Test duplicate registration and unknown directive failures.

`Components::Base` exposes:

```ruby
class << self
  attr_reader :type

  def register_as(value)
    @type = value.freeze
  end
end
```

and an instance contract `#compile(node, context)` that subclasses implement.

### Step 3: Run tests and confirm expected failures

```bash
bundle exec ruby test/project_detail/directive_parser_test.rb
bundle exec ruby test/project_detail/component_registry_test.rb
```

Expected: missing constants/files.

### Step 4: Implement deterministic source parsing and registry

Implement a line-oriented state machine that skips Kramdown fenced code blocks, parses one directive at a time, rejects nesting, and returns immutable `DirectiveNode` values. Parse quoted attributes with Ruby standard-library `Shellwords`; do not add dependencies.

Keep registry construction explicit and deterministic. Do not use filesystem glob autoloading.

### Step 5: Run focused tests and diff checks

```bash
bundle exec ruby test/project_detail/directive_parser_test.rb
bundle exec ruby test/project_detail/component_registry_test.rb
git diff --check
```

### Step 6: Commit parser and registry

```bash
git add _plugins/project_detail.rb _plugins/project_detail/directive_parser.rb _plugins/project_detail/component_registry.rb _plugins/project_detail/components/base.rb test/project_detail/directive_parser_test.rb test/project_detail/component_registry_test.rb
git commit -m "feat: parse project detail directives"
```

---

## Task 3: Add Render Context, Compiler Orchestration, Raw HTML Rejection, and Block Rendering

**Files:**

- Create: `_plugins/project_detail/compiler.rb`
- Create: `_plugins/project_detail/render_context.rb`
- Create: `test/project_detail/compiler_test.rb`
- Modify: `_plugins/project_detail.rb`
- Modify: `_layouts/project-detail.html`

### Step 1: Write failing compiler tests

Test the planned orchestration interface:

```ruby
result = Compiler.new(
  markdown: source,
  config: {},
  frontmatter: {},
  source_path: "_projects/example.md",
  kramdown_options: {},
  registry: registry
).call
```

The result must expose:

```ruby
Result = Struct.new(
  :content,
  :intro_markdown,
  :chapters,
  :navigation_enabled,
  :intro_style,
  :blocks,
  keyword_init: true
)
```

Cover:

- Existing configuration defaults and invalid values.
- Directive nodes dispatched through the registry.
- Generated opaque block IDs stored in `blocks`.
- Source replacement with an internal include reference.
- HTML comments accepted.
- Inline and block author HTML rejected with path and line.
- Legacy layouts unaffected because the hook still checks `layout: project-detail`.

### Step 2: Run the test and confirm failure

```bash
bundle exec ruby test/project_detail/compiler_test.rb
```

Expected: missing `RenderContext` and new compiler behavior.

### Step 3: Implement orchestration

`RenderContext` owns:

- `source_path`
- `frontmatter`
- `kramdown_options`
- current heading label
- per-heading figure counters
- generated block storage
- `#store_block(block) -> id`
- `#error!(message, line:)`

The compiler must reject source HTML before inserting trusted includes, compile directives to block hashes, store blocks in `project_detail_generated.blocks`, and then delegate Intro/chapter work to `ChapterCompiler`.

Use a sentinel token during chapter parsing so internal Liquid markup cannot be mistaken for author HTML. Convert sentinels to internal include tags only after validation and chapter wrapping.

The layout continues consuming `page.project_detail_generated`; no duplicate component data is placed in frontmatter.

### Step 4: Run compiler and rendering tests

```bash
bundle exec ruby test/project_detail/compiler_test.rb
bundle exec ruby test/project_detail_processor_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: all pass and no visible output change yet.

### Step 5: Commit orchestration

```bash
git add _plugins/project_detail.rb _plugins/project_detail/compiler.rb _plugins/project_detail/render_context.rb _layouts/project-detail.html test/project_detail/compiler_test.rb
git commit -m "feat: compile project detail content blocks"
```

---

## Task 4: Implement Shared Figure and Caption Primitives

**Files:**

- Create: `_plugins/project_detail/primitives/caption.rb`
- Create: `_plugins/project_detail/primitives/figure.rb`
- Create: `_plugins/project_detail/components/standalone_figure.rb`
- Create: `_includes/pages/project-detail/blocks/figure.html`
- Create: `_includes/pages/project-detail/blocks/primitives/media-frame.html`
- Create: `_includes/pages/project-detail/blocks/primitives/caption.html`
- Create: `_sass/pages/project-detail/primitives/_media-frame.scss`
- Create: `_sass/pages/project-detail/primitives/_caption.scss`
- Create: `test/project_detail/components/standalone_figure_test.rb`
- Modify: `_plugins/project_detail/compiler.rb`
- Modify: `_sass/pages/_project-detail.scss`

### Step 1: Write failing standalone Figure tests

Cover:

- Standalone Markdown image becomes a `figure` block.
- Inline prose image stays ordinary Markdown.
- Alt, source, and optional image title are preserved.
- Missing alt text fails.
- Title creates caption; no title creates no caption.
- Nearest H1 or H2 heading forms the uppercase label.
- Sequence increments under one heading and resets under the next heading.

Expected block:

```ruby
{
  "type" => "figure",
  "image" => { "src" => "/image.png", "alt" => "Board" },
  "caption" => {
    "label" => "HARDWARE / 01",
    "text" => "Top side with primary control circuitry."
  }
}
```

### Step 2: Run and confirm failure

```bash
bundle exec ruby test/project_detail/components/standalone_figure_test.rb
```

### Step 3: Implement Kramdown-based standalone-image conversion

Inspect Kramdown elements and source locations; do not use rendered-HTML regex. Replace only paragraphs whose sole visible child is one image. Use `Primitives::Figure` and `Primitives::Caption` to normalize data and sequence labels.

### Step 4: Render semantic Figure markup

The internal include must produce one media surface with the approved radius, glass, border, shadow, background, and `overflow: hidden`. Images with their own white background fill the media frame without nested padding or a second glass layer.

Caption styling matches the approved mock: compact monospaced uppercase label left, authored caption right, restrained spacing, and no decorative separator unrelated to the caption relationship.

### Step 5: Run focused and site tests

```bash
bundle exec ruby test/project_detail/components/standalone_figure_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

### Step 6: Commit Figure primitives

```bash
git add _plugins/project_detail/compiler.rb _plugins/project_detail/primitives _plugins/project_detail/components/standalone_figure.rb _includes/pages/project-detail/blocks _sass/pages/_project-detail.scss _sass/pages/project-detail/primitives test/project_detail/components/standalone_figure_test.rb
git commit -m "feat: render project detail figures"
```

---

## Task 5: Implement Narrative Title, Callout, and Featured Link

**Files:**

- Create: `_plugins/project_detail/components/narrative_title.rb`
- Create: `_plugins/project_detail/components/callout.rb`
- Create: `_plugins/project_detail/components/featured_link.rb`
- Create: `_includes/pages/project-detail/blocks/narrative-title.html`
- Create: `_includes/pages/project-detail/blocks/callout.html`
- Create: `_includes/pages/project-detail/blocks/featured-link.html`
- Create: `_sass/pages/project-detail/components/_narrative-title.scss`
- Create: `_sass/pages/project-detail/components/_callout.scss`
- Create: `_sass/pages/project-detail/components/_featured-link.scss`
- Create: `test/project_detail/components/narrative_title_test.rb`
- Create: `test/project_detail/components/callout_test.rb`
- Create: `test/project_detail/components/featured_link_test.rb`
- Modify: `_plugins/project_detail.rb`
- Modify: `_sass/pages/_project-detail.scss`

### Step 1: Write failing component contract tests

Narrative Title tests:

- Valid only as first visible block after an H1.
- Accepts one inline-Markdown paragraph.
- Rejects headings, multiple paragraphs, media, and use elsewhere.
- Marks its chapter so the normal H1 can use label styling.

Callout tests:

- Requires emphasized first paragraph.
- Preserves remaining paragraphs, lists, and links as rendered Markdown.
- Rejects headings, media, raw HTML, nested directives, and empty content.

Featured Link tests:

- Requires exactly one standalone link.
- Preserves label and URL.
- Rejects empty, multiple-link, and prose-plus-link bodies.

### Step 2: Run tests and confirm failures

```bash
bundle exec ruby test/project_detail/components/narrative_title_test.rb
bundle exec ruby test/project_detail/components/callout_test.rb
bundle exec ruby test/project_detail/components/featured_link_test.rb
```

### Step 3: Implement components and register them explicitly

Each component returns only serializable data. Any rendered Markdown stored in a block must be produced with the site's Kramdown options and sanitized by the component's structural validation before rendering.

### Step 4: Add includes and mock-aligned styles

Reuse the current Project Detail type scale, spacing tokens, line color, glass treatment, radius, and shadow. Narrative Title changes hierarchy without changing the semantic chapter anchor. Callout and Featured Link must use distinct visual treatments for distinct content relationships; do not introduce generic horizontal rules.

### Step 5: Run component and rendering tests

```bash
bundle exec ruby test/project_detail/components/narrative_title_test.rb
bundle exec ruby test/project_detail/components/callout_test.rb
bundle exec ruby test/project_detail/components/featured_link_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

### Step 6: Commit the text components

```bash
git add _plugins/project_detail.rb _plugins/project_detail/components _includes/pages/project-detail/blocks _sass/pages/_project-detail.scss _sass/pages/project-detail/components test/project_detail/components
git commit -m "feat: add project detail text components"
```

---

## Task 6: Implement Gallery and Collection Layout Primitives

**Files:**

- Create: `_plugins/project_detail/primitives/collection.rb`
- Create: `_plugins/project_detail/components/gallery.rb`
- Create: `_includes/pages/project-detail/blocks/gallery.html`
- Create: `_sass/pages/project-detail/primitives/_collection.scss`
- Create: `_sass/pages/project-detail/components/_gallery.scss`
- Create: `test/project_detail/components/gallery_test.rb`
- Modify: `_plugins/project_detail.rb`
- Modify: `_sass/pages/_project-detail.scss`

### Step 1: Write failing Gallery tests

Test:

- One image fails with guidance to use plain Markdown image syntax.
- Two images produce `layout: two`.
- Three produce `layout: three`.
- Four produce `layout: four`.
- Five and more produce `layout: masonry`.
- Empty galleries and non-image children fail.
- Every image preserves alt/title and gets its own generated caption label.
- Unknown attributes fail.

### Step 2: Run and confirm failure

```bash
bundle exec ruby test/project_detail/components/gallery_test.rb
```

### Step 3: Implement shared Collection normalization and Gallery compilation

`Primitives::Collection` returns explicit layout metadata from the item count. It must not inspect image dimensions or infer author intent.

### Step 4: Add responsive rendering

- 2/3/4 use CSS Grid and equal aspect-ratio frames.
- 5+ uses CSS multi-column layout and `break-inside: avoid`.
- Desktop uses the specified item-count columns.
- Tablet caps Grid and masonry at two columns.
- Mobile uses one column.
- Each item reuses media-frame and caption primitives.

### Step 5: Run focused, rendering, and stylesheet tests

```bash
bundle exec ruby test/project_detail/components/gallery_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
git diff --check
```

### Step 6: Commit Gallery

```bash
git add _plugins/project_detail.rb _plugins/project_detail/primitives/collection.rb _plugins/project_detail/components/gallery.rb _includes/pages/project-detail/blocks/gallery.html _sass/pages/_project-detail.scss _sass/pages/project-detail/primitives/_collection.scss _sass/pages/project-detail/components/_gallery.scss test/project_detail/components/gallery_test.rb
git commit -m "feat: add project detail galleries"
```

---

## Task 7: Implement Videos and People

**Files:**

- Create: `_plugins/project_detail/components/videos.rb`
- Create: `_plugins/project_detail/components/people.rb`
- Create: `_includes/pages/project-detail/blocks/videos.html`
- Create: `_includes/pages/project-detail/blocks/people.html`
- Create: `_includes/pages/project-detail/blocks/primitives/video-item.html`
- Create: `_includes/pages/project-detail/blocks/primitives/person-card.html`
- Create: `_sass/pages/project-detail/components/_videos.scss`
- Create: `_sass/pages/project-detail/components/_people.scss`
- Create: `test/project_detail/components/videos_test.rb`
- Create: `test/project_detail/components/people_test.rb`
- Modify: `_plugins/project_detail.rb`
- Modify: `_sass/pages/_project-detail.scss`

### Step 1: Write failing Videos tests

Cover:

- YouTube watch, `youtu.be`, and existing embed URL normalization.
- Output always uses `https://www.youtube-nocookie.com/embed/{id}`.
- Link text becomes iframe title; optional link title becomes visible caption.
- One/two/three-plus layout metadata.
- Unsupported hosts, malformed IDs, empty bodies, and non-link children fail.

### Step 2: Write failing People tests

Cover:

- `source` required.
- Source resolves from `frontmatter["people"]`.
- Required `name`, `role`, `image`; optional `url`.
- Unknown source, wrong source type, empty group, unknown keys, and missing values fail.
- Non-linked person emits no URL.
- Generated portrait alt text is stable.

### Step 3: Run and confirm failures

```bash
bundle exec ruby test/project_detail/components/videos_test.rb
bundle exec ruby test/project_detail/components/people_test.rb
```

### Step 4: Implement and register both components

Use `URI` from the Ruby standard library for video URL parsing. Reuse `Primitives::Collection` for column metadata but keep Videos validation separate from Gallery.

People must copy validated fields into block data rather than exposing the entire frontmatter object to includes.

### Step 5: Add accessible includes and responsive styles

Videos use a stable 16:9 frame, lazy iframes, explicit titles, and safe `allow` attributes. People use the same glass/radius/shadow family as other Project Detail media without nesting multiple glass surfaces.

### Step 6: Run tests

```bash
bundle exec ruby test/project_detail/components/videos_test.rb
bundle exec ruby test/project_detail/components/people_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

### Step 7: Commit Videos and People

```bash
git add _plugins/project_detail.rb _plugins/project_detail/components/videos.rb _plugins/project_detail/components/people.rb _includes/pages/project-detail/blocks _sass/pages/_project-detail.scss _sass/pages/project-detail/components test/project_detail/components
git commit -m "feat: add project detail videos and people"
```

---

## Task 8: Decompose Project Detail SCSS Without Visual Regression

**Files:**

- Create: `_sass/pages/project-detail/_shell.scss`
- Create: `_sass/pages/project-detail/_article.scss`
- Create: `_sass/pages/project-detail/_navigation.scss`
- Modify: `_sass/pages/_project-detail.scss`
- Modify: `test/project_detail_rendering_test.rb`

### Step 1: Add failing stylesheet ownership assertions

Extend rendering tests to require compiled selectors for every component and primitive and to reject removed legacy selectors such as `.project-media-grid`, `.project-video-grid`, and `.project-team-grid` after Scopen migration.

Keep existing approved geometry assertions for Hero, Bridge, reading grid, chapter rhythm, and Corner Navigation.

### Step 2: Run rendering test and confirm the expected failure

```bash
bundle exec ruby test/project_detail_rendering_test.rb
```

### Step 3: Move existing rules by ownership

- `_shell.scss`: page tokens, Hero, Bridge Intro, outer containers.
- `_article.scss`: reading grid, chapter typography, prose flow.
- `_navigation.scss`: desktop chapter rail and mobile Corner.
- Component/primitives partials: only their own rules and responsive variants.
- `_project-detail.scss`: imports/uses only.

Do not change approved numeric design values during the move unless a component requires an explicit new value from the mock.

### Step 4: Run rendering tests and compare compiled CSS

```bash
bundle exec ruby test/project_detail_rendering_test.rb
git diff --check
```

### Step 5: Commit style decomposition

```bash
git add _sass/pages/_project-detail.scss _sass/pages/project-detail test/project_detail_rendering_test.rb
git commit -m "refactor: modularize project detail styles"
```

---

## Task 9: Migrate Scopen to Markdown, Directives, and Frontmatter Data

**Files:**

- Modify: `_projects/scopen.md`
- Modify: `test/project_detail_rendering_test.rb`
- Create: `test/project_detail/scopen_source_test.rb`

### Step 1: Write failing source and rendering tests

Source tests must assert:

- No author HTML tags remain in Scopen Markdown.
- Videos use `::: videos`.
- Image groups use `::: gallery`.
- Team uses `::: people source=team`.
- Featured presentation uses `::: featured-link`.
- Structured `people.team` data includes each member's name, role, image, and optional URL.

Rendering tests must assert:

- The five existing chapters and navigation links remain.
- Approved Hero 04 and cover behavior remain.
- Bridge Intro remains.
- Video titles and embed URLs render.
- Gallery captions and generated labels render.
- People names and roles render.
- The existing project technical copy remains present.
- No author directive syntax leaks into HTML.
- No legacy project-detail grid class remains.

### Step 2: Run tests and confirm failure

```bash
bundle exec ruby test/project_detail/scopen_source_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

### Step 3: Convert Scopen content

- Add `people.team` to frontmatter.
- Replace presentation prose link with Featured Link where the approved mock uses the styled action.
- Replace iframe HTML with Videos.
- Replace paired figure HTML with Gallery.
- Add image titles for authored Figure captions.
- Replace team-card HTML with People.
- Add Narrative Title only where it improves the approved mock hierarchy; do not invent it for every chapter.
- Preserve ordinary one-image Markdown for standalone figures.

### Step 4: Build and run focused tests

```bash
bundle exec ruby test/project_detail/scopen_source_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
bundle exec jekyll build
```

### Step 5: Commit Scopen migration

```bash
git add _projects/scopen.md test/project_detail/scopen_source_test.rb test/project_detail_rendering_test.rb
git commit -m "content: migrate Scopen to project components"
```

---

## Task 10: Add Permanent Author and Architecture Documentation

**Files:**

- Create: `docs/project-detail/README.md`
- Create: `docs/project-detail/architecture.md`
- Create: `docs/project-detail/migration.md`
- Create: `docs/project-detail/components/README.md`
- Create: `docs/project-detail/components/narrative-title.md`
- Create: `docs/project-detail/components/figure.md`
- Create: `docs/project-detail/components/gallery.md`
- Create: `docs/project-detail/components/callout.md`
- Create: `docs/project-detail/components/videos.md`
- Create: `docs/project-detail/components/people.md`
- Create: `docs/project-detail/components/featured-link.md`
- Create: `test/project_detail/documentation_test.rb`
- Modify: `docs/content-schema.md`
- Modify: `docs/architecture/frontend.md`
- Modify: `docs/designs/08-26-2026/project-detail-architecture.md`

### Step 1: Write the failing documentation parity test

Load the production registry and assert:

```ruby
expected = registry.types.sort
documented = Dir["docs/project-detail/components/*.md"]
  .map { |path| File.basename(path, ".md") }
  .reject { |name| name == "README" || name == "figure" }
  .sort
assert_equal expected, documented
```

Also assert:

- Component index links every registry type and `figure.md`.
- Every component doc has Purpose, Syntax, Options, Content Contract, Behavior, Generated Semantics, Validation, Examples, and Related Components headings.
- Author README documents Intro, H1 chapters, navigation, and raw HTML policy.
- Architecture and schema cross-links exist.

### Step 2: Run and confirm failure

```bash
bundle exec ruby test/project_detail/documentation_test.rb
```

### Step 3: Write permanent documentation

Use copy-paste-ready Markdown examples that exactly match parser behavior. Document build-error examples and responsive behavior. Clearly separate author API from internal implementation.

Mark `docs/designs/08-26-2026/project-detail-architecture.md` as historical/superseded for current authoring guidance without deleting it.

### Step 4: Run documentation tests and link scan

```bash
bundle exec ruby test/project_detail/documentation_test.rb
rg -n "TODO|TBD|FIXME" docs/project-detail docs/content-schema.md docs/architecture/frontend.md
```

Expected: documentation test passes; `rg` returns no placeholders.

### Step 5: Commit documentation

```bash
git add docs/project-detail docs/content-schema.md docs/architecture/frontend.md docs/designs/08-26-2026/project-detail-architecture.md test/project_detail/documentation_test.rb docs/superpowers/specs/2026-08-27-project-detail-content-components-design.md docs/superpowers/plans/2026-08-27-project-detail-content-components.md
git commit -m "docs: document project detail components"
```

---

## Task 11: Full Regression and Browser Verification

**Files:**

- Modify if defects are found: implementation/test files already listed
- Do not add temporary screenshots or generated `_site` output to Git

### Step 1: Run every Project Detail unit test

```bash
for test_file in test/project_detail/*_test.rb test/project_detail/components/*_test.rb; do
  bundle exec ruby "$test_file"
done
```

Expected: all pass.

### Step 2: Run repository Ruby and JavaScript tests

Discover current test entrypoints from the repository and run all relevant suites, including:

```bash
bundle exec ruby test/project_detail_processor_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
bundle exec ruby test/project_detail_mock_test.rb
```

Run the repository's existing JavaScript test command if one is defined in `package.json`.

### Step 3: Build production output

```bash
JEKYLL_ENV=production bundle exec jekyll build
```

Expected: successful build, no Project Detail warnings, no leaked directive markers.

### Step 4: Browser QA against the approved design

Start the existing local Jekyll server and inspect Scopen at:

- Wide desktop: 3840 × 2160 logical capture or the browser's widest available viewport.
- Desktop: 1440 × 1000.
- Tablet: 820 × 1180.
- Mobile: 390 × 844.

Verify:

- Hero 04 remains `cover` and no top/bottom edge appears while resizing.
- Bridge Intro geometry matches the approved mock.
- Desktop chapter navigation and Mobile Corner behavior are unchanged.
- Corner remains hidden until Main Content begins.
- Figure and Gallery media share the same glass, radius, shadow, background, and full-bleed white-image behavior.
- Caption label/text geometry matches the approved mock.
- Gallery 2/3/4 and masonry responsive layouts behave as specified.
- Videos, Callout, Narrative Title, People, and Featured Link are visually consistent.
- Focus, Escape, reduced motion, and chapter anchors remain functional.

### Step 5: Inspect the final diff and repository state

```bash
git diff --check
git status --short
git diff --stat
```

Confirm no unrelated existing change was discarded, no `_site` output is staged, and no generated image outside the approved Hero set was added.

### Step 6: Request code review and address findings

Use `superpowers:requesting-code-review` for the complete change. Resolve every specification or correctness finding, rerun the affected focused test, then rerun the complete verification set.

### Step 7: Final verification evidence

Use `superpowers:verification-before-completion`. Report the exact successful commands, browser viewports checked, and any remaining risk. Do not claim completion if a relevant suite or viewport was not verified.
