# Global Surface and Rhythm Tuning Design

## Goal

Extend the interactive homepage mock with a small global design system that keeps surface materials and spacing rhythm visually consistent across Navigation, Experiences, Work, Skills, and Notes while preserving useful section-specific geometry.

The system controls shared design language rather than forcing every component to use identical raw CSS values.

## Scope

This change applies only to the interactive design mock. It does not modify the production Jekyll site.

The existing Save default and Reset behavior must include the new global values, global-application choices, and local overrides.

## Tuning Panel Structure

Add a `Global design system` section near the top of the tuning panel with two groups.

### Surface

- Tint
- Surface opacity
- Surface blur
- Edge highlight
- Shadow strength
- Corner radius
- Hover lift

### Rhythm

- Card spacing
- Card padding
- Section spacing

Each control has an `Apply globally` checkbox. Global application is disabled by default for surface properties so the current calibrated Navigation and card values remain unchanged until the user deliberately links them. Card spacing and section spacing are linked by default. A property can be unlinked independently without affecting the other global properties.

## Global and Local Behavior

When a property's `Apply globally` checkbox is enabled:

- The global value is the source of truth.
- Relevant local sliders remain visible so the relationship is understandable, but they are disabled and display a `Global` state.
- Changing the global value updates every applicable section immediately.

When the checkbox is disabled:

- Each section restores its last local value for that property.
- Local sliders become editable again.
- Re-enabling the checkbox does not destroy the stored local value; it only makes the global value authoritative again.

Section-specific structural controls remain local and never receive an `Apply globally` checkbox. These include navigation height and horizontal padding, hero typography and composition, caption inset, footer height, gradient reach, image edge blend, work layout, and information scale.

## Surface Mapping

Global values express perceived material strength. Each section maps them to an appropriate implementation for its background.

| Section | Global surface behavior |
| --- | --- |
| Navigation | Applies after the scroll-triggered surface appears; the top-of-page transparent state remains unchanged. |
| Experiences | Uses the global light-surface tint, opacity, blur, edge, shadow, radius, and lift. |
| Work | Applies to Inset Glass and Split Card surfaces. Image Caption keeps its gradient treatment but inherits radius, shadow, and lift. |
| Skills | Uses the same light-surface material as Experiences. |
| Notes | Uses perceptually equivalent dark-surface values; tint and edge colors are derived for contrast instead of copying light RGB values. |

The tuning panel itself is excluded so adjusting the system never makes its own controls unreadable.

## Rhythm Mapping

Spacing uses a shared base rhythm rather than one fixed gap everywhere.

| Relationship | Multiplier | Examples |
| --- | ---: | --- |
| Standard card grid | `1.0` | Experiences, Grid, Notes |
| Composed or nested layout | `0.75` | Bento and Triptych internal gaps |
| Tight repeated elements | `0.5` | Skill chips and closely related micro-elements |
| Loose horizontal sequence | `1.25` | Rail spacing when additional separation improves scanning |

`Card spacing` controls the base rhythm. Derived values should remain whole pixels and be clamped so responsive layouts do not overflow.

`Card padding` applies to text-bearing cards but not to image crop geometry or navigation padding. `Section spacing` controls vertical distance between major homepage sections independently from card gaps.

## Defaults

- Global surface tint: Ice
- Global opacity: 48%
- Global blur: 18px
- Global edge highlight: 42%
- Global shadow strength: 10%
- Global corner radius: 26px
- Global hover lift: 5px
- Global card spacing: 24px
- Global card padding: 28px
- Global section spacing: 112px

Existing navigation hardcoded defaults remain `46px` height, `36%` opacity, and `8%` shadow strength when the corresponding material properties are locally unlinked. Existing hero defaults remain `38px` and weight `480`.

## Persistence and Reset

`Save default` captures:

- Global slider and tint values
- Each `Apply globally` checkbox state
- Every retained local override
- Existing navigation, hero, card, layout, and work-tab choices

Refreshing restores the complete saved state. `Reset` clears the saved state and restores all hardcoded global values, checkbox states, local overrides, and existing mock defaults.

## Responsive Behavior

- Global values apply on desktop and mobile.
- Spacing multipliers may be reduced on narrow screens when required to prevent overflow, but their relative hierarchy remains intact.
- Navigation keeps its existing mobile-specific geometry.
- The tuning panel must remain usable without covering the full viewport.

## Verification

- Toggle every global property on and off and confirm only applicable local controls change state.
- Confirm local values survive an unlink, relink, and second unlink cycle.
- Confirm global changes affect Navigation, Experiences, Work, Skills, and Notes according to the mapping table.
- Confirm the transparent top navigation remains transparent even when global surfaces are enabled.
- Confirm Save default, refresh restoration, and Reset include global and local state.
- Confirm desktop and mobile layouts have no horizontal overflow.
- Confirm all images and fonts load and the browser console contains no errors.
