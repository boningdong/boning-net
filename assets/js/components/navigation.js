(function(root, factory) {
    var navigation = factory();

    if (typeof module === 'object' && module.exports) {
        module.exports = navigation;
    } else {
        root.Navigation = navigation;
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', navigation.init);
        } else {
            navigation.init();
        }
    }
}(typeof globalThis !== 'undefined' ? globalThis : this, function() {
    'use strict';

    function shouldShowSurface(scrollY) {
        return scrollY > 24;
    }

    function init() {
        var shell = document.querySelector('[data-navigation]');
        if (!shell) return;

        var bar = shell.querySelector('[data-navigation-bar]');
        var trigger = shell.querySelector('[data-menu-trigger]');
        var panel = shell.querySelector('[data-menu-panel]');

        function setMenu(open, restoreFocus) {
            shell.classList.toggle('menu-open', open);
            trigger.setAttribute('aria-expanded', String(open));
            panel.setAttribute('aria-hidden', String(!open));
            if (!open && restoreFocus) trigger.focus();
        }

        function syncSurface() {
            bar.classList.toggle('surface-visible', shouldShowSurface(window.scrollY));
        }

        trigger.addEventListener('click', function() {
            setMenu(!shell.classList.contains('menu-open'));
        });

        panel.querySelectorAll('a').forEach(function(link) {
            link.addEventListener('click', function() { setMenu(false); });
        });

        document.addEventListener('click', function(event) {
            if (shell.classList.contains('menu-open') && !shell.contains(event.target)) {
                setMenu(false);
            }
        });

        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape' && shell.classList.contains('menu-open')) {
                setMenu(false, true);
            }
        });

        window.addEventListener('resize', function() {
            if (window.innerWidth > 640 && shell.classList.contains('menu-open')) {
                setMenu(false);
            }
        });
        window.addEventListener('scroll', syncSurface, { passive: true });
        syncSurface();
    }

    return {
        init: init,
        shouldShowSurface: shouldShowSurface
    };
}));
