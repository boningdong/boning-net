# All Projects Project Detail Migration Design

**Date:** 2026-08-30
**Status:** Proposed for implementation

## Goal

Migrate the eleven remaining portfolio projects from the Bootstrap-era `project-post` layout to the production `project-detail` system already used by Scopen. Preserve the facts, media, links, dates, tags, and project URLs while lightly proofreading the English and removing obsolete presentation code after every project has moved.

The finished collection must use one authoring model: frontmatter, ordinary Markdown, standalone captioned images, and the existing typed directives. Project source files must not contain structural HTML, Liquid expressions, Bootstrap classes, or raw iframes.

## Scope

The migration covers:

- `_projects/ar_domino.md`
- `_projects/areusafe.md`
- `_projects/chatbot.md`
- `_projects/drsstc.md`
- `_projects/ecosystem.md`
- `_projects/kossel_printer.md`
- `_projects/msp430_dev.md`
- `_projects/nes_emulator.md`
- `_projects/simplewatch.md`
- `_projects/smartlamp.md`
- `_projects/spl_visualization.md`

Scopen remains the reference implementation and receives no editorial restructuring as part of this migration.

## Alternatives Considered

### 1. Project-by-project migration with contract tests — selected

Migrate one project at a time, preserve its media order, verify the authored contract, and render the complete collection before deleting legacy code. This costs more test setup than a mechanical replacement but gives each short, irregular document an explicit review boundary and makes cleanup evidence-based.

### 2. One mechanical conversion followed by a global editorial pass

A script could replace layouts and extract image paths quickly. The legacy documents are structurally inconsistent, however: some begin with images, some contain videos, some have only one H1, and several headings contain spelling errors or numbered prose. A mechanical converter would either preserve weak structure or require enough exceptions to become harder to review than direct migration.

### 3. Add a compatibility renderer for legacy HTML

The new layout could accept old Bootstrap grids and iframes. This would keep two authoring systems alive, weaken the raw-HTML boundary, retain Bootstrap-era concepts in content, and prevent removal of the old dependency surface. It is rejected.

## Shared Page Contract

Every migrated project will:

- set `layout: project-detail`;
- inherit `_config.yml`'s approved default Hero 04 and omit a project-specific `hero` field;
- retain its existing `cover` for Projects List cards;
- use `intro_style: featured` explicitly or through the documented default;
- use `navigation: auto` explicitly or through the documented default;
- place a concise lead and short overview before the first H1;
- use H1 headings for navigable topic chapters and H2 headings only for local structure;
- use ordinary Markdown for paragraphs, lists, links, and standalone images;
- give every standalone image useful alt text and a short title caption without sentence-ending punctuation;
- use `::: video-embed` for YouTube media;
- use `::: featured-link` in Project Intro only for GitHub or source-code destinations;
- keep live demos in the relevant Main Content chapter;
- contain no author-written structural HTML or Liquid.

The default `navigation: auto` behavior remains authoritative. Documents with insufficient chapters will render without desktop chapter navigation and without Corner Navigation; the migration will not invent empty chapters solely to force navigation.

## Project Intro Rules

Every project receives the same two-level Bridge structure used by Scopen:

1. A short lead sentence that states the project's most distinctive outcome or constraint.
2. A compact overview derived from existing copy that states the goal, scope, and personal role when known.

The Intro may correct grammar and compress repetition but must not introduce unverified outcomes, technologies, collaborators, or responsibilities. Projects with an existing GitHub or source-code URL receive one `featured-link` in Intro. AreUSafe has no source link, and its Play Store link remains in Main Content. Programming Languages Trend uses GitHub in Intro and retains the p5.js live demo in Main Content.

## Main Content and Navigation

Existing content will be reorganized only where necessary to produce meaningful H1 chapters. Generic and incorrect headings such as `Descriptions`, `Concep`, `Design Concep`, and `Progress` may become clearer forms such as `Overview`, `Design`, `Implementation`, `Results`, or `Current Status`.

The migration may:

- move an opening description into Project Intro;
- merge adjacent paragraphs that repeat the same point;
- split dense text into short paragraphs or lists;
- add brief transitions between existing topics or media;
- correct tense, articles, plurals, punctuation, capitalization, spelling, and terminology;
- correct clear title errors such as `NES Emulator Projec` and `High frequnecy`.

The migration must not:

- reinterpret the technical work;
- claim a project was completed when the source describes it as unfinished;
- remove documented contributors or attribution;
- modernize historical technology names;
- add retrospective lessons or results that are not present in the source;
- substantially expand the prose.

## Media Migration

All legacy Bootstrap image grids will become standalone Markdown figures in their current reading order. Each image renders full width through the existing Project Detail figure primitive. No `gallery` directive or multi-column image component will be reintroduced.

Animated GIFs remain ordinary image sources and receive the same figure treatment. Existing YouTube iframes in AR Domino and DRSSTC become individual `video-embed` directives with privacy-enhanced embeds supplied by the component. Videos remain one per row at every viewport.

Media captions will be short noun phrases that identify what the image proves or depicts. Captions will not end in periods, exclamation marks, or question marks.

## Links

Existing `external-link` frontmatter remains during migration because collection consumers may still read it. When it points to GitHub or source code, the same destination is authored as an Intro `featured-link` with a specific label such as `View source on GitHub`.

Live application links remain in Main Content as ordinary Markdown links. The migration does not convert every inline link into a component.

## Proofreading Standard

Proofreading is intentionally conservative. It covers:

- spelling and typographical errors;
- subject–verb agreement;
- articles and prepositions;
- singular/plural agreement;
- verb tense consistency;
- capitalization of product and technology names;
- awkward phrasing where the intended meaning is unambiguous;
- list parallelism and punctuation;
- obvious terminology errors such as `phrases` where `phases` is intended.

When a sentence's technical meaning is ambiguous, preserve the original claim and make only the smallest grammatical correction.

## Legacy Retirement

Legacy deletion happens only after all twelve project documents build through `project-detail` and the generated project pages contain no Bootstrap-era markup.

The first removal candidates are:

- `_layouts/project-post.html`;
- `_layouts/default.html`, if no production page references it after migration;
- `_includes/header.html`, if it becomes unreachable with `default`;
- production-unreferenced files under `_includes/showcase/`;
- production-unreferenced files under `assets/css/showcase/`;
- production-unreferenced files under `_sass/showcase/`;
- remote Bootstrap, jQuery, Popper, and legacy font requests owned by the deleted shell;
- obsolete tests and documentation that assert coexistence with `project-post`.

Deletion is reachability-based, not directory-name-based. A file stays if any production layout, include, page, stylesheet, or script still references it. Design mocks under `docs/designs/` remain historical artifacts and are not production dependencies.

## Documentation Updates

Update the permanent authoring and architecture documentation so `project-detail` is the only project page contract. Remove migration language that describes `project-post` as a supported long-term path.

With explicit user approval, update both `AGENTS.md` and `CLAUDE.md` to:

- name `project-detail.html` as the project layout;
- direct new projects to the Project Detail author guide;
- document the Markdown and typed-directive boundary;
- remove Bootstrap-era project authoring instructions.

## Validation Strategy

### Authored-source contract

Add a collection-wide source test that checks every `_projects/*.md` document for:

- `layout: project-detail`;
- no raw structural HTML;
- no author Liquid;
- no `project-post` references;
- valid Project Intro/Main Content structure;
- captioned standalone images;
- punctuation-free media titles;
- registered typed directives only.

### Rendered collection contract

Build the site and verify every project output:

- uses the modern Project Detail shell;
- includes the approved default Hero asset unless explicitly overridden in the future;
- omits Bootstrap, jQuery, Popper, legacy project styles, and raw directive markers;
- preserves its expected media sources and external destinations;
- renders navigation only when the generated chapter contract enables it.

Add focused assertions for AR Domino and DRSSTC video normalization, Programming Languages Trend link placement, and selected short projects without forced navigation.

### Legacy cleanup contract

Add or update architecture tests that fail while production files still reference `project-post`, the legacy project layout, Bootstrap, jQuery, Popper, or project-only showcase styles. Verify the final generated site contains no legacy project shell artifacts.

### Full verification

Run:

- all Project Detail Ruby tests;
- the Project Detail rendering integration suite;
- modern page regression tests;
- JavaScript tests;
- a production Jekyll build;
- `git diff --check`;
- a final repository reference scan for deleted legacy paths and dependencies.

## Implementation Sequence

1. Add collection-wide failing tests for the final authoring and rendering contracts.
2. Migrate projects in small groups, running source and render tests after each group.
3. Proofread each project while its structure is being migrated.
4. Update permanent documentation and the approved instruction files.
5. Run a reachability audit and delete only unreferenced legacy files and dependencies.
6. Run the complete verification matrix on the cleaned repository.

No legacy file is deleted before the migrated collection builds successfully, so cleanup remains separable from content conversion and failures can be localized.
