// conv1_small_gemm_top.sv (fixed)
`timescale 1ns/1ps
import backbone_pkg::*;

module conv1_small_gemm_top #(
  parameter int DATA_W_P = DATA_W,
  parameter int ACC_W_P  = ACC_W
)(
  input  logic                         clk,
  input  logic                         rst_n,

  input  logic                         start,
  output logic                         done,

  // Input feature: CIN x H_IN x W_IN
  input  logic signed [DATA_W_P-1:0]   fmap_i   [1][8][8],

  // Weight: COUT x CIN x KH x KW
  input  logic signed [DATA_W_P-1:0]   weight_i [4][1][3][3],

  // Output: COUT x H_OUT x W_OUT
  output logic signed [ACC_W_P-1:0]    out_o    [4][8][8]
);

  // -------------------------
  // Conv params
  // -------------------------
  localparam int CIN    = 1;
  localparam int H_IN   = 8;
  localparam int W_IN   = 8;

  localparam int COUT   = 4;
  localparam int KH     = 3;
  localparam int KW     = 3;
  localparam int STRIDE = 1;
  localparam int PAD    = 1;

  localparam int H_OUT  = 8;
  localparam int W_OUT  = 8;

  // GEMM: C[MxN] = A[MxK] * B[KxN]
  localparam int M_TOTAL = H_OUT * W_OUT;     // 64
  localparam int N_TOTAL = COUT;              // 4
  localparam int K_TOTAL = CIN * KH * KW;     // 9

  // systolic / tiling
  localparam int SA_ROWS = 4;
  localparam int SA_COLS = 4;
  localparam int K_MAX   = 16;
  localparam int K_TILE  = 4;                 // 9 -> 4+4+1

  // ---------------------------------
  // GEMM matrices
  // ---------------------------------
  logic signed [DATA_W_P-1:0] A_full [M_TOTAL][K_TOTAL];
  logic signed [DATA_W_P-1:0] B_full [K_TOTAL][N_TOTAL];
  logic signed [ACC_W_P-1:0]  C_full [M_TOTAL][N_TOTAL];

  // ---------------------------------
  // im2col: fmap_i -> A_full  (fixed)
  // ---------------------------------
  always_comb begin
    // default zero
    for (int m = 0; m < M_TOTAL; m++)
      for (int k = 0; k < K_TOTAL; k++)
        A_full[m][k] = '0;

    // 一行一行對應 M = oh*W_OUT + ow
    for (int m = 0; m < M_TOTAL; m++) begin
      int oh  = m / W_OUT;   // 0..7
      int ow  = m % W_OUT;   // 0..7
      int idx = 0;

      for (int c = 0; c < CIN; c++) begin
        for (int kh = 0; kh < KH; kh++) begin
          for (int kw = 0; kw < KW; kw++) begin
            int ih = oh * STRIDE + kh - PAD;
            int iw = ow * STRIDE + kw - PAD;

            logic signed [DATA_W_P-1:0] val;
            if (ih < 0 || ih >= H_IN || iw < 0 || iw >= W_IN)
              val = '0;
            else
              val = fmap_i[c][ih][iw];

            if (idx < K_TOTAL)
              A_full[m][idx] = val;
            idx++;
          end
        end
      end
    end
  end

  // ---------------------------------
  // weight -> B_full (K_TOTAL x N_TOTAL)
  // ---------------------------------
  always_comb begin
    for (int k = 0; k < K_TOTAL; k++)
      for (int n = 0; n < N_TOTAL; n++)
        B_full[k][n] = '0;

    for (int n = 0; n < COUT; n++) begin
      int idx_w = 0;
      for (int c = 0; c < CIN; c++) begin
        for (int kh = 0; kh < KH; kh++) begin
          for (int kw = 0; kw < KW; kw++) begin
            if (idx_w < K_TOTAL)
              B_full[idx_w][n] = weight_i[n][c][kh][kw];
            idx_w++;
          end
        end
      end
    end
  end

  // ---------------------------------
  // 3D tiled GEMM
  // ---------------------------------
  gemm_tiled_controller_3d #(
    .ROWS     (SA_ROWS),
    .COLS     (SA_COLS),
    .M_TOTAL  (M_TOTAL),
    .N_TOTAL  (N_TOTAL),
    .K_TOTAL  (K_TOTAL),
    .K_MAX    (K_MAX),
    .K_TILE   (K_TILE),
    .DATA_W_P (DATA_W_P),
    .ACC_W_P  (ACC_W_P)
  ) u_conv1_small (
    .clk    (clk),
    .rst_n  (rst_n),
    .start  (start),
    .busy   (/* open */),
    .done   (done),
    .A_full (A_full),
    .B_full (B_full),
    .C_full (C_full)
  );

  // ---------------------------------
  // C_full -> out_o
  // ---------------------------------
  always_comb begin
    for (int co = 0; co < COUT; co++)
      for (int oh = 0; oh < H_OUT; oh++)
        for (int ow = 0; ow < W_OUT; ow++) begin
          int m_idx2 = oh * W_OUT + ow;
          out_o[co][oh][ow] = C_full[m_idx2][co];
        end
  end

endmodule
