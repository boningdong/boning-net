const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const modulePath = path.resolve(__dirname, '../../assets/js/pages/experiences.js');

function loadExperiences() {
  assert.equal(fs.existsSync(modulePath), true, 'experiences module should exist');
  delete require.cache[modulePath];
  return require(modulePath);
}

function createClassList(initialValues = []) {
  const values = new Set(initialValues);

  return {
    contains(value) {
      return values.has(value);
    },
    toggle(value, force) {
      if (force === undefined) {
        if (values.has(value)) values.delete(value);
        else values.add(value);
      } else if (force) {
        values.add(value);
      } else {
        values.delete(value);
      }
      return values.has(value);
    }
  };
}

function createCard() {
  const label = { textContent: 'Details' };
  const panel = {
    attributes: { 'aria-hidden': 'false' },
    inert: false,
    setAttribute(name, value) {
      this.attributes[name] = value;
    },
    getAttribute(name) {
      return this.attributes[name];
    }
  };
  const listeners = {};
  const button = {
    attributes: { 'aria-expanded': 'true' },
    addEventListener(type, listener) {
      listeners[type] = listener;
    },
    click() {
      listeners.click();
    },
    getAttribute(name) {
      return this.attributes[name];
    },
    querySelector(selector) {
      return selector === '[data-experience-toggle-label]' ? label : null;
    },
    setAttribute(name, value) {
      this.attributes[name] = value;
    }
  };
  const card = {
    classList: createClassList(['is-open']),
    querySelector(selector) {
      if (selector === '[data-experience-toggle]') return button;
      if (selector === '[data-experience-details]') return panel;
      return null;
    }
  };

  return { button, card, label, panel };
}

function createRoot(cardFixtures) {
  return {
    classList: createClassList(),
    querySelectorAll(selector) {
      return selector === '[data-experience-card]' ? cardFixtures.map((fixture) => fixture.card) : [];
    }
  };
}

test('accordion enhancement initializes every work entry closed', () => {
  const { init } = loadExperiences();
  const cards = [createCard(), createCard(), createCard()];
  const root = createRoot(cards);

  init(root);

  assert.equal(root.classList.contains('is-enhanced'), true);
  cards.forEach(({ button, card, label, panel }) => {
    assert.equal(card.classList.contains('is-open'), false);
    assert.equal(button.getAttribute('aria-expanded'), 'false');
    assert.equal(panel.getAttribute('aria-hidden'), 'true');
    assert.equal(panel.inert, true);
    assert.equal(label.textContent, 'Details');
  });
});

test('accordion keeps only the most recently selected work entry open', () => {
  const { init } = loadExperiences();
  const cards = [createCard(), createCard(), createCard()];

  init(createRoot(cards));
  cards[0].button.click();
  cards[1].button.click();

  assert.equal(cards[0].card.classList.contains('is-open'), false);
  assert.equal(cards[0].button.getAttribute('aria-expanded'), 'false');
  assert.equal(cards[0].panel.getAttribute('aria-hidden'), 'true');
  assert.equal(cards[0].panel.inert, true);
  assert.equal(cards[0].label.textContent, 'Details');
  assert.equal(cards[1].card.classList.contains('is-open'), true);
  assert.equal(cards[1].button.getAttribute('aria-expanded'), 'true');
  assert.equal(cards[1].panel.getAttribute('aria-hidden'), 'false');
  assert.equal(cards[1].panel.inert, false);
  assert.equal(cards[1].label.textContent, 'Close');
  assert.equal(cards[2].card.classList.contains('is-open'), false);
});

test('selecting the open work entry closes it', () => {
  const { init } = loadExperiences();
  const cards = [createCard(), createCard()];

  init(createRoot(cards));
  cards[0].button.click();
  cards[0].button.click();

  assert.equal(cards[0].card.classList.contains('is-open'), false);
  assert.equal(cards[0].button.getAttribute('aria-expanded'), 'false');
  assert.equal(cards[0].panel.getAttribute('aria-hidden'), 'true');
  assert.equal(cards[0].label.textContent, 'Details');
});

test('accordion initialization safely handles missing roots and controls', () => {
  const { init } = loadExperiences();
  const brokenCard = { card: { classList: createClassList(), querySelector() { return null; } } };

  assert.doesNotThrow(() => init(null));
  assert.doesNotThrow(() => init(createRoot([brokenCard])));
});
