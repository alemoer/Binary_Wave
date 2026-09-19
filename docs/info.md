<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

CDM Matrix is a VGA "digital rain" display. It outputs 640x480 at 60 Hz from a 25.175 MHz clock and needs no memory: every pixel is calculated on the fly.

- **Character grid.** The screen is divided into 8x12-pixel cells (80 columns by 40 rows). A small glyph ROM holds an 8x12 bitmap for each character.
- **The message.** The character shown in each cell is picked from the phrase **COLEGIO DE MUNTINLUPA** (21 characters, uppercase). The index is `(row + column) mod 21`, so every column reads the phrase from top to bottom and repeats it, with each neighboring column shifted by one letter.
- **The rain.** A frame counter, advanced once per frame on VSync, drives falling "drops". Each column has its own speed and offset, some columns are switched off, and each drop has a bright leading edge that fades into a colored tail. For roughly the first thousand frames (about 17 seconds) the rain sweeps in from the top of the screen; after that the full rain runs continuously.
- **Colors.** The fade uses one of four 6-bit (2 bits per channel) palettes stored in a small ROM.

Modules: `tt_um_vga_glyph_mode` (top level, message and rain logic), `glyphs_rom` (character bitmaps), `palette_rom` (colors), `hvsync_generator` (VGA timing).

## How to test

1. Connect a TinyVGA Pmod to the output pins `uo[7:0]` and plug it into a VGA monitor.
2. Run the design with a 25.175 MHz clock. Keep `ui[7:6]` low (640x480 mode) and reset with `rst_n`.
3. Green rain made of the letters of COLEGIO DE MUNTINLUPA should appear.
4. Change the palette with `ui[1:0]`: `00` green, `01` red, `10` blue, `11` pride.

The design can also be tried in the Tiny Tapeout VGA Playground.

## External hardware

- TinyVGA Pmod (VGA output) on the dedicated outputs
- A VGA monitor
- No other hardware is needed

## Credits

This design is based on the `tt_um_vga_glyph_mode` matrix-rain design by James Ross (Apache-2.0). The change made for this project is the message: the glyph index is taken from the phrase COLEGIO DE MUNTINLUPA instead of cycling through the whole glyph set.
