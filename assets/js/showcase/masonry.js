(function() {
    function setupMasonry(config) {
        var container = document.querySelector(config.container);
        if (!container || typeof Masonry === 'undefined') return;

        var masonry = new Masonry(container, {
            itemSelector: config.itemSelector,
            columnWidth: config.columnWidth,
            gutter: config.gutter,
            horizontalOrder: true,
            fitWidth: true,
            transitionDuration: '0.35s'
        });

        container.querySelectorAll('img').forEach(function(image) {
            if (image.complete) return;
            image.addEventListener('load', function() {
                masonry.layout();
            });
        });
    }

    document.addEventListener('DOMContentLoaded', function() {
        setupMasonry({
            container: '.showcase',
            itemSelector: '.card',
            columnWidth: 280,
            gutter: 40
        });
        setupMasonry({
            container: '.grid',
            itemSelector: '.grid-item',
            columnWidth: 250,
            gutter: 20
        });
    });
})();
