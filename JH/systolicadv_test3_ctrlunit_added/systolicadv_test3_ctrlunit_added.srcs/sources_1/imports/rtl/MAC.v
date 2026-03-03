`timescale 1ns / 1ns

module MAC #(parameter bit_width=8, acc_width=32)(
    input clk,
    input rst,
    input control,
    input inject_fault_p,
    input inject_fault_d,
    input inject_fault_w,
    input [acc_width-1:0] acc_in,
    input [bit_width-1:0] data_in,
    input [bit_width-1:0] wt_path_in,
    output reg [acc_width-1:0] acc_out, // 모듈 외부로 나감 (MAC의 연산결과)
    output reg [bit_width-1:0] data_out,
    output reg [bit_width-1:0] wt_path_out
);

    wire [acc_width-1:0] mlt;
    assign mlt = control ? 0 : (data_in * wt_path_out);

    // XOR-based error detection - 정상 기대값 내부 저장용
    reg [acc_width-1:0] golden_acc;
    reg [bit_width-1:0] golden_data;
    reg [bit_width-1:0] golden_weight;

    // 오류 검출용
    wire [acc_width-1:0] err_p;
    wire [bit_width-1:0] err_d;
    wire [bit_width-1:0] err_w;

    reg bypass;

    assign err_p = acc_out ^ golden_acc;
    assign err_d = data_out ^ golden_data;
    assign err_w = wt_path_out ^ golden_weight;

    always @(posedge clk) begin
        if (rst) begin
            acc_out       <= 0;
            data_out      <= 0;
            wt_path_out   <= 0;
            golden_acc    <= 0;
            golden_data   <= 0;
            golden_weight <= 0;
            bypass        <= 0;
        end else if (control) begin
            acc_out       <= 0;
            data_out      <= 0;
            wt_path_out   <= wt_path_in;
            golden_acc    <= 0;
            golden_data   <= 0;
            golden_weight <= wt_path_in;
            bypass        <= 0;
        end else if (inject_fault_p || inject_fault_d || inject_fault_w) begin
            golden_acc    <= acc_in + mlt;
            golden_data   <= data_in;
            golden_weight <= wt_path_in;

            acc_out       <= inject_fault_p ? ((acc_in + mlt) ^ 32'h00000001) : (acc_in + mlt);
            data_out      <= inject_fault_d ? (data_in ^ 8'h01) : data_in;
            wt_path_out   <= inject_fault_w ? (wt_path_in ^ 8'h01) : wt_path_in;
        end else if (bypass) begin
            acc_out       <= golden_acc;
            data_out      <= golden_data;
            wt_path_out   <= golden_weight;
        end else begin
            acc_out       <= acc_in + mlt;
            data_out      <= data_in;
        
            golden_acc    <= acc_in + mlt;
            golden_data   <= data_in;

        end

        if (!rst && (err_p || err_d || err_w))
            bypass <= 1;
    end
endmodule
