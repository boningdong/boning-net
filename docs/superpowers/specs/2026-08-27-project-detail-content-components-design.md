# Project Detail Content Components Design

Status: Approved for implementation

Date: 2026-08-27

Initial rollout: Scopen only

Supersedes for authoring guidance: `docs/designs/08-26-2026/project-detail-architecture.md`

## 1. Goal and Boundary

The Project Detail system must let an author reproduce the approved Scopen mock using frontmatter, ordinary Markdown, and a small set of explicit typed directives. Authors must not write layout HTML, Liquid includes, component class names, or duplicated chapter metadata.

The build remains a Jekyll build-time system. It uses the Kramdown dependency already present in the repository and local Ruby code under `_plugins`. It adds no third-party Jekyll plugin, HTML parser, client-side Markdown parser, or component framework.

The first production migration applies only to `_projects/scopen.md`. Projects still using `layout: project-post` retain their current rendering and authoring contract.

## 2. System Contract

### 2.1 Inputs

- Project frontmatter, including ordinary project metadata and optional structured component data.
- Markdown content using level-one headings for chapters.
- Typed directives for visual structures that ordinary Markdown cannot express unambiguously.
- Existing local media assets.

### 2.2 Outputs

- Project Intro and semantic Main Content.
- Chapter metadata and stable heading anchors.
- Server-rendered component markup from internal Liquid includes.
- Responsive styling consistent with the approved Project Detail mock.
- Complete accessible content before JavaScript runs.

### 2.3 Responsibilities

- Ruby compiler: validate author input, partition Intro and chapters, parse typed directives, create typed block data, and emit internal render references.
- Component registry: map public directive names to one implementation and define the authoritative list of documented components.
- Liquid includes: render trusted internal block data into semantic HTML.
- Kramdown: render ordinary Markdown and inline Markdown inside supported directive fields.
- SCSS: own visual layout and responsive behavior.
- JavaScript: only operate the existing chapter navigation, active-section tracking, and Corner interaction. Static content components require no JavaScript.

## 3. Project Document Structure

The existing Project Detail chapter contract remains unchanged:

1. Visible Markdown before the first level-one heading is Project Intro.
2. The first level-one heading and everything after it is Main Content.
3. Each level-one heading creates one chapter and one navigation entry.
4. Level-two and deeper headings remain ordinary content inside their parent chapter.
5. Empty lines and HTML comments before the first level-one heading do not create an Intro.
6. A document with no level-one heading renders as ordinary Main Content and has no chapter navigation.

The existing configuration remains deliberately small:

```yaml
project_detail:
  navigation: auto
  intro_style: featured
```

- `navigation`: `auto | none`, default `auto`.
- `intro_style`: `featured | plain`, default `featured`.

When present, `project_detail` must be a mapping and may contain only these two keys. Scalars, arrays, null values, and unknown or misspelled keys fail with the source path rather than silently falling back.

`auto` derives navigation from level-one headings. It renders the desktop chapter navigation and the mobile Corner Navigation when at least two chapters exist. `none` suppresses both.

Authored explicit H1 IDs must start with an ASCII letter and then contain only ASCII letters, numbers, underscores, or hyphens. This validation does not constrain Kramdown-generated IDs. Duplicate or malformed explicit IDs fail at the physical heading line, and chapter IDs are escaped at every generated HTML attribute boundary.

## 4. Typed Directive Grammar

Public directives use fenced blocks:

```markdown
::: directive-name option=value
directive content
:::
```

The opening marker must occupy its own line apart from the directive name and optional attributes. The closing `:::` must occupy its own line. Attributes use `key=value`; quoted values are supported when a value contains whitespace.

Directive names and option names are exact and case-sensitive. Unknown directives, unknown options, malformed attributes, missing closing markers, and invalid child content fail the build with the source path and source line.

Directives cannot nest in version one. Encountering an opening directive inside another directive fails the build instead of relying on ambiguous closing-marker behavior.

The compiler replaces a validated directive with an internal Liquid include reference keyed by an opaque generated block ID. Authors never write that include or block ID.

## 5. Public Components

### 5.1 Narrative Title

Syntax:

```markdown
# Hardware

::: narrative-title
Two systems, one very narrow board.
:::
```

Rules:

- The directive is optional.
- It is valid only as the first visible content block after a level-one chapter heading.
- It accepts inline Markdown but not block children, headings, media, or nested directives.
- The level-one heading remains the chapter identity, anchor, and navigation label.
- When present, the level-one heading is rendered as the smaller chapter label and the narrative title becomes the large displayed heading.
- When absent, the level-one heading retains the normal large chapter-heading presentation.
- No heading level is inferred or generated from a level-two heading.

### 5.2 Standalone Figure and Figure Caption

Authors use ordinary Markdown image syntax:

```markdown
![Exploded diagram of all six PCB layers](/assets/img/projects/scopen/scopen_pcb_6_layers.png "Six layers connect acquisition, storage, and wireless control.")
```

Rules:

- A Markdown image that is the only visible content in its paragraph becomes a Figure component.
- The alt text remains the image alternative text.
- The optional Markdown image title becomes the authored caption.
- An image without a title renders the media surface without a caption row.
- Inline images embedded in prose remain ordinary inline images.
- The caption's left label is generated from the nearest current chapter or subsection heading plus a per-heading figure sequence.
- The caption's right side is the authored title text.
- Figure numbering resets when the nearest heading changes.
- Generated labels are presentation metadata and are not added to chapter navigation.

Example generated labels include `HARDWARE / 01` and `INDUSTRIAL DESIGN / 01`.

### 5.3 Gallery

Syntax:

```markdown
::: gallery
![Analog front end block diagram](/assets/img/projects/scopen/scopen_afe.jpg "Isolation, gain control, and differential conversion.")
![Controller block diagram](/assets/img/projects/scopen/scopen_mcu.jpg "STM32, SRAM, touch input, and WiFi control.")
:::
```

Content contract:

- The body contains only standalone Markdown images separated by blank lines.
- Every item uses the same alt/title behavior as a standalone Figure.
- One item is invalid and fails with guidance to use a plain Markdown image.
- Empty galleries and non-image children are invalid.

Layout contract:

- 2 items: one row of two equal media frames.
- 3 items: one row of three equal media frames.
- 4 items: a two-by-two grid of equal media frames.
- 5 or more items: CSS multi-column masonry that preserves intrinsic media proportions.
- Tablet: no more than two columns.
- Mobile: one column.
- Items in the two-to-four range use equal visual frame proportions even if the source image dimensions differ.
- Masonry uses CSS multi-column layout rather than experimental native CSS Masonry or JavaScript measurement.
- The peer collection uses `ul`/`li` semantics. A captioned `li` contains `figure` and `figcaption`; a captionless `li` contains a neutral container and no empty figure semantics, while still advancing the shared figure sequence.

### 5.4 Callout

Syntax:

```markdown
::: callout
**2.45 × 0.73 in**

The six-layer board is narrower than a stick of gum.
:::
```

Rules:

- The first visible child must be one emphasized paragraph using either strong or emphasis Markdown.
- Remaining content is ordinary Markdown and may contain paragraphs, lists, and links.
- The component is semantically generic; it is not restricted to metrics.
- Headings, media, raw HTML, and nested directives are invalid inside a Callout.

### 5.5 Videos

Syntax:

```markdown
::: videos
[Scopen hardware demonstration](https://www.youtube.com/watch?v=4xJvWEb1Kwo "Hardware demonstration")
[Scopen software demonstration](https://www.youtube.com/watch?v=fFWyjB_XNrE "Software demonstration")
:::
```

Content contract:

- The body contains only standalone Markdown links separated by blank lines.
- Link text is the accessible video title.
- The optional link title is the visible caption.
- Version one accepts YouTube watch and share URLs and normalizes them to privacy-enhanced embeds.
- Unsupported hosts and malformed video URLs fail the build.

Layout contract:

- 1 item: full width.
- 2 items: two columns.
- 3 or more items: a grid capped at two columns.
- Tablet and mobile: one column.
- Videos reuse internal collection and caption primitives but remain a separate public directive with video-specific validation.

### 5.6 People

Frontmatter supplies structured data:

```yaml
people:
  team:
    - name: Byron Aguilar
      role: Computer Engineer
      image: /assets/img/people/byron.png
      url: https://www.linkedin.com/in/byron-aguilar-a139057b/
```

Markdown places the component:

```markdown
::: people source=team
:::
```

Rules:

- `source` is required and resolves beneath the document's top-level `people` mapping.
- Each person requires `name`, `role`, and `image`.
- `url` is optional. A person without a URL renders without an empty or inert link.
- Unknown sources, non-array sources, empty arrays, unknown person keys, and missing required values fail the build.
- Image alt text is generated as `Portrait of {name}`.
- The general `source` contract permits future groups without creating a new directive.

### 5.7 Featured Link

Syntax:

```markdown
::: featured-link
[Watch the presentation](https://youtu.be/ieGTWUUsJ_8)
:::
```

Rules:

- The body contains exactly one standalone Markdown link.
- Inline emphasis in the label is allowed if Kramdown preserves it as link content.
- Extra prose, multiple links, media, headings, raw HTML, and nested directives are invalid.
- External links follow the site's existing external-link behavior; the compiler does not silently add a new-window target.
- XML/HTML comments are invalid because the body contract is exactly one standalone link; they are not silently discarded.

## 6. Raw HTML Policy

Project documents using `layout: project-detail` must not contain author-written structural HTML. HTML comments remain allowed. Inline and block HTML elements otherwise fail the build with source path and line number.

Author-written Liquid tags and outputs are rejected with physical source locations before any internal sentinel or include is inserted. Backtick and tilde fenced code blocks may contain literal Liquid examples; the compiler protects those delimiters so Jekyll renders the examples without executing them. Only compiler-generated internal Liquid is executable.

This is an intentional authoring boundary, not an HTML limitation in the rendering layer. Trusted markup is produced only by internal includes and ordinary Kramdown output. Legacy `layout: project-post` documents are not checked by this rule.

## 7. Compiler Architecture

### 7.1 Pipeline

The document hook performs the following ordered stages:

1. Validate `project_detail` configuration.
2. Reject author-written HTML except comments and reject executable author Liquid outside fenced examples.
3. Protect literal Liquid examples inside fenced code, then parse directive fences and attributes into source-aware directive nodes.
4. Resolve each directive through the component registry and validate its content.
5. Parse the remaining Markdown through Kramdown to identify Intro, chapters, heading IDs, and standalone images.
6. Convert directives and standalone images into serializable typed block hashes.
7. Store block hashes under `project_detail_generated.blocks` using generated IDs.
8. Replace component source ranges with internal include references.
9. Wrap chapters while preserving Kramdown-compatible IDs and the existing navigation data.
10. Allow Liquid and Kramdown to render the final trusted markup.

Directive parsing occurs before general Kramdown interpretation so the fence grammar and error locations remain deterministic. Component bodies are then parsed with Kramdown according to each component's explicit content contract.

### 7.2 Core Interfaces

`DirectiveParser#call` returns source-aware nodes with `name`, `attributes`, `body`, `start_line`, and `end_line`.

`ComponentRegistry` owns the map from public type to component class. Registration fails on duplicate names. Unknown lookups raise a source-aware configuration error. The registry is also the source for documentation completeness tests.

Each component inherits from `Components::Base`, declares its public type, validates one directive node in a `RenderContext`, and returns a serializable block hash. Component classes do not emit final HTML.

`RenderContext` supplies the document path, frontmatter, Kramdown options, current heading label, sequence counters, and block storage. It centralizes source-aware failures and prevents component-specific global state.

Shared primitives normalize collection layout metadata, media items, and captions. Public directives remain independent even when they reuse the same primitives.

### 7.3 File Ownership

```text
_plugins/project_detail.rb
_plugins/project_detail/
  compiler.rb
  chapter_compiler.rb
  directive_parser.rb
  component_registry.rb
  render_context.rb
  errors.rb
  components/
    base.rb
    standalone_figure.rb
    narrative_title.rb
    gallery.rb
    callout.rb
    videos.rb
    people.rb
    featured_link.rb
  primitives/
    collection.rb
    figure.rb
    caption.rb
```

The root plugin file remains a thin require and Jekyll-hook entrypoint. Chapter behavior moves into `ChapterCompiler`; orchestration stays in `Compiler`.

Internal markup lives beneath:

```text
_includes/pages/project-detail/blocks/
  narrative-title.html
  figure.html
  gallery.html
  callout.html
  videos.html
  people.html
  featured-link.html
  primitives/
    media-frame.html
    caption.html
    video-item.html
    person-card.html
```

Project Detail styles use a thin `_sass/pages/_project-detail.scss` entry and component-owned partials beneath `_sass/pages/project-detail/`. Responsive rules remain with the component or primitive they modify.

## 8. Accessibility and Semantics

- Chapter anchors and heading hierarchy remain available without JavaScript.
- Narrative Title does not create a second semantic chapter; its markup supplements the chapter heading presentation.
- Figures use `figure` and `figcaption` only when a caption exists; captionless media still has meaningful alt text.
- Galleries and video grids use list semantics when grouping multiple peer items.
- Video iframes use authored accessible titles, lazy loading, safe allow attributes, and `youtube-nocookie.com` embeds.
- People cards preserve names and roles as text; linked cards have one coherent accessible target.
- Build errors prevent invalid empty links, missing alt text, or ambiguous component bodies from reaching production.

## 9. Documentation Contract

Permanent author documentation lives at `docs/project-detail/README.md`. Technical architecture lives at `docs/project-detail/architecture.md`, and Scopen conversion guidance lives at `docs/project-detail/migration.md`.

Every public directive has a file under `docs/project-detail/components/`. Standalone Figure also has a component document even though it uses ordinary Markdown instead of a directive.

Each component document contains these exact sections:

1. Purpose
2. Syntax
3. Options
4. Content Contract
5. Behavior
6. Generated Semantics
7. Validation
8. Examples
9. Related Components

`docs/project-detail/components/README.md` indexes every registry directive plus Standalone Figure. An automated documentation test compares the component registry to the documentation tree and index so adding a registered directive without documenting it fails CI.

`docs/content-schema.md` links to the author guide. `docs/architecture/frontend.md` links to the technical architecture. The older 2026-08-26 design document remains as historical context and points readers to the current guide.

## 10. Testing Strategy

Tests use the repository's existing dependency-free Ruby assertion style.

- Parser tests cover fences, quoted attributes, line locations, missing closes, malformed attributes, unknown directives, and prohibited nesting.
- Registry tests cover registration, duplicate names, unknown names, and enumeration for documentation.
- Component tests cover every valid form, invalid body, invalid option, and serialized block shape.
- Figure tests cover standalone versus inline images, title captions, sequence reset, and captionless media.
- Chapter tests preserve all existing Intro, heading ID, duplicate ID, navigation, and wrapping behavior.
- Compiler tests cover stage ordering, raw HTML rejection, generated block storage, and coexistence of Markdown with multiple components.
- Rendering tests build the site and inspect semantic output, internal include rendering, Scopen migration, and legacy-page isolation.
- Documentation tests enforce registry/document parity and required headings.
- Browser QA covers the approved wide desktop, desktop, tablet, and mobile layouts, including galleries, caption alignment, video grids, people cards, Narrative Title, Bridge Intro, desktop navigation, and Corner Navigation.

## 11. Migration and Compatibility

Scopen is converted from author-written `<div>`, `<figure>`, `<iframe>`, and team-card HTML to typed directives, plain Markdown images, and frontmatter people data. The rendered information and approved visual design are preserved.

The implementation does not migrate other projects, change their layouts, or reject HTML in legacy pages. Future migration is explicit: switch to `layout: project-detail`, adopt the chapter contract, and replace structural HTML with documented components.

## 12. Extension Rules

A future display type is added by:

1. Defining one component class with a unique public type and explicit validation.
2. Registering it in the component registry.
3. Adding its internal include and component-owned SCSS.
4. Adding unit and rendering tests.
5. Adding the required component documentation.

New component types do not add frontmatter booleans. Frontmatter is used only for project data or genuine document-wide behavior. Incompatible public syntax requires an explicit contract/version discussion; internal refactors do not.

## 13. Explicit Non-Goals

- Automatic inference of galleries, callouts, video groups, people groups, or featured links.
- Author-written Liquid includes as a public component API.
- Nested directives in version one.
- A public `figure` directive.
- JavaScript masonry or client-side component rendering.
- Native experimental CSS Masonry.
- Installing a new Markdown extension or HTML parser.
- Migrating projects other than Scopen in the initial rollout.
