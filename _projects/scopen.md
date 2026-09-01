---
layout: project-detail
title: Scopen
subtitle: A wireless oscilloscope designed to make circuit debugging portable.
date: 2020-06-15
cover: /assets/img/projects/scopen/cover-logo-flat-v2.png
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
      role: Electrical Engineer
      image: /assets/img/people/byron.png
    - name: Boning Dong
      role: Computer Engineer
      image: /assets/img/people/boning.png
      url: https://www.linkedin.com/in/boning-dong
    - name: Cesar Gonzalez
      role: Electrical Engineer
      image: /assets/img/people/cesar.png
      url: https://www.linkedin.com/in/cesar-gonzalez-0098341b0/
---
A lab instrument that fits in your pocket.

Scopen began with a practical frustration: oscilloscopes are indispensable but rarely close at hand. We designed an affordable wireless probe that captures a signal, processes it on-device, and streams the samples to a desktop interface.

::: featured-link
[Watch the presentation](https://youtu.be/ieGTWUUsJ_8)
:::

# Context

For our UCSB Computer Engineering capstone, Scopen was not intended to replace a laboratory oscilloscope. We focused on the essential path: condition the input, sample it reliably, move the data wirelessly, and present it clearly on a desktop.

::: video-embed
[Working prototype demo](https://youtu.be/fFWyjB_XNrE "Working prototype demo")
:::

The rest of the project follows that signal path from the circuit board to firmware, software, and the enclosure.

# Hardware

::: narrative-title
Two systems, one very narrow board.
:::

The board combines an isolated analog front end with an STM32 and ESP32 control system. One path conditions the signal; the other samples, stores, and transmits it.

::: callout
**2.45 × 0.73 in**

The electrical system fits on a six-layer printed circuit board. Placing components on both sides kept the board narrower than a stick of gum while leaving the prototype practical to assemble by hand.
:::

That packaging constraint shaped the board before it shaped the enclosure. Components occupy both faces of the same narrow footprint.

![Top side of the assembled Scopen circuit board](/assets/img/projects/scopen/scopen_pcb_top.png "Top side PCB - main controller and signal circuitry")

![Bottom side of the assembled Scopen circuit board](/assets/img/projects/scopen/scopen_pcb_bottom.png "Bottom side PCB - SRAM, AFE and debug interface")

The two populated faces solved the component-density problem. The six-layer stack handled routing, power distribution, and separation between the signal and control domains.

![Exploded diagram of all six Scopen PCB layers](/assets/img/projects/scopen/scopen_pcb_6_layers.png "Six-layer PCB stack")

The physical stack supports two electrical domains that must cooperate without compromising the signal. The analog path conditions the input; the controller path captures the result and coordinates every other subsystem.

![Block diagram of the Scopen analog front end](/assets/img/projects/scopen/scopen_afe.jpg "Analog front-end architecture")

![Block diagram of the Scopen microcontroller system](/assets/img/projects/scopen/scopen_mcu.jpg "Controller subsystems")

# Firmware

::: narrative-title
Keep sampling deterministic. Move everything else around it.
:::

The firmware spans two controllers. An STM32 handles acquisition, local storage, touch input, and device state. An ESP32 bridges the instrument to the desktop application over WiFi. The system is divided by responsibility rather than by feature: time-critical acquisition stays close to the STM32 peripherals, while communication and product behavior run in layers above the hardware drivers.

![Layered architecture of the STM32 and ESP32 firmware](/assets/img/projects/scopen/scopen_firmware_stack.png "Firmware stack")

That separation left two critical problems to solve: sampling at a fixed interval and moving data without interrupting acquisition.

## Deterministic Acquisition

Fixed-interval sampling could not depend on software interrupt timing. The High Resolution Timer triggers the ADCs in hardware, and DMA moves each completed conversion directly into external SRAM.

![HRTIM triggered ADC and DMA sampling sequence](/assets/img/projects/scopen/scopen_adc_sampling.jpg "ADC & DMA sampling sequence")

## Task Orchestration

The STM32 stack combines HAL drivers with targeted low-level drivers where tighter control was required. One example is repeated-start I2C communication with the touch sensor. FreeRTOS coordinates five tasks: three for communication and two for the instrument's core logic. Semaphores protect the SPI bus and track empty and occupied queue slots.

![FreeRTOS task and semaphore relationships](/assets/img/projects/scopen/scopen_thread_manage.png "Synchronization design")

With acquisition and task coordination separated, the remaining problem is moving samples off the instrument without blocking either path.

## Wireless Bridge

The ESP32 runs separate upstream and downstream paths. Sample data travels from the STM32 over SPI because throughput matters most in that direction. User commands return over UART, where the lower bandwidth is sufficient. The ESP32 then forwards both paths through UDP and TCP connections.

![Wireless data paths between STM32, ESP32, and desktop software](/assets/img/projects/scopen/scopen_esp.jpg "STM32-to-desktop data path")

By the time samples reach the desktop, acquisition timing is already isolated from user interaction and network latency.

# Software

::: narrative-title
Make the system feel like an instrument.
:::

The desktop application follows a Model View Controller structure so acquisition, rendering, and interaction can evolve independently.

![Model View Controller architecture of the Scopen desktop application](/assets/img/projects/scopen/scopen_software_stack.png "Model View Controller architecture of the PC app")

That separation keeps device communication out of the rendering path and gives the interface one consistent model of the current acquisition state.

## Instrument Interface

We built the interface in Java Swing and drew the oscilloscope controls specifically for the product rather than relying on stock widgets. The result combines live signal display, acquisition controls, and device communication in one dark workspace.

![Scopen Java Swing desktop interface showing a live waveform](/assets/img/projects/scopen/scopen_software_interface.jpg "Desktop instrument interface")

The interface completed the signal path, but the electronics still needed to become a device someone could hold.

# Industrial Design

::: narrative-title
Turn the board into a handheld instrument.
:::

With the electrical and software systems working, the final task was packaging the board without compromising access to the probe, controls, or connectors.

We modeled the enclosure in Fusion 360, then printed and assembled several iterations at product scale.

![Fusion 360 model of the blue Scopen enclosure](/assets/img/projects/scopen/scopen_id_blue.png "Enclosure CAD study")

::: video-embed
[Rendered product video](https://youtu.be/4xJvWEb1Kwo "Rendered product video")
:::

# Team

Scopen was created by three engineering students working across hardware, firmware, software, and industrial design.

::: people source=team
:::

## Acknowledgements

Thanks to Professor Yogananda Isukapalli for leading the UCSB Computer Engineering capstone program, Kyle Douglas and Aditya Wadaskar for their technical guidance, and Jeff Longo for his help with the mobile application.
