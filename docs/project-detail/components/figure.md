# Standalone Figure

## Purpose

Use a Standalone Figure for one project image with required alternative text and an optional visible caption.

## Syntax

Write an ordinary Markdown image as the only visible content in its paragraph. The optional Markdown image title becomes the caption.

```markdown
![Exploded diagram of all six PCB layers](/assets/img/projects/example/pcb-layers.png "Six layers connect acquisition, storage, and wireless control")
```

## Options

Standalone Figure is not a directive and accepts no directive options. Its author inputs are the Markdown image destination, alt text, and optional title.

## Content Contract

The image must be the only visible content in its paragraph. Nonblank alt text and a nonblank image destination are required. Image destinations must be relative or use `http` or `https`. The title is optional. When present, write it as a short display title without terminal sentence punctuation. An image embedded in a prose sentence remains an ordinary inline image. Image-only paragraphs inside blockquotes and list items are also recognized as Standalone Figures.

## Behavior

A titled image fills the Main Content column with the shared glass media surface and a caption row below it. The generated caption label sits at the left edge while the authored description aligns to the right edge. The label uses the nearest preceding H1 or H2 plus a two-digit sequence, such as `HARDWARE / 01` or `INDUSTRIAL DESIGN / 01`. An H3 does not reset the sequence. Media items advance the shared sequence even when they have no visible caption. Captions stack into one left-aligned column on mobile; images keep their intrinsic proportions at all widths.

## Generated Semantics

A titled image renders as `figure` containing the image surface and `figcaption`. A title-less image renders only the media surface and `img`, without empty `figure` or `figcaption` markup. Kramdown named and numeric entities in the authored source, alt text, and title are decoded exactly once into block data; the Liquid include then escapes each value exactly once at its HTML boundary. Authored alt text remains the image's `alt` value. Generated labels are presentation metadata and never become headings or navigation entries.

## Validation

The build fails when a recognized Standalone Figure has blank alt text, a blank image destination, or an unsafe image destination.

```text
_projects/example.md:18: figure alt text is required
```

Do not write `::: figure`; no public Figure directive exists.

## Examples

A captionless figure is valid:

```markdown
![Bottom side of the assembled circuit board](/assets/img/projects/example/board-bottom.png)
```

This image stays inline because the paragraph also contains prose:

```markdown
The ![status icon](/assets/img/projects/example/status.png) turns green when capture begins.
```

Reference-style image syntax is also supported when it resolves to an image-only paragraph:

```markdown
![Assembled board][board]

[board]: /assets/img/projects/example/board.png "Top side of the assembled board"
```

## Related Components

Author multiple peer images as separate Standalone Figure paragraphs. Video captions use the same label sequence through [Video Embed](video-embed.md).
