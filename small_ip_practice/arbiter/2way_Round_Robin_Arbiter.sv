/*
2-way Round-Robin Arbiter
Round-robin 是一種 公平的仲裁（arbitration）演算法，用途是：
當多個模組同時要求使用同一資源時，不是永遠讓同一個人先，而是輪流給每個人一次機會。

Question
Design a 2-way round-robin arbiter:

Inputs: req[1:0]

Outputs: gnt[1:0]

If both request at the same time, alternate grant between them.

Assume one-cycle grant; no locking.

cycle :   1   2   3   4   5
req   :  11  11  11  11  11
gnt   :  01  10  01  10  01   (alternating)
last  :   0   1   0   1   0

*/
module rr_arbiter_2 (
  input  logic clk,
  input  logic rst_n,
  input  logic [1:0] req,
  output logic [1:0] gnt
);

  logic last; // 0 or 1: who was served last

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      last <= 1'b0;
    end else begin
      if      (gnt[0]) last <= 1'b0;
      else if (gnt[1]) last <= 1'b1;
    end
  end

  always_comb begin
    gnt = 2'b00;
    unique case (req)
      2'b01: gnt = 2'b01;   // only 0 requests
      2'b10: gnt = 2'b10;   // only 1 requests
      2'b11: begin          // both request
        if (last == 1'b0) gnt = 2'b10; // last served 0 → this time serve 1
        else              gnt = 2'b01;
      end
      default: gnt = 2'b00;
    endcase
  end

endmodule
