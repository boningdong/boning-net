# Global Surface and Rhythm Tuning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add opt-in global surface controls and shared spacing rhythm controls to the interactive homepage mock without overwriting its calibrated local defaults.

**Architecture:** Keep the visual mock as a single self-contained HTML document. Add global CSS custom properties and section adapters for rendering, a small JavaScript binding registry for global/local control state, and extend the existing persistence payload so local overrides survive link and unlink cycles.

**Tech Stack:** HTML, CSS custom properties, vanilla JavaScript, Node.js built-in test runner, in-app Browser visual verification.

## Global Constraints

- Modify the interactive mock only; do not change production Jekyll templates, Sass, or JavaScript.
- Preserve Navigation defaults of `46px` height, `36%` opacity, and `8%` shadow strength when surface properties are locally unlinked.
- Preserve Hero defaults of `38px` title size and weight `480`.
- Surface properties link independently; switching a property between local and global must not erase its local value.
- Card spacing and section spacing are globally linked by default; surface properties are locally controlled by default.
- The transparent top-of-page Navigation state must remain transparent.
- Notes use dark-surface adapters rather than raw light-surface RGB values.
- Do not stage or commit `.superpowers/`; it is an existing untracked visual-design workspace.

---

### Task 1: Add a Static Contract Test for the Global System

**Files:**
- Create: `.superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.contract.test.mjs`
- Test: `.superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.contract.test.mjs`

**Interfaces:**
- Consumes: `homepage-mock-v3.html` as UTF-8 text.
- Produces: A Node test contract for required global tokens, control IDs, linkage attributes, and state functions.

- [ ] **Step 1: Write the failing structural contract**

```js
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const html = readFileSync(new URL('./homepage-mock-v3.html', import.meta.url), 'utf8');

test('declares global surface and rhythm tokens', () => {
  for (const token of [
    '--global-surface-opacity',
    '--global-surface-blur',
    '--global-edge-highlight',
    '--global-shadow-strength',
    '--global-corner-radius',
    '--global-hover-lift',
    '--global-card-gap',
    '--global-card-padding',
    '--global-section-gap'
  ]) assert.match(html, new RegExp(`${token}:`));
});

test('renders global controls with independent linkage checkboxes', () => {
  for (const id of [
    'global-tint', 'global-opacity', 'global-blur', 'global-highlight',
    'global-shadow', 'global-radius', 'global-lift', 'global-card-gap',
    'global-card-padding', 'global-section-gap'
  ]) assert.match(html, new RegExp(`id="${id}"`));

  for (const key of [
    'tint', 'opacity', 'blur', 'highlight', 'shadow',
    'radius', 'lift', 'card-gap', 'card-padding', 'section-gap'
  ]) assert.match(html, new RegExp(`data-global-link="${key}"`));
});

test('defines linkage and persistence functions', () => {
  for (const fn of [
    'setGlobalDesignVariable',
    'toggleGlobalBinding',
    'syncGlobalBindings',
    'captureLocalOverrides',
    'restoreLocalOverrides'
  ]) assert.match(html, new RegExp(`function ${fn}\\(`));
});
```

- [ ] **Step 2: Run the contract and verify it fails**

Run:

```bash
node --test .superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.contract.test.mjs
```

Expected: FAIL because `--global-surface-opacity` and the global controls do not exist yet.

---

### Task 2: Add Global Tokens, Section Adapters, and Panel Controls

**Files:**
- Modify: `.superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.html:11-297`
- Modify: `.superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.html:451-490`
- Test: `.superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.contract.test.mjs`

**Interfaces:**
- Consumes: Existing `--nav-*`, `--glass*`, `--card-*`, and spacing declarations.
- Produces: Global CSS tokens, `body.global-*` adapter classes, controls whose IDs match Task 1, and `data-global-link` checkboxes.

- [ ] **Step 1: Add the global token defaults to `:root`**

```css
--global-surface-opacity: .48;
--global-surface-blur: 18px;
--global-edge-highlight: .42;
--global-shadow-strength: .1;
--global-corner-radius: 26px;
--global-hover-lift: 5px;
--global-card-gap: 24px;
--global-card-padding: 28px;
--global-section-gap: 112px;
--global-surface-rgb: 226 237 240;
```

- [ ] **Step 2: Add surface adapters that only activate for linked properties**

Use one body class per linked property so linking Edge highlight does not implicitly link opacity or blur.

```css
body.global-opacity .experience-card,
body.global-opacity .skill-card,
body.global-opacity.caption-inset .portfolio-meta,
body.global-opacity.caption-split .portfolio-item,
body.global-opacity.caption-split .portfolio-meta { --surface-opacity: var(--global-surface-opacity); }

body.global-radius .experience-card,
body.global-radius .skill-card,
body.global-radius .note-card,
body.global-radius .portfolio-item,
body.global-radius .portfolio-visual { border-radius: var(--global-corner-radius); }

body.global-lift .experience-card:hover,
body.global-lift .skill-card:hover,
body.global-lift .note-card:hover,
body.global-lift.caption-split .portfolio-item:hover { transform: translateY(calc(-1 * var(--global-hover-lift))); }
```

Refactor each applicable surface rule to consume section-level `--surface-*` variables. Notes derive edge and surface colors for their dark background while sharing the global strength values.

- [ ] **Step 3: Map rhythm tokens by relationship**

```css
body.global-card-gap .experience-grid,
body.global-card-gap .layout-grid,
body.global-card-gap .notes-grid { gap: var(--global-card-gap); }

body.global-card-gap .layout-bento,
body.global-card-gap .layout-triptych { gap: calc(var(--global-card-gap) * .75); }

body.global-card-gap .layout-rail { gap: calc(var(--global-card-gap) * 1.25); }

body.global-card-padding .experience-copy,
body.global-card-padding .skill-card,
body.global-card-padding .note-card { padding: var(--global-card-padding); }

body.global-section-gap .about,
body.global-section-gap .experience,
body.global-section-gap .work,
body.global-section-gap .skills,
body.global-section-gap .notes { padding-block: var(--global-section-gap); }
```

The Hero and Navigation are intentionally absent from the section-gap selector.

- [ ] **Step 4: Add the `Global design system` panel group**

Add the group immediately after Reset and Save default. Each row contains a label, output, slider or tint choice, and a checkbox with an accessible label such as `Apply Edge highlight globally`. Surface checkboxes start unchecked. `Card spacing` and `Section spacing` start checked.

- [ ] **Step 5: Run the token and markup portions of the contract**

Run:

```bash
node --test --test-name-pattern="tokens|controls" .superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.contract.test.mjs
```

Expected: PASS for token and control tests; the function test still fails.

---

### Task 3: Implement Independent Global/Local Binding State

**Files:**
- Modify: `.superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.html:576-678`
- Test: `.superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.contract.test.mjs`

**Interfaces:**
- Consumes: Global control IDs and `data-global-link` checkboxes from Task 2.
- Produces: `setGlobalDesignVariable(property, value, outputId, outputValue)`, `toggleGlobalBinding(key, checked)`, `syncGlobalBindings()`, `captureLocalOverrides()`, and `restoreLocalOverrides(overrides)`.

- [ ] **Step 1: Define the binding registry**

```js
const globalBindingRegistry = {
  tint: { className: 'global-tint', localControls: ['nav-tint-options'] },
  opacity: { className: 'global-opacity', localControls: ['nav-opacity', 'caption-opacity'] },
  blur: { className: 'global-blur', localControls: ['nav-blur', 'caption-blur'] },
  highlight: { className: 'global-highlight', localControls: ['nav-highlight'] },
  shadow: { className: 'global-shadow', localControls: ['nav-shadow'] },
  radius: { className: 'global-radius', localControls: ['card-radius'] },
  lift: { className: 'global-lift', localControls: [] },
  'card-gap': { className: 'global-card-gap', localControls: [] },
  'card-padding': { className: 'global-card-padding', localControls: ['info-padding'] },
  'section-gap': { className: 'global-section-gap', localControls: [] }
};
```

- [ ] **Step 2: Implement linkage without deleting local values**

Add the following functions, using `.global-state` as the visible status marker inside each local control group:

```js
function setGlobalDesignVariable(property, value, outputId, outputValue) {
  document.documentElement.style.setProperty(property, value);
  document.getElementById(outputId).value = outputValue;
}

function captureLocalOverrides() {
  const ids = Object.values(globalBindingRegistry)
    .flatMap(binding => binding.localControls);
  return Object.fromEntries(ids.map(id => {
    const control = document.getElementById(id);
    if (!control) return [id, null];
    if (control.matches('input')) return [id, control.value];
    const selected = control.querySelector('.preview-option.active');
    return [id, selected ? selected.textContent.trim() : null];
  }));
}

function restoreLocalOverrides(overrides) {
  Object.entries(overrides || {}).forEach(([id, value]) => {
    const control = document.getElementById(id);
    if (!control || value == null) return;
    if (control.matches('input')) {
      control.value = value;
      control.dispatchEvent(new Event('input', { bubbles: true }));
      return;
    }
    const option = Array.from(control.querySelectorAll('.preview-option'))
      .find(button => button.textContent.trim() === value);
    if (option) option.click();
  });
}

function syncGlobalBindings() {
  document.querySelectorAll('[data-global-link]').forEach(checkbox => {
    const key = checkbox.dataset.globalLink;
    const binding = globalBindingRegistry[key];
    if (!binding) return;
    document.body.classList.toggle(binding.className, checkbox.checked);
    binding.localControls.forEach(id => {
      const control = document.getElementById(id);
      if (!control) return;
      const inputs = control.matches('input,button') ? [control] : Array.from(control.querySelectorAll('input,button'));
      inputs.forEach(input => {
        input.disabled = checkbox.checked;
        input.setAttribute('aria-disabled', String(checkbox.checked));
      });
      const group = control.closest('.range-control, .preview-block');
      if (!group) return;
      let marker = group.querySelector('.global-state');
      if (!marker) {
        marker = document.createElement('span');
        marker.className = 'global-state';
        marker.textContent = 'Global';
        group.appendChild(marker);
      }
      marker.hidden = !checkbox.checked;
    });
  });
}

function toggleGlobalBinding(key, checked) {
  const checkbox = document.querySelector(`[data-global-link="${key}"]`);
  if (checkbox) checkbox.checked = checked;
  syncGlobalBindings();
}
```

These functions toggle only the registry class for the supplied key and never write global values into local range inputs.

- [ ] **Step 3: Extend state capture and restoration**

Extend `captureTuningState()` with:

```js
globalLinks: Object.fromEntries(
  Array.from(document.querySelectorAll('[data-global-link]'))
    .map(input => [input.dataset.globalLink, input.checked])
),
localOverrides: captureLocalOverrides()
```

In `applyTuningState(state)`, restore ranges and option buttons first, then restore `localOverrides`, checkbox values, and finally call `syncGlobalBindings()` so disabled states and adapter classes reflect the restored configuration.

- [ ] **Step 4: Ensure Reset restores hardcoded checkbox states**

Capture `hardCodedTuning` only after the global panel exists and the default checked states have been applied. `resetTuning()` must clear local storage, restore the complete hardcoded object, and return `Card spacing` and `Section spacing` to linked state.

- [ ] **Step 5: Run the complete contract**

Run:

```bash
node --test .superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.contract.test.mjs
```

Expected: all three contract tests PASS.

---

### Task 4: Verify Interaction, Persistence, and Responsive Rendering

**Files:**
- Modify if verification finds a defect: `.superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.html`
- Test: `.superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.contract.test.mjs`

**Interfaces:**
- Consumes: Completed global tuning implementation.
- Produces: A visually checked mock with a clean console and deterministic Save/Reset behavior.

- [ ] **Step 1: Sync the canonical mock to the active visual-companion content directory**

Copy `homepage-mock-v3.html`, its contract test, and existing assets to the current companion session, then touch the HTML file so it becomes the served screen.

- [ ] **Step 2: Verify global/local behavior at desktop size**

At `1440 × 900`, confirm:

- Top Navigation remains transparent.
- Linking Edge highlight changes Navigation, Experiences, Work glass surfaces, Skills, and the dark Notes adapter.
- Linking Card spacing changes each layout according to `1.0`, `0.75`, and `1.25` multipliers.
- Unlinking a property re-enables local controls and restores the last local value.
- Relinking and unlinking again preserves that value.

- [ ] **Step 3: Verify persistence**

Choose distinctive global values, unlink at least one property, change its local value, click Save default, refresh, and confirm all global values, link states, and the local override return. Click Reset, refresh again, and confirm the hardcoded defaults return.

- [ ] **Step 4: Verify responsive layout**

At `390 × 844`, confirm the page and tuning panel have no horizontal overflow, Navigation keeps its mobile geometry, global gap multipliers remain ordered, and controls remain reachable.

- [ ] **Step 5: Run final health checks**

Run:

```bash
node --test .superpowers/brainstorm/17624-1786761814/content/homepage-mock-v3.contract.test.mjs
git diff --check
```

In the browser, confirm all images have nonzero `naturalWidth`, `document.fonts.status` is `loaded`, and the console contains no errors.

- [ ] **Step 6: Leave the deliverable tab at the desktop Hero**

Reset the tuning state, return to `1440 × 900`, scroll to the Hero, and finalize the updated visual-companion tab. Do not modify or stage unrelated `.superpowers/` or `_sass/design/` files.
