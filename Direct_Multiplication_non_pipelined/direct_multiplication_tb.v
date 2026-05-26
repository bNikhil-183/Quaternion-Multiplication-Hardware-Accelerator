`timescale 1ns / 1ps

module direct_multiplication_tb;

    // Inputs
    reg signed [15:0] a1, b1, c1, d1;
    reg signed [15:0] a2, b2, c2, d2;

    // Outputs
    wire [31:0] r1, r2, r3, r4;

    // Instantiate the Unit Under Test (UUT)
    direct_multiplication uut (
        .a1(a1), .b1(b1), .c1(c1), .d1(d1),
        .a2(a2), .b2(b2), .c2(c2), .d2(d2),
        .r1(r1), .r2(r2), .r3(r3), .r4(r4)
    );

    initial begin
        $display("Time\t\t a1\t b1\t c1\t d1\t | a2\t b2\t c2\t d2\t || r1\t\t r2\t\t r3\t\t r4");
        $monitor("%0t\t %d\t %d\t %d\t %d\t | %d\t %d\t %d\t %d\t || %d\t %d\t %d\t %d",
                 $time, a1, b1, c1, d1, a2, b2, c2, d2, r1, r2, r3, r4);

        // Test 1: Identity Quaternion * Any Quaternion
        a1 = 16'd1; b1 = 16'd0; c1 = 16'd0; d1 = 16'd0;
        a2 = 16'd2; b2 = 16'd3; c2 = 16'd4; d2 = 16'd5;
        #20;

        // Test 2: Quaternion * Identity
        a1 = 16'd2; b1 = 16'd3; c1 = 16'd4; d1 = 16'd5;
        a2 = 16'd1; b2 = 16'd0; c2 = 16'd0; d2 = 16'd0;
        #20;

        // Test 3: Negative values
        a1 = -16'sd1; b1 = -16'sd2; c1 = -16'sd3; d1 = -16'sd4;
        a2 =  16'sd4; b2 =  16'sd3; c2 =  16'sd2; d2 =  16'sd1;
        #20;

        // Test 4: Both inputs zero
        a1 = 16'd0; b1 = 16'd0; c1 = 16'd0; d1 = 16'd0;
        a2 = 16'd0; b2 = 16'd0; c2 = 16'd0; d2 = 16'd0;
        #20;

        // Test 5: Large magnitude inputs
        a1 = 16'sd30000; b1 = 16'sd20000; c1 = -16'sd15000; d1 = 16'sd10000;
        a2 = -16'sd10000; b2 = 16'sd15000; c2 = -16'sd20000; d2 = 16'sd30000;
        #20;

        $finish;
    end
endmodule
