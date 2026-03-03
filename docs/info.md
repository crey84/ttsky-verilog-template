<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

A counter cycles through values 1 to 6 to continuously at clock speed,Because the counter moves faster than a human can perceive, the value it holds at any moment is effectively unpredictable, simulating a random dice roll. When the roll button (ui_in[0]) is pressed and released, the current counter value is latched into an output register and held stable. A debounce circuit filters mechanical noise from the button to ensure only one clean edge is detected per roll

## How to test

Apply reset by holding rst_n low then releasing it high. The output uo_out[2:0] should read 1 (binary 001). Press and release ui_in[0] to roll. Verify that uo_out[2:0] shows a value between 1 and 6. Roll multiple times and confirm the result only updates on button release, not while the button is held down. The result should remain stable between rolls.

## External hardware

No external hardware is required. Optionally connect uo_out[2:0] to 3 LEDs to display the binary dice result, where bit 0 is the LSB.
