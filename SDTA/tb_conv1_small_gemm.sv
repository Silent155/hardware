// tb_conv1_small_gemm.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module tb_conv1_small_gemm;

  // small conv1 config
  localparam int CIN   = 1;
  localparam int H_IN  = 8;
  localparam int W_IN  = 8;

  localparam int COUT  = 4;
  localparam int KH    = 3;
  localparam int KW    = 3;
  localparam int STRIDE = 1;
  localparam int PAD    = 1;

  localparam int H_OUT = 8;
  localparam int W_OUT = 8;

  logic clk   = 0;
  logic rst_n = 0;
  logic start;
  logic done;

  // fmap / weight / output
  logic signed [15:0] fmap   [CIN][H_IN][W_IN];
  logic signed [15:0] weight [COUT][CIN][KH][KW];

  int                 golden_out [COUT][H_OUT][W_OUT];
  logic signed [31:0] dut_out    [COUT][H_OUT][W_OUT];

  // DUT
  conv1_small_gemm_top dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .start   (start),
    .done    (done),
    .fmap_i  (fmap),
    .weight_i(weight),
    .out_o   (dut_out)
  );

  // clock
  always #5 clk = ~clk;

  // -----------------------------
  // load one case
  // -----------------------------
  task automatic load_case(input int id);
    string f_in, f_w, f_out;
    int fd_in, fd_w, fd_out;
    int i, j, k, c, val;

    $display("=== Load conv1 small case %0d ===", id);

    f_in  = $sformatf("conv1_small_cases/in_%0d.txt",  id);
    f_w   = $sformatf("conv1_small_cases/w_%0d.txt",   id);
    f_out = $sformatf("conv1_small_cases/out_%0d.txt", id);

    // fmap
    fd_in = $fopen(f_in, "r");
    if (!fd_in) begin
      $display("ERROR: cannot open %s", f_in);
      $finish;
    end

    for (c = 0; c < CIN; c++)
      for (i = 0; i < H_IN; i++)
        for (j = 0; j < W_IN; j++) begin
          if ($fscanf(fd_in, "%d\n", val) != 1) begin
            $display("ERROR: read fmap failed at c=%0d, i=%0d, j=%0d", c, i, j);
            $finish;
          end
          fmap[c][i][j] = val;
        end
    $fclose(fd_in);

    // weight
    fd_w = $fopen(f_w, "r");
    if (!fd_w) begin
      $display("ERROR: cannot open %s", f_w);
      $finish;
    end

    for (c = 0; c < COUT; c++)
      for (k = 0; k < CIN; k++)
        for (i = 0; i < KH; i++)
          for (j = 0; j < KW; j++) begin
            if ($fscanf(fd_w, "%d\n", val) != 1) begin
              $display("ERROR: read weight failed at co=%0d, ci=%0d, kh=%0d, kw=%0d",
                       c, k, i, j);
              $finish;
            end
            weight[c][k][i][j] = val;
          end
    $fclose(fd_w);

    // golden
    fd_out = $fopen(f_out, "r");
    if (!fd_out) begin
      $display("ERROR: cannot open %s", f_out);
      $finish;
    end

    for (c = 0; c < COUT; c++)
      for (i = 0; i < H_OUT; i++)
        for (j = 0; j < W_OUT; j++) begin
          if ($fscanf(fd_out, "%d\n", val) != 1) begin
            $display("ERROR: read golden_out failed at co=%0d, oh=%0d, ow=%0d",
                     c, i, j);
            $finish;
          end
          golden_out[c][i][j] = val;
        end
    $fclose(fd_out);
  endtask

  // -----------------------------
  // compare
  // -----------------------------
  task automatic compare_case(input int id);
    int errors = 0;

    for (int c = 0; c < COUT; c++)
      for (int i = 0; i < H_OUT; i++)
        for (int j = 0; j < W_OUT; j++) begin
          if (dut_out[c][i][j] !== golden_out[c][i][j]) begin
            $display("ERR case %0d: out[%0d][%0d][%0d] = %0d expect %0d",
                     id, c, i, j, dut_out[c][i][j], golden_out[c][i][j]);
            errors++;
          end
        end

    if (errors == 0)
      $display("=== Small conv1 case %0d PASS ===", id);
    else
      $display("=== Small conv1 case %0d FAIL | errors = %0d ===", id, errors);
  endtask

  // -----------------------------
  // main
  // -----------------------------
  initial begin
    $display("==== SMALL CONV1 8x8 TEST START ====");

    start = 0;
    #20 rst_n = 1;

    for (int id = 0; id < 5; id++) begin
      load_case(id);

      @(posedge clk);
      start = 1;
      @(posedge clk);
      start = 0;

      wait (done == 1);
      @(posedge clk);

      compare_case(id);
    end

    $display("==== ALL SMALL CONV1 CASES DONE ====");
    $finish;
  end

endmodule
