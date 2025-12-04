`timescale 1ns/1ps
import backbone_pkg::*;

// ======================================================
// Testbench for conv1_axi_stream_top
// ======================================================
module tb_conv1_axi_stream_top;

  // --------------------------
  // Parameters
  // --------------------------
  localparam DATA_W = DATA_W;
  localparam ACC_W  = ACC_W;

  localparam CIN  = 3;
  localparam HIN  = 112;
  localparam WIN  = 112;
  localparam COUT = 64;
  localparam HOUT = 56;
  localparam WOUT = 56;

  localparam FMAP_TOT   = CIN * HIN * WIN;      // 37632
  localparam WEIGHT_TOT = COUT * CIN * 7 * 7;   // 9408
  localparam OUT_TOT    = COUT * HOUT * WOUT;   // 200704

  // --------------------------
  // DUT signals
  // --------------------------
  logic clk, rst_n;
  logic start;
  logic done;

  // AXIS fmap
  logic                      s_fmap_tvalid;
  logic                      s_fmap_tready;
  logic signed [DATA_W-1:0] s_fmap_tdata;
  logic                      s_fmap_tlast;

  // AXIS weight
  logic                      s_weight_tvalid;
  logic                      s_weight_tready;
  logic signed [DATA_W-1:0] s_weight_tdata;
  logic                      s_weight_tlast;

  // AXIS output
  logic                      m_out_tvalid;
  logic                      m_out_tready;
  logic signed [ACC_W-1:0]  m_out_tdata;
  logic                      m_out_tlast;

  // --------------------------
  // Instantiate DUT
  // --------------------------
  conv1_axi_stream_top #(
    .DATA_W_P (DATA_W),
    .ACC_W_P  (ACC_W)
  ) dut (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .start                  (start),
    .done                   (done),

    .s_axis_fmap_tvalid     (s_fmap_tvalid),
    .s_axis_fmap_tready     (s_fmap_tready),
    .s_axis_fmap_tdata      (s_fmap_tdata),
    .s_axis_fmap_tlast      (s_fmap_tlast),

    .s_axis_weight_tvalid   (s_weight_tvalid),
    .s_axis_weight_tready   (s_weight_tready),
    .s_axis_weight_tdata    (s_weight_tdata),
    .s_axis_weight_tlast    (s_weight_tlast),

    .m_axis_out_tvalid      (m_out_tvalid),
    .m_axis_out_tready      (m_out_tready),
    .m_axis_out_tdata       (m_out_tdata),
    .m_axis_out_tlast       (m_out_tlast)
  );

  // --------------------------
  // clock
  // --------------------------
  initial clk = 0;
  always #0.001 clk = ~clk;

  // --------------------------
  // test vectors (Python dump)
  // --------------------------
  integer i;
  integer fmap_file, weight_file, golden_file;

  integer scan_fmap, scan_weight, scan_out;

  int fmap_mem   [0:FMAP_TOT-1];
  int weight_mem [0:WEIGHT_TOT-1];
  int golden_out [0:OUT_TOT-1];

  int out_capture [0:OUT_TOT-1];
  int out_cnt;

  // --------------------------
  // AXIS output ready
  // --------------------------
  initial m_out_tready = 1;

  // --------------------------
  // Task: send fmap stream
  // --------------------------
  task send_fmap;
    begin
      $display("=== SENDING FMAP (%0d words) ===", FMAP_TOT);

      s_fmap_tvalid = 1'b0;
      s_fmap_tdata  = '0;
      s_fmap_tlast  = 1'b0;

      @(posedge clk);

      for (i = 0; i < FMAP_TOT; i++) begin
        @(posedge clk);

        s_fmap_tdata  = fmap_mem[i];
        s_fmap_tvalid = 1'b1;
        s_fmap_tlast  = (i == FMAP_TOT-1);

        // å¿…é?ˆç?? ready
        while (!s_fmap_tready) @(posedge clk);
      end

      @(posedge clk);
      s_fmap_tvalid = 1'b0;
      s_fmap_tlast  = 1'b0;
    end
  endtask

  // --------------------------
  // Task: send weight stream
  // --------------------------
  task send_weight;
    begin
      $display("=== SENDING WEIGHT (%0d words) ===", WEIGHT_TOT);

      s_weight_tvalid = 1'b0;
      s_weight_tdata  = '0;
      s_weight_tlast  = 1'b0;

      @(posedge clk);

      for (i = 0; i < WEIGHT_TOT; i++) begin
        @(posedge clk);

        s_weight_tdata  = weight_mem[i];
        s_weight_tvalid = 1'b1;
        s_weight_tlast  = (i == WEIGHT_TOT-1);

        while (!s_weight_tready) @(posedge clk);
      end

      @(posedge clk);
      s_weight_tvalid = 1'b0;
      s_weight_tlast  = 1'b0;
    end
  endtask

  // --------------------------
  // Capture output stream
  // --------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      out_cnt = 0;
    end else begin
      if (m_out_tvalid && m_out_tready) begin
        out_capture[out_cnt] = m_out_tdata;
        out_cnt++;
      end
    end
  end

  // --------------------------
  // Main TB
  // --------------------------
  int err;
  initial begin
    rst_n = 0;
    start = 0;

    s_fmap_tvalid   = 0;
    s_weight_tvalid = 0;

    // load test data
    $readmemh("fmap_hex.txt",   fmap_mem);
    $readmemh("weight_hex.txt", weight_mem);
    $readmemh("golden_hex.txt", golden_out);

    #100;
    rst_n = 1;

    #50;
    start = 1;
    #10;
    start = 0;

    // ?? fmap
    send_fmap;

    // ?? weight
    send_weight;

    // ç­? done
    $display("=== WAITING conv1 DONE ===");
    wait(done);

    $display("=== DONE, NOW CHECK OUTPUT ===");
    #20;

    // Compare
    err = 0;
    for (i = 0; i < OUT_TOT; i++) begin
      if (out_capture[i] !== golden_out[i]) begin
        $display("ERR @%0d: DUT=%0d expect=%0d",
          i, out_capture[i], golden_out[i]);
        err++;
      end
    end

    if (err == 0)
      $display("==== CONV1 AXI STREAM PASS ====");
    else
      $display("==== CONV1 AXI STREAM FAIL | err=%0d ====", err);

    $stop;
  end

endmodule
