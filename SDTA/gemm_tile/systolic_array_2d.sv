// systolic_array_2d.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module systolic_array_2d #(
  parameter int ROWS     = 16,
  parameter int COLS     = 16,
  parameter int DATA_W_P = DATA_W,
  parameter int ACC_W_P  = ACC_W
)(
  input  logic                         clk,
  input  logic                         rst_n,
  input  logic                         clear_all,
  input  logic                         valid_in,

  input  logic signed [DATA_W_P-1:0]   a_in [ROWS],
  input  logic signed [DATA_W_P-1:0]   b_in [COLS],

  output logic signed [ACC_W_P-1:0]    c_out   [ROWS][COLS],
  output logic                         c_valid [ROWS][COLS]   // 目前沒被上層用
);

  // 內部連線
  logic signed [DATA_W_P-1:0] a_wire [ROWS][COLS+1];
  logic signed [DATA_W_P-1:0] b_wire [ROWS+1][COLS];

  // 輸入接左/上邊界
  genvar i, j;
  generate
    for (i = 0; i < ROWS; i++) begin : GEN_A_IN
      assign a_wire[i][0] = a_in[i];
    end
    for (j = 0; j < COLS; j++) begin : GEN_B_IN
      assign b_wire[0][j] = b_in[j];
    end
  endgenerate

  // PE array
  generate
    for (i = 0; i < ROWS; i++) begin : GEN_ROW
      for (j = 0; j < COLS; j++) begin : GEN_COL
        pe_2d #(
          .DATA_W_P (DATA_W_P),
          .ACC_W_P  (ACC_W_P)
        ) u_pe (
          .clk       (clk),
          .rst_n     (rst_n),
          .clear_all (clear_all),
          .valid_in  (valid_in),
          .a_in      (a_wire[i][j]),
          .b_in      (b_wire[i][j]),
          .a_out     (a_wire[i][j+1]),
          .b_out     (b_wire[i+1][j]),
          .c_out     (c_out[i][j])
        );

        // 簡單給個 valid 訊號（先全 1，因為上層沒用到）
        assign c_valid[i][j] = 1'b1;
      end
    end
  endgenerate

endmodule : systolic_array_2d
