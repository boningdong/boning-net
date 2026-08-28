---
layout: project-detail
title: Scopen
subtitle: A wireless oscilloscope designed to make circuit debugging portable.
date: 2020-06-15
cover: /assets/img/projects/scopen/cover-logo.png
featured: true
featured-order: 1
tags:
  - hardware
  - system-design
  - firmware
  - embedded
  - c
  - pcb
  - java
people:
  team:
    - name: Byron Aguilar
      role: Computer Engineer
      image: /assets/img/people/byron.png
      url: https://www.linkedin.com/in/byron-aguilar-a139057b/
    - name: Boning Dong
      role: Computer Engineer
      image: /assets/img/people/boning.png
      url: https://www.linkedin.com/in/boning-dong
    - name: Cesar Gonzalez
      role: Computer Engineer
      image: /assets/img/people/cesar.png
      url: https://www.linkedin.com/in/cesar-gonzalez-0098341b0/
---
A lab instrument that fits in your pocket.

Scopen began with a practical frustration: oscilloscopes are indispensable but rarely close at hand. We designed an affordable wireless probe that captures a signal, processes it on-device, and streams the samples to a desktop interface.

# Context

Oscilloscopes are indispensable when debugging electronics, but they are rarely close at hand. For our UCSB Computer Engineering capstone, we designed an affordable wireless probe that captures a signal, processes it on the device, and streams the result to a desktop interface.

The goal was not to replace a full laboratory oscilloscope. We wanted the most useful parts of one in a compact instrument that we could carry between a bench, a classroom, and a field project.

![Scopen capstone poster](/assets/img/projects/scopen/scopen_poster.jpg "Capstone poster summarizing the Scopen system.")

The complete design and development process is covered in the presentation.

::: featured-link
[Watch the Scopen presentation](https://youtu.be/ieGTWUUsJ_8)
:::

These shorter demonstrations show the physical prototype and software working together.

::: videos
[Scopen hardware demonstration](https://youtu.be/4xJvWEb1Kwo "Physical prototype and signal capture demonstration.")

[Scopen software demonstration](https://youtu.be/fFWyjB_XNrE "Desktop interface and wireless workflow demonstration.")
:::

# Hardware

::: narrative-title
Two systems, one very narrow board.
:::

The board is built around two tightly coupled systems. The analog front end isolates and scales the incoming signal before producing a differential output. The controller side samples that output, stores data in external SRAM, reads touch input, and manages the wireless link.

::: gallery
![Block diagram of the Scopen analog front end](/assets/img/projects/scopen/scopen_afe.jpg "Analog front end: isolation, gain control, and differential conversion.")

![Block diagram of the Scopen microcontroller system](/assets/img/projects/scopen/scopen_mcu.jpg "Controller system: STM32, SRAM, touch input, and WiFi controller.")
:::

::: callout
**2.45 × 0.73 in**

The electrical system fits on a six-layer printed circuit board. Placing components on both sides kept the board narrower than a stick of gum while leaving the prototype practical to assemble by hand.
:::

::: gallery
![Top side of the assembled Scopen circuit board](/assets/img/projects/scopen/scopen_pcb_top.png "Top side with the primary controller and signal circuitry.")

![Bottom side of the assembled Scopen circuit board](/assets/img/projects/scopen/scopen_pcb_bottom.png "Bottom side with supporting components and interconnects.")
:::

![Exploded diagram of all six Scopen PCB layers](/assets/img/projects/scopen/scopen_pcb_6_layers.png "Exploded view of the six-layer PCB stack.")

# Firmware

The firmware spans two controllers. An STM32 handles acquisition, local storage, touch input, and device state. An ESP32 bridges the instrument to the desktop application over WiFi.

![Layered architecture of the STM32 and ESP32 firmware](/assets/img/projects/scopen/scopen_firmware_stack.png "Layered architecture of the STM32 and ESP32 firmware.")

The STM32 stack combines HAL drivers with targeted low-level drivers where tighter control was required. One example is repeated-start I2C communication with the touch sensor. FreeRTOS coordinates five tasks: three for communication and two for the instrument's core logic. Semaphores protect the SPI bus and track empty and occupied queue slots.

Fixed-interval sampling could not depend on software interrupt timing. The High Resolution Timer triggers the ADCs in hardware, and DMA moves each completed conversion directly into external SRAM.

![HRTIM triggered ADC and DMA sampling sequence](/assets/img/projects/scopen/scopen_adc_sampling.jpg "HRTIM-triggered ADC and DMA sampling sequence.")

![FreeRTOS task and semaphore relationships](/assets/img/projects/scopen/scopen_thread_manage.png "FreeRTOS task and semaphore relationships.")

The ESP32 runs separate upstream and downstream paths. Sample data travels from the STM32 over SPI because throughput matters most in that direction. User commands return over UART, where the lower bandwidth is sufficient. The ESP32 then forwards both paths through UDP and TCP connections.

![Wireless data paths between STM32, ESP32, and desktop software](/assets/img/projects/scopen/scopen_esp.jpg "Wireless data paths between STM32, ESP32, and desktop software.")

# Software

The desktop application follows a Model View Controller structure so acquisition, rendering, and interaction can evolve independently.

![Model View Controller architecture of the Scopen desktop application](/assets/img/projects/scopen/scopen_software_stack.png "Model View Controller architecture of the Scopen desktop application.")

We built the interface in Java Swing and drew the oscilloscope controls specifically for the product rather than relying on stock widgets. The result combines live signal display, acquisition controls, and device communication in one dark workspace.

![Scopen Java Swing desktop interface showing a live waveform](/assets/img/projects/scopen/scopen_software_interface.jpg "Java Swing desktop interface showing a live waveform.")

## Industrial Design

The electronics were packaged in a handheld enclosure designed in Autodesk Fusion 360. We printed and assembled several iterations to validate access to the probe, controls, connectors, and internal board.

::: gallery
![Fusion 360 model of the blue Scopen enclosure](/assets/img/projects/scopen/scopen_id_blue.png "Enclosure geometry developed around the narrow circuit board.")

![Rendered view of the assembled Scopen handheld enclosure](/assets/img/projects/scopen/scopen_id_render.png "Assembled product study with probe, controls, and display window.")
:::

## What we would improve

- Replace the Java Swing desktop client with a portable web-based application.
- Trade some sampling speed for higher effective resolution through longer sample periods or oversampling.
- Refine the capacitive touch system beyond the proof of concept so interaction remains reliable across enclosure and environmental changes.

# Team

Scopen was created by three computer engineering students across hardware, firmware, software, and industrial design.

::: people source=team
:::

## Acknowledgements

We thank Professor Yogananda Isukapalli for leading the UCSB Computer Engineering capstone program; Kyle Douglas and Aditya Wadaskar for their technical guidance; and Jeff Longo for helping develop the mobile application.
