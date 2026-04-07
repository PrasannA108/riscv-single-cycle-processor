#  RISC-V Single Cycle Processor (Verilog)

## Overview

This project implements a **32-bit single-cycle RISC-V processor** using **Verilog HDL**, designed and simulated in **Xilinx Vivado**.

The processor executes each instruction in a single clock cycle and supports a subset of the RISC-V ISA, including arithmetic, memory, and branch operations.

---

## Features

* 32-bit architecture
* Single-cycle datapath design
* Modular Verilog implementation
* Instruction execution in one clock cycle
* Functional simulation using Vivado

---

## Supported Instruction Types

###  R-Type

* `add`
* `sub`
* `and`
* `or`

### I-Type

* `addi`
* `lw`

### S-Type

* `sw`

###  SB-Type

* `beq`

---

##  Architecture

The processor follows a standard **single-cycle datapath**:

```
PC → Instruction Memory → Control Unit → Register File → ALU → Data Memory → Write Back
```

### Key Components:

* **Program Counter (PC)**
* **Instruction Memory**
* **Control Unit**
* **ALU Control Unit**
* **Register File**
* **ALU (Arithmetic Logic Unit)**
* **Data Memory**
* **Multiplexers (MUXes)**

##  Simulation Results

* Correct PC increment by 4
* Instruction fetch verified
* Control signals generated correctly
* ALU operations validated
* Register write-back confirmed

##  Tools Used

* Verilog HDL
* Xilinx Vivado (Simulation)

---

## Learning Outcomes

* Understanding of RISC-V ISA
* Single-cycle processor design
* Datapath and control unit integration
* Debugging hardware using waveforms
* Memory initialization in Verilog

---

## Future Improvements

* Pipeline implementation (5-stage pipeline)
* Hazard detection and forwarding
* Support for more RISC-V instructions
* Branch prediction
* FPGA deployment


Feel free to reach out for collaboration or questions!
