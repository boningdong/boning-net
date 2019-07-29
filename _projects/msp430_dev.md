---
layout: post
title: MSP430 Development Board
---

# Descriptions 
The project is an MSP430F2132 development board with an RGB LED controller and extension connectors on it. I designed this development as a development tool board to fulfill my requirement of testing tasks of my Smart Lamp at Tsinghua University.

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
