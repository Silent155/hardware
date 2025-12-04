// tb_conv1_bn1.sv
`timescale 1ns/1ps
`include "backbone_pkg.sv"
`include "conv1_7x7_parallel.sv"
`include "bn_affine_2d.sv"

module tb_conv1_bn1;
  import backbone_pkg::*;

  // clock & reset
  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n = 0;

  // memories
  data_t fmap_in      [0:3*112*112-1];
  data_t conv1_weight [0:64*3*7*7-1];
  data_t fmap_conv1   [0:64*56*56-1];

  data_t bn1_scale [0:64-1];
  data_t bn1_shift [0:64-1];
  data_t fmap_bn1  [0:64*56*56-1];

  // done flags
  logic conv1_done, bn1_done;

  // ------------------------------------------------------------------
  // DUT: conv1
  // ------------------------------------------------------------------
  conv1_7x7_parallel #(
    .IN_C(3),
    .IN_H(112),
    .IN_W(112),
    .OUT_C(64),
    .K(7),
    .STRIDE(2),
    .PAD(3)
  ) u_conv1 (
    .clk     (clk),
    .rst_n   (rst_n),
    .start   (1'b1),        // ä¸???‹å?‹å°±è·?
    .done    (conv1_done),
    .fmap_in (fmap_in),
    .weight  (conv1_weight),
    .fmap_out(fmap_conv1)
  );

  // ------------------------------------------------------------------
  // DUT: bn1
  // ------------------------------------------------------------------
  bn_affine_2d #(
    .C(64),
    .H(56),
    .W(56),
    .USE_RELU(1'b1)
  ) u_bn1 (
    .clk     (clk),
    .rst_n   (rst_n),
    .start   (conv1_done),
    .done    (bn1_done),
    .fmap_in (fmap_conv1),
    .scale   (bn1_scale),
    .shift   (bn1_shift),
    .fmap_out(fmap_bn1)
  );
   integer f;
  // ------------------------------------------------------------------
  // Initial: load mem & run
  // ------------------------------------------------------------------
  initial begin
    $display("Loading mem files...");

    $readmemh("input_image_int16.mem", fmap_in);
    $readmemh("conv1_weight.mem",      conv1_weight);
    $readmemh("bn1_scale.mem",         bn1_scale);
    $readmemh("bn1_shift.mem",         bn1_shift);

    #20;
    rst_n = 1;

    // ç­‰åˆ° bn1 ??šå??
    wait(bn1_done);
    $display("BN1 done, dumping fmap_bn1...");

   
    f = $fopen("bn1_out_int16_rtl.mem", "w");
    for (int i = 0; i < 64*56*56; i++) begin
      $fwrite(f, "%04x\n", fmap_bn1[i]);
    end
    $fclose(f);

    $display("Saved bn1_out_int16_rtl.mem");
    $finish;
  end

endmodule
