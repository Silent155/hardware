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

  localparam int M_TOTAL = H_OUT * W_OUT;
  localparam int N_TOTAL = COUT;
  localparam int K_TOTAL = CIN * KH * KW;

  localparam int SA_ROWS = 16;
  localparam int SA_COLS = 16;
  localparam int K_MAX   = 2048;
  localparam int K_TILE  = 16;

  // B_full [K_TOTAL][N_TOTAL]
  logic signed [DATA_W_P-1:0] B_full [K_TOTAL][N_TOTAL];

  // reshape weights -> B_full
  int idx;
  always_comb begin
    for (int k = 0; k < K_TOTAL; k++)
      for (int n = 0; n < N_TOTAL; n++)
        B_full[k][n] = '0;

    for (int n = 0; n < COUT; n++) begin
      idx = 0;
      for (int c = 0; c < CIN; c++)
        for (int kh = 0; kh < KH; kh++)
          for (int kw = 0; kw < KW; kw++) begin
            if (idx < K_TOTAL)
              B_full[idx][n] = weight_i[n][c][kh][kw];
            idx++;
          end
    end
  end

  // C_full from controller
  logic signed [ACC_W_P-1:0] C_full [M_TOTAL][N_TOTAL];

  // BRAM write side
  logic                       c_wr_en;
  int                         c_wr_addr;
  logic signed [ACC_W_P-1:0]  c_wr_data;

  // BRAM read side（目前不用，可先綁 0）
  logic                       c_rd_en;
  int                         c_rd_addr;
  logic signed [ACC_W_P-1:0]  c_rd_data;
  logic                       c_rd_valid;

  // controller done/busy
  logic ctrl_busy, ctrl_done;

  // BRAM instance：用來存 conv1 output（之後你可以拿去接 DMA）
  conv1_C_accum_bram #(
    .M_TOTAL (M_TOTAL),
    .N_TOTAL (N_TOTAL),
    .ACC_W_P (ACC_W_P)
  ) u_C_bram (
    .clk       (clk),
    .rst_n     (rst_n),
    .clear_all (1'b0),        // 現在暫時不從這裡 clear，下一版要真的用再加
    .rd_en     (c_rd_en),
    .rd_addr   (c_rd_addr),
    .rd_data   (c_rd_data),
    .rd_valid  (c_rd_valid),
    .wr_en     (c_wr_en),
    .wr_addr   (c_wr_addr),
    .wr_data   (c_wr_data)
  );

  // 目前不從 BRAM 讀，所以綁成 0，避免多 driver
  assign c_rd_en   = 1'b0;
  assign c_rd_addr = '0;

  // GEMM controller
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
  ) u_ctrl (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (start),
    .busy      (ctrl_busy),
    .done      (ctrl_done),
    .fmap_i    (fmap_i),
    .B_full    (B_full),
    .C_full    (C_full),
    .c_wr_en   (c_wr_en),
    .c_wr_addr (c_wr_addr),
    .c_wr_data (c_wr_data)
  );

  // top-level done = ctrl_done（不再加 dump FSM）
  assign done = ctrl_done;
int m_idx;
  // C_full -> out_o（跟你原本一模一樣）
  always_comb begin
    for (int co = 0; co < COUT; co++)
      for (int oh = 0; oh < H_OUT; oh++)
        for (int ow = 0; ow < W_OUT; ow++) begin
          m_idx = oh * W_OUT + ow;
          out_o[co][oh][ow] = C_full[m_idx][co];
        end
  end

endmodule : conv1_gemm_top
