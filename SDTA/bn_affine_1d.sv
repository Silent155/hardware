// bn_affine_1d.sv
`include "backbone_pkg.sv"

module bn_affine_1d #(
  parameter int C = 512,
  parameter bit USE_RELU = 1'b0  // 預設不用 ReLU
)(
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic                 start,
  output logic                 done,

  input  backbone_pkg::data_t  vec_in  [0:C-1],
  input  backbone_pkg::data_t  scale   [0:C-1],
  input  backbone_pkg::data_t  shift   [0:C-1],
  output backbone_pkg::data_t  vec_out [0:C-1]
);
  import backbone_pkg::*;

  typedef enum logic [1:0] {
    IDLE,
    RUN,
    DONE
  } state_t;

  state_t state;
  int i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      done  <= 1'b0;
      i     <= 0;
    end else begin
      case (state)
        IDLE: begin
          done <= 1'b0;
          if (start) begin
            i     <= 0;
            state <= RUN;
          end
        end

        RUN: begin
          data_t x  = vec_in[i];
          data_t sc = scale[i];
          data_t sh = shift[i];

          acc_t mul   = acc_t'(x) * acc_t'(sc);             // Q4.28
          acc_t mul_q = mul >>> FRAC_BITS;                  // 回到 Q2.14
          acc_t sum   = mul_q + acc_t'(sh);

          data_t y = sat16(sum);
          if (USE_RELU) begin
            y = relu(y);
          end
          vec_out[i] <= y;

          if (i < C-1) begin
            i <= i + 1;
          end else begin
            state <= DONE;
          end
        end

        DONE: begin
          done  <= 1'b1;
          state <= IDLE;
        end

      endcase
    end
  end

endmodule
