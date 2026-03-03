`timescale 1ns / 1ns

module MAC #(parameter bit_width=8, acc_width=32)(
    clk,
    control,
    acc_in,    //a
    acc_out,   //a+b*c
    data_in,   //b
    wt_path_in,      //c
    data_out,  
    wt_path_out,
    scan_en      
 );
   input clk;
   input control; // control signal used to indidate if it is weight loading or not
   
   input [acc_width-1:0]        acc_in; // accumulation in
   input [bit_width-1:0]        data_in;  // data input or activation in
   input [bit_width-1:0]        wt_path_in;   // weight data in
   input                        scan_en;
   output reg [acc_width-1:0]   acc_out;  // accumulation out
   output reg [bit_width-1:0]   data_out;    // activation out
   output reg [bit_width-1:0]   wt_path_out;      // weight data out
   
   // A register to store the stationary weights
   //reg [bit_width-1:0] mac_weight;
   wire [acc_width-1:0] mlt;

   assign mlt = control ? 'h0 : data_in*wt_path_out;
   
   // implement your MAC Unit below
   always@(posedge clk) begin
      if (control) begin
         data_out    <= 'h0;
         acc_out     <= 'h0;
         wt_path_out  <= wt_path_in;
      end else if(scan_en) begin
         data_out    <= data_in;
         acc_out     <= acc_in;
         wt_path_out <= wt_path_in;
      end
      else begin
         data_out    <= data_in;
         acc_out     <= acc_in + mlt;
      end
   end

endmodule