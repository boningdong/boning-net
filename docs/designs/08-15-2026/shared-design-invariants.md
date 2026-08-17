# Shared design invariants

This file is the cross-page design contract for the homepage and the Projects, Artwork, Album, Notes, and Experiences pages.

Use it together with `finalized-main-style.json` and `homepage-mock-v3.html`. When values disagree, the finalized JSON has precedence over hard-coded control defaults in the mock.

## Design intent

The site should feel quiet, precise, tactile, and personal. Photography and artwork provide the visual impact; interface elements support them with restrained glass, soft mist surfaces, and disciplined typography.

Modernization must not substantially restructure the existing content or compete with the hero artwork. Consistency comes from shared geometry, spacing, material behavior, and type roles rather than making every page use the same composition.

## Hard invariants

These values remain consistent across pages unless Boning explicitly approves a new global value.

| System | Invariant | Value or rule |
| --- | --- | --- |
| Geometry | Card radius | `26px` |
| Geometry | Navigation radius | Fully rounded pill, `999px` |
| Spacing | Desktop card gap | `28px` |
| Spacing | Mobile card gap | `21px`, derived as `28px × 0.75` |
| Spacing | Standard section space | `112px` above and below a distinct section |
| Spacing | Mobile section space | Approximately `81px`, derived as `112px × 0.72` |
| Motion | Card hover lift | `5px` |
| Shadow | Shared shadow strength | `10%` alpha |
| Type | Display face | Instrument Sans |
| Type | Body face | Source Sans 3 |
| Type | Utility face | IBM Plex Mono |
| Type | Major section heading | Weight `650`, tight tracking around `-0.055em` |
| Type | Navigation labels | `13px`, weight `560` |
| Type | Site name | Same `13px` scale as navigation, weight `650` |

Spacing is relational rather than mechanically identical. Cards at the same hierarchy use the shared gap. Dense controls such as filter pills use their own smaller gap and must not inherit the card gap.

## Navigation contract

- The site name is always written as `Boning Dong`; it does not collapse to `BD` at any viewport size.
- `Boning Dong` links to the homepage, so a separate Home item is unnecessary.
- Desktop and medium-width navigation remain right aligned and retain the same label size and generous spacing.
- Small screens replace navigation links with one Menu control on the right. The site name remains on the left.
- The menu panel is a second glass island, not a different component language. It inherits the navigation tint, opacity, blur, highlight, shadow, ink color, and corner logic.
- At the top of a hero, navigation has no glass surface and uses opaque light text with a conventional dark text shadow. It must not use blend modes.
- After scrolling, the glass surface appears and the text switches to the selected surface-appropriate ink color.
- Final navigation values are: height `46px`, surface opacity `48%`, blur `8px`, inner side padding `24px`, edge highlight `35%`, and text opacity `95%`.
- The finalized navigation tint is Pearl with black ink. Global tint is not linked to navigation in the finalized preset.

## Surface and card contract

- Glass is a material system, not decoration: every glass card needs a translucent fill, a fine light edge, a subtle inset highlight, a soft external shadow, and consistent blur behavior.
- Shared card geometry is radius `26px`, gap `28px`, hover lift `5px`, and shadow alpha `10%`.
- Split Card image and footer form one card. The image remains clipped by the card's upper corners; the footer inherits the lower corners.
- Split Card footer reference values are `58%` white surface opacity, `22px` blur, and an effective minimum padding of `22px`.
- The image/footer divider is a restrained hairline with a short centered gradient highlight. It must not read as a heavy rule.
- Project imagery does not zoom in Split Card mode. Hover motion belongs to the entire card.
- Edge highlights should be reduced on darker tints rather than compensated with stronger shadows.
- Titles live inside the card system. Overlay captions use shadow or gradient for contrast; Split Cards place titles inside the footer.

## Page and section rhythm

Distinct sections use `112px` of vertical space above and below their content. The next background boundary must begin after the preceding section's bottom space; it must never touch the final row of cards.

### Mist continuity

Mist is the continuous-gallery mode for list pages.

- Highlights and the complete gallery share one uninterrupted Mist background.
- Remove the intermediate background boundary and border between them.
- Keep separate semantic headings and HTML sections for accessibility, filtering, and responsive behavior.
- Replace two independent `112px` section edges with one internal transition of `80px` between the Highlights cards and the Projects heading.
- On mobile, use approximately `58px`, derived as `80px × 0.72`.
- The page still keeps the standard outer section space after the hero and before the footer.

Paper may use the same content hierarchy with a neutral background. Sectioned intentionally preserves separate background bands and the full `112px` edge spacing.

## Typography hierarchy

- Hero titles act as a texture over the image, not as the dominant object. Homepage reference: `32px`, weight `480`.
- Page hero titles should remain close to the homepage scale and weight unless longer copy requires a responsive reduction.
- Section headings use the display face, weight `650`, tight tracking, and a responsive size around `34–58px`.
- Card titles use the display face around weight `580–620`; size may vary with card hierarchy.
- Body copy uses Source Sans 3 with comfortable line height and muted blue-gray ink.
- Utility labels, dates, tags, and metadata use IBM Plex Mono, uppercase only when the label is short.
- A delimiter is chosen for a semantic role, not as a general decoration. Avoid repeating the same separator in both hero title and subtitle.

## Content-page hero contract

Projects, Artwork, and Experiences share an image-forward hero system that is independent of the homepage hero treatment.

- Use a shared `400px` minimum hero height at every viewport size.
- Do not copy the homepage's stronger cinematic overlay; content-page imagery should remain clearly visible.
- Use a restrained horizontal shade from `34%` on the text-supporting side to `8%` on the open side.
- Use a second vertical shade of `4%` at the top, `2%` through the middle, and `34%` at the bottom for edge legibility.
- Preserve title readability with a focused text shadow rather than darkening the entire image.
- Individual pages may select different images and focal positions, but overlay strength, title scale, metadata treatment, and navigation behavior remain shared.

## Responsive rules

- Responsive layouts may change column count and card aspect ratio, but not material, radius, type roles, or interaction logic.
- Medium screens retain desktop navigation typography and spacing while space remains sufficient.
- Mobile card gaps scale to `21px`; filter-pill gaps remain approximately `9px`.
- Mobile section space scales to approximately `72%` of its desktop counterpart.
- Menus, filters, and tuning controls must remain keyboard accessible and have visible focus states.
- Honor `prefers-reduced-motion` by suppressing nonessential transitions and smooth scrolling.

## Page-level freedoms

The following may vary when required by content:

- Grid structure: bento, regular grid, or editorial image rhythm.
- Card height and image aspect ratio.
- Number of featured items.
- Page-specific metadata and filters.
- Background mode: Paper, Mist, or Sectioned.
- Caption mode when the content benefits from imagery-first presentation.

These variations must consume the shared tokens above rather than redefining near-duplicate radii, gaps, shadows, typefaces, or glass recipes.

## Current Projects decisions

- Hero: `Projects - Ideas made tangible`.
- First group: `Highlights`.
- Complete collection heading: `Projects`.
- Filtering is single-tag and OR-like at the collection level: one selected tag shows projects containing that tag. `All` clears the constraint.
- All filters, including More/Less, use the same pill component.
- Large screens can expose three to six filter controls before More; smaller screens expose fewer without changing component style.
- Gallery cards use Split Card with a default height of `400px`, footer padding `22px`, and description-to-tags gap `16px`.
- Mist is the recommended Projects background and uses the continuity rule above.

## Current Artwork decisions

- Hero: `Artwork — Studies in light & character`, with `Graphite / Charcoal / Watercolor` metadata and the shared content-page overlay treatment.
- Content hierarchy: `Highlights` followed by `The Collection`, with no explanatory paragraph beneath either section heading.
- Highlights use a single horizontal rail at `330px` image height; image width is derived from each work's intrinsic aspect ratio and images are never cropped.
- The Highlights rail drifts automatically, pauses on hover or keyboard focus, supports direct horizontal scrolling, and becomes manual when reduced motion is requested.
- The Collection uses three aspect-ratio-preserving masonry columns by default, with the shared `28px` desktop and `21px` mobile gaps.
- Default captions use the Museum label treatment below the image rather than covering the artwork.
- Medium filters are visible by default and offer All, Pencil, Charcoal, and Watercolor.
- The default artwork viewer is a glass dialog that displays the full-resolution image without cropping.
- Mist is the approved continuous background across Highlights and The Collection, using the shared `80px` internal transition.

## Current Experiences decisions

- Hero: `Experience / Education`, with `Embedded systems / Hardware / Product craft` metadata and the shared `400px` content-page hero height.
- Content hierarchy: Work Experience followed by Education on one continuous Mist surface; there is no Career Path introduction.
- Work entries use equal `122px` collapsed summaries and a `20px` sequential timeline gap.
- Each work card integrates a left brand region separated by a vertical gradient hairline; logos do not sit inside nested boxes.
- Timeline nodes use the shared steel palette and remain centered on the collapsed summary when details expand.
- Production uses a single-open inline accordion. Detail Dock and Tune controls remain mock-only.
- Education uses paired UCSB cards on desktop and a stacked layout on small screens.

## Checklist for Artwork and Experiences

Before presenting either page, verify:

- Navigation behavior and values match this contract.
- Radius, desktop/mobile card gaps, lift, and shadow match shared values.
- Section boundaries include their required bottom space.
- Glass cards use the shared material recipe rather than a new approximation.
- Typefaces and type roles match the hierarchy.
- Mobile behavior preserves design language rather than substituting generic controls.
- Any intentional exception is named, justified by the content, and presented for approval.
