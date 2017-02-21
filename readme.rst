========
MoodLamp
========

This is my take on an RGB mood lamp.

**WARNING!! As of -Q1 2017-, this is very much a “pre-alpha” or “WIP” (Work In Progress). This repository's contents should not be used as-is in any project for any reason at this time. In short, it's not close to done yet.**

Synopsis
---------------------
An RGB mood lamp creates soothing, beautiful soft light of endless colors. The light output gradually fades from one color to the next, creating a comfortable lighting experience. It achieves an endless range of colors and shades by using a semi opaque optical “diffuser” to mix varying amounts of RGB (Red, Green, and Blue) light together. Adding all this together gives rise to the name “RGB mood lamp.”

Overview
---------------------
At the lowest level, the system uses PWM (Pulse Width Modulation) and persistence of vision to vary the brightness of each LED. Pins of the microcontroler are rapidly switched on and off, which in turn, switch on and off LEDs. The time spent on vs. the time spent off is the duty cycle. Persistence of vision “averages” this duty cycle giving rise to the apparent varying brightness. Mixing the three primary colors at varying brightness's gives rise to the apparent varying color.

At the next level up, the system gradually shifts from one seed color value to the next. This is done using a process called interpolation, and governs the behavior of transitioning from one color to the next. There are two types of interpolation that are suited to an RGB mood lamp, “linear” and “spline.”

At the next level up, the system must generate the seed color values that lower layers will interpolate between. This can be done with a table, an algorithm, or from user input. Other external events could also change the way in which these colors are generated. Such as after an elapsed time, do something different for seed color output.

At the last level, the system does interface tasks.  This directs and controls the “mode” of the mood lamp. An example would be changing from full multi-color to just pulsing one’s favorite color. Another possible mode is full white (acting as a reading lamp or nightlight). Speed and variety of color would also be adjusted here.

The human interaction could be buttons, or something like an ESP8266 or similar Bluetooth board could be used for an interface to a cellphone or home network.

Function and Features
---------------------
This project is currently for the PIC18F27K40 and PIC18F13K50 microcontrolers. It should be trivial to port to any other Microchip part. Porting to a different language would be a bit more difficult, though a less developed PIC CX8 branch does exist (just not publicly).

By using optimized PIC18 ASM, the code is fast and small. Total code size at the time of writing this is less than 700 bytes, speed is about 20us per interpolation iteration for the PIC18F13K50 @ 32Mhz. Very efficient.

The implementation is intended to be able to control four sets of RGB LEDs, or 12 independent PWM channels total. That is, you can have four different colors actively lighting the diffuser at a time. With light piping or fiber-optics, one can use this feature to selective light specific areas of your diffuser.

So far this code uses spline interpolation to fade between the seed color values. Unlike linear interpolation, spline interpolation avoids abrupt transitions, especially when directly on seed values. This generally provides a more smooth experience. The implementation uses Cubic Hermite spline interpolation with optimizations for unit interval. This is plenty fast, making a linear interpolation option unnecessary.

Seed color values are generated using a 48 bit Galois LFSR (Linear Feedback Shift Register). This PRNG has very high entropy, is very white, and is plenty fast and small. Estimated time before the sequence will repeat is 178 years @ 50K iterations a second. Some initial seeds are given at the top of the source file.

Much of the operations are done layer at a time in large batches, that is, “pipe-lined.” This allows the overhead of context switching to be hidden, at the expense of needing large buffers to hold intermediate work. 

The lowest layer of the system, the PWM layer, has an inherent wait-time component. The system only really needs to deal with PWM code for the short time the pins need their state changed. The implementation is designed from the ground up to take advantage of this idle time to do other things.  This GREATLY improves total throughput and performance.


TODOs
---------------------
This project is just getting underway, so there is much to be done. This is by no means an exhaustive list.

- There is no interface code yet. All settings and selections are being done in source through the development environment and debug equipment. This is mostly an artifact of the fact that this is a microcontroler project. The running firmware needs interaction with physical parts to really constitute a complete interface.

- The system doesn’t save the PRNG state. For this reason, if the system loses power, the PRNG will reload the starting seed value and the colors will repeat.

- The the code that accesses the ring buffers is not centralized. The duplication of code here is undesired. This should be refactored into a proper subroutine with the capability of pointing to the ring buffer being processed.

- Several LUTs have been provided for Cubic Hermite spline, but switching between them is currently a manual operation done in source. A way to do this with firmware setting would be preferred.

- Although the intended design is to allow four independent color channels, code currently does not do this. It currently generates color for one channel, and copies it to the other three. This is a difficult problem to do, as success is VERY performance dependent.

- Source currently needs several tweaks when changing target devices. It is desirable for this to be done with a simple switch at the top of the source file.






