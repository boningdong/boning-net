(function(root, factory) {
    var home = factory();

    if (typeof module === 'object' && module.exports) {
        module.exports = home;
    } else {
        root.HomePage = home;
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', home.init);
        } else {
            home.init();
        }
    }
}(typeof globalThis !== 'undefined' ? globalThis : this, function() {
    'use strict';

    function nextTabIndex(current, key, count) {
        if (key === 'ArrowRight') return (current + 1) % count;
        if (key === 'ArrowLeft') return (current - 1 + count) % count;
        if (key === 'Home') return 0;
        if (key === 'End') return count - 1;
        return current;
    }

    function createWorkState(count, activeIndex) {
        return Array.from({ length: count }, function(_, index) {
            var selected = index === activeIndex;
            return {
                selected: selected,
                tabIndex: selected ? 0 : -1,
                hidden: !selected
            };
        });
    }

    function init() {
        var tabList = document.querySelector('[data-home-tabs]');
        if (!tabList) return;

        var tabs = Array.from(tabList.querySelectorAll('[role="tab"]'));
        var panels = tabs.map(function(tab) {
            return document.getElementById(tab.getAttribute('aria-controls'));
        });

        function activate(index, moveFocus) {
            var states = createWorkState(tabs.length, index);
            tabs.forEach(function(tab, tabIndex) {
                var state = states[tabIndex];
                tab.classList.toggle('active', state.selected);
                tab.setAttribute('aria-selected', String(state.selected));
                tab.tabIndex = state.tabIndex;
                panels[tabIndex].classList.toggle('active', state.selected);
                panels[tabIndex].hidden = state.hidden;
            });
            if (moveFocus) tabs[index].focus();
        }

        tabs.forEach(function(tab, index) {
            tab.addEventListener('click', function() { activate(index); });
            tab.addEventListener('keydown', function(event) {
                var next = nextTabIndex(index, event.key, tabs.length);
                if (next === index && !['Home', 'End'].includes(event.key)) return;
                event.preventDefault();
                activate(next, true);
            });
        });
    }

    return {
        createWorkState: createWorkState,
        init: init,
        nextTabIndex: nextTabIndex
    };
}));
