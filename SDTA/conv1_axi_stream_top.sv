// conv1_axi_stream_top.sv
`timescale 1ns/1ps
import backbone_pkg::*;

module conv1_axi_stream_top #(
  parameter int DATA_W_P = DATA_W,
  parameter int ACC_W_P  = ACC_W
)(
  input  logic                         clk,
  input  logic                         rst_n,

  // Â§ñÈÉ®??üÂ??/ÂÆåÊ?êÊ?óÊ?ôÔ?àÂèØ?é• AXI-Lite Ë®ªÂ?äÊ?? GPIOÔº?
  input  logic                         start,
  output logic                         done,

  // AXI-Stream: fmap in
  input  logic                         s_axis_fmap_tvalid,
  output logic                         s_axis_fmap_tready,
  input  logic signed [DATA_W_P-1:0]   s_axis_fmap_tdata,
  input  logic                         s_axis_fmap_tlast,   // optional (debug)

  // AXI-Stream: weight in
  input  logic                         s_axis_weight_tvalid,
  output logic                         s_axis_weight_tready,
  input  logic signed [DATA_W_P-1:0]   s_axis_weight_tdata,
  input  logic                         s_axis_weight_tlast, // optional (debug)

  // AXI-Stream: output out
  output logic                         m_axis_out_tvalid,
  input  logic                         m_axis_out_tready,
  output logic signed [ACC_W_P-1:0]    m_axis_out_tdata,
  output logic                         m_axis_out_tlast
);

  // ----------------------------
  // conv1 ?õ∫ÂÆöÂ?ÉÊï∏
  // ----------------------------
  localparam int CIN    = 3;
  localparam int H_IN   = 112;
  localparam int W_IN   = 112;
  localparam int COUT   = 64;
  localparam int KH     = 7;
  localparam int KW     = 7;
  localparam int H_OUT  = 56;
  localparam int W_OUT  = 56;

  localparam int FMAP_TOTAL   = CIN  * H_IN  * W_IN;   //  3*112*112 =  37632
  localparam int WEIGHT_TOTAL = COUT * CIN  * KH * KW; // 64*3*7*7  =   9408
  localparam int OUT_TOTAL    = COUT * H_OUT * W_OUT;  // 64*56*56  = 200704

  // ----------------------------
  // ?Öß?É® buffer: fmap / weight / out
  // ----------------------------
  logic signed [DATA_W_P-1:0] fmap_buf   [CIN][H_IN][W_IN];
  logic signed [DATA_W_P-1:0] weight_buf [COUT][CIN][KH][KW];
  logic signed [ACC_W_P-1:0]  out_buf    [COUT][H_OUT][W_OUT];

  // ?Öß?É® conv1_top ‰ªãÈù¢
  logic                          conv_start;
  logic                          conv_done;

  // ----------------------------
  // ÂØ¶‰?ãÂ?ñ‰?†Â?üÊú¨??? conv1_gemm_top
  // ÔºàÂ?áË®≠‰Ω†‰?ùÁ?ô‰?ÜÈ?ôÂ?ã‰?ãÈù¢Ôºöfmap_i / weight_i / out_oÔº?
  // ----------------------------
  conv1_gemm_top #(
    .DATA_W_P (DATA_W_P),
    .ACC_W_P  (ACC_W_P)
  ) u_conv1 (
    .clk      (clk),
    .rst_n    (rst_n),
    .start    (conv_start),
    .done     (conv_done),
    .fmap_i   (fmap_buf),
    .weight_i (weight_buf),
    .out_o    (out_buf)
  );

  // ----------------------------
  // Â§ñÂ±§ AXIS ?éß?à∂ FSM
  // ----------------------------
  typedef enum logic [2:0] {
    W_IDLE,
    W_LOAD_FMAP,
    W_LOAD_WEIGHT,
    W_START_CONV,
    W_WAIT_CONV,
    W_DUMP,
    W_DONE
  } w_state_t;

  w_state_t state, state_n;

  int fmap_cnt,   fmap_cnt_n;
  int weight_cnt, weight_cnt_n;
  int out_cnt,    out_cnt_n;

  // done flag
  logic done_r;
  assign done = done_r;

  // ----------------------------
  // Sequential
  // ----------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state       <= W_IDLE;
      fmap_cnt    <= 0;
      weight_cnt  <= 0;
      out_cnt     <= 0;
      done_r      <= 1'b0;
    end
    else begin
      state       <= state_n;
      fmap_cnt    <= fmap_cnt_n;
      weight_cnt  <= weight_cnt_n;
      out_cnt     <= out_cnt_n;

      if (state == W_DONE)
        done_r <= 1'b1;
      else if (state == W_IDLE && start)
        done_r <= 1'b0;
    end
  end
 int c, h, w;
    int co, ci, kh, kw;
    int oh, ow;

  // ----------------------------
  // Combinational
  // ----------------------------
  // AXIS ??êË®≠??
  // fmap
  // weight
  // out
  // conv_start pulse
  always_comb begin
    state_n        = state;
    fmap_cnt_n     = fmap_cnt;
    weight_cnt_n   = weight_cnt;
    out_cnt_n      = out_cnt;

    s_axis_fmap_tready   = 1'b0;
    s_axis_weight_tready = 1'b0;

    m_axis_out_tvalid    = 1'b0;
    m_axis_out_tdata     = '0;
    m_axis_out_tlast     = 1'b0;

    conv_start           = 1'b0;

    // for index decoding
   
    case (state)

      //--------------------------------
      // Á≠? start
      //--------------------------------
      W_IDLE: begin
        if (start) begin
          fmap_cnt_n   = 0;
          weight_cnt_n = 0;
          out_cnt_n    = 0;
          state_n      = W_LOAD_FMAP;
        end
      end

      //--------------------------------
      // ËÆ? fmapÔº?3x112x112
      //--------------------------------
      W_LOAD_FMAP: begin
        s_axis_fmap_tready = 1'b1;

        if (s_axis_fmap_tvalid && s_axis_fmap_tready) begin
          // ??†Â?? fmap_cnt -> (c,h,w)
          int tmp1, tmp2;
          tmp1 = fmap_cnt; // 0..FMAP_TOTAL-1
          c    = tmp1 / (H_IN * W_IN);      // 0..2
          tmp2 = tmp1 % (H_IN * W_IN);      // 0..(112*112-1)
          h    = tmp2 / W_IN;               // 0..111
          w    = tmp2 % W_IN;               // 0..111

          if (c < CIN && h < H_IN && w < W_IN)
            fmap_buf[c][h][w] = s_axis_fmap_tdata;

          fmap_cnt_n = fmap_cnt + 1;

          if (fmap_cnt_n >= FMAP_TOTAL) begin
            state_n = W_LOAD_WEIGHT;
          end
        end
      end

      //--------------------------------
      // ËÆ? weightÔº?64x3x7x7
      //--------------------------------
      W_LOAD_WEIGHT: begin
        s_axis_weight_tready = 1'b1;

        if (s_axis_weight_tvalid && s_axis_weight_tready) begin
          int tmp1, tmp2;
          tmp1 = weight_cnt; // 0..WEIGHT_TOTAL-1

          co   = tmp1 / (CIN * KH * KW);         // 0..63
          tmp2 = tmp1 % (CIN * KH * KW);
          ci   = tmp2 / (KH * KW);               // 0..2
          tmp1 = tmp2 % (KH * KW);
          kh   = tmp1 / KW;                      // 0..6
          kw   = tmp1 % KW;                      // 0..6

          if (co < COUT && ci < CIN && kh < KH && kw < KW)
            weight_buf[co][ci][kh][kw] = s_axis_weight_tdata;

          weight_cnt_n = weight_cnt + 1;

          if (weight_cnt_n >= WEIGHT_TOTAL) begin
            state_n = W_START_CONV;
          end
        end
      end

      //--------------------------------
      // Áµ? conv1_gemm_top ‰∏???? start pulse
      //--------------------------------
      W_START_CONV: begin
        conv_start = 1'b1;
        state_n    = W_WAIT_CONV;
      end

      //--------------------------------
      // Á≠? conv ÂÆåÊ??
      //--------------------------------
      W_WAIT_CONV: begin
        if (conv_done) begin
          out_cnt_n = 0;
          state_n   = W_DUMP;
        end
      end

      //--------------------------------
      // ??? out_buf ËΩâÊ?? AXIS stream ??êÂá∫?éª
      //--------------------------------
      W_DUMP: begin
        // ?õÆ??çÁ?ñÁï•Ôºöout_cnt 0..OUT_TOTAL-1
        // mapping: out_cnt -> (co, oh, ow)
        int tmp;
        tmp = out_cnt;
        co  = tmp / (H_OUT * W_OUT);          // 0..63
        tmp = tmp % (H_OUT * W_OUT);
        oh  = tmp / W_OUT;                    // 0..55
        ow  = tmp % W_OUT;                    // 0..55

        if (co < COUT && oh < H_OUT && ow < W_OUT) begin
          m_axis_out_tvalid = 1'b1;
          m_axis_out_tdata  = out_buf[co][oh][ow];
          m_axis_out_tlast  = (out_cnt == OUT_TOTAL-1);

          if (m_axis_out_tvalid && m_axis_out_tready) begin
            out_cnt_n = out_cnt + 1;
            if (out_cnt_n >= OUT_TOTAL) begin
              state_n = W_DONE;
            end
          end
        end
        else begin
          // index Ê∫¢‰?çÂ∞±?õ¥?é• DONEÔºàÁ?ÜË?ñ‰?ä‰?çÊ?âÁôº??üÔ??
          state_n = W_DONE;
        end
      end

      //--------------------------------
      // DONEÔºö‰?ùÊ?? done=1ÔºåÁ?âÂ?ñÈÉ® reset ??ñ‰?ã‰?Ê¨? start
      //--------------------------------
      W_DONE: begin
        // ‰∏ç‰∏ª??ïÂ?ûÂà∞ IDLEÔºå‰∫§Áµ¶Â?ñÈù¢ reset ??ñÈ?çÊñ∞??? start
      end

      default: state_n = W_IDLE;
    endcase
  end

endmodule : conv1_axi_stream_top
