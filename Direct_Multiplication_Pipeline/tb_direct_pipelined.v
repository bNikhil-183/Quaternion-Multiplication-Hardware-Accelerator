`timescale 1ns / 1ps

module tb_direct_pipelined;

    // Clock and input/output declarations
    reg clk1, clk2;
    reg signed [15:0] a1, b1, c1, d1;
    reg signed [15:0] a2, b2, c2, d2;
    wire signed [31:0] r1, r2, r3, r4;

    // Instantiate the DUT
    direct_pipelined uut (
        .clk1(clk1),
        .clk2(clk2),
        .a1(a1), .b1(b1), .c1(c1), .d1(d1),
        .a2(a2), .b2(b2), .c2(c2), .d2(d2),
        .r1(r1), .r2(r2), .r3(r3), .r4(r4)
    );

    // Clock generation
    initial clk1 = 0;
    always #5 clk1 = ~clk1;  // 100 MHz

    initial clk2 = 0;
    always #10 clk2 = ~clk2; // 50 MHz

    // Apply test vectors
    initial begin
        // Initialize inputs
        a1 = 0; b1 = 0; c1 = 0; d1 = 0;
        a2 = 0; b2 = 0; c2 = 0; d2 = 0;

        // Wait for clocks to stabilize
        #20;

        // Test Case 1
        a1 = 16'sd1; b1 = 16'sd0; c1 = 16'sd0; d1 = 16'sd0;
        a2 = 16'sd1; b2 = 16'sd0; c2 = 16'sd0; d2 = 16'sd0;
        #200;

        // Test Case 2
        a1 = 16'sd1; b1 = 16'sd2; c1 = 16'sd3; d1 = 16'sd4;
        a2 = 16'sd5; b2 = 16'sd6; c2 = 16'sd7; d2 = 16'sd8;
        #400;

        // Test Case 3
        a1 = -16'sd3; b1 = 16'sd4; c1 = -16'sd2; d1 = 16'sd1;
        a2 = 16'sd2; b2 = -16'sd1; c2 = 16'sd3; d2 = -16'sd4;
        #400;

        // End simulation
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0t | a1=%d b1=%d c1=%d d1=%d | a2=%d b2=%d c2=%d d2=%d | r1=%d r2=%d r3=%d r4=%d",
            $time, a1, b1, c1, d1, a2, b2, c2, d2, r1, r2, r3, r4);
    end

endmodule
