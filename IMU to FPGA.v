`timescale 1ns / 1ps
`default_nettype none

module imu_to_quat_delta (
    input wire clk,
    input wire rst,
    input wire signed [15:0] wx, wy, wz,     // Angular rates
    input wire [31:0] dt,                    // Timestep
    output reg signed [15:0] dq0, dq1, dq2, dq3
);

    // Multiply angular rates by dt
    wire signed [31:0] wx_dt = wx * dt;
    wire signed [31:0] wy_dt = wy * dt;
    wire signed [31:0] wz_dt = wz * dt;

    // For magnitude estimation (optional, not used here directly)
    wire signed [31:0] wx_sq = wx * wx;
    wire signed [31:0] wy_sq = wy * wy;
    wire signed [31:0] wz_sq = wz * wz;
    wire signed [31:0] sum_sq = wx_sq + wy_sq + wz_sq;

    wire [15:0] mag_est;
    sqrt_approx sqrt_inst (
        .in(sum_sq[31:16]),   // Use upper 16 bits for approximate sqrt
        .out(mag_est)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dq0 <= 16'sd32767; // cos(θ/2) ≈ 1 for small θ
            dq1 <= 16'sd0;
            dq2 <= 16'sd0;
            dq3 <= 16'sd0;
        end else begin
            dq0 <= 16'sd32767; // Keep unit quaternion (only update vector part)

            // These lines are okay as a crude small-angle approx
            dq1 <= wx_dt >>> 16; // Right shift for scaling (simulate division by 2^16)
            dq2 <= wy_dt >>> 16;
            dq3 <= wz_dt >>> 16;
        end
    end

endmodule

// === Crude Sqrt Approximation ===
module sqrt_approx (
    input wire [15:0] in,
    output reg [15:0] out
);
    always @(*) begin
        casez (in)
            16'b1???????????????: out = 16'd256;
            16'b01??????????????: out = 16'd181;
            16'b001?????????????: out = 16'd128;
            16'b0001????????????: out = 16'd90;
            16'b00001???????????: out = 16'd64;
            16'b000001??????????: out = 16'd45;
            16'b0000001?????????: out = 16'd32;
            16'b00000001????????: out = 16'd23;
            16'b000000001???????: out = 16'd16;
            16'b0000000001??????: out = 16'd11;
            16'b00000000001?????: out = 16'd8;
            16'b000000000001????: out = 16'd5;
            16'b0000000000001???: out = 16'd4;
            16'b00000000000001??: out = 16'd3;
            16'b000000000000001?: out = 16'd2;
            default:              out = 16'd1;
        endcase
    end
endmodule
