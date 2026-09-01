# Experiences timeline modernization

## Status

Approved on August 16, 2026.

This document defines the production target for the Experiences page and the small shared hero adjustment required on the Projects and Artwork list pages. The design-lab controls remain mock-only and must not ship in production.

## Goal and boundary

Modernize `/resume.html` so it belongs to the same system as the homepage, Projects, and Artwork while presenting two content types only:

- Work Experience
- Education

The page is a portfolio timeline, not a printable résumé builder. Awards, skills, certifications, and a separate Career Path introduction are outside this iteration.

## Durable references

- `experiences-timeline-mock-v1.html` is the visual and interaction reference.
- `finalized-experiences-style.json` is the authoritative tuning state.
- `shared-design-invariants.md` remains authoritative for navigation, typography, glass material, and standard geometry.

When values conflict, the finalized Experiences preset takes precedence for page-specific fields and the shared invariants take precedence for global fields.

## Page architecture

The page uses the dependency-free `modern` layout and shared navigation/footer.

After the shared image-forward hero, one uninterrupted Mist content surface contains two semantic sections in this order:

1. Work Experience
2. Education

There is no introductory Career Path section and no material or border boundary between Work Experience and Education. The two headings retain `01 / 02` and `02 / 02` labels for scanability and accessibility.

The outer content rhythm uses `112px` on desktop and approximately `81px` on mobile. The internal Work-to-Education transition uses `80px` on desktop and approximately `58px` on mobile.

## Shared content-page hero

Projects, Artwork, and Experiences use the same `400px` minimum hero height at every viewport size. Their page-specific images and focal positions remain unchanged.

The existing content-page overlay, typography, navigation behavior, metadata treatment, and lower-right archive label remain shared. This is a global list-page correction: production implementation must replace the current `60svh` Projects and Artwork hero minimums with `400px` while adding the Experiences hero.

## Work timeline

Work entries come from `site.experiences`, remain filtered by `shown: true`, and are sorted by `start-date` in reverse chronological order.

### Collapsed entry geometry

- Every collapsed summary is exactly `122px` high.
- Timeline entry spacing is `20px`. This is a page-specific sequential rhythm, not a replacement for the shared `28px` card-grid gap.
- Card radius is the shared `26px`.
- The default surface tint is Ice and uses the shared glass edge, blur, highlight, and shadow treatment.
- Desktop summaries use a horizontal `brand | role | date | action` composition.

The brand area is not a nested logo card. It is an integrated left region with a restrained radial light treatment and a vertical gradient hairline separating it from the role copy. Reference widths are `132px` on desktop, `104px` on medium screens, and `76px` on small screens. Logos remain optically centered and keep their intrinsic aspect ratio.

### Timeline axis and nodes

The axis is a one-pixel blue-gray line with subtle fade at its first and last nodes. Nodes use the same steel hue, a Mist separation ring, and a fine outer edge.

Each node is positioned from the collapsed summary height, not from the total card height. Its center stays at `collapsed summary height / 2` before and after expansion. Expanded detail content grows only below the summary, so the node never recenters against the taller card.

### Detail interaction

Production uses a single-open inline accordion:

- All entries begin collapsed.
- Opening one entry closes any previously open entry.
- The fixed-height summary remains unchanged while detail content expands beneath it.
- The trigger exposes `aria-expanded`, has a visible keyboard focus state, and changes from Details to Close.
- Reduced-motion users receive an effectively immediate state change.

The mock's Detail Dock is an exploration aid only and must not ship unless separately approved.

## Education

Education follows Work Experience on the same Mist surface.

Desktop uses two equal-hierarchy cards; small screens stack them. The approved content is:

- UC Santa Barbara — Master's degree, Computer Engineering — 2021
- UC Santa Barbara — Bachelor's degree, Computer Engineering — 2016–2020 — GPA 3.95 — IEEE Student Branch

Education content should live in `_data/education.yml`. This is preferable to a collection because these entries have no detail pages or independent permalinks.

## Mock tuning and persistence

The mock retains the following exploration tools:

- Balanced, Recruiter, and Editorial starting points
- Inline accordion and Detail Dock
- Comfortable and Compact density
- Paired and Stacked education layout
- Ice, Pearl, and Smoke tint
- Hero height, collapsed height, radius, and timeline spacing ranges
- Save default, Reset, Import preset, and Export preset

The finalized production state is Balanced with Inline accordion, Comfortable density, Paired education cards, Ice tint, `400px` hero height, `122px` collapsed height, `26px` radius, and `20px` timeline spacing.

## Content and fallback behavior

- Preserve the substance of the existing Experience collection copy while correcting obvious spelling and grammar errors in visible labels.
- If an end date is absent, render `Now`.
- Every logo requires meaningful alt text; a missing logo must not leave a broken image control.
- JavaScript enhances the accordion only. All work and education text remains present in generated HTML.
- If JavaScript does not load, details remain readable rather than permanently hidden.

## Responsive and accessibility requirements

- Preserve the horizontal brand/content relationship on desktop and medium screens.
- On small screens, retain the vertical hairline and shrink the brand column rather than substituting a boxed logo.
- Keep the axis, nodes, cards, and triggers clear of horizontal overflow.
- Use semantic sections, headings, articles, buttons, and accessible expanded state.
- Honor `prefers-reduced-motion` and forced-color focus visibility.

## Verification

- Build Jekyll and run the modern-page regression suite.
- Add page-output assertions for the modern shell, five visible work entries, two education entries, shared section hierarchy, and absence of design-lab controls.
- Add JavaScript tests proving all entries start closed, one-open accordion behavior, accurate `aria-expanded`, and safe handling of missing controls.
- Verify Projects, Artwork, and Experiences all compute to a `400px` hero minimum.
- Inspect desktop, medium, and small layouts for equal collapsed heights, exact node alignment before and after expansion, readable details, and no horizontal overflow.
- Confirm all images and fonts load and the browser console contains no errors.
