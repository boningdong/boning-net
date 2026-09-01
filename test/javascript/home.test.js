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
