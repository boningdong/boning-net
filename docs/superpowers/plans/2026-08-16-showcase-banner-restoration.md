# Showcase Banner Restoration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the Projects hero to its original engineering-blueprint artwork and deliver sharp, vertically expanded banner assets for Projects, Artwork, and Experience.

**Architecture:** Use each existing banner as a high-fidelity image-edit target, generating scene-consistent material above and below the original composition. Normalize each accepted result to a 3840 by 800 JPEG for the current 4.8:1 hero, then update the three page includes without changing copy, overlays, or behavior.

**Tech Stack:** Jekyll/Liquid includes, built-in ImageGen editing, FFmpeg image normalization, Bundler/Jekyll verification.

## Global Constraints

- Preserve the complete horizontal composition and recognizable central subjects.
- Extend only the top and bottom with scene-consistent content and edge continuity.
- Add no text, logos, watermarks, new focal subjects, or decorative UI elements.
- Keep the center region calm enough for the existing white title overlay.
- Save enhanced files as versioned siblings; do not overwrite the source files.
- Final website assets must be 3840 by 800 pixels with a 4.8:1 aspect ratio.

---

### Task 1: Generate and Normalize the Three Enhanced Banners

**Files:**
- Read: `assets/img/showcase/projects-banner.jpg`
- Read: `assets/img/showcase/artwork-banner.jpg`
- Read: `assets/img/showcase/experience-banner.jpg`
- Create: `assets/img/showcase/projects-banner-hd.jpg`
- Create: `assets/img/showcase/artwork-banner-hd.jpg`
- Create: `assets/img/showcase/experience-banner-hd.jpg`
- Temporary: `/private/tmp/projects-banner-generated.png`
- Temporary: `/private/tmp/artwork-banner-generated.png`
- Temporary: `/private/tmp/experience-banner-generated.png`

**Interfaces:**
- Consumes: the three original 1920-by-252 JPEG banners.
- Produces: three 3840-by-800 JPEG assets referenced by Task 2.

- [ ] **Step 1: Edit the Projects source with built-in ImageGen**

Use `assets/img/showcase/projects-banner.jpg` as the edit target with this prompt:

```text
Use case: precise-object-edit
Asset type: responsive portfolio website hero banner
Primary request: Expand this exact engineering-blueprint banner vertically above and below while increasing clarity and detail. Preserve the original center strip, its full left-to-right mechanical sketch composition, dark navy blueprint paper, warm beige hand-drawn technical lines, line weights, grid, and restrained texture.
Composition/framing: very wide landscape banner; the original artwork remains centered horizontally and vertically; generate only scene-consistent blueprint paper and plausible continuation of cropped mechanical drawing lines above and below.
Constraints: change only the missing vertical canvas and resolution; keep all existing objects, proportions, colors, marks, and horizontal framing unchanged; calm center for white page title; no new focal object; no legible new words or numbers; no logo; no watermark; no border.
Avoid: photorealistic machinery, bright cyan CAD glow, modern UI overlays, dramatic lighting, seams, duplicated parts, or invented annotations.
```

Copy the accepted built-in tool artifact to `/private/tmp/projects-banner-generated.png`.

- [ ] **Step 2: Inspect the Projects result**

Reject and retry with one targeted correction if the central mechanical parts, muted palette, full-width composition, or hand-drawn quality changed, or if seams/text-like artifacts appear.

- [ ] **Step 3: Edit the Artwork source with built-in ImageGen**

Use `assets/img/showcase/artwork-banner.jpg` as the edit target with this prompt:

```text
Use case: precise-object-edit
Asset type: responsive portfolio website hero banner
Primary request: Expand this exact painterly forest-studio scene vertically above and below while increasing clarity. Preserve the original center strip, full left-to-right composition, trees, desk/easel-like forms, muted blue-green and plum palette, blocky digital brushwork, and atmospheric depth.
Composition/framing: very wide landscape banner; original artwork centered; extend the upper forest canopy and lower foreground naturally without introducing new focal subjects.
Constraints: change only the missing vertical canvas and resolution; keep every existing subject, proportion, palette relationship, brush style, and horizontal framing unchanged; calm center for white page title; no people; no text; no logo; no watermark; no border.
Avoid: photorealism, crisp vector edges, saturated neon colors, duplicated tree trunks, visible seams, or extra furniture.
```

Copy the accepted built-in tool artifact to `/private/tmp/artwork-banner-generated.png`.

- [ ] **Step 4: Inspect the Artwork result**

Reject and retry with one targeted correction if the original arrangement, palette, brushwork, or atmospheric depth changed, or if seams and unintended subjects appear.

- [ ] **Step 5: Edit the Experience source with built-in ImageGen**

Use `assets/img/showcase/experience-banner.jpg` as the edit target with this prompt:

```text
Use case: precise-object-edit
Asset type: responsive portfolio website hero banner
Primary request: Expand this exact painterly seascape vertically above and below while increasing clarity. Preserve the original center strip, full left-to-right ocean horizon, foreground sailboat, distant boats and rock, turquoise/navy palette, soft cloud forms, and faceted digital brushwork.
Composition/framing: very wide landscape banner; original artwork centered; continue only sky above and water below with the same perspective, wave rhythm, and brush texture.
Constraints: change only the missing vertical canvas and resolution; keep all existing boats, horizon, rock, proportions, colors, and horizontal framing unchanged; calm center for white page title; no new boats or landforms; no text; no logo; no watermark; no border.
Avoid: photorealism, glossy 3D rendering, saturated tropical colors, duplicated boats, visible seams, or dramatic weather.
```

Copy the accepted built-in tool artifact to `/private/tmp/experience-banner-generated.png`.

- [ ] **Step 6: Inspect the Experience result**

Reject and retry with one targeted correction if any boat, horizon, palette, brushwork, or composition changed, or if seams and new objects appear.

- [ ] **Step 7: Normalize accepted results to the production dimensions**

For each generated image, crop around the vertical center to a 4.8:1 frame, scale with Lanczos, and encode as a high-quality JPEG:

```bash
ffmpeg -i /private/tmp/projects-banner-generated.png -vf "crop=iw:iw/4.8:0:(ih-iw/4.8)/2,scale=3840:800:flags=lanczos" -q:v 2 assets/img/showcase/projects-banner-hd.jpg
ffmpeg -i /private/tmp/artwork-banner-generated.png -vf "crop=iw:iw/4.8:0:(ih-iw/4.8)/2,scale=3840:800:flags=lanczos" -q:v 2 assets/img/showcase/artwork-banner-hd.jpg
ffmpeg -i /private/tmp/experience-banner-generated.png -vf "crop=iw:iw/4.8:0:(ih-iw/4.8)/2,scale=3840:800:flags=lanczos" -q:v 2 assets/img/showcase/experience-banner-hd.jpg
```

- [ ] **Step 8: Verify asset dimensions and inspect final crops**

Run:

```bash
sips -g pixelWidth -g pixelHeight assets/img/showcase/projects-banner-hd.jpg assets/img/showcase/artwork-banner-hd.jpg assets/img/showcase/experience-banner-hd.jpg
```

Expected: each asset reports `pixelWidth: 3840` and `pixelHeight: 800`. Open all three final files and confirm no seams, hallucinated text, or damaged subjects remain in the production crop.

### Task 2: Connect the Enhanced Assets to the Page Heroes

**Files:**
- Modify: `_includes/pages/projects/hero.html`
- Modify: `_includes/pages/artwork/hero.html`
- Modify: `_includes/pages/experiences/hero.html`

**Interfaces:**
- Consumes: the three `*-banner-hd.jpg` files from Task 1.
- Produces: rendered hero `<img>` elements using those files.

- [ ] **Step 1: Verify the current hero references**

Run:

```bash
rg -n "hero-image.*src=" _includes/pages/projects/hero.html _includes/pages/artwork/hero.html _includes/pages/experiences/hero.html
```

Expected: Projects references `/assets/img/index/project-1.jpg`; Artwork and Experience reference their original low-height banner files.

- [ ] **Step 2: Update only the three image paths**

Set the Liquid `src` values to:

```text
/assets/img/showcase/projects-banner-hd.jpg
/assets/img/showcase/artwork-banner-hd.jpg
/assets/img/showcase/experience-banner-hd.jpg
```

Keep all existing classes, alt text, copy, dates, and fetch priority unchanged.

- [ ] **Step 3: Confirm there are exactly three HD references**

Run:

```bash
rg -n "showcase/(projects|artwork|experience)-banner-hd\.jpg" _includes/pages
```

Expected: one reference in each corresponding hero include and no unrelated matches.

### Task 3: Build and Perform Responsive Visual Verification

**Files:**
- Verify: `_site/projects.html`
- Verify: `_site/artwork.html`
- Verify: `_site/experiences.html`

**Interfaces:**
- Consumes: updated includes and enhanced image files.
- Produces: verified static pages with responsive banner presentation.

- [ ] **Step 1: Run source-level checks**

Run:

```bash
git diff --check
```

Expected: no output and exit code 0.

- [ ] **Step 2: Build the Jekyll site**

Run:

```bash
bundle exec jekyll build
```

Expected: build completes without errors.

- [ ] **Step 3: Start the local server and inspect all heroes**

Run:

```bash
bundle exec jekyll serve
```

Inspect `/projects/`, `/artwork/`, and `/experiences/` at approximately 1440-pixel and 390-pixel viewport widths. Confirm sharp imagery, title readability, balanced crop, no visible extension seams, and no broken asset requests.

- [ ] **Step 4: Review the final diff and working-tree scope**

Run:

```bash
git diff -- _includes/pages/projects/hero.html _includes/pages/artwork/hero.html _includes/pages/experiences/hero.html
git status --short
```

Expected: only the three intended includes, three new banner assets, and this task's documentation are changed; pre-existing `.superpowers/` files remain untouched.
