# Callout

## Purpose

Use `callout` to emphasize one lead value or phrase with supporting prose, lists, and links. It is semantically general and is not restricted to metrics.

## Syntax

```markdown
::: callout
**2.45 × 0.73 in**

The six-layer board is narrower than a stick of gum.
:::
```

## Options

This directive accepts no options or attributes.

## Content Contract

The first visible child must be one paragraph containing only a strong (`**...**`) or emphasis (`*...*`) span. The emphasized span may contain supported inline Markdown. Remaining children may be paragraphs, ordered or unordered lists, and safe links with supported inline Markdown. Headings, media, block code, raw HTML, inline attribute lists, and nested directives are not allowed.

## Behavior

The emphasized first paragraph receives display treatment in a narrow left column while the remaining Markdown forms a wider supporting column. The component is deliberately unboxed so it reads as an editorial interruption rather than another media card. At 640px and below the two columns stack and the vertical spacing tightens. It requires no JavaScript.

## Generated Semantics

The directive renders an `aside` containing the validated Kramdown HTML. Strong or emphasis semantics from the lead remain in the output, and lists and links keep their ordinary semantic elements.

## Validation

The build fails for an empty body, a plain or mixed first paragraph, a disallowed child, unsafe link, raw HTML, inline attribute list, nested directive, or unknown option.

```text
_projects/example.md:20: callout must begin with one paragraph containing only a strong or emphasis lead
```

## Examples

An emphasized label, link, and list are valid:

```markdown
::: callout
*Field note*

Read the [measurement protocol](https://example.com/protocol).

- Isolated acquisition
- Wireless control
:::
```

This lead is invalid because un-emphasized text shares the first paragraph:

```markdown
::: callout
**Key dimension** is compact.

Supporting copy.
:::
```

## Related Components

Use [Narrative Title](narrative-title.md) only for a chapter's display title. Use [Featured Link](featured-link.md) when the entire component should be one action.
