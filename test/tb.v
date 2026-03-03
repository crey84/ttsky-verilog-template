/*
 * Testbench for tt_um_example (Dice Roller)
 *
 * Self-checking testbench — prints PASS/FAIL for each test.
 * Tests:
 *   1. Reset sets output to 1
 *   2. Output in range after reset
 *   3. First roll produces value 1–6
 *   4. Result holds stable between rolls
 *   5. Five sequential rolls all produce values 1–6
 *   6. Result does not change while button is held (only on release)
 *   7. Mid-operation reset returns output to 1
 */

`timescale 1ns/1ps
`default_nettype none

module tb;

  // -------------------------------------------------------
  // DUT signals
  // -------------------------------------------------------
  reg        clk;
  reg        rst_n;
  reg  [7:0] ui_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // -------------------------------------------------------
  // Instantiate DUT
  // -------------------------------------------------------
  tt_um_example dut (
    .ui_in   (ui_in),
    .uo_out  (uo_out),
    .uio_in  (8'b0),
    .uio_out (uio_out),
    .uio_oe  (uio_oe),
    .ena     (1'b1),
    .clk     (clk),
    .rst_n   (rst_n)
  );

  // -------------------------------------------------------
  // Clock: 100MHz → 10ns period
  // -------------------------------------------------------
  initial clk = 0;
  always #5 clk = ~clk;

  // Convenience wire for dice output
  wire [2:0] dice_val = uo_out[2:0];

  // -------------------------------------------------------
  // Task: press and release button
  // Hold long enough to pass debounce counter (0xFFFF cycles)
  // -------------------------------------------------------
  task press_and_release;
    begin
      ui_in[0] = 1'b1;
      repeat(66000) @(posedge clk);  // hold through debounce
      ui_in[0] = 1'b0;
      repeat(66000) @(posedge clk);  // release through debounce
    end
  endtask

  // -------------------------------------------------------
  // Task: assert dice value is in range 1–6
  // -------------------------------------------------------
  task check_range;
    input [2:0] val;
    input integer test_num;
    begin
      if (val >= 1 && val <= 6) begin
        $display("PASS Test %0d: dice_val = %0d (valid range 1-6)", test_num, val);
      end else begin
        $display("FAIL Test %0d: dice_val = %0d (OUT OF RANGE!)", test_num, val);
        $finish;
      end
    end
  endtask

  // -------------------------------------------------------
  // Main test sequence
  // -------------------------------------------------------
  integer i;
  reg [2:0] prev_val;

  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);

    // Initialize
    ui_in = 8'b0;
    rst_n = 1'b0;
    repeat(10) @(posedge clk);

    // Release reset
    rst_n = 1'b1;
    @(posedge clk);

    // --------------------------------------------------
    // TEST 1: Reset sets dice output to 1
    // --------------------------------------------------
    if (dice_val == 3'd1)
      $display("PASS Test 1: Reset sets dice_val to 1");
    else begin
      $display("FAIL Test 1: Expected 1 after reset, got %0d", dice_val);
      $finish;
    end

    // --------------------------------------------------
    // TEST 2: Output is in valid range after reset
    // --------------------------------------------------
    repeat(20) @(posedge clk);
    check_range(dice_val, 2);

    // --------------------------------------------------
    // TEST 3: First roll gives a value in 1–6
    // --------------------------------------------------
    press_and_release;
    check_range(dice_val, 3);
    prev_val = dice_val;
    $display("       Roll 1 result: %0d", dice_val);

    // --------------------------------------------------
    // TEST 4: Result holds stable between rolls
    // --------------------------------------------------
    repeat(100) @(posedge clk);
    if (dice_val == prev_val)
      $display("PASS Test 4: Result holds stable between rolls (%0d)", dice_val);
    else begin
      $display("FAIL Test 4: Result changed without button press! Was %0d, now %0d", prev_val, dice_val);
      $finish;
    end

    // --------------------------------------------------
    // TEST 5: Five sequential rolls all produce 1–6
    // --------------------------------------------------
    for (i = 0; i < 5; i = i + 1) begin
      repeat(i * 13 + 5) @(posedge clk);  // vary timing for different counter positions
      press_and_release;
      check_range(dice_val, 5);
      $display("       Roll %0d result: %0d", i+2, dice_val);
    end

    // --------------------------------------------------
    // TEST 6: Result does NOT change while button is held
    // Should only update on release
    // --------------------------------------------------
    prev_val = dice_val;
    ui_in[0] = 1'b1;
    repeat(66000) @(posedge clk);  // button held through debounce
    if (dice_val == prev_val)
      $display("PASS Test 6: Result unchanged while button held (%0d)", dice_val);
    else begin
      $display("FAIL Test 6: Result changed while held! Was %0d, now %0d", prev_val, dice_val);
      $finish;
    end
    ui_in[0] = 1'b0;
    repeat(66000) @(posedge clk);
    check_range(dice_val, 6);
    $display("       After release: %0d", dice_val);

    // --------------------------------------------------
    // TEST 7: Mid-operation reset returns to 1
    // --------------------------------------------------
    rst_n = 1'b0;
    repeat(5) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    if (dice_val == 3'd1)
      $display("PASS Test 7: Mid-operation reset returns dice_val to 1");
    else begin
      $display("FAIL Test 7: Expected 1 after reset, got %0d", dice_val);
      $finish;
    end

    // --------------------------------------------------
    // ALL DONE
    // --------------------------------------------------
    $display("");
    $display("========================================");
    $display("  ALL TESTS PASSED — Dice Roller OK!");
    $display("========================================");
    $finish;
  end

  // Timeout watchdog
  initial begin
    #100_000_000;
    $display("FAIL: Simulation timeout!");
    $finish;
  end

endmodule