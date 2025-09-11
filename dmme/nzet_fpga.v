module nzet_fpga(ain_0,ain_1, maskin,ain0,ain1,ain2,ain3);

output reg [7:0]ain_0,ain_1;
input [7:0]ain0,ain1,ain2,ain3;
input [3:0]maskin;

wire  [3:0]NbitSel0;
wire  [3:0]NbitSel1;


wire [3:0]temp1;


assign NbitSel0 = maskin & (~maskin+1'b1);
always @(*) begin
    case(NbitSel0)
		4'b0001:ain_0 = ain0;
		4'b0010:ain_0 = ain1;
		4'b0100:ain_0 = ain2;
		default:ain_0 = 8'b0;
	endcase
end
assign temp1 = maskin ^ NbitSel0;
assign NbitSel1 = temp1 & (~temp1+1'b1);
always @(*) begin
    case(NbitSel1)
		4'b0010:ain_1 = ain1;
		4'b0100:ain_1 = ain2;
		4'b1000:ain_1 = ain3;
		default:ain_1 = 8'b0;
	endcase
end
endmodule