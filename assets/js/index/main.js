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
});

window.addEventListener('scroll', function() {
    if(window.scrollY <= 40) {
        document.getElementById('navbar').classList.remove('navbar-scroll');
    } else {
        document.getElementById('navbar').classList.add('navbar-scroll');
    }
});

// Showcase functions
function initProjectShowcase() {
    document.getElementById("button-project").classList.add("showcase-button-activate");
    document.getElementById("art-showcase").style.display = "none";
    slideDown("project-showcase");
}

function initArtworkShowcase() {
    document.getElementById("button-artwork").classList.add("showcase-button-activate");
    document.getElementById("project-showcase").style.display = "none";
    slideDown("art-showcase");
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

// Showcase buttos event listeners
document.getElementById("button-artwork").addEventListener('click', function() {
    document.getElementById("button-artwork").classList.add("showcase-button-activate");
    document.getElementById("button-project").classList.remove("showcase-button-activate");
    document.getElementById("project-showcase").style.display = "none";
    slideDown("art-showcase");
});

document.getElementById("button-project").addEventListener('click', function() {
    document.getElementById("button-project").classList.add("showcase-button-activate");
    document.getElementById("button-artwork").classList.remove("showcase-button-activate");
    document.getElementById("art-showcase").style.display = "none";
    slideDown("project-showcase");
});
