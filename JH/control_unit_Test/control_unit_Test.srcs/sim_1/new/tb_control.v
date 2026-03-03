`timescale 1ns/1ps

module control_unit_tb;
  // Parameters
  localparam depth     = 4;
  localparam bit_width = 8;
  localparam acc_width = 32;
  localparam size      = 4;

  // Ports
  reg clk;
  reg rst;
  reg faulty_flag;
  wire control;
  wire scan_en;

  // Instantiate DUT
  control_unit #(
    .depth(depth),
    .bit_width(bit_width),
    .acc_width(acc_width),
    .size(size)
  ) uut (
    .clk(clk),
    .rst(rst),
    .faulty_flag(faulty_flag),
    .control(control),
    .scan_en(scan_en)
  );

  // Clock generation: 10ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    // Initialize signals
    rst         = 1;
    faulty_flag = 0;

    // Release reset after a few cycles
    #20;
    rst = 0;

    // Wait for W_LOAD and MAC states
    #((depth+5)*10);

    // Inject fault to trigger SCAN
    faulty_flag = 1;
    #50;

    // Clear fault
    faulty_flag = 0;
    #50;

    // Finish simulation
    $finish;
  end

  // Monitor outputs
  initial begin
    $display("Time\tclk\trst\tfaulty_flag\tcontrol\tscan_en");
    $monitor("%0dns\t%b\t%b\t%b\t%b\t%b", $time, clk, rst, faulty_flag, control, scan_en);
  end

endmodule