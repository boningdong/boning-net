const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const modulePath = path.resolve(__dirname, '../../assets/js/pages/home.js');

test('home tabs wrap and support Home and End keys', () => {
  assert.equal(fs.existsSync(modulePath), true, 'home module should exist');
  const { nextTabIndex } = require(modulePath);

  assert.equal(nextTabIndex(2, 'ArrowRight', 3), 0);
  assert.equal(nextTabIndex(0, 'ArrowLeft', 3), 2);
  assert.equal(nextTabIndex(1, 'Home', 3), 0);
  assert.equal(nextTabIndex(1, 'End', 3), 2);
  assert.equal(nextTabIndex(1, 'Space', 3), 1);
});

test('selecting Artwork exposes only its panel and keyboard target', () => {
  const { createWorkState } = require(modulePath);

  assert.deepEqual(createWorkState(2, 1), [
    { selected: false, tabIndex: -1, hidden: true },
    { selected: true, tabIndex: 0, hidden: false }
  ]);
});


test('hero freezes entry height across toolbar changes and adapts to width changes', () => {
  const vm = require('node:vm');
  const listeners = {};
  const values = {};
  const hero = { style: { setProperty: (key, value) => { values[key] = value; } } };
  const window = { innerWidth: 390, innerHeight: 660,
    visualViewport: { height: 660, scale: 1 },
    matchMedia: () => ({ matches: true }),
    addEventListener: (name, callback) => { listeners[name] = callback; } };
  const document = { readyState: 'complete', querySelector: selector => selector === '.home-hero' ? hero : null };
  vm.runInNewContext(fs.readFileSync(modulePath, 'utf8'), { window, document });
  assert.equal(values['--home-viewport-height'], '660px');
  window.innerHeight = window.visualViewport.height = 740;
  listeners.resize();
  assert.equal(values['--home-viewport-height'], '660px');
  window.innerWidth = 844;
  window.innerHeight = window.visualViewport.height = 390;
  listeners.resize();
  assert.equal(values['--home-viewport-height'], '390px');
});
