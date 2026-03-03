`timescale 1ns / 1ps
// Systolic Array top level module. 
module MMU #(
  parameter depth     = 10,
  parameter bit_width = 8,
  parameter acc_width = 32
)(
  input                           clk,
  input                           rst,
  input  [bit_width*depth-1:0]    data_arr,
  input  [bit_width*depth-1:0]    wt_arr,
  output reg [acc_width*depth-1:0] acc_out
);

  genvar r,c;

  // 4) control_unit
  wire control;
  control_unit #(
    .depth(depth),
    .bit_width(bit_width),
    .acc_width(acc_width)
  ) ctrl (
    .clk        (clk),
    .rst        (rst),
    .control    (control)
  );
  
  // 5) 내부 데이터/weight/acc 파이프라인용 wire 선언
  wire [bit_width-1:0] mac_data_in  [0:depth-1][0:depth-1];
  wire [bit_width-1:0] mac_data_out [0:depth-1][0:depth-1];
  wire [bit_width-1:0] weight_in    [0:depth-1][0:depth-1];
  wire [bit_width-1:0] weight_out   [0:depth-1][0:depth-1];
  wire [acc_width-1:0] mac_acc_in   [0:depth-1][0:depth-1];
  wire [acc_width-1:0] mac_acc_out  [0:depth-1][0:depth-1];

  // 6) mac_data_in[row][0] ← data_arr or scan 시 8'h10
  generate
    for (r=0; r<depth; r=r+1) begin : GEN_COL0
      assign mac_data_in[r][0] =    control      //control 모드가 아니면  첫 열에 DATA를 쪼개어 입력
                                    ? {bit_width{1'b0}}    
                                    :  data_arr[(r+1)*bit_width-1 -: bit_width];
    end
  endgenerate

  // 7) 남은 칸은 좌측 mac_data_out 패스
  generate
    for (c=1; c<depth; c=c+1) begin : GEN_HORZ_PASS
      for (r=0; r<depth; r=r+1) begin
        assign mac_data_in[r][c] = mac_data_out[r][c-1];
      end
    end
  endgenerate

  // 8) weight_in: 첫 행←wt_arr(control), or 8'h01(scan), else 0
  generate
    for (c=0; c<depth; c=c+1) begin : WT_ROW0
      assign weight_in[0][c]    = control      //control 모드에서 첫 행에 weight를 쪼개어 입력
                                ? wt_arr[(c+1)*bit_width-1 -: bit_width]    
                                : {bit_width{1'b0}};
    end
    for (r=1; r<depth; r=r+1) begin : WT_PASS
      for (c=0; c<depth; c=c+1) begin
        assign weight_in[r][c]  = control
                                ? weight_out[r-1][c]
                                : {bit_width{1'b0}};
      end
    end
  endgenerate

  // 9) mac_acc_in: 첫 행←0, 나머지←위 mac_acc_out
  generate
    for (c=0; c<depth; c=c+1) begin : GEN_ACC_ROW0
      assign mac_acc_in[0][c] = {acc_width{1'b0}};
    end
    for (r=1; r<depth; r=r+1) begin : GEN_ACC_PASS
      for (c=0; c<depth; c=c+1) begin
        assign mac_acc_in[r][c] = mac_acc_out[r-1][c];
      end
    end
  endgenerate

  // 10) MAC 인스턴스화: faulty_flag는 per-PE wire에 연결
  generate
    for (r=0; r<depth; r=r+1) begin : GEN_ROW
      for (c=0; c<depth; c=c+1) begin : GEN_COL
        MAC #(
          .depth(depth),
          .bit_width(bit_width),
          .acc_width(acc_width)
        ) u_mac (
//          .PE_ROW      (r), //Delete when Analyzing Area
//          .PE_COL      (c), //Delete when Analyzing Area
          .clk         (clk),
          .rst         (rst),
          .control     (control),
          .acc_in      (mac_acc_in[r][c]),
          .acc_out     (mac_acc_out[r][c]),
          .data_in     (mac_data_in[r][c]),          
          .wt_path_in  (weight_in[r][c]),
          .data_out    (mac_data_out[r][c]),
          .wt_path_out (weight_out[r][c])
        );
      end
    end
  endgenerate

  // 11) 마지막 행 누적값을 acc_out에
  wire [acc_width*depth-1:0] last_row_concat;
  generate
    for (c=0; c<depth; c=c+1) begin : GEN_OUT_LAST_ROW
      assign last_row_concat[(depth-c)*acc_width-1 -: acc_width]
        = mac_acc_out[depth-1][c];
    end
  endgenerate

  // 12) 레지스터에 저장
  always @(posedge clk) begin
    acc_out <= last_row_concat;
  end

endmodule
