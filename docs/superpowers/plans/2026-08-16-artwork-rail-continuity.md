# Artwork Rail Continuity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Artwork Highlights and The Collection read as one continuous Projects-style Mist gallery, with an automatic-only default rail, a reduced-motion manual fallback, and wider softer edge fades.

**Architecture:** Keep the existing collection data, duplicated seamless track, and JavaScript drift engine. Add one noninteractive rail-shell wrapper so fixed edge overlays are independent of the scrolling viewport, and express default versus reduced-motion overflow entirely in page SCSS.

**Tech Stack:** Jekyll 4.4.1, Liquid, SCSS/Sass, vanilla JavaScript, Ruby generated-page contracts, Node's built-in test runner, in-app browser verification.

## Global Constraints

- The approved refinement is defined in `docs/superpowers/specs/2026-08-16-artwork-rail-continuity-design.md`.
- Do not modify the approved mock, preset, or `.superpowers/` directory.
- Artwork must use the same continuous Mist background recipe as Projects: `radial-gradient(circle at 76% 22%, rgb(255 255 255 / 0.68), transparent 36%), var(--mist)`.
- Keep Highlights and The Collection as separate semantic sections inside one uninterrupted background, with the existing `80px` desktop and `57.6px` mobile transition spacing.
- Default mode permits only automatic drift; horizontal wheel, trackpad, touch, scrollbar, and keyboard input must not manually move the rail.
- `prefers-reduced-motion: reduce` disables automatic drift and restores manual horizontal scrolling while keeping the scrollbar visually hidden.
- Hover and keyboard focus continue to pause automatic drift.
- Edge fades are fixed outside the scrolling element, wider and softer than the current `24px` mask, use stronger blur, and never intercept pointer or focus input.
- Preserve every artwork's intrinsic aspect ratio and existing viewer/filter behavior.
- Do not add controls or other UI.
- Do not push or merge.

---

## File Structure

- Modify `_includes/pages/artwork/highlights.html`: add one `artwork-rail-shell` wrapper while preserving the named rail region and track hooks.
- Modify `_sass/pages/_artwork.scss`: match Projects Mist, define default/reduced-motion overflow, hide scrollbars, and render fixed responsive edge overlays.
- Modify `test/modern_pages_test.rb`: assert the rail-shell contract in generated HTML.
- Do not modify `assets/js/pages/artwork.js` unless browser verification proves hidden overflow still accepts manual input; the existing `matchMedia` policy already stops automatic drift under reduced motion.

---

### Task 1: Add the Rail-Shell Contract

**Files:**
- Modify: `test/modern_pages_test.rb`
- Modify: `_includes/pages/artwork/highlights.html`

**Interfaces:**
- Consumes: the existing `[data-artwork-rail]` named region and `[data-artwork-track]` drift hook.
- Produces: one `.artwork-rail-shell` parent used by SCSS edge overlays without changing JavaScript selectors.

- [ ] **Step 1: Write the failing generated-page test**

Extend the Artwork hierarchy case with a scoped ordering assertion:

```ruby
assert_includes html, '<div class="artwork-rail-shell" data-artwork-rail-shell>'
shell_position = html.index('data-artwork-rail-shell')
rail_position = html.index('data-artwork-rail tabindex="0"')
track_position = html.index('data-artwork-track')
assert(shell_position < rail_position && rail_position < track_position, "expected shell to wrap the accessible rail and track")
```

- [ ] **Step 2: Run the Ruby contract to verify RED**

Run:

```bash
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
```

Expected: the new shell assertion fails while existing modern-page contracts pass.

- [ ] **Step 3: Add the minimal wrapper**

Render the existing accessible rail unchanged inside:

```liquid
<div class="artwork-rail-shell" data-artwork-rail-shell>
  <div class="artwork-rail" role="region" aria-label="Highlighted artwork" data-artwork-rail tabindex="0">
    <!-- existing track and loops -->
  </div>
</div>
```

- [ ] **Step 4: Rebuild and verify GREEN**

Run the commands from Step 2.

Expected: all Ruby generated-page contracts pass.

### Task 2: Implement Mist Continuity and Motion-Gated Rail Styling

**Files:**
- Modify: `_sass/pages/_artwork.scss`
- Test: `test/modern_pages_test.rb`
- Test: `test/javascript/artwork.test.js`

**Interfaces:**
- Consumes: `.artwork-rail-shell`, `.artwork-rail`, shared Mist/card variables, and the existing JavaScript `shouldAutoDrift({ reducedMotion, paused })` policy.
- Produces: automatic-only default overflow, reduced-motion manual fallback, invisible scrollbars, and noninteractive fixed edge fades.

- [ ] **Step 1: Record the pre-change browser failure**

At approximately `1440×1000`, verify the current rail exposes `overflow-x: auto`, a visible scrollbar, and accepts horizontal manual input. This is the visual RED state for the approved refinement.

- [ ] **Step 2: Match the Projects Mist recipe exactly**

Change `.artwork-content` to:

```scss
background:
  radial-gradient(circle at 76% 22%, rgb(255 255 255 / 0.68), transparent 36%),
  var(--mist);
```

Keep `.artwork-highlights` and `.artwork-collection` transparent and retain their existing spacing variables.

- [ ] **Step 3: Make default overflow automatic-only and hide scrollbars**

Use:

```scss
.artwork-rail {
  overflow-x: hidden;
  scrollbar-width: none;
}

.artwork-rail::-webkit-scrollbar {
  display: none;
}
```

Remove the existing mask-image and visible scrollbar colors. Keep the rail focusable so keyboard focus can pause drift.

- [ ] **Step 4: Restore manual overflow only for reduced motion**

Add:

```scss
@media (prefers-reduced-motion: reduce) {
  .artwork-rail {
    overflow-x: auto;
  }
}
```

Do not alter the existing JavaScript motion policy: it reads `matchMedia('(prefers-reduced-motion: reduce)').matches` on every frame and therefore reacts live.

- [ ] **Step 5: Add wider fixed edge fades**

Make `.artwork-rail-shell` positioned and add pointer-transparent pseudo-elements above the rail. Desktop overlays use a responsive width around `clamp(72px, 10vw, 168px)`, a gradual multi-stop Mist-to-transparent gradient, and approximately `14px` backdrop blur. Mobile overlays use approximately `56px` width and `10px` blur. Left and right gradients mirror each other.

- [ ] **Step 6: Build and run automated suites**

Run:

```bash
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
node --test test/javascript/*.test.js
```

Expected: Jekyll succeeds, all Ruby contracts pass, and all JavaScript tests pass.

### Task 3: Browser Verification and Handoff

**Files:**
- Modify only if a reproduced failure requires a scoped TDD fix.

**Interfaces:**
- Consumes: completed markup and SCSS from Tasks 1–2.
- Produces: evidence for the approved default and reduced-motion behavior.

- [ ] **Step 1: Verify desktop default mode**

At approximately `1440×1000`, confirm one continuous Projects-matched Mist surface, no scrollbar or hard section divider, wider fixed blurred edge fades, automatic drift, hover/focus pause, no manual movement from wheel/trackpad-equivalent or keyboard input, intact image ratios, no page overflow, and no console errors.

- [ ] **Step 2: Verify mobile default mode**

At approximately `390×844`, confirm the responsive edge width/blur, automatic-only rail, hidden scrollbar, correct image ratios, intact filters/viewer, no page overflow, and no console errors.

- [ ] **Step 3: Verify reduced-motion mode where browser tooling permits**

Emulate `prefers-reduced-motion: reduce`; confirm automatic drift stops, manual horizontal input works, the scrollbar remains hidden, and live preference changes do not require a reload. If the browser runtime lacks media emulation, report this limitation and rely on the existing Node policy test plus compiled CSS inspection without claiming browser verification.

- [ ] **Step 4: Run final fresh verification**

Run:

```bash
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
node --test test/javascript/*.test.js
git diff --check
git status --short
```

- [ ] **Step 5: Commit the implementation**

```bash
git add _includes/pages/artwork/highlights.html _sass/pages/_artwork.scss test/modern_pages_test.rb docs/superpowers/plans/2026-08-16-artwork-rail-continuity.md
git commit -m "refine: unify artwork rail continuity"
```

Do not stage `.superpowers/`, push, or merge.

---

## Self-Review

- Spec coverage: Mist parity, semantic section continuity, automatic-only default overflow, reduced-motion manual fallback, hidden scrollbars, wider blurred overlays, preserved aspect ratios, no new UI, automated tests, and desktop/mobile verification all map to explicit steps.
- Placeholder scan: every task names exact files, selectors, values, commands, expected outcomes, and fallback reporting behavior.
- Interface consistency: the Liquid wrapper class matches the SCSS selector; existing JavaScript data hooks remain unchanged; reduced-motion CSS and JavaScript use the same media query.
