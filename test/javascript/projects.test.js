const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const modulePath = path.resolve(__dirname, '../../assets/js/pages/projects.js');

test('project tag matching supports All and exact tag membership', () => {
  assert.equal(fs.existsSync(modulePath), true, 'projects module should exist');
  const { matchesTag } = require(modulePath);

  assert.equal(matchesTag('hardware embedded pcb', 'all'), true);
  assert.equal(matchesTag('hardware embedded pcb', 'embedded'), true);
  assert.equal(matchesTag('hardware embedded pcb', 'software'), false);
});

test('collapsed filters preserve the finalized responsive control counts', () => {
  assert.equal(fs.existsSync(modulePath), true, 'projects module should exist');
  const { collapsedTagCount } = require(modulePath);

  assert.equal(collapsedTagCount(1440), 5);
  assert.equal(collapsedTagCount(800), 4);
  assert.equal(collapsedTagCount(390), 3);
});

test('project result labels use correct singular and plural forms', () => {
  assert.equal(fs.existsSync(modulePath), true, 'projects module should exist');
  const { formatResultCount } = require(modulePath);

  assert.equal(formatResultCount(1), '1 project');
  assert.equal(formatResultCount(12), '12 projects');
});
