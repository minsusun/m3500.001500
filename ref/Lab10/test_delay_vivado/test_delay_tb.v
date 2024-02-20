`timescale 1ns / 1ps
module test_delay_tb();
reg clk;
reg rstn;
reg vld_i;
wire vld_o;
test_delay u_test_delay(
.clk(clk), 
.rstn(rstn),
.vld_i(vld_i),
.vld_o(vld_o));

parameter CLK_PERIOD = 10;
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = !clk;
end

initial begin
    rstn = 0;
    vld_i = 0;
    
    #(CLK_PERIOD/2) rstn = 1;
    
    #(10*CLK_PERIOD) @(posedge clk) vld_i = 1;
    #(CLK_PERIOD) @(posedge clk) vld_i = 0;
        
end

endmodule
