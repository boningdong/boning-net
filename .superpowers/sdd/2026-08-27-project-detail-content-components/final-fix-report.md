# Project Detail Final Review Fix Report

Date: 2026-08-27

Status: Complete

Implementation commit: `04cf294` (`fix: close project detail final review gaps`)

## Outcome

Every final reviewer finding is resolved with focused regression coverage, production rendering coverage where HTML semantics or build behavior mattered, updated author and architecture documentation, and a fresh full-suite verification run.

The worktree contained no unrelated user edits when this wave began. `_site` remained ignored and untracked after production builds, and no temporary site, fixture, or generated media output was added to the repository.

## Finding Resolution

### Important 1: Explicit H1 ID injection

- `ChapterCompiler` now distinguishes authored explicit IDs from ordinary Kramdown-generated IDs.
- Authored explicit IDs must match `\A[A-Za-z][A-Za-z0-9_-]*\z`: an ASCII letter first, followed by ASCII letters, numbers, underscores, or hyphens.
- Malformed explicit IDs fail at the physical H1 line, including frontmatter offset, and duplicate explicit IDs now report the duplicate heading line.
- Kramdown-generated IDs retain Kramdown behavior; the regression preserves generated `café--tools` even though it is outside the authored explicit-ID grammar.
- Chapter section `data-project-chapter` values are HTML-escaped in Ruby.
- Desktop and Corner navigation escape IDs in `href` and `data-project-chapter-link`, and escape chapter titles at their Liquid boundaries.
- Adversarial quote/attribute and markup IDs are rejected. A final Jekyll render injects hostile generated metadata directly into the layout boundary and proves it remains escaped text rather than attributes or elements.

### Important 2: Author Liquid bypass

- Compiler validation rejects author-written Liquid tag and output openings outside fenced code before directive sentinels or internal include references are created.
- Errors include the physical project source line for both `{% ... %}` and `{{ ... }}` forms.
- Backtick and tilde fenced code regions are exempt from rejection and have Liquid opening delimiters replaced with compiler-generated Liquid string outputs. Liquid therefore emits the literal delimiter in one pass without evaluating the authored example.
- A temporary real Jekyll render proves `{{ page.title }}` and `{% include injected.html %}` remain literal visible code, do not expand the page title, and do not attempt the authored include.
- Existing directive rendering still produces and executes the compiler-generated internal includes.

### Important 3: Gallery semantics

- Gallery peer collections now render as `ul` with one `li` per item.
- A captioned item contains `figure`, the media surface, and `figcaption`.
- A captionless item contains a neutral `div` and emits neither `figure` nor `figcaption`, while the compiler still advances its internal figure sequence.
- Shared collection CSS resets list padding and markers; Gallery CSS resets the new inner semantic wrapper margin without changing the approved grid or masonry geometry.
- Focused real-Jekyll render tests cover all peer/list, captioned, and captionless semantics. The Scopen production render asserts three Gallery lists and six Gallery list items.

### Important 4: Strict `project_detail` configuration

- The hook rejects a present scalar, array, or null `project_detail` value instead of coercing it to an empty mapping.
- The compiler independently rejects non-mapping configuration for direct callers.
- Only `navigation` and `intro_style` are accepted. Unknown and misspelled keys fail with the project source path and the allowed-key list.
- Hook and compiler regressions cover scalar, array, null, unknown key, valid mapping, and absent/default behavior.

### Minor 1: Figure metadata entity normalization

- A shared single-pass entity decoder now normalizes Kramdown named, decimal numeric, and hexadecimal numeric entity references in Figure `src`, `alt`, and `title` values before block storage.
- The decoder scans the original source once, so nested text such as `&amp;copy;` becomes `&copy;` rather than being recursively decoded to `©`.
- Liquid remains the single HTML-boundary escape, eliminating `&amp;amp;` and numeric-entity leakage in rendered media attributes and captions.
- Standalone Figure and Gallery regressions cover source, alt, caption, named, numeric, hexadecimal, and nested-reference behavior through real Jekyll rendering.
- Normalization cannot turn numeric-obfuscated `javascript:` into an accepted image source: Figure destinations are now limited to relative, `http`, or `https` values, with protocol-relative/slash-like and control-character forms rejected.

### Minor 2: Featured Link XML comments

- Featured Link now treats XML/HTML comments as body content and rejects them because its contract is exactly one standalone Markdown link.
- The error remains source-aware at the directive opening line.
- The author guide and component contract explicitly document that comments are not silently discarded in this strict body.

### Minor 3: Recursive serialization coverage

- Focused compiler tests now cover recursive hashes, symbol keys, `NaN`, positive infinity, a general unsupported nested object, and representative accepted nested hashes/arrays/scalars.
- Cycle rejection completes as `ConfigurationError` at the directive source line without a stack overflow.
- The existing serializer implementation required no production rewrite.
- Mutation verification temporarily changed cycle handling to accept repeated objects, removed the string-key check, and accepted every float. The three new regressions failed independently with `expected ConfigurationError to be raised`; restoring the guards returned the suite to green.

### Recommendation: Dependency-free mock harness

- `test/project_detail_mock_test.rb` no longer requires Minitest.
- The shared dependency-free harness gained only the assertions needed by the unchanged mock cases and now reports assertion counts.
- `bundle exec ruby test/project_detail_mock_test.rb` reports 7 passed, 0 failed, 55 assertions, preserving the original behavioral and assertion count.
- Task 11 verification commands and descriptions now use the Bundler-compatible dependency-free invocation.

### QA statement correction

- The Task 11 outcome now states that its earlier claim that all deferred minors were resolved was premature.
- It identifies the final-review gaps and points to this report for the fresh evidence that now closes them.

## TDD Evidence

The first focused run after adding regressions observed the expected failures before production changes:

- Chapter compiler rejected the new `source_line_offset` test API because physical-line support was absent.
- Author Liquid include/output tests reported that no `ConfigurationError` was raised; the final-render test attempted to execute `injected.html`.
- Scalar/array config and unknown-key tests reported that no `ConfigurationError` was raised.
- Gallery real-render tests found a `div` collection, `figure` peers, and no captionless neutral wrapper.
- Figure metadata tests observed raw `&amp;`/numeric references in stored blocks, and the obfuscated unsafe scheme was accepted.
- Featured Link accepted a comment plus one link.
- Final navigation rendering did not contain escaped hostile attribute values.

After minimal implementations, each focused suite passed. The pre-existing recursive serializer behavior was covered and then mutation-checked as described above.

## Final Verification

The final verification command ran:

```bash
set -e
for test_file in test/project_detail/*_test.rb test/project_detail/components/*_test.rb; do
  bundle exec ruby "$test_file"
done
bundle exec ruby test/project_detail_processor_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
bundle exec ruby test/project_detail_mock_test.rb
ruby test/modern_pages_test.rb
ruby test/responsive_images_test.rb
node --test test/javascript/*.test.js
JEKYLL_ENV=production bundle exec jekyll build
# local documentation-link and placeholder checks
git diff --check
git status --short
git diff --stat
```

Exact results:

- Project Detail per-file unit/component suite: 153 passed, 0 failed, 803 assertions.
- Project Detail processor: 7 passed, 0 failed, 34 assertions.
- Project Detail rendering: 3 stylesheet checks passed and 11 production-rendering checks passed; 0 failed.
- Approved design mock: 7 passed, 0 failed, 55 assertions through `bundle exec ruby` and the dependency-free harness.
- Broader modern-page Ruby suite: 12 passed, 0 failed.
- Responsive-image Ruby suite: 10 runs, 103 assertions, 0 failures, 0 errors, 0 skips.
- Repository JavaScript suite: 21 passed, 0 failed, 0 skipped or cancelled.
- Production Jekyll build: exit 0.
- Documentation links: 13 files checked, 0 broken local links.
- Documentation placeholders: 2 targets checked, 0 `TODO`/`TBD`/`FIXME` placeholders.
- `git diff --check`: exit 0.
- Pre-commit status contained only the expected final-review source, test, stylesheet, documentation, and report changes; no `_site` or temporary output was tracked.

## Remaining Concerns

No unresolved correctness finding remains.

The Figure URL validation intentionally formalizes a stricter compatibility boundary: protocol-relative, `data:`, and non-HTTP absolute schemes are rejected. The documented Project Detail contract and current Scopen source use local relative assets, so the production build confirms no current content impact.

The final wave did not repeat interactive browser viewport QA because none of the fixes change layout geometry or JavaScript behavior. Gallery's DOM change retains the same layout classes and is covered by compiled CSS, focused Jekyll rendering, and the complete production render/build suite.
