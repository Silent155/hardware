module pe (
    input clock,
    input en,
    input [3:0] maskin,
    input [63:0] ain,
    input [31:0] bin,
    input [31:0] cin,
    input [1:0] mode,
    input mode_nzet,
    output wire [3:0] maskOut,
    output wire [63:0] aOut,
    output wire [31:0] bOut,
    output wire [31:0] cOut
);

parameter DENDEN = 2'b00 ;
parameter SPADEN = 2'b01 ;
parameter SHIFT = 2'b10 ;
parameter WAIT = 2'b11 ;

    reg [3:0] maskout_reg;
    reg signed [63:0] aout_reg;
    reg signed [31:0] bout_reg;
    reg signed [31:0] cout_reg;


//wire
    wire signed [63:0] aout = (!en) ? 64'b0 : ain;
    wire signed [31:0] bout = (!en) ? 32'b0 : bin;
    reg signed [31:0] cout;
    wire signed [3:0] maskout = (!en) ? 4'b0 : maskin;

    wire signed [15:0] ain0 = ain[15:0];
    wire signed [15:0] ain1 = ain[31:16];
    wire signed [15:0] ain2 = ain[47:32];
    wire signed [15:0] ain3 = ain[63:48];

    wire signed [15:0] ain0_mac = (mode_nzet==SPADEN) ? aout0_nz : ain[15:0];
    wire signed [15:0] ain1_mac = (mode_nzet==SPADEN) ? aout1_nz : ain[31:16];
    
    wire signed [15:0] bin0 = bin[15:0];
    wire signed [15:0] bin1 = bin[31:16];

    wire signed [31:0] cin_mac = (mode==SHIFT) ? cin: cOut;
    wire signed [31:0] cout_mac;
    wire signed [15:0] aout0_nz;
    wire signed [15:0] aout1_nz;

mac macin(
    .bin0 (bin0),
    .bin1 (bin1),
    .ain0 (ain0_mac),
    .ain1 (ain1_mac),
    .cSumin (cin_mac),
    .cSumout (cout_mac)
);

nzet neztin(
    .ain_0 (aout0_nz),
    .ain_1 (aout1_nz),
    .maskin (maskin),
    .ain0 (ain0),
    .ain1 (ain1),
    .ain2 (ain2),
    .ain3 (ain3)
);

    assign maskOut = maskout_reg;
    assign aOut = aout_reg;
    assign bOut = bout_reg;
    assign cOut = cout_reg;


//cout
    always @(*) begin
        if(!en)
            cout = 32'b0;
        else begin
        case(mode)
            DENDEN : cout = cout_mac;
            SPADEN : cout = cout_mac;
            SHIFT : cout = cin_mac;
            WAIT : cout = cin_mac;
            default: cout = cin_mac;
        endcase
        end
    end


//OUTPUT reg
always @(posedge clock) begin
       maskout_reg <= maskout;
       bout_reg <= bout;
       cout_reg <= cout;
       aout_reg <= aout;end  











endmodule