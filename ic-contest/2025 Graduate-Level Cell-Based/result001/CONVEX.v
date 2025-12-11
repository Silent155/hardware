/*******************************************************
//MODULE:        CONVEX 
//FILE NAME:     CONVEX_finish_jumpsome.v
//DATE:          APRIL 5, 2025
//AUTHOR:        PO-HSIANG CHIU
//CODE TYPE:     RTL or Behavioral Level
//DESCRIPTION:   all pass
//@COPYRIGHT 2025 NCHU LAB612
//ALL RIGHT RESERVED
//
//MODIFICATION HISTORY:
//Date:2025/04/09           

Discription:normal memory number,read count-2,
delete TRANS2 count-1,
get read_pt to idle,delete nouse.
delete TRANS count-1,
change drop_counter to wire  
***drop first then renew memory
delete memory2
delete TRANS3
change x_h to combinationala
delete nouse
//04/8/2025
******************************************************/


module CONVEX(
input CLK,
input RST,
input [4:0] PT_XY,
output reg READ_PT=0,
output reg [9:0] DROP_XY,
output reg DROP_V);

localparam IDLE     = 'd0;
localparam READ     = 'd1;
localparam COMPUTE  = 'd2;
localparam TRANS    = 'd3;
localparam DROP2    = 'd4;
localparam DROP     = 'd5;

reg [9:0]DROP_XY_FIRST;

//////////////////////////////////////////////////
reg signed[21:0] dot1;
reg signed[21:0] dot2;
reg [9:0] x [0:11];
reg [9:0] y [0:11];

reg [3:0]count;

reg [2:0] state;
reg [2:0] next_state;

// 假設座標均為 10 bits signed，相減後用 11 bits 表示
wire signed [10:0] dx32, dy32, dx21, dy21;
wire signed [21:0] cross_turn;
reg [3:0] dot_counter;//account dot
reg [3:0]countdown;
// 計算第三點到第二點的向量分量
assign dx32 = x[1] - x[2];
assign dy32 = y[1] - y[2];

// 計算第二點到第一點的向量分量
assign dx21 = x[0] - x[2];
assign dy21 = y[0] - y[2];
wire signed[21:0]cross_32_31;
// 計算兩向量的外積
assign cross_32_31 = dx32 * dy21 - dy32 * dx21;

// 判斷是否逆時針：若外積 > 0，則轉彎為逆時針


always @(posedge CLK or posedge RST) begin
        if(RST)
	    countdown<=0;
    	else if(state==COMPUTE)
            countdown<=countdown-'d1;
        else
            countdown<=dot_counter-'d2;
    
end




reg [9:0]x_new,y_new;


reg signed[3:0] sum1,negative3,zero3;
reg negative1,negative2,zero1,zero2;
reg signed [1:0]position [0:11];
reg same_line_drop_old_idx1;
reg same_line_drop_old_idx2;
reg [3:0] same_line_drop_old_idx3;
reg [3:0] negative_idx;
wire [3:0] negative_idx2;
assign negative_idx2=(position[1]<0)?'d1:negative_idx;

wire signed [3:0]sum2;
wire [3:0]negative,zero;
assign sum2=sum1+position[0]+position[1];
assign negative=negative1+negative2+negative3;
assign zero=zero1+zero2+zero3;
reg same_line_drop_new_flag,same_line_drop_old_flag,inside_flag,same_point_flag;
wire same_line_drop_new_flag2,same_line_drop_old_flag2,inside_flag2,same_point_flag2;
assign same_line_drop_new_flag2=(state==TRANS)? (((sum2==(dot_counter-'d2)))?'d1:'d0):0;
assign same_line_drop_old_flag2=(state==TRANS)?(((sum2==(dot_counter-'d4)))?'d1:'d0):0;
assign same_point_flag2=(state==TRANS)?(((sum2==(dot_counter-'d3))&&(negative=='d0))?'d1:'d0):0;
assign inside_flag2=(state==TRANS)?(((sum2==(dot_counter-'d1)))?'d1:'d0):0;
always @(posedge CLK or posedge RST) begin
        if(RST)
	    same_line_drop_new_flag<=0;
    	else if(state==TRANS)
            same_line_drop_new_flag<=same_line_drop_new_flag2;
        else
            same_line_drop_new_flag<=same_line_drop_new_flag;
    
end
always @(posedge CLK or posedge RST) begin
        if(RST)
	    same_line_drop_old_flag<=0;
 	else if(state==TRANS)
            same_line_drop_old_flag<=same_line_drop_old_flag2;
        else
            same_line_drop_old_flag<=same_line_drop_old_flag;
    
end
always @(posedge CLK or posedge RST) begin
    
    	if(RST)
	    same_point_flag<=0;
        else if(state==TRANS)
            same_point_flag<=same_point_flag2;
        else
            same_point_flag<=same_point_flag;
    
end

always @(posedge CLK or posedge RST) begin
	if(RST)
	    inside_flag<=0;
    	else if(state==TRANS)
            inside_flag<=inside_flag2;
        else
            inside_flag<=inside_flag;
    
    
end

assign outside_flag=(state==TRANS)?((same_line_drop_new_flag2||same_line_drop_old_flag2||same_point_flag2||inside_flag2)?'d0:'d1):
((same_line_drop_new_flag||same_line_drop_old_flag||same_point_flag||inside_flag)?'d0:'d1);

wire [3:0]same_line_drop_old_idx;
reg [3:0]same_line_drop_old_idx_final;
reg t1;

assign same_line_drop_old_idx=(same_line_drop_old_idx3)? same_line_drop_old_idx3:t1;


reg [2:0] drop_counter;
reg [2:0] drop_odd3_counter;
reg [1:0]outside_odd_flag;
reg [2:0]drop_final_counter;

always @(posedge CLK or posedge RST) begin
    if (RST) 
        t1<='d0;
    else if(state==COMPUTE) begin
            if(same_line_drop_old_idx1) begin
                
                t1<='d1;
                
    
                    end
            else
                t1<='d0;
    end
end

always @(posedge CLK or posedge RST) begin
    if (RST) 
        same_line_drop_old_idx_final<='d0;
    else if(state==TRANS) begin
            if((dot1>0)&&(dot2>0)) begin
                
                    same_line_drop_old_idx_final<=same_line_drop_old_idx-'d1;
                
    
                    end
            else
                same_line_drop_old_idx_final<=same_line_drop_old_idx;
    end
end


//fsm_flag
wire read_done = ((count == 'd4)&&(dot_counter>'d3))?'d1:'d0;


wire compute_done=((countdown=='d2))?'d1:'d0;

wire drop_done=((negative+zero=='d1)?
                    ((count==dot_counter-negative_idx2-'d2)?'d1:'d0)  :  
                        (((outside_odd_flag=='d2)&&(count==negative+zero-'d3))?
                                                                                'd1:((count=='d0)?'d1:'d0)) );


wire drop2_done=((drop_final_counter=='d1)&&(count=='d1))?'d1:'d0;

always @(*) begin
    
        if(same_line_drop_old_idx>0)begin
            dot1=(x[same_line_drop_old_idx-'d1]-x[same_line_drop_old_idx])*(x_new-x[same_line_drop_old_idx])
                +(y[same_line_drop_old_idx-'d1]-y[same_line_drop_old_idx])*(y_new-y[same_line_drop_old_idx]);
            dot2=(x[same_line_drop_old_idx-'d1]-x_new)*(x[same_line_drop_old_idx-'d1]-x_new)
                +(y[same_line_drop_old_idx-'d1]-y_new)*(y[same_line_drop_old_idx-'d1]-y_new);
        end
        else begin
            dot1=(x[dot_counter-'d2]-x[0])*(x_new-x[0])
                +(y[dot_counter-'d2]-y[0])*(y_new-y[0]);
            dot2=(x[dot_counter-'d2]-x_new)*(x[0]-x_new)
                +(y[dot_counter-'d2]-y_new)*(y[0]-y_new);
        end
    
    
end

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        count <= 'd0;
    end
    else begin
        case(state)
            READ:begin
                if(count=='d4||read_done)
                    count<='d0;
                else
                    count<=count+'d1;
            end
            COMPUTE:begin
                if(compute_done)
                    count<='d0;
                else
                    count<=count+'d1;
            end
            DROP:begin
                if(drop_done)
                    count<='d0;
                else
                    count<=count+'d1;
            end
            DROP2:begin
                if(count=='d1)
                    count<='d0;
                else
                    count<=count+'d1;
            end
            default:count <= 'd0;
        endcase
    end
end


//FSM
always @(*) begin
    case(state)
        IDLE     : next_state = READ;
        READ     : next_state = read_done ? COMPUTE:((count=='d4)?IDLE : READ);
        COMPUTE  : next_state = compute_done ? TRANS : COMPUTE;
        TRANS    : next_state = (outside_flag&&(negative+zero=='d1))?
                                ((position[0]<0)?IDLE:DROP):DROP2;
        DROP2    : next_state = (drop2_done&&count=='d1)? 
                                (((outside_flag&&outside_odd_flag=='d2))?DROP:IDLE) : DROP2;
        DROP     : next_state = drop_done? IDLE : DROP;
           
        default  : next_state = IDLE;
    endcase
end

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        state <= IDLE;    
    end
    else begin
        state <= next_state;
    end
end

//READ_PT
always @(*) begin
    
        
    
    if (state == IDLE) begin
        READ_PT = 'd1;
    end
    else  begin
        READ_PT = 'd0;
    end
end
//memory

//memory1
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        x[0] <= 'd0;
        x[1] <= 'd0;
        x[2] <= 'd0;
        x[3] <= 'd0;
        x[4] <= 'd0;
        x[5] <= 'd0;
        x[6] <= 'd0;
        x[7] <= 'd0;
        x[8] <= 'd0;
        x[9] <= 'd0;
        x[10] <= 'd0;
        x[11] <= 'd0;
          
        y[0] <= 'd0;
        y[1] <= 'd0;
        y[2] <= 'd0;
        y[3] <= 'd0;
        y[4] <= 'd0;
        y[5] <= 'd0;
        y[6] <= 'd0;
        y[7] <= 'd0;
        y[8] <= 'd0;
        y[9] <= 'd0;
        y[10] <= 'd0;
        y[11] <= 'd0;   
    end
    else begin 
        case(state) 
            READ:begin
                case(count) 
                    'd0:begin
                            if(same_line_drop_old_flag)begin
                                        x[same_line_drop_old_idx_final]<=x_new;
                                        y[same_line_drop_old_idx_final]<=y_new;
                                        end
                            else begin
                                    case(outside_odd_flag)
                                        2'd1:begin
                                                x[dot_counter+drop_counter-negative+'d1]<='d0;
                                                y[dot_counter+drop_counter-negative+'d1]<='d0;
                                            end
                                
                                                endcase
                            end
                        end
                    'd4:begin
                        if(dot_counter<='d3) begin
                            x[dot_counter-'d1]<=x_new;
                            y[dot_counter-'d1]<=y_new;end
                        else begin
                            if(cross_32_31[21]=='d1)begin
                                x[2]<=x[1];
                                x[1]<=x[2];
                                y[2]<=y[1];
                                y[1]<=y[2];
                            end
                            else begin
                                x[2]<=x[2];
                                x[1]<=x[1];
                                y[2]<=y[2];
                                y[1]<=y[1];
                            end
                        end

                    end

                endcase
                
                
            end
            
            TRANS:begin
                if(outside_flag&&(negative+zero=='d1)&&(position[0]<0))
                    begin
                    x[dot_counter-'d1]<=x_new;
                    y[dot_counter-'d1]<=y_new;end
            end

            DROP:begin
                    if((negative+zero)>1)begin
                        case(outside_odd_flag)
                            2'd2:begin
                                if(negative+zero>'d2)begin
                                    x[negative-'d2]<=x_new;
                                    y[negative-'d2]<=y_new;
                                    x[negative-'d3-count]<=x[dot_counter+drop_counter-'d2-count];
                                    y[negative-'d3-count]<=y[dot_counter+drop_counter-'d2-count];
                                    end
                                else begin
                                    x[0]<=x_new;
                                    y[0]<=y_new;
                                end
                            end
                            default:begin
                                x[count]<=x[count];
                                y[count]<=y[count];
                            end
                        endcase
                    end
                    else begin
                            x[dot_counter-'d1-count]<=x[dot_counter-'d2-count];
                            y[dot_counter-'d1-count]<=y[dot_counter-'d2-count];
                    end
                end

            

            IDLE:begin
                if(drop_counter>'d0||(outside_flag&&negative+zero=='d1))begin
               
                    if(outside_flag)begin
                        if((negative+zero)>1)begin
                            case(outside_odd_flag)

                                2'd0:begin
                                    if((negative+zero>'d2)&&(position[1]>=0))begin
                                        x[negative_idx]<=x_new;
                                        y[negative_idx]<=y_new;
                                        x[negative_idx+'d1]<=x[negative_idx+negative+zero-'d1];
                                        y[negative_idx+'d1]<=y[negative_idx+negative+zero-'d1];
                                        x[negative_idx+'d2]<=x[negative_idx+negative+zero];
                                        y[negative_idx+'d2]<=y[negative_idx+negative+zero];
                                        
                                        x[negative_idx+'d3]<=x[negative_idx+negative+zero+'d1];
                                        y[negative_idx+'d3]<=y[negative_idx+negative+zero+'d1];
                                        x[negative_idx+'d4]<=x[negative_idx+negative+zero+'d2];
                                        y[negative_idx+'d4]<=y[negative_idx+negative+zero+'d2];
                                        x[negative_idx+'d5]<=x[negative_idx+negative+zero+'d3];
                                        y[negative_idx+'d5]<=y[negative_idx+negative+zero+'d3];
                                        
                                        
                                    
                                        end
                                    else if(position[1]>=0)begin
                                        x[negative_idx]<=x_new;
                                        y[negative_idx]<=y_new;
                                    end
                                    else if(negative+zero>'d2)begin
                                        x[1]<=x_new;
                                        y[1]<=y_new;
                                        x[2]<=x[negative+zero];
                                        y[2]<=y[negative+zero];
                                        x[3]<=x[negative+zero+'d1];
                                        y[3]<=y[negative+zero+'d1];
                                        x[4]<=x[negative+zero+'d2];
                                        y[4]<=y[negative+zero+'d2];
                                        x[5]<=x[negative+zero+'d3];
                                        y[5]<=y[negative+zero+'d3];
                                        x[6]<=x[negative+zero+'d4];
                                        y[6]<=y[negative+zero+'d4];
                                        x[7]<=x[negative+zero+'d5];
                                        y[7]<=y[negative+zero+'d5];
                                                                        
                                        end
                                    else begin
                                        x[1]<=x_new;
                                        y[1]<=y_new;
                                    end
                                end
                            
                                2'd1:begin
                                    if(position[1]>=0) begin
                                        x[negative_idx]<=x_new;
                                        y[negative_idx]<=y_new;                        
                                    end
                                    else if(position[2]>=0)begin
                                        x[0]<=x_new;
                                        y[0]<=y_new;                              
                                    end
                                    else if(position[3]>=0)begin
                                        x[1]<=x_new;
                                        y[1]<=y_new;
                                        x[0]<=x[dot_counter+drop_counter-negative+'d1];
                                        y[0]<=y[dot_counter+drop_counter-negative+'d1];                       
                                    end
                                    else if(position[4]>=0)begin
                                        x[2]<=x_new;
                                        y[2]<=y_new;
                                        x[1]<=x[dot_counter+drop_counter-negative+'d2];
                                        y[1]<=y[dot_counter+drop_counter-negative+'d2];
                                        x[0]<=x[dot_counter+drop_counter-negative+'d1];
                                        y[0]<=y[dot_counter+drop_counter-negative+'d1];   
                                    end
                                    
                                    end
                                2'd3:begin
                                    x[negative_idx]<=x_new;
                                    y[negative_idx]<=y_new;
                                    x[negative_idx+'d1]<=x[dot_counter+drop_counter-'d2];
                                    y[negative_idx+'d1]<=y[dot_counter+drop_counter-'d2];end
                                
                            endcase
                        end
                        else begin
                            if(position[0]>=0) begin
                                x[negative_idx2]<=x_new;
                                y[negative_idx2]<=y_new;
                            end
                        end            
                    end
            end
            end
        endcase
    end
end
    

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        dot_counter <= 'd0;
    end
    else if (state == IDLE) begin
        dot_counter <= READ_PT ? (dot_counter + 'd1) : dot_counter;
    end
    else if (state == DROP2) begin
        dot_counter <= DROP_V ? (dot_counter - 'd1) : dot_counter;
    end
    else  begin
        dot_counter <= dot_counter;
    end
end

//read

always @(posedge CLK or posedge RST) begin
    if(RST)begin
        x_new <= 0;
        y_new <= 0;	
        end        
    else if (state == READ) begin
        case(count)
            'd0:begin 
                x_new[9:5] <= PT_XY;
		        y_new<=y_new; end
            'd1:begin
		        x_new[4:0] <= PT_XY;
                y_new<=y_new;
		        end
            'd2:begin
                x_new<=x_new;
		        y_new[9:5] <= PT_XY;
		         end
            'd3:begin
                x_new<=x_new;
		        y_new[4:0] <= PT_XY; end
            default:begin
                x_new<=x_new;
                y_new<=y_new;
                 end
        endcase
    end
    
end



//counter




//compute
// 先定義中間連線（注意：向量分量用 11 bits 可以容納相減後的範圍）
wire signed [10:0] dx1_1, dy1_1, dx2_1, dy2_1;
wire signed [21:0] cross_temp1;

// 計算向量分量：
// 向量 AB = B - A
assign dx1_1 = x[0] - x[1];
assign dy1_1 = y[0] - y[1];

// 向量 AC = C - A
assign dx2_1 = x_new - x[1];
assign dy2_1 = y_new - y[1];

// 計算外積 (B-A) x (C-A)
assign cross_temp1 = dx1_1 * dy2_1 - dy1_1 * dx2_1;

// 根據 state 是否為 COMPUTE 決定輸出
wire signed [21:0] cross_position1;
assign cross_position1 = (state == COMPUTE) ? cross_temp1 : 'd0;


// 先定義中間連線（注意位寬必須足夠）
// A = (x[0], y[0])
// B = (x[dot_counter-'d2], y[dot_counter-'d2])
// C = (x_new, y_new)
wire signed [10:0] dx1_0, dy1_0, dx2_0, dy2_0;
wire signed [21:0] cross_temp0;

// 計算向量分量：
// 向量 AB 分量
assign dx1_0 = x[dot_counter-'d2] - x[0];
assign dy1_0 = y[dot_counter-'d2] - y[0];
// 向量 AC 分量
assign dx2_0 = x_new - x[0];
assign dy2_0 = y_new - y[0];

// 計算外積
assign cross_temp0 = dx1_0 * dy2_0 - dy1_0 * dx2_0;

// 根據 state 判斷是否計算外積
wire signed [21:0] cross_position0;
assign cross_position0 = (state == COMPUTE) ? cross_temp0 : 'd0;




// 定義內部連線，請依照您實際的模組宣告位置調整
wire signed [10:0] dx1, dy1, dx2, dy2;
wire signed [21:0] cross_temp;
wire signed [21:0] cross_position;
// 計算兩個向量的分量
// A = (x[countdown], y[countdown])
// B = (x[countdown-'d1], y[countdown-'d1])
// C = (x_new, y_new)
assign dx1 = x[countdown-'d1] - x[countdown];
assign dy1 = y[countdown-'d1] - y[countdown];
assign dx2 = x_new - x[countdown];
assign dy2 = y_new - y[countdown];

// 計算外積： (B-A) x (C-A) = dx1*dy2 - dy1*dx2
assign cross_temp = dx1 * dy2 - dy1 * dx2;

// 根據狀態決定輸出
assign cross_position = (state == COMPUTE) ? cross_temp : 'd0;




always @(posedge CLK or posedge RST) begin
    if (RST) begin
        same_line_drop_old_idx2<='d0;
        negative2<='d0;
        zero2<='d0;

        same_line_drop_old_idx1<='d0;
        negative1<='d0;
        zero1<='d0;end
    else if(state==COMPUTE) begin
        if(cross_temp1==0) begin
            
            same_line_drop_old_idx1<='d1;
            negative1<='d0;
            zero1<='d1;

            
        end
        else if(cross_temp1[21]=='d1) begin
            
            same_line_drop_old_idx1<='d0;
            negative1<='d1;
            zero1<='d0;
        end
        else begin
            
            same_line_drop_old_idx1<='d0;
            negative1<='d0;
            zero1<='d0;
        end

        if(cross_temp0==0) begin
            
            same_line_drop_old_idx2<='d1; 
            negative2<='d0;
            zero2<='d1;

        end
        else if(cross_temp0[21]=='d1)begin
            
            same_line_drop_old_idx2<='d0; 
            negative2<='d1;
            zero2<='d0;
        end
        else begin
            
           
            same_line_drop_old_idx2<='d0; 
            negative2<='d0;
            zero2<='d0;
           
        end

        end
    
   
end

wire signed [1:0] pos0 = (cross_temp0 == 0) ? 2'd0 :
                         (cross_temp0[21]) ? -2'd1 : 2'd1;
wire signed [1:0] pos1 = (cross_temp1 == 0) ? 2'd0 :
                         (cross_temp1[21]) ? -2'd1 : 2'd1;
wire signed [1:0] posN = (cross_temp  == 0) ? 2'd0 :
                         (cross_temp[21])  ? -2'd1 : 2'd1;

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        position[0] <= 2'd0;
        position[1] <= 2'd0;
        position[countdown] <= 2'd0;
    end else if (state == COMPUTE) begin
        position[0] <= pos0;
        position[1] <= pos1;
        position[countdown] <= posN;
    end
    
    
end

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        sum1<=4'd0;
        negative3<=4'd0;
        zero3<=4'd0;
        same_line_drop_old_idx3<='d0;
        negative_idx<='d0;end
    else if(state==COMPUTE) begin
        if(cross_temp==0) begin
            zero3<=zero3+'d1;
            same_line_drop_old_idx3<=countdown;
            negative_idx<=countdown;

        end
        else if(cross_temp[21]=='d1) begin
            sum1<=sum1-'d1;
            negative3<=negative3+'d1;
            same_line_drop_old_idx3<=same_line_drop_old_idx3;
            negative_idx<=countdown;
        end
        else begin
            sum1<=sum1+'d1;
        end
    end
    else if(state==READ) begin
        sum1<=4'd0;
        negative3<=4'd0;
        zero3<=4'd0;
        same_line_drop_old_idx3<='d0;
        negative_idx<='d0;end
end

//drop
wire [1:0]positive;
assign positive=(position[2]>=0)?'d1:
                    (position[3]>=0)?'d2:
                        (position[4]>=0)?'d3:
                            (position[5]>=0)?'d4:
                                (position[6]>=0)?'d5:'d0;


always @(posedge CLK or posedge RST) begin
    if (RST) 
        DROP_XY <= 'd0;
    else if (state == DROP2) begin
        if(inside_flag||same_line_drop_new_flag||inside_flag||same_point_flag) begin
                if(count==0)begin
                DROP_XY<=x_new;end
                else begin
                DROP_XY<=y_new;end
            end
        else if(same_line_drop_old_flag)begin
                if(count==0)
                DROP_XY<=x[same_line_drop_old_idx_final];
                else
                DROP_XY<=y[same_line_drop_old_idx_final]; 
            end
            
        else begin
        
            if(count==0)begin
                DROP_XY <= x[DROP_XY_FIRST];end
            else begin
            DROP_XY <= y[DROP_XY_FIRST];end end
    end
    else  begin
        DROP_XY <= 'd0;end
    
end


always @(*) begin
	if(state==DROP2)begin
	if(outside_flag)
	begin
            if((negative+zero)>1)begin
                case(outside_odd_flag)
                    2'd0:begin
                        if(position[1]>=0)begin
                   
                            DROP_XY_FIRST=negative_idx+negative+zero-'d1-drop_final_counter;
                         
                            end
                        else if((negative+zero)>'d2)begin
                            
                           
                            DROP_XY_FIRST=negative+zero-drop_final_counter;
                        end
                        else begin
                            
                            DROP_XY_FIRST='d1;
                            
                        end
                    end
                    2'd1:begin
                        if(position[1]>=0) begin
                            
                            DROP_XY_FIRST=negative_idx+drop_final_counter-'d1;
                            
                        end
                        else  begin
                                if(positive>drop_odd3_counter)begin
                                   
                                        DROP_XY_FIRST=drop_odd3_counter;end
                                else begin
                                  
                                        DROP_XY_FIRST=dot_counter-negative+drop_final_counter+drop_odd3_counter+positive-'d1;
                                    
                                        end
                                end
                        
                        end
                    2'd2:begin
                        
                            if(drop_final_counter==drop_counter)
                                    
                                        DROP_XY_FIRST=0;
                                    
                                else 
                                    
                                        DROP_XY_FIRST=drop_final_counter;
                            
                        
                    end
                    2'd3:begin
                        
                            DROP_XY_FIRST=dot_counter-'d2-drop_counter+drop_odd3_counter+drop_odd3_counter;
                    end
                    default:begin
                        DROP_XY_FIRST=0;
                    end
                endcase
            end
	    else DROP_XY_FIRST=0;
        end
       
        
        else 
	 begin
            
            DROP_XY_FIRST=0;
        end
    end
	else DROP_XY_FIRST=0;
end
//outside_drop
reg [1:0]outside_odd_flag2;
always @(*) begin
	
    
        if((position[0]>0)&&(position[dot_counter-'d2]>0))
            outside_odd_flag2='d0;//usually
        else if((position[0]<0)&&(position[dot_counter-'d2]<0))
            outside_odd_flag2='d1;
        else if((position[0]<0)&&(position[dot_counter-'d2]>0))
            outside_odd_flag2='d2;
        else
            outside_odd_flag2='d3;
    
end
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        outside_odd_flag <= 'd0;
    end
    else if(state==TRANS)
        outside_odd_flag <= outside_odd_flag2;
    else 
        outside_odd_flag <= outside_odd_flag;
    
end
//drop2
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        drop_odd3_counter <= 'd0;
    end
    else if(state==DROP2)begin
        if(count=='d1)
        drop_odd3_counter <= drop_odd3_counter+'d1;
        else
        drop_odd3_counter <= drop_odd3_counter;
        end
    else begin
        drop_odd3_counter <= 'd0;
    end
end


always @(posedge CLK or posedge RST) begin
    if (RST) begin
        drop_counter <= 'd0;
    end
    else if(state==TRANS)begin
	if(outside_flag)
            drop_counter <= negative+zero-'d1;
	else
	    drop_counter<='d1;
	end
    else begin
        drop_counter <= drop_counter;
    end
    
end


always @(posedge CLK or posedge RST) begin
    if (RST) begin
        drop_final_counter <= 'd0;
    end
    else if(state==TRANS)
	begin
        if(outside_flag)
            drop_final_counter <= negative+zero-'d1;
        else
            drop_final_counter<='d1;
	end
        
    else if ((state == DROP2)&(count=='d1)) begin
        drop_final_counter <= drop_final_counter-'d1;
    end
    
end

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        DROP_V <= 'd0;
    end
    else if ((state == DROP2)&(count=='d0)) begin
        DROP_V <= 'd1;
    end
    else  begin
        DROP_V <= 'd0;
    end
end

endmodule


