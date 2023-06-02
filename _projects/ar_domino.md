---
layout: project-post
title: AR Domino
# subtitle: A self-made high precision 3D printer.
subtitle: An AR domino game developed using Unity
date: 2021-05-01
cover: "/assets/img/projects/ar_domino/domino_cover.jpg"
external-link: "https://github.com/boningdong/AR-Domino"
tags:
    - unity
    - ar
    - game
    - software
---
# Background
Domino is a tile-based game played with Domino tile pieces, where players place the tiles one by one with a small distance to form a line and initiate toppling by pushing the first tile. Our AR Domino project aims to recreate this gaming experience in augmented reality (AR). The satisfaction of placing tiles and witnessing their sequential toppling is the focal point of our project. Users can virtually place Domino tiles and other game objects as platforms, triggering the toppling effect. Moreover, they can interact with real-world objects by overlaying virtual objects onto detected physical objects.

# Demo Video
<div class="row justify-content-center">
    <div class="col-12 p-2">
        <div class="video-container">
            <iframe src="https://www.youtube.com/embed/WEThYat87RQ" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
        </div>
    </div>
</div>

# Implementation
Our AR Domino game is developed primarily using the Unity game engine on iOS. We chose Unity because of its AR Foundation framework, which simplifies the creation of cross-platform AR applications. iOS was selected as our main development environment due to the consistent hardware specifications of iOS devices. The AR functionality on iOS is built upon the ARKit framework.

The project can be logically divided into four categories: User Input, AR Detection, Game Data, and Miscellaneous modules. It is important to note that the modules mentioned in this section may not directly correspond to the design of classes.

# Story Telling
The following figure illustrates the user interface layout of our app. At the center of the screen, a semi-transparent place indicator provides users with a visual reference for the domino's placement. In the bottom-right corner, a rotation ring allows users to adjust the face direction of the domino. Tapping the place button initiates the placement action.

<div class="row d-flex">
    <div class="col-lg-12">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/ar_domino/domino_storytelling.jpg">
    </div>
</div>

# Challenges
We encountered design and technical challenges during the development of our AR Domino game and devised solutions to address them. The two most significant challenges are outlined below.

## 1.Real-world scan-based object detection:
Current 3D object detection technology and our hardware limitations posed obstacles to accurate and efficient real-world object detection. To overcome this, we opted for 2D image tracking instead of 3D scanning. We created trackable image patterns on stickers and affixed them to the desired real-world objects. The image tracking algorithm successfully recognizes these patterns within approximately 1 second, providing sufficient speed for our game.

## 2.Interaction with real-world and virtual objects:
In our game, we sought to enable users to place virtual domino tiles on both real-world objects (such as AR Planes and 3D printed cubes) and virtual objects (like the Box object). To achieve this, we converted real-world objects into virtual objects by spawning 3D models at the positions of tracked images. We devised a straightforward method to determine the placement of virtual objects. By generating two rays from the camera—one from the ARRaycastManager for detecting AR planes and another from the Physics object for detecting virtual objects—we compared the collision points of the rays and selected the closer one for object placement.


