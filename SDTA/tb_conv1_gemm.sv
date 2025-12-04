// tb_conv1_gemm.sv
// ---------------------------------------------------------
// Testbench for conv1:
//   Input  : 3x112x112  int16
//   Weight : 64x3x7x7   int16
//   Output : 64x56x56   int32
//
// Reads:
//   conv1_cases/in_x.txt
//   conv1_cases/w_x.txt
//   conv1_cases/out_x.txt
//
// Calls:
//   conv1_gemm_top (your RTL module)
// ---------------------------------------------------------

`timescale 1ns/1ps
import backbone_pkg::*;

// -------------------------
// conv1 config
// -------------------------
localparam int CIN   = 3;
localparam int H_IN  = 112;
localparam int W_IN  = 112;

localparam int COUT  = 64;
localparam int KH    = 7;
localparam int KW    = 7;
localparam int STRIDE= 2;
localparam int PAD   = 3;

localparam int H_OUT = 56;
localparam int W_OUT = 56;

// -------------------------------------
// Testbench module
// -------------------------------------
module tb_conv1_gemm;

  logic clk = 0, rst_n = 0;
  logic start, done;

  // -----------------------------------------------------
  // Buffers for input fmap, weight, output
  // All int16 for fmap / weight
  // int32 for golden + DUT output
  // -----------------------------------------------------
  logic signed [15:0] fmap   [CIN][H_IN][W_IN];
  logic signed [15:0] weight [COUT][CIN][KH][KW];

  int golden_out [COUT][H_OUT][W_OUT];
  logic signed [31:0] dut_out [COUT][H_OUT][W_OUT];

  // -------------------------------------
  // Instantiate your conv1-gemm module
  // -------------------------------------
  conv1_gemm_top dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .start   (start),
    .done    (done),
    .fmap_i  (fmap),
    .weight_i(weight),
    .out_o   (dut_out)
  );

  always #5 clk = ~clk;


  // -------------------------------------
  // Load one test case
  // -------------------------------------
  task automatic load_case(input int id);
    string f_in, f_w, f_out;

    int fd_in, fd_w, fd_out;
    int i,j,k,c, val;

    $display("=== Load Case %0d ===", id);

    f_in  = $sformatf("in_%0d.txt", id);
    f_w   = $sformatf("w_%0d.txt", id);
    f_out = $sformatf("out_%0d.txt", id);

    // fmap
    fd_in = $fopen(f_in, "r");
    if (!fd_in) begin
      $display("ERROR: cannot open %s", f_in);
      $finish;
    end
    for (c=0; c<CIN; c++)
      for (i=0; i<H_IN; i++)
        for (j=0; j<W_IN; j++) begin
          $fscanf(fd_in, "%d\n", val);
          fmap[c][i][j] = val;
        end
    $fclose(fd_in);

    // weight
    fd_w = $fopen(f_w, "r");
    if (!fd_w) begin
      $display("ERROR: cannot open %s", f_w);
      $finish;
    end
    for (c=0; c<COUT; c++)
      for (k=0; k<CIN; k++)
        for (i=0; i<KH; i++)
          for (j=0; j<KW; j++) begin
            $fscanf(fd_w, "%d\n", val);
            weight[c][k][i][j] = val;
          end
    $fclose(fd_w);

    // golden out
    fd_out = $fopen(f_out, "r");
    if (!fd_out) begin
      $display("ERROR: cannot open %s", f_out);
      $finish;
    end
    for (c=0; c<COUT; c++)
      for (i=0; i<H_OUT; i++)
        for (j=0; j<W_OUT; j++) begin
          $fscanf(fd_out, "%d\n", val);
          golden_out[c][i][j] = val;
        end
    $fclose(fd_out);

  endtask


  // -------------------------------------
  // Compare DUT output with golden
  // -------------------------------------
  task automatic compare_case(input int id);
    int errors = 0;

    for (int c=0; c<COUT; c++)
      for (int i=0; i<H_OUT; i++)
        for (int j=0; j<W_OUT; j++)
          if (dut_out[c][i][j] !== golden_out[c][i][j]) begin
            $display("ERR Case %0d: out[%0d][%0d][%0d] = %0d expect %0d",
              id, c, i, j, dut_out[c][i][j], golden_out[c][i][j]);
            errors++;
          end

    if (errors == 0)
      $display("=== Case %0d PASS ===", id);
    else
      $display("=== Case %0d FAIL | errors = %0d ===", id, errors);
  endtask


  // -------------------------------------
  // Simulation main
  // -------------------------------------
  initial begin
    $display("==== Conv1 GEMM test start ====");

    #20 rst_n = 1;

    for (int id=0; id<5; id++) begin
      load_case(id);

      start = 1;
      @(posedge clk);
      start = 0;

      wait(done);
      @(posedge clk);

      compare_case(id);
    end

    $display("==== ALL DONE ====");
    $finish;
  end

endmodule
