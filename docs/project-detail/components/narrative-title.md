# Narrative Title

## Purpose

Use `narrative-title` to give a chapter an editorial display title while keeping its H1 as the chapter identity, anchor, and navigation label.

## Syntax

Place the directive as the first visible block after an H1:

```markdown
# Hardware

::: narrative-title
Two systems, one very narrow board.
:::
```

## Options

This directive accepts no options or attributes.

## Content Contract

The body must be exactly one inline-Markdown paragraph. Text, emphasis, strong text, code spans, safe links, entities, and line breaks are supported. Headings, lists, images, block code, multiple paragraphs, footnotes that expand into blocks, raw HTML, and nested directives are not supported.

Blank lines and HTML comments between the H1 and directive do not break placement. Any visible content before the directive does.

## Behavior

The H1 remains the chapter title used for its anchor and navigation. When the directive is present, the H1 receives the compact chapter-label presentation and the Narrative Title becomes the large display copy. On mobile, the display title uses the component's smaller fixed type size. Without this directive, the H1 retains its normal chapter-heading presentation.

## Generated Semantics

The existing H1 remains the only heading. The directive renders a marked container with one paragraph; it does not create another heading or another navigation entry.

## Validation

The build fails if the directive is not the first visible block after an H1, contains anything other than one supported paragraph, uses an unknown option, contains an inline attribute list, or contains an unsafe link.

```text
_projects/example.md:12: narrative-title must be the first visible block after an H1
```

## Examples

Inline emphasis and a safe link are valid:

```markdown
# Software

::: narrative-title
A **focused interface** for [live acquisition](https://example.com/acquisition).
:::
```

This is invalid because prose appears first:

```markdown
# Software

Chapter introduction.

::: narrative-title
This is now too late.
:::
```

## Related Components

Use ordinary [H1 chapters](../README.md#h1-chapters) when no separate display title is needed. Use a [Callout](callout.md) for emphasized information within a chapter.
