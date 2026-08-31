# Project Detail Migration Reference

All project documents now use the [Project Detail authoring contract](README.md). This completed-migration reference preserves the conversion checklist and source mappings for reviewing historical changes or adapting older content into the current contract.

## 1. Inventory an Existing Source

Record the URL, frontmatter, headings, prose, links, media, videos, and contributor data before adapting content. Preserve useful content and stable URLs while changing its representation.

## 2. Use the Project Layout

Retain normal project metadata and use the collection's single layout:

```yaml
---
layout: project-detail
title: Example Project
subtitle: A concise project summary.
date: 2026-08-27
cover: /assets/img/projects/example/cover.png
tags:
  - hardware
project_detail:
  navigation: auto
  intro_style: featured
---
```

Remove obsolete presentation-only frontmatter rather than copying generated chapter or component data into the source.

## 3. Establish Intro and Chapters

Place concise visible Markdown before the first H1 when the page needs a Project Intro. Convert every main chapter to an H1, and keep subsections at H2 or deeper.

```markdown
A compact instrument for field diagnostics.

# Context

Why the project exists.

# Hardware

How the physical system works.

## Analog Front End

Subsection details.
```

Delete duplicated navigation arrays or chapter lists. With `navigation: auto`, the compiler derives both responsive navigation presentations from the H1 sequence.

## 4. Replace Structural HTML

Project Detail rejects author-written HTML except comments. Replace common legacy structures as follows:

| Legacy source | Project Detail source |
| --- | --- |
| Image `<figure>` and caption HTML | [Standalone Figure](components/figure.md) Markdown |
| Image-row or masonry `<div>` markup | Separate [Standalone Figure](components/figure.md) Markdown paragraphs |
| Metric/highlight card HTML | [`callout`](components/callout.md) |
| YouTube `<iframe>` markup | [`video-embed`](components/video-embed.md) |
| Team-card HTML | [`people`](components/people.md) plus frontmatter |
| CTA/card anchor HTML | [`featured-link`](components/featured-link.md) |
| Display title paired with an H1 | [`narrative-title`](components/narrative-title.md) |

Do not replace historical HTML with hand-written Liquid includes. Includes and component classes are internal implementation.

## 5. Move Repeated People Data to Frontmatter

Define each group beneath top-level `people`, then place it once or more with its source name:

```yaml
people:
  team:
    - name: Ada Lovelace
      role: Software Engineer
      image: /assets/img/people/ada.png
      url: https://example.com/ada
```

```markdown
# Team

::: people source=team
:::
```

Every entry needs `name`, `role`, and `image`; omit `url` when there is no destination.

## 6. Validate in Small Steps

Build after converting the document structure, then after each component family. A component failure includes the source path and usually the physical line, for example:

```text
_projects/example.md:42: video-embed supports only valid YouTube video URLs
```

Correct the authored Markdown or frontmatter named by the error. Do not edit generated block IDs or include references.

## 7. Completed Migration Checklist

Confirm all of the following before considering the migration complete:

- The URL and meaningful content are preserved.
- Intro presentation matches `intro_style`.
- Every H1 produces the intended chapter anchor and navigation label.
- H2 and deeper headings remain within the correct chapter.
- Desktop and mobile navigation appear only when intended.
- Image alt text, video titles, captions, person names, roles, and links are correct.
- Video embeds, standalone figures, people, captions, and callouts reflow at desktop, tablet, and mobile widths.
- The page remains readable and anchor links work with JavaScript disabled.
- No author-written structural HTML or internal Liquid include remains.
- The project uses `layout: project-detail` and contains no author-written structural HTML or internal Liquid include.

The complete collection is the production reference. Individual sources demonstrate combinations of registered directives and ordinary standalone figures without exposing the internal rendering pipeline.
