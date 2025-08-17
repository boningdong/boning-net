document.addEventListener('DOMContentLoaded', function(){
    format_showcase();
});
document.querySelectorAll('.image').forEach(function(image) {
    image.addEventListener('load', format_showcase);
});
function format_showcase() {
    var gridElement = document.querySelector('.grid');
    if (gridElement) {
        new Masonry(gridElement, {
            itemSelector: '.grid-item',
            columnWidth: 250,
            gutter: 20,
            horizontalOrder: true,
            fitWidth: true,
            transitionDuration: '0.35s'
        });
    }
}