module control_unit #(
    parameter N = 3,
    parameter DATAW = 8
)(
    input clk,
    input rst,
    input shift_sig,

    input [DATAW-1:0] a_matrix [0:N*N-1],
    input [DATAW-1:0] b_matrix [0:N*N-1],

    output reg [DATAW-1:0] a_data [0:N-1],
    output reg [DATAW-1:0] b_data [0:N-1],
    output reg [N-1:0] a_en,
    output reg [N-1:0] b_en,
    output reg done
);

    reg [3:0] step;
    integer i, j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            step <= 0;
            a_en <= 0;
            b_en <= 0;
            done <= 0;
        end else if (shift_sig) begin
            a_en <= 0;
            b_en <= 0;

            // A 행렬 입력 로직
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    if (i + j == step) begin
                        a_data[i] <= a_matrix[i*N + j];
                        a_en[i]   <= 1'b1;
                    end
                end
            end

            // B 행렬 입력 로직
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    if (i + j == step) begin
                        b_data[j] <= b_matrix[i*N + j];
                        b_en[j]   <= 1'b1;
                    end
                end
            end

            // Step 증가
            if (step < 2*N - 2)
                step <= step + 1;
            else
                done <= 1'b1;
        end
    end
endmodule
