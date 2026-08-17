# Frontend architecture

The modern homepage, Projects, Artwork, and Experiences pages use Jekyll collections, data files, Liquid includes, one SCSS entry point, and dependency-free JavaScript.

## Boundaries

- `foundation` contains styling inputs and primitives with no specific UI identity: variables, mixins, base element rules, and layout rhythm.
- `components` contains named UI reused across modern pages: navigation, cards, and footer.
- `pages` contains composition and behavior unique to one page.

Promote a page rule to `components` only after another page actually reuses the same markup and behavior.

## Jekyll structure

- `_layouts/modern.html` is the dependency-free document shell for modern pages.
- `_layouts/default.html` remains the legacy shell for project-detail pages until they are redesigned.
- `_includes/components` contains reusable Liquid UI.
- `_includes/pages/<page>` contains page-specific Liquid sections.
- `_data` contains navigation, social links, and homepage data.
- Collections and their frontmatter remain the source of project, artwork, experience, and tag content.

## Assets

- `assets/css/main.scss` is the only public modern CSS entry and composes `_sass/foundation`, `_sass/components`, and `_sass/pages`.
- `assets/js/components` contains controllers for reusable UI.
- `assets/js/pages` contains page-specific controllers.
- Liquid generates content and URLs at build time; JavaScript manages interaction state only.

## Dependency boundary

Modern pages do not load Bootstrap, jQuery, or Popper.

Legacy dependencies stay isolated to the legacy layout until all dependent pages have migrated.
