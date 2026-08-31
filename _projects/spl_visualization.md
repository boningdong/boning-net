---
layout: project-detail
title: Programming Languages Trend
subtitle: A visualization of Seattle Public Library checkout data.
date: 2020-2-12
cover: "/assets/img/projects/spl_visualization/cover.png"
tags:
  - software
  - ar
---
Trace programming-language popularity through library checkout records.

This MAT 259 project classifies Seattle Public Library checkout data and maps changes in programming-language interest across time in an interactive 3D visualization.

::: featured-link
[View source on GitHub](https://github.com/boningdong/MAT259-3D-Visualization)
:::

# Context

This project is one of my MAT 259 projects. I wanted to explore changes in the popularity of different programming languages over the years. Using Seattle Public Library checkout records, I fetched, classified, and visualized the records to analyze the popularity change of a specific language and to see whether relationships exist between programming-language trends.

# Live Demo

[View the interactive p5.js demo](https://editor.p5js.org/boningUCSB/full/EsJxpC1m)

# Controls

In addition to controlling the camera angle with the mouse, you can navigate the camera with the W, A, S, and D keys to move forward, left, backward, and right. The Spacebar and Ctrl keys translate the camera up and down. The Arrow Up and Arrow Down keys tilt the camera.

# Visualization Design

![Sketch of the helix-based visualization](/assets/img/projects/spl_visualization/spl_visualization_5.png "Helical time mapping")

To fully use the extra dimensions in 3D space, I use the angle to represent month information and the height to represent the year. Overall, the data is presented in a helix pattern.

To differentiate programming languages, I colored most of them based on their logo colors. Each language has a separate radius as its track so that they do not collide with one another.

Daily checkouts are displayed using circles or tori so that the viewer can see the result from any angle.

Users can select the years and languages to display, making it easy to compare languages.

![Full programming-language trend visualization](/assets/img/projects/spl_visualization/spl_visualization_2.png "Full visualization view")

![Top-down programming-language trend visualization](/assets/img/projects/spl_visualization/cover.png "Top-down visualization view")

![Single-year programming-language trend visualization](/assets/img/projects/spl_visualization/spl_visualization_4.png "Single-year visualization view")

![Filtered programming-language trend visualization](/assets/img/projects/spl_visualization/spl_visualization_3.png "Filtered language view")
