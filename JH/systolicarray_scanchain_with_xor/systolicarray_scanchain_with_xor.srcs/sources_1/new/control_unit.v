`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/22 16:55:15
// Design Name: 
// Module Name: control_unit
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


module control_unit#(
  parameter depth     = 4,
  parameter bit_width = 8,
  parameter acc_width = 32,
  parameter size      = 4
)(
    input clk,
    input rst,
    input faulty_flag,
    output reg control,
    output reg scan_en
    );
    
    reg [depth:0] clkcnt = 0;
    
    reg [1:0] curr_state = 2'b0, next_state = 2'b0;
    always @(posedge clk) curr_state <= next_state;
    localparam      IDLE = 2'b00, W_LOAD = 2'b01,
                    MAC = 2'b10,  SCAN = 2'b11; 
                    
                    
    //FSM: IDLE -> Weight Preload -> MAC -> Scan(When Faulty Flag HIGH)
    always @(posedge clk) begin
        clkcnt <= clkcnt + 1;
        if(rst) begin
            next_state <= IDLE;
            clkcnt <= 0;
            control <= 0;
            scan_en <= 0;
        end else begin
            case(next_state)
                IDLE: begin
                    clkcnt <= clkcnt + 1;
                    if(clkcnt > 1) begin
                        control <= 1;
                        clkcnt <= 0;
                        next_state <= W_LOAD;    //2clk여유 후 가중치 로드 시작
                    end
                    else           next_state <= IDLE;
                end
                W_LOAD: begin
                    clkcnt <= clkcnt + 1;
                    if (faulty_flag)begin
                        clkcnt <= 0;
                        next_state <= SCAN;
                    end
                    else if(clkcnt == depth-1) begin
                        control <= 0;
                        next_state <= MAC;
                    end
                    else next_state <= W_LOAD;
                end
                MAC:
                    if(faulty_flag) begin
                        clkcnt <= 0;
                        next_state <= SCAN;
                    end
                    else            next_state <= MAC;
                SCAN: begin
                    clkcnt <= clkcnt + 1;
                    scan_en <= 1;
                    if(clkcnt == depth + 1) scan_en <= 0;
                    else if(clkcnt == depth + 2) scan_en <= 1;
                    else if(clkcnt > depth + 2) scan_en <= 0;
                end
            endcase
        end
    end
    
    
endmodule
