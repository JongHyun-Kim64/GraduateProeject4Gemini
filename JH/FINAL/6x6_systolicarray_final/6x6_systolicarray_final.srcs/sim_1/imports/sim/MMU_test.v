`timescale 1ns / 1ps

// sample testbench for a 4X4 Systolic Array

module test_TPU;

   // Inputs
   reg clk;
   reg rst;
   reg [47:0] data_arr;
   reg [47:0] wt_arr;

   // Outputs
   wire [191:0] acc_out;

   // Instantiate the Unit Under Test (UUT)
   MMU uut (
      .clk(clk),
      .rst(rst), 
      .data_arr(data_arr), 
      .wt_arr(wt_arr),
      .acc_out(acc_out)
   );

   // Add stimulus here
   always
      #250 clk=!clk;
      
   initial begin
      // Initialize Inputs
      clk = 0;
      data_arr = 0;
      wt_arr = 0;
      rst = 1;
      #1000;
      rst = 0;
      @(posedge clk);
      @(posedge clk);
      
      
      @(posedge clk);
      wt_arr=48'h 55_54_53_52_51_50;
      
      @(posedge clk);
      wt_arr=48'h 45_44_43_42_41_40;
      
      @(posedge clk);
      wt_arr=48'h 35_34_33_32_31_30;
      
      @(posedge clk);
      wt_arr=48'h 25_24_23_22_21_20;

      @(posedge clk);
      wt_arr=48'h 15_14_13_12_11_10;
      
      @(posedge clk);
      wt_arr=48'h 05_04_03_02_01_00;
      
      @(posedge clk);
      @(posedge clk);

      //1CYCLE
      data_arr=48'h 00_00_00_00_00_05;
      
      @(posedge clk);//2CYCLE
      data_arr=48'h 00_00_00_00_15_04;
      
      @(posedge clk);//3CYCLE
      data_arr=48'h 00_00_00_25_14_03;
      
      @(posedge clk);//4CYCLE
      data_arr=48'h 00_00_35_24_13_02;
      
      @(posedge clk);//5CYCLE
      data_arr=48'h 00_45_34_23_12_01;
      
      @(posedge clk);//6CYCLE
      data_arr=48'h 55_44_33_22_11_00;
      
      @(posedge clk);//7CYCLE
      data_arr=48'h 54_43_32_21_10_00;

      @(posedge clk);//7CYCLE
      data_arr=48'h 53_42_31_20_00_00;

      @(posedge clk);//7CYCLE
      data_arr=48'h 52_41_30_00_00_00;

      @(posedge clk);//7CYCLE
      data_arr=48'h 51_40_00_00_00_00;
      
      @(posedge clk);//7CYCLE
      data_arr=48'h 50_00_00_00_00_00;
      
      @(posedge clk);//7CYCLE
      data_arr=48'h 00_00_00_00_00_00;
      
      //scan mode enable
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      
   end
   
   
   
   
   initial begin
   $monitor("[OUTPUT] time=%0t y5=0x%0h, y4=0x%0h, y3=0x%0h, y2=0x%0h, y1=0x%0h, y0=0x%0h",
      $time,
      acc_out[287:256], // col=5
      acc_out[255:224], // col=4
      acc_out[223:192], // col=3
      acc_out[191:160], // col=2
      acc_out[159:128], // col=1
      acc_out[127:96]   // col=0
   );
end
endmodule

