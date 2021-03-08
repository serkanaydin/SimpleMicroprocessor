module processor( clk, data_out, data_in, address, memwt);
    input clk;
    input [15:0] data_in;
    output reg[15:0] data_out;
    output reg [11:0] address;
    output wire memwt;
 
    reg [11:0]  ir;
    reg [11:0] pc;
    reg [3:0]  state;
    reg [15:0] regbank [7:0];
    reg [15:0] result;
 
 
     localparam   FETCH=4'b0000,
                  LDI=4'b0001,
                  LD=4'b0010,
                  ST=4'b0011,
                  JZ=4'b0100,
                  JMP=4'b0101,
                  ALU=4'b0111,
						PUSH=4'b1000,
						POP=4'b1001,
						CALL=4'b1010,
						RET=4'b1011,
						POP2=4'b1100,
						RET2=4'b1101;
 
 
   wire intflag;
	wire zeroresult;
   always @(posedge clk)
        case(state)
 
            FETCH: 
            begin
                if ( data_in[15:12]==JZ) 
                    if (regbank[6][0])
                        state <= JMP;
                    else
                        state <= FETCH;
                else
                    state <= data_in[15:12];
                ir<=data_in[11:0];
                pc<=pc+1;
            end
 
            LDI:
            begin
                regbank[ ir[2:0] ] <= data_in;
                pc<=pc+1;
                state <= FETCH;
            end
 
 
            LD:
                begin
                    regbank[ ir[2:0] ] <= data_in;
                    state <= FETCH;  
                end 
 
            ST:
                begin
                    state <= FETCH;  
                end    
 
            JMP:
                begin
                    pc <= pc+ir;
                    state <= FETCH;  
                end          
 
            ALU:
                begin
                    regbank[ir[2:0]]<=result;
                    regbank[6][0]<=zeroresult;
                    state <= FETCH;
                end
			   PUSH: 
					begin
				      regbank[7]<=regbank[7]-1;
						state<=FETCH;
						 end
				POP:
					begin
						regbank[7]<=regbank[7]+1;
				      state<=POP2;
					end
				POP2:
				   begin
						regbank[ir[2:0]]<=data_in;
						state<=FETCH;
						 end
				CALL:
					begin
						regbank[7]<=regbank[7]-1;
						pc<=pc+ir;
						state<=FETCH;
					end
				RET:
					begin
						regbank[7]<=regbank[7]+1;
						state<=RET2;
					end
				RET2:
					begin
						pc<=data_in;
						state<=FETCH;
					end
        endcase
 
 
    always @*   
	 begin

        case (state)
		      PUSH:    begin 
								address=regbank[7][11:0];
								data_out=regbank[ ir[5:3] ]; 
							end
							
				POP2:    begin address=regbank[7][11:0];
				data_out=regbank[ ir[8:6] ]; end
				CALL:    
							begin 
								address=regbank[7][11:0];
								data_out=pc;	
							end
				RET2:    begin address=regbank[7][11:0];
				data_out=regbank[ ir[8:6] ]; end
            LD:      begin address=regbank[ir[5:3]][11:0];
				data_out=regbank[ ir[8:6] ]; end
            ST:      begin address=regbank[ir[5:3]][11:0];
				data_out=regbank[ ir[8:6] ]; end
            default: 				
							begin 
								address=pc;
				            data_out=regbank[ ir[8:6] ]; 
							end
         endcase
	 end 
 
 
    assign memwt=(state==ST)|(state==PUSH)|(state==CALL);
 
    always @*
        case (ir[11:9])
            3'h0: result = regbank[ir[8:6]]+regbank[ir[5:3]];
            3'h1: result = regbank[ir[8:6]]-regbank[ir[5:3]];
            3'h2: result = regbank[ir[8:6]]&regbank[ir[5:3]];
            3'h3: result = regbank[ir[8:6]]|regbank[ir[5:3]];
            3'h4: result = regbank[ir[8:6]]^regbank[ir[5:3]];
            3'h7: case (ir[8:6])
                        3'h0: result = !regbank[ir[5:3]];
                        3'h1: result = regbank[ir[5:3]];
                        3'h2: result = regbank[ir[5:3]]+1;
                        3'h3: result = regbank[ir[5:3]]-1;
                        default: result=16'h0000;
                    endcase
            default: result=16'h0000;
        endcase
	assign zeroresult = ~|result;
    initial begin
      state=FETCH;
		pc=0;
		regbank[0]=0;
		regbank[1]=0;
		regbank[2]=0;
		regbank[3]=0;
		regbank[4]=0;
		regbank[5]=0;
		regbank[6]=0;
		regbank[7]=0;
		end
		
endmodule