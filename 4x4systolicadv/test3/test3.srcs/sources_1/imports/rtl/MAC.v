`timescale 1ns / 1ns

module MAC #(parameter bit_width=8, acc_width=32)(
    input clk,
    input rst,
    input control,
    input inject_fault,
    input [acc_width-1:0] acc_in,
    input [bit_width-1:0] data_in,
    input [bit_width-1:0] wt_path_in,
    output reg [acc_width-1:0] acc_out, //모듈 외부로 나감(MAC의 연산결과)
    output reg [bit_width-1:0] data_out,
    output reg [bit_width-1:0] wt_path_out
);

    wire [acc_width-1:0] mlt;
    assign mlt = (control == 1'b1) ? 'h0 : data_in * wt_path_out;

    // XOR-based error detection
    reg [acc_width-1:0] golden_acc;  // 내부용(기댓값)
    wire [acc_width-1:0] err_p;
    reg bypass;
   
    assign err_p = acc_out != golden_acc;    //HIGH When acc_out != golden_acc
    
    
    
    always @(posedge clk) begin
        if (rst) begin //rst 1로 값 초기화
            acc_out     <= 0;
            data_out    <= 0;
            wt_path_out <= 0;
            golden_acc  <= 0;
            bypass      <= 0;
        end else if (control) begin //control 신호 1 -> weight preload
            acc_out     <= 0;
            data_out    <= 0;
            wt_path_out <= wt_path_in;
            golden_acc  <= 0;
            bypass      <= 0;  
            
            //오류 주입 후 우회 동작 확인
        end else if (inject_fault) begin
        acc_out <= (acc_in + mlt) ^ 32'h00000001;// LSB 반전
        
        end else if (bypass) begin //control=0, rst=0(연산 시작), XOR로 오류 PE 내부 판별
            acc_out     <= acc_in; //오류 있으면 연산없이 데이터 통로 역할로 해당 PE 무시(우회) 
            data_out    <= data_in;
            wt_path_out <= wt_path_in;
        
        end else begin //오류 PE 없으면 MAC 연산 수행
            acc_out     <= acc_in + mlt;
            data_out    <= data_in;
            golden_acc  <= acc_in + mlt;
        end

        if (!rst && err_p) //rst = 0일 때 정상 작동, 외부로 나갈 acc_out값과 비교 시점에 내부에 저장된 golden값 비교
            bypass <= 1;
    end
endmodule