---
layout: project-detail
title: AR Domino
subtitle: An augmented-reality domino game built with Unity.
date: 2021-05-01
cover: "/assets/img/projects/ar_domino/cover.jpg"
external-link: "https://github.com/boningdong/AR-Domino"
featured: true
featured-order: 2
tags:
  - unity
  - ar
  - game
  - software
---
Build domino runs across virtual and physical surfaces.

AR Domino recreates the placement and chain reaction of domino tiles in augmented reality. The Unity and ARKit application lets players place virtual objects, use tracked physical objects as platforms, and trigger the resulting run.

::: featured-link
[View source on GitHub](https://github.com/boningdong/AR-Domino)
:::

# Context

Domino is a tile-based game played with domino tiles, where players place tiles one by one with a small distance between them to form a line and initiate toppling by pushing the first tile. Our AR Domino project aims to recreate this gaming experience in augmented reality. The satisfaction of placing tiles and watching them topple sequentially is the focal point of the project. Users can virtually place domino tiles and other game objects as platforms, triggering the toppling effect. They can also interact with real-world objects by overlaying virtual objects onto detected physical objects.

# Demo

::: video-embed
[AR Domino demo](https://youtu.be/WEThYat87RQ "AR Domino gameplay demo")
:::

# Implementation

Our AR Domino game is developed primarily using the Unity game engine on iOS. We chose Unity because its AR Foundation framework simplifies the creation of cross-platform AR applications. iOS was selected as our main development environment because of its consistent hardware specifications. The AR functionality on iOS is built on the ARKit framework.

The project can be logically divided into four categories: User Input, AR Detection, Game Data, and Miscellaneous modules. The modules mentioned in this section may not directly correspond to the class design.

# Interaction Design

The following figure illustrates the user interface layout of our app. At the center of the screen, a semi-transparent place indicator provides users with a visual reference for domino placement. In the bottom-right corner, a rotation ring allows users to adjust the domino's orientation. Tapping the place button initiates the placement action.

![Annotated AR Domino placement interface](/assets/img/projects/ar_domino/domino_storytelling.jpg "Placement controls and interaction layout")

# Challenges

We encountered design and technical challenges during the development of our AR Domino game and devised solutions to address them. The two most significant challenges are outlined below.

## 1. Real-world scan-based object detection

Current 3D object detection technology and our hardware limitations posed obstacles to accurate and efficient real-world object detection. To overcome this, we opted for 2D image tracking instead of 3D scanning. We created trackable image patterns on stickers and affixed them to the desired real-world objects. The image tracking algorithm successfully recognizes these patterns within approximately 1 second, providing sufficient speed for our game.

## 2. Interaction with real-world and virtual objects

In our game, we sought to enable users to place virtual domino tiles on both real-world objects, such as AR planes and 3D-printed cubes, and virtual objects, such as the Box object. To achieve this, we converted real-world objects into virtual objects by spawning 3D models at the positions of tracked images. We devised a straightforward method to determine the placement of virtual objects: by generating two rays from the camera—one from the ARRaycastManager for detecting AR planes and another from the Physics object for detecting virtual objects—we compared the collision points of the rays and selected the closer one for object placement.
