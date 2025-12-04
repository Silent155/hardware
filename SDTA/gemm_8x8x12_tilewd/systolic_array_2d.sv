// systolic_array_2d.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module systolic_array_2d #(
  parameter int ROWS     = 16,
  parameter int COLS     = 16,
  parameter int DATA_W_P = DATA_W,
  parameter int ACC_W_P  = ACC_W
)(
  input  logic                             clk,
  input  logic                             rst_n,

  // Control
  input  logic                             clear_all,   // clear all PEs accumulators
  input  logic                             valid_in,    // global valid for current wavefront

  // Left boundary A inputs: one per row
  input  logic signed [DATA_W_P-1:0]       a_in   [ROWS],

  // Top boundary B inputs: one per column
  input  logic signed [DATA_W_P-1:0]       b_in   [COLS],

  // Local accumulated C outputs (ROWS x COLS)
  output logic signed [ACC_W_P-1:0]        c_out  [ROWS][COLS],
  output logic                             c_valid[ROWS][COLS]
);

  // Internal wires for A, B, valid
  logic signed [DATA_W_P-1:0] a_sig [ROWS][COLS+1]; // extra col for left boundary
  logic signed [DATA_W_P-1:0] b_sig [ROWS+1][COLS]; // extra row for top boundary
  logic                       v_sig [ROWS][COLS+1];

  genvar r, c;
  generate
    // Connect left boundary A & valid
    for (r = 0; r < ROWS; r++) begin : GEN_LEFT
      assign a_sig[r][0] = a_in[r];
      assign v_sig[r][0] = valid_in;
    end

    // Connect top boundary B
    for (c = 0; c < COLS; c++) begin : GEN_TOP
      assign b_sig[0][c] = b_in[c];
    end

    // Instantiate PE grid
    for (r = 0; r < ROWS; r++) begin : GEN_ROW
      for (c = 0; c < COLS; c++) begin : GEN_COL

        pe_systolic #(
          .DATA_W_P (DATA_W_P),
          .ACC_W_P  (ACC_W_P)
        ) u_pe (
          .clk       (clk),
          .rst_n     (rst_n),
          .clear     (clear_all),
          .valid_in  (v_sig[r][c]),
          .a_in      (a_sig[r][c]),
          .b_in      (b_sig[r][c]),   // from row above
          .acc_in    ('0),            // not used
          .a_out     (a_sig[r][c+1]),
          .b_out     (b_sig[r+1][c]),
          .valid_out (v_sig[r][c+1]),
          .acc_out   (c_out[r][c])
        );

        assign c_valid[r][c] = v_sig[r][c+1];

      end
    end
  endgenerate

endmodule : systolic_array_2d
