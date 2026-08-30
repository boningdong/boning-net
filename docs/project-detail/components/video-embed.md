# Video Embed

## Purpose

Use `video-embed` to turn one or more authored YouTube links into responsive, privacy-enhanced embeds.

## Syntax

```markdown
::: video-embed
[Hardware demonstration](https://www.youtube.com/watch?v=4xJvWEb1Kwo "Physical prototype demonstration")

[Software demonstration](https://youtu.be/fFWyjB_XNrE "Desktop interface demonstration")
:::
```

## Options

This directive accepts no options or attributes.

## Content Contract

The body contains only standalone Markdown link paragraphs separated by blank lines. Link text is required and becomes the iframe's accessible title. Inline formatting in link text is reduced to plain accessible title text. The optional Markdown link title becomes the visible caption; write it as a short display title without terminal sentence punctuation. A whitespace-only title is treated as absent.

Accepted destinations are valid `http` or `https` YouTube watch URLs, `youtu.be` share URLs, and YouTube or `youtube-nocookie.com` embed URLs containing exactly one valid 11-character video ID in the supported path/query position.

## Behavior

Every accepted destination is normalized to `https://www.youtube-nocookie.com/embed/{video-id}`. All items render vertically at the full width of the Main Content column, regardless of item count or viewport width. Each embed keeps a 16:9 frame and loads lazily.

Caption labels use the nearest H1 or H2 and the shared per-heading media sequence. A video without a link title omits its visible caption but still advances that sequence.

## Generated Semantics

The collection renders as a `ul` with one `li` per video. A captioned item contains a `figure`, responsive iframe frame, and `figcaption`; a captionless item uses a neutral `div` container instead of `figure`. The iframe receives the authored link text as `title`, safe media permissions, strict-origin referrer policy, lazy loading, and fullscreen support.

## Validation

An empty body, prose or non-link children, blank link text, an unsupported host, malformed or ambiguous video URL, unsafe URL, inline attribute list, unknown option, raw HTML, or nested directive stops the build.

```text
_projects/example.md:28: video-embed supports only valid YouTube video URLs
```

## Examples

A single captionless video is valid:

```markdown
::: video-embed
[Project overview](https://youtu.be/ieGTWUUsJ_8)
:::
```

This unsupported host is invalid even if it contains a YouTube-looking ID:

```markdown
::: video-embed
[Project overview](https://videos.example.com/ieGTWUUsJ_8)
:::
```

## Related Components

Use [Featured Link](featured-link.md) to link to a video without embedding it. Use a [Standalone Figure](figure.md) for each authored image.
