// =============================================================
// 8-way Pipelined Tree Round-Robin Arbiter
//   - 2 pipeline stages
//   - Latency: ~2 cycles from req to gnt (加上內部 rr2 state，實際可視為 2~3 拍)
// =============================================================
module rr8_tree_pipelined (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [7:0] req,
  output logic [7:0] gnt
);

  // ----- Stage 1 outputs (registered) -----
  logic [3:0] g_low_r, g_high_r;
  logic       has_low_r, has_high_r;

  // ----- Stage 2 combinational -----
  logic [1:0] top_req;
  logic [1:0] g_top;
  logic [7:0] gnt_comb;

  // -------- Stage 1: two 4-way groups --------
  rr4_stage1 u_low (
    .clk      (clk),
    .rst_n    (rst_n),
    .req      (req[3:0]),
    .grant_r  (g_low_r),
    .has_req_r(has_low_r)
  );

  rr4_stage1 u_high (
    .clk      (clk),
    .rst_n    (rst_n),
    .req      (req[7:4]),
    .grant_r  (g_high_r),
    .has_req_r(has_high_r)
  );

  // -------- Stage 2: top-level 2-way RR --------
  assign top_req = { has_high_r, has_low_r };

  rr2_core u_top (
    .clk (clk),
    .rst_n (rst_n),
    .req (top_req),
    .gnt (g_top)
  );

  // Decode final 8-way grant (combinational)
  always_comb begin
    gnt_comb = 8'b0000_0000;
    unique case (g_top)
      2'b01: gnt_comb[3:0] = g_low_r;
      2'b10: gnt_comb[7:4] = g_high_r;
      default: gnt_comb    = 8'b0000_0000;
    endcase
  end

  // -------- Stage-2 output pipeline register --------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      gnt <= 8'b0000_0000;
    else
      gnt <= gnt_comb;
  end

endmodule
