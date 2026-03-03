/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 *
 * Dice Roller — TinyTapeout
 *
 * A free-running counter cycles 1–6 continuously at clock speed.
 * When the roll button is pressed and released, the counter value
 * is latched as the dice result. A debounce circuit filters noise.
 *
 * Inputs:
 *   ui_in[0] - Roll button (press and release to roll)
 *
 * Outputs:
 *   uo_out[2:0] - Dice result in binary (1–6)
 *   uo_out[7]   - High while button is currently held
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Unused IOs set to 0
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  // Suppress unused input warnings
  wire _unused = &{ena, uio_in, ui_in[7:1], 1'b0};

  // -------------------------------------------------------
  // Free-running counter: cycles 1 through 6
  // Runs continuously so the latched value is unpredictable
  // -------------------------------------------------------
  reg [2:0] free_counter;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      free_counter <= 3'd1;
    end else begin
      if (free_counter == 3'd6)
        free_counter <= 3'd1;
      else
        free_counter <= free_counter + 3'd1;
    end
  end

  // -------------------------------------------------------
  // Button debounce logic
  // -------------------------------------------------------
  reg [1:0] sync_ff;        // 2-stage synchronizer for CDC
  reg [15:0] debounce_cnt;  // debounce timer (~0.65ms at 100MHz)
  reg btn_stable;           // debounced button state
  reg btn_prev;             // previous debounced state

  wire btn_released = (!btn_stable && btn_prev);  // falling edge = latch result

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff      <= 2'b0;
      debounce_cnt <= 16'd0;
      btn_stable   <= 1'b0;
      btn_prev     <= 1'b0;
    end else begin
      // Two-stage synchronizer
      sync_ff <= {sync_ff[0], ui_in[0]};

      // Track previous stable state
      btn_prev <= btn_stable;

      // Debounce: only switch btn_stable after input holds steady
      if (sync_ff[1] == btn_stable) begin
        debounce_cnt <= 16'd0;
      end else begin
        debounce_cnt <= debounce_cnt + 16'd1;
        if (debounce_cnt == 16'hFFFF) begin
          btn_stable   <= sync_ff[1];
          debounce_cnt <= 16'd0;
        end
      end
    end
  end

  // -------------------------------------------------------
  // Dice result register — latch on button release
  // -------------------------------------------------------
  reg [2:0] dice_result;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dice_result <= 3'd1;
    end else if (btn_released) begin
      dice_result <= free_counter;
    end
  end

  // -------------------------------------------------------
  // Output assignments
  // uo_out[2:0] = dice result (1–6 in binary)
  // uo_out[6:3] = unused, tied low
  // uo_out[7]   = button held status
  // -------------------------------------------------------
  assign uo_out[2:0] = dice_result;
  assign uo_out[6:3] = 4'b0000;
  assign uo_out[7]   = btn_stable;

endmodule