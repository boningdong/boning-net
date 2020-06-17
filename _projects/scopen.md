---
layout: project-post
title: Scopen - A wireless oscilloscope
subtitle: UCSB CE 2020 Capstone Project
date: 2020-6-15
cover: "/assets/img/projects/scopen_cover.png"
tags:
    - hardware
    - system-design
    - firmware
    - embedded
    - c
    - pcb
---

# Concept
Scopen is one of the UCSB CE 2020 capstone projects. We built this project not just for satisfying our curricular requirements, but more importantly, also for ourselves, because we always want to have an affordable, wireless, and handheld oscilloscope-like equipment, so that we can debug circuits easily.

# Product Videos
<iframe width="560" height="315" src="https://www.youtube.com/embed/4xJvWEb1Kwo" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
 
<div class="row">
    <div class="col-lg-6"></div>
     
    <div class="col-lg-6">
     
    </div>
</div>

# Controls
In addition to controlling the camera angle using the mouse, you can also naviagate the camera using 'w', 'a', 's', 'd' keys to move forward, left, backward and right. Also 'spacebar' and 'ctrl' can translate the camera up and down. Arrow UP and Arrow Down can tilt the camera.

# Design Concept
<div class="row">
    <div class="col-lg-1">
    </div>
    <div class="col-lg-9">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/spl_visualization_5.png">
    </div>
    <div class="col-lg-1">
    </div>
</div>
To fully utilize the extra dimensions in 3D space, I am trying to use the angle to represent the month information, and the height to represent the year. So overall the data will be presented following a helix pattern.
To differentiate the programming languages, I colored most of them based on their logo color, and each language will take one radius as their track so that they will not collide with each other.

The daily checkouts should be displayed using circles or torus so that the viewer can see the result from any angle.

Also, the user should be able to select the years and languages to be shown, it’s easy for the languages to be compared.

<div class="row d-flex">
    <div class="col-lg-6">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/spl_visualization_2.png">
    </div>
    <div class="col-lg-6">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/spl_visualization_1.png">
    </div>
</div>
<div class="row d-flex">
    <div class="col-lg-6">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/spl_visualization_4.png">
    </div>
    <div class="col-lg-6">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/spl_visualization_3.png">
    </div>
</div>
