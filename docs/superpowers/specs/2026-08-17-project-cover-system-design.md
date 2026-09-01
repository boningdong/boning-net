# Project Cover System Design

## Goal

Make project covers feel consistent and refined across the homepage and Projects page, replace the unsuitable Scopen cover with AI-expanded alternatives, and organize every project asset beneath its project-specific directory.

## Scope

This change covers the homepage project cards, Projects page highlight cards, Scopen cover artwork, project image paths, responsive image generation, tests, and cleanup of confirmed-unused project assets. Artwork page cards and project detail page layout are outside the visual redesign, although project detail image paths will be updated during migration.

## Cover Overlay System

Homepage project cards and Projects highlight cards will share the same overlay model:

- The shade belongs to the card, not the metadata container, so its geometry is independent of title length and image composition.
- The gradient spans the card but remains transparent through the upper 56%, transitions gradually, and ends at 0.56-alpha blue-black rather than opaque black.
- Metadata containers have no background of their own.
- Primary and secondary cards retain a deliberate type hierarchy, but font sizes and padding are fixed by card class and responsive breakpoint rather than image content.
- Mobile typography is capped to prevent long titles from dominating the image.
- Existing hover zoom and responsive `<picture>` behavior remain.

## Scopen Cover Variants

Three new landscape covers will be created using the existing Scopen poster, product render, and blueprint image as references:

1. `cover-logo`: preserves the recognizable Scopen logo and pen device, expands the canvas, and scales both down into a centered safe area.
2. `cover-product`: presents the pen device as a polished futuristic engineering product without embedded text.
3. `cover-blueprint`: combines the device with the blue technical drawing language of the existing blueprint artwork.

Every variant must support both wide and moderately tall card crops, retain its focal subject across desktop and mobile breakpoints, avoid website metadata in the lower-left text-safe region, and contain no watermark. The strongest result after browser QA becomes `cover`, while the other two remain available with descriptive filenames.

## Asset Layout

Each `_projects/<slug>.md` file owns a matching directory:

```text
assets/img/projects/<slug>/
```

Rules:

- Every project cover lives inside its matching directory and uses the basename `cover` with its native extension.
- Existing detail images move into the matching directory. Descriptive basenames are preserved where useful to reduce unnecessary renaming.
- Existing `ar_domino/` and `chatbot/` assets are folded into the same convention.
- `covers-hd/` is removed after its used files move to their owning project directories.
- Files confirmed to have no repository reference are removed rather than migrated.
- All frontmatter and inline Markdown/HTML references are updated atomically.

The twelve directory slugs are `ar_domino`, `areusafe`, `chatbot`, `drsstc`, `ecosystem`, `kossel_printer`, `msp430_dev`, `nes_emulator`, `scopen`, `simplewatch`, `smartlamp`, and `spl_visualization`.

## Verification

Automated checks will verify:

- every project cover is under the directory matching its project slug;
- no project asset remains directly under `assets/img/projects/` or in `covers-hd/`;
- all project image references resolve to existing files;
- cover sources meet the existing minimum width requirement;
- generated pages retain responsive WebP and fallback sources;
- the revised overlay CSS is present without the old opaque gradient rules;
- existing Ruby and JavaScript suites remain green.

Browser QA will cover homepage and Projects highlights at desktop and mobile widths, confirm responsive source selection, evaluate the three Scopen variants in actual card crops, and verify that text contrast remains readable without a heavy black footer.

## Cleanup and Git State

Confirmed-unused project images and superseded Scopen cover experiments will be deleted after references are audited. All work, including this spec and its implementation plan, remains unstaged in the current working tree. No commit will be created.
