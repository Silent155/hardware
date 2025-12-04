// pe_2d.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module pe_2d #(
  parameter int DATA_W_P = DATA_W,
  parameter int ACC_W_P  = ACC_W
)(
  input  logic                         clk,
  input  logic                         rst_n,

  input  logic                         clear_all,
  input  logic                         valid_in,

  // from left / top
  input  logic signed [DATA_W_P-1:0]   a_in,
  input  logic signed [DATA_W_P-1:0]   b_in,

  // to right / bottom
  output logic signed [DATA_W_P-1:0]   a_out,
  output logic signed [DATA_W_P-1:0]   b_out,

  // local accumulation
  output logic signed [ACC_W_P-1:0]    c_out
);

  logic signed [DATA_W_P-1:0] a_reg, b_reg;
  logic signed [ACC_W_P-1:0]  acc_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_reg   <= '0;
      b_reg   <= '0;
      acc_reg <= '0;
    end else begin
      if (clear_all) begin
        acc_reg <= '0;
      end else if (valid_in) begin
        acc_reg <= acc_reg + a_in * b_in;
      end
      a_reg <= a_in;
      b_reg <= b_in;
    end
  end

  assign a_out = a_reg;
  assign b_out = b_reg;
  assign c_out = acc_reg;

endmodule : pe_2d
