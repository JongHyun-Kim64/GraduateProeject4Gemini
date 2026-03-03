`timescale 1ns / 1ns

module MAC #(parameter depth = 6, bit_width=8, acc_width=32
)(  
//  input  [depth-1:0]      PE_ROW,//Delete when Analyzing Area
//  input  [depth-1:0]      PE_COL,//Delete when Analyzing Area
  input                   clk,
  input                   rst,
  input                   control,
  input  [acc_width-1:0]  acc_in,
  input  [bit_width-1:0]  data_in,
  input  [bit_width-1:0]  wt_path_in,
  output [acc_width-1:0]  acc_out,
  output [bit_width-1:0]  data_out,
  output [bit_width-1:0]  wt_path_out
);
   // A register to store the stationary weights
   // reg [bit_width-1:0] mac_weight;
   wire [acc_width-1:0] mlt = control ? 'h0 : data_in * wt_path_out;
   
   reg [bit_width-1:0] data_reg, wt_reg;
   reg [acc_width-1:0] acc_reg;
   
   // ----------------------------------------------------------------
   // 1) 패리티 생성 및 저장용 레지스터
   // ----------------------------------------------------------------
   // parity 생성·저장
   wire out_data_parity   = ^data_out;      // XOR-reduction
   wire out_weight_parity = ^wt_path_out;
   wire out_acc_parity    = ^acc_out;
   
   reg in_data_parity;
   reg in_weight_parity;
   reg in_acc_parity;
   
   reg w_fault, d_fault, a_fault;
   wire w_fault_wire, d_fault_wire, a_fault_wire;
   
   assign w_fault_wire = in_weight_parity ^ ^wt_reg;
   assign a_fault_wire = in_acc_parity ^ ^acc_reg;
   assign d_fault_wire = in_data_parity ^ ^data_reg;

   assign wt_path_out = (w_fault||w_fault_wire) ? wt_path_in : wt_reg;  //2025.05.25 15:32 수정, faulty_flag가 1이면 in을 그대로 out으로, 아니면 wt_reg에 저장된 값 출력
   assign acc_out = (a_fault||a_fault_wire) ? acc_in : acc_reg;  //2025.05.25 15:32 수정, faulty_flag가 1이면 in을 그대로 out으로, 아니면 acc_reg에 저장된 값 출력
   assign data_out = (d_fault||d_fault_wire) ? data_in : data_reg;  //2025.05.25 15:32 수정, faulty_flag가 1이면 in을 그대로 out으로, 아니면 data_reg에 저장된 값 출력
   //fault register과 wire로 OR 게이트 해주는 이유는 FAULT 발생 시 우회 경로 유지, 안정성을 위함
   
   
   // ----------------------------------------------------------------
   // 2) MAC 동작 및 parity 검사
   // ----------------------------------------------------------------
   //reg faulty_reg;
   always @(posedge clk) begin
      if(rst) begin
         data_reg       <= 'h0;     acc_reg         <= 'h0;     wt_reg              <= 'h0;
         in_data_parity <= 0;       in_acc_parity   <= 0;       in_weight_parity    <= 0;
         d_fault        <= 0;       a_fault         <= 0;       w_fault             <= 0;
      end
      else if (control) begin
         // weight load 모드
         data_reg <= {bit_width{1'b0}};
         acc_reg  <= {acc_width{1'b0}};
         in_weight_parity <= ^wt_path_in;
         //CODE FOR Weight SA TESTING
//         if((PE_ROW == 1)&&(PE_COL == 1)) wt_reg  <= 8'hab;//only for SA Test
//         else                wt_reg       <= wt_path_in;
         
         wt_reg  <= wt_path_in;  //CODE FOR NOT TESTING
         w_fault <= w_fault  | (in_weight_parity ^ out_weight_parity);
      end else begin
         // normal MAC 연산
         //CODE FOR Data SA TESTING
//         if((PE_ROW == 1)&&(PE_COL == 1)) data_reg  <= 8'hab;//only for SA Test
//         else                data_reg       <= data_in;
         data_reg       <= data_in;     //CODE FOR NOT TESTING
         
         //CODE FOR PSUM SA TESTING
//         if((PE_ROW == 1)&&(PE_COL == 1)) acc_reg  <= 8'hab;//only for SA Test
//         else                acc_reg        <= acc_in + mlt;
         acc_reg        <= acc_in + mlt;      //CODE FOR NOT TESTING
         
         in_data_parity <= ^data_in;
         in_acc_parity  <= ^(acc_in + mlt);
         
         d_fault <= d_fault  | (in_data_parity ^ out_data_parity);
         a_fault <= a_fault  | (in_acc_parity ^ out_acc_parity);
         // 재계산된 패리티와 저장된 패리티 비교
         // 하나라도 mismatch 시 error
      end
   end
   
   //assign fault_flag = faulty_reg;
   
endmodule