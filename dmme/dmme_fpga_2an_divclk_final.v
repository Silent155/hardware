module dmme_fpga (
    input clk_in,
    input en,
    input rst,
    input mode,
    output [3:0] an,
    output [3:0] bn, // 片?信?，控制 8 ??示器 // 片?信?，控制 8 ??示器
    output [7:0] seg0,       // 段?信?，?? a-g 的亮?
    output [7:0] seg1        // 段?信?，?? a-g 的亮?  
);
parameter IDLE=2'b0;
parameter MAC=2'b1;
parameter DONE=2'd2;
parameter DENDEN=1'b0;
parameter SPADEN=1'b1;
    
    reg [63:0]ain1=0;
    reg [63:0]ain2=0;
    reg [63:0]bin1=0;
    reg [63:0]bin2=0;
    reg [31:0]cout_12_1_final=0;
    reg [31:0]cout_12_2_final=0;
    reg [31:0]cout_22_1_final=0;
    reg [31:0]cout_22_2_final=0;

    reg [1:0]state=0;
    reg [1:0]next_state=0;

    reg [2:0]counter_denden=0;
    reg [2:0]counter_spaden=0;

    reg [1:0]pe11_1_mode_reg=0;
    reg [1:0]pe12_1_mode_reg=0;
    reg [1:0]pe21_1_mode_reg=0;
    reg [1:0]pe22_1_mode_reg=0;
    reg [1:0]pe11_2_mode_reg=0;
    reg [1:0]pe12_2_mode_reg=0;
    reg [1:0]pe21_2_mode_reg=0;
    reg [1:0]pe22_2_mode_reg=0;


    reg pe11_1_en_reg=0;
    reg pe12_1_en_reg=0;
    reg pe21_1_en_reg=0;
    reg pe22_1_en_reg=0;
    reg pe11_2_en_reg=0;
    reg pe12_2_en_reg=0;
    reg pe21_2_en_reg=0;
    reg pe22_2_en_reg=0;

    reg [63:0]ain_11_1=0;
    reg [63:0]ain_12_1=0;
    reg [63:0]ain_11_2=0;
    reg [63:0]ain_12_2=0;
    reg [31:0]bin_11_1=0;
    reg [31:0]bin_21_1=0;
    reg [31:0]bin_11_2=0;
    reg [31:0]bin_21_2=0;
    reg [3:0]maskin11_1=4'b0101;
    reg [3:0]maskin21_1=4'b0101;
    reg [3:0]maskin11_2=4'b0101;
    reg [3:0]maskin21_2=4'b0101;
    reg [3:0] maskin_11_1=0;
    reg [3:0] maskin_21_1=0;
    reg [3:0] maskin_11_2=0;
    reg [3:0] maskin_21_2=0;
    reg [31:0]cin_11_1=0;
    reg [31:0]cin_21_1=0;
    reg [31:0]cin_11_2=0;
    reg [31:0]cin_21_2=0;
    wire [1:0]mode_11_1,mode_12_1,mode_21_1,mode_22_1,mode_11_2,mode_12_2,mode_21_2,mode_22_2;
    wire [3:0]maskout_11_1,maskout_12_1,maskout_21_1,maskout_22_1,maskout_11_2,maskout_12_2,maskout_21_2,maskout_22_2;
    wire [63:0]aout_11_1,aout_12_1,aout_21_1,aout_22_1,aout_11_2,aout_12_2,aout_21_2,aout_22_2;
    wire [31:0]bout_11_1,bout_12_1,bout_21_1,bout_22_1,bout_11_2,bout_12_2,bout_21_2,bout_22_2;
    wire [31:0]cout_11_1,cout_12_1,cout_21_1,cout_22_1,cout_11_2,cout_12_2,cout_21_2,cout_22_2;


    reg pe11_1_en_start=0;
    reg pe12_1_en_start=0;
    reg pe21_1_en_start=0;
    reg pe22_1_en_start=0;
    reg pe11_2_en_start=0;
    reg pe12_2_en_start=0;
    reg pe21_2_en_start=0;
    reg pe22_2_en_start=0;

    reg [1:0]pe11_1_mode_start=0;
    reg [1:0]pe12_1_mode_start=0;
    reg [1:0]pe21_1_mode_start=0;
    reg [1:0]pe22_1_mode_start=0;
    reg [1:0]pe11_2_mode_start=0;
    reg [1:0]pe12_2_mode_start=0;
    reg [1:0]pe21_2_mode_start=0;
    reg [1:0]pe22_2_mode_start=0;

    wire finish;

    reg [31:0]data=0;
    reg [3:0]display=0;
    
    
    parameter maxcnt=4999;
    
    reg [20:0]divclk_cnt=0;
    reg [2:0]digit_counter=0;
    reg divclk=0;

segment_7 a1(
  .clk(clk_in),
  .LED_BIT(an),
  .LED_content_in(data[15:0]),
  .LED_content_out(seg0)
);
segment_7 a2(
  .clk(clk_in),
  .LED_BIT(bn),
  .LED_content_in(data[31:16]),
  .LED_content_out(seg1)
);
    
    
    
    always @(posedge clk_in) begin
        if(state==2'b1 && counter_denden==3'd3)
            data<=cout_12_1_final;
        else
            data<=data;
    end 


always @(*) begin
    if(mode==DENDEN)begin
        if(next_state==2'b1 && counter_denden==3'b0 && state==2'b0)begin
            ain1= 64'h2345678923456789;
            bin1= 64'h1111000011110000;end
        else if(state==2'b1 && counter_denden==3'b0)begin
            ain1 = 64'h1111000011110000;
            bin1 = 64'h2345678923456789;end
        else  begin  
            ain1 = 64'h0000000000000000;
            bin1 = 64'h0000000000000000;end
    end
    else begin
        if(next_state==2'b1 && counter_spaden==3'b0 && state==2'b0)begin
            ain1 = 64'h2345678923456789;
            bin1 = 64'h1111000011110000;end
        else  begin  
            ain1 = 64'h0000000000000000;
            bin1 = 64'h0000000000000000;end
    end
end

always @(*) begin
    if(mode==DENDEN)begin
        if(state==2'b1 && counter_denden==3'b0)begin
            ain2 = 64'h8765432187654321;
            bin2 = 64'h0000111100001111;end
        else if(state==2'b1 && counter_denden==3'd1)begin
            ain2 = 64'h0000111100001111;
            bin2 = 64'h8765432187654321;end
        else  begin  
            ain2= 64'h00000000;
            bin2= 64'h00000000;end
    end
    else begin
        if(state==2'b1 && counter_spaden==3'b0)begin
            ain2 = 64'h8765432187654321;
            bin2 = 64'h0000111100001111;end
        else  begin  
            ain2 = 64'h0000000000000000;
            bin2 = 64'h0000000000000000;end
    end
end



always @(*)begin
    if(mode==SPADEN)begin
        if(counter_spaden>1)begin
            cout_12_1_final = cout_12_1;
            cout_12_2_final = cout_12_2;end
        else begin
            cout_12_1_final = 32'b0;
            cout_12_2_final = 32'b0;end
    end
    else begin
        if(counter_denden>2)begin
            cout_12_1_final = cout_12_1;
            cout_12_2_final = cout_12_2;end
        else begin
            cout_12_1_final = 32'b0;
            cout_12_2_final = 32'b0;end
    end
end

always @(*)begin
    if(mode==SPADEN)begin
        if(counter_spaden>2)begin
            cout_22_1_final = cout_22_1;
            cout_22_2_final = cout_22_2;end
        else begin
            cout_22_1_final = 32'b0;
            cout_22_2_final = 32'b0;end
    end
    else begin
        if(counter_denden>3)begin
            cout_22_1_final = cout_22_1;
            cout_22_2_final = cout_22_2;end
        else begin
            cout_22_1_final = 32'b0;
            cout_22_2_final = 32'b0;end
    end
end
pe pe11_1(
    .clock (clk_in),
    .en (pe11_1_en_reg),
    .maskin (maskin_11_1),
    .ain (ain_11_1),
    .bin (bin_11_1),
    .cin (cin_11_1),
    .mode (pe11_1_mode_reg),
    .mode_nzet (mode),
    .maskOut (maskout_11_1),
    .aOut (aout_11_1),
    .bOut (bout_11_1),
    .cOut (cout_11_1)
);

pe pe12_1(
    .clock (clk_in),
    .en (pe12_1_en_reg),
    .maskin (maskout_11_1),
    .ain (ain_12_1),
    .bin (bout_11_1),
    .cin (cout_11_1),
    .mode (pe12_1_mode_reg),
    .mode_nzet (mode),
    .maskOut (maskout_12_1),
    .aOut (aout_12_1),
    .bOut (bout_12_1),
    .cOut (cout_12_1)
);

pe pe21_1(
    .clock (clk_in),
    .en (pe21_1_en_reg),
    .maskin (maskin_21_1),
    .ain (aout_11_1),
    .bin (bin_21_1),
    .cin (cin_21_1),
    .mode (pe21_1_mode_reg),
    .mode_nzet (mode),
    .maskOut (maskout_21_1),
    .aOut (aout_21_1),
    .bOut (bout_21_1),
    .cOut (cout_21_1)
);

pe pe22_1(
    .clock (clk_in),
    .en (pe22_1_en_reg),
    .maskin (maskout_21_1),
    .ain (aout_12_1),
    .bin (bout_21_1),
    .cin (cout_21_1),
    .mode (pe22_1_mode_reg),
    .mode_nzet (mode),
    .maskOut (maskout_22_1),
    .aOut (aout_22_1),
    .bOut (bout_22_1),
    .cOut (cout_22_1)
);

pe pe11_2(
    .clock (clk_in),
    .en (pe11_2_en_reg),
    .maskin (maskin_11_2),
    .ain (ain_11_2),
    .bin (bin_11_2),
    .cin (cin_11_2),
    .mode (pe11_2_mode_reg),
    .mode_nzet (mode),
    .maskOut (maskout_11_2),
    .aOut (aout_11_2),
    .bOut (bout_11_2),
    .cOut (cout_11_2)
);

pe pe12_2(
    .clock (clk_in),
    .en (pe12_2_en_reg),
    .maskin (maskout_11_2),
    .ain (ain_12_2),
    .bin (bout_11_2),
    .cin (cout_11_2),
    .mode (pe12_2_mode_reg),
    .mode_nzet (mode),
    .maskOut (maskout_12_2),
    .aOut (aout_12_2),
    .bOut (bout_12_2),
    .cOut (cout_12_2)
);

pe pe21_2(
    .clock (clk_in),
    .en (pe21_2_en_reg),
    .maskin (maskin_21_2),
    .ain (aout_11_2),
    .bin (bin_21_2),
    .cin (cin_21_2),
    .mode (pe21_2_mode_reg),
    .mode_nzet (mode),
    .maskOut (maskout_21_2),
    .aOut (aout_21_2),
    .bOut (bout_21_2),
    .cOut (cout_21_2)
);

pe pe22_2(
    .clock (clk_in),
    .en (pe22_2_en_reg),
    .maskin (maskout_21_2),
    .ain (aout_12_2),
    .bin (bout_21_2),
    .cin (cout_21_2),
    .mode (pe22_2_mode_reg),
    .mode_nzet (mode),
    .maskOut (maskout_22_2),
    .aOut (aout_22_2),
    .bOut (bout_22_2),
    .cOut (cout_22_2)
);


always @(*) begin
    case(state) 
        IDLE : begin if(en) begin 
                    next_state = MAC;end
               else begin
                    next_state = IDLE;end
               end
        MAC  : begin if(finish) begin
                    next_state = DONE;end
               else begin
                    next_state = MAC;end
               end
        DONE : begin next_state = IDLE;end
        default: begin next_state = IDLE;end
        
    endcase
    
    
end

always @(posedge clk_in or negedge rst) begin
        if(!rst)
            state <= IDLE;
        else
            state <= next_state;
end



always @(posedge clk_in) begin
    cin_11_1 <= 32'b0;
    cin_21_1 <= 32'b0;
    cin_11_2 <= 32'b0;
    cin_21_2 <= 32'b0;
    end


always @(posedge clk_in or negedge rst) begin
    if(!rst)
        begin
        ain_11_1 <= 'b0;
        ain_12_1 <= 'b0;
        bin_11_1 <= 'b0;
        bin_21_1 <= 'b0;

        ain_11_2 <= 'b0;
        ain_12_2 <= 'b0;
        bin_11_2 <= 'b0;
        bin_21_2 <= 'b0; 

        maskin_11_1 <= 'b0;
        maskin_21_1 <= 'b0;
        maskin_11_2 <= 'b0;
        maskin_21_2 <= 'b0;
        end   
    else if(next_state==MAC)begin
        maskin_11_1 <= maskin11_1;
        maskin_21_1 <= maskin21_1;
        maskin_11_2 <= maskin11_2;
        maskin_21_2 <= maskin21_2;
        if(mode==SPADEN)begin
            ain_11_1 <= ain1[63:0];
            ain_12_1 <= ain2[63:0];
            bin_11_1 <= bin1[31:0];
            bin_21_1 <= bin2[31:0];

            ain_11_2 <= ain1[63:0];
            ain_12_2 <= ain2[63:0];
            bin_11_2 <= bin1[63:32];
            bin_21_2 <= bin2[63:32]; end
        else begin
            ain_11_1 <= ain1[31:0];
            ain_12_1 <= ain2[31:0];
            bin_11_1 <= bin1[31:0];
            bin_21_1 <= bin2[31:0];

            ain_11_2 <= ain1[63:32];
            ain_12_2 <= ain2[63:32];
            bin_11_2 <= bin1[63:32];
            bin_21_2 <= bin2[63:32]; end
        end
    
    else begin
        ain_11_1 <= 'b0;
        ain_12_1 <= 'b0;
        bin_11_1 <= 'b0;
        bin_21_1 <= 'b0;

        ain_11_2 <= 'b0;
        ain_12_2 <= 'b0;
        bin_11_2 <= 'b0;
        bin_21_2 <= 'b0; 

        maskin_11_1 <= 'b0;
        maskin_21_1 <= 'b0;
        maskin_11_2 <= 'b0;
        maskin_21_2 <= 'b0;end
end


assign finish=(mode==DENDEN)? ((counter_denden==4)? 1'b1:1'b0) : ((counter_spaden==3)?1'b1:1'b0);

always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe11_1_en_reg <= 1'b0;
    else if(pe11_1_en_start)
        pe11_1_en_reg <= 1'b1;
    else
        pe11_1_en_reg <= 1'b0;
end
always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe12_1_en_reg <= 1'b0; 
    else if(pe12_1_en_start)
        pe12_1_en_reg <= 1'b1;
    else
        pe12_1_en_reg <= 1'b0;
end
always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe21_1_en_reg <= 1'b0;
    else if(pe21_1_en_start)
        pe21_1_en_reg <= 1'b1;
    else
        pe21_1_en_reg <= 1'b0;
end
always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe22_1_en_reg <= 1'b0;
    else if(pe22_1_en_start)
        pe22_1_en_reg <= 1'b1;
    else
        pe22_1_en_reg <= 1'b0;
end

always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe11_2_en_reg <= 1'b0;
    else if(pe11_2_en_start)
        pe11_2_en_reg <= 1'b1;
    else
        pe11_2_en_reg <= 1'b0;
end
always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe12_2_en_reg <= 1'b0;
    else if(pe12_2_en_start)
        pe12_2_en_reg <= 1'b1;
    else
        pe12_2_en_reg <= 1'b0;
end
always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe21_2_en_reg <= 1'b0;
    else if(pe21_2_en_start)
        pe21_2_en_reg <= 1'b1;
    else
        pe21_2_en_reg <= 1'b0;
end
always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe22_2_en_reg <= 1'b0;
    else if(pe22_2_en_start)
        pe22_2_en_reg <= 1'b1;
    else
        pe22_2_en_reg <= 1'b0;
end



always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe11_1_mode_reg <= 2'b0;
    else
        pe11_1_mode_reg <= pe11_1_mode_start;
end

always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe12_1_mode_reg <= 2'b0;
    else
        pe12_1_mode_reg <= pe12_1_mode_start;
end

always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe21_1_mode_reg <= 2'b0;
    else
        pe21_1_mode_reg <= pe21_1_mode_start;
end

always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe22_1_mode_reg <= 2'b0;
    else
        pe22_1_mode_reg <= pe22_1_mode_start;
end

always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe11_2_mode_reg <= 2'b0;
    else
        pe11_2_mode_reg <= pe11_2_mode_start;
end

always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe12_2_mode_reg <= 2'b0;
    else
        pe12_2_mode_reg <= pe12_2_mode_start;
end

always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe21_2_mode_reg <= 2'b0;
    else
        pe21_2_mode_reg <= pe21_2_mode_start;
end

always @(posedge clk_in or negedge rst) begin
    if(!rst)
        pe22_2_mode_reg <= 2'b0;
    else
        pe22_2_mode_reg <= pe22_2_mode_start;
end




always @(*) begin
    if(mode==DENDEN)begin
        case(counter_denden)
            0:  begin   
                pe22_1_mode_start = 2'b0;
                pe22_2_mode_start = 2'b0;
                pe11_1_mode_start = 2'b0;
                pe12_1_mode_start = 2'b0;
                pe21_1_mode_start = 2'b0;
                pe11_2_mode_start = 2'b0;
                pe12_2_mode_start = 2'b0;
                pe21_2_mode_start = 2'b0;end
            1: 
                begin
                    pe22_1_mode_start = 2'd0;
                    pe22_2_mode_start = 2'd0;
                    pe11_1_mode_start = 2'd3;
                    pe12_1_mode_start = 2'd0;
                    pe21_1_mode_start = 2'd0;
                    pe11_2_mode_start = 2'd3;
                    pe12_2_mode_start = 2'd0;
                    pe21_2_mode_start = 2'd0;end
            2:begin
                    pe22_1_mode_start = 2'b0;
                    pe22_2_mode_start = 2'b0;
                    pe11_1_mode_start = 2'b0;
                    pe12_1_mode_start = 2'd2;
                    pe21_1_mode_start = 2'd3;
                    pe11_2_mode_start = 2'b0;
                    pe12_2_mode_start = 2'd2;
                    pe21_2_mode_start = 2'd3;end
            3:begin
                    pe22_1_mode_start = 2'd2;
                    pe22_2_mode_start = 2'd2;
                    pe11_1_mode_start = 2'b0;
                    pe12_1_mode_start = 2'b0;
                    pe21_1_mode_start = 2'b0;
                    pe11_2_mode_start = 2'b0;
                    pe12_2_mode_start = 2'b0;
                    pe21_2_mode_start = 2'b0;end
            default:
                begin
                    pe22_1_mode_start = 2'b0;
                    pe22_2_mode_start = 2'b0;
                    pe11_1_mode_start = 2'b0;
                    pe12_1_mode_start = 2'b0;
                    pe21_1_mode_start = 2'b0;
                    pe11_2_mode_start = 2'b0;
                    pe12_2_mode_start = 2'b0;
                    pe21_2_mode_start = 2'b0;end
        endcase
    end
    else begin
        case(counter_spaden)
            0:  begin   
                if(state==MAC)begin
                pe22_1_mode_start = 2'b1;
                pe22_2_mode_start = 2'b1;
                pe11_1_mode_start = 2'd3;
                pe12_1_mode_start = 2'b1;
                pe21_1_mode_start = 2'b1;
                pe11_2_mode_start = 2'd3;
                pe12_2_mode_start = 2'b1;
                pe21_2_mode_start = 2'b1;end
                else begin
                pe22_1_mode_start = 2'b1;
                pe22_2_mode_start = 2'b1;
                pe11_1_mode_start = 2'b1;
                pe12_1_mode_start = 2'b1;
                pe21_1_mode_start = 2'b1;
                pe11_2_mode_start = 2'b1;
                pe12_2_mode_start = 2'b1;
                pe21_2_mode_start = 2'b1;end

                end
            1: 
                begin
                    pe22_1_mode_start = 2'b1;
                    pe22_2_mode_start = 2'b1;
                    pe11_1_mode_start = 2'b1;
                    pe12_1_mode_start = 2'd2;
                    pe21_1_mode_start = 2'd3;
                    pe11_2_mode_start = 2'b1;
                    pe12_2_mode_start = 2'd2;
                    pe21_2_mode_start = 2'd3;end
            2:begin
                    pe22_1_mode_start = 2'd2;
                    pe22_2_mode_start = 2'd2;
                    pe11_1_mode_start = 2'b1;
                    pe12_1_mode_start = 2'b1;
                    pe21_1_mode_start = 2'b1;
                    pe11_2_mode_start = 2'b1;
                    pe12_2_mode_start = 2'b1;
                    pe21_2_mode_start = 2'b1;end
            3:begin
                    pe22_1_mode_start = 2'b1;
                    pe22_2_mode_start = 2'b1;
                    pe11_1_mode_start = 2'b1;
                    pe12_1_mode_start = 2'b1;
                    pe21_1_mode_start = 2'b1;
                    pe11_2_mode_start = 2'b1;
                    pe12_2_mode_start = 2'b1;
                    pe21_2_mode_start = 2'b1;end
            default:
                begin
                    pe22_1_mode_start = 2'b1;
                    pe22_2_mode_start = 2'b1;
                    pe11_1_mode_start = 2'b1;
                    pe12_1_mode_start = 2'b1;
                    pe21_1_mode_start = 2'b1;
                    pe11_2_mode_start = 2'b1;
                    pe12_2_mode_start = 2'b1;
                    pe21_2_mode_start = 2'b1;end
        endcase

    end
end


always @(*) begin
    if(mode==DENDEN)begin
        case(counter_denden)
            0:  begin   
                pe22_1_en_start = 1'b0;
                pe22_2_en_start = 1'b0;
                if(next_state==MAC) begin
                    pe11_1_en_start = 1'b1;
                    pe11_2_en_start = 1'b1;end
                else begin
                    pe11_1_en_start = 1'b0;
                    pe11_2_en_start = 1'b0;end
                if(pe11_1_en_reg)begin
                    pe12_1_en_start = 1'b1;
                    pe21_1_en_start = 1'b1;
                    pe12_2_en_start = 1'b1;
                    pe21_2_en_start = 1'b1;end
                else begin
                    pe12_1_en_start = 1'b0;
                    pe21_1_en_start = 1'b0;
                    pe12_2_en_start = 1'b0;
                    pe21_2_en_start = 1'b0;end
            end
            1: 
                begin
                    pe22_1_en_start = 1'b1;
                    pe22_2_en_start = 1'b1;
                    pe11_1_en_start = 1'b1;
                    pe12_1_en_start = 1'b1;
                    pe21_1_en_start = 1'b1;
                    pe11_2_en_start = 1'b1;
                    pe12_2_en_start = 1'b1;
                    pe21_2_en_start = 1'b1;end
            2:begin
                    pe22_1_en_start = 1'b1;
                    pe22_2_en_start = 1'b1;
                    pe11_1_en_start = 1'b0;
                    pe12_1_en_start = 1'b1;
                    pe21_1_en_start = 1'b1;
                    pe11_2_en_start = 1'b0;
                    pe12_2_en_start = 1'b1;
                    pe21_2_en_start = 1'b1;end
            3:begin
                    pe22_1_en_start = 1'b1;
                    pe22_2_en_start = 1'b1;
                    pe11_1_en_start = 1'b0;
                    pe12_1_en_start = 1'b0;
                    pe21_1_en_start = 1'b0;
                    pe11_2_en_start = 1'b0;
                    pe12_2_en_start = 1'b0;
                    pe21_2_en_start = 1'b0;end
            default:
                begin
                    pe22_1_en_start = 1'b0;
                    pe22_2_en_start = 1'b0;
                    pe11_1_en_start = 1'b0;
                    pe12_1_en_start = 1'b0;
                    pe21_1_en_start = 1'b0;
                    pe11_2_en_start = 1'b0;
                    pe12_2_en_start = 1'b0;
                    pe21_2_en_start = 1'b0;end
        endcase
    end
    else begin
        case(counter_spaden)
            0:  begin   
                pe22_1_en_start = 1'b0;
                pe22_2_en_start = 1'b0;
                if(next_state==MAC) begin
                    pe11_1_en_start = 1'b1;
                    pe11_2_en_start = 1'b1;end
                else begin
                    pe11_1_en_start = 1'b0;
                    pe11_2_en_start = 1'b0;end
                if(pe11_1_en_reg)begin
                    pe12_1_en_start = 1'b1;
                    pe21_1_en_start = 1'b1;
                    pe12_2_en_start = 1'b1;
                    pe21_2_en_start = 1'b1;end
                else begin
                    pe12_1_en_start = 1'b0;
                    pe21_1_en_start = 1'b0;
                    pe12_2_en_start = 1'b0;
                    pe21_2_en_start = 1'b0;end
            end
               
            1: 
                begin
                    pe22_1_en_start = 1'b1;
                    pe22_2_en_start = 1'b1;
                    pe11_1_en_start = 1'b0;
                    pe12_1_en_start = 1'b1;
                    pe21_1_en_start = 1'b1;
                    pe11_2_en_start = 1'b0;
                    pe12_2_en_start = 1'b1;
                    pe21_2_en_start = 1'b1;end
            2:begin
                    pe22_1_en_start = 1'b1;
                    pe22_2_en_start = 1'b1;
                    pe11_1_en_start = 1'b0;
                    pe12_1_en_start = 1'b0;
                    pe21_1_en_start = 1'b0;
                    pe11_2_en_start = 1'b0;
                    pe12_2_en_start = 1'b0;
                    pe21_2_en_start = 1'b0;end
            3:begin
                    pe22_1_en_start = 1'b0;
                    pe22_2_en_start = 1'b0;
                    pe11_1_en_start = 1'b0;
                    pe12_1_en_start = 1'b0;
                    pe21_1_en_start = 1'b0;
                    pe11_2_en_start = 1'b0;
                    pe12_2_en_start = 1'b0;
                    pe21_2_en_start = 1'b0;end
            default:
                begin
                    pe22_1_en_start = 1'b0;
                    pe22_2_en_start = 1'b0;
                    pe11_1_en_start = 1'b0;
                    pe12_1_en_start = 1'b0;
                    pe21_1_en_start = 1'b0;
                    pe11_2_en_start = 1'b0;
                    pe12_2_en_start = 1'b0;
                    pe21_2_en_start = 1'b0;end
        endcase

    end
end




always@( posedge clk_in or negedge rst )
begin
        if( !rst ) counter_denden <= 3'd0;
        else if(state==MAC&&mode==DENDEN)
                counter_denden <= counter_denden + 3'd1;
        else
                counter_denden <= 3'd0;
end

always@( posedge clk_in or negedge rst )
begin
        if( !rst ) counter_spaden <= 3'd0;
        else if(state==MAC&&mode==SPADEN)
        begin
                counter_spaden <= counter_spaden + 3'd1;
        end
        else        
                counter_spaden <= 3'd0;

end

always@( posedge clk_in or negedge rst )
begin
        if( !rst ) digit_counter <= 2'd0;
        else if(en)
        begin
                digit_counter <= digit_counter + 2'd1;
        end
        else
                digit_counter <= 0;
end

endmodule