// tb_conv1_gemm_top.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module tb_conv1_gemm_top;

  // conv1 params
  localparam int CIN    = 3;
  localparam int H_IN   = 112;
  localparam int W_IN   = 112;

  localparam int COUT   = 64;
  localparam int KH     = 7;
  localparam int KW     = 7;
  localparam int STRIDE = 2;
  localparam int PAD    = 3;

  localparam int H_OUT  = 56;
  localparam int W_OUT  = 56;

  localparam int NUM_CASES = 5;  // Â∞çÊ?? Python CASES

  logic clk   = 0;
  logic rst_n = 0;
  logic start;
  logic done;

  // DUT ports
  logic signed [DATA_W-1:0] fmap_i   [CIN][H_IN][W_IN];
  logic signed [DATA_W-1:0] weight_i [COUT][CIN][KH][KW];
  logic signed [ACC_W-1:0]  out_o    [COUT][H_OUT][W_OUT];

  // golden
  int golden_out [COUT][H_OUT][W_OUT];

  // clock
  always #0.001 clk = ~clk;

  // DUT
  conv1_gemm_top #(
    .DATA_W_P (DATA_W),
    .ACC_W_P  (ACC_W)
  ) dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .start   (start),
    .done    (done),
    .fmap_i  (fmap_i),
    .weight_i(weight_i),
    .out_o   (out_o)
  );

  // -----------------------------
  // Load one case
  // -----------------------------
  task automatic load_case(int cid);
    int fd_in, fd_w, fd_out;
    int val;
    string f_in, f_w, f_out;

    f_in  = $sformatf("conv1_cases/in_%0d.txt",  cid);
    f_w   = $sformatf("conv1_cases/w_%0d.txt",   cid);
    f_out = $sformatf("conv1_cases/out_%0d.txt", cid);

    $display("=== Load conv1 case %0d ===", cid);

    // input fmap: [CIN][H_IN][W_IN]
    fd_in = $fopen(f_in, "r");
    if (!fd_in) begin
      $display("ERROR: cannot open %s", f_in);
      $finish;
    end
    for (int c = 0; c < CIN; c++)
      for (int h = 0; h < H_IN; h++)
        for (int w = 0; w < W_IN; w++) begin
          if ($fscanf(fd_in, "%d\n", val) != 1) begin
            $display("ERROR: read in fmap failed c=%0d h=%0d w=%0d", c,h,w);
            $finish;
          end
          fmap_i[c][h][w] = val;
        end
    $fclose(fd_in);

    // weights: [COUT][CIN][KH][KW]
    fd_w = $fopen(f_w, "r");
    if (!fd_w) begin
      $display("ERROR: cannot open %s", f_w);
      $finish;
    end
    for (int co = 0; co < COUT; co++)
      for (int c = 0; c < CIN; c++)
        for (int kh = 0; kh < KH; kh++)
          for (int kw = 0; kw < KW; kw++) begin
            if ($fscanf(fd_w, "%d\n", val) != 1) begin
              $display("ERROR: read weight failed co=%0d c=%0d kh=%0d kw=%0d",
                       co,c,kh,kw);
              $finish;
            end
            weight_i[co][c][kh][kw] = val;
          end
    $fclose(fd_w);

    // golden out: [COUT][H_OUT][W_OUT]
    fd_out = $fopen(f_out, "r");
    if (!fd_out) begin
      $display("ERROR: cannot open %s", f_out);
      $finish;
    end
    for (int co = 0; co < COUT; co++)
      for (int h = 0; h < H_OUT; h++)
        for (int w = 0; w < W_OUT; w++) begin
          if ($fscanf(fd_out, "%d\n", val) != 1) begin
            $display("ERROR: read golden out failed co=%0d h=%0d w=%0d",
                     co,h,w);
            $finish;
          end
          golden_out[co][h][w] = val;
        end
    $fclose(fd_out);
  endtask

  // -----------------------------
  // Compare one case
  // -----------------------------
  task automatic compare_case(int cid);
    int errors = 0;
    for (int co = 0; co < COUT; co++)
      for (int h = 0; h < H_OUT; h++)
        for (int w = 0; w < W_OUT; w++) begin
          if (out_o[co][h][w] !== golden_out[co][h][w]) begin
            $display("ERR case %0d: out[%0d][%0d][%0d] = %0d expect %0d",
                     cid, co, h, w,
                     out_o[co][h][w], golden_out[co][h][w]);
            errors++;
          end
        end

    if (errors == 0)
      $display("=== conv1 case %0d PASS ===", cid);
    else
      $display("=== conv1 case %0d FAIL | errors = %0d ===", cid, errors);
  endtask

  // -----------------------------
  // Main
  // -----------------------------
  initial begin
    $display("==== FULL conv1 GEMM TEST START ====");

    start = 0;
    rst_n = 0;
    #50;
    rst_n = 1;

    for (int cid = 0; cid < NUM_CASES; cid++) begin
      load_case(cid);

      @(posedge clk);
      start = 1;
      @(posedge clk);
      start = 0;

      // gemm_tiled_controller_3d ??? done ?òØ stickyÔº?
      // ?ú® S_IDLE ‰∏îÁ?ãÂà∞ start ??ÉÊ?? 0ÔºåÊ?‰ª•È?ôË£°?õ¥?é• wait Â∞±Â•Ω
      wait (done == 1);
      @(posedge clk);

      compare_case(cid);
    end

    $display("==== ALL FULL conv1 CASES DONE ====");
    $finish;
  end

endmodule
