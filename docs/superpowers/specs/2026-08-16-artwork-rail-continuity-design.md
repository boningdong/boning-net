# Artwork Rail Continuity Design

**Status:** Approved on August 16, 2026; edge treatment corrected after browser review

## Goal

Refine the modern Artwork page so Highlights and The Collection read as one continuous Mist gallery, and make the Highlights rail feel like a controlled automatic presentation rather than a conventional horizontal scroller.

## Scope

This is a focused refinement of the approved Artwork modernization. It does not change artwork data, card geometry, image ratios, section hierarchy, filters, viewer behavior, typography, or the approved mock and preset files.

## Mist continuity

- Artwork must use the same continuous Mist background recipe as Projects: the same radial highlight position, opacity, and fade extent.
- Highlights and The Collection remain separate semantic sections inside one uninterrupted page background.
- No border, band, scrollbar, or other horizontal rule may visually divide the two sections.
- The existing `80px` desktop and `57.6px` mobile internal transition spacing remains unchanged.

## Rail interaction

### Default motion mode

- The rail drifts automatically using the existing seamless duplicated track.
- The viewport uses hidden horizontal overflow, so mouse wheels, trackpads, touch gestures, scrollbars, and keyboard arrow keys cannot manually move the rail.
- Hover and keyboard focus continue to pause automatic drift.
- No visible scrollbar is rendered in any browser.

### Reduced-motion mode

- Detect `prefers-reduced-motion: reduce` with the existing `matchMedia` motion policy and a matching CSS media query.
- Automatic drift is disabled while reduced motion is active.
- Only in this mode, horizontal overflow becomes manually scrollable so every Highlight remains reachable by touch, trackpad, mouse, and keyboard.
- The manual scrollbar remains visually hidden; scrolling is communicated by the clipped rail composition and accessible named region rather than a scrollbar.
- A live change to the operating-system preference updates both drift and overflow behavior without reloading the page.

## Edge treatment

- Wrap the scroll viewport in a noninteractive edge-treatment container.
- Render left and right overlay fades outside the scrolling element so they remain fixed while the track moves.
- Each fade is materially wider than the current `24px` mask, with a continuous transition from Mist to transparent matching the first approved mock treatment.
- Do not use `blur` or `backdrop-filter`; the artwork must fade into the background color without exposing a rectangular filter region.
- Edge overlays use `pointer-events: none` and must not obstruct viewer triggers, rail focus, or reduced-motion manual scrolling.
- Mobile uses a narrower proportional fade than desktop while preserving the same continuous color transition.

## Structure

- `_includes/pages/artwork/highlights.html` adds one rail-shell wrapper around the existing accessible rail region.
- `_sass/pages/_artwork.scss` owns the Projects-matched Mist recipe, rail overflow policy, hidden-scrollbar rules, unblurred edge fades, and responsive/reduced-motion behavior.
- `assets/js/pages/artwork.js` keeps its existing automatic-motion detection and drift implementation; JavaScript changes are only required if browser verification reveals that default manual input can still move an `overflow: hidden` rail.

## Verification

- Add a failing generated-page contract for the rail-shell structure before changing production markup.
- Build with Jekyll and run all Ruby and JavaScript tests.
- Run `git diff --check`.
- At desktop and mobile viewports, verify one continuous Mist surface, no visible scrollbar or hard section divider, wider fixed edge fades, automatic drift, hover/focus pause, and no page-level horizontal overflow.
- In default motion mode, verify wheel, trackpad-equivalent, keyboard, and touch-equivalent input cannot manually move the rail.
- Under emulated reduced motion, verify automatic drift stops while manual horizontal input works and the scrollbar remains hidden.
- Check that all artwork images load, retain intrinsic aspect ratio, and produce no console errors.
