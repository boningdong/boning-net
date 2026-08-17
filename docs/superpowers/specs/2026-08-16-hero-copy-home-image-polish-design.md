# Hero Copy and Home Image Polish Design

## Goal

Unify the Projects, Artwork, and Experiences hero language around one clear personal-portfolio pattern, improve the homepage hero background for high-density displays, and verify whether the apparent Artwork hero edge is an actual rendering defect.

## Approved Copy System

Every showcase title follows `Page name - personal statement`, using the same visible hyphen separator.

- Projects: `Projects - Ideas made tangible`
- Projects categories: `Hardware / Software / Experiments`
- Artwork: `Artwork - The world as I see it`
- Artwork categories: `Drawing / Painting / Mixed media`
- Experiences: `Experiences - The journey so far`
- Experiences categories: `Education / Career / Growth`

The Artwork categories describe broad practices rather than the currently uploaded media, so they remain accurate as sketching, watercolor, oil pastel, oil painting, and future work are added. The Experiences categories describe the page's actual education and work history while leaving room for personal development.

## Homepage Image

- Treat `assets/img/index/banner.jpg` as the edit target, not a loose style reference.
- Preserve the monochrome mountain landscape, exact composition, tonal hierarchy, angular illustrated texture, right-side hiker, and open sky behind the central title.
- Increase clarity and usable resolution for a full-viewport responsive hero without inventing new subjects or changing the site's restrained mood.
- Save the enhanced result as a versioned sibling and update the homepage include; do not overwrite the original.
- The final production asset should be at least 3840 pixels wide and keep the source's aspect ratio closely enough that the existing `object-fit: cover` crop remains visually equivalent.

## Artwork Edge Diagnosis

Browser inspection at 1440 by 900 confirms that the hero and image both end at exactly 400 CSS pixels. Neither element has a bottom border, margin, padding, or inline-image gap. The next pixel belongs directly to `.artwork-content`, whose intentionally light `var(--mist)` background creates the visible transition.

This is a normal section boundary rather than a stray white edge, so no CSS masking or overlap will be added. Final visual verification must confirm that the boundary remains a single clean transition with no blank gap.

## Validation

- Build the Jekyll site and run the existing Ruby and JavaScript checks.
- Confirm the generated homepage image dimensions and inspect it directly for artifacts, composition drift, added subjects, text, borders, or watermarks.
- Inspect the homepage and all three showcase heroes at desktop and mobile widths.
- Verify the approved title and category copy, consistent hyphen separators, readable wrapping, sharp homepage imagery, and clean Artwork section transition.

## Success Criteria

- All three showcase heroes read as one coherent naming system.
- Artwork wording remains accurate across current and future media.
- Experiences uses the plural navigation label and presents journey-oriented supporting copy.
- The homepage hero is visibly sharper on high-density screens while preserving its established composition and character.
- Artwork contains no unintended white border or layout gap.
