# Responsive Image Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace low-resolution project and artwork thumbnails with canonical high-resolution sources and libvips-generated responsive WebP/original-format image sets.

**Architecture:** Collection frontmatter continues to expose a canonical `cover` path. A shared Liquid include selects one of three Jekyll Picture Tag presets, and Jekyll Picture Tag invokes libvips at build time to emit `<picture>` markup and derivatives under `_site/generated/`; the artwork viewer keeps loading `location` directly.

**Tech Stack:** Jekyll 4.4.1, Liquid, `jekyll_picture_tag` 2.1.x, libvips, Ruby verification scripts, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-08-17-responsive-image-pipeline-design.md`

## Global Constraints

- Generate WebP first and the original JPEG or PNG format second; do not generate AVIF.
- Generate large-card widths `[480, 800, 1200, 1600]`, grid-card widths `[320, 480, 640, 960, 1280]`, and artwork-rail widths `[240, 360, 480, 720, 960]` without upscaling during normal Jekyll builds.
- Use WebP quality 82 and JPEG quality 85, preserve PNG fallback, strip generated metadata, and emit intrinsic dimensions.
- Keep card images `loading="lazy"` and `decoding="async"`.
- Preserve descriptive alt text on real cards, empty alt text plus `aria-hidden="true"` on duplicate artwork rail cards, and unchanged full-resolution `data-full` artwork viewer URLs.
- Fail the build for missing sources, unsupported formats, or image-generation errors.
- Keep generated derivatives out of Git and under `_site/generated/` only.
- Delete legacy sources only after source and rendered-output searches prove they are unreferenced.

---

### Task 1: Build-time image pipeline

**Files:**
- Create: `_data/picture.yml`
- Create: `script/verify_responsive_images.rb`
- Modify: `Gemfile`
- Modify: `Gemfile.lock`
- Modify: `_config.yml`
- Modify: `.github/workflows/jekyll.yml`
- Modify: `.github/workflows/pr-preview.yml`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: local `vips` CLI and the existing `bundle exec jekyll build` workflow.
- Produces: presets named `large_card`, `grid_card`, and `artwork_rail`; generated URLs rooted at `/generated/`; `script/verify_responsive_images.rb --source` for source/config checks and `--site _site` for rendered-output checks.

- [ ] **Step 1: Write the failing source verifier**

Create a Ruby script using only the standard library. In `--source` mode it must assert that `Gemfile` and `_config.yml` register `jekyll_picture_tag`, `_data/picture.yml` contains the three exact preset names and width arrays, both workflows contain an `Install libvips` step before Ruby setup/build, `.gitignore` contains `/.superpowers/`, every project/artwork `cover` starts with `/assets/img/`, and every `cover`/artwork `location` resolves to a file below the repository root. Each failure prints its path and exits nonzero.

- [ ] **Step 2: Run the verifier and confirm the expected failure**

Run: `ruby script/verify_responsive_images.rb --source`

Expected: nonzero exit with missing plugin, missing presets, and missing CI libvips errors.

- [ ] **Step 3: Add and configure the plugin**

Add `gem "jekyll_picture_tag", "~> 2.1"` to the `jekyll_plugins` group and add `jekyll_picture_tag` to `_config.yml`'s `plugins`. Configure:

```yaml
picture:
  source: ""
  output: generated
  ignore_missing_images: false

media_queries:
  mobile: "max-width: 640px"
  tablet: "max-width: 850px"

presets:
  large_card:
    formats: [webp, original]
    widths: [480, 800, 1200, 1600]
    sizes:
      mobile: "calc(100vw - 36px)"
      tablet: "calc((100vw - 58px) * 0.575)"
    size: 630px
    dimension_attributes: true
    format_quality: { webp: 82, jpg: 85, jpeg: 85 }
  grid_card:
    formats: [webp, original]
    widths: [320, 480, 640, 960, 1280]
    sizes:
      mobile: "calc(100vw - 36px)"
      tablet: "calc((100vw - 58px) / 2)"
    size: 357px
    dimension_attributes: true
    format_quality: { webp: 82, jpg: 85, jpeg: 85 }
  artwork_rail:
    formats: [webp, original]
    widths: [240, 360, 480, 720, 960]
    sizes:
      mobile: "435px"
    size: 540px
    dimension_attributes: true
    format_quality: { webp: 82, jpg: 85, jpeg: 85 }
```

If Jekyll Picture Tag's installed schema names metadata stripping differently, inspect the installed 2.1.x gem and add its exact libvips saver option to every preset; verify generated files have no EXIF/IPTC fields with `vipsheader -a`.

- [ ] **Step 4: Make local and CI dependency setup deterministic**

Run `bundle install` to refresh `Gemfile.lock`. In both GitHub Actions workflows, insert this before `Setup Ruby`:

```yaml
- name: Install libvips
  run: sudo apt-get update && sudo apt-get install -y libvips-tools
```

Add `/.superpowers/` to `.gitignore` without changing existing ignore rules.

- [ ] **Step 5: Run source verification and a clean build**

Run: `ruby script/verify_responsive_images.rb --source && bundle exec jekyll clean && JEKYLL_ENV=production bundle exec jekyll build`

Expected: source verifier passes and Jekyll completes without missing-plugin or libvips errors.

- [ ] **Step 6: Commit the build pipeline**

```bash
git add Gemfile Gemfile.lock _config.yml _data/picture.yml .github/workflows/jekyll.yml .github/workflows/pr-preview.yml .gitignore script/verify_responsive_images.rb
git commit -m "build: add responsive image pipeline"
```

### Task 2: Shared responsive-image interface and card migration

**Files:**
- Create: `_includes/components/responsive-image.html`
- Modify: `_includes/pages/home/work.html`
- Modify: `_includes/pages/projects/highlight-card.html`
- Modify: `_includes/pages/projects/archive-card.html`
- Modify: `_includes/pages/artwork/artwork-card.html`
- Modify: `_sass/pages/_home.scss`
- Modify: `_sass/pages/_projects.scss`
- Modify: `_sass/pages/_artwork.scss`
- Modify: `script/verify_responsive_images.rb`

**Interfaces:**
- Consumes: `{% include components/responsive-image.html src=... preset=... alt=... loading="lazy" %}`.
- Produces: `<picture>` containing WebP and original `<source>` elements plus an `<img>` with `srcset`, `sizes`, `width`, `height`, `loading`, and `decoding`.

- [ ] **Step 1: Extend the verifier before migrating templates**

In source mode, require all five scoped template files to call `components/responsive-image.html` and reject direct card-image expressions matching `<img[^>]+(?:project|artwork)\.cover`. In site mode, parse `index.html`, `projects.html`, and `artwork.html`; require every scoped card picture to contain `.webp`, an original-format candidate, `srcset=`, `sizes=`, numeric `width=`/`height=`, `loading="lazy"`, and `decoding="async"`. Also assert each non-duplicate artwork trigger retains a `/assets/img/artwork/` `data-full` URL and each duplicate remains `aria-hidden="true"`.

- [ ] **Step 2: Run the extended source verifier and confirm failure**

Run: `ruby script/verify_responsive_images.rb --source`

Expected: nonzero exit listing the five templates still using direct image markup.

- [ ] **Step 3: Implement the shared include**

Normalize the leading slash from `include.src`, default `loading` to `lazy`, and dispatch only the three allowed presets with Jekyll Picture Tag. Pass escaped alt text and the exact `loading` plus `decoding="async"` attributes to the generated `<img>`. Raise a Liquid build error for an unknown preset so a misspelling cannot silently fall back to another size recipe.

- [ ] **Step 4: Migrate all scoped callers**

Use `large_card` for homepage bento cards and Projects Highlights, `grid_card` for Projects Archive and Artwork Collection, and `artwork_rail` for real and duplicated Artwork Highlights. Preserve the existing `data-full`, titles, metadata, button behavior, duplicate markup, and card DOM outside the media element.

- [ ] **Step 5: Make generated `<picture>` wrappers obey existing image layout**

Add focused rules so the generated `picture` fills `.portfolio-visual`, `.highlight-card`, `.archive-image`, and `.artwork-card-media`, while its child image keeps the existing object-fit behavior. Ensure images with intrinsic attributes remain fluid by keeping `max-width: 100%` and the context-specific `width`/`height` declarations.

- [ ] **Step 6: Build and run both verifier modes**

Run: `ruby script/verify_responsive_images.rb --source && bundle exec jekyll clean && JEKYLL_ENV=production bundle exec jekyll build && ruby script/verify_responsive_images.rb --site _site`

Expected: all checks pass; generated HTML contains responsive markup and artwork viewer URLs still target canonical full-resolution artwork files.

- [ ] **Step 7: Commit the template migration**

```bash
git add _includes/components/responsive-image.html _includes/pages/home/work.html _includes/pages/projects/highlight-card.html _includes/pages/projects/archive-card.html _includes/pages/artwork/artwork-card.html _sass/pages/_home.scss _sass/pages/_projects.scss _sass/pages/_artwork.scss script/verify_responsive_images.rb
git commit -m "refactor: render portfolio cards responsively"
```

### Task 3: Canonical high-resolution artwork sources

**Files:**
- Modify: `_artwork/*.md`
- Delete: `assets/img/artwork/covers/*.jpg`
- Modify: `script/verify_responsive_images.rb`

**Interfaces:**
- Consumes: each artwork entry's existing full-resolution `location` path.
- Produces: `cover == location` for every artwork entry while `location` remains unchanged.

- [ ] **Step 1: Add a failing artwork-source invariant**

Extend source verification to parse artwork YAML frontmatter and require `cover == location`, require both to exist, and require width at least 1280 pixels or height at least 1280 pixels using `vipsheader -f width/-f height`.

- [ ] **Step 2: Confirm the invariant fails on legacy covers**

Run: `ruby script/verify_responsive_images.rb --source`

Expected: nonzero exit listing artwork entries whose covers still point into `assets/img/artwork/covers/`.

- [ ] **Step 3: Point artwork covers to the originals**

For all ten `_artwork/*.md` files, replace `cover` with the unchanged `location` value. Do not alter title, dates, ordering, tags, or viewer source fields.

- [ ] **Step 4: Verify before deleting legacy artwork thumbnails**

Run: `ruby script/verify_responsive_images.rb --source && rg -n "assets/img/artwork/covers" . --glob '!_site/**' --glob '!.git/**'`

Expected: verifier passes and `rg` returns no source references.

- [ ] **Step 5: Delete obsolete artwork covers and rebuild**

Delete only the ten tracked files under `assets/img/artwork/covers/`, then run a clean production build and site verification. Confirm `data-full` values still point to the ten original full-resolution artwork files.

- [ ] **Step 6: Commit artwork source migration**

```bash
git add _artwork script/verify_responsive_images.rb
git add -u assets/img/artwork/covers
git commit -m "refactor: use original artwork sources"
```

### Task 4: Canonical project cover audit and enhancement

**Files:**
- Create when required: `assets/img/projects/covers-hd/<project-slug>.<jpg|png>`
- Modify: `_projects/*.md`
- Delete after verification: superseded low-resolution project cover files
- Modify: `script/verify_responsive_images.rb`

**Interfaces:**
- Consumes: each legacy project cover and all body images referenced by the same `_projects/<slug>.md` file.
- Produces: a canonical `cover` at least 1280 pixels wide for large-card projects and at least 960 pixels wide for grid-only projects, without changing text/logo/UI details.

- [ ] **Step 1: Add a failing project-cover resolution audit**

Use `vipsheader` in source verification to report dimensions for every project cover. Require featured projects and the three newest homepage projects to be at least 1280 pixels wide; require every other project cover to be at least 960 pixels wide. Exempt no file by name.

- [ ] **Step 2: Confirm the audit identifies undersized sources**

Run: `ruby script/verify_responsive_images.rb --source`

Expected: nonzero exit for the current 289–480px legacy covers and any cover below its required width.

- [ ] **Step 3: Recover exact or closest existing originals first**

For each failing cover, compare it with body images from the same project using a 16:9 center/attention thumbnail and structural similarity, then visually inspect the top matches. Use an existing body image directly when it reproduces the cover subject and framing; retain already adequate `ar_domino/domino_cover.jpg`, `kossel_cover.jpg`, `smartwatch_cover.jpg`, and any other cover that passes the threshold.

- [ ] **Step 4: Prepare deterministic high-resolution graphic/UI covers**

For AreUSafe, Ecosystem, Scopen, Programming Languages Trend, and any other cover containing readable UI, logos, text, charts, or technical graphics without an exact high-resolution source, create `assets/img/projects/covers-hd/<slug>.png` (or `.jpg` for photographic originals) using libvips Lanczos enlargement to the next required width. Preserve aspect ratio, do not add invented detail, and visually compare text/logo geometry against the legacy file at 100% and card scale.

- [ ] **Step 5: Prepare photographic covers without originals**

For any remaining photographic cover that has no acceptable body-image match, use the imagegen image-edit workflow once to upscale the legacy cover while preserving composition, colors, objects, and aspect ratio. Save the reviewed result under `assets/img/projects/covers-hd/` at 1600px wide for large-card use or 1280px wide for grid-only use; do not run AI generation during Jekyll builds.

- [ ] **Step 6: Update frontmatter and visually review sources**

Update only the affected project `cover` paths. Build a labeled contact sheet containing every canonical project cover and compare it with a second labeled sheet of legacy covers; reject any source with changed lettering, missing hardware, invented controls, severe halos, or a crop that hides the project subject.

- [ ] **Step 7: Pass source/build verification before cleanup**

Run: `ruby script/verify_responsive_images.rb --source && bundle exec jekyll clean && JEKYLL_ENV=production bundle exec jekyll build && ruby script/verify_responsive_images.rb --site _site`

Expected: all cover-resolution checks pass and every project card renders responsive candidates.

- [ ] **Step 8: Delete only superseded project covers**

For each old cover whose frontmatter changed, run `rg -n "<old path>" . --glob '!_site/**' --glob '!.git/**'`. Delete it only when the search returns no references. Keep body images, adequate canonical covers, and alternate originals that are still referenced by project pages.

- [ ] **Step 9: Commit canonical project sources**

```bash
git add _projects assets/img/projects/covers-hd script/verify_responsive_images.rb
git add -u assets/img/projects
git commit -m "refactor: upgrade project cover sources"
```

### Task 5: Browser verification and final cleanup

**Files:**
- Modify only if verification exposes a defect: scoped templates, preset data, or scoped SCSS from Tasks 1–4
- Delete: temporary contact sheets and source-matching files inside the repository, if any

**Interfaces:**
- Consumes: completed production `_site` and the local Jekyll server.
- Produces: verified desktop/tablet/mobile responsive behavior with no orphaned temporary assets.

- [ ] **Step 1: Run final automated checks from a clean tree state**

Run: `bundle exec jekyll clean && JEKYLL_ENV=production bundle exec jekyll build && ruby script/verify_responsive_images.rb --source && ruby script/verify_responsive_images.rb --site _site && git diff --check`

Expected: every command exits zero.

- [ ] **Step 2: Check generated candidates and metadata**

List `_site/generated/` and confirm each scoped source produces WebP plus JPEG/PNG fallback candidates, no width exceeds its canonical source width, and `vipsheader -a` shows stripped EXIF/IPTC metadata. Check representative file sizes to ensure mobile candidates are materially smaller than their 960–1600px counterparts.

- [ ] **Step 3: Verify pages in the browser**

Serve the site and inspect `/`, `/projects.html`, and `/artwork.html` at 1440px, 768px, and 390px viewport widths, with DPR 1 and DPR 2 where available. Confirm sharp card images, unchanged object-fit/crops and labels, no layout shift from intrinsic dimensions, and selected `currentSrc` widths consistent with each rendered slot.

- [ ] **Step 4: Verify artwork interaction and accessibility**

Open several Artwork Collection and Highlights items and confirm the viewer loads the full-resolution `location`, closes normally, and does not preload full originals before opening. Inspect duplicate rail cards for `aria-hidden="true"` and empty generated image alt text.

- [ ] **Step 5: Remove temporary and orphaned resources**

Run reference searches for every candidate deletion, remove only unreferenced temporary or superseded files, rebuild once more, rerun both verifier modes and `git diff --check`, then inspect `git status --short` to ensure `.superpowers/`, `_site/`, and generated derivatives are not staged.

- [ ] **Step 6: Commit any verification fixes or cleanup**

```bash
git add -u
git add _data _includes _sass script assets/img _projects _artwork
git commit -m "chore: verify and clean responsive images"
```
