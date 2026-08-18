# Project Cover System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver refined, consistent project-card overlays, three crop-safe AI Scopen covers, and a per-project asset directory structure.

**Architecture:** Project frontmatter remains the single source of truth for covers, while every project owns an asset directory matching its `_projects` filename. Homepage and Projects cards keep their existing markup but converge on one CSS overlay model with card-owned shading and metadata-only text layers.

**Tech Stack:** Jekyll 4.4.1, Liquid, SCSS, jekyll_picture_tag, libvips, Ruby/Minitest, Node test runner, ImageGen

**Spec:** `docs/superpowers/specs/2026-08-17-project-cover-system-design.md`

## Global Constraints

- Keep every change unstaged and do not create a commit.
- Preserve unrelated working-tree changes.
- Every cover must remain compatible with the responsive `large_card` and `grid_card` presets.
- Project folders must exactly match `_projects/<slug>.md` basenames.
- Remove only assets confirmed to have no repository reference or superseded derived assets.
- Use LF line endings and leave no trailing whitespace.

---

### Task 1: Asset-layout and overlay regression contracts

**Files:**
- Modify: `test/responsive_images_test.rb`
- Modify: `test/modern_pages_test.rb`

**Interfaces:**
- Consumes: `_projects/*.md`, generated `_site/index.html`, `_site/projects.html`, `_site/assets/css/main.css`
- Produces: regression contracts for folder ownership, reference integrity, responsive covers, and overlay output

- [ ] **Step 1: Add failing project asset-ownership tests**

Add a Minitest that derives each project slug from its Markdown filename, requires its `cover` to begin with `/assets/img/projects/<slug>/`, requires the cover file to exist, rejects files directly under `assets/img/projects/`, and rejects `assets/img/projects/covers-hd/`.

```ruby
def test_projects_own_their_assets
  failures = Dir.glob(File.join(ROOT, "_projects", "*.md")).filter_map do |path|
    slug = File.basename(path, ".md")
    cover = frontmatter(path).fetch("cover")
    next if cover.start_with?("/assets/img/projects/#{slug}/") && File.file?(File.join(ROOT, cover.delete_prefix("/")))

    "#{slug} does not own #{cover}"
  end

  assert_empty failures, failures.join("\n")
  assert_empty Dir.glob(File.join(ROOT, "assets/img/projects/*")).select { |path| File.file?(path) }
  refute_path_exists File.join(ROOT, "assets/img/projects/covers-hd")
end
```

- [ ] **Step 2: Add failing reference-integrity and overlay tests**

Scan project Markdown for `/assets/img/projects/...` references and assert every referenced source exists. Assert compiled CSS uses the new shared translucent shade and no longer contains the old `rgb(6 12 15 / 0.78)` or homepage metadata gradient.

- [ ] **Step 3: Run tests and verify RED**

Run: `ruby test/responsive_images_test.rb`

Expected: failures naming root-level assets, `covers-hd`, old cover paths, and old overlay CSS.

---

### Task 2: Per-project asset migration

**Files:**
- Modify: all twelve `_projects/*.md` files
- Move: `assets/img/projects/*` into twelve slug-matched directories
- Remove: confirmed-unused project assets and `assets/img/projects/covers-hd/`

**Interfaces:**
- Consumes: project slugs and path rules from Task 1
- Produces: `/assets/img/projects/<slug>/<asset>` paths consumed by Liquid, Jekyll Picture Tag, and project detail HTML

- [ ] **Step 1: Create all twelve project directories**

Create `ar_domino`, `areusafe`, `chatbot`, `drsstc`, `ecosystem`, `kossel_printer`, `msp430_dev`, `nes_emulator`, `scopen`, `simplewatch`, `smartlamp`, and `spl_visualization` beneath `assets/img/projects/`.

- [ ] **Step 2: Move used assets into their owner directories**

Preserve useful detail-image basenames. Rename each selected cover to `cover.<extension>`. Move `covers-hd/areusafe.png`, `covers-hd/chatbot.png`, and `covers-hd/ecosystem.png` to their owner directories as `cover.png`.

- [ ] **Step 3: Update frontmatter and inline image paths atomically**

Use `apply_patch` to replace every project image reference with its new owner-directory path. Keep Liquid `site.baseurl` usage unchanged.

- [ ] **Step 4: Delete confirmed-unused files**

Remove the audited unused files: numeric orphan image, unused original/PNG chatbot variants, unused Smart Lamp and Simple Watch images, unused Tesla Smart Lamp images, and any superseded derived cover that has no remaining reference.

- [ ] **Step 5: Run asset tests and verify the asset subset is GREEN**

Run: `ruby test/responsive_images_test.rb`

Expected: asset ownership, existence, resolution, and root-directory assertions pass; overlay assertions may remain red until Task 4.

---

### Task 3: Three Scopen AI cover variants

**Files:**
- Create: `assets/img/projects/scopen/cover-logo.png`
- Create: `assets/img/projects/scopen/cover-product.png`
- Create: `assets/img/projects/scopen/cover-blueprint.png`
- Create or select: `assets/img/projects/scopen/cover.png`
- Modify: `_projects/scopen.md`

**Interfaces:**
- Consumes: `assets/img/projects/scopen/poster.jpg`, `id_render.png`, and `id_blue.png`
- Produces: three high-resolution landscape covers with crop-safe focal regions; `cover.png` is the default responsive source

- [ ] **Step 1: Generate the logo-preserving expanded variant**

Use ImageGen with the poster reference. Preserve the logo and pen, reduce their apparent scale, expand the white/very-light technical background, center the composition, and leave generous safe margins.

- [ ] **Step 2: Generate the product-only variant**

Use the industrial render as reference. Preserve the pen silhouette and key physical features, place it in a cool blue-white engineering environment, omit all text and watermarks, and leave a low-detail lower-left metadata zone.

- [ ] **Step 3: Generate the blueprint variant**

Use the blueprint reference. Build a deliberate technical-drawing composition with blueprint lines, restrained cyan highlights, and the device as the focal object; omit embedded website text.

- [ ] **Step 4: Validate dimensions and choose the default**

Use `vipsheader` to require at least 1600px width. Inspect all three variants in the actual desktop and mobile card crops. Copy the strongest variant to `cover.png` and set Scopen frontmatter to `/assets/img/projects/scopen/cover.png`.

- [ ] **Step 5: Run the responsive image test**

Run: `ruby test/responsive_images_test.rb`

Expected: Scopen cover ownership, existence, and minimum width pass.

---

### Task 4: Shared refined cover overlay

**Files:**
- Modify: `_sass/pages/_home.scss`
- Modify: `_sass/pages/_projects.scss`
- Test: `test/responsive_images_test.rb`

**Interfaces:**
- Consumes: existing `.portfolio-item`, `.portfolio-meta`, `.highlight-card`, and `.highlight-info` markup
- Produces: one visually aligned card-owned gradient model across homepage and Projects highlights

- [ ] **Step 1: Implement the homepage card shade**

Add a non-interactive card pseudo-element above the image and below metadata using a transparent-to-blue-black gradient that stays clear through 56% of the card and ends at 0.56 alpha. Remove the gradient background from `.portfolio-meta` and reduce its text shadow.

- [ ] **Step 2: Implement the Projects highlight shade**

Replace the existing inset-dependent gradient and primary override with the same full-card gradient stops. Keep metadata padding fixed, reduce the primary title cap from 38px to 32px, and cap mobile titles at 26px.

- [ ] **Step 3: Run tests and verify GREEN**

Run: `ruby test/responsive_images_test.rb`

Expected: all Minitest assertions pass, including removal of old opaque gradients.

---

### Task 5: Full verification and visual QA

**Files:**
- Verify: generated `_site/`
- Verify: complete working-tree diff

**Interfaces:**
- Consumes: completed asset migration, cover variants, responsive markup, and overlay CSS
- Produces: verified unstaged implementation ready for user review

- [ ] **Step 1: Run a clean production build**

Run: `bundle exec jekyll clean`

Run: `JEKYLL_ENV=production bundle exec jekyll build`

Expected: exit 0 without warnings or missing-image errors.

- [ ] **Step 2: Run all automated suites**

Run: `ruby test/responsive_images_test.rb`

Run: `ruby test/modern_pages_test.rb`

Run: `node --test test/javascript/*.test.js`

Run: `git diff --check`

Expected: zero failures and zero whitespace errors.

- [ ] **Step 3: Perform browser QA at desktop and mobile widths**

Inspect homepage Projects and the Projects highlight section. Confirm shade height and opacity remain consistent across different images, metadata stays readable, Scopen retains its focal subject, and responsive source selection matches card width.

- [ ] **Step 4: Audit references and cleanup**

Search repository and `_site` output for old root-level paths and `covers-hd`. Remove only leftovers proven unreferenced, then repeat the build and relevant tests if cleanup changes files.

- [ ] **Step 5: Confirm Git state**

Run: `git status --short`

Run: `git diff --cached --name-only`

Expected: all task changes remain unstaged, the staged list is empty, and HEAD is unchanged.
