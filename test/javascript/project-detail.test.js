const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');

const modulePath = path.resolve(__dirname, '../../assets/js/pages/project-detail.js');

function controllerElement(dataset = {}) {
  const element = new EventTarget();
  const classes = new Set();
  const attributes = new Map();

  element.dataset = dataset;
  element.hidden = false;
  element.open = false;
  element.textContent = '';
  element.classList = {
    add(value) { classes.add(value); },
    contains(value) { return classes.has(value); },
    remove(value) { classes.delete(value); }
  };
  element.focus = () => {};
  element.getAttribute = (name) => attributes.get(name) ?? null;
  element.removeAttribute = (name) => attributes.delete(name);
  element.setAttribute = (name, value) => {
    attributes.set(name, String(value));
    if (name === 'open') element.open = true;
  };

  return element;
}

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

test('production initialization uses reduced motion for a chapter-link click', () => {
  const { init } = require(modulePath);
  const root = controllerElement();
  const main = controllerElement();
  const section = controllerElement({ projectChapter: 'hardware' });
  const link = controllerElement({ projectChapterLink: 'hardware' });
  const corner = controllerElement();
  const trigger = controllerElement();
  const count = controllerElement();
  const dialog = controllerElement();
  const closeButton = controllerElement();
  const scrollCalls = [];
  const historyCalls = [];
  let mediaQuery;

  main.getBoundingClientRect = () => ({ top: 800 });
  section.getBoundingClientRect = () => ({ top: 200 });
  section.scrollIntoView = (options) => scrollCalls.push(options);
  root.querySelector = (selector) => ({
    '[data-project-main]': main,
    '[data-project-corner]': corner,
    '[data-project-corner-trigger]': trigger,
    '[data-project-corner-count]': count,
    '[data-project-corner-dialog]': dialog,
    '[data-project-corner-close]': closeButton
  })[selector] || null;
  root.querySelectorAll = (selector) => ({
    '[data-project-chapter]': [section],
    '[data-project-chapter-link]': [link]
  })[selector] || [];

  const windowTarget = new EventTarget();
  windowTarget.innerHeight = 1000;
  windowTarget.innerWidth = 1440;
  windowTarget.matchMedia = (query) => {
    mediaQuery = query;
    return { matches: true };
  };
  windowTarget.requestAnimationFrame = (callback) => callback();
  windowTarget.history = {
    replaceState(...args) { historyCalls.push(args); }
  };

  const previousDocument = global.document;
  const previousWindow = global.window;
  global.document = {
    querySelector(selector) {
      return selector === '[data-project-detail]' ? root : null;
    }
  };
  global.window = windowTarget;

  try {
    init();
    const click = new Event('click', { cancelable: true });
    link.dispatchEvent(click);

    assert.equal(mediaQuery, '(prefers-reduced-motion: reduce)');
    assert.equal(click.defaultPrevented, true);
    assert.deepEqual(scrollCalls, [{ behavior: 'auto', block: 'start' }]);
    assert.deepEqual(historyCalls, [[null, '', '#hardware']]);
    assert.equal(link.getAttribute('aria-current'), 'location');
  } finally {
    if (previousDocument === undefined) delete global.document;
    else global.document = previousDocument;
    if (previousWindow === undefined) delete global.window;
    else global.window = previousWindow;
  }
});
