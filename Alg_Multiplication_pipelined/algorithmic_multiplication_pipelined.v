`timescale 1ns / 1ps

module algorithmic_multiplication_pipelined (
    input wire clk, 
    input wire rst,
    input wire start,
    input signed [15:0] a0, a1, a2, a3,
    input signed [15:0] b0, b1, b2, b3,
    output signed [31:0] q0, q1, q2, q3,
    output done
);

    wire signed [31:0] m[0:15];
    reg [15:0] m_done_reg;
    wire [15:0] m_done;

    /////////////////////////////////
    // Stage 1: 16 Parallel Multiplies 
    /////////////////////////////////
    booth_multiplier_pipelined   M0 (.clk(clk), .rst(rst), .start(start), .multiplicand(a0), .multiplier(b0), .result(m[0]), .done(m_done[0]));
    baugh_wooley_pipelined       M1 (.clk(clk), .rst(rst), .start(start), .a(a1), .b(b1), .product(m[1]), .done(m_done[1]));
    booth_multiplier_pipelined   M2 (.clk(clk), .rst(rst), .start(start), .multiplicand(a2), .multiplier(b2), .result(m[2]), .done(m_done[2]));
    baugh_wooley_pipelined       M3 (.clk(clk), .rst(rst), .start(start), .a(a3), .b(b3), .product(m[3]), .done(m_done[3]));
    
    booth_multiplier_pipelined   M4 (.clk(clk), .rst(rst), .start(start), .multiplicand(a0), .multiplier(b1), .result(m[4]), .done(m_done[4]));
    baugh_wooley_pipelined       M5 (.clk(clk), .rst(rst), .start(start), .a(a1), .b(b0), .product(m[5]), .done(m_done[5]));
    booth_multiplier_pipelined   M6 (.clk(clk), .rst(rst), .start(start), .multiplicand(a0), .multiplier(b2), .result(m[6]), .done(m_done[6]));
    baugh_wooley_pipelined       M7 (.clk(clk), .rst(rst), .start(start), .a(a2), .b(b0), .product(m[7]), .done(m_done[7]));
    
    booth_multiplier_pipelined   M8 (.clk(clk), .rst(rst), .start(start), .multiplicand(a0), .multiplier(b3), .result(m[8]), .done(m_done[8]));
    baugh_wooley_pipelined       M9 (.clk(clk), .rst(rst), .start(start), .a(a3), .b(b0), .product(m[9]), .done(m_done[9]));
    booth_multiplier_pipelined  M10 (.clk(clk), .rst(rst), .start(start), .multiplicand(a1), .multiplier(b2), .result(m[10]), .done(m_done[10]));
    baugh_wooley_pipelined      M11 (.clk(clk), .rst(rst), .start(start), .a(a2), .b(b1), .product(m[11]), .done(m_done[11]));
    
    booth_multiplier_pipelined  M12 (.clk(clk), .rst(rst), .start(start), .multiplicand(a1), .multiplier(b3), .result(m[12]), .done(m_done[12]));
    baugh_wooley_pipelined      M13 (.clk(clk), .rst(rst), .start(start), .a(a3), .b(b1), .product(m[13]), .done(m_done[13]));
    booth_multiplier_pipelined  M14 (.clk(clk), .rst(rst), .start(start), .multiplicand(a2), .multiplier(b3), .result(m[14]), .done(m_done[14]));
    baugh_wooley_pipelined      M15 (.clk(clk), .rst(rst), .start(start), .a(a3), .b(b2), .product(m[15]), .done(m_done[15]));
    
    // Latch done bits to detect completion
    always @(posedge clk or posedge rst) begin
        if (rst)
            m_done_reg <= 16'd0;
        else
            m_done_reg <= m_done_reg | m_done; 
    end

    assign done = (m_done_reg == 16'hFFFF);
    
    /////////////////////////////////
    // Stage 2: 12 Add/Sub Cascades
    /////////////////////////////////
    wire signed [31:0] t0, t1, t2, t3, t4, t5, t6, t7;

    // q0 = a0*b0 - a1*b1 - a2*b2 - a3*b3
    cla32_pipelined SUB1 (.clk(clk), .rst(rst), .a(m[0]), .b(-m[1]), .sum(t0));
    cla32_pipelined SUB2 (.clk(clk), .rst(rst), .a(t0), .b(-m[2]), .sum(t1));
    cla32_pipelined SUB3 (.clk(clk), .rst(rst), .a(t1), .b(-m[3]), .sum(q0));

    // q1 = a0*b1 + a1*b0 + a2*b3 - a3*b2 
    cla32_pipelined ADD1 (.clk(clk), .rst(rst), .a(m[4]), .b(m[5]), .sum(t2));
    cla32_pipelined ADD2 (.clk(clk), .rst(rst), .a(t2), .b(m[14]), .sum(t3));
    cla32_pipelined SUB4 (.clk(clk), .rst(rst), .a(t3), .b(-m[15]), .sum(q1)); 

    // q2 = a0*b2 - a1*b3 + a2*b0 + a3*b1 
    cla32_pipelined SUB5 (.clk(clk), .rst(rst), .a(m[6]), .b(-m[12]), .sum(t4)); 
    cla32_pipelined ADD3 (.clk(clk), .rst(rst), .a(t4), .b(m[7]), .sum(t5));
    cla32_pipelined ADD4 (.clk(clk), .rst(rst), .a(t5), .b(m[13]), .sum(q2));

    // q3 = a0*b3 + a1*b2 - a2*b1 + a3*b0
    cla32_pipelined ADD5 (.clk(clk), .rst(rst), .a(m[8]), .b(m[10]), .sum(t6));
    cla32_pipelined SUB6 (.clk(clk), .rst(rst), .a(t6), .b(-m[11]), .sum(t7)); 
    cla32_pipelined ADD6 (.clk(clk), .rst(rst), .a(t7), .b(m[9]), .sum(q3));

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Booth Multiplier Pipelined 
//////////////////////////////////////////////////////////////////////////////////
module booth_multiplier_pipelined (
    input clk,
    input rst,
    input start, 
    input signed [15:0] multiplicand,
    input signed [15:0] multiplier,
    output reg signed [31:0] result,
    output reg done
);
    reg signed [32:0] A, S, P; 
    reg [4:0] count;
    reg busy;

    wire signed [32:0] P_add = (P[1:0] == 2'b01) ? P + A :
                               (P[1:0] == 2'b10) ? P + S : P;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A <= 0; S <= 0; P <= 0; count <= 0;
            result <= 0; done <= 0; busy <= 0;
        end else begin
            if (start) begin
                A <= {multiplicand, 17'd0};
                S <= {-multiplicand, 17'd0};
                P <= {16'd0, multiplier, 1'b0};
                count <= 16; 
                busy <= 1;
                done <= 0;
            end else if (busy) begin
                P <= $signed(P_add) >>> 1;
                count <= count - 1;
                
                if (count == 1) begin
                    result <= {P_add[32], P_add[32:2]}; 
                    done <= 1;
                    busy <= 0;
                end
            end else begin
                done <= 0;
            end
        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Baugh-Wooley Multiplier Pipelined 
//////////////////////////////////////////////////////////////////////////////////
module baugh_wooley_pipelined (
    input wire clk,
    input wire rst,
    input wire start,
    input signed [15:0] a,
    input signed [15:0] b,
    output reg signed [31:0] product,
    output reg done
);
    reg [1:0] state;
    reg signed [31:0] a_ext, b_ext; 
    reg signed [31:0] partial;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0; product <= 0; done <= 0;
            a_ext <= 0; b_ext <= 0; partial <= 0;
        end else begin
            case (state)
                0: if (start) begin
                    a_ext <= $signed(a); 
                    b_ext <= $signed(b);
                    state <= 1;
                    done <= 0;
                end
                1: begin
                    partial <= a_ext * b_ext; 
                    state <= 2;
                end
                2: begin
                    product <= partial;
                    done <= 1;
                    state <= 0;
                end
            endcase
        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// CLA 32-bit Adder Pipelined 
//////////////////////////////////////////////////////////////////////////////////
module cla32_pipelined (
    input clk,
    input rst,
    input signed [31:0] a,
    input signed [31:0] b,
    output reg signed [31:0] sum
);
    reg signed [31:0] a_reg, b_reg;
    reg signed [32:0] temp_sum; 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= 0;
            a_reg <= 0;
            b_reg <= 0;
            temp_sum <= 0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            temp_sum <= a_reg + b_reg; 
            sum <= temp_sum[31:0];
        end
    end
endmodule