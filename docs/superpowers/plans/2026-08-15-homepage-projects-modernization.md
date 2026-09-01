# Homepage and Projects Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved homepage and Projects designs as clean, content-driven Jekyll pages without Bootstrap or jQuery, while preserving URLs, collections, project-detail pages, Artwork, and Experiences.

**Architecture:** The new pages use a standalone `modern` layout and one compiled CSS entry. SCSS is organized by responsibility into `foundation`, `components`, and `pages`; Liquid and JavaScript use `components` and `pages`. Legacy pages retain the current `default` layout until their later redesign.

**Tech Stack:** Jekyll 4.4.1, Liquid, SCSS, vanilla JavaScript, Ruby Minitest, Node's built-in test runner, in-app browser verification.

## Global Constraints

- Use `docs/designs/08-15-2026/finalized-main-style.json` as the homepage final parameter reference; production code does not load JSON.
- JSON values override mock defaults.
- Projects card height is `400px`; footer padding is `22px`; description-to-tags gap is `16px`.
- Shared values: `26px` card radius, `28px` desktop card gap, `21px` mobile gap, `112px` section space, approximately `81px` mobile section space, `5px` lift, and `10%` shadow alpha.
- Fonts: Instrument Sans display, Source Sans 3 body, IBM Plex Mono utility.
- Navigation: `46px` height, Pearl `48%` surface, `8px` blur, `24px` side padding, `35%` highlight, `95%` black ink after scroll.
- Homepage hero: Horizon, line divider, slash metadata divider, `32px`, weight `480`; work: Image Caption, Gradient, Bento.
- Projects uses the lighter content-page hero overlay and Mist continuity with an `80px` internal transition.
- Do not ship mock review/tuning/import/export/reset controls or `/files/...` URLs.
- Use existing collections, real content, frontmatter, images, URLs, and `relative_url`.
- Do not visually modify Artwork, Experiences, or project-detail pages.
- Honor visible focus and `prefers-reduced-motion`.

---

### Task 1: Architecture Documentation and Failing Acceptance Tests

**Files:**
- Create: `docs/architecture/frontend.md`
- Create: `test/modern_pages_test.rb`
- Create: `test/javascript/navigation.test.js`
- Create: `test/javascript/home.test.js`
- Create: `test/javascript/projects.test.js`

**Interfaces:**
- Ruby tests consume `_site/index.html`, `_site/projects.html`, and generated assets.
- Node tests consume pure exported helpers from the three production scripts.

- [ ] Document the `foundation / components / pages` boundaries, modern/legacy boundary, content flow, and asset entry points in concise prose.
- [ ] Add build-output assertions for the modern shell, collection-backed Projects cards, real local assets/links, and absence of Bootstrap, jQuery, `/files/`, and design-lab controls.
- [ ] Add navigation tests for `shouldShowSurface(24) == false` and `shouldShowSurface(25) == true`.
- [ ] Add home tab tests for ArrowLeft/ArrowRight/Home/End index behavior.
- [ ] Add Projects tests for tag matching, responsive collapsed filter counts, and singular/plural result labels.
- [ ] Run `bundle exec jekyll build && bundle exec ruby test/modern_pages_test.rb` and `node --test test/javascript/*.test.js`; confirm failures are caused by missing modern output/scripts.

### Task 2: Modern Jekyll Shell and Content Metadata

**Files:**
- Create: `_layouts/modern.html`
- Create: `_includes/components/navigation.html`
- Create: `_includes/components/footer.html`
- Create: `_data/navigation.yml`
- Create: `_data/social.yml`
- Modify: `_projects/scopen.md`
- Modify: `_projects/chatbot.md`
- Modify: `_projects/ar_domino.md`
- Modify: `_tags/*.md`

**Interfaces:**
- `modern.html` consumes `page.body_class`, `page.scripts`, the component includes, and `/assets/css/main.css`.
- Navigation consumes `site.data.navigation`; footer consumes `site.data.social` and `include.variant`.
- Project highlights consume `featured` and `featured-order`; tag filters consume `filter-order`.

- [ ] Create a semantic document shell with modern fonts, favicon, one CSS file, component navigation/footer, and page scripts through `relative_url`; do not load Bootstrap/jQuery/Popper.
- [ ] Create data-driven navigation and real social/contact data using current destinations.
- [ ] Add `featured`/`featured-order` metadata to Scopen, Chatbot, and AR Domino without changing existing fields or URLs.
- [ ] Add deterministic `filter-order` metadata to tag documents, preserving their current titles and colors.

### Task 3: Foundation and Reusable Components

**Files:**
- Replace/remove legacy draft: `_sass/design/tokens.scss`
- Create: `_sass/foundation/_variables.scss`
- Create: `_sass/foundation/_mixins.scss`
- Create: `_sass/foundation/_base.scss`
- Create: `_sass/foundation/_layout.scss`
- Create: `_sass/components/_navigation.scss`
- Create: `_sass/components/_cards.scss`
- Create: `_sass/components/_footer.scss`
- Create: `assets/css/main.scss`
- Create: `assets/js/components/navigation.js`

**Interfaces:**
- `variables` emits approved CSS custom properties.
- `mixins` provides only `glass-surface`, `focus-ring`, and `card-motion` recipes.
- `main.scss` is the sole modern CSS entry and composes foundation, components, and pages.
- Navigation JS exports `shouldShowSurface` for tests and initializes `[data-navigation]` in browsers.

- [ ] Implement approved variables and the minimum shared mixins.
- [ ] Implement scoped modern base styles, container/section primitives, focus, and reduced-motion behavior.
- [ ] Implement the transparent-over-hero and Pearl-glass-scrolled navigation, permanent `Boning Dong` label, and mobile second-island menu.
- [ ] Implement shared glass-card geometry/material/motion primitives and both footer variants.
- [ ] Implement/test navigation behavior for scroll, menu toggle, outside click, Escape focus restoration, link activation, and resize.
- [ ] Run Node navigation tests until green.

### Task 4: Homepage

**Files:**
- Modify: `index.html`
- Create: `_includes/pages/home/hero.html`
- Create: `_includes/pages/home/about.html`
- Create: `_includes/pages/home/experiences.html`
- Create: `_includes/pages/home/work.html`
- Create: `_includes/pages/home/skills.html`
- Create: `_sass/pages/_home.scss`
- Create: `assets/js/pages/home.js`
- Remove after references disappear: `_includes/index/*.html`
- Remove after consolidation: `assets/css/index/*.scss`
- Replace/remove after migration: `assets/js/index/main.js`

**Interfaces:**
- Homepage includes consume `site.data.home`, `site.projects`, `site.artwork`, and existing index assets.
- Home JS exports `nextTabIndex(current, key, count)` and initializes an ARIA tablist.

- [ ] Make `index.html` a thin `layout: modern` composition.
- [ ] Render the approved hero treatment using production identity content and `assets/img/index/banner.jpg`.
- [ ] Render About from real copy and portrait, Experiences from `_data/home.yml`, Work from the actual project/artwork collections, and existing Skills content.
- [ ] Implement Horizon hero, section rhythm, experience glass cards, image-caption gradient bento, skill cards, and responsive desktop/medium/mobile layouts.
- [ ] Implement tested keyboard/click Work tabs with `aria-selected`, `aria-controls`, `hidden`, and focus movement.
- [ ] Remove obsolete homepage includes/styles/script only after the modern page no longer references them.
- [ ] Run Node home tests and Ruby build tests; confirm homepage assertions pass.

### Task 5: Projects List Page

**Files:**
- Modify: `projects.html`
- Create: `_includes/pages/projects/hero.html`
- Create: `_includes/pages/projects/highlights.html`
- Create: `_includes/pages/projects/highlight-card.html`
- Create: `_includes/pages/projects/archive-card.html`
- Create: `_includes/pages/projects/filters.html`
- Create: `_sass/pages/_projects.scss`
- Create: `assets/js/pages/projects.js`

**Interfaces:**
- Highlights query `site.projects` where `featured == true`, sorted by `featured-order`.
- Archive iterates all sorted projects and resolves tag display names from `site.tags`.
- Projects JS exports `matchesTag`, `collapsedTagCount`, and `formatResultCount`, then initializes `[data-project-filters]`.

- [ ] Make `projects.html` a thin `layout: modern` composition and remove Masonry from this page only.
- [ ] Render the approved lighter hero using the real Scopen asset and collection-derived date range.
- [ ] Render three collection-backed Highlights and all 12 collection-backed archive cards with real covers, subtitles, dates, tags, and URLs.
- [ ] Generate ordered filters from tag collection metadata; collapsed desktop shows All + four tags + More (six controls), with fewer tag pills at medium/mobile widths.
- [ ] Implement Mist continuity, `80px`/`58px` transition, 3/2/1 grids, Split Cards, exact `400px`/`22px`/`16px`, shared geometry, and no archive-image zoom.
- [ ] Implement/test single-tag filtering, More/Less state, `aria-pressed`, live counts, active-hidden indication, and resize behavior.
- [ ] Run Node Projects tests and Ruby build tests until green.

### Task 6: Build, Link, Browser, and Visual Verification

**Files:**
- Review all changed files and `_site` output.

- [ ] Run `bundle exec jekyll build` and both automated suites fresh.
- [ ] Scan generated modern pages for `/files/` and design-lab controls; verify every local `href`/`src` resolves.
- [ ] Verify `_site/artwork.html`, `_site/resume.html`, and project-detail output still exist.
- [ ] Start `bundle exec jekyll serve --host 127.0.0.1 --port 4000 --no-watch`.
- [ ] Inspect homepage and Projects at `1440×900`, `1024×768`, and `390×844`.
- [ ] Exercise navigation scroll state, mobile menu, homepage tabs, Projects filters, More/Less, hover, images, and internal links.
- [ ] Compare computed radius, gaps, section spaces, fonts, glass, lift, Projects height/padding/gap, and hero overlays against the approved references.
- [ ] Fix each discovered defect with a failing regression test where practical, then rerun the affected and full verification gates.
- [ ] Run `git diff --check`, review the full diff, and report changed files, verification evidence, and any content-driven mock differences.
