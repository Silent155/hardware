// conv1_C_accum_bram.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module conv1_C_accum_bram #(
  parameter int M_TOTAL = 56*56,
  parameter int N_TOTAL = 64,
  parameter int ACC_W_P = ACC_W
)(
  input  logic                        clk,
  input  logic                        rst_n,

  // 全清  (controller 在 S_CLEAR_C 可以打一拍)
  input  logic                        clear_all,

  // 單埠 read
  input  logic                        rd_en,
  input  int                          rd_addr,
  output logic signed [ACC_W_P-1:0]   rd_data,
  output logic                        rd_valid,

  // 單埠 write
  input  logic                        wr_en,
  input  int                          wr_addr,
  input  logic signed [ACC_W_P-1:0]   wr_data
);

  localparam int DEPTH = M_TOTAL * N_TOTAL;

  logic signed [ACC_W_P-1:0] mem [0:DEPTH-1];

  // 簡單一拍 latency read, write-first 不特別處理（反正不會同時對同一位址 R/W）
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_valid <= 1'b0;
      rd_data  <= '0;
      for (int i = 0; i < DEPTH; i++)
        mem[i] <= '0;
    end
    else begin
      // clear_all：模擬/綜合都可，BRAM 會被推成 reset/clear 邏輯
      if (clear_all) begin
        for (int i = 0; i < DEPTH; i++)
          mem[i] <= '0;
      end
      else begin
        if (wr_en)
          mem[wr_addr] <= wr_data;
      end

      rd_valid <= rd_en;
      if (rd_en)
        rd_data <= mem[rd_addr];
    end
  end

endmodule : conv1_C_accum_bram
