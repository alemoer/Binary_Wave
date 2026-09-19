/*
 * Binary Wave - rolling waves made of 1s and 0s (VGA, Tiny Tapeout)
 *
 * 80 x 60 grid of 8x8 characters. Eight wave "layers" scroll and drift;
 * each layer is a row of 1s and 0s that follows its own wave line.
 * Back layers are dark teal, the front layer is bright.
 * No inputs. Needs hvsync_generator.v (already in the playground and in src/).
 */

`default_nettype none

module tt_um_alemoer_binary_wave (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // ---------------------------------------------------------------
  // VGA timing
  // ---------------------------------------------------------------
  wire hsync, vsync, display_on;
  wire [10:0] hpos;
  wire [9:0] vpos;

  hvsync_generator hvsync_gen (
      .clk(clk),
      .reset(~rst_n),
      .mode(2'b00),  // 640x480 @ 60 Hz
      .hsync(hsync),
      .vsync(vsync),
      .display_on(display_on),
      .hpos(hpos),
      .vpos(vpos)
  );

  reg [5:0] RGB;  // {R[1:0], G[1:0], B[1:0]}
  assign uo_out  = {hsync, RGB[0], RGB[2], RGB[4], vsync, RGB[1], RGB[3], RGB[5]};
  assign uio_out = 0;
  assign uio_oe  = 0;

  wire _unused_ok = &{ena, ui_in, uio_in};

  // ---------------------------------------------------------------
  // Time: one count per frame
  // ---------------------------------------------------------------
  reg [7:0] t;
  wire tick = (hpos == 11'd0) && (vpos == 10'd480);
  always @(posedge clk) begin
    if (!rst_n) t <= 0;
    else if (tick) t <= t + 8'd1;
  end

  // ---------------------------------------------------------------
  // Wave layers
  // ---------------------------------------------------------------
  wire [6:0] cx = hpos[9:3];  // character column 0..79
  wire [5:0] cy = vpos[8:3];  // character row    0..59
  wire [2:0] gx = hpos[2:0];  // pixel inside the character
  wire [2:0] gy = vpos[2:0];

  // triangle wave, 0..31, period 64
  function [4:0] tw(input [5:0] u);
    tw = u[5] ? ~u[4:0] : u[4:0];
  endfunction

  // soften the triangle: flatter tops and bottoms, 0..23
  function [4:0] ease(input [4:0] a);
    if (a < 5'd8) ease = {2'b0, a[4:1]};
    else if (a < 5'd24) ease = a - 5'd4;
    else ease = 5'd20 + {2'b0, a[3:1]};
  endfunction

  // wave height 0..34 for layer k at column c
  function [5:0] wave(input [2:0] k, input [6:0] c);
    reg [5:0] ua, ub, pa, pb;
    reg [4:0] a, b;
    begin
      pa = {k, 3'b0} + {3'b0, k};                // k*9
      pb = {k, 2'b0} + {3'b0, k};                // k*5
      ua = {c[4:0], 1'b0} + pa + t[6:1];         // slow drift right
      ub = {c[4:0], 1'b0} + c[5:0] + pb - t[7:2];// faster ripple left
      a = tw(ua);
      b = tw(ub);
      wave = {1'b0, ease(a)} + {2'b0, ease(b) >> 1};
    end
  endfunction

  // screen row of layer k at column c (front layers swing more)
  function [5:0] layer_y(input [2:0] k, input [6:0] c);
    reg [5:0] w, s;
    begin
      w = wave(k, c);
      s = (k >= 3'd4) ? (w >> 1) : (w >> 2);
      layer_y = 6'd8 + {k, 2'b0} + {3'b0, k} + ((k >= 3'd4) ? 6'd17 : 6'd8) - s;
    end
  endfunction

  // layer color: dark teal (back) -> bright (front)
  function [5:0] layer_col(input [2:0] k);
    case (k)
      3'd0: layer_col = 6'b00_01_10;
      3'd1: layer_col = 6'b00_10_10;
      3'd2: layer_col = 6'b00_10_11;
      3'd3: layer_col = 6'b00_11_11;
      3'd4: layer_col = 6'b00_11_11;
      3'd5: layer_col = 6'b01_11_11;
      3'd6: layer_col = 6'b01_11_11;
      default: layer_col = 6'b10_11_11;
    endcase
  endfunction

  // 5x7 glyphs: '0' (slashed) and '1'
  function [4:0] glyph_row(input one, input [2:0] r);
    if (one)
      case (r)
        3'd0: glyph_row = 5'b00100;
        3'd1: glyph_row = 5'b01100;
        3'd2: glyph_row = 5'b00100;
        3'd3: glyph_row = 5'b00100;
        3'd4: glyph_row = 5'b00100;
        3'd5: glyph_row = 5'b00100;
        3'd6: glyph_row = 5'b01110;
        default: glyph_row = 5'b00000;
      endcase
    else
      case (r)
        3'd0: glyph_row = 5'b01110;
        3'd1: glyph_row = 5'b10001;
        3'd2: glyph_row = 5'b10011;
        3'd3: glyph_row = 5'b10101;
        3'd4: glyph_row = 5'b11001;
        3'd5: glyph_row = 5'b10001;
        3'd6: glyph_row = 5'b01110;
        default: glyph_row = 5'b00000;
      endcase
  endfunction

  // ---------------------------------------------------------------
  // Pixel pipeline
  // ---------------------------------------------------------------
  reg [5:0] col;
  reg [5:0] yk, dk, wk;
  reg       one, dim, hit;
  reg [4:0] grow;
  reg [5:0] lc;
  integer k;

  always @* begin
    col = 6'b00_00_00;
    hit = 1'b0;
    dim = 1'b0;
    one = 1'b0;
    lc  = 6'b0;
    wk  = 6'd0; 
    grow = 5'd0;
    for (k = 0; k < 8; k = k + 1) begin
      yk = layer_y(k[2:0], cx);
      dk = cy - yk;
      if (dk == 6'd0 || dk == 6'd1) begin
        wk  = wave(k[2:0], cx);
        hit = 1'b1;
        dim = (dk == 6'd1);
        one = wk[1] ^ cx[0] ^ k[0] ^ dk[0];
        lc  = layer_col(k[2:0]);
      end
    end

    grow = glyph_row(one, gy);
    if (hit && gx >= 3'd1 && gx <= 3'd5 && grow[3'd5 - gx]) begin
      // '0' is a bit greener, '1' is the layer color
      col = one ? lc : {1'b0, lc[5], lc[3:2], (lc[1:0] == 2'b00) ? 2'b00 : (lc[1:0] - 2'b01)};
      if (dim) col = {1'b0, col[5], 1'b0, col[3], 1'b0, col[1]};
    end

    if (!display_on) col = 6'b00_00_00;
  end

  always @(posedge clk) RGB <= col;

endmodule
