`timescale 1ns/1ps
import backbone_pkg::*;

module tb_gemm16x16;

  localparam int ROWS = 16;
  localparam int COLS = 16;
  localparam int K    = 64;
  localparam int K_MAX = 2048;

  logic clk = 0, rst_n = 0;
  logic start;
  logic busy, done;

  // buffers
  logic signed [DATA_W-1:0]  A_buf [ROWS][K_MAX];
  logic signed [DATA_W-1:0]  B_buf [K_MAX][COLS];
  logic signed [ACC_W-1:0]   C_buf [ROWS][COLS];

  // Golden buffer
  int goldenC [ROWS][COLS];

  // Instantiate DUT
  gemm_systolic_core #(
    .ROWS (ROWS),
    .COLS (COLS),
    .K_MAX(K_MAX)
  ) dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .start   (start),
    .cfg_m   (ROWS),
    .cfg_n   (COLS),
    .cfg_k   (K),
    .busy    (busy),
    .done    (done),
    .A_buf   (A_buf),
    .B_buf   (B_buf),
    .C_buf   (C_buf)
  );

  always #5 clk = ~clk;

  // ------------------------------
  // Load A,B,C golden
  // ------------------------------
  task automatic load_case(int id);
    int fdA, fdB, fdC;
    int val;
    int i, j, k;
    string fA, fB, fC;

    fA = $sformatf("C:/Users/User/project_9/project_9.sim/sim_1/behav/xsim/A_%0d.txt", id);
    fB = $sformatf("C:/Users/User/project_9/project_9.sim/sim_1/behav/xsim/B_%0d.txt", id);
    fC = $sformatf("C:/Users/User/project_9/project_9.sim/sim_1/behav/xsim/C_golden_%0d.txt", id);


    $display("=== Load Case %0d ===", id);

    // Load A
    fdA = $fopen(fA, "r");
    if (!fdA) begin
      $display("ERROR: cannot open %s", fA);
      $finish;
    end

    for (i=0;i<ROWS;i++)
      for (k=0;k<K;k++) begin
        $fscanf(fdA, "%d\n", val);
        A_buf[i][k] = val;
      end
    $fclose(fdA);

    // Load B
    fdB = $fopen(fB, "r");
    if (!fdB) begin
      $display("ERROR: cannot open %s", fB);
      $finish;
    end

    for (k=0;k<K;k++)
      for (j=0;j<COLS;j++) begin
        $fscanf(fdB, "%d\n", val);
        B_buf[k][j] = val;
      end
    $fclose(fdB);

    // Load golden C
    fdC = $fopen(fC, "r");
    if (!fdC) begin
      $display("ERROR: cannot open %s", fC);
      $finish;
    end

    for (i=0;i<ROWS;i++)
      for (j=0;j<COLS;j++) begin
        $fscanf(fdC, "%d\n", val);
        goldenC[i][j] = val;
      end
    $fclose(fdC);
  endtask


  // ------------------------------
  // Compare C result
  // ------------------------------
  
  task automatic compare_case(int id);
    int i, j;
    int errors = 0;

    for (i=0;i<ROWS;i++)
      for (j=0;j<COLS;j++) begin
        if (C_buf[i][j] !== goldenC[i][j]) begin
          $display("ERR case %0d: C[%0d][%0d] = %0d expect %0d",
              id, i, j, C_buf[i][j], goldenC[i][j]);
          errors++;
        end
      end

    if (errors == 0)
      $display("=== Case %0d PASS ===", id);
    else
      $display("=== Case %0d FAIL | errors = %0d ===", id, errors);
  endtask


  // ------------------------------
  // Main test
  // ------------------------------
  initial begin
    $display("==== GEMM 16x16 TEST START ====");

    #20 rst_n = 1;

    for (int id=0; id<5; id++) begin
      load_case(id);

      start = 1;
      @(posedge clk);
      start = 0;

      wait(done);
      @(posedge clk);

      compare_case(id);
    end

    $display("==== ALL DONE ====");
    $finish;
  end

endmodule
