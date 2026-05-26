`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.08.2025 12:57:22
// Design Name: 
// Module Name: direct_multiplication
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


`timescale 1ns / 1ps

//full adder

module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

//ripple adder 16

module ripple_adder_16 (
    input [15:0] a, b,
    input cin,
    output [15:0] sum,
    output cout
);
    wire [15:0] c;
    full_adder fa0 (a[0], b[0], cin, sum[0], c[0]);
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin
            full_adder fa1 (a[i], b[i], c[i-1], sum[i], c[i]);
        end
    endgenerate
    assign cout = c[15];
endmodule

//ripple adder 32

module ripple_adder_32 (
    input [31:0] a, b,
    input cin,
    output [31:0] sum,
    output cout
);
    wire [31:0] c;
    full_adder fa0 (a[0], b[0], cin, sum[0], c[0]);
    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin
            full_adder fa1 (a[i], b[i], c[i-1], sum[i], c[i]);
        end
    endgenerate
    assign cout = c[31];
endmodule

// 2's complement 16

module twos_complement_16(
    input [15:0] in,
    output [15:0] out
);
    wire [15:0] ones_complement;
    wire d;
    assign ones_complement = ~in;
    ripple_adder_16 adder (ones_complement, 16'b1, 1'b0, out, d);
endmodule

// 2's complement 32

module twos_complement_32(
    input [31:0] in,
    output [31:0] out
);
    wire [31:0] ones_complement;
    wire d;
    assign ones_complement = ~in;
    ripple_adder_32 adder (ones_complement, 32'b1, 1'b0, out, d);
endmodule

// multiplier 16 bit

module multiplier_16bit(
    input signed [15:0] a,
    input signed [15:0] b,
    output signed [31:0] product
);
    wire [31:0] t[15:0];
    wire a_pp = a[15];
    wire b_pp = b[15];
    wire [15:0] abs_a, abs_b;
    wire [15:0] k_a, k_b;
    twos_complement_16 tc_a(a, k_a);
    twos_complement_16 tc_b(b, k_b);
    assign abs_a = a_pp ? k_a : a;
    assign abs_b = b_pp ? k_b : b;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pp_loop
            assign t[i] = ({16'b0, abs_a} & {32{abs_b[i]}}) << i;
        end
    endgenerate

    wire [31:0] sum1, sum2, sum3, sum4, sum5, sum6, sum7, sum8;
    wire [31:0] sum9, sum10, sum11, sum12, sum13, sum14, final_sum;
    wire d1, d2, d3, d4, d5, d6, d7, d8;
    wire d9, d10, d11, d12, d13, d14, d15;

    ripple_adder_32 add1 (t[0], t[1], 1'b0, sum1, d1);
    ripple_adder_32 add2 (t[2], t[3], 1'b0, sum2, d2);
    ripple_adder_32 add3 (t[4], t[5], 1'b0, sum3, d3);
    ripple_adder_32 add4 (t[6], t[7], 1'b0, sum4, d4);
    ripple_adder_32 add5 (t[8], t[9], 1'b0, sum5, d5);
    ripple_adder_32 add6 (t[10], t[11], 1'b0, sum6, d6);
    ripple_adder_32 add7 (t[12], t[13], 1'b0, sum7, d7);
    ripple_adder_32 add8 (t[14], t[15], 1'b0, sum8, d8);

    ripple_adder_32 add9  (sum1, sum2, 1'b0, sum9, d9);
    ripple_adder_32 add10 (sum3, sum4, 1'b0, sum10, d10);
    ripple_adder_32 add11 (sum5, sum6, 1'b0, sum11, d11);
    ripple_adder_32 add12 (sum7, sum8, 1'b0, sum12, d12);

    ripple_adder_32 add13 (sum9, sum10, 1'b0, sum13, d13);
    ripple_adder_32 add14 (sum11, sum12, 1'b0, sum14, d14);

    ripple_adder_32 add15 (sum13, sum14, 1'b0, final_sum, d15);

    wire [31:0] k_out;
    twos_complement_32 tc_out(final_sum, k_out);
    assign product = a[15] ^ b[15] ? k_out : final_sum;
endmodule

// direct

module direct_multiplication(
    input signed [15:0] a1, b1, c1, d1,
    input signed [15:0] a2, b2, c2, d2,
    output [31:0] r1, r2, r3, r4
);
    wire signed [31:0] aa, bb, cc, dd, ab, ba, cd, dc, ac, bd, ca, db, ad, bc, cb, da;
    wire [31:0] k1, k2, k3, k4, k5, k6, k7, k8;
    wire d13, d14, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12;

    multiplier_16bit m1(a1, a2, aa);
    multiplier_16bit m2(b1, b2, bb);
    multiplier_16bit m3(c1, c2, cc);
    multiplier_16bit m4(d1, d2, dd);
    multiplier_16bit m5(a1, b2, ab);
    multiplier_16bit m6(b1, a2, ba);
    multiplier_16bit m7(c1, d2, cd);
    multiplier_16bit m8(d1, c2, dc);
    multiplier_16bit m9(a1, c2, ac);
    multiplier_16bit m10(b1, d2, bd);
    multiplier_16bit m11(c1, a2, ca);
    multiplier_16bit m12(d1, b2, db);
    multiplier_16bit m13(a1, d2, ad);
    multiplier_16bit m14(b1, c2, bc);
    multiplier_16bit m15(c1, b2, cb);
    multiplier_16bit m16(d1, a2, da);

    wire [31:0] pp_bb, pp_cc, pp_dd;
    twos_complement_32 pp1(bb, pp_bb);
    ripple_adder_32 sub1(aa, pp_bb, 1'b0, k1, d13);
    twos_complement_32 pp2(cc, pp_cc);
    ripple_adder_32 sub2(k1, pp_cc, 1'b0, k2, d14);
    twos_complement_32 pp3(dd, pp_dd);
    ripple_adder_32 sub3(k2, pp_dd, 1'b0, r1, d3);

    ripple_adder_32 add1(ab, ba, 1'b0, k3, d4);
    ripple_adder_32 add2(k3, cd, 1'b0, k4, d5);
    wire [31:0] pp_dc;
    twos_complement_32 pp4(dc, pp_dc);
    ripple_adder_32 sub4(k4, pp_dc, 1'b0, r2, d6);

    wire [31:0] pp_bd;
    twos_complement_32 pp5(bd, pp_bd);
    ripple_adder_32 sub5(ac, pp_bd, 1'b0, k5, d7);
    ripple_adder_32 add3(k5, ca, 1'b0, k6, d8);
    ripple_adder_32 add4(k6, db, 1'b0, r3, d9);

    ripple_adder_32 add5(ad, bc, 1'b0, k7, d10);
    wire [31:0] pp_cb;
    twos_complement_32 pp6(cb, pp_cb);
    ripple_adder_32 sub6(k7, pp_cb, 1'b0, k8, d11);
    ripple_adder_32 add6(k8, da, 1'b0, r4, d12);
endmodule
 

  
  