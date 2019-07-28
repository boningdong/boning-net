$(document).ready(function() {
    resizeSkillsContainer();
    initArtworkShowcase();
}); 



$(window).scroll(function() {
    if($(window).scrollTop() <= 40) {
        $('#navbar').removeClass('navbar-scroll');
    } else {
        $('#navbar').addClass('navbar-scroll');
    }
});

// Showcase functions
function initProjectShowcase() {
    $("#button-project").addClass("showcase-button-activate");
    $("#art-showcase").hide();
    $("#project-showcase").slideDown(500);
}

function initArtworkShowcase() {
    $("#button-artwork").addClass("showcase-button-activate");
    $("#project-showcase").hide();
    $("#art-showcase").slideDown(500);
}

// Resize skills showcase
function resizeSkillsContainer() {
    var maxHeight = 0;
    $("#skills-showcase").children().each(function() {
        $(this).find("div.skills-container").height("auto");
    });
    $("#skills-showcase").children().each(function() {
        maxHeight = Math.max(maxHeight, $(this).find(".skills-container").height());
    });
    $("#skills-showcase").children().each(function() {
        $(this).find("div.skills-container").height(maxHeight);
    });
}

$(window).resize(resizeSkillsContainer);

// Showcase buttos event listeners
$("#button-artwork").click(function() {
    $("#button-artwork").addClass("showcase-button-activate");
    $("#button-project").removeClass("showcase-button-activate");
    $("#project-showcase").hide();
    $("#art-showcase").slideDown(500);
});

$("#button-project").click(function() {
    $("#button-project").addClass("showcase-button-activate");
    $("#button-artwork").removeClass("showcase-button-activate");
    $("#art-showcase").hide();
    $("#project-showcase").slideDown(500);
});

