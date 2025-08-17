---
layout: project-pos
title: MSP430 Development Board
subtitle: A development board for MSP430.
date: 2016-04-24
cover: "/assets/img/projects/msp430_devboard_cover.jpg"
tags:
    - hardware
    - firmware
    - embedded
    - c
    - pcb
---
# Descriptions
The project is an MSP430F2132 development board with an RGB LED controller and extension connectors on it. I designed this development as a development tool board to fulfill my requirement of testing tasks of my Smart Lamp at Tsinghua University.
<div class="row d-flex">
    <div class="col-lg-6">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/msp430_devboard_3.jpg">
    </div>
    <div class="col-lg-6">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/msp430_devboard_2.jpg">
    </div>
</div>
This board has the following features:
- It has a CP2102 USB to Serial chip for firmware uploading
- Integrates an NXP PCA family chip for RGB LED control.
- Includes 3 LED for testing the GPIO functions and debugging purpose.
- Provides power selection jumpers that allow users to power the board using an external debugger.
- Support both JTAG and Serial protocol to burn the firmware.
The whole project can be divided into the following phrases:
    - designing the hardware systems
    - choosing the components
    - designing, manufacturing and assembling the  PCBs
<div class="row d-flex">
    <div class="col-lg-11">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/msp430_devboard_1.jpg">
    </div>
</div>
