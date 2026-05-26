`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.08.2025 00:23:48
// Design Name: 
// Module Name: algorithmic_multiplication_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module algorithmic_multiplication_tb;

    // Clock and Reset
    reg clk;
    reg rst;

    // Inputs
    reg signed [15:0] a0, a1, a2, a3;
    reg signed [15:0] b0, b1, b2, b3;

    // Outputs
    wire signed [31:0] q0, q1, q2, q3;

    // Instantiate the Unit Under Test (UUT)
    quaternion_multiplication uut (
        .clk(clk),
        .rst(rst),
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .q0(q0), .q1(q1), .q2(q2), .q3(q3)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        a0 = 0; a1 = 0; a2 = 0; a3 = 0;
        b0 = 0; b1 = 0; b2 = 0; b3 = 0;

        // Wait for global reset
        #10;
        rst = 0;

        // Test Case 1
        a0 = 16'sd1; a1 = 16'sd2; a2 = 16'sd3; a3 = 16'sd4;
        b0 = 16'sd5; b1 = 16'sd6; b2 = 16'sd7; b3 = 16'sd8;

        #100; // wait for computation

        // Test Case 2
        a0 = -16'sd1; a1 = 16'sd0; a2 = -16'sd3; a3 = 16'sd2;
        b0 = 16'sd2;  b1 = -16'sd1; b2 = 16'sd1; b3 = 16'sd0;

        #100;

        // Test Case 3: All zero
        a0 = 0; a1 = 0; a2 = 0; a3 = 0;
        b0 = 0; b1 = 0; b2 = 0; b3 = 0;

        #100;

        $finish;
    end

    // Display results
    always @(posedge clk) begin
        $display("Time=%0t | q = (%0d, %0d, %0d, %0d)", $time, q0, q1, q2, q3);
    end

endmodule

  

  
        