`timescale 1ns / 1ps

module test_TPU;

    // Parameters for 10x10
    reg clk;
    reg rst;
    reg [79:0] data_arr; // 10*8=80bit
    reg [79:0] wt_arr;
    wire [319:0] acc_out;

    // MMU 인스턴스 (포트 사이즈에 맞게)
    MMU uut (
        .clk(clk),
        .rst(rst),
        .data_arr(data_arr),
        .wt_arr(wt_arr),
        .acc_out(acc_out)
    );

    always #250 clk = !clk;

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

        // 가중치 프리로드 (맨 아래 행부터, row 9~0)
        @(posedge clk); wt_arr = 80'h 99_98_97_96_95_94_93_92_91_90; // row 9
        @(posedge clk); wt_arr = 80'h 89_88_87_86_85_84_83_82_81_80; // row 8
        @(posedge clk); wt_arr = 80'h 79_78_77_76_75_74_73_72_71_70; // row 7
        @(posedge clk); wt_arr = 80'h 69_68_67_66_65_64_63_62_61_60; // row 6
        @(posedge clk); wt_arr = 80'h 59_58_57_56_55_54_53_52_51_50; // row 5
        @(posedge clk); wt_arr = 80'h 49_48_47_46_45_44_43_42_41_40; // row 4
        @(posedge clk); wt_arr = 80'h 39_38_37_36_35_34_33_32_31_30; // row 3
        @(posedge clk); wt_arr = 80'h 29_28_27_26_25_24_23_22_21_20; // row 2
        @(posedge clk); wt_arr = 80'h 19_18_17_16_15_14_13_12_11_10; // row 1
        @(posedge clk); wt_arr = 80'h 09_08_07_06_05_04_03_02_01_00; // row 0
        @(posedge clk); wt_arr = 0; // idle

        // 데이터 입력 (각 줄 한 칸씩 우로 shift, LSB가 col9)
        @(posedge clk); data_arr = 80'h 00_00_00_00_00_00_00_00_00_09;
        @(posedge clk); data_arr = 80'h 00_00_00_00_00_00_00_00_19_08;
        @(posedge clk); data_arr = 80'h 00_00_00_00_00_00_00_29_18_07;
        @(posedge clk); data_arr = 80'h 00_00_00_00_00_00_39_28_17_06;
        @(posedge clk); data_arr = 80'h 00_00_00_00_00_49_38_27_16_05;
        @(posedge clk); data_arr = 80'h 00_00_00_00_59_48_37_26_15_04;
        @(posedge clk); data_arr = 80'h 00_00_00_69_58_47_36_25_14_03;
        @(posedge clk); data_arr = 80'h 00_00_79_68_57_46_35_24_13_02;
        @(posedge clk); data_arr = 80'h 00_89_78_67_56_45_34_23_12_01;
        @(posedge clk); data_arr = 80'h 99_88_77_66_55_44_33_22_11_00;
        @(posedge clk); data_arr = 80'h 98_87_76_65_54_43_32_21_10_00;
        @(posedge clk); data_arr = 80'h 97_86_75_64_53_42_31_20_00_00;
        @(posedge clk); data_arr = 80'h 96_85_74_63_52_41_30_00_00_00;
        @(posedge clk); data_arr = 80'h 95_84_73_62_51_40_00_00_00_00;
        @(posedge clk); data_arr = 80'h 94_83_72_61_50_00_00_00_00_00;
        @(posedge clk); data_arr = 80'h 93_82_71_60_00_00_00_00_00_00;
        @(posedge clk); data_arr = 80'h 92_81_70_00_00_00_00_00_00_00;
        @(posedge clk); data_arr = 80'h 91_80_00_00_00_00_00_00_00_00;
        @(posedge clk); data_arr = 80'h 90_00_00_00_00_00_00_00_00_00;
        @(posedge clk); data_arr = 80'h 00_00_00_00_00_00_00_00_00_00;

        // 파이프라인 flush (여유 주기)
        repeat(12) @(posedge clk);

        $finish();
    end

    // 출력 모니터링: col9~col0 (acc_out[319:288] ~ acc_out[31:0])
    initial begin
        $monitor("[OUTPUT] time=%0t y9=0x%0h, y8=0x%0h, y7=0x%0h, y6=0x%0h, y5=0x%0h, y4=0x%0h, y3=0x%0h, y2=0x%0h, y1=0x%0h, y0=0x%0h",
            $time,
            acc_out[319:288], acc_out[287:256], acc_out[255:224], acc_out[223:192],
            acc_out[191:160], acc_out[159:128], acc_out[127:96],  acc_out[95:64],
            acc_out[63:32],   acc_out[31:0]
        );
    end

endmodule
