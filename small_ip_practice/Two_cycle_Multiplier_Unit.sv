/*
Two-cycle Multiplier Unit (with start / busy / done)

Question
Design a 16x16 multiplier unit that behaves like this:

Inputs: clk, rst_n, start, a[15:0], b[15:0]

Outputs: busy, done, prod[31:0]

When start=1 and busy=0, latch inputs and start computation.

After exactly 2 cycles, output prod and pulse done for 1 cycle.

busy must be 1 during computation.

波形概念（英文）

假設：

cycle1：start=1

cycle2~3：busy=1

cycle3：done=1

cycle :   1   2   3   4
start :   1   0   0   0
busy  :   0   1   1   0
done  :   0   0   1   0
state : IDLE C1  C2 IDLE


這就是典型的 multi-cycle functional unit 題，NVIDIA 類型公司很愛
*/

module mul2cycle (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        start,
  input  logic [15:0] a,
  input  logic [15:0] b,
  output logic        busy,
  output logic        done,
  output logic [31:0] prod
);

  typedef enum logic [1:0] {
    IDLE  = 2'b00,
    C1    = 2'b01,
    C2    = 2'b10
  } state_e;

  state_e state, state_n;

  logic [15:0] a_q, b_q;
  logic [31:0] prod_q;

  // state register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= state_n;
  end

  // latch inputs
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_q   <= '0;
      b_q   <= '0;
      prod_q<= '0;
    end else begin
      if (start && (state == IDLE)) begin
        a_q <= a;
        b_q <= b;
      end
      // simple model: combinational multiply at C2
      if (state == C2) begin
        prod_q <= a_q * b_q;
      end
    end
  end

  // next-state logic
  always_comb begin
    state_n = state;
    done    = 1'b0;
    busy    = 1'b0;

    case (state)
      IDLE: begin
        busy = 1'b0;
        if (start) begin
          state_n = C1;
        end
      end

      C1: begin
        busy    = 1'b1;
        state_n = C2;
      end

      C2: begin
        busy    = 1'b1;
        done    = 1'b1;
        state_n = IDLE;
      end
    endcase
  end

  assign prod = prod_q;

endmodule
