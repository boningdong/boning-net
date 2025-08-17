document.addEventListener('DOMContentLoaded', function(){
    format_showcase();
});
document.querySelectorAll('.card').forEach(function(card) {
    card.addEventListener('load', format_showcase);
});
function format_showcase() {
    var showcaseElement = document.querySelector('.showcase');
    if (showcaseElement) {
        new Masonry(showcaseElement, {
            itemSelector: '.card',
            columnWidth: 280,
            gutter: 40,
            horizontalOrder: true,
            fitWidth: true,
            transitionDuration: '0.35s'
        });
    }
}