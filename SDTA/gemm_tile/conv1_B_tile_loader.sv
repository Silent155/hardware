// conv1_B_tile_loader.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module conv1_B_tile_loader #(
  parameter int COLS     = 16,
  parameter int K_MAX    = 2048,
  parameter int K_TOTAL  = 3*7*7,   // 147
  parameter int N_TOTAL  = 64,
  parameter int DATA_W_P = DATA_W
)(
  input  logic                         clk,
  input  logic                         rst_n,

  input  logic                         start,
  output logic                         busy,
  output logic                         done,

  // tile base index
  input  int                           tile_k_base,
  input  int                           tile_n_base,

  // full weights: [K_TOTAL][N_TOTAL]
  input  logic signed [DATA_W_P-1:0]   B_full [K_TOTAL][N_TOTAL],

  // local tile buffer: [K_MAX][COLS]
  output logic signed [DATA_W_P-1:0]   B_buf  [K_MAX][COLS]
);

  typedef enum logic [1:0] { BL_IDLE, BL_RUN, BL_DONE } bl_state_t;
  bl_state_t bl_state, bl_state_n;

  int k_eff, n_eff;
  int total_B;
  int cnt, cnt_n;

  // compute effective k_eff / n_eff
  always_comb begin
    if (tile_k_base + 16 <= K_TOTAL)
      k_eff = 16;
    else
      k_eff = K_TOTAL - tile_k_base;
    if (tile_n_base + COLS <= N_TOTAL)
      n_eff = COLS;
    else
      n_eff = N_TOTAL - tile_n_base;
    if (k_eff < 0) k_eff = 0;
    if (n_eff < 0) n_eff = 0;

    total_B = k_eff * n_eff;
  end

  // FSM
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bl_state <= BL_IDLE;
      cnt      <= 0;
    end else begin
      bl_state <= bl_state_n;
      cnt      <= cnt_n;
    end
  end

  always_comb begin
    bl_state_n = bl_state;
    cnt_n      = cnt;
    busy       = 1'b0;
    done       = 1'b0;

    case (bl_state)
      BL_IDLE: begin
        if (start) begin
          cnt_n      = 0;
          bl_state_n = BL_RUN;
        end
      end

      BL_RUN: begin
        busy = 1'b1;
        if (cnt < total_B) begin
          int kk  = cnt / n_eff;
          int col = cnt % n_eff;

          B_buf[kk][col] <= B_full[tile_k_base + kk][tile_n_base + col];

          cnt_n = cnt + 1;
        end else begin
          bl_state_n = BL_DONE;
        end
      end

      BL_DONE: begin
        done       = 1'b1;
        bl_state_n = BL_IDLE;
      end

      default: bl_state_n = BL_IDLE;
    endcase
  end

endmodule : conv1_B_tile_loader
