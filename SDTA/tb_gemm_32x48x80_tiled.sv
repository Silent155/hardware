// tb_gemm_32x48x80_tiled.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module tb_gemm_32x48x80_tiled;

  localparam int M_TOTAL = 32;
  localparam int N_TOTAL = 48;
  localparam int K_TOTAL = 80;
  localparam int ROWS    = 16;
  localparam int COLS    = 16;
  localparam int K_MAX   = 2048;
  localparam int K_TILE  = 16;

  logic clk = 0;
  logic rst_n = 0;
  logic start;
  logic busy, done;

  // 大矩陣 buffer
  logic signed [DATA_W-1:0]  A_full [M_TOTAL][K_TOTAL];
  logic signed [DATA_W-1:0]  B_full [K_TOTAL][N_TOTAL];
  logic signed [ACC_W-1:0]   C_full [M_TOTAL][N_TOTAL];

  // golden
  int goldenC [M_TOTAL][N_TOTAL];

  // DUT = tiled controller + gemm_systolic_core
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

  // ------------------------------
  // 讀檔：A, B, C_golden
  // ------------------------------
  task automatic load_case(int id);
    int fdA, fdB, fdC;
    int val;
    int i, j, k;
    string fA, fB, fC;

    // 你可以改路徑，這裡假設檔案放在 xsim 工作目錄
    fA = $sformatf("A_%0d.txt", id);
    fB = $sformatf("B_%0d.txt", id);
    fC = $sformatf("C_golden_%0d.txt", id);

    $display("=== Load Case %0d ===", id);

    // A: M_TOTAL x K_TOTAL
    fdA = $fopen(fA, "r");
    if (!fdA) begin
      $display("ERROR: cannot open %s", fA);
      $finish;
    end

    for (i = 0; i < M_TOTAL; i++)
      for (k = 0; k < K_TOTAL; k++) begin
        if ($fscanf(fdA, "%d\n", val) != 1) begin
          $display("ERROR: read A_full failed at i=%0d, k=%0d", i, k);
          $finish;
        end
        A_full[i][k] = val;
      end
    $fclose(fdA);

    // B: K_TOTAL x N_TOTAL
    fdB = $fopen(fB, "r");
    if (!fdB) begin
      $display("ERROR: cannot open %s", fB);
      $finish;
    end

    for (k = 0; k < K_TOTAL; k++)
      for (j = 0; j < N_TOTAL; j++) begin
        if ($fscanf(fdB, "%d\n", val) != 1) begin
          $display("ERROR: read B_full failed at k=%0d, j=%0d", k, j);
          $finish;
        end
        B_full[k][j] = val;
      end
    $fclose(fdB);

    // C_golden: M_TOTAL x N_TOTAL
    fdC = $fopen(fC, "r");
    if (!fdC) begin
      $display("ERROR: cannot open %s", fC);
      $finish;
    end

    for (i = 0; i < M_TOTAL; i++)
      for (j = 0; j < N_TOTAL; j++) begin
        if ($fscanf(fdC, "%d\n", val) != 1) begin
          $display("ERROR: read C_golden failed at i=%0d, j=%0d", i, j);
          $finish;
        end
        goldenC[i][j] = val;
      end
    $fclose(fdC);
  endtask

  // ------------------------------
  // 比對結果
  // ------------------------------
  task automatic compare_case(int id);
    int i, j;
    int errors = 0;

    for (i = 0; i < M_TOTAL; i++)
      for (j = 0; j < N_TOTAL; j++) begin
        if (C_full[i][j] !== goldenC[i][j]) begin
          $display("ERR case %0d: C[%0d][%0d] = %0d expect %0d",
                   id, i, j, C_full[i][j], goldenC[i][j]);
          errors++;
        end
      end

    if (errors == 0)
      $display("=== Case %0d PASS ===", id);
    else
      $display("=== Case %0d FAIL | errors = %0d ===", id, errors);
  endtask

  // ------------------------------
  // Main
  // ------------------------------
  initial begin
    $display("==== GEMM 32x48x80 TILED TEST START ====");

    start = 0;
    #20 rst_n = 1;

    for (int id = 0; id < 5; id++) begin
      load_case(id);

      // pulse start
      @(posedge clk);
      start = 1;
      @(posedge clk);
      start = 0;

      // 等整個 tiled GEMM 完成
      wait(done == 1);
      @(posedge clk);

      compare_case(id);
    end

    $display("==== ALL DONE ====");
    $finish;
  end

endmodule
