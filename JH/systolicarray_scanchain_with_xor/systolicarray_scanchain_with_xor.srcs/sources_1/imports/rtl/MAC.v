`timescale 1ns / 1ns

module MAC #(parameter depth = 4, bit_width=8, acc_width=32
)(
  input  [depth-1:0]      PE_ROW,
  input  [depth-1:0]      PE_COL,
  input                   clk,
  input                   rst,
  input                   control,
  input  [acc_width-1:0]  acc_in,
  input  [bit_width-1:0]  data_in,
  input  [bit_width-1:0]  wt_path_in,
  input                   scan_en,
  output reg [acc_width-1:0] acc_out,
  output reg [bit_width-1:0] data_out,
  output reg [bit_width-1:0] wt_path_out,
  output reg               faulty_flag
);
   // A register to store the stationary weights
   // reg [bit_width-1:0] mac_weight;
   reg [depth*2-1:0] PE_NUMBER;
   wire [acc_width-1:0] mlt = control ? 'h0 : data_in * wt_path_out;

   // ----------------------------------------------------------------
   // 1) 패리티 생성 및 저장용 레지스터
   // ----------------------------------------------------------------
   // parity 생성·저장
   wire out_data_parity;
   wire out_weight_parity;
   wire out_acc_parity;

   assign out_data_parity   = ^data_out;      // XOR-reduction
   assign out_weight_parity = ^wt_path_out;
   assign out_acc_parity    = ^acc_out;
   
   reg in_data_parity;
   reg in_weight_parity;
   reg in_acc_parity;

   // ----------------------------------------------------------------
   // 2) MAC 동작 및 parity 검사
   // ----------------------------------------------------------------
   //reg faulty_reg;
   always @(posedge clk) begin
      PE_NUMBER <= {PE_ROW,PE_COL};
      if(rst) begin
         data_out     <= 'h0;   acc_out      <= 'h0;    wt_path_out  <= 'h0;
         in_data_parity <= 0;   in_acc_parity <= 0;     in_weight_parity <= 0;
         faulty_flag  <= 0;
      end
      else if (control) begin
         // weight load 모드
         data_out     <= 'h0;
         acc_out      <= 'h0;
         //CODE FOR Weight SA TESTING
         in_weight_parity <= ^wt_path_in;
//         if((PE_ROW == 1)&&(PE_COL == 2)&& wt_path_in) wt_path_out  <= 8'hab;//only for SA Test
//         else                wt_path_out  <= wt_path_in;
         //
         wt_path_out  <= wt_path_in;  //CODE FOR NOT TESTING
         faulty_flag <= in_weight_parity == !out_weight_parity;
         
      end else if (scan_en) begin
         // scan 모드
         data_out     <= data_in;
         acc_out      <= acc_in;
         wt_path_out  <= wt_path_in;
         
      end else begin
         // normal MAC 연산
         wt_path_out    <= wt_path_out;
         //CODE FOR Data SA TESTING
         if((PE_ROW == 1)&&(PE_COL == 2)&& data_in) data_out  <= 8'hab;//only for SA Test
         else                data_out       <= data_in;
//         data_out       <= data_in;     //CODE FOR NOT TESTING
         
         //CODE FOR PSUM SA TESTING
//         if((PE_ROW == 1)&&(PE_COL == 2)&& acc_in) acc_out  <= 8'hab;//only for SA Test
//         else                acc_out        <= acc_in + mlt;
         acc_out        <= acc_in + mlt;      //CODE FOR NOT TESTING
         
         in_data_parity <= ^data_in;
         in_acc_parity  <= ^(acc_in + mlt);
         faulty_flag <= (in_data_parity == !out_data_parity) || (in_acc_parity == !out_acc_parity) ;
         // 재계산된 패리티와 저장된 패리티 비교
         // 하나라도 mismatch 시 error
      end
   end
   
   //assign fault_flag = faulty_reg;
   
endmodule
