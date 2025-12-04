// pe_systolic.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module pe_systolic #(
  parameter int DATA_W_P = DATA_W,
  parameter int ACC_W_P  = ACC_W
)(
  input  logic                       clk,
  input  logic                       rst_n,

  // Control
  input  logic                       clear,      // clear local accumulator
  input  logic                       valid_in,   // wavefront valid

  // Data in
  input  logic signed [DATA_W_P-1:0] a_in,
  input  logic signed [DATA_W_P-1:0] b_in,
  input  logic signed [ACC_W_P-1:0]  acc_in,    // not used in this simple design

  // Data out (to neighbor)
  output logic signed [DATA_W_P-1:0] a_out,
  output logic signed [DATA_W_P-1:0] b_out,
  output logic                       valid_out,

  // Local accumulated result
  output logic signed [ACC_W_P-1:0]  acc_out
);

  // Local accumulator register (output-stationary)
  logic signed [ACC_W_P-1:0] acc_reg;

  // Combinational product
  logic signed [2*DATA_W_P-1:0] mult;

  assign mult = a_in * b_in;

  // Propagate data & valid
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_out     <= '0;
      b_out     <= '0;
      valid_out <= 1'b0;
      acc_reg   <= '0;
    end else begin
      a_out     <= a_in;
      b_out     <= b_in;
      valid_out <= valid_in;

      if (clear) begin
        acc_reg <= '0;
      end else if (valid_in) begin
        // acc = acc + mult (sign-extended)
        acc_reg <= acc_reg + {{(ACC_W_P-2*DATA_W_P){mult[2*DATA_W_P-1]}}, mult};
      end
    end
  end

  assign acc_out = acc_reg;

endmodule : pe_systolic
