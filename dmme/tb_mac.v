`timescale 1ns/10ps

module tb_mac;

    // Inputs
    reg [15:0] bin0;
    reg [15:0] bin1;
    reg [15:0] ain0;
    reg [15:0] ain1;
    reg [31:0] cSumin;

    // Outputs
    wire [31:0] cSumout;

    // Instantiate the Unit Under Test (UUT)
    mac uut (
        .bin0(bin0),
        .bin1(bin1),
        .ain0(ain0),
        .ain1(ain1),
        .cSumin(cSumin),
        .cSumout(cSumout)
    );

    // Test stimulus
    initial begin
        // Initialize Inputs
        bin0 = 16'h0000;
        bin1 = 16'h0000;
        ain0 = 16'h0000;
        ain1 = 16'h0000;
        cSumin = 32'h00000000;

        // Wait for global reset
        #20;

        // Test case 1: All inputs are zero
        #10;
        $display("Time = %0t | bin0 = %h | bin1 = %h | ain0 = %h | ain1 = %h | cSumin = %h | cSumout = %h", 
                 $time, bin0, bin1, ain0, ain1, cSumin, cSumout);

        // Test case 2: Multiply ain0 and bin0, ain1 and bin1, add them and then add cSumin
        ain0 = 16'd0003;
        ain1 = 16'd0004;
        bin0 = 16'd0005;
        bin1 = 16'd0006;
        cSumin = 32'd00000010;
        #10;
        $display("Time = %0t | bin0 = %d | bin1 = %d | ain0 = %d | ain1 = %d | cSumin = %d | cSumout = %d", 
                 $time, bin0, bin1, ain0, ain1, cSumin, cSumout);

        // Test case 3: Random values for inputs
        ain0 = 16'd1234;
        ain1 = 16'd5678;
        bin0 = 16'd9123;
        bin1 = 16'd4567;
        cSumin = 32'd1234567;
        #10;
        $display("Time = %0t | bin0 = %d | bin1 = %d | ain0 = %d | ain1 = %d | cSumin = %d | cSumout = %d", 
                 $time, bin0, bin1, ain0, ain1, cSumin, cSumout);

        // Finish simulation
        #100;
        $finish;
    end

endmodule
