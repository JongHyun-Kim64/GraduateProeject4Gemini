`timescale 1ns / 1ps
// Systolic Array top level module. 

module MMU #(
  parameter depth     = 4,
  parameter bit_width = 8,
  parameter acc_width = 32,
  parameter size      = 4
)(
  input                           clk,
  input                           rst,
  input  [bit_width*depth-1:0]    data_arr,
  input  [bit_width*depth-1:0]    wt_arr,
  output reg [acc_width*size-1:0] acc_out
);

  genvar row, col;
  
  // 4) control_unit에 top_fault만 넘김
  wire control;
  control_unit #(
    .depth(depth),
    .bit_width(bit_width),
    .acc_width(acc_width),
    .size(size)
  ) ctrl (
    .clk        (clk),
    .rst        (rst),
    .control    (control)
  );

  // 오류 삽입용 wire
  wire inject_fault_p [0:depth-1][0:depth-1];
  wire inject_fault_d [0:depth-1][0:depth-1];
  wire inject_fault_w [0:depth-1][0:depth-1];

  generate
    for (row = 0; row < depth; row = row + 1) begin : INIT_FAULT
      for (col = 0; col < depth; col = col + 1) begin : INIT_BITS
        assign inject_fault_p[row][col] = (row == 1 && col == 1) ? 1'b1 : 1'b0;
        assign inject_fault_d[row][col] = 1'b0;
        assign inject_fault_w[row][col] = 1'b0;
      end
    end
  endgenerate

  wire [bit_width-1:0] mac_data_in  [0:depth-1][0:depth-1];
  wire [bit_width-1:0] mac_data_out [0:depth-1][0:depth-1];
  wire [bit_width-1:0] weight_in    [0:depth-1][0:depth-1];
  wire [bit_width-1:0] weight_out   [0:depth-1][0:depth-1];
  wire [acc_width-1:0] mac_acc_in   [0:depth-1][0:depth-1];
  wire [acc_width-1:0] mac_acc_out  [0:depth-1][0:depth-1];

  generate
    for (row = 0; row < depth; row = row + 1) begin : GEN_COL0
      assign mac_data_in[row][0] = control
                                 ? {bit_width{1'b0}}
                                 : data_arr[(row+1)*bit_width-1 -: bit_width];
    end
  endgenerate

  generate
    for (col = 1; col < depth; col = col + 1) begin : GEN_HORZ_PASS
      for (row = 0; row < depth; row = row + 1) begin
        assign mac_data_in[row][col] = mac_data_out[row][col-1];
      end
    end
  endgenerate

  generate
    for (col = 0; col < depth; col = col + 1) begin : WT_ROW0
      assign weight_in[0][col] = control
                               ? wt_arr[(col+1)*bit_width-1 -: bit_width]
                               : {bit_width{1'b0}};
    end
    for (row = 1; row < depth; row = row + 1) begin : WT_PASS
      for (col = 0; col < depth; col = col + 1) begin
        assign weight_in[row][col] = control
                                   ? weight_out[row-1][col]
                                   : {bit_width{1'b0}};
      end
    end
  endgenerate

  generate
    for (col = 0; col < depth; col = col + 1) begin : GEN_ACC_ROW0
      assign mac_acc_in[0][col] = {acc_width{1'b0}};
    end
  endgenerate

  generate
    for (row = 1; row < depth; row = row + 1) begin : GEN_ACC_PASS
      for (col = 0; col < depth; col = col + 1) begin
        assign mac_acc_in[row][col] = mac_acc_out[row-1][col];
      end
    end
  endgenerate

  generate
    for (row = 0; row < depth; row = row + 1) begin : GEN_ROW
      for (col = 0; col < depth; col = col + 1) begin : GEN_COL
        MAC u_mac (
          .clk           (clk),
          .control       (control),
          .rst           (rst),
          .data_in       (mac_data_in[row][col]),
          .wt_path_in    (weight_in[row][col]),
          .acc_in        (mac_acc_in[row][col]),
          .data_out      (mac_data_out[row][col]),
          .wt_path_out   (weight_out[row][col]),
          .acc_out       (mac_acc_out[row][col]),
          .inject_fault_p(inject_fault_p[row][col]),
          .inject_fault_d(inject_fault_d[row][col]),
          .inject_fault_w(inject_fault_w[row][col])
        );
      end
    end
  endgenerate

  wire [acc_width*size-1:0] last_row_concat;

  generate
    for (col = 0; col < depth; col = col + 1) begin : GEN_OUT_LAST_ROW
      assign last_row_concat[(size-col)*acc_width-1 -: acc_width]
        = mac_acc_out[depth-1][col];
    end
  endgenerate

  always @(posedge clk) begin
    acc_out <= last_row_concat;
  end
endmodule
