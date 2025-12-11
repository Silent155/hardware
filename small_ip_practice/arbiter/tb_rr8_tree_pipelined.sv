// =============================================================
// Testbench for rr8_tree_pipelined
// =============================================================
`timescale 1ns/1ps

module tb_rr8_tree_pipelined;

  logic        clk;
  logic        rst_n;
  logic [7:0]  req;
  logic [7:0]  gnt;

  // DUT
  rr8_tree_pipelined dut (
    .clk (clk),
    .rst_n (rst_n),
    .req (req),
    .gnt (gnt)
  );

  // clock
  always #5 clk = ~clk;

  // reset
  initial begin
    clk   = 0;
    rst_n = 0;
    req   = 0;
    #30;
    rst_n = 1;
  end

  // stimulus generator
  initial begin
    @(posedge rst_n);

    // --- Test 1: all request high ---
    $display("=== TEST 1: ALL REQUEST HIGH ===");
    req = 8'b1111_1111;
    repeat (10) @(posedge clk);

    // --- Test 2: single-bit walking ---
    $display("=== TEST 2: WALKING 1 ===");
    for (int i = 0; i < 8; i++) begin
      req = 1 << i;
      @(posedge clk);
    end

    // --- Test 3: random traffic ---
    $display("=== TEST 3: RANDOM ===");
    repeat (20) begin
      req = $urandom_range(0, 255);  // random 8-bit
      @(posedge clk);
    end

    // --- Test 4: alternating pattern ---
    $display("=== TEST 4: ALTERNATING ===");
    req = 8'b1010_1010;
    repeat (8) @(posedge clk);

    req = 8'b0101_0101;
    repeat (8) @(posedge clk);

    $display("=== TEST DONE ===");
    $finish;
  end

  // Simple checker: ensure gnt is one-hot or zero
  always @(posedge clk) begin
    if (rst_n) begin
      if (gnt !== 8'b0 && (gnt & (gnt - 1)) !== 0) begin
        $display("[%0t] ERROR: gnt not one-hot! gnt = %b", $time, gnt);
      end
      $display("[%0t] req=%b  gnt=%b", $time, req, gnt);
    end
  end

endmodule
