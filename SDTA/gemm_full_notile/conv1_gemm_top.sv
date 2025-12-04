// conv1_gemm_top.sv
`timescale 1ns/1ps
import backbone_pkg::*;

// Full conv1: input 3x112x112, weight 64x3x7x7, output 64x56x56
module conv1_gemm_top #(
  parameter int DATA_W_P = DATA_W,
  parameter int ACC_W_P  = ACC_W
)(
  input  logic                         clk,
  input  logic                         rst_n,

  input  logic                         start,
  output logic                         done,

  // Input feature map: CIN x H_IN x W_IN (int16)
  input  logic signed [DATA_W_P-1:0]   fmap_i   [3][112][112],

  // Weights: COUT x CIN x KH x KW (int16)
  input  logic signed [DATA_W_P-1:0]   weight_i [64][3][7][7],

  // Output feature map: COUT x H_OUT x W_OUT (int32)
  output logic signed [ACC_W_P-1:0]    out_o    [64][56][56]
);

  // -------------------------
  // Conv params
  // -------------------------
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

  // GEMM: C[MxN] = A[MxK] * B[KxN]
  localparam int M_TOTAL = H_OUT * W_OUT;     // 56*56 = 3136
  localparam int N_TOTAL = COUT;              // 64
  localparam int K_TOTAL = CIN * KH * KW;     // 3*7*7 = 147

  // systolic / tiling（先用跟你之前一樣的 16x16, K_TILE=16）
  localparam int SA_ROWS = 16;
  localparam int SA_COLS = 16;
  localparam int K_MAX   = 2048;
  localparam int K_TILE  = 16;                // 147 => 16*9 + 3

  // ---------------------------------
  // GEMM matrices
  // ---------------------------------
  logic signed [DATA_W_P-1:0] A_full [M_TOTAL][K_TOTAL];
  logic signed [DATA_W_P-1:0] B_full [K_TOTAL][N_TOTAL];
  logic signed [ACC_W_P-1:0]  C_full [M_TOTAL][N_TOTAL];

  // ---------------------------------
  // im2col: fmap_i -> A_full (M_TOTAL x K_TOTAL)
  // 這裡寫法與 small conv1 相同，只是尺寸放大
  // ---------------------------------
  always_comb begin
    // default zero
    for (int m = 0; m < M_TOTAL; m++)
      for (int k = 0; k < K_TOTAL; k++)
        A_full[m][k] = '0;

    for (int m = 0; m < M_TOTAL; m++) begin
      int oh  = m / W_OUT;   // 0..55
      int ow  = m % W_OUT;   // 0..55
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
  // Python 端 weight.reshape(COUT, K_TOTAL)
  // 這裡做 transpose 成 K x COUT
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
  // 3D tiled GEMM controller
  // （你已經用小矩陣驗證過的那顆）
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
  ) u_conv1_gemm (
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
  // C_full -> out_o[COUT][H_OUT][W_OUT]
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
