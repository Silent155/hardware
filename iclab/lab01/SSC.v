module SSC (
    card_num,
    input_money,
    snack_num,
    price,
    out_valid,
    out_change
);

input [63:0]card_num;
input [8:0]input_money;
input [31:0]snack_num;
input [31:0]price;
output reg outvalid;
output reg [8:0] out_change;



wire [3:0]c16,c15,c14,c13,c12,c11,c10,c9,c8,c7,c6,c5,c4,c3,c2,c1;
wire [4:0]c15_2,c13_2,c11_2,c9_2,c7_2,c5_2,c3_2,c1_2;
wire [4:0]c15_3,c13_3,c11_3,c9_3,c7_3,c5_3,c3_3,c1_3;
wire [8:0]sum;

wire [3:0] snack1,snack2,snack3,snack4,snack5,snack6,snack7,snack8;
wire [3:0] price1,price2,price3,price4,price5,price6,price7,price8;
wire [7:0] total1,total2,total3,total4,total5,total6,total7,total8;
wire [7:0] total1_1,total2_1,total3_1,total4_1,total5_1,total6_1,total7_1,total8_1;
wire [7:0] total1_2,total2_2,total3_2,total4_2,total5_2,total6_2,total7_2,total8_2;
wire [7:0] total1_3,total2_3,total3_3,total4_3,total5_3,total6_3,total7_3,total8_3;
wire [7:0] total1_4,total2_4,total3_4,total4_4,total5_4,total6_4,total7_4,total8_4;
wire [7:0] total1_5,total2_5,total3_5,total4_5,total5_5,total6_5,total7_5,total8_5;
wire [7:0] total1_6,total2_6,total3_6,total4_6,total5_6,total6_6,total7_6,total8_6;

wire valid_flag;






assign c16 = [63:60]card_num;
assign c15 = [59:56]card_num;
assign c14 = [55:52]card_num;
assign c13 = [51:48]card_num;
assign c12 = [47:44]card_num;
assign c11 = [43:40]card_num;
assign c10 = [39:36]card_num;
assign c9  = [35:32]card_num;
assign c8  = [31:28]card_num;
assign c7  = [27:24]card_num;
assign c6  = [23:20]card_num;
assign c5  = [19:16]card_num;
assign c4  = [15:12]card_num;
assign c3  = [11:8] card_num;
assign c2  = [7:4]  card_num;
assign c1  = [3:0]  card_num;

//even multiple 2
assign c15_2 = c15<<1;
assign c13_2 = c13<<1;
assign c11_2 = c11<<1;
assign c9_2  = c9<<1 ;
assign c7_2  = c7<<1 ;
assign c5_2  = c5<<1 ;
assign c3_2  = c3<<1 ;
assign c1_2  = c1<<1 ;
//if excess 10,split and add
assign c15_3 = (c15_2 > 'd10)? c15_2-'d9 : c15_2;
assign c13_3 = (c13_2 > 'd10)? c13_2-'d9 : c13_2;
assign c11_3 = (c11_2 > 'd10)? c11_2-'d9 : c11_2;
assign c9_3 = (c9_2 > 'd10)? c9_2-'d9 : c9_2;
assign c7_3 = (c7_2 > 'd10)? c7_2-'d9 : c7_2;
assign c5_3 = (c5_2 > 'd10)? c5_2-'d9 : c5_2;
assign c3_3 = (c3_2 > 'd10)? c3_2-'d9 : c3_2;
assign c1_3 = (c1_2 > 'd10)? c1_2-'d9 : c1_2;

assign sum1=c15_3+c13_3;
assign sum2=c11_3+c9_3;
assign sum3=c7_3+c5_3;
assign sum4=c3_3+c1_3;
assign sum5=c16+c14;
assign sum6=c12+c10;
assign sum7=c8+c6;
assign sum8=c4+c2;
assign sum9=sum1+sum2;
assign sum10=sum3+sum4;
assign sum11=sum5+sum6;
assign sum12=sum7+sum8;
assign sum13=sum9+sum10;
assign sum14=sum11+sum12;
assign sum15=sum13+sum14;

assign valid_flag=(sum15%3'd10==0)? 'd1:'d0;
//snack
assign snack8 = [31:28]snack_num;
assign snack7 = [27:24]snack_num;
assign snack6 = [23:20]snack_num;
assign snack5 = [19:16]snack_num;
assign snack4 = [15:12]snack_num;
assign snack3 = [11:8]snack_num;
assign snack2 = [7:4]snack_num;
assign snack1 = [3:0]snack_num;

assign price8 = [31:28]price;
assign price7 = [27:24]price;
assign price6 = [23:20]price;
assign price5 = [19:16]price;
assign price4 = [15:12]price;
assign price3 = [11:8]price;
assign price2 = [7:4]price;
assign price1 = [3:0]price;

assign total8 = snack8*price8;
assign total7 = snack7*price7;
assign total6 = snack6*price6;
assign total5 = snack5*price5;
assign total4 = snack4*price4;
assign total3 = snack3*price3;
assign total2 = snack2*price2;
assign total1 = snack1*price1;


//step1
always @(*) begin
    if(total8>total7)begin
        total8_1 = total8;
        total7_1 = total7;
    end
    else begin
        total8_1 = total7;
        total7_1 = total8;
    end
end

always @(*) begin
    if(total6>total5)begin
        total6_1 = total6;
        total5_1 = total5;
    end
    else begin
        total6_1 = total5;
        total5_1 = total6;
    end
end

always @(*) begin
    if(total4>total3)begin
        total4_1 = total4;
        total3_1 = total3;
    end
    else begin
        total4_1 = total3;
        total3_1 = total4;
    end
end

always @(*) begin
    if(total2>total1)begin
        total2_1 = total2;
        total1_1 = total1;
    end
    else begin
        total2_1 = total1;
        total1_1 = total2;
    end
end


//step2

always @(*) begin
    if(total8_1>total6_1)begin
        total8_2 = total8_1;
        total6_2 = total6_1;
    end
    else begin
        total8_2 = total6_1;
        total6_2 = total8_1;
    end
end

always @(*) begin
    if(total7_1>total5_1)begin
        total7_2 = total7_1;
        total5_2 = total5_1;
    end
    else begin
        total7_2 = total5_1;
        total5_2 = total7_1;
    end
end

always @(*) begin
    if(total4_1>total2_1)begin
        total4_2 = total4_1;
        total2_2 = total2_1;
    end
    else begin
        total4_2 = total2_1;
        total2_2 = total4_1;
    end
end

always @(*) begin
    if(total3_1>total1_1)begin
        total3_2 = total3_1;
        total1_2 = total1_1;
    end
    else begin
        total3_2 = total1_1;
        total1_2 = total3_1;
    end
end

//step3
always @(*) begin
    if(total7_2>total6_2)begin
        total7_3 = total7_2;
        total6_3 = total6_2;
    end
    else begin
        total7_3 = total6_2;
        total6_3 = total7_2;
    end
end

always @(*) begin
    if(total3_2>total2_2)begin
        total3_3 = total3_2;
        total2_3 = total2_2;
    end
    else begin
        total3_3 = total2_2;
        total2_3 = total3_2;
    end
end


always @(*) begin
        total1_3 = total1_2;
        total4_3 = total4_2;
        total5_3 = total5_2;
        total8_3 = total8_2;
end

//step4
always @(*) begin
    if(total8_3>total4_3)begin
        total8_4 = total8_3;
        total4_4 = total4_3;
    end
    else begin
        total8_4 = total4_4;
        total4_4 = total8_4;
    end
end

always @(*) begin
    if(total7_3>total3_3)begin
        total7_4 = total7_3;
        total3_4 = total3_3;
    end
    else begin
        total7_4 = total3_3;
        total3_4 = total7_3;
    end
end

always @(*) begin
    if(total8_3>total4_3)begin
        total6_4 = total6_3;
        total2_4 = total2_3;
    end
    else begin
        total6_4 = total2_4;
        total2_4 = total4_4;
    end
end

always @(*) begin
    if(total5_3>total1_3)begin
        total5_4 = total5_3;
        total1_4 = total1_3;
    end
    else begin
        total5_4 = total1_3;
        total1_4 = total5_3;
    end
end

//step5
always @(*) begin
    if(total6_4>total4_4)begin
        total6_5 = total6_4;
        total4_5 = total4_4;
    end
    else begin
        total6_5 = total6_4;
        total4_5 = total4_4;
    end
end

always @(*) begin
    if(total5_4>total3_4)begin
        total5_5 = total5_4;
        total3_5 = total3_4;
    end
    else begin
        total5_5 = total3_4;
        total3_5 = total5_4;
    end
end


always @(*) begin
        total1_5 = total1_4;
        total2_5 = total2_4;
        total7_5 = total7_4;
        total8_5 = total8_4;
end
//step6
always @(*) begin
    if(total7_5>total6_5)begin
        total7_6 = total7_5;
        total6_6 = total6_5;
    end
    else begin
        total7_6 = total6_5;
        total6_6 = total7_5;
    end
end

always @(*) begin
    if(total5_5>total4_5)begin
        total5_6 = total5_5;
        total4_6 = total4_5;
    end
    else begin
        total5_6 = total4_5;
        total4_6 = total5_5;
    end
end

always @(*) begin
    if(total3_5>total2_5)begin
        total3_6 = total3_5;
        total2_6 = total2_5;
    end
    else begin
        total3_6 = total2_5;
        total2_6 = total3_5;
    end
end


always @(*) begin
        total1_6 = total1_5;
        total8_6 = total8_5;
end


//buy

    
always @(*)begin
    if(input_money>=total8_6)begin
        input2=input_money-total8_6;
    end
    else begin
        input2=input_money;
    end
end

always @(*)begin
    if(input2>=total7_6)begin
        input3=input2-total7_6;
    end
    else begin
        input3=input2;
    end
end

always @(*)begin
    if(input3>=total6_6)begin
        input4=input3-total6_6;
    end
    else begin
        input4=input3;
    end
end

always @(*)begin
    if(input4>=total5_6)begin
        input5=input4-total5_6;
    end
    else begin
        input5=input4;
    end
end

always @(*)begin
    if(input5>=total4_6)begin
        input6=input5-total4_6;
    end
    else begin
        input6=input5;
    end
end

always @(*)begin
    if(input6>=total3_6)begin
        input7=input6-total3_6;
    end
    else begin
        input7=input6;
    end
end

always @(*)begin
    if(input7>=total2_6)begin
        input8=input7-total2_6;
    end
    else begin
        input8=input7;
    end
end

always @(*)begin
    if(input8>=total1_6)begin
        input9=input8-total1_6;
    end
    else begin
        input9=input8;
    end
end

always @(*)begin
    if(valid_flag)begin
        out_change=input9;
        out_valid=1'd1;
    end
    else begin
        out_change=input_money;
        out_valid=1'd0;
    end
end

endmodule