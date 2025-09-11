`timescale 1ns/10ps

module dmme_nonmem_tb;

    // Inputs
    reg clk;
    reg en;
    reg rst;
    reg [3:0] maskin;
    reg [63:0] ain1;
    reg [63:0] ain2;
    wire done;
    reg [63:0] bin1;
    reg [63:0] bin2;
    reg mode;

    // Outputs
    
    reg [3:0]maskin11_1;
    reg [3:0]maskin21_1;
    reg [3:0]maskin11_2;
    reg [3:0]maskin21_2;

    wire [31:0]cout_22_1;
    wire [31:0]cout_22_2;
    wire [31:0]cout_12_2;
    wire [31:0]cout_12_1;
    // Instantiate the Unit Under Test (UUT)
    dmme_nonmem uut(
    .clk(clk),
    .en(en),
    .rst(rst),
    .mode(mode),
    .ain1(ain1),
    .ain2(ain2),
    .bin1(bin1),
    .bin2(bin2),
    .maskin11_1(maskin11_1),
    .maskin21_1(maskin21_1),
    .maskin11_2(maskin11_2),
    .maskin21_2(maskin21_2),
    .done(done),
    .cout_22_1_final(cout_22_1),
    .cout_22_2_final(cout_22_2),
    .cout_12_2_final(cout_12_2),
    .cout_12_1_final(cout_12_1)
);

    // Clock generation
    initial begin
        clk = 1;
        forever #5 clk = ~clk; // 10ns clk period
    end

    // Test stimulus
    initial begin
        // Initialize Inputs
        en = 0;
        rst= 1;
        maskin11_1 = 4'b0000;
        maskin21_1 = 4'b0000;
        maskin11_2 = 4'b0000;
        maskin21_2 = 4'b0000;
        ain1 = 64'h0000000000000000;
        bin1 = 64'h00000000;
        ain2 = 64'h0000000000000000;
        bin2 = 64'h00000000;
        mode = 1'b0;

        // Wait for global reset
        #10;

        // Test case 1: Enable = 1, Mode = DENDEN
        en = 1;
        mode = 1'b0; // DENDEN mode
        maskin11_1 = 4'b0101;
        maskin11_2 = 4'b0101;
        maskin21_1 = 4'b0101;
        maskin21_2 = 4'b0101;
        #10;
        ain1 = 64'h2345678923456789;
        bin1 = 64'h1111000011110000;
        #10;
        ain1 = 64'h1111000011110000;
        bin1 = 64'h2345678923456789;
        ain2 = 64'h8765432187654321;
        bin2 = 64'h0000111100001111;
        #10;
        ain1 = 64'h0000000000000000;
        bin1 = 64'h0000000000000000;
        ain2 = 64'h0000111100001111;
        bin2 = 64'h8765432187654321;
        #10;
        ain2 = 64'h0000000000000000;
        bin2 = 64'h0000000000000000;
       
        #30;

        

        
        // Test case 2: Mode = SPADEN
        rst=1'b0;
        en=1'b0;
        ain1 = 64'h0000000000000000;
        bin1 = 64'h00000000;
        ain2 = 64'h0000000000000000;
        bin2 = 64'h00000000;
        #11;
        rst=1'b1;
        
        en=1'b1;
        mode = 1'b1; // DENDEN mode
        maskin11_1 = 4'b0101;
        maskin11_2 = 4'b0101;
        maskin21_1 = 4'b0101;
        maskin21_2 = 4'b0101;
        #9;
        ain1 = 64'h2345678923456789;
        bin1 = 64'h1111000011110000;
        #10;
        ain1 = 64'h0000000000000000;
        bin1 = 64'h0000000000000000;
        ain2 = 64'h8765432187654321;
        bin2 = 64'h0000111100001111;
        #10;
        ain1 = 64'h0000000000000000;
        bin1 = 64'h0000000000000000;
        ain2 = 64'h0000000000000000;
        bin2 = 64'h0000000000000000;
        #10;
        ain2 = 64'h0000000000000000;
        bin2 = 64'h0000000000000000;
        #60;
        //watch cout=cin
        
        en = 0;
        maskin11_1 = 4'b0000;
        maskin21_1 = 4'b0000;
        maskin11_2 = 4'b0000;
        maskin21_2 = 4'b0000;
        ain1 = 64'h0000000000000000;
        bin1 = 64'h00000000;
        ain2 = 64'h0000000000000000;
        bin2 = 64'h00000000;
        mode = 1'b0;



        #10;//clock50
        en=1'b1;

        // Test case 3: Mode = SHIFT
        mode = 1'b0; // SHIFT mode
         #10;
               ain1 = 64'h2345678923456789;
               bin1 = 64'h1111000011110000;
               #10;
               ain1 = 64'h1111000011110000;
               bin1 = 64'h2345678923456789;
               ain2 = 64'h8765432187654321;
               bin2 = 64'h0000111100001111;
               #10;
               ain1 = 64'h0000000000000000;
               bin1 = 64'h0000000000000000;
               ain2 = 64'h0000111100001111;
               bin2 = 64'h8765432187654321;
               #10;
               ain2 = 64'h0000000000000000;
               bin2 = 64'h0000000000000000;
        // Test case 4: Mode = WAIT
        #60;
        mode = 1'b1; // WAIT mode
        #60;
        //clock80 watch result

        
        // Test case 5: Disable enable signal
        en = 0;
        maskin11_1 = 4'b0000;
        maskin21_1 = 4'b0000;
        maskin11_2 = 4'b0000;
        maskin21_2 = 4'b0000;
        ain1 = 64'h0000000000000000;
        bin1 = 64'h00000000;
        ain2 = 64'h0000000000000000;
        bin2 = 64'h00000000;
        mode = 1'b0;

        // Test case 6: Random inputs with Enable = 1
        
        //clock110 watch result
        // Finish simulation
        #10;
        $finish;
    end

    // Monitor .
    initial begin
        $monitor("Time = %0t | en = %b | mode = %b | cout_12_1 = %b | cout_22_1 = %h | cout_12_2 = %h | cout_22_2 = %h", 
                 $time, en, mode, cout_12_1, cout_22_1, cout_12_2, cout_22_2);
    end

endmodule

