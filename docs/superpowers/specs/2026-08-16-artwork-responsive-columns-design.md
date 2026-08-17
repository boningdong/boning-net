# Artwork Responsive Columns Design

## Goal

Make The Collection use the same responsive column progression as the Projects archive so artwork cards remain comfortably sized on narrow phones.

## Approved behavior

- Above `850px`, The Collection remains a three-column masonry layout.
- From `641px` through `850px`, The Collection remains a two-column masonry layout.
- At `640px` and below, The Collection becomes a one-column masonry layout, matching Projects.
- The existing desktop `28px` gap and mobile `21px` gap remain unchanged.
- Artwork images continue to preserve their intrinsic aspect ratios and are never cropped.
- Highlights, filters, viewer behavior, content ordering, and collection data remain unchanged.

## Implementation boundary

Add the one-column collection override inside Artwork's existing `max-width: 640px` media query. Do not introduce JavaScript or a new shared responsive abstraction for this focused change.

## Verification

- Add a generated-CSS regression contract before changing production SCSS.
- Verify the contract fails before implementation and passes afterward.
- Run the existing Ruby and JavaScript test suites, Jekyll build, and `git diff --check`.
- In a mobile browser viewport at or below `640px`, verify one collection column, intrinsic image ratios, no page-level horizontal overflow, and no console errors.
- In a viewport between `641px` and `850px`, verify two collection columns remain.
