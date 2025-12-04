// conv1_gemm_top.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module conv1_gemm_top #(
  parameter int DATA_W_P = DATA_W,
  parameter int ACC_W_P  = ACC_W
)(
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         start,
  output logic                         done,

  input  logic signed [DATA_W_P-1:0]   fmap_i   [3][112][112],
  input  logic signed [DATA_W_P-1:0]   weight_i [64][3][7][7],
  output logic signed [ACC_W_P-1:0]    out_o    [64][56][56]
);

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

  localparam int M_TOTAL = H_OUT * W_OUT; // 3136
  localparam int N_TOTAL = COUT;          // 64
  localparam int K_TOTAL = CIN * KH * KW; // 147

  localparam int SA_ROWS = 16;
  localparam int SA_COLS = 16;
  localparam int K_MAX   = 2048;
  localparam int K_TILE  = 16;

  logic signed [DATA_W_P-1:0] B_full [K_TOTAL][N_TOTAL];
  logic signed [ACC_W_P-1:0]  C_full [M_TOTAL][N_TOTAL];

  // reshape weights -> B_full
  int idx;
  always_comb begin
    for (int k = 0; k < K_TOTAL; k++)
      for (int n = 0; n < N_TOTAL; n++)
        B_full[k][n] = '0;

    for (int n = 0; n < COUT; n++) begin
      idx = 0;
      for (int c = 0; c < CIN; c++) begin
        for (int kh = 0; kh < KH; kh++) begin
          for (int kw = 0; kw < KW; kw++) begin
            if (idx < K_TOTAL)
              B_full[idx][n] = weight_i[n][c][kh][kw];
            idx++;
          end
        end
      end
    end
  end

  conv1_gemm_ctrl_3d_streamA #(
    .ROWS     (SA_ROWS),
    .COLS     (SA_COLS),
    .M_TOTAL  (M_TOTAL),
    .N_TOTAL  (N_TOTAL),
    .K_TOTAL  (K_TOTAL),
    .K_MAX    (K_MAX),
    .K_TILE   (K_TILE),
    .DATA_W_P (DATA_W_P),
    .ACC_W_P  (ACC_W_P)
  ) u_conv1 (
    .clk    (clk),
    .rst_n  (rst_n),
    .start  (start),
    .busy   (/* open */),
    .done   (done),
    .fmap_i (fmap_i),
    .B_full (B_full),
    .C_full (C_full)
  );

  // C_full -> out_o
  always_comb begin
    for (int co = 0; co < COUT; co++)
      for (int oh = 0; oh < H_OUT; oh++)
        for (int ow = 0; ow < W_OUT; ow++) begin
          int m_idx = oh * W_OUT + ow;
          out_o[co][oh][ow] = C_full[m_idx][co];
        end
  end

endmodule : conv1_gemm_top
