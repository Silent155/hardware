module geofence (
 
        clk,reset,X,Y,
     
        valid,is_inside
);    

//  INPUT AND OUTPUT                        
   
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;


// parameters

parameter IDLE = 4'd0, IN_OBJ = 4'd1, IN = 4'd2,DELAY1=4'd3 ,IS_NEG = 4'd4,ORDER = 4'd5;
parameter DELAY2=4'd6,DELAY3=4'd7,DELAY4=4'd8, IS_INSIDE = 4'd9,DELAY5=4'd10, OUT = 4'd11, RESET = 4'd12;


//  Wires & Registers

reg [3:0] state=4'b0;
reg [3:0] next_state=4'b0;
reg [9:0] obj_x, obj_y;
reg [9:0] x[0:5];
reg [9:0] y[0:5];
reg [2:0] counter_IN=3'b0;
reg [1:0] counter_circle=2'b0, counter_repeat=2'b0;

reg signed [10:0] Ax, Bx, Ay, By;
wire signed [20:0] AxBy, BxAy;
wire signed [20:0] x01y,x10y,x12y,x21y,x23y,x32y,x34y,x43y,x45y,x54y,x50y,x05y;
wire [2:0] counter_A, counter_B;
reg [5:0] before_array=6'b0;
reg [5:0] inside_array=6'b0;



//assign
assign AxBy = Ax * By;
assign BxAy = Bx * Ay;

assign x01y=(x[ 0 ]-obj_x)*(y[ 1 ]-y[ 0 ]);
assign x10y=(x[ 1 ]-x[ 0 ])*(y[ 0 ]-obj_y);

assign x12y=(x[ 1 ]-obj_x)*(y[ 2 ]-y[ 1 ]);
assign x21y=(x[ 2 ]-x[ 1 ])*(y[ 1 ]-obj_y);

assign x23y=(x[ 2 ]-obj_x)*(y[ 3 ]-y[ 2 ]);
assign x32y=(x[ 3 ]-x[ 2 ])*(y[ 2 ]-obj_y);

assign x34y=(x[ 3 ]-obj_x)*(y[ 4 ]-y[ 3 ]);
assign x43y=(x[ 4 ]-x[ 3 ])*(y[ 3 ]-obj_y);

assign x45y=(x[ 4 ]-obj_x)*(y[ 5 ]-y[ 4 ]);
assign x54y=(x[ 5 ]-x[ 4 ])*(y[ 4 ]-obj_y);

assign x50y=(x[ 5 ]-obj_x)*(y[ 0 ]-y[ 5 ]);
assign x05y=(x[ 0 ]-x[ 5 ])*(y[ 5 ]-obj_y);


assign counter_A = counter_circle + 3'd1;
assign counter_B = counter_circle + 3'd2;
reg is_neg=1'b0;


//Ax, Bx, Ay, By
always@(posedge clk or posedge reset)
begin
	if(reset)
	begin
                Ax <= 11'd0; Bx <= 11'd0; Ay <= 11'd0; By <= 11'd0;
        end
        else begin
	case(state)
		DELAY1:
			begin
		        Ax <= x[ counter_A ]-x[ 0 ];
		        Bx <= x[ counter_B ]-x[ 0 ];
		        Ay <= y[ counter_A ]-y[ 0 ];
		        By <= y[ counter_B ]-y[ 0 ];

			end
		IS_NEG:  begin
			if(AxBy > BxAy) is_neg=1'b1;
			else is_neg=1'b0;end
		ORDER:
			begin
			Ax <= Ax ;
			Bx <= Bx ;
			Ay <= Ay ;
			By <= By ;end
		default:begin	
			Ax <= 11'd0; Bx <= 11'd0; Ay <= 11'd0; By <= 11'd0;is_neg=1'b0;end      
		
	endcase
	end
end


//  OUTPUT : valid & is_inside

always@( posedge clk or posedge reset )
begin
        if( reset )
        begin
                valid <= 1'd0;
                is_inside <= 1'd0;
        end
        else if( state == OUT )
        begin
                valid <= 1'd1;
                if( inside_array == 6'b00_0000 )is_inside <= 1'd1;
                else is_inside <= 1'd0;
        end    
        else
        begin
                valid <= 1'd0;
                is_inside <= 1'd0;
        end
end


//  inside_array

always@( posedge clk or posedge reset)
begin
	if(reset)
	begin
	inside_array <= 6'b00_0000;
	before_array <= 6'b00_0000;
	end
        else if( state == IS_INSIDE )
        begin
                if( x01y > x10y ) before_array[ 0 ] <= 1'd1;
                else before_array[ 0 ] <= 1'd0;
		if( x12y > x21y ) before_array[ 1 ] <= 1'd1;
                else before_array[ 1 ] <= 1'd0;
		if( x23y > x32y ) before_array[ 2 ] <= 1'd1;
                else before_array[ 2 ] <= 1'd0;
		if( x34y > x43y ) before_array[ 3 ] <= 1'd1;
                else before_array[ 3 ] <= 1'd0;
		if( x45y > x54y ) before_array[ 4 ] <= 1'd1;
                else before_array[ 4 ] <= 1'd0;
		if( x50y > x05y ) before_array[ 5 ] <= 1'd1;
                else before_array[ 5 ] <= 1'd0;
        end
	else if( state == DELAY5 )
        begin
                if( before_array[0] ) inside_array[ 0 ] <= 1'd1;
                else inside_array[ 0 ] <= 1'd0;
		if( before_array[1] ) inside_array[ 1 ] <= 1'd1;
                else inside_array[ 1 ] <= 1'd0;
		if( before_array[2] ) inside_array[ 2 ] <= 1'd1;
                else inside_array[ 2 ] <= 1'd0;
		if( before_array[3] ) inside_array[ 3 ] <= 1'd1;
                else inside_array[ 3 ] <= 1'd0;
		if( before_array[4] ) inside_array[ 4 ] <= 1'd1;
                else inside_array[ 4 ] <= 1'd0;
		if( before_array[5] ) inside_array[ 5 ] <= 1'd1;
                else inside_array[ 5 ] <= 1'd0;
        end
	else begin
		inside_array <= 6'b00_0000;
		before_array <= 6'b00_0000;end
end


//  INPUT


//obj_x, obj_y
always@( posedge clk or posedge reset )
begin
        if( reset )
        begin
                obj_x <= 10'd0; obj_y <= 10'd0;
        end
        else if( state == IDLE || state == IN_OBJ )
        begin
                obj_x <= X; obj_y <= Y;
        end
	else begin obj_x <= obj_x; obj_y <= obj_y;end
end

//x,y
always@( posedge clk or posedge reset)
begin
	if(reset)begin
			x[0]<=10'd0; 
			x[1]<=10'd0;   
			x[2]<=10'd0;   
			x[3]<=10'd0;   
			x[4]<=10'd0;   
			x[5]<=10'd0; 
			y[0]<=10'd0; 
			y[1]<=10'd0;   
			y[2]<=10'd0;   
			y[3]<=10'd0;   
			y[4]<=10'd0;   
			y[5]<=10'd0;end 
	else begin
	case(state)
		IN:begin
		        x[ counter_IN ] <= X; y[ counter_IN ] <= Y;
			end
		ORDER: begin
                if( is_neg )
                begin
                        x[ counter_A ] <= x[ counter_B ];
                        y[ counter_A ] <= y[ counter_B ];
                        x[ counter_B ] <= x[ counter_A ];
                        y[ counter_B ] <= y[ counter_A ];
                end
		else
		begin
			x[ counter_A ] <= x[ counter_A ];
                        y[ counter_A ] <= y[ counter_A ];
                        x[ counter_B ] <= x[ counter_B ];
                        y[ counter_B ] <= y[ counter_B ];end
       		end 
		RESET:begin
			x[0]<=10'd0; 
			x[1]<=10'd0;   
			x[2]<=10'd0;   
			x[3]<=10'd0;   
			x[4]<=10'd0;   
			x[5]<=10'd0; 
			y[0]<=10'd0; 
			y[1]<=10'd0;   
			y[2]<=10'd0;   
			y[3]<=10'd0;   
			y[4]<=10'd0;   
			y[5]<=10'd0;end 
		default:
			begin
		 	x[0]<=x[0]; 
			x[1]<=x[1];   
			x[2]<=x[2];   
			x[3]<=x[3];   
			x[4]<=x[4];   
			x[5]<=x[5]; 
			y[0]<=y[0]; 
			y[1]<=y[1];   
			y[2]<=y[2];   
			y[3]<=y[3];   
			y[4]<=y[4];   
			y[5]<=y[5]; 
			end 
		endcase
end
	
end


//  counter_IN

always@( posedge clk or posedge reset )
begin
        if( reset ) counter_IN <= 3'd0;
        else if( state == IN ) counter_IN <= ( counter_IN == 3'd6 )? 3'd0 : counter_IN + 3'd1;
	else counter_IN <= 3'd0;
end


//  counter_circle

always@( posedge clk or posedge reset )
begin
        if( reset ) counter_circle <= 2'd0;
        else if( state == IN ) counter_circle <= 2'd0;
        else if( state == ORDER ) counter_circle <= ( counter_circle == 2'd3 )? 2'd0 : counter_circle + 2'd1;
	else counter_circle <= counter_circle ;
end




//  counter_repeat

always@( posedge clk or posedge reset )
begin
        if( reset ) counter_repeat <= 2'd0;
        else begin
	case(state)
		IN:	counter_repeat <= 2'd0;
		ORDER:
		begin
                if( counter_circle == 2'd3 ) counter_repeat <= counter_repeat + 2'd1;
		else counter_repeat <= counter_repeat ;
        	end
		IS_INSIDE:counter_repeat <= 2'd0;
		default:counter_repeat <= counter_repeat ;
	endcase
	end
end


//  FSM

always@( posedge clk or posedge reset )
begin
        if( reset ) state <= IDLE;
        else state <= next_state;
end

always@( * )
begin
        case( state )
        IDLE:           next_state = IN;
        IN_OBJ:         next_state = IN;
        IN:             next_state = ( counter_IN == 3'd6 )? DELAY1 : IN ;
	DELAY1: 	next_state = IS_NEG;
	IS_NEG:		next_state = ORDER;
        ORDER:   	next_state = ( counter_repeat == 2'd3 && counter_circle == 2'd3 )? DELAY2 : DELAY1 ;
	DELAY2: 	next_state = DELAY3;
	DELAY3: 	next_state = DELAY4;
	DELAY4:		next_state = IS_INSIDE;
        IS_INSIDE:      next_state = DELAY5;
	DELAY5:		next_state = OUT;
	OUT: 		next_state = RESET;
        RESET: 		next_state = IN_OBJ;
        default:        next_state = IDLE;
        endcase
end

endmodule
