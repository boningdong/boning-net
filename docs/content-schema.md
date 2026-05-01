# Content Schema

This site is driven by Jekyll collections and data files. Use these fields when
adding or editing content so shared includes can render pages consistently.

## Projects

Location: `_projects/*.md`

Required frontmatter:

```yaml
---
layout: project-post
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
banner: /assets/img/projects/example_banner.jpg
```

Notes:
- `tags` must match `tag-id` values from `_tags/*.md`.
- `cover` is used on the projects index card.
- `banner` is used on the project detail hero. If omitted, the default projects banner is used.

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
- If `end-date` is omitted, the page displays `Now`.

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
- `tag-id` is the stable value referenced by project frontmatter.
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

`work_showcases` drives the homepage artwork/projects toggle:

```yaml
work_showcases:
  artwork:
    button_label: Artwork
    quote: Quote shown above the images.
    href: /artwork.html
    cta: More Artwork
    images:
      - /assets/img/index/example.jpg
```
