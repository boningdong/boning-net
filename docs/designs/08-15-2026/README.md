# Site modernization design handoff

This directory is the durable design reference for the homepage and Projects list-page modernization approved on August 15, 2026.

## Status

- The homepage and Projects list-page design and tuning choices are finalized.
- The files in this directory describe a mock only.
- The production Jekyll pages have not been refactored to these designs yet.
- Future implementation should preserve the existing large-scale layout and content structure unless Boning explicitly requests otherwise.

## Shared source of truth

`shared-design-invariants.md` defines the design elements and parameters that must remain consistent across the homepage, Projects, Artwork, and Experiences pages.

## Homepage source of truth

1. `finalized-style.json` contains the exact option selections, numeric tuning values, and global-link settings chosen in the design lab.
2. `homepage-mock-v3.html` defines the visual behavior and maps the preset fields to CSS classes, custom properties, and component states.

Use the JSON and mock together. The JSON is not intended to be interpreted independently of the mock's controls and CSS mappings.

## Projects source of truth

1. `finalized-project-style.json` contains the final Projects tuning: Mist background, six visible tag controls, `400px` card height, `22px` footer padding, and `16px` description-to-tags gap.
2. `projects-list-mock-v4.html` defines the finalized Projects hierarchy, filter behavior, card system, responsive behavior, lighter content-page hero, and Mist continuity rules.

Use the Projects JSON and mock together. Values from `finalized-project-style.json` take precedence over the mock's hard-coded control defaults.

## Preset field semantics

- `activeOptions`: selected design modes. Values containing `:` match a control's `data-preset`; other values match the visible option label.
- `ranges`: control IDs mapped to their selected values. The mock's input handlers translate these values into CSS custom properties.
- `globalLinks`: identifies which surface and spacing properties are controlled globally instead of per component.
- `globalTint`: the selected global surface tint.
- `work`: the work category visible when the preset was exported.

## Implementation instruction for a future session

For the homepage, refactor the production page to match `homepage-mock-v3.html`, applying `finalized-style.json` as the final tuning state.

For the Projects list page, refactor the production page to match `projects-list-mock-v4.html`, applying `finalized-project-style.json` as the final tuning state.

Treat these files and `shared-design-invariants.md` as the approved design baseline; do not redesign the pages or materially change their layouts without explicit approval.

The mocks' design-lab controls are evaluation tooling and should not be shipped to production pages.
