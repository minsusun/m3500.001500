`timescale 1ns / 1ps
module test_delay(
input clk, 
input rstn,
input vld_i,
output vld_o);
    
reg [4:0] vld_d;
wire vld_i_s = vld_i; // Fix a timing synchronizion issue in Vivado
always@(posedge clk, negedge rstn) begin
    if(!rstn) 
        vld_d <= 0;
    else
        vld_d <= {vld_d[3:0], vld_i_s};
        //vld_d <= {vld_d[3:0], vld_i};
end
assign vld_o = vld_d[4];
endmodule
