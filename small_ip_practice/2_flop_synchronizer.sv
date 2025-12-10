/*
Question
Explain and code a 2-flop synchronizer for a single-bit signal crossing from clk_a to clk_b.
波形概念
clk_a : _/‾\_/‾\_/‾\_/‾\_
clk_b : __/‾\__/‾\__/‾\__/‾
in_a  : ___0___1__________
ff1   : ______0___1_______
ff2   : ______0_______1___
out_b : ______0_______1___
*/

module sync_2ff (
  input  logic clk_b,
  input  logic rst_b_n,
  input  logic in_a,       // in clk_a domain, after you registered it
  output logic out_b       // in clk_b domain
);

  logic ff1, ff2;

  always_ff @(posedge clk_b or negedge rst_b_n) begin
    if (!rst_b_n) begin
      ff1  <= 1'b0;
      ff2  <= 1'b0;
    end else begin
      ff1  <= in_a;
      ff2  <= ff1;
    end
  end

  assign out_b = ff2;

endmodule
