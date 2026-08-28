# Task 11 Report: Full Regression, Integration Cleanup, and Browser QA

## Outcome

The Project Detail integration is reproducible, the deferred minor findings are resolved, the browser-discovered `navigation: none` width defect is fixed, and the complete regression/build matrix passes.

`_site` remains ignored and unstaged. The temporary Gallery 2/3/4/masonry browser fixture was removed after QA, and no generated responsive image was left in the source tree.

## Commits

- `22f8314` (`chore: preserve approved project detail design baseline`) commits the previously approved Hero/Bridge/Corner include changes, selected Hero assets, recovered design mocks, and mock regression test.
- `f41088e` (`fix: close project detail integration gaps`) commits the deferred validation, video semantics, documentation, Scopen URL assertions, serialization guard, Corner Escape fallback, and reduced-motion testability changes.
- `f830c35` (`fix: expand project details without navigation`) commits the browser-discovered full-width Main Content fix for `project_detail.navigation: none` and its stylesheet regression.

## Integration Cleanup

- Featured Link now rejects empty, ASCII-whitespace-only, and Unicode-space-only accessible labels.
- A whitespace-only video link title is normalized to an absent caption.
- Captionless videos render a neutral `div.project-video-content`; captioned videos retain `figure` and `figcaption`. Both paths share identical layout styling.
- Scopen source coverage asserts all three exact LinkedIn team URLs.
- The author guide clarifies that comments are globally permitted in ordinary Project Detail content while each strict component body follows its own Content Contract.
- The documented serializability gap was reachable through the supported registered-component extension boundary: an injected component could return arbitrary nested Ruby objects. The compiler now recursively accepts only string-keyed hashes, arrays, strings, integers, finite floats, booleans, and `nil`, while rejecting cycles and other object types.
- Corner Navigation now has an explicit Escape keydown fallback. This was added after the selected in-app browser did not close the native dialog through supported synthetic Escape input, even though the close button and anchors worked.
- Reduced-motion anchor behavior is now directly testable: reduced motion selects `auto`; the default selects `smooth`.
- `project_detail.navigation: none` now adds a no-navigation reading modifier so Main Content occupies the full content width instead of the otherwise reserved 176px rail column.

## Final Automated Verification

The final verification command was:

```bash
set -e
for test_file in test/project_detail/*_test.rb test/project_detail/components/*_test.rb; do
  bundle exec ruby "$test_file"
done
bundle exec ruby test/project_detail_processor_test.rb
bundle exec ruby test/project_detail_rendering_test.rb
ruby test/project_detail_mock_test.rb
ruby test/modern_pages_test.rb
ruby test/responsive_images_test.rb
node --test test/javascript/*.test.js
JEKYLL_ENV=production bundle exec jekyll build
git diff --check
git status --short
```

Results:

- Project Detail per-file unit suite: 136 passed, 0 failed.
- Project Detail processor: 4 passed, 0 failed.
- Project Detail rendering: 3 stylesheet checks and 9 production-rendering checks passed.
- Approved design mock suite, run with plain Ruby because Minitest is not declared in the bundle: 7 runs, 55 assertions, 0 failures.
- Broader modern-page suite: 12 passed, 0 failed.
- Responsive-image suite, run with plain Ruby: 10 runs, 103 assertions, 0 failures.
- Repository JavaScript suite: 20 passed, 0 failed.
- Production Jekyll build: exit 0, no Project Detail warnings, no directive-marker leak reported by rendering assertions.
- `git diff --check`: clean.

Focused TDD evidence included observed red failures before implementation for:

- Featured Link whitespace-only accessible labels.
- Video whitespace-only captions and captionless neutral semantics.
- Nested non-JSON-like component data.
- Corner Escape handler.
- Reduced-motion scroll behavior.
- No-navigation Main Content width.

## Browser QA

The local Jekyll server ran at `http://127.0.0.1:4011/` because port 4000 was already occupied. Browser control used the required in-app browser runtime. The viewport override was reset and the server was stopped after QA.

### Scopen viewport evidence

| Viewport | Hero and Bridge | Navigation | Responsive component evidence |
| --- | --- | --- | --- |
| 3840 × 2160 | Hero and image rectangles were both `3840 × 780`; `object-fit: cover`, `object-position: 72% 50%`, and Hero overflow was hidden. Visual capture kept the focal instrument at the right without revealing a top or bottom image edge. Bridge was `1120 × 422` with `186.836px / 851.164px` columns and an `82px` gap. | Desktop rail was visible, sticky, and `top: 86px`; Corner was hidden. | No horizontal overflow. All 16 media frames shared one border/radius/background/shadow/backdrop signature; nested images reported `backdrop-filter: none`.
| 1440 × 1000 | Hero and image rectangles were both `1440 × 520`; the approved subject remained visible with no exposed image edge. Bridge remained `1120 × 422` with the approved two-column geometry. | Desktop rail was visible and sticky; Corner was hidden. | Videos were two `351px` columns, People were three `228px` columns, two-item Galleries were two `418px` columns, and desktop captions used the approved label/text split or the video single-column caption form. No horizontal overflow.
| 820 × 1180 | Hero and image rectangles were both `820 × 520`, `object-position: 76% 50%`. Bridge was `776 × 355`, with `120px / 622px` columns and a `34px` gap. | Desktop rail was hidden. Corner remained hidden at the top of the page. | Videos collapsed to one `720px` column, People used two `351px` columns, and Scopen Galleries retained two `379px` columns. No horizontal overflow.
| 390 × 844 | Hero and image rectangles were both `390 × 470`, `object-position: 80% 50%`; the visual capture retained the instrument subject and no exposed top/bottom edge. Bridge stacked cleanly in the visual capture. | Corner was hidden at the top. After scroll, Main Content top was `201px` against a `591px` reveal line and Corner became visible with `1 / 5`. | Videos, Galleries, People, and captions collapsed to `362px` single columns with no horizontal overflow. Mobile captions used a `6px` label/text gap.

### Corner interaction evidence at 390 × 844

- Before Main Content: `hidden=true`, not visible.
- Open through a coordinate derived from the visible trigger: dialog opened without changing the tested `700px` scroll position; focus moved to the Close button.
- Close button: dialog closed, scroll remained `700px`, and focus returned to the trigger.
- Hardware anchor: dialog closed, URL became `#hardware`, Hardware reached `70px` from the viewport top, both desktop/mobile Hardware links carried `aria-current="location"`, count became `2 / 5`, and focus returned to the trigger.
- Escape after the explicit fallback: dialog closed, scroll was preserved, and focus returned to the trigger.
- Active-section tracking also selected Team in both navigation presentations during direct scroll inspection.

The first semantic-locator open appeared to jump from `700px` to `2004px`. Root-cause isolation showed that this was the test locator auto-scrolling the fixed trigger's DOM position before clicking; a visible coordinate click preserved `700px` exactly and ruled out an application scroll-jump defect.

### Component and surface evidence

- Scopen rendered Figure, three two-item Galleries, Videos, Callout, Narrative Title, People, and Featured Link with their expected semantic elements and counts.
- Every `.project-media-frame` on Scopen reported the same `26px` radius, translucent surface, inset highlight, drop shadow, and `blur(12px) saturate(1.02)` backdrop signature.
- Nested images reported no backdrop filter, confirming no double-glass compositing.
- Featured Link rendered as a flex surface with `26px` radius; Callout and People cards used the same radius/surface/shadow family without nested glass.
- Desktop captions used the label/text grid for standalone media and one-column captions inside video/gallery items; mobile captions collapsed to one column with a `6px` gap.
- The browser reported `prefers-reduced-motion: reduce` inactive in the host environment. It confirmed that the reduced-motion and reduced-transparency media rules are present; both reduced/default anchor branches are covered by the JavaScript regression test.

### Supplemental Gallery/captionless-video fixture

Scopen contains only two-item Galleries and captioned videos, so a temporary, uncommitted Project Detail page exercised the remaining variants with production layouts and styles:

- 1440 × 1000, full `1120px` Main Content width: Gallery 2 = `551px × 2`; Gallery 3 = about `361px × 3`; Gallery 4 = `551px × 2`; masonry = 3 columns. Captionless video was a `DIV`, had no `figcaption`, and its content/frame widths both measured `720px`.
- 820 × 1180, `776px` Main Content width: Gallery 2/3/4 all used `379px × 2`; masonry used 2 columns. Captionless video content/frame widths both measured `720px`.
- 390 × 844, `362px` Main Content width: Gallery 2/3/4 and masonry all collapsed to one `362px` column. Captionless video content/frame widths both measured `362px`.
- All three fixture viewports reported no horizontal overflow.

This fixture exposed and verified the `navigation: none` width fix, then was deleted. No fixture source or generated responsive image remains.

### Legacy shell and browser console

- `projects/areusafe.html` at 1440 × 1000 retained Bootstrap and jQuery, had no `[data-project-detail]` root, rendered its legacy `.container` shell, and had no horizontal overflow.
- Final browser error-log query returned an empty array.

## Final Repository State and Review Boundary

- No unrelated user work was discarded.
- `_site` is ignored and unstaged.
- No temporary fixture, screenshot, or generated image is tracked.
- Per the integration-task dispatch, no review subagent was created; the parent task owns the separate final independent code review.

Remaining risk is limited to the browser host not offering a reduced-motion emulation toggle. The active reduced-motion presentation could not be visually captured, so evidence combines live stylesheet-rule inspection with direct JavaScript branch coverage.
