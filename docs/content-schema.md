# Content Schema

This site is driven by Jekyll collections and data files. Use these fields when
adding or editing content so shared includes can render pages consistently.

## Projects

Location: `_projects/*.md`

Required frontmatter:

```yaml
---
layout: project-detail
title: Project title
subtitle: Short project description
date: 2024-01-01
cover: /assets/img/projects/example_cover.jpg
tags:
  - software
---
```

Optional frontmatter:

```yaml
external-link: https://github.com/example/project
hero: /assets/img/projects/example_hero.png
hero_alt: Description of the project hero image
```

Notes:
- `tags` must match `tag-id` values from `_tags/*.md`.
- `cover` is used on the projects index card.
- `hero` overrides the Project Detail hero image. If it is omitted, the Hero uses `site.project_detail.default_hero`.
- `hero_alt` describes the hero image. Omitted, empty, or whitespace-only values use the project title followed by ` project illustration`; supplied values are trimmed and then used exactly.

Every project uses the [Project Detail author guide](project-detail/README.md) for its Markdown and component contract, including Intro placement, H1 chapters, navigation options, typed directives, structured people data, Markdown figures, and the raw HTML policy.

## Artwork

Location: `_artwork/*.md`

Required frontmatter:

```yaml
---
location: /assets/img/artwork/example.jpg
cover: /assets/img/artwork/covers/example.jpg
title: Artwork title
date: 2024-01-01
tags:
  - pencil
---
```

Notes:
- `location` is the full-size modal image.
- `cover` is the masonry grid thumbnail.
- `tags` must match `tag-id` values from `_tags/*.md`; the first tag is displayed as the artwork medium.
- Artwork filters are generated from the shared tag registry and only include tags used by at least one artwork. Adding artwork with an existing tag requires no template changes; define a new `_tags/*.md` entry only when introducing a new medium.

## Experiences

Location: `_experiences/*.md`

Required frontmatter:

```yaml
---
company: Company
job-title: Role title
start-date: 2024-01-01
logo: /assets/img/experiences/company.png
shown: true
---
```

Optional frontmatter:

```yaml
end-date: 2024-12-01
```

Notes:
- `shown: true` controls whether the entry appears on the experiences page.
- The experiences page filters to `shown: true` and sorts entries by `start-date` in descending order.
- If `end-date` is omitted, the page displays `Now`.
- The Markdown body is rendered as the role detail and remains readable when JavaScript is unavailable.

## Education Data

Location: `_data/education.yml`

Required fields:

```yaml
- institution: UC Santa Barbara
  mark: UCSB
  degree: Master’s degree
  field: Computer Engineering
  period: "2021"
  details: []
```

Notes:
- `mark` is the short institution label shown in the card's brand mark.
- `period` is display text and may be a single year or a range.
- `details` is an array of optional credential notes such as GPA or student organizations.
- Education entries are rendered in data-file order and do not create detail pages or permalinks.

## Tags

Location: `_tags/*.md`

Required frontmatter:

```yaml
---
tag-id: software
tag-title: Software
tag-color:
  top: "#123456"
  bottom: "#654321"
---
```

Notes:
- `tag-id` is the stable value referenced by project and artwork frontmatter.
- Project and Artwork filters each show only registry entries used by their own collection.
- `tag-color.top` and `tag-color.bottom` are used by the shared tag badge include.

## Homepage Data

Location: `_data/home.yml`

`featured_experiences` drives the homepage experience cards:

```yaml
featured_experiences:
  - company: Company
    title: Role title
    description: Short homepage description.
    logo: /assets/img/index/company.png
    url: https://example.com
    cta: Visit Company
```

The homepage hero and about copy are stored in `hero` and `about`.

`selected_work` fixes the three Artwork and Project cards shown on the homepage. Each value is the collection Markdown filename without its extension, and list order maps to the feature, secondary, and tertiary card positions:

```yaml
selected_work:
  artwork:
    - snow_scene
    - the_witcher
    - scene_watercolor
  projects:
    - ar_domino
    - scopen
    - chatbot
```

Changing a collection item's date does not affect this selection. Keep exactly three valid slugs in each list.

`notes_preview` controls the temporary Notes preview. Set `enabled: false` to omit it and automatically restore three-part section numbering before deployment:

```yaml
notes_preview:
  enabled: true
  kicker: Ideas in progress
  badge: Future module
  title: Notes
  intro: Preview introduction.
  items:
    - type: Technology
      title: Sample note
      description: Placeholder summary.
      date: Sample article
```
