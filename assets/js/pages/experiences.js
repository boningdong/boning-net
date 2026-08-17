(function(root, factory) {
    var experiences = factory();

    if (typeof module === 'object' && module.exports) {
        module.exports = experiences;
    } else {
        root.ExperiencesPage = experiences;
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', function() { experiences.init(); });
        } else {
            experiences.init();
        }
    }
}(typeof globalThis !== 'undefined' ? globalThis : this, function() {
    'use strict';

    function controlsFor(card) {
        if (!card || typeof card.querySelector !== 'function') return null;

        var button = card.querySelector('[data-experience-toggle]');
        var panel = card.querySelector('[data-experience-details]');
        var label = button && button.querySelector('[data-experience-toggle-label]');

        if (!button || !panel || !label) return null;
        return { button: button, label: label, panel: panel };
    }

    function setCardExpanded(card, expanded) {
        var controls = controlsFor(card);
        if (!controls) return false;

        card.classList.toggle('is-open', expanded);
        controls.button.setAttribute('aria-expanded', String(expanded));
        controls.panel.setAttribute('aria-hidden', String(!expanded));
        controls.panel.inert = !expanded;
        controls.label.textContent = expanded ? 'Close' : 'Details';
        return true;
    }

    function init(rootElement) {
        var pageRoot = rootElement;

        if (pageRoot === undefined && typeof document !== 'undefined') {
            pageRoot = document.querySelector('[data-experiences-page]');
        }
        if (!pageRoot || typeof pageRoot.querySelectorAll !== 'function') return;

        var cards = Array.from(pageRoot.querySelectorAll('[data-experience-card]'));
        pageRoot.classList.toggle('is-enhanced', true);

        cards.forEach(function(card) {
            var controls = controlsFor(card);
            if (!controls) return;

            setCardExpanded(card, false);
            controls.button.addEventListener('click', function() {
                var shouldOpen = !card.classList.contains('is-open');

                cards.forEach(function(item) { setCardExpanded(item, false); });
                if (shouldOpen) setCardExpanded(card, true);
            });
        });
    }

    return {
        init: init,
        setCardExpanded: setCardExpanded
    };
}));
