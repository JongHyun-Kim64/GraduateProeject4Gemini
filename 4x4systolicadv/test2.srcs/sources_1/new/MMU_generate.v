`timescale 1ns / 1ps
// Systolic Array top level module. 

module MMU #(
  parameter depth     = 4,
  parameter bit_width = 8,
  parameter acc_width = 32,
  parameter size      = 4
)(
  input                           clk,
  input                           control,
  input  [bit_width*depth-1:0]    data_arr,
  input  [bit_width*depth-1:0]    wt_arr,
  output reg [acc_width*size-1:0] acc_out
);

  genvar row, col;

  // 1) comb wire 로 선언
  wire [bit_width-1:0] mac_data_in  [0:depth-1][0:depth-1];
  wire [bit_width-1:0] mac_data_out [0:depth-1][0:depth-1];
  wire [bit_width-1:0] weight_in    [0:depth-1][0:depth-1];
  wire [bit_width-1:0] weight_out   [0:depth-1][0:depth-1];
  wire [acc_width-1:0] mac_acc_in [0:depth-1][0:depth-1];
  wire [acc_width-1:0] mac_acc_out  [0:depth-1][0:depth-1];

  // 2) row=0, col=0 은 data_arr 에서 바로 뽑아오고
  generate
    for(row=0; row<depth; row=row+1) begin : GEN_COL0
      // 맨 왼쪽  행에 data 삽입
      assign mac_data_in[row][0] = control
                                 ? {bit_width{1'b0}}
                                 : data_arr[(row+1)*bit_width-1 -: bit_width];
    end
  endgenerate

  // 3) 같은 행에서 "즉시" 옆 칸으로 패스
generate
  for (col = 1; col < depth; col = col + 1) begin : GEN_HORZ_PASS
    for (row = 0; row < depth; row = row + 1) begin
      // combinational 연결 -> 클록 딜레이 0
      assign mac_data_in[row][col] = mac_data_out[row][col-1];
    end
  end
endgenerate

  // 4) weight_in: 위에서 구현하신 대로
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

  // 5) mac_acc_in 은 클럭 경로 (예: 수직 이동)
//  integer i, j;
//  always @(posedge clk) begin
//    for (i = 0; i < depth; i = i + 1) begin
//      for (j = 0; j < depth; j = j + 1) begin
//        if (j == 0) begin
//          if (i == 0)
//            mac_acc_in[0][0] <= 0;
//          else
//            mac_acc_in[i][0] <= mac_acc_out[i-1][0];
//        end else begin
//          mac_acc_in[i][j] <= mac_acc_out[i][j-1];
//        end
//      end
//    end
//  end
  // -----------------------------
  // 5-1) combinational 연결로 맨 첫 행은 0
  // -----------------------------
  generate
    for (col = 0; col < depth; col = col + 1) begin : GEN_ACC_ROW0
      assign mac_acc_in[0][col] = {acc_width{1'b0}};
    end
  endgenerate

  // -----------------------------
  // 5-2) 그 아래 행들은 위 행의 acc_out 을 바로 받아 오도록
  // -----------------------------
  generate
    for (row = 1; row < depth; row = row + 1) begin : GEN_ACC_PASS
      for (col = 0; col < depth; col = col + 1) begin
        assign mac_acc_in[row][col] = mac_acc_out[row-1][col];
      end
    end
  endgenerate

  // 6) MAC 인스턴스화
  generate
    for (row = 0; row < depth; row = row + 1) begin : GEN_ROW
      for (col = 0; col < depth; col = col + 1) begin : GEN_COL
        MAC u_mac (
          .clk         (clk),
          .control     (control),
          .data_in     (mac_data_in[row][col]),
          .wt_path_in  (weight_in[row][col]),
          .acc_in      (mac_acc_in[row][col]),
          .data_out    (mac_data_out[row][col]),
          .wt_path_out (weight_out[row][col]),
          .acc_out     (mac_acc_out[row][col])
        );
      end
    end
  endgenerate

  // 7) 최종 출력
  always @(posedge clk) begin
    acc_out <= mac_acc_out[depth-1][depth-1];
  end

endmodule