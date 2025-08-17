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
    - java
---

<div class="col-lg-12 p-3">
    <img style="width: 100%; height: auto;" src="{{ site.baseurl }}/assets/img/projects/scopen_poster.jpg">
</div>

# Team Members
<div class="row text-center">
    <div class="col-4 p-2">
        <div class="pb-2">
            <a href="https://www.linkedin.com/in/byron-aguilar-a139057b/"><img src="{{ site.baseurl }}/assets/img/people/byron.png" style="width: 100%; height: auto; max-width: 200px;" alt="Byron Aguilar"></a>
        </div>
        <div class="">
          <h5 class="">Byron Aguilar</h5>
        </div>
    </div>
    <div class="col-4 p-2">
        <div class="pb-2">
            <a href="https://www.linkedin.com/in/boning-dong"><img src="{{ site.baseurl }}/assets/img/people/boning.png" style="width: 100%; height: auto; max-width: 200px;" alt="Boning Dong"></a>
        </div>
        <div class="">
          <h5 class="">Boning Dong</h5>
        </div>
    </div>
    <div class="col-4 p-2">
        <div class="pb-2">
            <a href="https://www.linkedin.com/in/cesar-gonzalez-0098341b0/"><img src="{{ site.baseurl }}/assets/img/people/cesar.png" style="width: 100%; height: auto; max-width: 200px;" alt="Cesar Gonzalez"></a>
        </div>
        <div class="">
          <h5 class="">Cesar Gonzalez</h5>
        </div>
    </div>
</div>


# Concept
Scopen is one of the UCSB CE 2020 capstone projects. We built this project not just for satisfying our curricular requirements, but more importantly, also for ourselves, because we always want to have an affordable, wireless, and handheld oscilloscope-like equipment, so that we can debug circuits easily.

# Product Videos
If you want to checkout our full presentation video, here is the link: <a href="https://youtu.be/ieGTWUUsJ_8">Scopen Presentation</a>
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
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_afe.jpg">
    </div>
    <div class="col-lg-12 p-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_mcu.jpg">
    </div>
</div>

One of the challenges we were facing is how to fit all of the components in a compact board, and at the same time, make sure that we can assemble the boards by ourselves (we need to solder them by ourselves).
To minimize the size of the board, we determined to place components on both sides of the PCB. Eventually, we built the whole system onto a 2.45" by 0.73", 6-layer printed circuit board (PCB), which is even smaller than a piece of regular gum.

<div class="row justify-content-center">
    <div class="col-lg-6 p-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_pcb_top.png">
    </div>
    <div class="col-lg-6 p-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_pcb_bottom.png">
    </div>
</div>

Here are the diagrams of all the layers.
<div class="row justify-content-center ">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_pcb_6_layers.png">
    </div>
</div>


# Firmware
Overall the firmware architecture can be seen from the following diagram.
<div class="row justify-content-center">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_firmware_stack.png">
    </div>
</div>

The STM32 firmware stack is on the left, and the right is the one for ESP32.
For the STM32 stack, as we can see, we build our project mainly based on the STM32 HAL Library, which provides the low-level drivers to most of the internal peripherals. For those peripherals on which we need special features, we wrote our own the low-level drivers based on the STM32 LL Library, which functions as the wrapper layer of the registers. For example, we need the restart feature of I2C to communicate with the touch sensor efficiently. So we wrote our I2C library based on the STM32 LL I2C Library.

One thing to notice in the middle layer is that the external sensors are driven based on the low-level drivers mentioned above. Another thing worth mentioning is that we used freeRTOS in this project because we need to let the controller run different tasks "at the same time."

On the top layer, as we can see, there are five threads in total in our final implementation.  Three of them handle communication, and two of them deal with the general logic.

The ESP32 stack is relatively simple because we wrote the firmware based on the Arduino Library. There are two threads in total: one for managing the downstream communication and the other one for upstream.

There are several challenges we were facing while developing the firmware. The first challenge is how to trigger the ADC sampling with a fixed time interval. We cannot use interrupts if we want to make the sampling trigger time to be accurate enough, because context switching takes time, and the exact time it takes is unpredictable. Our solution is to use HRTIM (High-Resolution Timer) as the triggering source to control when the ADCs start sampling. After each sampling finishes, the DMAs will move the result from the ADC result register to the external SRAM. The following diagram demonstrates our ideas.
<div class="row justify-content-center">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_adc_sampling.jpg">
    </div>
</div>

The second challenge we were facing is thread management. We used the CMSIS API based on the freeRTOS, which enables more than one thread to run on our platform. It's also worth mentioning that we used several semaphores to avoid the race conditions introduced by this multithreading scheme: one semaphore to control the access to the SPI interface and two semaphores to indicates the empty and occupied slots for each queue.
<div class="row justify-content-center">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_thread_manage.png">
    </div>
</div>

The last challenge we were dealing with is how to enable wireless communication between the pen and the PC/Mobile software. We eventually used the UDP and TCP protocols and implemented the message forwarding features on ESP32 with its Arduino library. Overall we have two threads that handle the upstream and downstream communication separately. The upstream communicate with the STM32 through the SPI interface because the upstream channel passes the sampling data, and the faster transfer speed of SPI can lessen its transfer time. The downstream communication with the STM32 is used for forwarding the user commands from the software to the pen, so a relatively slower UART interface is enough. Here is the block diagram.
<div class="row justify-content-center">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_esp.jpg">
    </div>
</div>

# Software
Nothing is unique about software development. The only thing worth mentioning is that we tried to follow the Model-View-Controller design pattern to develop our project. Overall the architecture is shown by the following diagram.
<div class="row justify-content-center">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_software_stack.png">
    </div>
</div>

We used the Java Swing library for the front-end UI. We wrote the code to draw the nobs line by line to have an expected design. Currently, we already have an intuitive and functional design with an elegant dark theme.
<div class="row justify-content-center">
    <div class="col-lg-12 px-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_software_interface.jpg">
    </div>
</div>

# Industrial Design
We also designed a case for our product using Autodesk Fusion 360, 3D printed it and assembled everything to make it like a real product. Here are some of the screenshots.
<div class="row justify-content-center">
    <div class="col-lg-12 p-3">
        <img class="project-photo mx-auto my-2 my-md-4" src="{{ site.baseurl }}/assets/img/projects/scopen_id_blue.png">
    </div>
    <div class="col-lg-12 p-3">
        <img class="project-photo mx-auto my-2 my-md-4 no-shadow" src="{{ site.baseurl }}/assets/img/projects/scopen_id_render.png">
    </div>
</div>

# Issues & Improvements
- We can rewrite the front-end software in JavaScript using React and Electron framework to improve the design and make it portable to different platforms.
- Current the sampling accuracy is not high and the resolution is not high enough (8 bit). We probably can tweak the parameters to sacrifice a portion of the speed to improve the accuracy, probably by enabling oversampling or simply increasing the sampling period.
- The touch sensor works from a prove-of-concept perspective but not good enough; it's not sensitive enough to respond to the user input.

# Acknowledgment
We want to give special thanks to **Prof. Yogananda Isukapalli** for managing the UCSB CE capstone program. We also want to thank our TAs **Kyle Douglas** and **Aditya Wadaskar** for giving us valuable advice, and **Jeff Longo** for helping us develop our mobile end app.