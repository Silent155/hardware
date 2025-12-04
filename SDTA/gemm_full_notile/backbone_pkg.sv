// backbone_pkg.sv
package backbone_pkg;

  parameter int DATA_W    = 16;
  parameter int ACC_W     = 32;
  parameter int FRAC_BITS = 14;   // Q2.14 example

  typedef logic signed [DATA_W-1:0] data_t;
  typedef logic signed [ACC_W-1:0]  acc_t;

  function automatic data_t sat16(acc_t x);
    acc_t maxv =  16'sh7FFF;
    acc_t minv = -16'sh8000;
    if (x > maxv)       return data_t'(maxv[DATA_W-1:0]);
    else if (x < minv)  return data_t'(minv[DATA_W-1:0]);
    else                return data_t'(x[DATA_W-1:0]);
  endfunction

endpackage : backbone_pkg
