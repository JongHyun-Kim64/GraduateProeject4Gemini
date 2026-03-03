`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 11:39:43
// Design Name: 
// Module Name: xor_detect
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module xor_detect(
    input clk,
    input rst,
    input weight_in,
    output weight_out,
    input data_in,
    output data_out,
    input psum_in,
    output psum_out
    );
    
    reg weight, data, psum;
    reg reg_p;
    wire err_w, err_d, err_p;
    
    always @(posedge clk) begin
        weight  <= 0;
        data    <= data_in;
        psum    <= psum_in;
        reg_p  <= psum_in;
    end
    
    assign  weight_out = weight;
    assign  data_out = data;
    assign  psum_out = psum;
    
    assign err_p = psum ^ reg_p;
    
    
endmodule
