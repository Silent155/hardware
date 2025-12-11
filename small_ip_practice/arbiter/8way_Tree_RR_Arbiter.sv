/*
req[7:0]
 ↓        ↓
rr4_low  rr4_high
 ↓        ↓
 two group winners → rr2 top → final index

*/
// =============================================================
// 8-way Tree Round-Robin Arbiter
// =============================================================
module rr8 (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [7:0]  req,
  output logic [7:0]  gnt
);

  logic [3:0] g_low, g_high;  // from rr4
  logic       req_low, req_high;
  logic [1:0] g_top;          // top rr2 winner

  // 4-way low group
  rr4 u_low (
    .clk(clk), .rst_n(rst_n),
    .req(req[3:0]),
    .gnt(g_low)
  );

  // 4-way high group
  rr4 u_high (
    .clk(clk), .rst_n(rst_n),
    .req(req[7:4]),
    .gnt(g_high)
  );

  // convert to 2-bit request for top arbiter
  assign req_low  = (g_low  != 4'b0000);
  assign req_high = (g_high != 4'b0000);

  // top 2-way RR arbiter
  rr2 rr_top (
    .clk(clk), .rst_n(rst_n),
    .req({req_high, req_low}),
    .gnt(g_top)
  );

  // decode final 8-bit grant
  always_comb begin
    gnt = 8'b0000_0000;

    case (g_top)
      2'b01: gnt[3:0] = g_low;
      2'b10: gnt[7:4] = g_high;
      default: gnt = 8'b0000_0000;
    endcase
  end

endmodule
