`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/14 18:17:46
// Design Name: 
// Module Name: PE_MAC
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

module PE_MAC (
    input wire clk,
    input wire rst,
    input wire [7:0] activation_in,
    input wire [7:0] weight_in,
    input wire [15:0] psum_in,

    output reg [7:0] activation_out,
    output reg [7:0] weight_out,
    output reg [15:0] psum_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            activation_out <= 8'd0;
            weight_out <= 8'd0;
            psum_out <= 16'd0;
        end else begin
            // MAC 연산
            psum_out <= psum_in + (activation_in * weight_in);

            // 데이터 forwarding
            activation_out <= activation_in;
            weight_out <= weight_in;
        end
    end
endmodule

