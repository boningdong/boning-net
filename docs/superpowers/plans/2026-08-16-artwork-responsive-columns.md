# Artwork Responsive Columns Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Artwork's collection masonry use the same three-, two-, and one-column responsive progression as the Projects archive.

**Architecture:** Keep the existing CSS multi-column masonry and its `--artwork-collection-columns` variable. Add a single mobile override at the shared `640px` breakpoint; no markup or JavaScript changes are needed.

**Tech Stack:** Jekyll 4.4.1, Liquid-generated pages, SCSS/Sass, Ruby generated-page contracts, Node's built-in test runner, in-app browser verification.

## Global Constraints

- Above `850px`, The Collection remains three columns.
- From `641px` through `850px`, The Collection remains two columns.
- At `640px` and below, The Collection becomes one column, matching Projects.
- Keep the existing `28px` desktop and `21px` mobile gaps.
- Preserve artwork images' intrinsic aspect ratios without cropping.
- Do not change Highlights, filters, viewer behavior, content ordering, or collection data.
- Do not modify or stage `.superpowers/`.
- Do not push or merge.

---

## File Structure

- Modify `test/modern_pages_test.rb`: protect the compiled mobile one-column Artwork contract.
- Modify `_sass/pages/_artwork.scss`: set the collection column variable to one inside the existing `max-width: 640px` media query.

---

### Task 1: Align Artwork Collection Breakpoints With Projects

**Files:**
- Modify: `test/modern_pages_test.rb`
- Modify: `_sass/pages/_artwork.scss`

**Interfaces:**
- Consumes: `.artwork-collection-grid { columns: var(--artwork-collection-columns); }` and the existing `850px` two-column override.
- Produces: a compiled `max-width: 640px` rule setting `--artwork-collection-columns: 1`.

- [ ] **Step 1: Write the failing generated-CSS contract**

Add these assertions to the Artwork visual module test so the complete responsive progression, masonry gaps, and uncropped image contract remain protected:

```ruby
assert_includes css, ".artwork-page{--artwork-highlight-height: 330px;--artwork-collection-columns: 3"
assert_includes css, ".artwork-collection-grid{columns:var(--artwork-collection-columns);column-gap:var(--card-gap)}"
assert_includes css, ".artwork-collection-card .artwork-card-media,.artwork-collection-card img{width:100%;height:auto}"
assert_includes css, "@media(max-width: 850px){.artwork-page{--artwork-collection-columns: 2}"
assert_includes css, "@media(max-width: 640px){.artwork-page{--artwork-collection-columns: 1}"
assert_includes css, ".artwork-collection-grid{column-gap:var(--mobile-card-gap)}"
```

The existing rules satisfy every assertion except the new phone-specific one-column override, so RED remains attributable to the missing `640px` behavior.

- [ ] **Step 2: Build and run the focused Ruby test to verify RED**

Run:

```bash
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
```

Expected: the Artwork visual-module case fails because the compiled `640px` one-column contract is absent; the other cases pass.

- [ ] **Step 3: Add the minimal SCSS override**

At the beginning of `_sass/pages/_artwork.scss`'s existing `@media (max-width: 640px)` block, add:

```scss
.artwork-page {
  --artwork-collection-columns: 1;
}
```

Do not change the masonry implementation or gap values.

- [ ] **Step 4: Rebuild and verify GREEN**

Run:

```bash
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
```

Expected: `9 passed, 0 failed`.

- [ ] **Step 5: Verify both responsive states in a real browser**

At `390x844`, inspect The Collection and confirm:

- computed `column-count` is `1`;
- visible collection cards occupy the single masonry column;
- displayed image width/height ratios match `naturalWidth/naturalHeight` within rendering tolerance;
- document horizontal overflow is `0`;
- the console has no errors.

At `768x900`, confirm computed `column-count` remains `2`, document horizontal overflow is `0`, and the console has no errors.

- [ ] **Step 6: Run the complete verification suite**

Run:

```bash
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec jekyll build
/Users/boning/.rvm/wrappers/ruby-3.3.6/bundle exec ruby test/modern_pages_test.rb
node --test test/javascript/*.test.js
git diff --check
git status --short
```

Expected: the build succeeds, Ruby reports `9 passed, 0 failed`, Node reports `12` passing tests and `0` failures, `git diff --check` is silent, and status lists only the intended plan/test/SCSS changes plus the pre-existing untracked `.superpowers/` directory.

- [ ] **Step 7: Request final code review and create the local commit**

Request review of the final diff against `docs/superpowers/specs/2026-08-16-artwork-responsive-columns-design.md`. Resolve all Critical and Important findings, repeat Step 6 if code changes, then commit only:

```bash
git add docs/superpowers/plans/2026-08-16-artwork-responsive-columns.md test/modern_pages_test.rb _sass/pages/_artwork.scss
git commit -m "fix: align artwork mobile columns"
```

Do not add `.superpowers/`, push, or merge.
