# Experiences / Resume Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy résumé page with the approved dependency-free Experiences / Education timeline while preserving the existing collection content and unifying all three content-list heroes at `400px`.

**Architecture:** Jekyll and Liquid render a complete, readable document from `site.experiences` and `_data/education.yml`; page-specific includes own hero, work timeline, and education markup. A dependency-free page controller progressively enhances the readable details into a single-open accordion, while a dedicated Sass page module implements the approved geometry and responsive behavior through the existing modern token system.

**Tech Stack:** Jekyll 4.4.1, Liquid, YAML, SCSS/Sass, dependency-free JavaScript, Ruby output tests, Node's built-in test runner, in-app browser visual verification.

## Global Constraints

- Work only in `/Users/boning/Projects/boning-net` on the existing `dev/boning/css-modernization` branch; the approved baseline `00fce84203703e1b7254356496e96190f2a16222` is an ancestor of `HEAD`.
- Do not stage, commit, modify, or delete the untracked `.superpowers/` directory.
- Do not add Bootstrap, jQuery, Popper, or any new frontend dependency.
- Keep one uninterrupted Mist content surface after the hero, with Work Experience followed by Education and no Career Path intro, Awards, Skills, Tune panel, Detail Dock, presets, or design-lab controls.
- Render only `shown: true` experiences, sorted by `start-date` descending; the production output must contain exactly five current visible roles.
- Use the approved page values exactly: `400px` hero minimum, `122px` collapsed summary, `26px` card radius, `20px` timeline entry gap, `112px`/`80px` desktop outer/internal spacing, and approximately `81px`/`58px` mobile spacing.
- Keep every timeline node centered at `122px / 2` from the top of its card even when the detail region expands.
- Preserve readable details without JavaScript; JavaScript must initialize all entries closed, allow only one open entry, synchronize `aria-expanded`, support native button keyboard behavior, and tolerate missing page controls.
- Keep the approved Experiences visual direction unchanged and reuse the shared navigation, compact footer, typefaces, focus treatment, reduced-motion contract, and design tokens.
- Correct visible `Microsof` labels to `Microsoft` without changing the substance of the experience descriptions.

---

### Task 1: Add Generated-Page Acceptance Coverage and Confirm RED

**Files:**
- Modify: `test/modern_pages_test.rb`
- Test: `_site/resume.html`
- Test: `_site/assets/css/main.css`

**Interfaces:**
- Consumes: Jekyll output from `bundle exec jekyll build`.
- Produces: output-level contracts for the modern shell, data counts/order, semantic sections, progressive-enhancement markup, forbidden dependencies/controls, and the three shared hero heights.

- [ ] **Step 1: Add a page-shell and data-flow test**

Add a test that loads `resume.html` and asserts the literal modern body class, active Experiences navigation, page controller script, five `data-experience-card` articles, two `data-education-card` articles, and absence of Bootstrap/jQuery:

```ruby
"Experiences page uses the modern collection-backed shell" => lambda do
  html = built("resume.html")

  assert_includes html, '<body class="modern-page experiences-page">'
  assert_includes html, 'href="/resume.html" class="active" aria-current="page">Experiences</a>'
  assert_includes html, '/assets/js/pages/experiences.js'
  assert(html.scan("data-experience-card").length == 5, "expected five visible work entries")
  assert(html.scan("data-education-card").length == 2, "expected two education entries")
  refute_includes html, "bootstrap.min.css"
  refute_includes html, "jquery"
end,
```

- [ ] **Step 2: Add hierarchy, ordering, content, accessibility, and exclusion assertions**

Add a second test that proves Work precedes Education, Apple is the first visible role, Microsoft is spelled correctly, AIRTIST is absent, both UCSB degrees and the two undergraduate notes render, every trigger has `aria-controls`, and no unapproved section or design-lab controls ship:

```ruby
"Experiences page preserves the approved hierarchy and readable details" => lambda do
  html = built("resume.html")
  work_position = html.index('id="work-experience-title"')
  education_position = html.index('id="education-title"')
  first_role_position = html.index('data-experience-card')

  assert(work_position && education_position && work_position < education_position, "expected Work Experience before Education")
  assert(first_role_position && html.index("Apple", first_role_position) < html.index("Microsoft", first_role_position), "expected reverse chronological work order")
  assert_includes html, "Master’s degree"
  assert_includes html, "Bachelor’s degree"
  assert_includes html, "GPA 3.95"
  assert_includes html, "IEEE Student Branch"
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
```

- [ ] **Step 3: Expand the global design-lab exclusion test**

Include `built("resume.html")` in the joined modern-page HTML and keep the existing forbidden-control regular expression unchanged so the new page is protected by the same regression check.

- [ ] **Step 4: Add compiled-style contracts for page geometry**

Add assertions against built `main.css` that require the Experiences module, `--experience-summary-height:122px`, `--experience-card-gap:20px`, `min-height:400px` for `.projects-hero`, `.artwork-hero`, and `.experiences-hero`, and a node top derived from half the fixed summary height rather than card height:

```ruby
"content-list heroes and Experiences timeline compile approved geometry" => lambda do
  css = built("assets/css/main.css")

  assert_includes css, ".experiences-page"
  assert_includes css, "--experience-summary-height: 122px"
  assert_includes css, "--experience-card-gap: 20px"
  assert(css.match?(/\.projects-hero\{[^}]*min-height:400px/), "expected Projects hero to compile at 400px")
  assert(css.match?(/\.artwork-hero\{[^}]*min-height:400px/), "expected Artwork hero to compile at 400px")
  assert(css.match?(/\.experiences-hero\{[^}]*min-height:400px/), "expected Experiences hero to compile at 400px")
  assert_includes css, "top:calc(var(--experience-summary-height)/2 - 10px)"
end,
```

- [ ] **Step 5: Build legacy output and verify the new tests fail for the intended missing modernization**

Run:

```bash
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
```

Expected: the build succeeds, existing tests remain green, and the new Experiences/hero tests fail because `resume.html` is still legacy and the new Sass/data/controller are absent.

### Task 2: Render the Approved Experiences and Education Document

**Files:**
- Create: `_data/education.yml`
- Create: `_includes/pages/experiences/hero.html`
- Create: `_includes/pages/experiences/work.html`
- Create: `_includes/pages/experiences/work-card.html`
- Create: `_includes/pages/experiences/education.html`
- Modify: `resume.html`
- Modify: `_experiences/microsoft-2019.md`
- Modify: `_experiences/microsoft-2020.md`
- Modify: `docs/content-schema.md`
- Test: `test/modern_pages_test.rb`

**Interfaces:**
- Consumes: `site.experiences`, with fields `company`, `job-title`, `start-date`, optional `end-date`, optional `logo`, `shown`, and Markdown body; `site.data.education`, with `institution`, `mark`, `degree`, `field`, `period`, and `details`.
- Produces: complete semantic HTML with stable `data-experience-*` hooks, button/panel relationships, and no-JavaScript-readable details for the page controller and Sass module.

- [ ] **Step 1: Add the two approved education records**

Create `_data/education.yml` with exactly:

```yaml
- institution: UC Santa Barbara
  mark: UCSB
  degree: Master’s degree
  field: Computer Engineering
  period: "2021"
  details: []

- institution: UC Santa Barbara
  mark: UCSB
  degree: Bachelor’s degree
  field: Computer Engineering
  period: 2016–2020
  details:
    - GPA 3.95
    - IEEE Student Branch
```

- [ ] **Step 2: Create the shared content-page Experiences hero include**

Render `/assets/img/showcase/experience-banner.jpg` with meaningful alt text and high fetch priority, the title `Experience / Education`, metadata `Embedded systems / Hardware / Product craft`, and the lower-right label `Career archive / 2017—Now` using `.experiences-hero`, `.experiences-hero-image`, `.experiences-hero-copy`, and `.experiences-hero-index` classes.

- [ ] **Step 3: Create the work-card include with progressive-enhancement semantics**

For each `include.job`, render one `<article data-experience-card>`, a fixed `.role-summary`, an integrated `.role-logo` region with either `<img alt="{{ include.job.company }} logo">` or a text fallback, role/company/date content, and a native button. Render the button and panel initially expanded (`aria-expanded="true"`, `aria-hidden="false"`) so their attributes match the readable no-JavaScript document; use `data-experience-toggle`, `data-experience-toggle-label`, and `data-experience-details` hooks so the controller can close them after enhancement. Use `Now` when `end-date` is absent and render the collection Markdown body through `markdownify` inside the detail panel.

- [ ] **Step 4: Create the work and education section includes**

`work.html` must render the `Career timeline` kicker, `Work Experience` heading, `01 / 02`, and each filtered/sorted role inside one `.experience-timeline`. `education.html` must render the `Foundation` kicker, `Education` heading, `02 / 02`, and two equal-hierarchy cards sourced only from `site.data.education`; loop through `details` without inventing additional credential content.

- [ ] **Step 5: Replace the legacy résumé entry point**

Change `resume.html` frontmatter to:

```yaml
---
layout: modern
title: Experiences
browser_title: Boning's Experiences
body_class: experiences-page
nav_active: experiences
footer_variant: compact
scripts:
  - /assets/js/pages/experiences.js
---
```

Then filter and sort in Liquid:

```liquid
{% assign visible_experiences = site.experiences | where: "shown", true | sort: "start-date" | reverse %}
{% include pages/experiences/hero.html experiences=visible_experiences %}
<main class="experiences-content" data-experiences-page>
  {% include pages/experiences/work.html experiences=visible_experiences %}
  {% include pages/experiences/education.html education=site.data.education %}
</main>
```

- [ ] **Step 6: Correct only the two visible Microsoft company labels**

Change `company: Microsof` to `company: Microsoft` in `_experiences/microsoft-2019.md` and `_experiences/microsoft-2020.md`; leave their role descriptions and all other collection content unchanged.

- [ ] **Step 7: Document the Education data schema and modern rendering boundary**

Extend `docs/content-schema.md` with the exact `_data/education.yml` fields, note that `details` is an array of optional credential notes, and clarify that the Experiences page filters `shown: true`, sorts by `start-date` descending, renders `Now` for missing end dates, and keeps Markdown bodies readable without JavaScript.

- [ ] **Step 8: Build and run the page-output test**

Run:

```bash
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
```

Expected: markup/data tests pass; the Sass geometry test still fails because the Experiences module and shared hero corrections are not implemented yet.

### Task 3: Build and Test the Single-Open Accordion Controller

**Files:**
- Create: `test/javascript/experiences.test.js`
- Create: `assets/js/pages/experiences.js`

**Interfaces:**
- Consumes: a root matching `[data-experiences-page]`, cards matching `[data-experience-card]`, buttons matching `[data-experience-toggle]`, label nodes matching `[data-experience-toggle-label]`, and panels matching `[data-experience-details]`.
- Produces: `init(root?)`, `setCardExpanded(card, expanded)`, and single-open click behavior; CommonJS exports support Node tests and the browser branch initializes after DOM readiness.

- [ ] **Step 1: Write a DOM-behavior test harness and failing tests**

Use small in-memory elements implementing the actual controller boundary (`querySelector`, `querySelectorAll`, `addEventListener`, `setAttribute`, and `classList.toggle`). Add tests that initialize three expanded cards and assert all become closed, click the first then second trigger and assert only the most recent card is open with correct `aria-expanded`, `aria-hidden`, and Details/Close text, click the open trigger again to close it, and call `init` with a missing root/card control without throwing.

- [ ] **Step 2: Run the Experiences JavaScript test and confirm RED**

Run:

```bash
node --test test/javascript/experiences.test.js
```

Expected: failure because `assets/js/pages/experiences.js` does not exist.

- [ ] **Step 3: Implement the minimal UMD-style page controller**

Match existing modern page modules. `setCardExpanded` must toggle `.is-open`, set the trigger's `aria-expanded`, set the panel's `aria-hidden`, and switch the visible label between `Details` and `Close`. `init` must resolve `document.querySelector('[data-experiences-page]')` when no root is passed, return safely when the root or controls are missing, add `.is-enhanced`, close every valid card, and attach click listeners that close all cards before opening only the requested closed card.

- [ ] **Step 4: Run the targeted and complete JavaScript suites**

Run:

```bash
node --test test/javascript/experiences.test.js
node --test test/javascript/*.test.js
```

Expected: all Experiences behavior tests and all existing JavaScript tests pass with zero failures.

### Task 4: Implement the Approved Visual System and Shared Hero Height

**Files:**
- Create: `_sass/pages/_experiences.scss`
- Modify: `assets/css/main.scss`
- Modify: `_sass/pages/_projects.scss`
- Modify: `_sass/pages/_artwork.scss`
- Test: `test/modern_pages_test.rb`

**Interfaces:**
- Consumes: the Task 2 markup classes/hooks and shared properties from `_sass/foundation/_variables.scss`.
- Produces: one continuous Mist surface, fixed summary/node geometry, progressive accordion states, responsive education pairing/stacking, and `400px` computed list-page heroes.

- [ ] **Step 1: Add the Experiences Sass module to the modern entry point**

Append `@use "pages/experiences";` to `assets/css/main.scss` after the existing page modules.

- [ ] **Step 2: Implement the Experiences hero and continuous Mist surface**

Use the shared `34% → 8%` horizontal and `4% / 2% / 34%` vertical overlays, preserve the banner focal position near `center 48%`, set `min-height: 400px`, and match existing content-page title/metadata/index type roles. Style `.experiences-content` as one uninterrupted Mist background; apply `112px` above Work, `80px` between Work and Education, and `112px` below Education, with the shared `80.64px` and `57.6px` mobile equivalents.

- [ ] **Step 3: Implement the timeline axis, fixed summary, integrated logo region, and card material**

Set `--experience-summary-height: 122px` and `--experience-card-gap: 20px` on `.experiences-page`. Use a `1px` steel/blue-gray gradient axis whose endpoints align with the first and last summary centers. Place each `20px` outer-diameter node with `top: calc(var(--experience-summary-height) / 2 - 10px)` so expansion never recenters it. Use shared `26px` radius, Ice translucent fill, light edge/inset highlight, `18px` blur, and `10%` shadow. Keep the brand region integrated at `132px`, with radial light and a fading vertical hairline; never add an inner logo border, background box, or radius.

- [ ] **Step 4: Implement fixed desktop, medium, and small summary compositions**

Desktop uses `132px minmax(0, 1fr) auto auto`. At medium widths, retain horizontal brand/content structure with a `104px` brand column, move the date under role copy, and keep the action at the right. At `640px` and below, use a `76px` brand column, keep the vertical divider, hide only the optional summary excerpt and visible Details/Close word while preserving the accessible button name, and prevent overflow. The summary remains exactly `122px` at every width.

- [ ] **Step 5: Implement progressive accordion and accessibility visuals**

Before `.is-enhanced`, show detail content and hide nonfunctional toggle buttons. After enhancement, show buttons and animate the detail grid from `0fr` to `1fr` only for `.is-open`; keep the summary height unchanged. Use the shared focus-visible ring, add an explicit forced-colors outline, and suppress hover lift/detail animation under reduced motion or non-hover input as appropriate.

- [ ] **Step 6: Implement paired Education cards**

Use two equal columns on desktop with `20px` gap and stack below the medium breakpoint. Match the approved Ice glass geometry, UCSB mark, utility period label, display-face degree title, and credential-note footer; cards must not introduce a new background section between Work and Education.

- [ ] **Step 7: Set all three content-list heroes to `400px` at every viewport**

Replace `.projects-hero` and `.artwork-hero` `min-height: 60svh` with `min-height: 400px` and remove their mobile `54svh` overrides. Preserve all page-specific image sources, focal positions, overlays, titles, metadata, and indexes.

- [ ] **Step 8: Build and run the full generated-page suite**

Run:

```bash
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
```

Expected: every modern-page output and compiled-style test passes with zero failures.

### Task 5: Verify Rendering, Review the Diff, and Commit

**Files:**
- Modify only when a verified failure requires a scoped TDD fix.
- Create screenshots under `/tmp` so verification artifacts are not committed.

**Interfaces:**
- Consumes: the complete production tree from Tasks 1–4.
- Produces: fresh automated/build evidence, browser geometry/accessibility evidence, independent code-review findings, and one clean implementation commit.

- [ ] **Step 1: Run fresh automated verification**

Run:

```bash
env JEKYLL_ENV=production /Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
node --test test/javascript/*.test.js
git diff --check
```

Expected: production build exits 0, all Ruby tests pass, all JavaScript tests pass, and the diff has no whitespace errors.

- [ ] **Step 2: Start a local production-equivalent server**

Run `/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll serve --host 127.0.0.1 --port 4000` in a persistent terminal session and use the in-app browser for all remaining checks.

- [ ] **Step 3: Check desktop, medium, and mobile layouts**

At approximately `1440×1000`, `820×900`, and `390×844`, load `/resume.html` and verify: body is modern; no horizontal overflow; all images have positive natural dimensions; computed hero height is exactly `400px`; every collapsed summary is exactly `122px`; Work and Education share one background; Education is two columns on desktop and one on mobile; all fonts resolve to the intended family roles; and the browser console has no errors.

- [ ] **Step 4: Measure the fixed node anchor before and after expansion**

For every viewport, evaluate each card's summary and node geometry from `getBoundingClientRect()` plus `getComputedStyle(card, '::before')`. Record the node center relative to the card top while collapsed, open one card, record it again, and require both values to remain `61px` within subpixel rounding tolerance. Also verify exactly one card can be open and `aria-expanded`/`aria-hidden` agree with its visual state.

- [ ] **Step 5: Capture collapsed and expanded screenshots**

Save one collapsed and one expanded Experiences screenshot per viewport under `/tmp/boning-net-experiences/`. Inspect brand integration, fading divider, Ice material, 26px corners, 20px rhythm, axis/node language, details readability, focus visibility, education pairing/stacking, image loading, and absence of clipping or overflow.

- [ ] **Step 6: Check keyboard, no-JavaScript fallback, reduced motion, and all three heroes**

Use Tab then Enter/Space to operate role triggers and confirm visible focus. Emulate `prefers-reduced-motion: reduce` and confirm state changes are effectively immediate. Disable JavaScript for a fresh Experiences load or inspect the generated HTML without running its controller and confirm all details remain readable. Visit `/projects.html`, `/artwork.html`, and `/resume.html` at all three viewports and require every hero's computed height to equal `400px` while images, focal positions, overlays, titles, and metadata remain intact.

- [ ] **Step 7: Review protected paths and request independent code review**

Run:

```bash
git status --short
git diff --stat 00fce84
git diff 00fce84 -- docs/designs/08-15-2026 .superpowers
```

Expected: `.superpowers/` remains untracked and unchanged, approved design files have no diff, and only planned implementation/test/schema/plan files differ. Dispatch `superpowers:requesting-code-review` against `00fce84..HEAD` plus the working-tree diff; fix all verified Critical and Important findings using a failing test first, then rerun Steps 1, 3, 4, and 6 when relevant.

- [ ] **Step 8: Run the final verification gate and commit only planned paths**

Run the complete Step 1 command set again after review fixes. Then stage explicit planned paths—never `.superpowers/`—and commit:

```bash
git add resume.html _data/education.yml _includes/pages/experiences _sass/pages/_experiences.scss _sass/pages/_projects.scss _sass/pages/_artwork.scss assets/css/main.scss assets/js/pages/experiences.js _experiences/microsoft-2019.md _experiences/microsoft-2020.md docs/content-schema.md docs/superpowers/plans/2026-08-16-experiences-resume-modernization.md test/modern_pages_test.rb test/javascript/experiences.test.js
git commit -m "feat: modernize experiences timeline"
```

- [ ] **Step 9: Verify the committed tree and prepare the handoff**

Run `git status --short --branch`, `git show --stat --oneline --decorate HEAD`, and `git diff --check HEAD^ HEAD`. Report the outcome, exact automated and browser checks actually completed, the commit SHA/message, and any check not completed or remaining risk without claiming unrun verification.

---

## Self-Review

- Spec coverage: modern shell, continuous Mist hierarchy, exact work filtering/order/count, education data/count/content, fixed card geometry, integrated brand treatment, fixed node anchoring, single-open progressive accordion, accessibility/reduced motion, responsive education, shared `400px` heroes, spelling repair, dependency boundary, output/JavaScript tests, production build, three-viewport screenshots, console/assets/overflow/focus checks, protected `.superpowers/`, review, and commit are each assigned to explicit steps.
- Placeholder scan: the plan contains no deferred implementation markers; every created file has an exact responsibility, stable interface, and verification command.
- Interface consistency: Liquid emits the same `data-experience-*` hooks consumed by `experiences.js`; the JavaScript tests exercise the exported `init` and `setCardExpanded` boundary; Sass targets the exact class names emitted by the page includes; Ruby tests inspect the generated filenames produced by the modern layout.
