module tb_SystolicArray2x2;

    reg clk;
    reg rst;

    reg [7:0] act_in_0, act_in_1;
    reg [7:0] weight_in_0, weight_in_1;

    wire [15:0] psum_out_0_0, psum_out_0_1;
    wire [15:0] psum_out_1_0, psum_out_1_1;
    wire w_error;
    wire a_error;   
    wire o_error;   

    // Instantiate your systolic array (2x2)
    SystolicArray2x2 dut (
        .clk(clk),
        .rst(rst),
        .act_in_0(act_in_0),
        .act_in_1(act_in_1),
        .weight_in_0(weight_in_0),
        .weight_in_1(weight_in_1),
        .psum_out_0_0(psum_out_0_0),
        .psum_out_0_1(psum_out_0_1),
        .psum_out_1_0(psum_out_1_0),
        .psum_out_1_1(psum_out_1_1),
        .w_error(w_error),
        .a_error(a_error),
        .o_error(o_error)

    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("---- Systolic Array 2x2 Test ----");
        clk = 0;
        rst = 1;

        // 초기값
        act_in_0 = 0; act_in_1 = 0;
        weight_in_0 = 0; weight_in_1 = 0;

        #15 rst = 0;

        // Cycle 1: A[:,0] = [1,3], W[0,:] = [1,2]
        act_in_0 = 8'd2;
        weight_in_0 = 8'd3;
        #100
        
        act_in_0 = 8'd1;
        weight_in_0 = 8'd1;
        act_in_1 = 8'd4;
        weight_in_1 = 8'd4;
        #100
         act_in_0 = 8'd0;
        weight_in_0 = 8'd0;
        
        act_in_1 = 8'd3;
        weight_in_1 = 8'd2;
        #100
        
        act_in_1 = 8'd0;
        weight_in_1 = 8'd0;
     

        #50; // 연산 완료까지 기다림

        // 결과 확인
        $display("Expected: O[0][0]=7, O[0][1]=10, O[1][0]=15, O[1][1]=22");
        $display("Received: %d %d %d %d", 
            psum_out_0_0, psum_out_0_1, psum_out_1_0, psum_out_1_1);

        // 검증
        if (psum_out_0_0 !== 16'd7)  $display("Mismatch at O[0][0]");
        if (psum_out_0_1 !== 16'd10) $display("Mismatch at O[0][1]");
        if (psum_out_1_0 !== 16'd15) $display("Mismatch at O[1][0]");
        if (psum_out_1_1 !== 16'd22) $display("Mismatch at O[1][1]");
        else                         $display("All outputs match expected results!");

        $finish;
    end
endmodule
