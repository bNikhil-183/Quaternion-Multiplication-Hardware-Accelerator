`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.08.2025 00:20:38
// Design Name: 
// Module Name: multiplication_algorithmic
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


module modified_rca (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] sum
);
    wire [31:0] g, p, c;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) 
		     begin
                assign g[i] = a[i] & b[i];
                assign p[i] = a[i] ^ b[i];
           end
    endgenerate

    assign c[0] = 1'b0;
    generate
        for (i = 1; i < 32; i = i + 1) 
		      begin
               assign c[i] = g[i-1] | (p[i-1] & c[i-1]);
            end
    endgenerate

    assign sum = p ^ c;
endmodule

//booth_multiplier

module booth_multiplier (
    input clk,
    input rst,
    input signed [15:0] multiplicand,
    input signed [15:0] multiplier,
    output reg signed [31:0] result
);
    reg signed [33:0] product;         // 17-bit accumulator + 16-bit multiplier + 1 bit
    reg signed [16:0] M;               // Sign-extended multiplicand
    reg [3:0] cycle;                   // 8 Booth cycles

    reg signed [33:0] temp_product;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            product <= 34'd0;
            M <= 17'd0;
            cycle <= 4'd0;
            result <= 32'sd0;
        end else begin
            if (cycle == 0) begin
                // Initialization
                M <= {multiplicand[15], multiplicand};     // Sign extend multiplicand
                product <= {17'd0, multiplier, 1'b0};      // Append 0 at LSB
                cycle <= 4'd8;
            end else begin
                // Use blocking assignments to avoid race conditions
                temp_product = product;

                // Booth encoding on lowest 3 bits
                case (product[2:0])
                    3'b000, 3'b111: ; // No operation
                    3'b001, 3'b010: temp_product[33:17] = temp_product[33:17] + M;              // +M
                    3'b011:         temp_product[33:17] = temp_product[33:17] + (M <<< 1);      // +2M
                    3'b100:         temp_product[33:17] = temp_product[33:17] - (M <<< 1);      // -2M
                    3'b101, 3'b110: temp_product[33:17] = temp_product[33:17] - M;              // -M
                endcase

                // Arithmetic right shift by 2
                product <= $signed(temp_product) >>> 2;

                cycle <= cycle - 1;

               if (product[32] == 1'b0) result <= product[32:1] >>> 2;
	           	else result <= $signed(product[32:1]) >>> 2 ;
            end
        end
    end
endmodule	

//baugh wooley

module baugh_wooley (
    input  signed [15:0] a,
    input  signed [15:0] b,
    output signed [31:0] product
);
    wire [31:0] partial[15:0];

    genvar i, j;
    generate
        for (i = 0; i < 16; i = i + 1) 
		     begin
                 for (j = 0; j < 16; j = j + 1) begin 
                 assign partial[i][i+j] = ((i == 15) ^ (j == 15)) ? ~(a[i] & b[j]) : (a[i] & b[j]);
end
            //filling left over bits with zero
            for (j = 0; j < i; j = j + 1) begin
            assign partial[i][j] = 1'b0;
            end
            for (j = i + 16; j < 32; j = j + 1) begin
             assign partial[i][j] = 1'b0;
             end
           end
    endgenerate
	 
//adding all partial sums 
    reg signed [31:0] sum;
    integer k;
    always @(*)
	  begin
           sum = 32'h00010001;  //error bit
           for (k = 0; k < 16; k = k + 1)
           sum = sum + partial[k];
     end

    assign product = sum;
endmodule


//quaternion multiplier
module multiplication_algorithmic (
    input  clk,
    input  rst,
    input  signed [15:0] a0, a1, a2, a3,
    input  signed [15:0] b0, b1, b2, b3,
    output signed [31:0] q0, q1, q2, q3
);
    wire signed [31:0] t[0:15];

   baugh_wooley m0 (.a(a0), .b(b0), .product(t[0]));
	booth_multiplier m1 (.clk(clk), .rst(rst), .multiplicand(a1), .multiplier(b1), .result(t[1]));
	booth_multiplier m2 (.clk(clk), .rst(rst), .multiplicand(a2), .multiplier(b2), .result(t[2]));
	baugh_wooley m3 (.a(a3), .b(b3), .product(t[3]));

    booth_multiplier m12 (.clk(clk), .rst(rst), .multiplicand(a0), .multiplier(b3), .result(t[12]));
    baugh_wooley m13 (.a(a2), .b(b1), .product(t[13]));
    baugh_wooley m14 (.a(a1), .b(b2), .product(t[14]));
    booth_multiplier m15 (.clk(clk), .rst(rst), .multiplicand(a3), .multiplier(b0), .result(t[15]));

    booth_multiplier m4  (.clk(clk), .rst(rst), .multiplicand(a0), .multiplier(b1), .result(t[4]));
    booth_multiplier m5  (.clk(clk), .rst(rst), .multiplicand(a1), .multiplier(b0), .result(t[5]));
    booth_multiplier m6  (.clk(clk), .rst(rst), .multiplicand(a2), .multiplier(b3), .result(t[6]));
    booth_multiplier m7  (.clk(clk), .rst(rst), .multiplicand(a3), .multiplier(b2), .result(t[7]));

    booth_multiplier m8  (.clk(clk), .rst(rst), .multiplicand(a0), .multiplier(b2), .result(t[8]));
    booth_multiplier m9  (.clk(clk), .rst(rst), .multiplicand(a1), .multiplier(b3), .result(t[9]));
    booth_multiplier m10 (.clk(clk), .rst(rst), .multiplicand(a2), .multiplier(b0), .result(t[10]));
    booth_multiplier m11 (.clk(clk), .rst(rst), .multiplicand(a3), .multiplier(b1), .result(t[11]));

	 wire signed [31:0] s01, s02, s11, s12, s21, s22, s31, s32;

    modified_rca add0 (.a(t[1]), .b(t[2]), .sum(s01));
    modified_rca add1 (.a(s01), .b(t[3]), .sum(s02));
    modified_rca sub0 (.a(t[0]), .b(~s02 + 1), .sum(q0));
	    
	 modified_rca add2 (.a(t[4]), .b(t[5]), .sum(s11));
    modified_rca add3 (.a(s11), .b(t[6]), .sum(s12));
    modified_rca sub1 (.a(s12), .b(~t[7] + 1), .sum(q1));

    modified_rca sub2 (.a(t[8]), .b(~t[9] + 1), .sum(s21));
    modified_rca add4 (.a(s21), .b(t[10]), .sum(s22));
    modified_rca add5 (.a(s22), .b(t[11]), .sum(q2));

    modified_rca sub3 (.a(t[12]), .b(~t[13] + 1), .sum(s31));
    modified_rca add6 (.a(s31), .b(t[14]), .sum(s32));
    modified_rca add7 (.a(s32), .b(t[15]), .sum(q3));
endmodule

               
	