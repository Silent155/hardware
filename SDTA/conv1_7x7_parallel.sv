// conv1_7x7_parallel.sv
`include "backbone_pkg.sv"

module conv1_7x7_parallel #(
  parameter int IN_C   = 3,
  parameter int IN_H   = 112,
  parameter int IN_W   = 112,
  parameter int OUT_C  = 64,
  parameter int K      = 7,
  parameter int STRIDE = 2,
  parameter int PAD    = 3
)(
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic                 start,
  output logic                 done,

  input  backbone_pkg::data_t  fmap_in  [0:IN_C*IN_H*IN_W-1],
  input  backbone_pkg::data_t  weight   [0:OUT_C*IN_C*K*K-1],
  output backbone_pkg::data_t  fmap_out [0:OUT_C*((IN_H+2*PAD-K)/STRIDE+1)*((IN_W+2*PAD-K)/STRIDE+1)-1]
);
  import backbone_pkg::*;

  localparam int OUT_H = (IN_H + 2*PAD - K)/STRIDE + 1;
  localparam int OUT_W = (IN_W + 2*PAD - K)/STRIDE + 1;

  // index helper
  function automatic int idx_in(int c, int h, int w);
    return c*IN_H*IN_W + h*IN_W + w;
  endfunction

  function automatic int idx_w(int oc, int ic, int ky, int kx);
    return oc*IN_C*K*K + ic*K*K + ky*K + kx;
  endfunction

  function automatic int idx_out(int oc, int oh, int ow);
    return oc*OUT_H*OUT_W + oh*OUT_W + ow;
  endfunction

  // FSM
  typedef enum logic [1:0] {IDLE, RUN, DONE} state_t;
  state_t state;

  int oc, oh, ow;

  // combinational dot-product over 3*7*7
  acc_t sum_full_comb;

  always_comb begin
    sum_full_comb = '0;

    for (int ic = 0; ic < IN_C; ic++) begin
      for (int ky = 0; ky < K; ky++) begin
        for (int kx = 0; kx < K; kx++) begin
          int in_h = oh*STRIDE + ky - PAD;
          int in_w = ow*STRIDE + kx - PAD;

          data_t x_val;

          if (in_h < 0 || in_h >= IN_H || in_w < 0 || in_w >= IN_W) begin
            x_val = '0;
          end
          else begin
            int idx = idx_in(ic, in_h, in_w);
            x_val = fmap_in[idx];
          end

          int w_idx = idx_w(oc, ic, ky, kx);
          data_t w_val = weight[w_idx];

          acc_t mul = acc_t'(x_val) * acc_t'(w_val);
          sum_full_comb += mul;
        end
      end
    end
  end

  // main FSM
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      done  <= 1'b0;
      oc    <= 0;
      oh    <= 0;
      ow    <= 0;
    end else begin
      case (state)
        IDLE: begin
          done <= 1'b0;
          if (start) begin
            oc <= 0;
            oh <= 0;
            ow <= 0;
            state <= RUN;
          end
        end

        RUN: begin
          // quantize & saturate
          acc_t sum_q = sum_full_comb >>> FRAC_BITS;
          data_t y    = sat16(sum_q);

          int oidx = idx_out(oc, oh, ow);
          fmap_out[oidx] <= y;

          // update indices
          if (ow < OUT_W-1) begin
            ow <= ow + 1;
          end else begin
            ow <= 0;
            if (oh < OUT_H-1) begin
              oh <= oh + 1;
            end else begin
              oh <= 0;
              if (oc < OUT_C-1) begin
                oc <= oc + 1;
              end else begin
                state <= DONE;
              end
            end
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
