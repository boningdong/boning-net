---
layout: project-pos
title: Programming Languages Trend
subtitle: Seattle Library Data Visualization.
date: 2020-2-12
cover: "/assets/img/projects/spl_visualization_cover.png"
tags:
    - software
    - ar
---
# Concep
This project is one of my MAT259 projects. In this project, I wanted to explore the change of the popularities of different programming languages over the past years. By using the Seattle Public Library checkout records, I fetched, classified and visualized these checkout records to analyze the popularity change of a specific language, and also tried to see if there is any relationship between the trend of different programming languages.
# Project Links
[Project online demo](https://editor.p5js.org/boningUCSB/full/EsJxpC1m)
[Source Code on Github](https://github.com/boningdong/MAT259-3D-Visualization)
# Controls
In addition to controlling the camera angle using the mouse, you can also naviagate the camera using 'w', 'a', 's', 'd' keys to move forward, left, backward and right. Also 'spacebar' and 'ctrl' can translate the camera up and down. Arrow UP and Arrow Down can tilt the camera.
# Design Concep
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
