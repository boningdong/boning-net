---
layout: project-detail
title: Smart Lamp
subtitle: A Bluetooth-controlled smart lamp designed from hardware to enclosure.
date: 2016-07-21
cover: "/assets/img/projects/smartlamp/cover-product.png"
external-link: 'https://github.com/boningdong/Smart-Lamp'
tags:
    - hardware
    - system-design
    - firmware
    - embedded
    - c
    - pcb
---
A connected light designed as a complete product.

Smart Lamp began as a gift for my high-school friends and teachers before I moved to the United States. Building on work from Dr. Lintao Tang's lab at Tsinghua University, I designed the hardware, firmware, and enclosure as one system.

::: featured-link
[View source on GitHub](https://github.com/boningdong/Smart-Lamp)
:::

# Context

I planned to build this project as a gift for my high-school friends and teachers before I moved to the United States for my Bachelor's degree. Unfortunately, I could not produce enough lamps because of time limitations.

![Warm white lamp](/assets/img/projects/smartlamp/smartlamp_5.jpg "Warm white lamp")

![Red lamp](/assets/img/projects/smartlamp/smartlamp_3.jpg "Red lamp")

![Purple lamp](/assets/img/projects/smartlamp/smartlamp_6.jpg "Purple lamp")

# Features

The lamp has the following features:

- The lamp can be controlled through a capacitive touch interface and Bluetooth.
- The capacitive touch interface has one button that supports on/off and dimming control.
- Users can connect to the lamp with Bluetooth to control dimming, color, and on/off functions.
- The lamp supports wireless charging and charging through Micro-USB.
- The lamp integrates a battery management system for three-phase charging of an 18650 battery.
- An MSP430 MCU achieves low power consumption.

# Development

I designed the product from scratch, including the hardware, firmware, and industrial design.

The project followed these development phases:

- Planning the functionality
- Developing the industrial design, planning dimensions, and creating 3D models
- Designing the hardware systems
- Choosing components
- Designing, manufacturing, and assembling the PCBs
- Developing the firmware

![Smart Lamp electronics](/assets/img/projects/smartlamp/smartlamp_1.jpg "Smart Lamp electronics")

![LED module](/assets/img/projects/smartlamp/smartlamp_4.jpg "LED module")
