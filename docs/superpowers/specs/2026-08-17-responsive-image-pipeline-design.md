# Responsive Image Pipeline Design

## Goal

Replace manually maintained, low-resolution project and artwork thumbnails with a build-time responsive image pipeline that preserves visual quality while allowing browsers to download an appropriately sized asset for each rendered slot.

The change must improve thumbnail clarity on high-density displays without introducing a runtime image service or forcing visitors to download full-resolution originals for card views.

## Scope

The pipeline covers thumbnail and card images in:

- the homepage Projects and Artwork panels;
- Projects Highlights and Archive;
- Artwork Highlights and Collection.

Artwork viewer images continue to load their full-resolution `location` asset on demand. Hero images, project-detail body images, experience logos, the homepage portrait, and other site imagery are outside this change.

## Architecture

The system has three boundaries:

1. **Content:** Project and artwork frontmatter identifies one canonical high-resolution `cover` source. Artwork keeps `location` as the full-resolution viewer source.
2. **Build:** Jekyll Picture Tag selects a named preset, invokes libvips, and writes responsive WebP and original-format derivatives into the generated site.
3. **Presentation:** Shared Liquid image markup supplies `picture`, `srcset`, `sizes`, intrinsic dimensions, alternative text, and loading attributes. The browser selects the appropriate candidate using the rendered slot width and device pixel ratio.

libvips runs only during local or GitHub Actions builds. Generated derivatives live under `_site/generated/` and are not committed to Git or served by a runtime application.

## Dependencies and Deployment

Add `jekyll_picture_tag` 2.x to the `jekyll_plugins` Bundler group. Developers install libvips once on macOS with Homebrew. Both the production deployment workflow and pull-request preview workflow install `libvips-tools` before Jekyll runs.

The existing custom GitHub Actions deployment remains responsible for producing and uploading `_site`; no hosting architecture changes are required.

## Source Image Policy

The existing `cover` field remains the public content interface but changes meaning from “prebuilt thumbnail” to “canonical high-resolution card source.”

For each project, choose the source in this order:

1. the exact high-resolution image from which the legacy cover was derived;
2. the closest high-resolution image already used in that project’s detail page;
3. a one-time enhanced version of the legacy cover when no suitable high-resolution source exists.

One-time enhancement is source preparation, not part of every Jekyll build. Photographic covers use AI super-resolution when enhancement is required. Covers containing logos, text, UI, or technical graphics use non-generative enlargement or reconstruction from existing high-resolution project assets so generated characters and technical details are not silently altered. Enhanced source files are committed as canonical assets and reviewed visually before use.

Artwork `cover` values point to the same high-resolution file as `location` unless a future artwork requires separate art direction. Keeping both fields preserves a uniform collection schema and permits an intentionally different high-resolution cover later.

## Responsive Presets

Centralize image behavior in `_data/picture.yml`. Presets correspond to materially different rendered slots rather than individual pages:

- large featured and homepage cards generate `[480, 800, 1200, 1600]` pixel-wide candidates;
- standard grid cards generate `[320, 480, 640, 960, 1280]` pixel-wide candidates;
- the fixed-height artwork rail generates `[240, 360, 480, 720, 960]` pixel-wide candidates.

All presets output WebP followed by the original JPEG or PNG format as fallback. WebP uses quality 82, generated JPEG uses quality 85, PNG remains PNG, and all generated derivatives strip metadata. The first release avoids AVIF to keep local and CI dependencies predictable.

Each preset declares `sizes` values aligned with the existing 640px and 850px responsive layout breakpoints. Width candidates cover both normal and high-density displays without deliberately upscaling undersized sources during the build.

## Markup and Loading Behavior

Replace direct card-level `<img src>` markup with `_includes/components/responsive-image.html`. Callers provide the source, preset, alt text, and loading semantics; callers do not assemble `srcset` strings.

Card images use `loading="lazy"` and `decoding="async"`. Existing accessibility behavior remains intact:

- real cards keep descriptive alternative text;
- duplicated artwork rail cards remain hidden from assistive technology and use empty alternative text;
- the Artwork viewer continues to receive its full-resolution URL through `data-full` and assigns it only when opened.

Duplicate artwork rail cards reuse identical generated URLs, allowing the browser cache to avoid duplicate transfers.

## Failure Handling

Missing canonical sources, unsupported formats, or image-generation errors fail the Jekyll build rather than silently emitting broken markup. Source selection is audited before template migration so every collection entry resolves to an existing file.

Jekyll Picture Tag does not invent missing resolution. Any source that remains too small for its intended slot is enhanced once before it becomes the canonical `cover` source. AI-enhanced photographs and reconstructed graphic covers receive visual review because automated enlargement can introduce artifacts.

## Resource Cleanup

After all templates have migrated and the production build proves that no references remain, remove:

- obsolete files in `assets/img/artwork/covers/`;
- low-resolution project cover files replaced by canonical high-resolution or enhanced sources;
- temporary files created during source matching or enhancement.

Only files confirmed unreferenced by source, generated output, and content searches are deleted. The deleted committed assets remain recoverable from Git history.

Add `.superpowers/` to `.gitignore` so visual brainstorming artifacts do not enter commits.

## Verification

Verification covers the complete image path:

1. Run a clean production Jekyll build with libvips available.
2. Confirm every scoped card emits responsive markup with WebP and original-format candidates, a nonempty `srcset`, an appropriate `sizes` value, and intrinsic dimensions.
3. Confirm all generated candidate files exist and no candidate exceeds the canonical source dimensions unless it is an intentionally enhanced source.
4. Confirm source searches find no references to deleted legacy covers.
5. Inspect the homepage, Projects, and Artwork pages at desktop, tablet, and mobile widths, including high-density emulation where available.
6. Open Artwork viewer items and verify that the full-resolution `location` still loads and that duplicate rail cards remain inaccessible to assistive technology.
7. Run repository formatting and whitespace checks, including `git diff --check`.

## Acceptance Criteria

- Project and artwork card images appear sharp on normal and high-density displays when an adequate source exists.
- Mobile and smaller card slots download smaller generated candidates rather than full-resolution originals.
- The browser receives WebP and original-format fallbacks without AVIF.
- The full-size Artwork viewer behavior is unchanged.
- Local, pull-request, and production builds share the same libvips-backed pipeline.
- Obsolete thumbnails are removed only after all references and rendered output have been verified.
