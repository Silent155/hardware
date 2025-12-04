// gemm_systolic_core.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module gemm_systolic_core #(
  parameter int ROWS     = 16,
  parameter int COLS     = 16,
  parameter int K_MAX    = 2048,   // maximum K per tile
  parameter int DATA_W_P = DATA_W,
  parameter int ACC_W_P  = ACC_W
)(
  input  logic                         clk,
  input  logic                         rst_n,

  // Config for this GEMM tile: C[MxN] = A[MxK] * B[KxN]
  input  logic                         start,
  input  logic [$clog2(ROWS+1)-1:0]    cfg_m,   // rows in this tile (<= ROWS)
  input  logic [$clog2(COLS+1)-1:0]    cfg_n,   // cols in this tile (<= COLS)
  input  logic [$clog2(K_MAX+1)-1:0]   cfg_k,   // K length

  output logic                         busy,
  output logic                         done,

  // Simple local RAM interfaces for A and B
  input  logic signed [DATA_W_P-1:0]   A_buf  [ROWS][K_MAX],
  input  logic signed [DATA_W_P-1:0]   B_buf  [K_MAX][COLS],

  // C result output (after done = 1)
  output logic signed [ACC_W_P-1:0]    C_buf  [ROWS][COLS]
);

  typedef enum logic [1:0] { IDLE, RUN, FLUSH, DONE_S } state_t;
  state_t state, state_n;

  logic [$clog2(K_MAX+ROWS+COLS+2)-1:0] cycle_cnt;
  logic                                  clear_all;
  logic                                  valid_in;

  int m_eff, n_eff, k_eff;
  int end_cycle;

  logic signed [DATA_W_P-1:0] a_in [ROWS];
  logic signed [DATA_W_P-1:0] b_in [COLS];

  logic signed [ACC_W_P-1:0]  c_out   [ROWS][COLS];
  logic                       c_valid [ROWS][COLS];

  integer i1,j1;

  // systolic array
  systolic_array_2d #(
    .ROWS     (ROWS),
    .COLS     (COLS),
    .DATA_W_P (DATA_W_P),
    .ACC_W_P  (ACC_W_P)
  ) u_array (
    .clk      (clk),
    .rst_n    (rst_n),
    .clear_all(clear_all),
    .valid_in (valid_in),
    .a_in     (a_in),
    .b_in     (b_in),
    .c_out    (c_out),
    .c_valid  (c_valid)
  );

  // derive sizes
  always_comb begin
    m_eff = cfg_m;
    n_eff = cfg_n;
    k_eff = cfg_k;
    end_cycle = (k_eff - 1) + (m_eff - 1) + (n_eff - 1);
  end

  // FSM + cycle counter
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= IDLE;
      cycle_cnt <= '0;
    end else begin
      state <= state_n;
      if (state == RUN) cycle_cnt <= cycle_cnt + 1'b1;
      else              cycle_cnt <= '0;
    end
  end

  always_comb begin
    state_n   = state;
    busy      = 1'b0;
    done      = 1'b0;
    clear_all = 1'b0;
    valid_in  = 1'b0;

    case(state)
      IDLE: begin
        if (start) begin
          state_n   = RUN;
          clear_all = 1'b1;
        end
      end

      RUN: begin
        busy     = 1'b1;
        valid_in = 1'b1;
        if (cycle_cnt == end_cycle)
          state_n = FLUSH;
      end

      FLUSH: begin
        busy    = 1'b1;
        state_n = DONE_S;
      end

      DONE_S: begin
        done    = 1'b1;
        state_n = IDLE;
      end
    endcase
  end

  // data injection
  int cyc, k_idx_A, k_idx_B;
  always_comb begin
    for (i1 = 0; i1 < ROWS; i1++)
      a_in[i1] = '0;
    for (j1 = 0; j1 < COLS; j1++)
      b_in[j1] = '0;

    if (state == RUN) begin
      cyc = cycle_cnt;

      for (int row = 0; row < m_eff; row++) begin
        k_idx_A = cyc - row;
        if (k_idx_A >= 0 && k_idx_A < k_eff)
          a_in[row] = A_buf[row][k_idx_A];
      end

      for (int col = 0; col < n_eff; col++) begin
        k_idx_B = cyc - col;
        if (k_idx_B >= 0 && k_idx_B < k_eff)
          b_in[col] = B_buf[k_idx_B][col];
      end
    end
  end

  // latch C at FLUSH->DONE
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i=0; i<ROWS; i++)
        for (int j=0; j<COLS; j++)
          C_buf[i][j] <= '0;
    end else if (state == FLUSH && state_n == DONE_S) begin
      for (int i=0; i<m_eff; i++)
        for (int j=0; j<n_eff; j++)
          C_buf[i][j] <= c_out[i][j];
    end
  end

endmodule : gemm_systolic_core
