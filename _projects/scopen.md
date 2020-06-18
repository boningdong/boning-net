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

# Team Members
Scopen is one of the UCSB CE 2020 capstone projects. We built this project not just for satisfying our curricular requirements, but more importantly, also for ourselves, because we always want to have an affordable, wireless, and handheld oscilloscope-like equipment, so that we can debug circuits easily.

# Concept
Scopen is one of the UCSB CE 2020 capstone projects. We built this project not just for satisfying our curricular requirements, but more importantly, also for ourselves, because we always want to have an affordable, wireless, and handheld oscilloscope-like equipment, so that we can debug circuits easily.

# Product Videos
<div class="row justify-content-center">
    <div class="col-lg-6 p-2">
        <div class="video-container">
            <iframe src="https://www.youtube.com/embed/4xJvWEb1Kwo" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
        </div>
    </div>
    <div class="col-lg-6 p-2">
        <div class="video-container">
            <iframe src="https://www.youtube.com/embed/fFWyjB_XNrE" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
        </div>
    </div>
</div>
 
# Hardware
Overall, the hardware system consists of two parts, the Analog Front End (AFE), which handles isolating the scaling the input signal, and the microcontroller system (MCU), which deals with sampling the output from the AFE and managing the surrounding peripherals. In detail, the AFE consists of several stages to isolate the input signal, to scale up and down, and to make the output signal to be differential respectively. In addition to the main microcontroller, the MCU system also includes an external SRAM memory (for storing the sampled data), a touch sensor (for providing an intuitive user interaction), and a WiFi controller (for handling the communication between MCU and PC/Phone App). The architecture of the AFE and the MCU system can be seen from the following two diagrams.

<div class="row justify-content-center">
    <div class="col-lg-12 p-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_afe.jpg">
    </div>
    <div class="col-lg-12 p-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_mcu.jpg">
    </div>
</div>

One of the challenges we were facing is how to fit all of the components in a compact board, and at the same time, make sure that we can assemble the boards by ourselves (we need to solder them by ourselves).
To minimize the size of the board, we determined to place components on both sides of the PCB. Eventually, we built the whole system onto a 2.45" by 0.73", 6-layer printed circuit board (PCB), which is even smaller than a piece of regular gum.

<div class="row justify-content-center">
    <div class="col-lg-6 p-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_pcb_top.png">
    </div>
    <div class="col-lg-6 p-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_pcb_bottom.png">
    </div>
</div>

Here are the diagrams of all the layers.
<div class="row justify-content-center">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_pcb_6_layers.png">
    </div>
</div>


# Firmware
Overall the firmware architecture can be seen from the following diagram.
<div class="row justify-content-center">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_firmware_stack.png">
    </div>
</div>

The STM32 firmware stack is on the left, and the right is the one for ESP32.
For the STM32 stack, as we can see, we build our project mainly based on the STM32 HAL Library, which provides the low-level drivers to most of the internal peripherals. For those peripherals on which we need special features, we wrote our own the low-level drivers based on the STM32 LL Library, which functions as the wrapper layer of the registers. For example, we need the restart feature of I2C to communicate with the touch sensor efficiently. So we wrote our I2C library based on the STM32 LL I2C Library.

One thing to notice in the middle layer is that the external sensors are driven based on the low-level drivers mentioned above. Another thing worth mentioning is that we used freeRTOS in this project because we need to let the controller run different tasks "at the same time."

On the top layer, as we can see, there are five threads in total in our final implementation.  Three of them handle communication, and two of them deal with the general logic.

The ESP32 stack is relatively simple because we wrote the firmware based on the Arduino Library. There are two threads in total: one for managing the downstream communication and the other one for upstream.

# Software
Nothing is unique about software development. The only thing worth mentioning is that we tried to follow the Model-View-Controller design pattern to develop our project. Overall the architecture is shown by the following diagram.
<div class="row justify-content-center">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_software_stack.png">
    </div>
</div>

We used the Java Swing library for the front-end UI. We wrote the code to draw the nobs line by line to have an expected design. Currently, we already have an intuitive and functional design with an elegant dark theme.

# Industrial Design
We also designed a case for our product using Autodesk Fusion 360, 3D printed it and assembled everything to make it like a real product. Here are some of the screenshots.
<div class="row justify-content-center">
    <div class="col-lg-12 p-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_id_blue.png">
    </div>
    <div class="col-lg-12 p-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_id_render.png">
    </div>
</div>

# Issues & Improvements
We can rewrote the front-end software in JavaScript using React and Electron framework to improve the design and make it portable to different platforms.
Current the sampling accuracy is not high and the resolution is not high enough (8 bit). We probably can tweak the parameters to sacrifice portion of the speed to improve the accuracy, probably by enabling oversampling or simply increasing the sampling period.
Touch sensor works from an prove-of-concept pespective but not good enough; it's not sensitive enough to response to the user input.
