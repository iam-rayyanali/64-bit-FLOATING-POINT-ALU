# 64-bit IEEE 754 Floating Point Unit (FPU) in Verilog

This project implements a **64-bit IEEE 754-compliant Floating Point Unit (FPU)** in Verilog. It supports fundamental arithmetic operations—**addition**, **subtraction**, **multiplication**, and **division**—on **double-precision** floating-point numbers.

---

## 🚀 Features

- ✅ IEEE 754 **double-precision (64-bit)** floating-point format  
- ✅ Support for **Addition**, **Subtraction**, **Multiplication**, **Division**  
- ✅ Handles **edge cases**:  
  - Zero  
  - Infinity  
  - NaN (Not a Number)  
  - Denormalized numbers  
- ✅ **Modular Verilog** design  
- ✅ Comes with **two testbenches** for validation  

---

## 🧮 Supported Operations

The operation is selected using a 2-bit `op` input:

| Operation      | `op` Code |
|----------------|-----------|
| Addition       | `2'b00`   |
| Subtraction    | `2'b01`   |
| Multiplication | `2'b10`   |
| Division       | `2'b11`   |

---

## 📁 Project Structure

```bash
.
├── fpu.v            # Top-level FPU module: integrates all operation modules
├── fpu_add_sub.v    # Addition and Subtraction implementation
├── fpu_mul.v        # Multiplication logic (double-precision)
├── fpu_div.v        # Division logic (double-precision)
├── fpu_tb1.v        # Testbench 1: Basic arithmetic checks with real number comparisons
├── fpu_tb2.v        # Testbench 2: Edge case tests (NaN, INF, Zeros, etc.)
└── README.md        # Project documentation (this file)
