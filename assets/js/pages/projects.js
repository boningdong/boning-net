(function(root, factory) {
    var projects = factory();

    if (typeof module === 'object' && module.exports) {
        module.exports = projects;
    } else {
        root.ProjectsPage = projects;
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', projects.init);
        } else {
            projects.init();
        }
    }
}(typeof globalThis !== 'undefined' ? globalThis : this, function() {
    'use strict';

    function matchesTag(tags, selectedTag) {
        if (selectedTag === 'all') return true;
        var values = Array.isArray(tags) ? tags : String(tags).trim().split(/\s+/);
        return values.includes(selectedTag);
    }

    function collapsedTagCount(viewportWidth) {
        if (viewportWidth <= 640) return 3;
        if (viewportWidth <= 850) return 4;
        return 5;
    }

    function formatResultCount(count) {
        return count + (count === 1 ? ' project' : ' projects');
    }

    function init() {
        var rootElement = document.querySelector('[data-project-filters]');
        if (!rootElement) return;

        var filterButtons = Array.from(rootElement.querySelectorAll('[data-filter]'));
        var moreButton = rootElement.querySelector('[data-more-toggle]');
        var moreLabel = moreButton.querySelector('[data-more-label]');
        var resultCount = rootElement.querySelector('[data-result-count]');
        var cards = Array.from(rootElement.querySelectorAll('[data-project-card]'));
        var expanded = false;

        function activeFilterIndex() {
            return filterButtons.findIndex(function(button) {
                return button.getAttribute('aria-pressed') === 'true';
            });
        }

        function renderFilters() {
            var visibleCount = collapsedTagCount(window.innerWidth);
            filterButtons.forEach(function(button, index) {
                button.hidden = !expanded && index >= visibleCount;
            });
            moreButton.classList.toggle('active', !expanded && activeFilterIndex() >= visibleCount);
            moreButton.setAttribute('aria-expanded', String(expanded));
            moreLabel.textContent = expanded ? 'Less' : 'More';
        }

        function applyFilter(button) {
            var selectedTag = button.dataset.filter;
            var visible = 0;

            filterButtons.forEach(function(filterButton) {
                var active = filterButton === button;
                filterButton.classList.toggle('active', active);
                filterButton.setAttribute('aria-pressed', String(active));
            });
            cards.forEach(function(card) {
                var matches = matchesTag(card.dataset.tags, selectedTag);
                card.hidden = !matches;
                if (matches) visible += 1;
            });
            resultCount.textContent = formatResultCount(visible);
            renderFilters();
        }

        filterButtons.forEach(function(button) {
            button.addEventListener('click', function() { applyFilter(button); });
        });
        moreButton.addEventListener('click', function() {
            expanded = !expanded;
            renderFilters();
        });
        window.addEventListener('resize', renderFilters);
        renderFilters();
    }

    return {
        collapsedTagCount: collapsedTagCount,
        formatResultCount: formatResultCount,
        init: init,
        matchesTag: matchesTag
    };
}));
