# Hero Copy and Home Image Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved hero copy system, replace the homepage background with a faithful higher-resolution version, and verify that the Artwork hero boundary has no rendering defect.

**Architecture:** Keep the existing hero markup and responsive styling, changing only user-facing copy and one versioned image reference. Use the original homepage banner as a high-fidelity image-edit target, normalize the accepted result to the source aspect ratio at 3840 by 2352 pixels, and validate rendered pages through the existing Jekyll integration checks plus desktop and mobile browser inspection.

**Tech Stack:** Jekyll/Liquid includes, SCSS, built-in ImageGen editing, FFmpeg image normalization, Ruby integration tests, Node test runner, in-app browser verification.

## Global Constraints

- Use the approved A copy exactly.
- Use a visible hyphen separator for Projects, Artwork, and Experiences.
- Preserve all existing hero structure, overlays, dates, navigation, and responsive geometry.
- Treat `assets/img/index/banner.jpg` as an edit target and preserve its composition, subjects, monochrome palette, and angular illustrated texture.
- Save the homepage enhancement as a versioned sibling; do not overwrite the original.
- Do not add an Artwork boundary workaround unless browser evidence demonstrates a real gap or border.
- Leave the pre-existing untracked `.superpowers/` directory untouched.

---

### Task 1: Define the Rendered Hero Contract

**Files:**
- Modify: `test/modern_pages_test.rb`

**Interfaces:**
- Consumes: generated `_site/index.html`, `_site/projects.html`, `_site/artwork.html`, and `_site/resume.html`.
- Produces: integration assertions for approved visible copy, separators, and the new homepage image reference.

- [ ] **Step 1: Add failing rendered-page assertions**

Extend the homepage test to require `/assets/img/index/banner-hd-v2.jpg`. Extend the Projects collection test to require `Projects`, `Ideas made tangible`, `Hardware`, `Software`, and `Experiments`. Replace the old Artwork hero assertions with `The world as I see it`, `Drawing`, `Painting`, and `Mixed media`, while rejecting the old wording. Extend the Experiences hierarchy test to require `Experiences`, `The journey so far`, `Education`, `Career`, and `Growth`, while rejecting the old hero phrases.

- [ ] **Step 2: Build and verify the new contract fails for the intended reasons**

Run:

```bash
bundle exec jekyll build
ruby test/modern_pages_test.rb
```

Expected: Jekyll builds successfully, then the Ruby suite fails because the new image path and approved copy are not yet rendered.

### Task 2: Create the Higher-Resolution Homepage Banner

**Files:**
- Read: `assets/img/index/banner.jpg`
- Create: `assets/img/index/banner-hd-v2.jpg`
- Temporary: `/private/tmp/home-banner-generated.png`

**Interfaces:**
- Consumes: the original 1920 by 1176 monochrome mountain illustration.
- Produces: a visually faithful 3840 by 2352 JPEG for Task 3.

- [ ] **Step 1: Edit the source through built-in ImageGen**

Use the original as the edit target with this prompt:

```text
Use case: precise-object-edit
Asset type: full-viewport personal portfolio website hero background
Primary request: Enhance this exact monochrome mountain illustration to a substantially higher level of clarity and usable resolution while preserving its established visual identity.
Input images: Image 1 is the edit target.
Subject: the same layered alpine range, dark foreground cliffs and pine trees, small hiker on the right ridge, tiny distant birds, and broad quiet sky.
Style/medium: preserve the exact restrained grayscale palette, posterized angular digital brushwork, faceted rock shapes, matte texture, and atmospheric depth; refine existing edges and internal detail without making the image photorealistic.
Composition/framing: preserve the complete source composition, aspect ratio, horizon, scale, subject positions, and open central sky used behind website copy.
Constraints: change only clarity, resolution, and natural fine detail within existing forms; keep all mountains, trees, hiker, birds, tonal relationships, and framing unchanged; no new subjects; no text; no logo; no watermark; no border.
Avoid: photorealism, color tint, smooth airbrushed gradients, new peaks, duplicated trees, extra hikers, dramatic weather, glowing edges, visible seams, or UI elements.
```

- [ ] **Step 2: Inspect the generated result**

Compare it directly with the source. Reject and retry with one targeted correction if the mountain silhouette, right-side hiker, monochrome palette, angular texture, open central sky, or complete framing changes, or if extra subjects, text-like marks, borders, or seams appear.

Copy the accepted built-in artifact to `/private/tmp/home-banner-generated.png` before normalization.

- [ ] **Step 3: Normalize the accepted result**

Crop only if required to match the source aspect ratio, scale with Lanczos, and encode a 3840 by 2352 JPEG:

```bash
ffmpeg -i /private/tmp/home-banner-generated.png -vf "crop=iw:min(ih\,iw*1176/1920):0:(ih-min(ih\,iw*1176/1920))/2,scale=3840:2352:flags=lanczos" -q:v 2 assets/img/index/banner-hd-v2.jpg
```

- [ ] **Step 4: Verify the final asset**

Run:

```bash
sips -g pixelWidth -g pixelHeight assets/img/index/banner-hd-v2.jpg
```

Expected: `pixelWidth: 3840` and `pixelHeight: 2352`. Inspect the final JPEG directly for composition drift and generation artifacts.

### Task 3: Apply the Approved Copy and Image Reference

**Files:**
- Modify: `_includes/pages/home/hero.html`
- Modify: `_includes/pages/artwork/hero.html`
- Modify: `_includes/pages/experiences/hero.html`

**Interfaces:**
- Consumes: `assets/img/index/banner-hd-v2.jpg` and the approved copy contract from Task 1.
- Produces: updated rendered hero markup without layout or behavior changes.

- [ ] **Step 1: Update the homepage image path**

Change only the homepage hero `src` to `/assets/img/index/banner-hd-v2.jpg`. Keep the class, alt text, and fetch priority unchanged.

- [ ] **Step 2: Update Artwork copy**

Render exactly:

```text
Artwork - The world as I see it
Drawing / Painting / Mixed media
```

Keep the existing elements and classes; replace the visible em dash with a hyphen.

- [ ] **Step 3: Update Experiences copy**

Render exactly:

```text
Experiences - The journey so far
Education / Career / Growth
```

Keep the existing elements and classes; change `Experience` to `Experiences` and replace the visible slash separator with a hyphen.

- [ ] **Step 4: Build and verify the rendered contract passes**

Run:

```bash
bundle exec jekyll build
ruby test/modern_pages_test.rb
```

Expected: the build succeeds and every Ruby integration test passes.

### Task 4: Perform Full Regression and Responsive Visual Verification

**Files:**
- Verify: `_site/index.html`
- Verify: `_site/projects.html`
- Verify: `_site/artwork.html`
- Verify: `_site/resume.html`

**Interfaces:**
- Consumes: the complete updated site.
- Produces: evidence that text, imagery, boundary rendering, and existing interactivity remain correct.

- [ ] **Step 1: Run the JavaScript regression suite**

Run:

```bash
node --test test/javascript/*.test.js
```

Expected: every JavaScript test passes with no warnings or errors.

- [ ] **Step 2: Inspect desktop rendering**

At a 1440 by 900 viewport, inspect the homepage, Projects, Artwork, and Experiences heroes. Confirm the approved text, single-line or balanced wrapping, consistent hyphen treatment, readable contrast, sharp homepage background, and absence of broken images.

- [ ] **Step 3: Inspect mobile rendering**

At a 390 by 844 viewport, inspect the same four heroes. Confirm no horizontal overflow or clipped copy, meaningful image crops, and usable navigation.

- [ ] **Step 4: Re-check the Artwork boundary**

Confirm `.artwork-hero` and `.artwork-hero-image` share the same bottom edge, there is no border or gap, and the next pixel belongs to `.artwork-content`. Make no CSS change if those facts remain true.

- [ ] **Step 5: Run final source and scope checks**

Run:

```bash
git diff --check
git status --short
```

Expected: no whitespace errors; only this task's test, includes, documentation, and versioned homepage asset are changed, while `.superpowers/` remains untouched.

- [ ] **Step 6: Commit the completed implementation**

Stage only the intended files and commit with:

```bash
git commit -m "feat: polish hero copy and homepage image"
```
