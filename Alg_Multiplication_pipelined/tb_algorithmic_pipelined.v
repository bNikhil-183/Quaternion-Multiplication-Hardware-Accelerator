// Testbench
//////////////////////////////////////////////////////////////////////////////////
module tb_algorithmic_pipelined;
    reg clk = 0;   
    reg rst;
    reg start;
    reg signed [15:0] a0, a1, a2, a3;
    reg signed [15:0] b0, b1, b2, b3;

    wire signed [31:0] q0, q1, q2, q3;
    wire done;

    algorithmic_multiplication_pipelined uut (
        .clk(clk), .rst(rst), .start(start),
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .q0(q0), .q1(q1), .q2(q2), .q3(q3),
        .done(done)
    );

    always #5 clk = ~clk;  

    initial begin
        $display("Starting Quaternion Multiplication Testbench");
        $dumpfile("algorithmic_pipeline.vcd");
        $dumpvars(0, tb_algorithmic_pipelined);

        rst = 1;
        start = 0;
        
        #20 rst = 0;

        // A = 1 + 2i + 3j + 4k
        // B = 5 + 6i + 7j + 8k
        a0 = 16'sd1; a1 = 16'sd2; a2 = 16'sd3; a3 = 16'sd4;
        b0 = 16'sd5; b1 = 16'sd6; b2 = 16'sd7; b3 = 16'sd8;

        #10 start = 1;
        #10 start = 0;

        wait (done == 1);

        // Allow 3 internal CLA stages (9 cycles min latency) to ripple through
        #150; 

        $display("\nQuaternion Result:");
        $display("q0 = %d (Expected: -60)", q0);
        $display("q1 = %d (Expected:  12)", q1);
        $display("q2 = %d (Expected:  30)", q2);
        $display("q3 = %d (Expected:  24)", q3);

        #50;
        $finish;
    end
endmodule