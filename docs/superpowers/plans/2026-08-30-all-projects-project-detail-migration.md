# All Projects Project Detail Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate all eleven remaining portfolio projects to the production Project Detail authoring and rendering system, lightly proofread their copy, and remove the unreachable Bootstrap-era project stack.

**Architecture:** Treat each project document as a validated content unit: featured Intro before the first H1, H1-derived chapters, standalone Markdown figures, and existing typed directives. Add collection-wide source and rendering contracts first, migrate related projects in reviewable groups, then delete legacy code only after a production reference audit proves it unreachable.

**Tech Stack:** Jekyll 4.4.1, Kramdown, Ruby project-detail compiler/tests, Liquid includes, SCSS, vanilla JavaScript

**Spec:** `docs/superpowers/specs/2026-08-30-all-projects-project-detail-migration-design.md`

## Global Constraints

- All migrated projects use `layout: project-detail` and inherit Hero 04 from `project_detail.default_hero`.
- Existing `cover`, date, tags, project URL, attribution, media, and factual claims remain intact.
- All projects use the featured Project Intro and `navigation: auto`; zero or one H1 naturally disables navigation.
- Project content contains no structural HTML, Liquid, Bootstrap classes, or raw iframes.
- Images are standalone, full-width Markdown figures in the original reading order; no gallery or multi-column component is added.
- Videos use one `video-embed` item per directive and remain one per row.
- GitHub/source links use an Intro `featured-link`; live demos remain ordinary links in Main Content.
- Proofreading fixes clear English errors without adding new technical or historical claims.
- Media titles are short noun phrases without sentence-ending punctuation.
- Legacy files are deleted only after every project builds through `project-detail`.

---

### Task 1: Establish the collection-wide migration contract

**Files:**
- Create: `test/project_detail/project_collection_source_test.rb`
- Modify: `test/project_detail_rendering_test.rb`
- Reference: `test/project_detail/scopen_source_test.rb`
- Reference: `test/project_detail/test_helper.rb`

**Interfaces:**
- Consumes: `_projects/*.md`, the existing TinyTestCase assertions, and generated `_site/projects/*.html`.
- Produces: a source contract for every project and a rendered contract that later migration tasks satisfy incrementally.

- [ ] **Step 1: Add a failing collection source test**

Create a test that parses every project frontmatter and body, using the same safe YAML configuration as `scopen_source_test.rb`. The final assertions must be:

```ruby
PROJECT_PATHS = Dir[File.join(ROOT, "_projects", "*.md")].sort.freeze

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
      assert line.match?(/^!\[[^\]]+\]\([^\s)]+\s+"[^".!?]+"\)\s*$/), line
    end
  end
end
```

Implement `parse_project(path)` by matching the two YAML fences, calling `YAML.safe_load` with `Date`, and returning `[frontmatter, body]`. Do not duplicate the project compiler in the test.

- [ ] **Step 2: Run the source test and verify the migration contract fails**

Run:

```bash
bundle exec ruby test/project_detail/project_collection_source_test.rb
```

Expected: FAIL for the eleven `layout: project-post` documents and their raw HTML/Liquid.

- [ ] **Step 3: Add failing rendered collection assertions**

Add a rendering test that iterates the eleven expected slugs after the integration suite builds the site:

```ruby
legacy_slugs = %w[
  ar_domino areusafe chatbot drsstc ecosystem kossel_printer
  msp430_dev nes_emulator simplewatch smartlamp spl_visualization
]

legacy_slugs.each do |slug|
  html = built("projects/#{slug}.html")
  assert_includes html, '<body class="modern-page project-detail-page">'
  assert_includes html, "data-project-detail"
  assert_includes html, "night-instrument-expanded.png"
  refute_includes html, "bootstrap.min.css"
  refute_includes html, "jquery"
  refute_includes html, "project-photo"
end
```

Add focused final assertions for the two legacy video IDs and external destinations:

```ruby
assert_includes built("projects/ar_domino.html"), "www.youtube-nocookie.com/embed/WEThYat87RQ"
assert_includes built("projects/drsstc.html"), "www.youtube-nocookie.com/embed/fd-R-8HahTA"
assert_includes built("projects/spl_visualization.html"), "https://editor.p5js.org/boningUCSB/full/EsJxpC1m"
```

- [ ] **Step 4: Run the rendering test and verify it fails on the legacy shell**

Run:

```bash
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: FAIL because the eleven outputs still include the legacy shell and do not expose `data-project-detail`.

- [ ] **Step 5: Commit the red contract**

```bash
git add test/project_detail/project_collection_source_test.rb test/project_detail_rendering_test.rb
git commit -m "test: define full project migration contract"
```

---

### Task 2: Migrate AreUSafe and Java Ecosystem Simulator

**Files:**
- Modify: `_projects/areusafe.md`
- Modify: `_projects/ecosystem.md`
- Test: `test/project_detail/project_collection_source_test.rb`
- Test: `test/project_detail_rendering_test.rb`

**Interfaces:**
- Consumes: `project-detail`, ordinary figures, `featured-link`, and default `navigation: auto` behavior.
- Produces: two HTML-free software project documents, including one naturally navigation-free short page.

- [ ] **Step 1: Convert AreUSafe to the new source contract**

Use this frontmatter correction and structure:

```yaml
layout: project-detail
title: AreUSafe
subtitle: An Android app for exploring city safety information.
date: 2017-05-01
```

Use the featured Intro lead `Safety information for unfamiliar cities, designed for Android.` The overview must state that this was the author's first Android app, that Tian Gao proposed the idea, and that the author handled UI/UX and Android client development. Use one H1, `# Application`, so navigation remains hidden. Keep the Play Store URL as an ordinary link. Convert the two images to separate figures with titles `City safety overview` and `Safety information detail`.

Correct the false opening `Tesla Coil is an Android App` to `AreUSafe is an Android app`.

- [ ] **Step 2: Convert Ecosystem Simulator to the new source contract**

Use `layout: project-detail`, correct the subtitle to `An ecosystem simulator for exploring individual and group behavior.`, and author this Intro:

```markdown
Model a population by giving every animal its own rules.

This Java simulator explores how individual behavior can produce group-level predator–prey patterns. Tian Gao inspired the project, which I built to practice Java, object-oriented design patterns, and multithreading.

::: featured-link
[View source on GitHub](https://github.com/boningdong/JavaEcoSimulator)
:::
```

Use `# Simulation Model` and `# Results`. Keep the feature list, but correct possessives, verb agreement, `pregnant` phrasing, `Statistician`, and `over time`. Convert both GIFs to figures titled `Sheep and wolf simulation` and `Population trend over time`.

- [ ] **Step 3: Run source and rendering tests**

```bash
bundle exec ruby test/project_detail/project_collection_source_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: the two migrated pages satisfy their individual rendered assertions; the collection test still fails only for the nine remaining legacy projects.

- [ ] **Step 4: Commit the two migrations**

```bash
git add _projects/areusafe.md _projects/ecosystem.md
git commit -m "content: migrate early software projects"
```

---

### Task 3: Migrate AR Domino, AI Chatbot Avatar, and Programming Languages Trend

**Files:**
- Modify: `_projects/ar_domino.md`
- Modify: `_projects/chatbot.md`
- Modify: `_projects/spl_visualization.md`
- Test: `test/project_detail/project_collection_source_test.rb`
- Test: `test/project_detail_rendering_test.rb`

**Interfaces:**
- Consumes: standalone figures, `featured-link`, `video-embed`, H1 navigation, and ordinary Main Content links.
- Produces: three modern interactive-software case studies with source/demo placement matching the design spec.

- [ ] **Step 1: Convert AR Domino**

Remove commented-out frontmatter. Correct the subtitle to `An augmented-reality domino game built with Unity.` Keep the GitHub URL and use this Intro:

```markdown
Build domino runs across virtual and physical surfaces.

AR Domino recreates the placement and chain reaction of domino tiles in augmented reality. The Unity and ARKit application lets players place virtual objects, use tracked physical objects as platforms, and trigger the resulting run.

::: featured-link
[View source on GitHub](https://github.com/boningdong/AR-Domino)
:::
```

Use H1 chapters `# Context`, `# Demo`, `# Implementation`, `# Interaction Design`, and `# Challenges`. Replace the iframe with:

```markdown
::: video-embed
[AR Domino demo](https://youtu.be/WEThYat87RQ "AR Domino gameplay demo")
:::
```

Convert `domino_storytelling.jpg` to a figure titled `Placement controls and interaction layout`. Correct `Story Telling` to `Interaction Design`, `1.Real-world` spacing, `face direction` to `orientation`, and sentence flow without changing the described raycast solution.

- [ ] **Step 2: Convert AI Chatbot Avatar**

Correct `An 3D` to `A 3D` and use the subtitle `A 3D AI avatar for interactive story creation.` Use a featured Intro with the lead `Turn a text conversation into an explorable 3D story.` and an overview that preserves the use of the ChatGPT API, self-trained image models, Unity, and C#.

Use H1 chapters `# Overview`, `# Goals`, and `# Interface`. Move `chatbot_demo_1.jpg` into Overview and convert all four images to standalone figures. Before authoring captions, inspect the images and use accurate, short noun phrases; the required first caption is `3D chatbot environment`. Correct `2 friends and I` to `two friends and I`, remove sentence-initial `And`, correct `practicing animations`, and remove `etc.` from the goals list.

- [ ] **Step 3: Convert Programming Languages Trend**

Correct the subtitle to `A visualization of Seattle Public Library checkout data.` Use this Intro and source link:

```markdown
Trace programming-language popularity through library checkout records.

This MAT 259 project classifies Seattle Public Library checkout data and maps changes in programming-language interest across time in an interactive 3D visualization.

::: featured-link
[View source on GitHub](https://github.com/boningdong/MAT259-3D-Visualization)
:::
```

Use H1 chapters `# Context`, `# Live Demo`, `# Controls`, and `# Visualization Design`. Keep only the p5.js demo link in Live Demo. Correct `Concep`, `naviagate`, capitalization of key names, `popularities`, and the run-on sentence about language comparison. Convert all five images to standalone figures; title the helix diagram `Helical time mapping` and inspect the remaining images for accurate short titles.

- [ ] **Step 4: Run source and rendering tests**

```bash
bundle exec ruby test/project_detail/project_collection_source_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: AR Domino's privacy-enhanced video and SPL's live/source destinations render correctly; six projects now satisfy the source contract.

- [ ] **Step 5: Commit the interactive software migrations**

```bash
git add _projects/ar_domino.md _projects/chatbot.md _projects/spl_visualization.md
git commit -m "content: migrate interactive software projects"
```

---

### Task 4: Migrate Kossel 3D Printer and MSP430 Development Board

**Files:**
- Modify: `_projects/kossel_printer.md`
- Modify: `_projects/msp430_dev.md`
- Test: `test/project_detail/project_collection_source_test.rb`
- Test: `test/project_detail_rendering_test.rb`

**Interfaces:**
- Consumes: featured Intro, standalone figures, and automatic navigation suppression for concise pages.
- Produces: two HTML-free early hardware projects with their complete image sequences.

- [ ] **Step 1: Convert Kossel 3D Printer**

Correct the subtitle to `A self-built, high-precision delta 3D printer.` Use the lead `Rebuild a delta printer around precision instead of compromise.` Preserve the Kossel/Rostock origin and explain that the existing low-quality printer motivated a second build using linear rails and a custom dual-fan effector.

Use H1 chapters `# Context` and `# Build`. Convert all eight images to standalone figures in the current order. Inspect each photo before choosing captions; use `Original Kossel printer` for `kossel_1.jpg`, `Rebuilt printer frame` for `kossel_9.jpg`, and concise part names for the six modeled/printed components. Correct `built-in 2012`, `enable itself to print`, `other Kossel 3D printer`, `I initially have`, and `determined to use` while preserving the self-replication concept.

- [ ] **Step 2: Convert MSP430 Development Board**

Use the subtitle `A custom MSP430 development board for embedded prototyping.` and the lead `Build the development tool the Smart Lamp needed.` Explain in Intro that the MSP430F2132 board was created at Tsinghua University to test Smart Lamp hardware and firmware.

Use H1 chapters `# Board Design` and `# Features`. Convert all three images to standalone figures titled after inspection. Correct the duplicated `development as a development tool board`, `USB to Serial` to `USB-to-serial`, `3 LED`, `debugging purpose`, `Support`, `burn the firmware`, `phrases`, `planing`, and double spaces before `PCBs`. Keep the complete feature and development-phase lists.

- [ ] **Step 3: Run source and rendering tests**

```bash
bundle exec ruby test/project_detail/project_collection_source_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: eight projects satisfy the source contract; the test fails only for NES Emulator, Simple Watch, Smart Lamp, and DRSSTC if Scopen is included in the total.

- [ ] **Step 4: Commit the early hardware migrations**

```bash
git add _projects/kossel_printer.md _projects/msp430_dev.md
git commit -m "content: migrate early hardware projects"
```

---

### Task 5: Migrate Smart Lamp and Simple Watch

**Files:**
- Modify: `_projects/smartlamp.md`
- Modify: `_projects/simplewatch.md`
- Test: `test/project_detail/project_collection_source_test.rb`
- Test: `test/project_detail_rendering_test.rb`

**Interfaces:**
- Consumes: featured Intro, source `featured-link`, H1 navigation, and standalone figures.
- Produces: two product-oriented embedded projects with corrected development status and preserved GitHub destinations.

- [ ] **Step 1: Convert Smart Lamp**

Use the subtitle `A Bluetooth-controlled smart lamp designed from hardware to enclosure.` and this Intro structure:

```markdown
A connected light designed as a complete product.

Smart Lamp began as a gift for my high-school friends and teachers before I moved to the United States. Building on work from Dr. Lintao Tang's lab at Tsinghua University, I designed the hardware, firmware, and enclosure as one system.

::: featured-link
[View source on GitHub](https://github.com/boningdong/Smart-Lamp)
:::
```

Use `# Context`, `# Features`, and `# Development`. Move the three opening images into Context and the final two into Development as standalone figures. Inspect and caption each photo. Correct `Bachelor's'`, `limitation of time`, repeated `product-level product`, `simulator`, `by capacitive touch interface`, `connect the lamp using Bluetooth`, `Micro-USB`, `three phrases charging`, `planing`, `ID design`, and list capitalization.

- [ ] **Step 2: Convert Simple Watch**

Use the subtitle `A compact smartwatch designed from circuit board to firmware.` and the lead `Use a watch-sized PCB to test product-level system design.` Keep the GitHub destination in an Intro `featured-link`.

Use `# Design Goals`, `# Development`, and `# Current Status`. Preserve that the project was unfinished as of the 2019 update. Convert all four images to standalone figures after inspection. Correct tense, `PCB designing`, spaces inside parentheses, duplicated `simple watch`, missing verb in `and capable`, `phrases`, `planing`, double spaces, and the unclear sentence about zero-ohm resistors by stating that they allowed subsystems to be isolated during validation.

- [ ] **Step 3: Run source and rendering tests**

```bash
bundle exec ruby test/project_detail/project_collection_source_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: ten migrated projects plus Scopen satisfy the source contract; only the two remaining legacy hardware pages fail.

- [ ] **Step 4: Commit the product hardware migrations**

```bash
git add _projects/smartlamp.md _projects/simplewatch.md
git commit -m "content: migrate product hardware projects"
```

---

### Task 6: Migrate NES Emulator Project and DRSSTC

**Files:**
- Modify: `_projects/nes_emulator.md`
- Modify: `_projects/drsstc.md`
- Test: `test/project_detail/project_collection_source_test.rb`
- Test: `test/project_detail_rendering_test.rb`

**Interfaces:**
- Consumes: source `featured-link`, `video-embed`, standalone figures, and H1 navigation.
- Produces: the final two migrated project documents and a fully green collection source contract.

- [ ] **Step 1: Convert NES Emulator Project**

Correct the title to `NES Emulator Project` and subtitle to `A custom game console that runs NES software on an STM32.` Use a featured Intro lead `Build the console, then emulate the machine.` Preserve Jeff's attribution and the UCSB ECE 153B context, and use the existing GitHub URL in `featured-link`.

Use `# Context`, `# Engineering Challenges`, `# Development`, and `# Current Status`. Preserve the dated incomplete status. Convert the four images to standalone figures after inspection. Correct the opening run-on sentence, `The idea is from Jeff`, `did attract me`, `24bits Parallel LCD screen`, `ports planning`, `NES CPU`, `phrases`, `planing`, `the PCBs`, `proceed more tests`, and agreement around CPU/PPU progress.

- [ ] **Step 2: Convert DRSSTC**

Keep the full title and correct the subtitle to `A high-frequency, high-voltage transformer that plays music with lightning.` Use the lead `Turn power electronics into a musical high-voltage instrument.` Preserve UCSB IEEE, Spring 2018, and the author's leadership role. Put the existing GitHub URL in an Intro `featured-link`.

Use `# Context`, `# Engineering Scope`, `# Parameters`, and `# Results`. Convert the three opening images and three result photos to standalone figures in order. Replace the raw iframe with:

```markdown
::: video-embed
[DRSSTC performance](https://youtu.be/fd-R-8HahTA "Musical arc demonstration")
:::
```

Keep all numeric parameters. Correct `Tesla Coil` capitalization where generic, the historical paragraph's grammar without changing its claims, `determined to build`, `really good`, `fields together`, `basic analog circuit`, `PCB designing`, `In the same time`, `hand-on`, `mechanical structure`, `arch` to `arc`, `1.3 meters long`, and `800W` spacing.

- [ ] **Step 3: Run the source and rendering contracts**

```bash
bundle exec ruby test/project_detail/project_collection_source_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: PASS for all twelve project sources and every generated project page, including both privacy-enhanced YouTube embeds.

- [ ] **Step 4: Commit the final project migrations**

```bash
git add _projects/nes_emulator.md _projects/drsstc.md
git commit -m "content: complete project detail migration"
```

---

### Task 7: Update the permanent authoring and repository instructions

**Files:**
- Modify: `docs/content-schema.md`
- Modify: `docs/architecture/frontend.md`
- Modify: `docs/project-detail/README.md`
- Modify: `docs/project-detail/migration.md`
- Modify: `docs/project-detail/architecture.md`
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Test: `test/project_detail/documentation_test.rb`

**Interfaces:**
- Consumes: the now-universal `project-detail` contract.
- Produces: documentation that never instructs authors to create or retain `project-post` pages.

- [ ] **Step 1: Strengthen the documentation test before editing docs**

Add assertions that permanent docs and instruction files contain no `layout: project-post` or statements that legacy project pages remain supported:

```ruby
paths = %w[
  docs/content-schema.md
  docs/architecture/frontend.md
  docs/project-detail/README.md
  docs/project-detail/migration.md
  docs/project-detail/architecture.md
  AGENTS.md
  CLAUDE.md
]

paths.each do |path|
  text = File.read(File.join(ROOT, path))
  refute_includes text, "layout: project-post"
  refute_includes text, "layout: `project-post`"
end
```

- [ ] **Step 2: Run the documentation test and verify it fails**

```bash
bundle exec ruby test/project_detail/documentation_test.rb
```

Expected: FAIL on the existing coexistence and legacy authoring text.

- [ ] **Step 3: Rewrite permanent docs around one project contract**

Update `content-schema.md` to show `layout: project-detail` and link the author guide. Update frontend architecture to remove the two-shell project transition. Change the migration guide from an active coexistence guide into a completed migration/reference checklist, retaining useful HTML-to-component mappings. Remove the Scopen-only rollout language from the Project Detail README and architecture.

Update `AGENTS.md` and `CLAUDE.md` so their Project Overview, Main Layouts, Adding New Projects, and Development Notes identify `project-detail.html`, the H1 navigation model, Markdown figures, and typed directives. Do not add instructions unrelated to project authoring.

- [ ] **Step 4: Run documentation and source tests**

```bash
bundle exec ruby test/project_detail/documentation_test.rb
bundle exec ruby test/project_detail/project_collection_source_test.rb
```

Expected: PASS.

- [ ] **Step 5: Commit documentation updates**

```bash
git add AGENTS.md CLAUDE.md docs/content-schema.md docs/architecture/frontend.md docs/project-detail test/project_detail/documentation_test.rb
git commit -m "docs: make project detail the sole authoring contract"
```

---

### Task 8: Retire the unreachable legacy project stack

**Files:**
- Delete when unreferenced: `_layouts/project-post.html`
- Delete when unreferenced: `_layouts/default.html`
- Delete when unreferenced: `_includes/header.html`
- Delete when unreferenced: `_includes/showcase/*.html`
- Delete when unreferenced: `assets/css/showcase/*.scss`
- Delete when unreferenced: `_sass/showcase/*.scss`
- Modify: `test/modern_pages_test.rb`
- Modify: `test/project_detail_rendering_test.rb`

**Interfaces:**
- Consumes: a fully migrated collection and repository reference scan.
- Produces: a modern-only production page graph without Bootstrap, jQuery, Popper, the legacy project shell, or project-only showcase CSS.

- [ ] **Step 1: Record the production reachability graph**

Run:

```bash
rg -n 'project-post|layout:\s*default|include\s+showcase/|assets/css/showcase|_sass/showcase|bootstrap|min\.js|jquery|popper' \
  --glob '!docs/designs/**' --glob '!docs/superpowers/**' --glob '!_site/**' .
```

Classify every result as a production reference, permanent documentation reference, test fixture, or historical design artifact. Do not delete a file with a production consumer.

- [ ] **Step 2: Add failing modern-only architecture assertions**

Extend `modern_pages_test.rb` and the rendering integration test to assert:

```ruby
%w[_layouts/project-post.html _layouts/default.html _includes/header.html].each do |path|
  refute File.exist?(File.join(ROOT, path)), "expected #{path} to be retired"
end

Dir[File.join(ROOT, "_site", "projects", "*.html")].each do |path|
  html = File.read(path)
  refute_includes html, "bootstrap"
  refute_includes html, "jquery"
  refute_includes html, "popper"
  refute_includes html, "project-posts.css"
end
```

Also assert the production source tree contains no page or layout frontmatter using `default` or `project-post`.

- [ ] **Step 3: Run architecture tests and verify they fail before deletion**

```bash
bundle exec ruby test/modern_pages_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: FAIL because the legacy files still exist.

- [ ] **Step 4: Delete only the files proven unreachable**

Remove the three legacy shell files. Remove each `_includes/showcase`, `assets/css/showcase`, and `_sass/showcase` file only when Step 1 found no production consumer. The expected final state is removal of those directories because all top-level pages and all project pages use the modern shell; re-run the scan if any unexpected consumer appears.

Do not delete `_tags`, project image assets, `docs/designs`, modern page includes, or the Project Detail compiler/components.

- [ ] **Step 5: Build and run architecture tests after cleanup**

```bash
JEKYLL_ENV=production bundle exec jekyll build
bundle exec ruby test/modern_pages_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
```

Expected: PASS with no missing include, stylesheet, or asset errors.

- [ ] **Step 6: Re-run the reference scan**

```bash
rg -n 'project-post|layout:\s*default|include\s+showcase/|assets/css/showcase|bootstrap|min\.js|jquery|popper' \
  --glob '!docs/designs/**' --glob '!docs/superpowers/**' --glob '!_site/**' .
```

Expected: no production references. Test text that asserts absence may remain.

- [ ] **Step 7: Commit legacy retirement**

```bash
git add -A
git commit -m "refactor: retire legacy project page stack"
```

---

### Task 9: Run the final migration verification matrix

**Files:**
- Verify: `_projects/*.md`
- Verify: `_site/projects/*.html`
- Verify: all files changed by Tasks 1–8

**Interfaces:**
- Consumes: the completed migrated collection and cleaned production graph.
- Produces: fresh evidence that source, rendering, JavaScript, documentation, and production builds agree.

- [ ] **Step 1: Run every Project Detail unit and component test**

```bash
for test_file in test/project_detail/*_test.rb test/project_detail/components/*_test.rb; do
  bundle exec ruby "$test_file" || exit 1
done
```

Expected: all files report zero failures.

- [ ] **Step 2: Run rendered-page and modern-page integration tests**

```bash
bundle exec ruby test/project_detail_rendering_test.rb
bundle exec ruby test/modern_pages_test.rb
```

Expected: all tests pass.

- [ ] **Step 3: Run browser behavior tests**

```bash
node --test test/javascript/*.test.js
```

Expected: all tests pass with zero skipped or cancelled tests.

- [ ] **Step 4: Build the production site**

```bash
JEKYLL_ENV=production bundle exec jekyll build
```

Expected: exit 0 with all twelve project outputs generated.

- [ ] **Step 5: Verify repository and generated output hygiene**

```bash
git diff --check
rg -n '<div|<iframe|\{[{%]' _projects
rg -n 'bootstrap|jquery|popper|project-posts\.css' _site/projects
git status --short
```

Expected: the two `rg` commands return no matches, `git diff --check` succeeds, and status contains only intentional uncommitted verification-report changes if such a report was explicitly added.

- [ ] **Step 6: Review the final diff by project and dependency family**

```bash
git diff --stat HEAD~8..HEAD
git log --oneline --decorate -10
```

Confirm all eleven project files, permanent documentation, instruction files, tests, and legacy deletions are represented. Confirm no project asset directory was removed.

