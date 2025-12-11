// =============================================================
// 4-way Round-Robin Arbiter with Stage-1 pipeline register
// =============================================================
module rr4_stage1 (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [3:0] req,
  output logic [3:0] grant_r,   // registered winner (1-hot)
  output logic       has_req_r  // registered "any request?" flag
);

  logic [1:0] g0, g1;       // from leaf rr2
  logic [1:0] top_req;
  logic [1:0] g_top;
  logic [3:0] grant_comb;
  logic       has_req_comb;

  // two 2-way arbiters for [1:0] and [3:2]
  rr2_core u_leaf0 (
    .clk (clk),
    .rst_n (rst_n),
    .req (req[1:0]),
    .gnt (g0)
  );

  rr2_core u_leaf1 (
    .clk (clk),
    .rst_n (rst_n),
    .req (req[3:2]),
    .gnt (g1)
  );

  // top-level request: if any winner in each pair
  assign top_req = { (g1 != 2'b00), (g0 != 2'b00) };

  rr2_core u_top (
    .clk (clk),
    .rst_n (rst_n),
    .req (top_req),
    .gnt (g_top)
  );

  // decode 4-bit grant (combinational)
  always_comb begin
    grant_comb = 4'b0000;

    if (g_top[0]) begin
      grant_comb[1:0] = g0;
    end
    else if (g_top[1]) begin
      grant_comb[3:2] = g1;
    end
  end

  assign has_req_comb = (grant_comb != 4'b0000);

  // -------- Stage-1 pipeline register --------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant_r   <= 4'b0000;
      has_req_r <= 1'b0;
    end else begin
      grant_r   <= grant_comb;
      has_req_r <= has_req_comb;
    end
  end

endmodule
