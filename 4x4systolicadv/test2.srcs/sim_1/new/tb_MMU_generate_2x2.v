`timescale 1ns / 1ps

// sample testbench for a 4X4 Systolic Array

module test_TPU;

   // Inputs
   reg clk;
   reg control;
   reg [31:0] data_arr;
   reg [31:0] wt_arr;

   // Outputs
   wire [127:0] acc_out;

   // Instantiate the Unit Under Test (UUT)
   MMU uut (
      .clk(clk), 
      .control(control), 
      .data_arr(data_arr), 
      .wt_arr(wt_arr), 
      .acc_out(acc_out)
   );

   initial begin
      // Initialize Inputs
      clk = 0;
      control = 0;
      data_arr = 0;
      wt_arr = 0;
      
      // Wait 100 ns for global reset to finish
      #5000;
    end
   
   // Add stimulus here
   always
      #250 clk=!clk;
      
   initial begin
      wt_arr=32'h 33323130;
      @(posedge clk);
      control=1;
      
      @(posedge clk);
      wt_arr=32'h 23222120;
      
      @(posedge clk);
      wt_arr=32'h 13121110;

      @(posedge clk);
      wt_arr=32'h 03020100;

      @(posedge clk);
      @(posedge clk);

      control=0;
      //1CYCLE
      data_arr=32'h 00_00_00_03;
      
      @(posedge clk);//2CYCLE
      data_arr=32'h 00_00_13_02;
      
      @(posedge clk);//3CYCLE
      data_arr=32'h 00_23_12_01;
      
      @(posedge clk);//4CYCLE
      data_arr=32'h 33_22_11_00;
      
      @(posedge clk);//5CYCLE
      data_arr=32'h 32_21_10_00;
      
      @(posedge clk);//6CYCLE
      data_arr=32'h 31_20_00_00;
      
      @(posedge clk);//7CYCLE
      data_arr=32'h 30_00_00_00;

      @(posedge clk);//8CYCLE
      data_arr=32'h 00_00_00_00;
      
   end
   
   initial begin
      $monitor("[OUTPUT] time=%0t y3=0x%0h, y2=0x%0h, y1=0x%0h, y0=0x%0h", $time, acc_out[127:96], acc_out[95:64], acc_out[63:32], acc_out[31:0]);
   end

   initial begin
      #1000000
      $finish();
   end
      
endmodule
