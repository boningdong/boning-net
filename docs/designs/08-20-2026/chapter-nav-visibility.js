(function exposeChapterNavigationVisibility(root, factory) {
  const api = factory();

  if (typeof module === "object" && module.exports) {
    module.exports = api;
  } else {
    root.chapterNavVisibility = api;
  }
}(typeof globalThis !== "undefined" ? globalThis : this, function createChapterNavigationVisibility() {
  const REVEAL_LINE = 0.7;

  const shouldRevealChapterNavigation = (contextTop, viewportHeight) => contextTop <= viewportHeight * REVEAL_LINE;

  return { shouldRevealChapterNavigation };
}));

