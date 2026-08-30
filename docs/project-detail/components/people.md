# People

## Purpose

Use `people` to place a validated group of contributors whose data lives once in project frontmatter.

## Syntax

Define the group beneath the top-level `people` mapping:

```yaml
people:
  team:
    - name: Byron Aguilar
      role: Computer Engineer
      image: /assets/img/people/byron.png
      url: https://www.linkedin.com/in/byron-aguilar-a139057b/
    - name: Ada Lovelace
      role: Software Engineer
      image: /assets/img/people/ada.png
```

Place it with an empty directive body:

```markdown
::: people source=team
:::
```

## Options

`source` is required and is the only accepted option. It names a key directly beneath the document's top-level `people` mapping. Quote it when the key contains whitespace, for example `source="project team"`.

## Content Contract

The resolved source must be a nonempty array. Every entry must be a mapping with nonblank string values for `name`, `role`, and `image`. `url` is optional and must be a nonblank safe URL when present. No other entry keys are accepted. The directive body must be empty.

## Behavior

People render in frontmatter order. A desktop row supports three columns, layouts below 900px use two columns, and layouts at 640px and below use one column. Images use square cropped frames. A person with `url` becomes one linked card; a person without it remains an unlinked card with no empty destination.

## Generated Semantics

The group renders as a `ul` with one `li` per person. Linked entries use one coherent anchor; unlinked entries use an `article` with a heading and paragraph. Names and roles remain text. Image alt text is generated as `Portrait of {name}`.

## Validation

The build fails for a missing or blank `source`, unknown option, nonempty body, missing source, non-mapping `people` data, non-array or empty group, non-mapping entry, unknown entry key, missing required key, blank/wrong-type value, or unsafe URL.

```text
_projects/example.md:44: people source "team" was not found
```

## Examples

Multiple named groups can share the same schema:

```yaml
people:
  team:
    - name: Ada Lovelace
      role: Software Engineer
      image: /assets/img/people/ada.png
  advisors:
    - name: Grace Hopper
      role: Technical Advisor
      image: /assets/img/people/grace.png
```

```markdown
# Team

::: people source=team
:::

## Advisors

::: people source=advisors
:::
```

## Related Components

Use a [Standalone Figure](figure.md) for images that are not structured contributor records. The [migration guide](../migration.md#5-move-repeated-people-data-to-frontmatter) shows how to replace legacy team-card HTML.
