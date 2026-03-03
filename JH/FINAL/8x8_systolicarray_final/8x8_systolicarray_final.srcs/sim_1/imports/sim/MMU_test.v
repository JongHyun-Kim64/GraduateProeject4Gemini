`timescale 1ns / 1ps

module test_TPU;

    // Parameters for 8x8
    reg clk;
    reg rst;
    reg [63:0] data_arr;
    reg [63:0] wt_arr;
    wire [255:0] acc_out;

    // MMU 인스턴스 (포트 사이즈에 맞게)
    MMU uut (
        .clk(clk),
        .rst(rst),
        .data_arr(data_arr),
        .wt_arr(wt_arr),
        .acc_out(acc_out)
    );

    always #250 clk = !clk;

    integer i;

    initial begin
        // Initialize Inputs
        clk = 0;
        data_arr = 0;
        wt_arr = 0;
        rst = 1;
        #1000;
        rst = 0;
        @(posedge clk);
        @(posedge clk);

        // 가중치 프리로드 (맨 아래 행부터)
        @(posedge clk); wt_arr = 64'h 77_76_75_74_73_72_71_70; // row 7
        @(posedge clk); wt_arr = 64'h 67_66_65_64_63_62_61_60; // row 6
        @(posedge clk); wt_arr = 64'h 57_56_55_54_53_52_51_50; // row 5
        @(posedge clk); wt_arr = 64'h 47_46_45_44_43_42_41_40; // row 4
        @(posedge clk); wt_arr = 64'h 37_36_35_34_33_32_31_30; // row 3
        @(posedge clk); wt_arr = 64'h 27_26_25_24_23_22_21_20; // row 2
        @(posedge clk); wt_arr = 64'h 17_16_15_14_13_12_11_10; // row 1
        @(posedge clk); wt_arr = 64'h 07_06_05_04_03_02_01_00; // row 0
        @(posedge clk); wt_arr = 0; // idle

        // 데이터 입력 (왼쪽에서 오른쪽으로 한 칸씩 shift)
        @(posedge clk); data_arr = 64'h 00_00_00_00_00_00_00_07;
        @(posedge clk); data_arr = 64'h 00_00_00_00_00_00_17_06;
        @(posedge clk); data_arr = 64'h 00_00_00_00_00_27_16_05;
        @(posedge clk); data_arr = 64'h 00_00_00_00_37_26_15_04;
        @(posedge clk); data_arr = 64'h 00_00_00_47_36_25_14_03;
        @(posedge clk); data_arr = 64'h 00_00_57_46_35_24_13_02;
        @(posedge clk); data_arr = 64'h 00_67_56_45_34_23_12_01;
        @(posedge clk); data_arr = 64'h 77_66_55_44_33_22_11_00;
        @(posedge clk); data_arr = 64'h 76_65_54_43_32_21_10_00;
        @(posedge clk); data_arr = 64'h 75_64_53_42_31_20_00_00;
        @(posedge clk); data_arr = 64'h 74_63_52_41_30_00_00_00;
        @(posedge clk); data_arr = 64'h 73_62_51_40_00_00_00_00;
        @(posedge clk); data_arr = 64'h 72_61_50_00_00_00_00_00;
        @(posedge clk); data_arr = 64'h 71_60_00_00_00_00_00_00;
        @(posedge clk); data_arr = 64'h 70_00_00_00_00_00_00_00;
        @(posedge clk); data_arr = 64'h 00_00_00_00_00_00_00_00;

        // 파이프라인 flush (여유 주기)
        repeat(12) @(posedge clk);

        $finish();
    end

    // 출력 모니터링: col7~col0 (acc_out[255:224] ~ acc_out[31:0])
    initial begin
        $monitor("[OUTPUT] time=%0t y7=0x%0h, y6=0x%0h, y5=0x%0h, y4=0x%0h, y3=0x%0h, y2=0x%0h, y1=0x%0h, y0=0x%0h",
            $time,
            acc_out[255:224], acc_out[223:192], acc_out[191:160], acc_out[159:128],
            acc_out[127:96],   acc_out[95:64],   acc_out[63:32],   acc_out[31:0]
        );
    end

endmodule
