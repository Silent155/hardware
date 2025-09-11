module mac (
    input signed [15:0]bin0,
    input signed [15:0]bin1,
    input signed [15:0]ain0,
    input signed [15:0]ain1,
    input signed [31:0]cSumin,
    output signed [31:0]cSumout
);
    wire signed [31:0]mult1;
    wire signed [31:0]mult2;
    
    wire signed [31:0]add1;
  

    assign mult1 = ain0*bin0;
    assign mult2 = ain1*bin1;

    assign add1 = mult1+mult2;
    assign cSumout = add1+cSumin;
    
    
endmodule