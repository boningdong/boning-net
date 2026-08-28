(function(root, factory) {
    var projectDetail = factory();

    if (typeof module === 'object' && module.exports) {
        module.exports = projectDetail;
    } else {
        root.ProjectDetail = projectDetail;
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', projectDetail.init);
        } else {
            projectDetail.init();
        }
    }
}(typeof globalThis !== 'undefined' ? globalThis : this, function() {
    'use strict';

    function shouldRevealCorner(mainTop, viewportHeight) {
        return mainTop <= viewportHeight * 0.7;
    }

    function activeChapterIndex(positions, viewportHeight) {
        var readingLine = viewportHeight * 0.36;
        var activeIndex = 0;

        positions.forEach(function(position, index) {
            if (position <= readingLine) activeIndex = index;
        });

        return activeIndex;
    }

    function handleCornerDialogKeydown(event, closeDialog) {
        if (!event || (event.key !== 'Escape' && event.key !== 'Esc')) return false;

        if (typeof event.preventDefault === 'function') event.preventDefault();
        closeDialog(true);
        return true;
    }

    function chapterScrollBehavior(reducedMotion) {
        return reducedMotion ? 'auto' : 'smooth';
    }

    function init() {
        var rootElement = document.querySelector('[data-project-detail]');
        if (!rootElement) return;

        var main = rootElement.querySelector('[data-project-main]');
        var sections = Array.from(rootElement.querySelectorAll('[data-project-chapter]'));
        var links = Array.from(rootElement.querySelectorAll('[data-project-chapter-link]'));
        var corner = rootElement.querySelector('[data-project-corner]');
        var trigger = rootElement.querySelector('[data-project-corner-trigger]');
        var count = rootElement.querySelector('[data-project-corner-count]');
        var dialog = rootElement.querySelector('[data-project-corner-dialog]');
        var closeButton = rootElement.querySelector('[data-project-corner-close]');

        if (!main || !sections.length || !links.length || !corner || !trigger || !dialog) return;

        var total = sections.length;
        var activeIndex = 0;
        var mainReached = false;
        var reducedMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        var restoreDialogFocus = true;

        function isMobile() {
            return window.innerWidth < 900;
        }

        function closeDialog(restoreFocus) {
            if (!dialog.open) return;
            restoreDialogFocus = restoreFocus !== false;
            if (typeof dialog.close === 'function') {
                dialog.close();
            } else {
                dialog.removeAttribute('open');
                if (restoreDialogFocus) trigger.focus();
            }
        }

        function setCornerVisible(visible) {
            var shouldShow = visible && isMobile();
            if (!shouldShow) {
                corner.classList.remove('is-visible');
                corner.hidden = true;
                closeDialog(false);
                return;
            }

            if (!corner.hidden && corner.classList.contains('is-visible')) return;
            corner.hidden = false;
            window.requestAnimationFrame(function() {
                corner.classList.add('is-visible');
            });
        }

        function syncActive(nextIndex) {
            activeIndex = Math.max(0, Math.min(nextIndex, total - 1));
            var activeId = sections[activeIndex].dataset.projectChapter;

            links.forEach(function(link) {
                if (link.dataset.projectChapterLink === activeId) {
                    link.setAttribute('aria-current', 'location');
                } else {
                    link.removeAttribute('aria-current');
                }
            });
            if (count) count.textContent = (activeIndex + 1) + ' / ' + total;
            trigger.setAttribute(
                'aria-label',
                'Open project chapters, chapter ' + (activeIndex + 1) + ' of ' + total
            );
        }

        function syncFromGeometry() {
            var positions = sections.map(function(section) {
                return section.getBoundingClientRect().top;
            });
            syncActive(activeChapterIndex(positions, window.innerHeight));
        }

        function syncCornerFromGeometry() {
            mainReached = shouldRevealCorner(main.getBoundingClientRect().top, window.innerHeight);
            setCornerVisible(mainReached);
        }

        links.forEach(function(link) {
            link.addEventListener('click', function(event) {
                var id = link.dataset.projectChapterLink;
                var target = sections.find(function(section) {
                    return section.dataset.projectChapter === id;
                });
                if (!target) return;

                event.preventDefault();
                syncActive(sections.indexOf(target));
                closeDialog(true);
                target.scrollIntoView({
                    behavior: chapterScrollBehavior(reducedMotion),
                    block: 'start'
                });
                window.history.replaceState(null, '', '#' + encodeURIComponent(id));
            });
        });

        trigger.addEventListener('click', function() {
            restoreDialogFocus = true;
            if (typeof dialog.showModal === 'function') {
                dialog.showModal();
            } else {
                dialog.setAttribute('open', '');
            }
        });

        if (closeButton) {
            closeButton.addEventListener('click', function() {
                closeDialog(true);
            });
        }

        dialog.addEventListener('close', function() {
            if (restoreDialogFocus && !corner.hidden) trigger.focus();
            restoreDialogFocus = true;
        });

        dialog.addEventListener('click', function(event) {
            if (event.target === dialog) closeDialog(true);
        });

        dialog.addEventListener('keydown', function(event) {
            handleCornerDialogKeydown(event, closeDialog);
        });

        window.addEventListener('resize', function() {
            syncCornerFromGeometry();
            syncFromGeometry();
        });

        if ('IntersectionObserver' in window) {
            var revealObserver = new IntersectionObserver(function(entries) {
                entries.forEach(function(entry) {
                    mainReached = entry.isIntersecting && shouldRevealCorner(
                        entry.boundingClientRect.top,
                        window.innerHeight
                    );
                    setCornerVisible(mainReached);
                });
            }, { rootMargin: '0px 0px -30% 0px', threshold: 0 });

            var chapterObserver = new IntersectionObserver(function() {
                syncFromGeometry();
            }, { rootMargin: '-30% 0px -60% 0px', threshold: [0, 1] });

            revealObserver.observe(main);
            sections.forEach(function(section) { chapterObserver.observe(section); });
        }

        syncActive(0);
        syncCornerFromGeometry();
        syncFromGeometry();
    }

    return {
        activeChapterIndex: activeChapterIndex,
        chapterScrollBehavior: chapterScrollBehavior,
        handleCornerDialogKeydown: handleCornerDialogKeydown,
        init: init,
        shouldRevealCorner: shouldRevealCorner
    };
}));
