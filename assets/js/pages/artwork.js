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

    function wrapRailPosition(position, cycleWidth) {
        if (cycleWidth <= 0) return position;
        return ((position % cycleWidth) + cycleWidth) % cycleWidth;
    }

    function initFilters(rootElement) {
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
            });
        });
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
        var firstDuplicate = track.querySelector('[data-highlight-artwork-duplicate]');
        var motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
        var hovering = false;
        var focused = false;
        var manualPauseUntil = 0;
        var lastFrame = 0;
        var driftSpeed = 18;

        function pauseForManualInput() {
            manualPauseUntil = performance.now() + 1800;
        }

        function cycleWidth() {
            return firstDuplicate ? firstDuplicate.offsetLeft - track.offsetLeft : 0;
        }

        function frame(timestamp) {
            var elapsed = lastFrame ? Math.min(timestamp - lastFrame, 50) : 0;
            var paused = hovering || focused || timestamp < manualPauseUntil;

            if (shouldAutoDrift({ reducedMotion: motionQuery.matches, paused: paused })) {
                rail.scrollLeft = wrapRailPosition(rail.scrollLeft + driftSpeed * elapsed / 1000, cycleWidth());
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
        window.requestAnimationFrame(frame);
    }

    function init() {
        var rootElement = document.querySelector('[data-artwork-page]');
        if (!rootElement) return;

        initFilters(rootElement);
        initViewer(rootElement);
        initRail(rootElement);
    }

    return {
        createFilterState: createFilterState,
        createViewerContent: createViewerContent,
        formatArtworkCount: formatArtworkCount,
        init: init,
        isViewerCloseKey: isViewerCloseKey,
        matchesMedium: matchesMedium,
        shouldAutoDrift: shouldAutoDrift,
        wrapRailPosition: wrapRailPosition
    };
}));
