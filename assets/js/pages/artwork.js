(function(root, factory) {
    var artwork = factory();

    if (typeof module === 'object' && module.exports) {
        module.exports = artwork;
    } else {
        root.ArtworkPage = artwork;
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', artwork.init);
        } else {
            artwork.init();
        }
    }
}(typeof globalThis !== 'undefined' ? globalThis : this, function() {
    'use strict';

    function matchesMedium(medium, selectedMedium) {
        return selectedMedium === 'all' || String(medium).toLowerCase() === selectedMedium;
    }

    function formatArtworkCount(count) {
        return count + (count === 1 ? ' work' : ' works');
    }

    function createFilterState(media, selectedMedium) {
        var visible = media.map(function(medium) {
            return matchesMedium(medium, selectedMedium);
        });

        return {
            visible: visible,
            count: visible.filter(Boolean).length
        };
    }

    function createHorizontalMasonryLayout(itemHeights, columnCount, gap) {
        var columns = Math.max(1, Math.floor(Number(columnCount) || 1));
        var spacing = Math.max(0, Number(gap) || 0);
        var columnHeights = Array(columns).fill(0);
        var positions = itemHeights.map(function(itemHeight, index) {
            var column = index % columns;
            var top = columnHeights[column];
            columnHeights[column] += Math.max(0, Number(itemHeight) || 0) + spacing;
            return { column: column, top: top };
        });
        var tallestColumn = columnHeights.length ? Math.max.apply(Math, columnHeights) : 0;

        return {
            positions: positions,
            height: Math.max(0, tallestColumn - (positions.length ? spacing : 0))
        };
    }

    function createViewerContent(data) {
        return {
            src: data.full,
            alt: data.title,
            title: data.title,
            meta: data.meta
        };
    }

    function isViewerCloseKey(key) {
        return key === 'Escape';
    }

    function shouldAutoDrift(state) {
        return !state.reducedMotion && !state.paused;
    }

    function measureRailCycle(firstOriginalOffset, firstDuplicateOffset) {
        return Math.max(0, firstDuplicateOffset - firstOriginalOffset);
    }

    function wrapRailPosition(position, cycleWidth, cycleStart) {
        if (cycleWidth <= 0) return position;
        var start = cycleStart || 0;
        return start + ((((position - start) % cycleWidth) + cycleWidth) % cycleWidth);
    }

    function normalizeManualRailPosition(position, cycleWidth, cycleStart, reducedMotion) {
        return reducedMotion ? wrapRailPosition(position, cycleWidth, cycleStart) : position;
    }

    function areRailImagesSettled(images) {
        return Array.from(images).every(function(image) {
            return image.complete;
        });
    }

    function initFilters(rootElement, scheduleCollectionLayout) {
        var filterButtons = Array.from(rootElement.querySelectorAll('[data-artwork-filter]'));
        var cards = Array.from(rootElement.querySelectorAll('[data-collection-artwork-card]'));
        var resultCount = rootElement.querySelector('[data-artwork-result-count]');

        filterButtons.forEach(function(button) {
            button.addEventListener('click', function() {
                var selectedMedium = button.dataset.filter;
                var state = createFilterState(cards.map(function(card) {
                    return card.dataset.medium;
                }), selectedMedium);

                filterButtons.forEach(function(filterButton) {
                    var active = filterButton === button;
                    filterButton.classList.toggle('active', active);
                    filterButton.setAttribute('aria-pressed', String(active));
                });
                cards.forEach(function(card, index) {
                    card.hidden = !state.visible[index];
                });
                resultCount.textContent = formatArtworkCount(state.count);
                scheduleCollectionLayout();
            });
        });
    }

    function initCollection(rootElement) {
        var grid = rootElement.querySelector('[data-artwork-collection-grid]');
        if (!grid || typeof window.requestAnimationFrame !== 'function') return function() {};

        var cards = Array.from(grid.querySelectorAll('[data-collection-artwork-card]'));
        var scheduledFrame = 0;

        function readPositiveNumber(value, fallback) {
            var parsed = parseFloat(value);
            return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
        }

        function layoutCollection() {
            scheduledFrame = 0;
            var computedStyle = window.getComputedStyle(grid);
            var columns = Math.max(1, Math.round(readPositiveNumber(computedStyle.getPropertyValue('--artwork-collection-columns'), 1)));
            var gap = Math.max(0, parseFloat(computedStyle.getPropertyValue('--artwork-collection-gap')) || 0);
            var availableWidth = grid.clientWidth;
            var cardWidth = Math.max(0, (availableWidth - gap * (columns - 1)) / columns);
            var visibleCards = cards.filter(function(card) { return !card.hidden; });

            visibleCards.forEach(function(card) {
                card.style.width = cardWidth + 'px';
            });

            var layout = createHorizontalMasonryLayout(visibleCards.map(function(card) {
                return card.getBoundingClientRect().height;
            }), columns, gap);

            visibleCards.forEach(function(card, index) {
                var position = layout.positions[index];
                var left = position.column * (cardWidth + gap);
                card.style.transform = 'translate3d(' + left + 'px,' + position.top + 'px,0)';
            });
            grid.style.height = layout.height + 'px';
            grid.classList.add('is-masonry-ready');
        }

        function scheduleCollectionLayout() {
            if (scheduledFrame) window.cancelAnimationFrame(scheduledFrame);
            scheduledFrame = window.requestAnimationFrame(layoutCollection);
        }

        cards.forEach(function(card) {
            var image = card.querySelector('img');
            if (!image || image.complete) return;
            image.addEventListener('load', scheduleCollectionLayout, { once: true });
            image.addEventListener('error', scheduleCollectionLayout, { once: true });
        });
        window.addEventListener('resize', scheduleCollectionLayout);
        if (document.fonts && document.fonts.ready) document.fonts.ready.then(scheduleCollectionLayout);
        scheduleCollectionLayout();

        return scheduleCollectionLayout;
    }

    function initViewer(rootElement) {
        var viewer = document.querySelector('[data-artwork-viewer]');
        if (!viewer) return;

        var viewerImage = viewer.querySelector('[data-artwork-viewer-image]');
        var viewerTitle = viewer.querySelector('[data-artwork-viewer-title]');
        var viewerMeta = viewer.querySelector('[data-artwork-viewer-meta]');
        var closeButton = viewer.querySelector('[data-artwork-viewer-close]');
        var lastTrigger = null;

        rootElement.querySelectorAll('[data-artwork-trigger]').forEach(function(trigger) {
            trigger.addEventListener('click', function() {
                var content = createViewerContent(trigger.dataset);
                lastTrigger = trigger;
                viewerImage.src = content.src;
                viewerImage.alt = content.alt;
                viewerTitle.textContent = content.title;
                viewerMeta.textContent = content.meta;
                viewer.showModal();
                closeButton.focus();
            });
        });

        closeButton.addEventListener('click', function() {
            viewer.close();
        });
        viewer.addEventListener('click', function(event) {
            if (event.target === viewer) viewer.close();
        });
        viewer.addEventListener('keydown', function(event) {
            if (!isViewerCloseKey(event.key) || !viewer.open) return;
            event.preventDefault();
            viewer.close();
        });
        viewer.addEventListener('close', function() {
            if (lastTrigger && lastTrigger.isConnected) lastTrigger.focus();
        });
    }

    function initRail(rootElement) {
        var rail = rootElement.querySelector('[data-artwork-rail]');
        if (!rail || typeof window.requestAnimationFrame !== 'function') return;

        var track = rail.querySelector('[data-artwork-track]');
        var firstPrevious = track.querySelector('[data-highlight-artwork-copy="previous"]');
        var firstOriginal = track.querySelector('[data-highlight-artwork-card]');
        var firstNext = track.querySelector('[data-highlight-artwork-copy="next"]');
        var railImages = Array.from(track.querySelectorAll('img'));
        var motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
        var hovering = false;
        var focused = false;
        var initialized = false;
        var manualPauseUntil = 0;
        var lastFrame = 0;
        var driftSpeed = 18;

        function pauseForManualInput() {
            manualPauseUntil = performance.now() + 1800;
        }

        function cycleWidth() {
            if (!firstOriginal || !firstNext) return 0;
            return measureRailCycle(firstOriginal.offsetLeft, firstNext.offsetLeft);
        }

        function cycleStart() {
            if (!firstPrevious || !firstOriginal) return 0;
            return measureRailCycle(firstPrevious.offsetLeft, firstOriginal.offsetLeft);
        }

        function railReady() {
            return areRailImagesSettled(railImages);
        }

        function frame(timestamp) {
            var elapsed = lastFrame ? Math.min(timestamp - lastFrame, 50) : 0;
            var paused = hovering || focused || timestamp < manualPauseUntil;
            var width = cycleWidth();
            var start = cycleStart();

            if (!initialized && railReady() && width > 0 && start > 0) {
                rail.scrollLeft = start;
                initialized = true;
                rail.setAttribute('data-artwork-rail-ready', '');
                lastFrame = timestamp;
                window.requestAnimationFrame(frame);
                return;
            }

            if (initialized && shouldAutoDrift({ reducedMotion: motionQuery.matches, paused: paused })) {
                rail.scrollLeft = wrapRailPosition(rail.scrollLeft + driftSpeed * elapsed / 1000, width, start);
            }
            lastFrame = timestamp;
            window.requestAnimationFrame(frame);
        }

        rail.addEventListener('pointerenter', function() { hovering = true; });
        rail.addEventListener('pointerleave', function() { hovering = false; });
        rail.addEventListener('focusin', function() { focused = true; });
        rail.addEventListener('focusout', function(event) {
            focused = Boolean(event.relatedTarget && rail.contains(event.relatedTarget));
        });
        rail.addEventListener('wheel', pauseForManualInput, { passive: true });
        rail.addEventListener('pointerdown', pauseForManualInput, { passive: true });
        rail.addEventListener('touchstart', pauseForManualInput, { passive: true });
        rail.addEventListener('scroll', function() {
            if (!initialized || !motionQuery.matches) return;
            var normalized = normalizeManualRailPosition(rail.scrollLeft, cycleWidth(), cycleStart(), true);
            if (Math.abs(normalized - rail.scrollLeft) > 0.5) rail.scrollLeft = normalized;
        }, { passive: true });
        window.addEventListener('resize', function() {
            initialized = false;
            rail.removeAttribute('data-artwork-rail-ready');
        });
        window.requestAnimationFrame(frame);
    }

    function init() {
        var rootElement = document.querySelector('[data-artwork-page]');
        if (!rootElement) return;

        var scheduleCollectionLayout = initCollection(rootElement);
        initFilters(rootElement, scheduleCollectionLayout);
        initViewer(rootElement);
        initRail(rootElement);
    }

    return {
        areRailImagesSettled: areRailImagesSettled,
        createFilterState: createFilterState,
        createHorizontalMasonryLayout: createHorizontalMasonryLayout,
        createViewerContent: createViewerContent,
        formatArtworkCount: formatArtworkCount,
        init: init,
        isViewerCloseKey: isViewerCloseKey,
        matchesMedium: matchesMedium,
        measureRailCycle: measureRailCycle,
        normalizeManualRailPosition: normalizeManualRailPosition,
        shouldAutoDrift: shouldAutoDrift,
        wrapRailPosition: wrapRailPosition
    };
}));
