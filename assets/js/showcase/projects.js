$(document).ready(function(){
    $('.showcase').masonry({
        itemSelector: '.card',
        columnWidth: 280,
        gutter: 40,
        horizontalOrder: true,
        fitWidth: true,
        transitionDuration: '0.35s'
    });
});
