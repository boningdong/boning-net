# Project Detail Technical Architecture

This document describes the build-time implementation behind `layout: project-detail`. The public authoring contract is the [Project Detail author guide](README.md); internal classes, generated hashes, include references, and CSS class names described here are not author API.

## System Boundary

The system accepts project frontmatter and Markdown, compiles every project document during Jekyll's `:documents, :pre_render` hook, and emits complete semantic content plus optional chapter navigation. Project pages use `layout: project-detail`.

Kramdown remains the Markdown parser. The system adds no client-side Markdown parser, component framework, HTML-parser dependency, or third-party Jekyll plugin. JavaScript does not create project content.

## Inputs and Outputs

Author-controlled inputs are:

- ordinary project frontmatter;
- optional `project_detail.navigation` and `project_detail.intro_style` values;
- Intro and chapter Markdown;
- five registered typed directives;
- standalone Markdown images; and
- structured `people` frontmatter consumed by the `people` directive.

Build output consists of transformed Markdown containing trusted internal include references, chapter metadata, Intro parts, navigation state, and serializable component blocks under `page.project_detail_generated`. Liquid includes render the blocks; Kramdown renders ordinary Markdown and supported component fields.

## Compilation Pipeline

`BoningNet::ProjectDetail.compile_document` constructs `Compiler` with the document body, project configuration, frontmatter, source path, frontmatter line offset, Kramdown options, and the production registry.

`Compiler#call` performs these stages in order:

1. Require `project_detail`, when present, to be a mapping; reject unknown keys; and validate `navigation` and `intro_style`.
2. Parse the author source with Kramdown and reject author-written HTML elements.
3. Reject author-written Liquid tags and outputs outside fenced code, then protect fenced literal examples from Liquid evaluation.
4. Parse directive fences into immutable, source-aware nodes.
5. Find standalone Markdown image paragraphs outside directive ranges.
6. Establish the nearest H1 or H2 context, compile each component to a block hash, and recursively validate its string-keyed JSON-like data.
7. Store blocks under opaque IDs such as `project-detail-block-1`.
8. Replace component source ranges with collision-resistant sentinels.
9. Pass transformed Markdown to `ChapterCompiler` to extract Intro, validate authored explicit IDs, wrap H1 chapters, and derive navigation metadata.
10. Replace sentinels with trusted internal Liquid include references.
11. Store the result in `page.project_detail_generated` for the layout.

Directive parsing precedes component-body Kramdown parsing so fence errors and source locations remain deterministic. Standalone images are identified from Kramdown structure, not inferred with a rendered-HTML regular expression.

## Registry and Components

`ComponentRegistry` is the authority for public directive types. `_plugins/project_detail.rb` registers `narrative-title`, `callout`, `featured-link`, `video-embed`, and `people`. Duplicate registration and unknown lookup are configuration errors, and `registry.types` drives documentation parity tests.

Each registered component inherits from `Components::Base`, declares one immutable public type, validates a `DirectiveNode` against a `RenderContext`, and returns a plain hash with a valid `type`. Components do not emit final HTML.

`Components::StandaloneFigure` is intentionally outside the directive registry because its public syntax is ordinary Markdown. It converts an image-only paragraph to the internal `figure` block shape. This distinction prevents documentation or extensions from implying that `::: figure` is supported.

Shared primitives own image/caption block shapes and per-heading caption labels. Reuse of a primitive does not make two public directives interchangeable.

## Render Context and Generated Data

`RenderContext` owns the source path, frontmatter, Kramdown options, current H1/H2 identity, per-heading figure counters, and block storage. It also adds the physical frontmatter offset to source-aware component errors.

Conceptually, a compiled document exposes:

```yaml
project_detail_generated:
  intro_markdown: "..."
  chapters:
    - index: 1
      id: context
      title: Context
  navigation_enabled: false
  corner_navigation_enabled: false
  intro_style: featured
  blocks:
    project-detail-block-1:
      type: figure
      image:
        src: /assets/img/projects/example/board.png
        alt: Example circuit board
  intro_parts:
    - kind: markdown
      markdown: "..."
```

This shape is internal build output. Authors must not place it in frontmatter or depend on its block IDs.

## Chapter Compilation

`ChapterCompiler` uses Kramdown's document and table-of-contents structures to identify level-one headings and Kramdown-compatible IDs. Content before the first H1 becomes Intro when visible. Main Content is wrapped in semantic `.project-chapter` sections without changing the authored heading hierarchy.

With `navigation: auto`, one H1 enables desktop chapter navigation, while two or more H1 chapters enable both desktop and Corner Navigation from the same chapter array. Zero H1 chapters create neither navigation presentation. With `navigation: none`, both presentations remain disabled regardless of chapter count. These presentation flags do not change the desktop reading rail: Main Content keeps its right-hand grid column even when the chapter-list column is empty. Authored explicit H1 IDs use a restricted ASCII grammar, duplicate explicit IDs are rejected before rendering, and every generated HTML attribute boundary escapes the resulting chapter metadata. Kramdown-generated IDs remain unchanged.

## Rendering Ownership

Internal component markup lives in `_includes/pages/project-detail/blocks/`, with shared render fragments under `blocks/primitives/`. The project-detail layout owns Hero, Intro, Main Content, desktop navigation, and Corner Navigation composition.

The thin `_sass/pages/_project-detail.scss` entry composes page structure, component partials, and primitive partials. Component-specific responsive rules remain beside the component they modify. The Main Content rail is intentionally wider than long-form prose: direct paragraphs and classless Markdown lists use `--project-prose-width`, while registered component roots, media, headings, Callout, Video Embed, and People use the complete rail. This keeps readable line lengths without allowing a generic list selector to constrain list-based component markup. Video Embed remains one full-width column at every breakpoint; People owns its documented responsive card grid.

JavaScript in `assets/js/pages/project-detail.js` progressively enhances chapter navigation with active-section tracking, Corner visibility, panel interaction, focus management, Escape handling, and anchor scrolling. It does not parse Markdown, create blocks, or move content between page regions.

## Validation and Trust Boundary

The compiler rejects non-mapping or unknown-key configuration, raw author HTML except comments, executable author Liquid outside fenced examples, malformed or nested directives, unknown directives/options, unsafe component URLs, invalid component children, non-JSON-like nested block data, and component-specific missing data. Errors use the project path and physical source line when available.

Only internal Liquid includes emit structural component HTML. Component content rendered through Kramdown is constrained to the node types and attributes accepted by that component. This keeps author content separate from trusted rendering implementation.

## Accessibility and Progressive Rendering

The server-rendered document contains heading anchors and readable content before JavaScript runs. Image alt text remains on images, authored video link text becomes iframe titles, captioned media uses `figure`/`figcaption`, video and people collections use list markup, and unlinked people do not receive inert anchors.

JavaScript-enhanced navigation preserves anchor behavior and adds focus and state management. Reduced-motion behavior remains a presentation concern rather than a compiler branch.

## Extension Procedure

To add a public directive:

1. Create a component class with one unique registered type and explicit validation.
2. Register it in `_plugins/project_detail.rb`.
3. Add its internal include and component-owned SCSS.
4. Add unit and rendering coverage.
5. Add the corresponding author document and component-index link.

The documentation parity test fails when the production registry, documentation files, or component index diverge. New display types do not add frontmatter booleans; frontmatter is reserved for project data or genuine document-wide behavior.
