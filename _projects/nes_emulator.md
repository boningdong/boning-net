---
layout: project-detail
title: NES Emulator Project
subtitle: A custom game console that runs NES software on an STM32.
date: 2019-05-08
cover: "/assets/img/projects/nes_emulator/cover.jpg"
external-link: 'https://github.com/boningdong/STM32-NES-Console-Hardware'
tags:
    - hardware
    - system-design
    - firmware
    - embedded
    - c
    - pcb
---
Build the console, then emulate the machine.

Jeff and I designed and built a custom hardware game console for UCSB ECE 153B. The console combines a purpose-built PCB with STM32 firmware that emulates NES software.

::: featured-link
[View source on GitHub](https://github.com/boningdong/STM32-NES-Console-Hardware)
:::

# Context

The goal of this project was to build a hardware game console and develop firmware on an STM32 processor to emulate the NES processor so the console could run NES games.

Jeff originated the idea because he is a big fan of NES games and had always wanted to work on a project like this. Although I am not as interested in NES games as he is, the engineering process involved attracted me.

# Engineering Challenges

This project is challenging in the following aspects:

- We needed to finish the hardware design in only one week, including system design, component selection, schematic design, and PCB layout design.
- We had to make sure the system did not have hardware-level mistakes in the first version.
- A 24-bit parallel LCD screen is used in this system, which adds difficulty to port planning, PCB layout work, and firmware development.
- External SDRAM is used, which makes it harder to plan the ports and route the PCB.
- Developing firmware to emulate the NES CPU and PPU is tedious.

# Development

The whole project can be divided into the following phases:

- Planning the functionality
- Designing the hardware systems
- Choosing the components
- Designing, manufacturing, and assembling the PCBs
- Developing the firmware

![Bare console PCB](/assets/img/projects/nes_emulator/nes_emulator_5.jpg "Bare console PCB")

![Console PCB underside](/assets/img/projects/nes_emulator/nes_emulator_4.jpg "Console PCB underside")

![Console board with display](/assets/img/projects/nes_emulator/nes_emulator_2.jpg "Console board with display")

![Assembled console](/assets/img/projects/nes_emulator/cover.jpg "Assembled console")

# Current Status

Currently, we have finished the PCB board design and assembly work. The driver-level firmware has been completed and tested. The CPU and PPU are almost finished but still need bug fixes and further testing. (Updated 07/28/2019)
