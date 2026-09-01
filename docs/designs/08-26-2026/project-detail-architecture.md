# Project Detail Architecture

> Historical design document, superseded for current authoring guidance. Use the [Project Detail author guide](../../project-detail/README.md) for supported syntax and the [current technical architecture](../../project-detail/architecture.md) for implementation ownership. This file remains as design-decision context for the initial chapter system.

Status: Approved for implementation

Date: 2026-08-26

Initial rollout: Scopen only

## Objective

Create a Markdown-first Project Detail system whose structure is resolved during the Jekyll build. Project authors should normally edit only frontmatter and Markdown. The build derives the Project Intro, main chapters, anchors, and responsive chapter navigation without a duplicated chapter list.

The first production rollout applies only to Scopen. Existing projects using `layout: project-post` remain unchanged until they are migrated deliberately.

## Selected Visual Design

- Layout: the approved Project Detail design.
- Hero: selected background 04, rendered with `cover` by default. A project-provided hero overrides the default.
- Project Intro: the approved Bridge presentation when `intro_style` is `featured`.
- Desktop chapters: the approved desktop chapter navigation.
- Mobile chapters: the approved Corner Navigation.
- Mobile Corner Navigation stays hidden through the Hero and appears when the reader reaches Main Content.
- Main-content media, glass, radii, shadows, spacing, and background treatment use the same design tokens and visual semantics as the homepage and current modern pages.

## Public Authoring Contract

Opting into the system requires only the new layout:

```yaml
---
layout: project-detail
title: Scopen
subtitle: A wireless oscilloscope designed to make circuit debugging portable.
hero: /assets/img/projects/scopen/hero.png
---
```

`layout: project-detail` is the architecture switch. There is no `project_detail_version` field and no plugin-specific boolean.

Optional behavior overrides are namespaced:

```yaml
project_detail:
  navigation: auto
  intro_style: featured
```

Both values may be omitted. Their defaults are:

```yaml
project_detail:
  navigation: auto
  intro_style: featured
```

Accepted values are deliberately narrow:

- `navigation`: `auto | none`
- `intro_style`: `featured | plain`

Invalid values fail the build with the source path, invalid value, and accepted values. They do not silently fall back.

## Markdown Structure

Example:

```markdown
A lab instrument that fits in your pocket.

# Context

Project background.

# Hardware

Hardware content.

## Analog Front End

A subsection within Hardware.

# Firmware

Firmware content.
```

The content contract is:

1. Visible Markdown before the first level-one heading is Project Intro.
2. The first level-one heading and everything after it is Main Content.
3. Every level-one heading starts a main chapter.
4. Level-two and deeper headings stay within their parent chapter and never enter chapter navigation.
5. Empty lines and HTML comments alone do not constitute an Intro.
6. If the document starts with a level-one heading, no Intro markup or Intro spacing is rendered.
7. If the document has no level-one heading, the whole document is rendered as ordinary Main Content. It has no extracted Intro and no chapter navigation.

Project Intro is intentionally concise: it may be one strong sentence or a short paragraph. The build does not impose a character limit.

Authors may rely on Kramdown-generated heading IDs or provide a stable explicit ID:

```markdown
# Industrial Design {#industrial-design}
```

## Intro Rendering

### Featured

`intro_style: featured` extracts the Project Intro from the ordinary content flow and renders it through the approved Bridge component. The Intro retains normal Markdown inline semantics such as emphasis and links.

### Plain

`intro_style: plain` preserves the normal Kramdown HTML presentation immediately before the first level-one heading. It does not add the Bridge label, display typography, decorative container, or featured spacing.

If no Intro exists, `intro_style` has no visible effect.

## Chapter Navigation

### Auto

`navigation: auto` derives navigation from level-one Markdown headings in source order.

- Two or more chapters render chapter navigation.
- Fewer than two chapters render no navigation because a one-item navigator has no navigational value.
- Desktop renders the approved chapter navigation.
- Mobile renders the approved Corner Navigation.
- Both responsive presentations consume the same generated chapter data and anchor IDs.
- CSS selects the responsive presentation; JavaScript does not build separate desktop and mobile datasets.

### None

`navigation: none` suppresses both responsive navigation presentations:

- No desktop chapter navigation is rendered.
- No mobile Corner Navigation is rendered.
- No chapter-tracking JavaScript is initialized.
- Main Content is still parsed and rendered into semantic chapters so its typography, anchors, spacing, and section separators remain consistent.

## Build-Time Architecture

The implementation uses a local `_plugins` component and the Kramdown version already provided by Jekyll. It adds no third-party Jekyll plugin and no HTML-parser dependency.

The Project Detail processor runs only for documents using `layout: project-detail`. It performs one logical compilation pipeline:

1. Validate `project_detail.navigation` and `project_detail.intro_style`.
2. Parse the Markdown with the site's existing Kramdown configuration.
3. Inspect the Kramdown document structure rather than matching source or rendered HTML with regular expressions.
4. Locate the first level-one heading and partition Intro from Main Content.
5. Collect level-one chapter titles, source order, and Kramdown-compatible IDs.
6. Render Intro and Main Content with the same Kramdown configuration.
7. Expose generated Intro HTML, Main Content HTML, and chapter metadata to the layout as internal build data.

Conceptually, the generated chapter data is:

```yaml
chapters:
  - index: 1
    id: context
    title: Context
  - index: 2
    id: hardware
    title: Hardware
```

This generated structure is internal output, not author-maintained frontmatter.

The parser, layout, and JavaScript have separate responsibilities:

- Build processor: content interpretation, validation, Intro extraction, chapter extraction, and stable anchors.
- Layout/includes: Hero, Project Intro, semantic Main Content, desktop navigation markup, and Corner Navigation markup.
- CSS: visual treatment and responsive selection.
- JavaScript: active-section tracking, Corner visibility, panel interaction, focus management, Escape handling, and anchor scrolling.

JavaScript never interprets Markdown, moves Intro content, creates chapter data, or reconstructs the article.

## Progressive Behavior and Accessibility

The build emits complete semantic content and navigation markup. Main Content remains readable without JavaScript.

When navigation is present, JavaScript progressively adds:

- Active chapter state through `IntersectionObserver`.
- Current position such as `2 / 5`.
- Corner indicator reveal after Main Content begins.
- Corner panel open and close behavior.
- Keyboard focus containment and restoration.
- Escape-to-close behavior.
- Reduced-motion-compatible scrolling and transitions.

The active chapter state is an enhancement. Anchor links remain valid without tracking.

## Failure Handling

Build errors are explicit and attributable. For example:

```text
_projects/scopen.md: project_detail.navigation must be "auto" or "none"; received "automatic"
```

The processor must also detect and report conditions that would produce unreliable navigation, including duplicate explicit heading IDs. Error messages include the project source path and the affected heading when available.

Ordinary empty states are not errors:

- No visible pre-heading content means no Project Intro.
- No level-one heading means ordinary Main Content with no navigation.
- One level-one heading means one semantic chapter with no navigation.

## Rollout and Compatibility

Scopen is migrated first by changing its layout and restructuring its Markdown into the approved chapter model while preserving useful existing technical content and media.

The processor does not run for `layout: project-post`, so the other project documents, their Bootstrap-era markup, and their existing URLs remain unchanged. Future migration consists of selecting `layout: project-detail` and adapting the Markdown to the public authoring contract.

The absence of a schema-version field is intentional. A version should be introduced only if a future authoring contract becomes incompatible with this one. Optional internal components do not receive individual frontmatter booleans; automatic conventions are the default and namespaced configuration exists only for genuine author overrides.

## Verification Strategy

Automated coverage will verify:

- Intro extraction for one sentence and one short paragraph.
- No Intro output when the first visible node is a level-one heading.
- No split when the document has no level-one heading.
- Chapter extraction from level-one headings only.
- Exclusion of level-two and deeper headings from navigation.
- Kramdown-generated and explicit anchor IDs.
- Duplicate explicit-ID failure.
- Default configuration values.
- Rejection of invalid configuration values.
- `navigation: auto` behavior for zero, one, and multiple chapters.
- `navigation: none` suppressing both desktop and mobile navigation.
- `featured` and `plain` Intro rendering.
- Scopen rendering through the new layout while a legacy project remains unchanged.
- Corner visibility, open/close, active chapter, anchor navigation, keyboard, and reduced-motion behavior.

Visual verification will cover desktop, wide desktop, tablet, and mobile widths, including the selected Hero 04 in `cover` mode, the Bridge Project Intro, desktop chapter navigation, and Corner Navigation.

## Out of Scope for the Initial Rollout

- Migrating projects other than Scopen.
- Manual chapter lists or reordered navigation.
- Additional navigation modes beyond `auto | none`.
- Additional Intro styles beyond `featured | plain`.
- A public project-detail schema version.
- Per-plugin frontmatter flags.
