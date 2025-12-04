// backbone_pkg.sv
package backbone_pkg;

  // ---- Fixed-point format ----
  parameter int DATA_W = 16;
  parameter int ACC_W  = 32;

  typedef logic signed [DATA_W-1:0] data_t;
  typedef logic signed [ACC_W-1:0]  acc_t;

  // Saturate helper (目前沒用到，可以保留)
  function automatic data_t sat16(acc_t x);
    acc_t maxv =  16'sh7FFF;
    acc_t minv = -16'sh8000;
    if (x > maxv) return maxv[DATA_W-1:0];
    else if (x < minv) return minv[DATA_W-1:0];
    else return data_t'(x[DATA_W-1:0]);
  endfunction

  // ReLU（目前沒用到，可以保留）
  function automatic data_t relu(data_t x);
    if (x[DATA_W-1] == 1'b1) return '0;
    else return x;
  endfunction

endpackage : backbone_pkg
