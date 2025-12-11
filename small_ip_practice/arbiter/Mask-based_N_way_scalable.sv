/*
8-way Round-Robin Arbiter
rr_arbiter #(
  .N(8)
) u_rr8 (
  .clk (clk),
  .rst_n (rst_n),
  .req (req_8),
  .gnt (gnt_8)
);
16-way Round-Robin Arbiter
rr_arbiter #(
  .N(16)
) u_rr16 (
  .clk (clk),
  .rst_n (rst_n),
  .req (req_16),
  .gnt (gnt_16)
);

「下一輪優先權從 上一個 winner 的下一個 開始掃」
假設：req = 4'b1111 一直都是 1111

初始 mask = 1111

masked_req = 1111 → fixed priority → grant = 0001 (idx0)

next_mask → bits > 0 設成 1 → mask = 1110

下一個 cycle：

masked_req = req & mask = 1111 & 1110 = 1110 → grant = 0010 (idx1)

mask = 1100

再下一個：

masked_req = 1100 → grant = 0100 (idx2)

mask = 1000

再下一個：

masked_req = 1000 → grant = 1000 (idx3)

mask = 0000 → special case：下次 masked_req = 0 → 回到 req 做 priority

之後繞回 idx0。
→ 完整實現 round-robin，無 starvation。
*/
// ============================================================
// Parameterizable Round-Robin Arbiter (mask-based)
// ============================================================
module rr_arbiter #(
  parameter int N = 8
)(
  input  logic         clk,
  input  logic         rst_n,
  input  logic [N-1:0] req,
  output logic [N-1:0] gnt
);

  // mask[i] = 1 means: index i is allowed as "starting point or after"
  logic [N-1:0] mask;

  // masked request & its grant
  logic [N-1:0] masked_req;
  logic [N-1:0] gnt_masked;
  logic [N-1:0] gnt_raw;

  // --- (1) masked request ---
  assign masked_req = req & mask;

  // --- (2) fixed-priority on masked_req and raw req ---

  fixed_priority_arbiter #(.N(N)) u_fp_masked (
    .req (masked_req),
    .gnt (gnt_masked)
  );

  fixed_priority_arbiter #(.N(N)) u_fp_raw (
    .req (req),
    .gnt (gnt_raw)
  );

  // --- (3) Choose which grant to use ---
  // If masked_req has any bit set, we use gnt_masked
  // Otherwise, we wrap around and use gnt_raw
  always_comb begin
    if (masked_req != '0)
      gnt = gnt_masked;
    else
      gnt = gnt_raw;
  end

  // --- (4) Update mask according to the chosen grant ---
  // New mask: bits strictly higher than granted index are 1,
  // others are 0.
  function automatic logic [N-1:0] next_mask (input logic [N-1:0] grant);
    logic [N-1:0] m;
    m = '0;
    // if no grant (no req), keep mask all 1
    if (grant == '0) begin
      m = {N{1'b1}};
    end else begin
      bit seen_one = 0;
      for (int i = 0; i < N; i++) begin
        if (seen_one)
          m[i] = 1'b1;
        else if (grant[i]) begin
          seen_one = 1;
          m[i] = 1'b0; // this index and below are 0
        end else begin
          m[i] = 1'b0;
        end
      end
    end
    return m;
  endfunction

  // --- (5) mask register ---
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mask <= {N{1'b1}};   // everyone allowed at start
    end else begin
      mask <= next_mask(gnt);
    end
  end

endmodule
