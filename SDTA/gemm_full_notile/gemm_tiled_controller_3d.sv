// gemm_tiled_controller_3d.sv (sticky done + watchdog 版)
`timescale 1ns/1ps
import backbone_pkg::*;

module gemm_tiled_controller_3d #(
  parameter int ROWS      = 16,
  parameter int COLS      = 16,
  parameter int M_TOTAL   = 32,
  parameter int N_TOTAL   = 48,
  parameter int K_TOTAL   = 80,
  parameter int K_MAX     = 2048,
  parameter int K_TILE    = 16,
  parameter int DATA_W_P  = DATA_W,
  parameter int ACC_W_P   = ACC_W
)(
  input  logic                         clk,
  input  logic                         rst_n,

  input  logic                         start,
  output logic                         busy,
  output logic                         done,   // sticky done

  input  logic signed [DATA_W_P-1:0]   A_full [M_TOTAL][K_TOTAL],
  input  logic signed [DATA_W_P-1:0]   B_full [K_TOTAL][N_TOTAL],
  output logic signed [ACC_W_P-1:0]    C_full [M_TOTAL][N_TOTAL]
);

  // ----------------------------------------------------------------
  // systolic core 接口
  // ----------------------------------------------------------------
  logic signed [DATA_W_P-1:0] A_buf [ROWS][K_MAX];
  logic signed [DATA_W_P-1:0] B_buf [K_MAX][COLS];
  logic signed [ACC_W_P-1:0]  C_tile[ROWS][COLS];

  logic core_start;
  logic core_busy, core_done;

  logic [$clog2(ROWS+1)-1:0]  cfg_m;
  logic [$clog2(COLS+1)-1:0]  cfg_n;
  logic [$clog2(K_MAX+1)-1:0] cfg_k;

  gemm_systolic_core #(
    .ROWS     (ROWS),
    .COLS     (COLS),
    .K_MAX    (K_MAX),
    .DATA_W_P (DATA_W_P),
    .ACC_W_P  (ACC_W_P)
  ) u_core (
    .clk   (clk),
    .rst_n (rst_n),

    .start (core_start),
    .cfg_m (cfg_m),
    .cfg_n (cfg_n),
    .cfg_k (cfg_k),

    .busy  (core_busy),
    .done  (core_done),

    .A_buf (A_buf),
    .B_buf (B_buf),
    .C_buf (C_tile)
  );

  // ----------------------------------------------------------------
  // tiling indices
  // ----------------------------------------------------------------
  int tile_m_base, tile_n_base, tile_k_base;
  int tile_m_base_n, tile_n_base_n, tile_k_base_n;

  int load_cnt_A, load_cnt_A_n;
  int load_cnt_B, load_cnt_B_n;
  int acc_cnt,     acc_cnt_n;

  typedef enum logic [3:0] {
    S_IDLE,
    S_SET_TILE_MN,
    S_CHECK_MN_DONE,
    S_INIT_K_TILE,
    S_CHECK_K_DONE,
    S_LOAD_A,
    S_LOAD_B,
    S_START_CORE,
    S_WAIT_CORE,
    S_ACCUM_C,
    S_NEXT_K_TILE,
    S_NEXT_MN_TILE,
    S_DONE_ALL
  } state_t;

  state_t state, state_n;

  // ------------------------------
  // sticky done + watchdog
  // ------------------------------
  logic done_r;
  assign done = done_r;

  int watchdog_cnt;

  // ----------------------------------------------------------------
  // Sequential: 狀態、index、done_r、watchdog
  // ----------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= S_IDLE;
      tile_m_base  <= 0;
      tile_n_base  <= 0;
      tile_k_base  <= 0;
      load_cnt_A   <= 0;
      load_cnt_B   <= 0;
      acc_cnt      <= 0;
      done_r       <= 1'b0;
      watchdog_cnt <= 0;

      for (int i = 0; i < M_TOTAL; i++)
        for (int j = 0; j < N_TOTAL; j++)
          C_full[i][j] <= '0;
    end
    else begin
      state        <= state_n;
      tile_m_base  <= tile_m_base_n;
      tile_n_base  <= tile_n_base_n;
      tile_k_base  <= tile_k_base_n;
      load_cnt_A   <= load_cnt_A_n;
      load_cnt_B   <= load_cnt_B_n;
      acc_cnt      <= acc_cnt_n;

      // sticky done：第一次 DONE_ALL 之後維持為 1
      if (state == S_DONE_ALL)
        done_r <= 1'b1;
      else if (state == S_IDLE && start)
        done_r <= 1'b0;

      // watchdog：只要不在 IDLE 就加計數
      if (state != S_IDLE)
        watchdog_cnt <= watchdog_cnt + 1;
      else
        watchdog_cnt <= 0;

      // 過多 cycles 還沒結束，print debug
      if (watchdog_cnt > 20_000_000) begin
        $display("[WATCHDOG] stuck! time=%0t state=%0d m_base=%0d n_base=%0d k_base=%0d loadA=%0d loadB=%0d acc=%0d",
                 $time, state, tile_m_base, tile_n_base, tile_k_base,
                 load_cnt_A, load_cnt_B, acc_cnt);
        $stop;
      end
    end
  end

  // ----------------------------------------------------------------
  // Combinational: next state, cfg, core_start, busy
  // ----------------------------------------------------------------
  int m_eff, n_eff, k_eff;
  int total_A, total_B, total_C;

  always_comb begin
    state_n        = state;
    tile_m_base_n  = tile_m_base;
    tile_n_base_n  = tile_n_base;
    tile_k_base_n  = tile_k_base;
    load_cnt_A_n   = load_cnt_A;
    load_cnt_B_n   = load_cnt_B;
    acc_cnt_n      = acc_cnt;

    busy           = 1'b0;
    core_start     = 1'b0;

    // ---- compute effective tile sizes ----
    if (tile_m_base + ROWS <= M_TOTAL)
      m_eff = ROWS;
    else
      m_eff = (M_TOTAL - tile_m_base);

    if (tile_n_base + COLS <= N_TOTAL)
      n_eff = COLS;
    else
      n_eff = (N_TOTAL - tile_n_base);

    if (tile_k_base + K_TILE <= K_TOTAL)
      k_eff = K_TILE;
    else
      k_eff = (K_TOTAL - tile_k_base);

    if (m_eff < 0) m_eff = 0;
    if (n_eff < 0) n_eff = 0;
    if (k_eff < 0) k_eff = 0;

    cfg_m = m_eff[$bits(cfg_m)-1:0];
    cfg_n = n_eff[$bits(cfg_n)-1:0];
    cfg_k = k_eff[$bits(cfg_k)-1:0];

    total_A = m_eff * k_eff;
    total_B = k_eff * n_eff;
    total_C = m_eff * n_eff;

    case (state)

      S_IDLE: begin
        if (start) begin
          tile_m_base_n = 0;
          tile_n_base_n = 0;
          tile_k_base_n = 0;
          load_cnt_A_n  = 0;
          load_cnt_B_n  = 0;
          acc_cnt_n     = 0;
          state_n       = S_SET_TILE_MN;
        end
      end

      S_SET_TILE_MN: begin
        busy    = 1'b1;
        state_n = S_CHECK_MN_DONE;
      end

      S_CHECK_MN_DONE: begin
        busy = 1'b1;
        if (tile_m_base >= M_TOTAL || m_eff == 0 || n_eff == 0)
          state_n = S_DONE_ALL;
        else begin
          tile_k_base_n = 0;
          state_n       = S_INIT_K_TILE;
        end
      end

      S_INIT_K_TILE: begin
        busy         = 1'b1;
        load_cnt_A_n = 0;
        load_cnt_B_n = 0;
        acc_cnt_n    = 0;
        state_n      = S_CHECK_K_DONE;
      end

      S_CHECK_K_DONE: begin
        busy = 1'b1;
        if (tile_k_base >= K_TOTAL || k_eff == 0)
          state_n = S_NEXT_MN_TILE;
        else
          state_n = S_LOAD_A;
      end

      // A tile
      S_LOAD_A: begin
        busy = 1'b1;
        if (load_cnt_A < total_A) begin
          int row = load_cnt_A / k_eff;
          int kk  = load_cnt_A % k_eff;
          A_buf[row][kk] = A_full[tile_m_base + row][tile_k_base + kk];
          load_cnt_A_n   = load_cnt_A + 1;
        end
        else begin
          load_cnt_B_n = 0;
          state_n      = S_LOAD_B;
        end
      end

      // B tile
      S_LOAD_B: begin
        busy = 1'b1;
        if (load_cnt_B < total_B) begin
          int kk  = load_cnt_B / n_eff;
          int col = load_cnt_B % n_eff;
          B_buf[kk][col] = B_full[tile_k_base + kk][tile_n_base + col];
          load_cnt_B_n   = load_cnt_B + 1;
        end
        else begin
          state_n   = S_START_CORE;
        end
      end

      S_START_CORE: begin
        busy       = 1'b1;
        core_start = 1'b1;
        state_n    = S_WAIT_CORE;
      end

      S_WAIT_CORE: begin
        busy = 1'b1;
        if (core_done)
          state_n = S_ACCUM_C;
      end

      S_ACCUM_C: begin
        busy = 1'b1;
        if (acc_cnt < total_C) begin
          int row = acc_cnt / n_eff;
          int col = acc_cnt % n_eff;
          if (tile_k_base == 0)
            C_full[tile_m_base + row][tile_n_base + col] = C_tile[row][col];
          else
            C_full[tile_m_base + row][tile_n_base + col]
              = C_full[tile_m_base + row][tile_n_base + col] + C_tile[row][col];

          acc_cnt_n = acc_cnt + 1;
        end
        else begin
          state_n = S_NEXT_K_TILE;
        end
      end

      S_NEXT_K_TILE: begin
        busy          = 1'b1;
        tile_k_base_n = tile_k_base + k_eff;
        state_n       = S_INIT_K_TILE;
      end

      S_NEXT_MN_TILE: begin
        busy = 1'b1;
        if (tile_n_base + n_eff < N_TOTAL) begin
          tile_n_base_n = tile_n_base + n_eff;
          tile_k_base_n = 0;
          state_n       = S_SET_TILE_MN;
        end
        else begin
          tile_n_base_n = 0;
          tile_m_base_n = tile_m_base + m_eff;
          tile_k_base_n = 0;
          state_n       = S_SET_TILE_MN;
        end
      end

      S_DONE_ALL: begin
        busy    = 1'b0;
        state_n = S_IDLE;
      end

      default: begin
        state_n = S_IDLE;
      end
    endcase
  end

endmodule
