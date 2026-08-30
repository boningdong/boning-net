# Featured Link

## Purpose

Use `featured-link` for one visually distinct text action represented by a normal Markdown destination and accessible label. It is especially suited to the Project Intro.

## Syntax

```markdown
::: featured-link
[Watch the presentation](https://youtu.be/ieGTWUUsJ_8)
:::
```

## Options

This directive accepts no options or attributes.

## Content Contract

The body contains exactly one standalone Markdown link paragraph. The destination must be nonblank and safe. The label may contain supported inline Markdown such as emphasis, strong text, or a code span. A Markdown link title is accepted but is not rendered by this component. XML/HTML comments are not discarded: because the body contract is exactly one standalone link, a comment makes the body invalid. Extra prose, multiple links, images, headings, lists, raw HTML, inline attribute lists, and nested directives are also not allowed.

## Behavior

The link renders as a compact uppercase utility label with a fitted underline and a trailing arrow. Inside a featured Project Intro it occupies only its intrinsic width rather than stretching across the content column. The arrow moves slightly on hover, and spacing tightens at 640px and below. The compiler preserves the authored destination and does not add `target="_blank"` or otherwise force a new window.

## Generated Semantics

The component renders one anchor containing the rendered inline label and a decorative arrow hidden from assistive technology. It does not wrap the action in an additional interactive element.

## Validation

The build fails for an empty body, more or fewer than one standalone link, an XML/HTML comment, blank or unsafe destination, disallowed child content, inline attribute list, unknown option, raw HTML, or nested directive.

```text
_projects/example.md:16: featured-link must contain exactly one standalone Markdown link
```

## Examples

Inline emphasis in the label is valid:

```markdown
::: featured-link
[Watch *the complete presentation*](https://example.com/presentation)
:::
```

This is invalid because the paragraph contains text outside the link:

```markdown
::: featured-link
Continue to [the presentation](https://example.com/presentation).
:::
```

## Related Components

Use [Video Embed](video-embed.md) when a YouTube destination should render as an embed. Use [Callout](callout.md) when supporting prose or a list belongs inside the component.
