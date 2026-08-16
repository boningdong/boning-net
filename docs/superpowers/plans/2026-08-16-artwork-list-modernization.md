# Artwork List Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy Artwork gallery with the approved modern, collection-backed Artwork page while preserving every artwork's intrinsic aspect ratio and providing accessible filters, an automatically drifting Highlights rail, and a glass full-resolution viewer.

**Architecture:** Render the page through the existing `modern` layout and compose it from focused Liquid includes under `_includes/pages/artwork/`. Keep content and featured selection in the `_artwork` collection, style the page through one `_sass/pages/_artwork.scss` entry, and encapsulate filtering, rail motion, and dialog behavior in one dependency-free UMD JavaScript module with exported pure helpers for Node tests.

**Tech Stack:** Jekyll 4.4.1, Liquid, semantic HTML, SCSS/Sass, vanilla JavaScript, Ruby build-contract tests, Node's built-in test runner.

## Global Constraints

- The approved design sources are `docs/designs/08-15-2026/artwork-list-mock-v1.html`, `docs/designs/08-15-2026/finalized-artwork-style.json`, and `docs/designs/08-15-2026/shared-design-invariants.md`; do not redesign or change their visual direction.
- Do not modify, delete, stage, or commit `.superpowers/`.
- Do not ship Tune Artwork, JSON preset viewing/export, mock debugging controls, comparison state, or `/files/` mappings.
- Reuse the modern layout, shared Navigation and Footer, shared foundation tokens, and existing Artwork collection and banner assets.
- Highlights are Snow Scene, Terminator, Watercolor Scenery, and Captain America, selected through `featured` and `featured-order` frontmatter.
- Artwork images must never be cropped: Highlights are `330px` tall by default with intrinsic widths, Collection cards use intrinsic image height, and the viewer uses the full-resolution `location` image with `object-fit: contain`.
- Desktop card gap is `28px`; mobile card gap is `21px`; the default Collection is three masonry columns.
- Automatic rail drift pauses on hover and keyboard focus, permits touch/trackpad/manual horizontal scrolling, and is disabled under `prefers-reduced-motion`.
- Filters are All, Pencil, Charcoal, and Watercolor, expose their pressed state, and update a live result count.
- The viewer must support click/touch activation, Escape, an explicit Close control, visible focus, native dialog semantics, and focus restoration.
- Use LF line endings, remove trailing whitespace, and preserve unrelated user changes.
- Do not push or merge.

---

## File Structure

- Modify `artwork.html`: modern-layout frontmatter, collection sorting, and page include composition only.
- Create `_includes/pages/artwork/hero.html`: derive hero count and year range from the passed collection.
- Create `_includes/pages/artwork/artwork-card.html`: shared semantic card markup for rail originals, inaccessible rail duplicates, and Collection viewer triggers.
- Create `_includes/pages/artwork/highlights.html`: select and order featured collection records and render the seamless two-copy rail.
- Create `_includes/pages/artwork/filters.html`: render the accessible fixed medium controls and live collection count.
- Create `_includes/pages/artwork/collection.html`: render The Collection heading, filters, and masonry cards.
- Create `_includes/pages/artwork/viewer.html`: render the one reusable native glass dialog.
- Create `_sass/pages/_artwork.scss`: approved hero, Mist continuity, rail, masonry, museum labels, dialog, focus, reduced-motion, and responsive behavior.
- Modify `assets/css/main.scss`: compile the Artwork page module.
- Create `assets/js/pages/artwork.js`: filter state, drift lifecycle, seamless wrapping, viewer content, dialog close/focus behavior, and exported test helpers.
- Modify four `_artwork/*.md` files: add maintainable featured flags and ordering.
- Modify `test/modern_pages_test.rb`: assert generated architecture, data sourcing, hierarchy, featured ordering, accessibility structure, and absence of lab artifacts.
- Create `test/javascript/artwork.test.js`: assert filter, viewer, and reduced-motion/rail behavior.

---

### Task 1: Add Failing Generated-Page Contracts

**Files:**
- Modify: `test/modern_pages_test.rb`
- Test: `test/modern_pages_test.rb`

**Interfaces:**
- Consumes: generated `_site/artwork.html` from `bundle exec jekyll build`.
- Produces: build-level contracts for `data-artwork-page`, `data-artwork-rail`, `data-artwork-card`, `data-artwork-filter`, and `#artwork-viewer` used by later tasks.

- [ ] **Step 1: Write the failing modern-shell and data-backed page tests**

Add cases that assert:

```ruby
html = built("artwork.html")
assert_includes html, '<body class="modern-page artwork-page">'
assert_includes html, 'href="/artwork" class="active" aria-current="page">Artwork</a>'
assert_includes html, 'data-artwork-page'
assert(html.scan('data-collection-artwork-card').length == 10, "expected 10 collection-backed artwork cards")
assert_includes html, 'data-full="/assets/img/artwork/snow_scene.jpg"'
refute_includes html, 'masonry.pkgd.min.js'
refute_includes html, 'bootstrap.min.css'
```

Add hierarchy and accessibility assertions for the exact hero copy, `10 works / 2015—2020`, Highlights before The Collection, four interactive featured cards, four `aria-hidden="true"` duplicates without viewer-trigger attributes, `role="group"`, filter `aria-pressed`, live result count, `dialog` labeling, viewer image alt target, and explicit Close button. Extend the design-lab exclusion test to include Artwork and reject `Tune Artwork`, `View JSON`, `Download JSON`, `/files/`, and preset controls.

- [ ] **Step 2: Run the test to verify it fails for the legacy page**

Run: `bundle exec jekyll build && bundle exec ruby test/modern_pages_test.rb`

Expected: the existing homepage and Projects cases pass; new Artwork cases fail because the page still uses `layout: default` and legacy Bootstrap modal/masonry markup.

- [ ] **Step 3: Record the red state without changing production code**

Confirm the failure messages name missing modern Artwork contracts rather than a Jekyll or dependency failure.

- [ ] **Step 4: Commit the failing contract tests**

```bash
git add test/modern_pages_test.rb
git commit -m "test: define modern artwork page contracts"
```

### Task 2: Migrate the Page Shell and Collection Data Model

**Files:**
- Modify: `artwork.html`
- Create: `_includes/pages/artwork/hero.html`
- Create: `_includes/pages/artwork/artwork-card.html`
- Create: `_includes/pages/artwork/highlights.html`
- Create: `_includes/pages/artwork/filters.html`
- Create: `_includes/pages/artwork/collection.html`
- Create: `_includes/pages/artwork/viewer.html`
- Modify: `_artwork/snow_scene.md`
- Modify: `_artwork/terminator.md`
- Modify: `_artwork/scene_watercolor.md`
- Modify: `_artwork/captain_america.md`
- Test: `test/modern_pages_test.rb`

**Interfaces:**
- Consumes: `site.artwork` records with `title`, `date`, `tags`, `cover`, `location`, plus new `featured` and `featured-order` fields.
- Produces: page hooks consumed by `assets/js/pages/artwork.js`: `[data-artwork-page]`, `[data-artwork-rail]`, `[data-artwork-track]`, `[data-artwork-filter]`, `[data-collection-artwork-card]`, `[data-artwork-trigger]`, `[data-artwork-viewer]`, and viewer field hooks.

- [ ] **Step 1: Add featured frontmatter in the approved order**

Use the following exact values:

```yaml
# snow_scene.md
featured: true
featured-order: 1

# terminator.md
featured: true
featured-order: 2

# scene_watercolor.md
featured: true
featured-order: 3

# captain_america.md
featured: true
featured-order: 4
```

- [ ] **Step 2: Replace `artwork.html` with modern page composition**

Use frontmatter values `layout: modern`, `body_class: artwork-page`, `nav_active: artwork`, `footer_variant: compact`, and `scripts: [/assets/js/pages/artwork.js]`. Sort `site.artwork` by date descending once, pass it to the hero and collection includes, and render one `<main class="artwork-content" data-artwork-page>` containing Highlights then Collection, followed by the viewer include.

- [ ] **Step 3: Implement the derived hero**

In `hero.html`, assign newest and oldest records from the sorted input and render:

```liquid
<h1><span>Artwork</span><span aria-hidden="true">—</span><span>Studies in light &amp; character</span></h1>
<p><span>Graphite</span><span>Charcoal</span><span>Watercolor</span></p>
<span class="artwork-hero-index">{{ include.artworks.size }} works / {{ oldest.date | date: "%Y" }}—{{ newest.date | date: "%Y" }}</span>
```

Use `/assets/img/showcase/artwork-banner.jpg`, a descriptive alt, and `fetchpriority="high"`.

- [ ] **Step 4: Implement one reusable semantic artwork card**

For original rail and Collection cards, render a `button type="button"` with `data-artwork-trigger`, `data-full`, `data-title`, `data-meta`, and an `aria-label="View …"`; render the cover image and Museum label using the first tag and year. For loop duplicates, render a noninteractive container with `aria-hidden="true"`, no `data-artwork-trigger`, and an empty image alt so it cannot enter the accessibility tree or tab order.

- [ ] **Step 5: Implement Highlights, filters, Collection, and viewer includes**

Highlights selects `site.artwork | where: "featured", true | sort: "featured-order"`, renders four originals plus four inaccessible duplicates in a labeled horizontal region, and preserves the approved `01 / 02` header. Filters render the four exact buttons with `aria-pressed`, and a `role="status" aria-live="polite"` count. Collection renders `02 / 02`, the filters, and all sorted records in CSS masonry columns. Viewer renders `<dialog id="artwork-viewer" aria-labelledby="artwork-viewer-title" aria-describedby="artwork-viewer-description">`, empty dynamic image/title/meta targets, the approved description, and a `Close viewer` button.

- [ ] **Step 6: Build and rerun the generated-page contracts**

Run: `bundle exec jekyll build && bundle exec ruby test/modern_pages_test.rb`

Expected: structural/data/accessibility tests pass; visual styles and behavior are not yet claimed.

- [ ] **Step 7: Commit the page architecture and data model**

```bash
git add artwork.html _includes/pages/artwork _artwork/snow_scene.md _artwork/terminator.md _artwork/scene_watercolor.md _artwork/captain_america.md
git commit -m "feat: migrate artwork to modern collection layout"
```

### Task 3: Add Failing Artwork Interaction Tests

**Files:**
- Create: `test/javascript/artwork.test.js`
- Test: `test/javascript/artwork.test.js`

**Interfaces:**
- Consumes: CommonJS exports from `assets/js/pages/artwork.js`.
- Produces: required helper contracts `matchesMedium`, `formatArtworkCount`, `createFilterState`, `createViewerContent`, `shouldAutoDrift`, and `wrapRailPosition`.

- [ ] **Step 1: Write the failing filter tests**

```javascript
assert.equal(matchesMedium('pencil', 'all'), true);
assert.equal(matchesMedium('charcoal', 'pencil'), false);
assert.deepEqual(createFilterState(['pencil', 'charcoal', 'pencil'], 'pencil'), {
  visible: [true, false, true],
  count: 2
});
assert.equal(formatArtworkCount(1), '1 work');
assert.equal(formatArtworkCount(10), '10 works');
```

- [ ] **Step 2: Write failing viewer and rail-policy tests**

```javascript
assert.deepEqual(createViewerContent({ full: '/full.jpg', title: 'Snow Scene', meta: 'Pencil · 2020' }), {
  src: '/full.jpg',
  alt: 'Snow Scene',
  title: 'Snow Scene',
  meta: 'Pencil · 2020'
});
assert.equal(shouldAutoDrift({ reducedMotion: true, paused: false }), false);
assert.equal(shouldAutoDrift({ reducedMotion: false, paused: true }), false);
assert.equal(shouldAutoDrift({ reducedMotion: false, paused: false }), true);
assert.equal(wrapRailPosition(420, 400), 20);
```

Also retain `test/javascript/navigation.test.js` in the full JavaScript command so the shared navigation threshold remains covered.

- [ ] **Step 3: Run tests to verify the Artwork module is missing**

Run: `node --test test/javascript/*.test.js`

Expected: existing home, projects, and navigation tests pass; Artwork tests fail because `assets/js/pages/artwork.js` does not exist.

- [ ] **Step 4: Commit the failing JavaScript tests**

```bash
git add test/javascript/artwork.test.js
git commit -m "test: define artwork interaction behavior"
```

### Task 4: Implement Filters, Rail Motion, and Glass Viewer Behavior

**Files:**
- Create: `assets/js/pages/artwork.js`
- Test: `test/javascript/artwork.test.js`

**Interfaces:**
- Consumes: the `data-*` hooks defined in Task 2, `window.matchMedia`, `requestAnimationFrame`, and native `<dialog>` methods.
- Produces: a UMD `ArtworkPage` module whose `init()` binds page behavior and whose pure helpers satisfy Task 3.

- [ ] **Step 1: Implement pure filter, viewer, and rail helpers**

Implement exact membership matching, singular/plural count formatting, filter-state projection, safe viewer dataset projection, automatic-motion policy, and cycle-width wrapping. Keep helpers independent of DOM globals so `require()` works under Node.

- [ ] **Step 2: Bind accessible filters**

On filter click, make exactly one button active, synchronize `aria-pressed`, set `hidden` on nonmatching Collection cards, and update the live count with `formatArtworkCount`. Do not remove cards from DOM or alter artwork data.

- [ ] **Step 3: Bind the full-resolution viewer**

On any nonduplicate artwork trigger click, copy `data-full`, title, and metadata into the dialog, give the image a complete alt, remember the trigger, and call `showModal()`. Close from the explicit control and backdrop click; rely on native Escape handling; on `close`, restore focus to the remembered trigger if it is still connected.

- [ ] **Step 4: Implement continuous auto drift without blocking manual input**

Keep the viewport natively `overflow-x: auto`. In a `requestAnimationFrame` loop, increment `scrollLeft` by elapsed time at a restrained constant speed and wrap at half the duplicated track width. Pause on pointer enter and focus in; resume on pointer leave and when focus leaves the rail; pause briefly after wheel, touch/pointer, or scroll input so trackpad and drag gestures remain under user control.

- [ ] **Step 5: Honor reduced motion dynamically**

Read `matchMedia('(prefers-reduced-motion: reduce)')` before starting automatic motion and subscribe to its `change` event. Never advance the rail while reduced motion is active; retain native manual scrolling in every state.

- [ ] **Step 6: Run the complete JavaScript suite**

Run: `node --test test/javascript/*.test.js`

Expected: all home, navigation, Projects, and Artwork tests pass.

- [ ] **Step 7: Commit behavior**

```bash
git add assets/js/pages/artwork.js test/javascript/artwork.test.js
git commit -m "feat: add accessible artwork interactions"
```

### Task 5: Implement the Approved Artwork Visual System

**Files:**
- Create: `_sass/pages/_artwork.scss`
- Modify: `assets/css/main.scss`
- Test: `test/modern_pages_test.rb`

**Interfaces:**
- Consumes: shared CSS custom properties from `_sass/foundation/_variables.scss`, shared focus treatment from `_sass/foundation/_base.scss`, and Task 2 class names.
- Produces: page-specific responsive visual behavior without changing shared foundation values.

- [ ] **Step 1: Add the Artwork Sass module to the main bundle**

Append `@use "pages/artwork";` to `assets/css/main.scss`.

- [ ] **Step 2: Implement the shared content-page hero contract**

Use the approved `60svh` desktop / `54svh` mobile hero, existing banner composition near `center 47%`, the `34% → 8%` horizontal shade and `4% / 2% / 34%` vertical shade, `28–32px` weight-480 title, utility metadata, and lower-right derived index. Hide the index and stack metadata only on mobile as in the mock.

- [ ] **Step 3: Implement Mist continuity and section rhythm**

Use one radial Mist background for both semantic sections, `112px` outer top/bottom spacing, an `80px` desktop transition from Highlights to Collection, and the shared mobile equivalents. Keep headings free of explanatory paragraphs.

- [ ] **Step 4: Implement the uncropped Highlights rail**

Set each rail cover to `height: 330px; width: auto; max-width: none; object-fit: contain`, with `290px` as the approved small-screen cap. Use a max-content flex track, `28px`/`21px` gaps, edge fades that do not intercept input, native horizontal overflow, scroll snap only if it does not interfere with automatic drift, and a subtle scrollbar. Do not use `object-fit: cover` or fixed card widths.

- [ ] **Step 5: Implement Museum cards and intrinsic masonry**

Use shared `26px` glass cards, `5px` lift, `10%` shadow, and labels beneath images. Use CSS multi-columns with three default columns, two on medium/mobile where needed, `28px` desktop column/card gap and `21px` mobile gap. Set Collection images to `width: 100%; height: auto` with no aspect-ratio box and no crop.

- [ ] **Step 6: Implement filters and the approved glass dialog**

Match the approved pill sizes/colors and live count typography. Size the dialog to `min(1000px, 100% - 34px)`, use a two-column layout above `850px`, one column below, full-resolution image containment, glass edge/highlight/blur/shadow, a dark blurred backdrop, and an explicit pill close control. Preserve the global focus-visible ring for every button.

- [ ] **Step 7: Add motion safeguards**

Use `@media (prefers-reduced-motion: reduce)` only for nonessential transitions; do not disable native horizontal scrolling. Suppress card lift on coarse pointers/reduced motion where appropriate while preserving focus states.

- [ ] **Step 8: Build and run generated-page tests**

Run: `bundle exec jekyll build && bundle exec ruby test/modern_pages_test.rb`

Expected: all generated-page tests pass and Sass compilation succeeds.

- [ ] **Step 9: Commit styles**

```bash
git add _sass/pages/_artwork.scss assets/css/main.scss
git commit -m "feat: style modern artwork collection"
```

### Task 6: Verify Behavior, Rendering, and Repository Hygiene

**Files:**
- Modify only if a verified failure requires a scoped fix.
- Test: `test/modern_pages_test.rb`
- Test: `test/javascript/*.test.js`

**Interfaces:**
- Consumes: completed implementation from Tasks 1–5.
- Produces: recorded evidence that automated and visual acceptance criteria are met.

- [ ] **Step 1: Run all automated tests fresh**

Run:

```bash
bundle exec jekyll build
bundle exec ruby test/modern_pages_test.rb
node --test test/javascript/*.test.js
git diff --check
```

Expected: each command exits 0 with no failed tests or whitespace errors.

- [ ] **Step 2: Start the local Jekyll server**

Run `bundle exec jekyll serve --host 127.0.0.1 --port 4000` and keep the process available for browser verification.

- [ ] **Step 3: Verify one desktop viewport**

At approximately `1440×1000`, inspect `/artwork/` and confirm every image returns successfully, `naturalWidth / naturalHeight` matches `getBoundingClientRect().width / height` within a small rounding tolerance for rail and Collection images, `document.documentElement.scrollWidth <= window.innerWidth`, the rail moves and pauses on hover/focus, every filter produces the correct count, viewer uses the full-resolution URL and closes by button/Escape/backdrop, Artwork nav is active, and the console has no errors.

- [ ] **Step 4: Verify one mobile viewport**

At approximately `390×844`, repeat image-load, aspect-ratio, overflow, filters, rail manual-scroll, viewer, Menu/navigation, and console checks. Emulate `prefers-reduced-motion: reduce` and confirm the rail remains stationary while manual horizontal scrolling remains possible.

- [ ] **Step 5: Use systematic debugging for any failure**

For each failure, reproduce it, isolate the responsible layer, add or refine the smallest failing automated check where practical, implement the root-cause fix, and rerun the affected test plus the full verification commands. Do not alter the approved mock/preset; if they are the verified source of a blocker, stop and report the exact conflict.

- [ ] **Step 6: Review the final diff and protected paths**

Run:

```bash
git status --short
git diff --stat 2f40bc7
git diff --check 2f40bc7
git diff 2f40bc7 -- docs/designs/08-15-2026 .superpowers
```

Expected: no changes to approved design files or `.superpowers/`; only planned production, content frontmatter, test, and plan files differ from `2f40bc7`.

- [ ] **Step 7: Request code review and address findings**

Use `superpowers:requesting-code-review` against the complete diff from `2f40bc7`, fix every verified High/Medium issue through TDD and systematic debugging, and rerun Step 1 after any change.

- [ ] **Step 8: Prepare the handoff**

Report the implementation outcome, major files, exact verification commands and outputs, anything not verified or remaining risk, and current `git status --short`. Do not push or merge.

---

## Self-Review

- Spec coverage: page shell, navigation/footer, derived hero metadata, frontmatter-driven highlights, uncropped rail, manual/reduced-motion behavior, masonry, filters/count, full-resolution viewer, responsive behavior, forbidden lab tools, automated suites, Jekyll build, diff hygiene, and desktop/mobile browser checks are each assigned to an explicit task.
- Placeholder scan: every implementation and verification step is concrete; no deferred or undefined work remains.
- Interface consistency: Liquid emits the same `data-*` hooks consumed by `ArtworkPage.init`; the six helper names in the JavaScript tests exactly match the Task 4 exports; CSS targets the class names assigned by the Task 2 includes.
