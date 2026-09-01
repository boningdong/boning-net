---
layout: project-detail
title: MSP430 Development Board
subtitle: A custom MSP430 development board for embedded prototyping.
date: 2016-04-24
cover: "/assets/img/projects/msp430_dev/cover.jpg"
tags:
    - hardware
    - firmware
    - embedded
    - c
    - pcb
---
Build the development tool the Smart Lamp needed.

I created this MSP430F2132 development board at Tsinghua University to test Smart Lamp hardware and firmware.

# Board Design

The board includes an RGB LED controller and extension connectors for embedded prototyping.

![Bare development board](/assets/img/projects/msp430_dev/msp430_devboard_3.jpg "Bare development board")

![Assembled development board](/assets/img/projects/msp430_dev/msp430_devboard_2.jpg "Assembled development board")

# Features

This board has the following features:

- It has a CP2102 USB-to-serial chip for firmware uploading.
- It integrates an NXP PCA family chip for RGB LED control.
- It includes three LEDs for testing GPIO functions and debugging.
- It provides power-selection jumpers that allow users to power the board using an external debugger.
- It supports both JTAG and serial protocols for burning firmware.

The whole project can be divided into the following development phases:

- Designing the hardware system
- Choosing the components
- Designing, manufacturing, and assembling the PCBs

![PCB fabrication stages](/assets/img/projects/msp430_dev/cover.jpg "PCB fabrication stages")
