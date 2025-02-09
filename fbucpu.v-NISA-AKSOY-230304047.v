  module tb_fb_cpu;
 
    parameter TEST_CASE = 1;
    
    parameter ADDRESS_WIDTH = 6;
    parameter DATA_WIDTH = 10;
    
    reg clk = 1;
    reg rst;
    
    wire [ADDRESS_WIDTH-1:0] addr_toRAM;
    wire [DATA_WIDTH-1:0] data_toRAM, data_fromRAM;
    wire [ADDRESS_WIDTH-1:0] pCounter;
    wire wrEn;
 
    always clk = #5 !clk;
    
    reg error;
    
    initial begin
      rst = 1;
      error = 0;
      #100;
      rst <= #1 0;
      #5000;
      
      if(TEST_CASE == 1)
        memCheck(52,15);
      
      else if(TEST_CASE == 2)
        memCheck(52,50);
      
      else if(TEST_CASE == 3)
        memCheck(52,50);
      
      #100;
      $finish;
    end
    
    fb_cpu #(
        ADDRESS_WIDTH,
        DATA_WIDTH
    ) fb_cpu_Inst(
        .clk(clk), 
        .rst(rst), 
        .MDRIn(data_toRAM), 
        .RAMWr(wrEn), 
        .MAR(addr_toRAM), 
        .MDROut(data_fromRAM), 
        .PC(pCounter)
    );
    
    blram #(ADDRESS_WIDTH, 64, TEST_CASE) blram(
      .clk(clk),
      .rst(rst),
      .i_we(wrEn),
      .i_addr(addr_toRAM),
      .i_ram_data_in(data_toRAM),
      .o_ram_data_out(data_fromRAM)
    );
    
    task memCheck;
        input [5:0] memLocation;
        input [9:0] expectedValue;
        begin
          if(blram.memory[memLocation] != expectedValue) begin
                error = 1;
          end
        end
    endtask
    
endmodule
 
module blram(clk, rst, i_we, i_addr, i_ram_data_in, o_ram_data_out);
 
parameter SIZE = 6;
parameter DEPTH = 64;
parameter TEST_CASE = 1;
 
input clk; 
input rst;
input i_we;
input [SIZE-1:0] i_addr;
input [9:0] i_ram_data_in;
output reg [9:0] o_ram_data_out;
 
reg [9:0] memory[0:DEPTH-1];
 
always @(posedge clk) begin
  o_ram_data_out <= #1 memory[i_addr[SIZE-1:0]];
  if (i_we)
        memory[i_addr[SIZE-1:0]] <= #1 i_ram_data_in;
end 
 
initial begin
    if(TEST_CASE == 1) begin
        memory[0] = 10'b0000110010; 
        memory[1] = 10'b0010110011; 
        memory[2] = 10'b0001110100; 
        memory[3] = 10'b1001000000; 
        memory[50] = 10'b0000000101; 
        memory[51] = 10'b0000001010; 
    end else if(TEST_CASE == 2) begin
        memory[0] = 10'b0000110010; 
        memory[1] = 10'b0100110011; 
        memory[2] = 10'b0001110100; 
        memory[3] = 10'b1001000000; 
        memory[50] = 10'b0000000101; 
        memory[51] = 10'b0000001010; 
    end else if(TEST_CASE == 3) begin
        memory[0]= 10'b0000110011; 
        memory[1]= 10'b0011110001;
        memory[2]= 10'b0111001010; 
        memory[3]= 10'b0000110000; 
        memory[4]= 10'b0010110010; 
        memory[5]= 10'b0001110000; 
        memory[6]= 10'b0000110001;
        memory[7]= 10'b0010101110;
        memory[8]= 10'b0001110001; 
        memory[9]= 10'b0110000000; 
        memory[10]= 10'b0000110000; 
        memory[11]= 10'b0001110100; 
        memory[12]= 10'b1001000000;
        
        memory[46]= 10'b1; 
        memory[48]= 10'b0; 
        memory[49]= 10'b0; 
        memory[50]= 10'b0000000101; 
        memory[51]= 10'b0000001010;
 
    end
end 
 
endmodule
 
module fb_cpu #(
    parameter ADDRESS_WIDTH = 6,
    parameter DATA_WIDTH = 10
)(
    input clk, 
    input rst, 
    output reg [DATA_WIDTH-1:0] MDRIn, 
    output reg RAMWr, 
    output reg [ADDRESS_WIDTH-1:0] MAR, 
    input [DATA_WIDTH-1:0] MDROut, 
    output reg [5:0] PC
);
 
reg [DATA_WIDTH - 1:0] IR, IRNext;
reg [5:0] PCNext;
reg [9:0] ACC, ACCNext;
reg [2:0] state, stateNext;
 
always@(posedge clk) begin
    state       <= #1 stateNext;
    PC          <= #1 PCNext;
    IR          <= #1 IRNext;
    ACC         <= #1 ACCNext;
end
 
always@(*) begin
    stateNext   = state;
    PCNext      = PC;
    IRNext      = IR;
    ACCNext     = ACC;
    MAR         = 0;
    RAMWr       = 0;
    MDRIn       = 0;
    
    if(rst) begin
        stateNext   = 0;
        PCNext      = 0;
        MAR         = 0;
        RAMWr       = 0;
        IRNext      = 0;
        ACCNext     = 0;
        MDRIn       = 0;
    end else begin
        case(state)
            0: begin
                MAR = PC;
                RAMWr = 0;
                stateNext = state + 1;
            end
            
            1: begin
                
                IRNext = MDROut;
                PCNext = PC + 1;
                stateNext = state + 1;
            end
            
            2: begin
                
                case(IR[9:6])
                    4'b0000: begin 
                        MAR = IR[5:0];
                        stateNext = 3;
                    end
                    4'b0001: begin
                        MAR = IR[5:0];
                        MDRIn = ACC;
                        RAMWr = 1;
                        stateNext = 0;
                    end
                    4'b0010: begin 
                        MAR = IR[5:0];
                        stateNext = 3;
                    end
                    4'b0011: begin 
                        MAR = IR[5:0];
                        stateNext = 3;
                    end
                    4'b0100: begin 
                        MAR = IR[5:0];
                        stateNext = 3;
                    end
                    4'b0110: begin 
                        PCNext = IR[5:0];
                        stateNext = 0;
                    end
                    4'b0111: begin 
                        if (ACC == 0)
                            PCNext = IR[5:0];
                        stateNext = 0;
                    end
                    4'b1001: begin 
                        stateNext = 4;
                    end
                endcase
            end
            
            3: begin
                
                case(IR[9:6])
                    4'b0000: begin 
                        ACCNext = MDROut;
                        stateNext = 0;
                    end
                    4'b0010: begin 
                        ACCNext = ACC + MDROut;
                        stateNext = 0;
                    end
                    4'b0011: begin 
                        ACCNext = ACC - MDROut;
                        stateNext = 0;
                    end
                    4'b0100: begin 
                        ACCNext = ACC * MDROut;
                        stateNext = 0;
                    end
                endcase
            end
            
            4: begin
                stateNext = 4;
            end
        endcase
    end
end
 
endmodule
 
module top (
  input clk, 
  input rst,
  input [15:0] switches,
  input btnU,
  input btnD,
  input btnL,
  input btnR,
  input btnM,
  output reg [15:0] leds,
  output reg [7:0] ss3, ss2, ss1, ss0,
  output reg red, green, blue
);
 
tb_fb_cpu tb_fb_cpuInst();
 


endmodule
