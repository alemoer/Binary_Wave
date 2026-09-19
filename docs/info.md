<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Binary Wave is a VGA display of rolling waves made of 1s and 0s. It outputs 640x480 at 60 Hz from a 25.175 MHz clock and needs no memory: every pixel is calculated on the fly.

- **Character grid.** The screen is divided into 8x8-pixel cells (80 columns by 60 rows). The only characters are `1` and a slashed `0`, drawn as 5x7 bitmaps directly in logic, so no glyph ROM is needed.
- **Wave layers.** Eight layers each draw a line of characters that follows its own wave. The height of a layer at each column is the sum of two triangle waves with softened peaks: one drifts right and one ripples left at a different speed. Every layer has its own phase offset, so the layers roll against each other like a 3D surface. The front layers swing more than the back ones.
- **Ones and zeros.** Whether a cell shows `1` or `0` depends on the wave height at that spot, so the digits flip as a wave passes over them. Each line is two rows thick: a bright row with a dimmer row under it.
- **Animation.** A frame counter, advanced once per frame at the start of vertical blanking, moves the waves.
- **Colors.** Colors use 2 bits per channel. Layers go from dark blue-teal at the back to bright cyan at the front. `1` uses the layer color and `0` is slightly greener.

The design has no inputs. The VGA mode is fixed to 640x480.

Modules: `tt_um_alemoer_binary_wave` (top level: wave, glyph and color logic) and `hvsync_generator` (VGA timing).

## How to test

1. Connect a TinyVGA Pmod to the output pins `uo[7:0]` and plug it into a VGA monitor.
2. Run the design with a 25.175 MHz clock and reset with `rst_n`. No input pins are used.
3. Rolling waves made of teal and cyan 1s and 0s should appear on a black background and keep moving.

The design can also be tried in the Tiny Tapeout VGA Playground.

## External hardware

- TinyVGA Pmod (VGA output) on the dedicated outputs
- A VGA monitor
- No other hardware is needed

## Credits

The VGA timing module `hvsync_generator` comes from the `tt_um_vga_glyph_mode` design by James Ross (Apache-2.0). The wave, glyph and color logic in the top module is new for this project.