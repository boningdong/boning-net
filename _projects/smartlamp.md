---
layout: project-post
title: Smart Lamp
subtitle: A Bluetooth controlled smart lamp.
date: 2016-07-21
cover: "/assets/img/projects/smartlamp_cover.jpg"
external-link: 'https://github.com/boningdong/Smart-Lamp'
tags:
    - hardware
    - system-design
    - firmware
    - embedded
    - c
    - pcb
---

<div class="row d-flex">
    <div class="col-lg-4">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/smartlamp_5.jpg">
    </div>
    <div class="col-lg-4">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/smartlamp_3.jpg">
    </div>
    <div class="col-lg-4">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/smartlamp_6.jpg">
    </div>
</div>

# Description
I planned to build this project as a gift to my high school friends and teachers before I went to the US for my Bachelor's' degree. But unfortunately, I couldn't produce enough of them because of the limitation of time.

This project is based on my work at Dr. Lintao Tang's lab at Tsinghua University. The details can be found in my Tsinghua Smart Lamp page.
As usual, I tried to build a "product-level" product and design everything from scratch; from hardware, to firmware, and even to industrial design (ID design).

## The simulator has the following features:
- The lamp can be controlled by capacitive touch interface and by Bluetooth.
- The capacitive touch interface has just one button but supports both on/off control and dimming control.
- Users can connect the lamp using Bluetooth and control the dimming, color, and on/off of the lamp. 
- The lamp supports both wireless charging and charging through Micro-USB.
- The lamp integrates a battery management system to three phrases charging management for 18650 battery.
- MSP430 MCU is used to achieve low power consumption.

## The whole project can be divided into the following phrases:
- planing the functionalities
- thinking about the ID design, planing the dimensions and creating the 3D models.
- designing the hardware systems
- choosing the components
- designing, manufacturing and assembling the  PCBs
- developing the firmware

<div class="row d-flex">
    <div class="col-lg-6">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/smartlamp_1.jpg">
    </div>
    <div class="col-lg-6">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/smartlamp_4.jpg">
    </div>
</div>
