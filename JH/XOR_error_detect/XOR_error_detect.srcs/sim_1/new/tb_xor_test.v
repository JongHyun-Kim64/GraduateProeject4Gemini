`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/14 12:05:37
// Design Name: 
// Module Name: tb_xor_test
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

module tb_xor_detect;
    // Inputs to DUT
    reg clk;
    reg rst;
    reg weight_in;
    reg data_in;
    reg psum_in;

    // Outputs from DUT
    wire weight_out;
    wire data_out;
    wire psum_out;

    // Instantiate the Device Under Test (DUT)
    xor_detect uut (
        .clk(clk),
        .rst(rst),
        .weight_in(weight_in),
        .weight_out(weight_out),
        .data_in(data_in),
        .data_out(data_out),
        .psum_in(psum_in),
        .psum_out(psum_out)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        weight_in = 0;
        data_in   = 0;
        psum_in   = 0;

        // Release reset after 2 cycles
        #10;
        rst = 0;

        // Test vector sequence
        // Apply a few patterns and observe 1-clock delay
        #10;
        weight_in = 1; data_in = 0; psum_in = 1;
        #10;
        weight_in = 0; data_in = 1; psum_in = 0;
        #10;
        weight_in = 1; data_in = 1; psum_in = 1;
        #10;
        weight_in = 0; data_in = 0; psum_in = 0;

        // Finish simulation
        #20;
        $finish;
    end

    // Monitoring
    initial begin
        $display("Time | rst | w_in d_in p_in | w_out d_out p_out");
        $monitor("%4dns |   %b |   %b    %b    %b  |   %b     %b      %b", 
                 $time, rst, weight_in, data_in, psum_in, weight_out, data_out, psum_out);
    end

endmodule