const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const modulePath = path.resolve(__dirname, '../../assets/js/components/navigation.js');

test('navigation surface appears only after the approved scroll threshold', () => {
  assert.equal(fs.existsSync(modulePath), true, 'navigation module should exist');
  const { shouldShowSurface } = require(modulePath);

  assert.equal(shouldShowSurface(24), false);
  assert.equal(shouldShowSurface(25), true);
});
