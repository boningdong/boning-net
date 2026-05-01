// Reusable slideDown animation function
function slideDown(elementId) {
    var element = document.getElementById(elementId);
    if (!element) return;
    element.style.transform = 'translateY(-20px)';
    element.style.opacity = '0';
    element.style.display = 'block';
    element.style.transition = 'transform 0.5s ease, opacity 0.5s ease';
    setTimeout(function() {
        element.style.transform = 'translateY(0)';
        element.style.opacity = '1';
    }, 10);
}
document.addEventListener('DOMContentLoaded', function() {
    resizeSkillsContainer();
    initArtworkShowcase();
    initShowcaseButtons();
});
window.addEventListener('scroll', function() {
    var navbar = document.getElementById('navbar');
    if (!navbar) return;
    if (window.scrollY <= 40) {
        navbar.classList.remove('navbar-scroll');
    } else {
        navbar.classList.add('navbar-scroll');
    }
});
// Showcase functions
function initProjectShowcase() {
    var projectButton = document.getElementById("button-project");
    var artworkShowcase = document.getElementById("artwork-showcase");
    if (!projectButton || !artworkShowcase) return;
    projectButton.classList.add("showcase-button-activate");
    artworkShowcase.style.display = "none";
    slideDown("project-showcase");
}
function initArtworkShowcase() {
    var artworkButton = document.getElementById("button-artwork");
    var projectShowcase = document.getElementById("project-showcase");
    if (!artworkButton || !projectShowcase) return;
    artworkButton.classList.add("showcase-button-activate");
    projectShowcase.style.display = "none";
    slideDown("artwork-showcase");
}
// Resize skills showcase
function resizeSkillsContainer() {
    var maxHeight = 0;
    var skillsShowcase = document.getElementById("skills-showcase");
    if (!skillsShowcase) return;
    var children = skillsShowcase.children;
    for (var i = 0; i < children.length; i++) {
        var skillsContainer = children[i].querySelector("div.skills-container");
        if (skillsContainer) {
            skillsContainer.style.height = "auto";
        }
    }
    for (var i = 0; i < children.length; i++) {
        var skillsContainer = children[i].querySelector(".skills-container");
        if (skillsContainer) {
            maxHeight = Math.max(maxHeight, skillsContainer.offsetHeight);
        }
    }
    for (var i = 0; i < children.length; i++) {
        var skillsContainer = children[i].querySelector("div.skills-container");
        if (skillsContainer) {
            skillsContainer.style.height = maxHeight + "px";
        }
    }
}
window.addEventListener('resize', resizeSkillsContainer);
// Showcase button event listeners
function initShowcaseButtons() {
    var artworkButton = document.getElementById("button-artwork");
    var projectButton = document.getElementById("button-project");
    var artworkShowcase = document.getElementById("artwork-showcase");
    var projectShowcase = document.getElementById("project-showcase");
    if (!artworkButton || !projectButton || !artworkShowcase || !projectShowcase) return;

    artworkButton.addEventListener('click', function() {
        artworkButton.classList.add("showcase-button-activate");
        projectButton.classList.remove("showcase-button-activate");
        projectShowcase.style.display = "none";
        slideDown("artwork-showcase");
    });
    projectButton.addEventListener('click', function() {
        projectButton.classList.add("showcase-button-activate");
        artworkButton.classList.remove("showcase-button-activate");
        artworkShowcase.style.display = "none";
        slideDown("project-showcase");
    });
}
