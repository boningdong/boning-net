# Project Detail Author Guide

Use this guide when writing a project with `layout: project-detail`. The public authoring API is frontmatter, ordinary Markdown, and the typed directives listed in the [component index](components/README.md). Do not write Liquid includes, generated block IDs, layout HTML, or component class names in project content.

For compiler and rendering internals, see the [technical architecture](architecture.md). For converting an existing project, see the [migration guide](migration.md).

## Start a Project Detail Document

Set the layout in the project's frontmatter. Existing project metadata such as `title`, `subtitle`, `date`, `cover`, and `tags` continues to use the site's [content schema](../content-schema.md).

```yaml
---
layout: project-detail
title: Example Project
subtitle: A concise description of the project.
date: 2026-08-27
cover: /assets/img/projects/example/cover.png
tags:
  - hardware
project_detail:
  navigation: auto
  intro_style: featured
---
```

The `project_detail` value, when present, must be a mapping. Both supported options are optional: `navigation` accepts `auto` or `none` and defaults to `auto`, while `intro_style` accepts `featured` or `plain` and defaults to `featured`. Unknown keys, including misspellings, and invalid values stop the Jekyll build instead of being ignored.

## Project Intro

Visible Markdown before the first level-one heading is the Project Intro.

```markdown
A portable instrument for debugging circuits anywhere.

This short second paragraph can add essential context.

# Context

The first chapter begins here.
```

With `intro_style: featured`, the Intro is extracted into the featured Bridge presentation. With `intro_style: plain`, it remains ordinary rendered Markdown immediately before the first chapter. Blank lines and HTML comments alone do not create an Intro. If the document begins with an H1, no Intro is rendered. If the document has no H1, all content renders as ordinary Main Content and no chapter navigation is created.

## H1 Chapters

Every Markdown H1 starts a chapter and supplies its title, anchor, and navigation label. H2 and deeper headings remain inside the current chapter.

```markdown
# Context

Project background.

# Hardware {#hardware}

Hardware overview.

## Analog Front End

Subsection content.
```

Kramdown generates an anchor when no explicit ID is present. Use `{#stable-id}` on an H1 when a permanent hand-authored anchor is useful. An explicit ID must start with an ASCII letter and then contain only ASCII letters, numbers, underscores, or hyphens. Duplicate or malformed explicit H1 IDs stop the build with the heading's physical source line. This restriction applies only to authored explicit IDs; Kramdown-generated IDs retain Kramdown's normal behavior. Do not duplicate chapter titles in frontmatter.

## Navigation

With `navigation: auto`, two or more H1 chapters produce desktop chapter navigation and the mobile Corner Navigation from the same generated chapter data. Zero or one H1 produces no navigation. With `navigation: none`, neither navigation presentation is rendered, but H1 chapters remain semantic anchored sections.

Navigation links and chapter content work before JavaScript runs. JavaScript only adds active-chapter tracking, the mobile Corner interaction, focus handling, and enhanced scrolling.

## Typed Directives

Use a directive only when ordinary Markdown cannot express the component. Its opening marker, name, and optional `key=value` attributes occupy one line; its closing marker occupies its own line.

```markdown
::: callout
**Key result**

Supporting Markdown.
:::
```

Names and option names are case-sensitive. Quote an attribute value that contains whitespace, for example `source="project team"`. Directives cannot nest. Unknown directives, unknown options, malformed attributes, or a missing close marker stop the build with the source path and line.

The public directive types are:

- [`narrative-title`](components/narrative-title.md)
- [`gallery`](components/gallery.md)
- [`callout`](components/callout.md)
- [`videos`](components/videos.md)
- [`people`](components/people.md)
- [`featured-link`](components/featured-link.md)

A [Standalone Figure](components/figure.md) is also a public component, but authors create it with ordinary Markdown image syntax rather than a `figure` directive.

## Raw HTML Policy

Author-written inline and block HTML is not allowed in content using `layout: project-detail`. HTML comments remain globally allowed in ordinary Project Detail content.

```markdown
<!-- This editorial note is allowed. -->
```

Structural HTML such as `<div>`, `<figure>`, and `<iframe>` stops the build. Author-written Liquid tags and outputs, including `{% include ... %}` and `{{ page.value }}`, also stop the build with their physical source line; only compiler-generated internal Liquid is allowed to execute. Literal Liquid examples remain supported inside backtick or tilde fenced code blocks and render as written without execution. Use ordinary Markdown or a documented component instead. Each typed component body follows its own stricter Content Contract, so a comment inside a component is accepted only when that component explicitly permits it. These restrictions apply only to `layout: project-detail`; legacy `layout: project-post` documents retain their existing behavior.

## Links and Safety

Links in validated component fields may be relative or use `http`, `https`, `mailto`, or `tel`. Unsafe, malformed, control-character-obfuscated, and network-path URLs are rejected. Component inline attribute lists are rejected where the component contract does not explicitly allow them.

## Build Errors

Failures identify the project path and source line whenever a precise content location exists. For example:

```text
_projects/example.md:18: unknown directive "comparison"
_projects/example.md:24: gallery requires at least two images; use a plain Markdown image instead
_projects/example.md:31: raw HTML is not allowed in project detail content
```

Fix the author source named by the error. Generated includes and `project_detail_generated` data are internal output and must not be edited or copied into a project document.
