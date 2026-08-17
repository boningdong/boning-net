# Showcase Banner Restoration Design

## Goal

Restore the Projects hero to the earlier engineering-blueprint artwork and improve the Projects, Artwork, and Experience hero images so they remain sharp and compositionally complete in the current 400-pixel-tall responsive hero.

## Source Assets

- Projects: `assets/img/showcase/projects-banner.jpg`, the original dark engineering-blueprint banner.
- Artwork: `assets/img/showcase/artwork-banner.jpg`, the existing forest/studio painting.
- Experience: `assets/img/showcase/experience-banner.jpg`, the existing seascape painting.

Each source is approximately 1920 by 252 pixels. The page heroes are at least 400 pixels tall, so the browser currently enlarges the files and discards substantial horizontal content to satisfy `object-fit: cover`.

## Considered Approaches

1. **Preserve and outpaint vertically — selected.** Keep the existing center strip, extend the scene above and below, and enhance detail at a larger output size. This preserves the site's visual identity while fixing both aspect ratio and clarity.
2. **Interpolation-only upscaling.** This is deterministic and perfectly preserves pixels, but it cannot restore missing vertical content and would retain the severe horizontal crop.
3. **Full visual regeneration.** This offers the most freedom and detail, but it risks changing recognizable subjects, brushwork, and the intended blueprint composition.

## Design

- Produce three landscape banner assets sized for the current hero and high-density desktop displays, targeting a 4.8:1 composition equivalent to the 1920 by 400 rendered hero.
- Treat each source as an edit target, not a loose style reference.
- Preserve the complete horizontal composition and recognizable central subjects.
- Extend only the top and bottom with scene-consistent content and edge continuity.
- Add no text, logos, watermarks, new focal subjects, or decorative UI elements.
- Keep the center region calm enough for the existing white title overlay.
- Save the enhanced files as versioned siblings in `assets/img/showcase/`; do not overwrite the source files.
- Update all three hero includes to reference the enhanced assets. Projects will switch from the temporary PCB photo back to the blueprint artwork.

## Validation

- Inspect all three final images directly for seams, unintended subject changes, artifacts, and text-like hallucinations.
- Confirm image dimensions and file formats.
- Build the Jekyll site.
- Inspect Projects, Artwork, and Experience heroes at desktop and mobile widths, verifying title readability, responsive crop, and lack of visible seams.

## Success Criteria

- Projects visibly uses the older dark engineering-blueprint aesthetic.
- Artwork and Experience retain their original scenes and visual character.
- All three banners look sharp in the 400-pixel hero and preserve substantially more of their original horizontal composition.
- Existing copy, overlays, and page behavior remain unchanged.
