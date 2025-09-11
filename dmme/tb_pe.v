`timescale 1ns/10ps

module tb_pe;

    // Inputs
    reg clock;
    reg en;
    reg [3:0] maskin;
    reg [63:0] ain;
    reg [31:0] bin;
    reg [31:0] cin;
    reg [1:0] mode;

    // Outputs
    wire [3:0] maskOut;
    wire [63:0] aOut;
    wire [31:0] bOut;
    wire [31:0] cOut;

    // Instantiate the Unit Under Test (UUT)
    pe uut (
        .clock(clock),
        .en(en),
        .maskin(maskin),
        .ain(ain),
        .bin(bin),
        .cin(cin),
        .mode(mode),
        .maskOut(maskOut),
        .aOut(aOut),
        .bOut(bOut),
        .cOut(cOut)
    );

    // Clock generation
    initial begin
        clock = 1;
        forever #5 clock = ~clock; // 10ns clock period
    end

    // Test stimulus
    initial begin
        // Initialize Inputs
        en = 0;
        maskin = 4'b0000;
        ain = 64'h0000000000000000;
        bin = 32'h00000000;
        cin = 32'h00000000;
        mode = 2'b00;

        // Wait for global reset
        #10;

        // Test case 1: Enable = 1, Mode = DENDEN
        en = 1;
        maskin = 4'b0101;
        ain = 64'h123456789;
        bin = 32'h11110000;
        cin = 32'h00009999;
        mode = 2'b00; // DENDEN mode
        #10;

        ain = 64'h987654321;
        bin = 32'h00001111;

        #10;
        // Test case 2: Mode = SPADEN
        mode = 2'b11; // SPADEN mode
        #10;
        //watch cout=cin
        #10;
        en = 0;
        maskin = 4'b0000;
        ain = 64'h0000000000000000;
        bin = 32'h00000000;
        cin = 32'h00000000;
        mode = 2'b00;




        #10;//clock50
        en=1'b1;

        // Test case 3: Mode = SHIFT
        mode = 2'b00; // SHIFT mode
        ain = 64'h8888777755;
        bin = 32'h07654321;
    
        #10;
        ain = 64'h111111112222;
        bin = 32'h02324545;
        // Test case 4: Mode = WAIT
        #10;
        mode = 2'b11; // WAIT mode
        #10;
        //clock80 watch result

        #5;
        // Test case 5: Disable enable signal
        en = 0;
        maskin = 4'b0000;
        ain = 64'h0000000000000000;
        bin = 32'h00000000;
        cin = 32'h00000000;
        mode = 2'b00;
        #10;

        // Test case 6: Random inputs with Enable = 1
        en = 1;
        maskin = 4'b1010;
        ain = 64'h05A5A5A5A5A5A5A5;
        bin = 32'h0A5A5A5A;
        cin = 32'h02345678;
        mode = 2'b01; // SPADEN mode
        #10;
        mode = 2'b11;
        #10
        //clock110 watch result
        // Finish simulation
        #100;
        $finish;
    end

    // Monitor output values
    initial begin
        $monitor("Time = %0t | en = %b | mode = %b | maskOut = %b | aOut = %h | bOut = %h | cOut = %h", 
                 $time, en, mode, maskOut, aOut, bOut, cOut);
    end

endmodule
