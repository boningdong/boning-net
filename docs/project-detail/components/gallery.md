# Gallery

## Purpose

Use `gallery` to present two or more related project images as one responsive collection.

## Syntax

```markdown
::: gallery
![Analog front end block diagram](/assets/img/projects/example/afe.jpg "Isolation, gain control, and differential conversion.")

![Controller block diagram](/assets/img/projects/example/controller.jpg "Controller, storage, input, and wireless control.")
:::
```

## Options

This directive accepts no options or attributes. Layout is derived from the number of items.

## Content Contract

The body contains only standalone Markdown image paragraphs separated by blank lines. Every image requires nonblank alt text and a nonblank destination. A Markdown image title is optional and becomes that item's caption. Inline attribute lists are not allowed.

## Behavior

Two items render as one row of two equal frames, three as one row of three equal frames, and four as a two-by-two grid. Two-to-four item layouts use equal 4:3 visual frames with cropped images. Five or more items use three-column CSS multi-column masonry and retain intrinsic image proportions. Below 900px, three-item and masonry layouts use at most two columns; at 640px and below, every gallery becomes one column. Masonry is CSS-only and uses no JavaScript measurement.

Caption labels use the nearest H1 or H2 and the shared per-heading media sequence. Items without titles omit their caption row but still advance that sequence.

## Generated Semantics

The gallery renders one collection container. Each peer item renders as a `figure` with an image media frame and an optional `figcaption`. Authored alt text stays on the `img`; authored title text is escaped into the caption.

## Validation

An empty gallery, a one-image gallery, prose or other non-image children, missing image alt/source values, inline attribute lists, unknown options, raw HTML, and nested directives stop the build.

```text
_projects/example.md:24: gallery requires at least two images; use a plain Markdown image instead
```

## Examples

A caption is optional for each item:

```markdown
::: gallery
![Top of the assembled board](/assets/img/projects/example/top.png "Primary controller and signal circuitry.")

![Bottom of the assembled board](/assets/img/projects/example/bottom.png)
:::
```

This is invalid because a gallery cannot contain explanatory prose:

```markdown
::: gallery
Two views of the board.

![Top of the board](/assets/img/projects/example/top.png)

![Bottom of the board](/assets/img/projects/example/bottom.png)
:::
```

## Related Components

Use a [Standalone Figure](figure.md) for one image. Use [Videos](videos.md) for YouTube embeds; video links are not valid Gallery children.
