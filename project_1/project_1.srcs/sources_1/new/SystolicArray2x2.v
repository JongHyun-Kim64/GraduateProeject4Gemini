module SystolicArray2x2 (
    input wire clk,
    input wire rst,

    input wire [7:0] act_in_0,  // A[0][col]
    input wire [7:0] act_in_1,  // A[1][col]
    input wire [7:0] weight_in_0, // W[row][0]
    input wire [7:0] weight_in_1,

    output wire [15:0] psum_out_0_0,
    output wire [15:0] psum_out_0_1,
    output wire [15:0] psum_out_1_0,
    output wire [15:0] psum_out_1_1,
    output wire w_error,  
    output wire a_error,  
    output wire o_error  
);

    wire [7:0] a_0_0, a_1_0, a_0_1, a_1_1;
    wire [7:0] w_0_0, w_0_1, w_1_0, w_1_1;
    wire [15:0] p_00, p_01, p_10, p_11;
    wire TEST, SHIFT;
    
    control_unit CU (
    .clk    (clk),
    .rst    (rst),
    .test_sig   (TEST),
    .shift_sig  (SHIFT)
    );
    
    // PE(0,0)
    PE_MAC1 pe00 (
        .clk(clk),
        .rst(rst),
        .activation_in(act_in_0),
        .weight_in(weight_in_0),
        .psum_in(16'd0),
        .test   (TEST),
        .shift  (SHIFT),
        .activation_out(a_0_0),
        .weight_out(w_0_0),
        .psum_out(p_00),
        .w_error(w_error),
        .a_error(a_error),
        .o_error(o_error)
    );

    // PE(0,1)
    PE_MAC1 pe01 (
        .clk(clk),
        .rst(rst),
        .activation_in(a_0_0),
        .weight_in(weight_in_1),
        .psum_in(16'd0),
        .test   (TEST),
        .shift  (SHIFT),
        .activation_out(a_0_1),
        .weight_out(w_0_1),
        .psum_out(p_01),
        .w_error(w_error),
        .a_error(a_error),
        .o_error(o_error)
    );

    // PE(1,0)
    PE_MAC1 pe10 (
        .clk(clk),
        .rst(rst),
        .activation_in(act_in_1),
        .weight_in(w_0_0),
        .psum_in(16'd0),
        .test   (TEST),
        .shift  (SHIFT),
        .activation_out(a_1_0),
        .weight_out(w_1_0),
        .psum_out(p_10),        
        .w_error(w_error),
        .a_error(a_error),
        .o_error(o_error)
    );

    // PE(1,1)
    PE_MAC1 pe11 (
        .clk(clk),
        .rst(rst),
        .activation_in(a_1_0),
        .weight_in(w_0_1),
        .psum_in(p_10),
        .test   (TEST),
        .shift  (SHIFT),
        .activation_out(a_1_1),
        .weight_out(w_1_1),
        .psum_out(p_11),        
        .w_error(w_error),
        .a_error(a_error),
        .o_error(o_error)
    );

    // 출력 매핑
    assign psum_out_0_0 = p_00;
    assign psum_out_0_1 = p_01;
    assign psum_out_1_0 = p_10;
    assign psum_out_1_1 = p_11;

endmodule
