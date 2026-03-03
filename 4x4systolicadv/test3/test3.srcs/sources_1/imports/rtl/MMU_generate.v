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
  input                           control,
  input  [bit_width*depth-1:0]    data_arr,
  input  [bit_width*depth-1:0]    wt_arr,
  output reg [acc_width*size-1:0] acc_out
);

  genvar row, col;
  
//  //오류 삽입용 wire, 실제 오버헤드 계산시 제외
//      wire inject_fault_00=0;
//      wire inject_fault_01=0;
//      wire inject_fault_02=0;
//      wire inject_fault_03=0;
//      wire inject_fault_10=0;
//      wire inject_fault_11=1; //오류 주입
//      wire inject_fault_12=0;
//      wire inject_fault_13=0;
//      wire inject_fault_20=0;
//      wire inject_fault_21=0;
//      wire inject_fault_22=0;
//      wire inject_fault_23=0;
//      wire inject_fault_30=0;
//      wire inject_fault_31=0;
//      wire inject_fault_32=0;
//      wire inject_fault_33=0;

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
          .rst         (rst),
          .data_in     (mac_data_in[row][col]),
          .wt_path_in  (weight_in[row][col]),
          .acc_in      (mac_acc_in[row][col]),
          .data_out    (mac_data_out[row][col]),
          .wt_path_out (weight_out[row][col]),
          .acc_out     (mac_acc_out[row][col]),
          .inject_fault(
          (row == 0 && col == 0) ? inject_fault_00 :
          (row == 0 && col == 1) ? inject_fault_01 :
          (row == 0 && col == 2) ? inject_fault_02 :
          (row == 0 && col == 3) ? inject_fault_03 :
          (row == 1 && col == 0) ? inject_fault_10 :
          (row == 1 && col == 1) ? inject_fault_11 :
          (row == 1 && col == 2) ? inject_fault_12 :
          (row == 1 && col == 3) ? inject_fault_13 :
          (row == 2 && col == 0) ? inject_fault_20 :
          (row == 2 && col == 1) ? inject_fault_21 :
          (row == 2 && col == 2) ? inject_fault_22 :
          (row == 2 && col == 3) ? inject_fault_23 :
          (row == 3 && col == 0) ? inject_fault_30 :
          (row == 3 && col == 1) ? inject_fault_31 :
          (row == 3 && col == 2) ? inject_fault_32 :
          (row == 3 && col == 3) ? inject_fault_33 :
          1'b0)
        );
      end
    end
  endgenerate

// 7) 최종 출력: 마지막 행 PE[depth-1][0..depth-1]를 한꺼번에 acc_out으로
// ---------------------------------------------------------------

// 7-1) 마지막 행을 위한 wire 벡터 선언
wire [acc_width*size-1:0] last_row_concat;

// 7-2) generate로 열(col)만 반복하며 슬라이스 단위 assign
generate
  for (col = 0; col < depth; col = col + 1) begin : GEN_OUT_LAST_ROW
    // (size - col) * acc_width - 1 부터 acc_width 비트씩 잘라서
    // mac_acc_out[depth-1][col]을 배치
    assign last_row_concat[(size-col)*acc_width-1 -: acc_width]
      = mac_acc_out[depth-1][col];
  end
endgenerate

// 7-3) 클록 엣지에서 acc_out에 등록
always @(posedge clk) begin
  acc_out <= last_row_concat;
end
endmodule