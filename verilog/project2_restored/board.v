module board(clk,clk2,display,grounds,rowwrite,colread);
output[3:0] rowwrite;
input [3:0] colread;
wire [11:0] address;
input clk;
input clk2;
wire memwt;

output wire[6:0] display;
output wire[3:0] grounds;

reg [15:0] data_in;
wire [15:0] data_out;
wire [15:0]ramOut;

reg [25:0] clk3;
always @(posedge clk2)
    clk3<=clk3+1;
initial clk3=0;

wire[3:0] keyout;
reg [15:0] data_all;
reg [1:0] ready_buffer;
reg ack;
reg statusordata;
wire[15:0] reg0;
localparam	BEGINMEM=12'h000,
		ENDMEM=12'h05f,
		KEYPAD=12'h060,
		SEVENSEG=12'h070;

always @(*)
	if ( (BEGINMEM<=address) && (address<=ENDMEM) )
		begin
			data_in=ramOut;
			ack=0;
			statusordata=0;
		end
	else if (address==KEYPAD+1)
		begin	
			statusordata=1;
			data_in=keyout;
			ack=0;
		end
	else if (address==KEYPAD)
		begin
			statusordata=0;
			data_in=keyout;
			ack=1;
		end
	else
		begin
			data_in=16'hf345; //any number
			ack=0;
			statusordata=0;
		end

wire cMain;
assign cMain= clk2;

always@(posedge cMain)
	if (memwt &&SEVENSEG==address )
			data_all<=data_out;

	
ram ram1(.din(data_out),.address(address),.memwt(memwt),.clk(cMain),.dout(ramOut));
processor cpu(.clk(cMain),.data_out(data_out),.data_in(data_in),.address(address),.memwt(memwt));
keypad  kp1(.rowwrite(rowwrite),.colread(colread),.clk(cMain),.keyout(keyout),.statusordata(statusordata),.ack(ack));
sevensegment sseg(.datain(data_all),.grounds(grounds),.display(display),.clk(clk2));


initial begin
data_all=0;
end
endmodule

module ram
(	
	input [15:0] din,
	input [11:0] address,
	input memwt, clk,
	output [15:0] dout);
	reg [15:0] ram[0:127];
	integer i;
initial begin
            for (i=0;i<128;i=i+1)
            begin
                ram[i]=16'h0;  
            end                       
            $readmemh("C:/intelFPGA_lite/18.0/RAM.txt", ram);
          end
	
	localparam	BEGINMEM=12'h000,
		ENDMEM=12'h5f;
		
	always @(posedge clk)
	begin
			if (memwt &&( (BEGINMEM<=address) && (address<=ENDMEM) ))
			ram[address]<=din;
		end
	assign dout = ram[address];
endmodule






