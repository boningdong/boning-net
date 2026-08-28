const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');

const modulePath = path.resolve(__dirname, '../../assets/js/pages/project-detail.js');

test('Corner Navigation appears only when Main Content reaches 70 percent of the viewport', () => {
  const { shouldRevealCorner } = require(modulePath);

  assert.equal(shouldRevealCorner(701, 1000), false);
  assert.equal(shouldRevealCorner(700, 1000), true);
  assert.equal(shouldRevealCorner(-20, 1000), true);
});

test('active chapter selects the last heading above the reading line', () => {
  const { activeChapterIndex } = require(modulePath);

  assert.equal(activeChapterIndex([120, 620, 1120], 1000), 0);
  assert.equal(activeChapterIndex([-500, 120, 620], 1000), 1);
  assert.equal(activeChapterIndex([-1000, -400, 120], 1000), 2);
});

test('Corner Navigation Escape handler closes and prevents the native fallback', () => {
  const { handleCornerDialogKeydown } = require(modulePath);
  let prevented = false;
  let restoreFocus;

  const handled = handleCornerDialogKeydown({
    key: 'Escape',
    preventDefault() { prevented = true; }
  }, (nextRestoreFocus) => { restoreFocus = nextRestoreFocus; });

  assert.equal(handled, true);
  assert.equal(prevented, true);
  assert.equal(restoreFocus, true);
  assert.equal(handleCornerDialogKeydown({ key: 'Enter' }, () => {}), false);
});

test('project chapter scrolling disables animation for reduced motion', () => {
  const { chapterScrollBehavior } = require(modulePath);

  assert.equal(chapterScrollBehavior(true), 'auto');
  assert.equal(chapterScrollBehavior(false), 'smooth');
});
