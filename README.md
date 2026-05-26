# EL_007: Hardware Accelerator for Quaternion Multiplication
![Language](https://img.shields.io/badge/Language-Verilog%20%7C%20C%2B%2B-orange)
![Event](https://img.shields.io/badge/Event-IITI%20SOC%202025%20(Electronics)-purple)

## Team EL_007
**Members:** Bhasuru Nikhil, Shakkar Ridhi, Nainsi Kushwaha

---

## 📖 Table of Contents
1. [Project Overview](#project-overview)
2. [Background & Mathematical Model](#background--mathematical-model)
3. [System Architecture Overview](#system-architecture-overview)
4. [Detailed Hardware Architectures](#detailed-hardware-architectures)
   - [1. Direct Combinational Multiplication](#1-direct-combinational-multiplication)
   - [2. Direct Pipelined Multiplication](#2-direct-pipelined-multiplication)
   - [3. Algorithmic Quaternion Multiplication](#3-algorithmic-quaternion-multiplication)
   - [4. Pipelined Algorithmic Multiplication](#4-pipelined-algorithmic-multiplication)
5. [Interface and Communication Pathways](#interface-and-communication-pathways)
   - [Method 1: Arduino-Assisted Pipeline (UART)](#method-1-arduino-assisted-pipeline-uart)
   - [Method 2: Direct IMU-FPGA Interface (Bonus Implementation)](#method-2-direct-imu-fpga-interface-bonus-implementation)
6. [Testbench Simulations, Register Outputs, and Data Flow](#testbench-simulations-register-outputs-and-data-flow)
7. [Qualitative Effects & Hardware Trade-offs](#qualitative-effects--hardware-trade-offs)
8. [Repository Structure](#repository-structure)
9. [Future Scope & Acknowledgements](#future-scope--acknowledgements)

---

## 1. Project Overview

The objective of this project is to design and implement a highly efficient hardware accelerator on an FPGA (PYNQ-Z2) to perform real-time quaternion multiplication. Quaternions are predominantly used in aerospace, robotics, AR/VR, and 3D graphics to represent spatial orientations and rotations, avoiding the phenomena of "gimbal lock" found in Euler angles.

However, processing continuous streams of IMU (Inertial Measurement Unit) data and calculating quaternion multiplication poses a heavy computational bottleneck for standard CPUs. This project solves this by offloading the quaternion mathematics to a dedicated hardware accelerator.

Our implementation successfully integrates raw Gyroscope data from an MPU6050 IMU, computes orientation deltas, and accelerates the sequential operations using various Verilog-based multiplier architectures. 

---

## 2. Background & Mathematical Model

A quaternion is represented as:
`Q = w + xi + yj + zk`
where `w, x, y, z` are real numbers, and `i, j, k` are fundamental quaternion units.

When multiplying two quaternions `Q1(a1, b1, c1, d1)` and `Q2(a2, b2, c2, d2)`, the resultant quaternion `Q_new(r1, r2, r3, r4)` is calculated as:
* `r1 (w) = a1*a2 - b1*b2 - c1*c2 - d1*d2`
* `r2 (x) = a1*b2 + b1*a2 + c1*d2 - d1*c2`
* `r3 (y) = a1*c2 - b1*d2 + c1*a2 + d1*b2`
* `r4 (z) = a1*d2 + b1*c2 - c1*b2 + d1*a2`

Each quaternion multiplication requires **16 distinct 16-bit multiplications** and **12 additions/subtractions**. Implementing this natively on an FPGA demands careful resource management and pipelining to ensure maximum throughput without violating timing constraints.

---

## 3. System Architecture Overview

To comprehensively analyze the best approach for hardware acceleration, we developed four distinct Verilog architectures. These range from basic combinatorial logic to heavily pipelined algorithmic frameworks.

1.  **Direct Combinational:** Uses standard arithmetic blocks (Ripple Carry Adders).
2.  **Direct Pipelined:** Introduces dual-clock registering to isolate critical paths.
3.  **Algorithmic Combinational:** Utilizes specialized multipliers (Booth and Baugh-Wooley) for signed operations.
4.  **Algorithmic Pipelined:** The pinnacle of our design, merging specialized multipliers with deep pipelined states (CLA32) for uninterrupted real-time execution.

---

## 4. Detailed Hardware Architectures

### 1. Direct Combinational Multiplication
**(File: `direct_multiplication.v`)**

This architecture maps the mathematical formula directly into hardware logic.
* **Submodules Built:** * `full_adder`, `ripple_adder_16`, `ripple_adder_32`
    * `twos_complement_16`, `twos_complement_32`
    * `multiplier_16bit`: Uses a shift-and-add partial product generator to multiply magnitudes, determining final signs via XOR (`a[15] ^ b[15]`).
* **Data Flow:** The input 16-bit parameters are instantiated into 16 `multiplier_16bit` modules. The resulting 32-bit values are passed through a web of Two's Complement blocks and 32-bit Ripple Carry Adders to resolve the final `r1, r2, r3, r4` coordinates.
* **Qualitative Effect:** While it accurately computes the multiplication, the combinational depth is extremely high. The ripple carry adders create a massive critical path delay, making it unsuitable for high-frequency real-time continuous streaming.

### 2. Direct Pipelined Multiplication
**(File: `direct_multiplication_pipelined.v`)**

To resolve the timing bottlenecks of the direct method, we introduced pipelining.
* **Dual-Clock Mechanism (`clk1`, `clk2`):** The logic uses two non-overlapping clock domains to manage the staging.
* **Pipelined Multiplier (`multiplier_16bit_pipelined`):** * Stage 1 (`clk1`): Calculates partial products `pp[0]` to `pp[3]` and accumulates them into `sum_stage1`.
    * Stage 2 (`clk2`): Computes `pp[4]` to `pp[7]` and accumulates with `sum_stage1` into `sum_stage2`.
    * Stage 3 (`clk1`): Computes `pp[8]` to `pp[11]`, saving to `sum_stage3`.
    * Stage 4 (`clk2`): Final accumulation.
* **Top-Level Registers:** `reg_32` instances are placed between the addition/subtraction hierarchies. For example, `nbb_r`, `ncc_r`, `sub1_r`, etc.
* **Qualitative Effect:** The introduction of registers significantly increases the maximum operating frequency (Fmax). The initial output latency increases, but the overall throughput becomes 1 operation per clock cycle once the pipeline is full. 

### 3. Algorithmic Quaternion Multiplication
**(File: `multiplication_algorithmic.v`)**

This architecture optimizes the arithmetic by switching out generic multipliers for specialized algorithms tailored to specific bit-level behaviors of the inputs.
* **Booth Multiplier (`booth_multiplier`):** Radix-4 Booth encoding is used for signed multiplication, reducing the number of partial products by inspecting 3 bits (`product[2:0]`) at a time to execute `+M`, `+2M`, `-M`, `-2M`, or `0`.
* **Baugh-Wooley Multiplier (`baugh_wooley`):** Used for efficiently multiplying signed numbers using 2's complement directly in a combinational matrix without sign-extension padding.
* **Modified Ripple Carry Adder (`modified_rca`):** Computes generate (`g = a & b`) and propagate (`p = a ^ b`) signals.
* **Deployment:** The 16 required multiplications are distributed optimally among Booth and Baugh-Wooley cores (e.g., `M0`, `M2` Booth; `M1`, `M3` Baugh-Wooley).

### 4. Pipelined Algorithmic Multiplication
**(File: `algorithmic_multiplication_pipelined.v`)**

The pinnacle of the project, merging algorithmic efficiency with deep pipelining.
* **Stage 1 - Parallel Processing:** 14 parallel pipelined multipliers (Booth and Baugh-Wooley).
* **Synchronization (`done` signal latching):** To ensure all multiplications finish before addition begins, `m_done` bits from all 16 cores are bitwise ORed into an `m_done_reg`. The pipeline only advances when `m_done_reg == 16'hFFFF`.
* **Stage 2 - CLA Cascades (`cla32_pipelined`):** The addition/subtraction cascade utilizes Pipelined Carry Lookahead Adders (CLA) instead of Ripple Adders. This eradicates the long O(N) gate delays found in standard addition.
* **Qualitative Effect:** This provides the absolute best balance of latency across stages. It handles continuous operation smoothly and is the recommended architecture for integration onto the PYNQ-Z2 board.

---

## 5. Interface and Communication Pathways

### Method 1: Arduino-Assisted Pipeline (UART)
**(File: `Final_Arduino_SOC.ino`)**

1.  **I2C Read:** The Arduino acts as the I2C Master, querying register `0x43` of the MPU6050 to extract raw Gyroscope data (`gx`, `gy`, `gz`).
2.  **Delta Calculation:** The Arduino scales the raw data to degrees/sec, then to radians, and computes the delta quaternion using small-angle approximations.
3.  **UART Transmission:** The delta data is scaled by 10,000 (to transmit floats as `int16_t`) and sent byte-by-byte to the FPGA over Serial UART.
4.  **FPGA Processing & Return:** The FPGA receives the data, calculates the multiplication, and sends back an 8-byte buffer. The Arduino reconstructs the data and calculates the updated angular velocity.

### Method 2: Direct IMU-FPGA Interface (Bonus Implementation)
**(File: `IMU to FPGA.v`)**

Bypassing the Arduino completely provides massive speedups by avoiding UART bottlenecks.
* **I2C Master on FPGA:** Custom Verilog logic to read raw bytes from the MPU6050.
* **Hardware Delta Calculation (`imu_to_quat_delta`):** Takes `wx, wy, wz` and `dt`. Calculates `wx_dt`, `wy_dt`, `wz_dt` internally using bit-shifting (`>>> 16`) to emulate floating-point division and scale the outputs into the Q15 format delta quaternion.
* **Hardware Square Root Approximation (`sqrt_approx`):** A custom module that uses `casez` wildcard matching to find the highest set bit and assigns a rough square root estimate for rapid vector normalization.

---

## 6. Testbench Simulations, Register Outputs, and Data Flow

### Pipelined Algorithmic Testbench (`tb_algorithmic_pipelined.v`)
* **Inputs:** `A = 1 + 2i + 3j + 4k`, `B = 5 + 6i + 7j + 8k`.
* **Data Flow:** The `start` pulse is fired. The pipelined Booth/Baugh-Wooley cores spin up, storing partial products in latches. The CLA32 cascades wait for the `done` signal to flip high.
* **Outputs Observed:** * `q0 = -60` (Expected: -60)
    * `q1 = 12` (Expected: 12)
    * `q2 = 30` (Expected: 30)
    * `q3 = 24` (Expected: 24)
* **Registers:** The system accounts for a 9-clock cycle minimum latency for the 3 internal CLA stages to ripple through successfully.

### Rotational Simulation / Feedback Testbench (`tb_bonus.v`)
This TB simulates physical object rotations (Roll, Pitch, Yaw) fed directly into the FPGA.
* **Initial State:** `q0 = 16'sd32767` (representing 1.0 in Q15 format), `q1 = q2 = q3 = 0`.
* **Feedback Loop:** ```verilog
    always @(posedge clk) begin
        if (seen_nonzero) begin
            q0 <= q0_new[30:15]; // Downscale from Q30 product to Q15 state
            q1 <= q1_new[30:15];
            q2 <= q2_new[30:15];
            q3 <= q3_new[30:15];
        end
    end
    ```
* **Simulation Trace:**
    * Rotates roughly 15000 units on X-axis (`wx = 15000`). Result mapped to `q1_scaled`.
    * Rotates on Y-axis (`wy = 15000`). Result alters `q2_scaled`.
    * Demonstrates real-time compounding of 3D rotational matrices entirely in hardware.

---

## 7. Qualitative Effects & Hardware Trade-offs

| Architecture | Speed (Max Freq) | Area (LUTs/Registers) | Latency | Use-Case Fit |
| :--- | :--- | :--- | :--- | :--- |
| **Direct Combinational** | Very Low | Low | 1 Cycle (Slow) | Basic proof of concept, low-speed systems. |
| **Direct Pipelined** | High | Medium (High Flip-Flop usage) | Multi-Cycle | High throughput, decent for generic hardware. |
| **Algorithmic Comb.** | Medium | Low (Optimized logic) | 1 Cycle (Slow) | Area-constrained devices. |
| **Algorithmic Pipelined** | Very High | High | Multi-Cycle | **Ideal for IMU sensor fusion.** Continuous high-speed data flow. |

**Key Takeaways:**
1.  **Pipelining is Non-Negotiable:** Continuous IMU data streaming (e.g., at 1000Hz) requires pipelining to avoid missing samples while the multiplier processes data.
2.  **Fractional Arithmetic (Q-Format):** Scaling data (e.g., shifting `[30:15]`) proved essential. Floating point math is incredibly hardware intensive; using scaled integers (Q15/Q30) bypassed the need for a DSP block, preserving FPGA logic real estate.
3.  **Algorithmic Efficiency:** Swapping simple multipliers for Booth encoding halved the partial product accumulation phase.
---
## 8. External Resources

https://share.google/vLRxOtKJnZ5gnRpvB
https://share.google/mTRVE3X9I1PaTySKQ
https://share.google/U68MjuvapWPtFbpu9
https://share.google/SIA1VyrFZaAz3vVPz
https://share.google/DvmhEwlhn4XL35j5F

## 9. Tools Used

- Xilinx Vivado (Simulation & Synthesis)
- Modelsim and Quartus (for testing)
- Arduino IDE (IMU Communication)
- Overleaf (Report Documentation)
- Git & GitHub (Version Control)
