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

test('horizontal masonry assigns chronological items across columns before starting the next visual row', () => {
  const { createHorizontalMasonryLayout } = require(modulePath);

  assert.deepEqual(createHorizontalMasonryLayout([100, 120, 80, 90, 70], 3, 20), {
    positions: [
      { column: 0, top: 0 },
      { column: 1, top: 0 },
      { column: 2, top: 0 },
      { column: 0, top: 120 },
      { column: 1, top: 140 }
    ],
    height: 210
  });
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

test('viewer recognizes Escape as its keyboard close command', () => {
  assert.equal(fs.existsSync(modulePath), true, 'artwork module should exist');
  const { isViewerCloseKey } = require(modulePath);

  assert.equal(isViewerCloseKey('Escape'), true);
  assert.equal(isViewerCloseKey('Enter'), false);
});

test('rail motion stops for reduced motion or interaction and wraps seamlessly', () => {
  assert.equal(fs.existsSync(modulePath), true, 'artwork module should exist');
  const { measureRailCycle, normalizeManualRailPosition, shouldAutoDrift, wrapRailPosition } = require(modulePath);

  assert.equal(shouldAutoDrift({ reducedMotion: true, paused: false }), false);
  assert.equal(shouldAutoDrift({ reducedMotion: false, paused: true }), false);
  assert.equal(shouldAutoDrift({ reducedMotion: false, paused: false }), true);
  assert.equal(wrapRailPosition(420, 400), 20);
  assert.equal(wrapRailPosition(180, 400), 180);
  assert.equal(wrapRailPosition(40, 0), 40);
  assert.equal(wrapRailPosition(820, 400, 400), 420);
  assert.equal(wrapRailPosition(380, 400, 400), 780);
  assert.equal(normalizeManualRailPosition(380, 400, 400, true), 780);
  assert.equal(normalizeManualRailPosition(380, 400, 400, false), 380);
  assert.equal(measureRailCycle(160, 960), 800);
});

test('rail initialization waits for settled images but accepts failed images', () => {
  const { areRailImagesSettled } = require(modulePath);

  assert.equal(areRailImagesSettled([{ complete: true, naturalWidth: 400 }, { complete: false, naturalWidth: 0 }]), false);
  assert.equal(areRailImagesSettled([{ complete: true, naturalWidth: 400 }, { complete: true, naturalWidth: 0 }]), true);
});


function createRailHarness() {
  const vm = require('node:vm');
  const listeners = {};
  let nextFrame;
  let now = 0;
  let scrollLeft = 0;
  const rail = {
    clientWidth: 390,
    get scrollLeft() { return scrollLeft; },
    set scrollLeft(value) { scrollLeft = Math.round(value); },
    querySelector: () => ({
      querySelector: selector => ({ offsetLeft: selector.includes('previous') ? 0 : selector.includes('next') ? 2000 : 1000 }),
      querySelectorAll: () => []
    }),
    addEventListener: (name, callback) => { listeners[name] = callback; },
    setAttribute() {}, removeAttribute() {}, contains: () => false
  };
  const root = { querySelector: selector => selector === '[data-artwork-rail]' ? rail : null, querySelectorAll: () => [] };
  const document = { readyState: 'complete', querySelector: selector => selector === '[data-artwork-page]' ? root : null };
  const window = { requestAnimationFrame: callback => { nextFrame = callback; },
    matchMedia: () => ({ matches: false }), addEventListener() {} };
  vm.runInNewContext(fs.readFileSync(modulePath, 'utf8'), { window, document, performance: { now: () => now } });
  function frame(time) { now = time; nextFrame(time); }
  frame(1);
  return { rail, listeners, frame };
}

test('rail accumulates subpixel drift even when browser rounds scrollLeft', () => {
  const { rail, frame } = createRailHarness();
  for (let time = 17; time < 1000; time += 16) frame(time);
  assert.ok(rail.scrollLeft >= 1017);
});

test('touch hover does not latch pause and a held touch pauses until release', () => {
  const { rail, listeners, frame } = createRailHarness();
  listeners.pointerenter({ pointerType: 'touch' });
  frame(51);
  assert.ok(rail.scrollLeft > 1000);
  listeners.touchstart({ touches: [{}] });
  const held = rail.scrollLeft;
  frame(3000);
  assert.equal(rail.scrollLeft, held);
  listeners.touchend({ touches: [] });
  frame(4000);
  assert.equal(rail.scrollLeft, held);
  frame(4900);
  assert.ok(rail.scrollLeft > held);
});

test('manual momentum extends pause and autoplay resumes from the manual position', () => {
  const { rail, listeners, frame } = createRailHarness();
  listeners.touchstart({ touches: [{}] });
  listeners.touchend({ touches: [] });
  frame(1500);
  rail.scrollLeft = 1250;
  listeners.scroll();
  frame(2500);
  assert.equal(rail.scrollLeft, 1250);
  frame(3400);
  assert.ok(rail.scrollLeft > 1250 && rail.scrollLeft < 1260);
});
