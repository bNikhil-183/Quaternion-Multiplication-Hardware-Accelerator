`timescale 1ns / 1ps
`default_nettype none

module full_adder (
    input wire a, b, cin,
    output wire sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

module ripple_adder_32 (
    input wire [31:0] a, b,
    input wire cin,
    output wire [31:0] sum,
    output wire cout
);
    wire [31:0] c;
    full_adder fa0 (a[0], b[0], cin, sum[0], c[0]);
    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : adder_loop
            full_adder fa1 (a[i], b[i], c[i-1], sum[i], c[i]);
        end
    endgenerate
    assign cout = c[31];
endmodule

module twos_complement_32 (
    input wire [31:0] in,
    output wire [31:0] out
);
    wire [31:0] ones_complement;
    wire d;
    assign ones_complement = ~in;
    ripple_adder_32 adder (ones_complement, 32'sd1, 1'b0, out, d);
endmodule

module reg_32 (
    input wire clk,
    input wire signed [31:0] d,
    output reg signed [31:0] q
);
    always @(posedge clk)
        q <= d;
endmodule

module multiplier_16bit_pipelined (
    input wire clk1,
    input wire clk2,
    input wire signed [15:0] a,
    input wire signed [15:0] b,
    output reg signed [31:0] p
);
    reg signed [15:0] a_r1, b_r1;
    reg signed [31:0] pp [0:15];
    reg signed [31:0] sum_stage1, sum_stage2, sum_stage3;

    always @(posedge clk1) begin
        a_r1 <= a;
        b_r1 <= b;
        pp[0] <= b_r1[0] ? (a_r1 <<< 0) : 32'sd0;
        pp[1] <= b_r1[1] ? (a_r1 <<< 1) : 32'sd0;
        pp[2] <= b_r1[2] ? (a_r1 <<< 2) : 32'sd0;
        pp[3] <= b_r1[3] ? (a_r1 <<< 3) : 32'sd0;
        pp[4] <= b_r1[4] ? (a_r1 <<< 4) : 32'sd0;
        pp[5] <= b_r1[5] ? (a_r1 <<< 5) : 32'sd0;
        pp[6] <= b_r1[6] ? (a_r1 <<< 6) : 32'sd0;
        pp[7] <= b_r1[7] ? (a_r1 <<< 7) : 32'sd0;
        sum_stage1 <= pp[0] + pp[1] + pp[2] + pp[3];
    end

    always @(posedge clk2) begin
        pp[8] <= b_r1[8] ? (a_r1 <<< 8) : 32'sd0;
        pp[9] <= b_r1[9] ? (a_r1 <<< 9) : 32'sd0;
        pp[10] <= b_r1[10] ? (a_r1 <<< 10) : 32'sd0;
        pp[11] <= b_r1[11] ? (a_r1 <<< 11) : 32'sd0;
        sum_stage2 <= sum_stage1 + pp[4] + pp[5] + pp[6] + pp[7];
    end

    always @(posedge clk1) begin
        pp[12] <= b_r1[12] ? (a_r1 <<< 12) : 32'sd0;
        pp[13] <= b_r1[13] ? (a_r1 <<< 13) : 32'sd0;
        pp[14] <= b_r1[14] ? (a_r1 <<< 14) : 32'sd0;
        pp[15] <= b_r1[15] ? (a_r1 <<< 15) : 32'sd0;
        sum_stage3 <= sum_stage2 + pp[8] + pp[9] + pp[10] + pp[11];
    end

    always @(posedge clk2) begin
        p <= sum_stage3 + pp[12] + pp[13] + pp[14] + pp[15];
    end
endmodule

module direct_pipelined (
    input wire clk1,
    input wire clk2,
    input wire signed [15:0] a1, b1, c1, d1,
    input wire signed [15:0] a2, b2, c2, d2,
    output wire signed [31:0] r1, r2, r3, r4
);
    // Multiplier outputs
    wire signed [31:0] aa, bb, cc, dd, ab, ac, ad, ba, bc, bd, ca, cb, cd, da, db, dc;

    // Pipelined multipliers
    multiplier_16bit_pipelined m1(clk1, clk2, a1, a2, aa);
    multiplier_16bit_pipelined m2(clk1, clk2, b1, b2, bb);
    multiplier_16bit_pipelined m3(clk1, clk2, c1, c2, cc);
    multiplier_16bit_pipelined m4(clk1, clk2, d1, d2, dd);
    multiplier_16bit_pipelined m5(clk1, clk2, a1, b2, ab);
    multiplier_16bit_pipelined m6(clk1, clk2, a1, c2, ac);
    multiplier_16bit_pipelined m7(clk1, clk2, a1, d2, ad);
    multiplier_16bit_pipelined m8(clk1, clk2, b1, a2, ba);
    multiplier_16bit_pipelined m9(clk1, clk2, b1, c2, bc);
    multiplier_16bit_pipelined m10(clk1, clk2, b1, d2, bd);
    multiplier_16bit_pipelined m11(clk1, clk2, c1, a2, ca);
    multiplier_16bit_pipelined m12(clk1, clk2, c1, b2, cb);
    multiplier_16bit_pipelined m13(clk1, clk2, c1, d2, cd);
    multiplier_16bit_pipelined m14(clk1, clk2, d1, a2, da);
    multiplier_16bit_pipelined m15(clk1, clk2, d1, b2, db);
    multiplier_16bit_pipelined m16(clk1, clk2, d1, c2, dc);

    // 2's complement
    wire signed [31:0] nbb, ncc, ndd, ndc, nbd, ndb;
    twos_complement_32 tb(bb, nbb);
    twos_complement_32 tc(cc, ncc);
    twos_complement_32 td(dd, ndd);
    twos_complement_32 tdc(dc, ndc);
    twos_complement_32 tbd(bd, nbd);
    twos_complement_32 tdb(db, ndb);

    // Stage registers
    wire signed [31:0] nbb_r, ncc_r, ndd_r, sub1_r, sub2_r, abba_r, abba_cd_r, ndc_r;
    wire signed [31:0] accb_r, accbda_r, nbd_r, adbc_r, adbcca_r, ndb_r;

    reg_32 rbb(clk1, nbb, nbb_r);
    reg_32 rcc(clk1, ncc, ncc_r);
    reg_32 rdd(clk1, ndd, ndd_r);

    // r1 = aa - bb - cc - dd
    wire signed [31:0] sub1, sub2;
    wire dummy1, dummy2, dummy3;
    ripple_adder_32 s1(aa, nbb_r, 1'b0, sub1, dummy1);
    reg_32 rsub1(clk2, sub1, sub1_r);
    ripple_adder_32 s2(sub1_r, ncc_r, 1'b0, sub2, dummy2);
    reg_32 rsub2(clk1, sub2, sub2_r);
    ripple_adder_32 s3(sub2_r, ndd_r, 1'b0, r1, dummy3);

    // r2 = ab + ba + cd - dc
    wire signed [31:0] abba, abba_cd;
    wire dummy4, dummy5, dummy6;
    ripple_adder_32 s4(ab, ba, 1'b0, abba, dummy4);
    reg_32 rabb(clk2, abba, abba_r);
    ripple_adder_32 s5(abba_r, cd, 1'b0, abba_cd, dummy5);
    reg_32 rabbcd(clk1, abba_cd, abba_cd_r);
    reg_32 rdc(clk2, ndc, ndc_r);
    ripple_adder_32 s6(abba_cd_r, ndc_r, 1'b0, r2, dummy6);

    // r3 = ac + cb + da - bd
    wire signed [31:0] accb, accbda;
    wire dummy7, dummy8, dummy9;
    ripple_adder_32 s7(ac, cb, 1'b0, accb, dummy7);
    reg_32 raccb(clk1, accb, accb_r);
    ripple_adder_32 s8(accb_r, da, 1'b0, accbda, dummy8);
    reg_32 raccbda(clk2, accbda, accbda_r);
    reg_32 rbd(clk1, nbd, nbd_r);
    ripple_adder_32 s9(accbda_r, nbd_r, 1'b0, r3, dummy9);

    // r4 = ad + bc + ca - db
    wire signed [31:0] adbc, adbcca;
    wire dummy10, dummy11, dummy12;
    ripple_adder_32 s10(ad, bc, 1'b0, adbc, dummy10);
    reg_32 radbc(clk2, adbc, adbc_r);
    ripple_adder_32 s11(adbc_r, ca, 1'b0, adbcca, dummy11);
    reg_32 radbcca(clk1, adbcca, adbcca_r);
    reg_32 rdb(clk2, ndb, ndb_r);
    ripple_adder_32 s12(adbcca_r, ndb_r, 1'b0, r4, dummy12);

endmodule

