`timescale 1ns/10ps

module dmme_reg(
    input clk,
    input en,
    input rst,
    input mode,
    input [63:0]ain1,
    input [63:0]ain2,
    input [63:0]bin1,
    input [63:0]bin2,
    input [3:0]maskin,
    output reg valid_12_out,
    output reg valid_22_out,
    output reg done,

    output [31:0]cout_22_1_final,
    output [31:0]cout_22_2_final,
    output [31:0]cout_12_2_final,
    output [31:0]cout_12_1_final
);

    // Inputs
  
    
    reg [63:0] ain1_reg;
    reg [63:0] ain2_reg;
    
    reg [63:0] bin1_reg;
    reg [63:0] bin2_reg;
    reg mode_reg;

    // Outputs
    
    reg [3:0]maskin11_1;
    reg [3:0]maskin21_1;
    reg [3:0]maskin11_2;
    reg [3:0]maskin21_2;

    wire [31:0]cout_22_1;
    wire [31:0]cout_22_2;
    wire [31:0]cout_12_2;
    wire [31:0]cout_12_1;

    reg [31:0]cout_22_1_reg;
    reg [31:0]cout_22_2_reg;
    reg [31:0]cout_12_2_reg;
    reg [31:0]cout_12_1_reg;

   
    // Instantiate the Unit Under Test (UUT)
    dmme_nonmem uut(
    .clk(clk),
    .en(en),
    .rst(rst),
    .mode(mode),
    .ain1(ain1_reg),
    .ain2(ain2_reg),
    .bin1(bin1_reg),
    .bin2(bin2_reg),
    .maskin11_1(maskin11_1),
    .maskin21_1(maskin21_1),
    .maskin11_2(maskin11_2),
    .maskin21_2(maskin21_2),
    .valid_12_out(valid_12_out),
    .valid_22_out(valid_22_out),
    .done(done),
    .cout_22_1_final(cout_22_1),
    .cout_22_2_final(cout_22_2),
    .cout_12_2_final(cout_12_2),
    .cout_12_1_final(cout_12_1)
    );

    always @(posedge clk or negedge rst) begin
    if (!rst) begin
        cout_12_1_reg <= 1'b0;
        cout_12_2_reg <= 1'b0;
        cout_22_1_reg <= 1'b0;
        cout_22_2_reg <= 1'b0;
    end
    else begin
        cout_12_1_reg <= cout_12_1;
        cout_12_2_reg <= cout_12_2;
        cout_22_1_reg <= cout_22_1;
        cout_22_2_reg <= cout_22_2;
        
    end
    end
    
    always @(posedge clk or negedge rst) begin
    if (!rst) begin
        ain1_reg <= 1'b0;
        ain2_reg <= 1'b0;
        bin1_reg <= 1'b0;
        bin2_reg <= 1'b0;

        maskin11_1 <= 4'b0;
        maskin21_1 <= 4'b0;
        maskin11_2 <= 4'b0;
        maskin21_2 <= 4'b0;

        mode_reg <= 1'b0;
    end
    else begin
        ain1_reg <= ain1;
        ain2_reg <= ain2;
        bin1_reg <= bin1;
        bin2_reg <= bin2;

        maskin11_1 <= maskin;
        maskin21_1 <= maskin;
        maskin11_2 <= maskin;
        maskin21_2 <= maskin;
            
        mode_reg <= mode;
    end
    end



    

endmodule

