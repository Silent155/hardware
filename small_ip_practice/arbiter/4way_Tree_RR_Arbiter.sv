/*
req[3:0]
  ↓        ↓
 rr2a    rr2b 
  ↓        ↓
 2 winners (one from each pair)
  ↓
 top rr2 (decides final winner)

*/
// =============================================================
// 4-way Tree Round-Robin Arbiter
// =============================================================
module rr4 (
  input  logic        clk,
  input  logic        rst_n,
  input  logic [3:0]  req,
  output logic [3:0]  gnt
);

  logic [1:0] g0, g1;      // grants from leaf nodes
  logic [1:0] req_top;     // request vector to top rr2
  logic [1:0] g_top;       // top-level winner

  // leaf arbiters
  rr2 rr_leaf0(
    .clk(clk), .rst_n(rst_n),
    .req(req[1:0]),
    .gnt(g0)
  );

  rr2 rr_leaf1(
    .clk(clk), .rst_n(rst_n),
    .req(req[3:2]),
    .gnt(g1)
  );

  // top-level request:
  // if any winner inside leaf, represent by 1 bit
  assign req_top = { (g1 != 2'b00), (g0 != 2'b00) };

  // top-level arbiter
  rr2 rr_top(
    .clk(clk), .rst_n(rst_n),
    .req(req_top),
    .gnt(g_top)
  );

  // decode final winner
  always_comb begin
    gnt = 4'b0000;
    
    // winner from low leaf?
    if (g_top[0]) begin
      gnt[1:0] = g0;
    end
    // winner from high leaf?
    else if (g_top[1]) begin
      gnt[3:2] = g1;
    end
  end

endmodule
