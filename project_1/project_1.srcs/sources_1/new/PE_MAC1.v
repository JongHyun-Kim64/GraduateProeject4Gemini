`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/14 18:22:32
// Design Name: 
// Module Name: PE_MAC1
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


module PE_MAC1(
    input wire clk,
    input wire rst,
    input wire [7:0] activation_in,
    input wire [7:0] weight_in,
    input wire [15:0] psum_in,
    input wire test,
    input wire shift,

    output reg [7:0] activation_out,
    output reg [7:0] weight_out,
    output reg [15:0] psum_out,
    output reg w_error,  
    output reg a_error,  
    output reg o_error  
);

    reg [7:0] prev_activation;
    reg [7:0] prev_weight;
    reg [15:0] expected_psum;


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            activation_out <= 8'd0;
            weight_out <= 8'd0;
            psum_out <= 16'd0;
            
            prev_activation <= 8'd0;
            prev_weight <= 8'd0;
            expected_psum <= 16'd0;

            a_error <= 1'b0;
            w_error <= 1'b0;
            o_error <= 1'b0;
        end else begin
            // 계산
            expected_psum <= psum_in + (activation_in * weight_in);
            // MAC 연산
            //psum_out <= psum_out + (activation_in * weight_in); 
            psum_out <= 16'd0; //stuck at error 가정 

            // 데이터 forwarding
            if(shift) begin
                activation_out <= activation_in;
                weight_out <= weight_in;
            end
            
            if( test) begin
            // 변화 감지 + 오류 비교
            a_error <=    (activation_in != activation_out); // activation이 이전과 다름
            w_error <=    (weight_in != weight_out); // weight이 이전과 다름
            o_error <=    (psum_out != expected_psum);          // psum 연산 결과 오류 
            end
                

        end
    end
endmodule