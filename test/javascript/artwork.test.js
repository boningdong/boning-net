const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const modulePath = path.resolve(__dirname, '../../assets/js/pages/artwork.js');

test('artwork filtering matches exact media and projects visible state', () => {
  assert.equal(fs.existsSync(modulePath), true, 'artwork module should exist');
  const { createFilterState, matchesMedium } = require(modulePath);

  assert.equal(matchesMedium('pencil', 'all'), true);
  assert.equal(matchesMedium('pencil', 'pencil'), true);
  assert.equal(matchesMedium('charcoal', 'pencil'), false);
  assert.deepEqual(createFilterState(['pencil', 'charcoal', 'pencil'], 'pencil'), {
    visible: [true, false, true],
    count: 2
  });
});

test('artwork result labels use correct singular and plural forms', () => {
  assert.equal(fs.existsSync(modulePath), true, 'artwork module should exist');
  const { formatArtworkCount } = require(modulePath);

  assert.equal(formatArtworkCount(1), '1 work');
  assert.equal(formatArtworkCount(10), '10 works');
});

test('viewer content uses the full-resolution source and complete text', () => {
  assert.equal(fs.existsSync(modulePath), true, 'artwork module should exist');
  const { createViewerContent } = require(modulePath);

  assert.deepEqual(createViewerContent({
    full: '/assets/img/artwork/snow_scene.jpg',
    title: 'Snow Scene',
    meta: 'Pencil · 2020'
  }), {
    src: '/assets/img/artwork/snow_scene.jpg',
    alt: 'Snow Scene',
    title: 'Snow Scene',
    meta: 'Pencil · 2020'
  });
});

test('rail motion stops for reduced motion or interaction and wraps seamlessly', () => {
  assert.equal(fs.existsSync(modulePath), true, 'artwork module should exist');
  const { shouldAutoDrift, wrapRailPosition } = require(modulePath);

  assert.equal(shouldAutoDrift({ reducedMotion: true, paused: false }), false);
  assert.equal(shouldAutoDrift({ reducedMotion: false, paused: true }), false);
  assert.equal(shouldAutoDrift({ reducedMotion: false, paused: false }), true);
  assert.equal(wrapRailPosition(420, 400), 20);
  assert.equal(wrapRailPosition(180, 400), 180);
  assert.equal(wrapRailPosition(40, 0), 40);
});
