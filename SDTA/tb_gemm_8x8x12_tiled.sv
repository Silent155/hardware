// tb_gemm_8x8x12_tiled.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module tb_gemm_8x8x12_tiled;

  // -----------------------------
  // 測試矩陣尺寸
  // -----------------------------
  localparam int M_TOTAL = 8;
  localparam int N_TOTAL = 8;
  localparam int K_TOTAL = 12;

  localparam int ROWS    = 4;   // systolic array rows
  localparam int COLS    = 4;   // systolic array cols
  localparam int K_MAX   = 16;  // 必須 >= K_TILE
  localparam int K_TILE  = 4;   // 12 = 4 * 3 tiles

  logic clk   = 0;
  logic rst_n = 0;
  logic start;
  logic busy, done;

  // A, B, C buffers
  logic signed [DATA_W-1:0]  A_full [M_TOTAL][K_TOTAL];
  logic signed [DATA_W-1:0]  B_full [K_TOTAL][N_TOTAL];
  logic signed [ACC_W-1:0]   C_full [M_TOTAL][N_TOTAL];

  // golden
  int goldenC [M_TOTAL][N_TOTAL];

  // -----------------------------
  // DUT: 3D-tiled GEMM controller
  // -----------------------------
  gemm_tiled_controller_3d #(
    .ROWS     (ROWS),
    .COLS     (COLS),
    .M_TOTAL  (M_TOTAL),
    .N_TOTAL  (N_TOTAL),
    .K_TOTAL  (K_TOTAL),
    .K_MAX    (K_MAX),
    .K_TILE   (K_TILE)
  ) dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .start  (start),
    .busy   (busy),
    .done   (done),
    .A_full (A_full),
    .B_full (B_full),
    .C_full (C_full)
  );

  // clock
  always #5 clk = ~clk;

  // -----------------------------
  // Load A, B, C_golden for case cid
  // -----------------------------
  task automatic load_case(int cid);
    int fdA, fdB, fdC;
    int val;
    int i, j, k;
    string fA, fB, fC;

    fA = $sformatf("A_%0d.txt", cid);
    fB = $sformatf("B_%0d.txt", cid);
    fC = $sformatf("C_golden_%0d.txt", cid);

    $display("=== Load Case %0d ===", cid);

    // ---------- A: 8 x 12 ----------
    fdA = $fopen(fA, "r");
    if (!fdA) begin
      $display("ERROR: cannot open %s", fA);
      $finish;
    end

    for (i = 0; i < M_TOTAL; i++) begin
      for (k = 0; k < K_TOTAL; k++) begin
        if ($fscanf(fdA, "%d\n", val) != 1) begin
          $display("ERROR: read A_full failed at i=%0d, k=%0d", i, k);
          $finish;
        end
        A_full[i][k] = val;
      end
    end
    $fclose(fdA);

    // ---------- B: 12 x 8 ----------
    fdB = $fopen(fB, "r");
    if (!fdB) begin
      $display("ERROR: cannot open %s", fB);
      $finish;
    end

    for (k = 0; k < K_TOTAL; k++) begin
      for (j = 0; j < N_TOTAL; j++) begin
        if ($fscanf(fdB, "%d\n", val) != 1) begin
          $display("ERROR: read B_full failed at k=%0d, j=%0d", k, j);
          $finish;
        end
        B_full[k][j] = val;
      end
    end
    $fclose(fdB);

    // ---------- C_golden: 8 x 8 ----------
    fdC = $fopen(fC, "r");
    if (!fdC) begin
      $display("ERROR: cannot open %s", fC);
      $finish;
    end

    for (i = 0; i < M_TOTAL; i++) begin
      for (j = 0; j < N_TOTAL; j++) begin
        if ($fscanf(fdC, "%d\n", val) != 1) begin
          $display("ERROR: read C_golden failed at i=%0d, j=%0d", i, j);
          $finish;
        end
        goldenC[i][j] = val;
      end
    end
    $fclose(fdC);
  endtask


  // -----------------------------
  // Compare
  // -----------------------------
  task automatic compare_case(int cid);
    int i, j;
    int errors = 0;

    for (i = 0; i < M_TOTAL; i++) begin
      for (j = 0; j < N_TOTAL; j++) begin
        if (C_full[i][j] !== goldenC[i][j]) begin
          $display("ERR case %0d: C[%0d][%0d] = %0d expect %0d",
                   cid, i, j, C_full[i][j], goldenC[i][j]);
          errors++;
        end
      end
    end

    if (errors == 0)
      $display("=== Case %0d PASS ===", cid);
    else
      $display("=== Case %0d FAIL | errors = %0d ===", cid, errors);
  endtask


  // -----------------------------
  // Main
  // -----------------------------
  initial begin
    $display("==== GEMM 8x8x12 TILED TEST START ====");
    start = 0;
    #20 rst_n = 1;

    for (int cid = 0; cid < 5; cid++) begin
      load_case(cid);

      @(posedge clk);
      start = 1;
      @(posedge clk);
      start = 0;

      // 等這一筆 GEMM 完成
      wait(done == 1);
      @(posedge clk);

      compare_case(cid);
    end

    $display("==== ALL CASES DONE ====");
    $finish;
  end

endmodule
