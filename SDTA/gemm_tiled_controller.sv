// gemm_tiled_controller.sv
`timescale 1ns/1ps
import backbone_pkg::*;

// 大矩陣 C[M_TOTAL x N_TOTAL] = A[M_TOTAL x K_TOTAL] * B[K_TOTAL x N_TOTAL]
// 內部用 16x16 systolic tile 去掃過整個 M,N 平面。
// 目前假設: K_TOTAL <= K_MAX (不再對 K 切 tile)
module gemm_tiled_controller #(
  parameter int ROWS      = 16,
  parameter int COLS      = 16,
  parameter int M_TOTAL   = 64,    // 實際矩陣 M
  parameter int N_TOTAL   = 64,    // 實際矩陣 N
  parameter int K_TOTAL   = 64,    // 實際矩陣 K (<= K_MAX)
  parameter int K_MAX     = 2048,  // gemm_systolic_core 的 K_MAX
  parameter int DATA_W_P  = DATA_W,
  parameter int ACC_W_P   = ACC_W
)(
  input  logic                         clk,
  input  logic                         rst_n,

  input  logic                         start,   // 啟動「整顆」大 GEMM
  output logic                         busy,    // 任何 tile 在跑都為 1
  output logic                         done,    // 全部 tiles 結束，打一拍 1

  // 大矩陣 A, B, C 介面（暫時用 local RAM 形式）
  input  logic signed [DATA_W_P-1:0]   A_full [M_TOTAL][K_TOTAL],
  input  logic signed [DATA_W_P-1:0]   B_full [K_TOTAL][N_TOTAL],
  output logic signed [ACC_W_P-1:0]    C_full [M_TOTAL][N_TOTAL]
);

  // ----------------------------------------------------------------
  // 內部 tile buffer <-> systolic core
  // ----------------------------------------------------------------
  logic signed [DATA_W_P-1:0] A_buf [ROWS][K_MAX];
  logic signed [DATA_W_P-1:0] B_buf [K_MAX][COLS];
  logic signed [ACC_W_P-1:0]  C_tile[ROWS][COLS];

  logic core_start;
  logic core_busy, core_done;

  logic [$clog2(ROWS+1)-1:0]  cfg_m;
  logic [$clog2(COLS+1)-1:0]  cfg_n;
  logic [$clog2(K_MAX+1)-1:0] cfg_k;

  // 實際這一個 tile 的有效大小
  int m_eff, n_eff, k_eff;

  // ----------------------------------------------------------------
  // Instantiate systolic GEMM core (你那顆)
  // ----------------------------------------------------------------
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
  // Tiling indices
  //  tile_m_base: 目前 tile 左上角在大矩陣中的 row 起始
  //  tile_n_base: 目前 tile 左上角在大矩陣中的 col 起始
  // ----------------------------------------------------------------
  int tile_m_base;  // 0 .. M_TOTAL-1，step = m_eff
  int tile_n_base;  // 0 .. N_TOTAL-1，step = n_eff

  // 載入 A/B tile 時用的 counter
  int load_row;
  int load_col;
  int load_k;

  // 將 tile 寫回 C_full 用的 counter
  int acc_row;
  int acc_col;

  // ----------------------------------------------------------------
  // Controller FSM
  // ----------------------------------------------------------------
  typedef enum logic [2:0] {
    S_IDLE,
    S_INIT_TILE,   // 設定 m_eff/n_eff/k_eff, 清 counter
    S_LOAD_A,      // 把 A_full -> A_buf
    S_LOAD_B,      // 把 B_full -> B_buf
    S_START_CORE,  // 打 core_start 一拍
    S_WAIT_CORE,   // 等 core_done
    S_ACCUM_C,     // 把 C_tile 寫回 C_full（現在是覆蓋，之後 K-tiling 再改 +=）
    S_NEXT_TILE,   // 移到下一個 tile
    S_DONE_ALL
  } ctrl_state_t;

  ctrl_state_t state, state_n;

  // ----------------------------------------------------------------
  // FSM 狀態暫存
  // ----------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= S_IDLE;
      tile_m_base  <= 0;
      tile_n_base  <= 0;
      load_row     <= 0;
      load_col     <= 0;
      load_k       <= 0;
      acc_row      <= 0;
      acc_col      <= 0;

      // 初始化 C_full 為 0（這裡視需求，可以改成外部先清）
      for (int i = 0; i < M_TOTAL; i++)
        for (int j = 0; j < N_TOTAL; j++)
          C_full[i][j] <= '0;
    end
    else begin
      state <= state_n;

      // 大部分的 counter 在各自狀態中更新
      case (state)

        // --- 啟動整個運算 ---
        S_IDLE: begin
          if (start) begin
            tile_m_base <= 0;
            tile_n_base <= 0;
          end
        end

        // --- 決定這個 tile 的 m_eff / n_eff / k_eff ---
        S_INIT_TILE: begin
          load_row <= 0;
          load_col <= 0;
          load_k   <= 0;
          acc_row  <= 0;
          acc_col  <= 0;
        end

        // --- 載入 A tile ---
        S_LOAD_A: begin
          if (load_row < m_eff) begin
            if (load_k < K_TOTAL) begin
              A_buf[load_row][load_k] <= A_full[tile_m_base + load_row][load_k];
              load_k <= load_k + 1;
            end
            else begin
              load_k   <= 0;
              load_row <= load_row + 1;
            end
          end
        end

        // --- 載入 B tile ---
        S_LOAD_B: begin
          if (load_col < n_eff) begin
            if (load_k < K_TOTAL) begin
              B_buf[load_k][load_col] <= B_full[load_k][tile_n_base + load_col];
              load_k <= load_k + 1;
            end
            else begin
              load_k   <= 0;
              load_col <= load_col + 1;
            end
          end
        end

        // --- 將 C_tile 寫回 C_full ---
        S_ACCUM_C: begin
          if (acc_row < m_eff) begin
            if (acc_col < n_eff) begin
              // ★ 目前沒有 K-tiling，所以直接覆蓋
              //    若未來要 K 分段，改成:
              // C_full[...] <= C_full[...] + C_tile[acc_row][acc_col];
              C_full[tile_m_base + acc_row][tile_n_base + acc_col]
                  <= C_tile[acc_row][acc_col];

              acc_col <= acc_col + 1;
            end
            else begin
              acc_col <= 0;
              acc_row <= acc_row + 1;
            end
          end
        end

        // 其他 state 不需要在這裡改 counter
        default: /* do nothing */ ;
      endcase
    end
  end

  // ----------------------------------------------------------------
  // 組合邏輯：決定下一個 state + 控制 core_start, cfg_m/n/k, busy, done
  // ----------------------------------------------------------------
  always_comb begin
    state_n   = state;
    busy      = 1'b0;
    done      = 1'b0;
    core_start = 1'b0;

    // 預設 tile 大小（之後 S_INIT_TILE 會依照剩餘邊界修正 m_eff/n_eff）
    m_eff = ROWS;
    n_eff = COLS;
    k_eff = K_TOTAL;    // 現在先不對 K 做 tiling

    // clamp 邊界：最後一個 tile 可能不足 16
    if (tile_m_base + m_eff > M_TOTAL)
      m_eff = M_TOTAL - tile_m_base;
    if (tile_n_base + n_eff > N_TOTAL)
      n_eff = N_TOTAL - tile_n_base;

    // cfg_* 給 systolic core
    cfg_m = m_eff[$bits(cfg_m)-1:0];
    cfg_n = n_eff[$bits(cfg_n)-1:0];
    cfg_k = k_eff[$bits(cfg_k)-1:0];

    case (state)

      S_IDLE: begin
        if (start)
          state_n = S_INIT_TILE;
      end

      S_INIT_TILE: begin
        busy    = 1'b1;
        // 若 m_eff 或 n_eff = 0，代表已經沒有 tile，要結束
        if (m_eff <= 0 || n_eff <= 0) begin
          state_n = S_DONE_ALL;
        end
        else begin
          state_n = S_LOAD_A;
        end
      end

      S_LOAD_A: begin
        busy = 1'b1;
        if (load_row >= m_eff)
          state_n = S_LOAD_B;
      end

      S_LOAD_B: begin
        busy = 1'b1;
        if (load_col >= n_eff)
          state_n = S_START_CORE;
      end

      S_START_CORE: begin
        busy      = 1'b1;
        core_start= 1'b1;      // 打一拍給 core
        state_n   = S_WAIT_CORE;
      end

      S_WAIT_CORE: begin
        busy = 1'b1;
        if (core_done)
          state_n = S_ACCUM_C;
      end

      S_ACCUM_C: begin
        busy = 1'b1;
        if (acc_row >= m_eff)
          state_n = S_NEXT_TILE;
      end

      S_NEXT_TILE: begin
        busy = 1'b1;
        // 走完一列 tile，就換下一列
        if (tile_n_base + n_eff >= N_TOTAL) begin
          tile_n_base = 0;
          tile_m_base = tile_m_base + m_eff;

          if (tile_m_base + m_eff >= M_TOTAL)
            state_n = S_DONE_ALL;
          else
            state_n = S_INIT_TILE;
        end
        else begin
          // 同一列的下一個 tile
          tile_n_base = tile_n_base + n_eff;
          state_n     = S_INIT_TILE;
        end
      end

      S_DONE_ALL: begin
        done    = 1'b1;
        state_n = S_IDLE;
      end

      default: state_n = S_IDLE;
    endcase
  end

endmodule : gemm_tiled_controller
