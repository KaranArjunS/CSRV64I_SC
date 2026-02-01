## How to Use This Repository

This repository is intended for **simulation and learning**.  
The core is **not targeted for FPGA synthesis** in its current form.

You interact with the core by:
1. Providing a program (`program/program.hex`)
2. Running a Verilator-based simulation
3. Observing architectural behavior via writeback logs (and optionally waveforms)

---

## Prerequisites

Recommended environment:

- **Linux** or **WSL (Ubuntu)**
- **Verilator** (v4.x or newer)
- **C++ compiler** (`g++` or `clang`)
- `make`

### Install on Ubuntu / WSL

```bash
sudo apt update
sudo apt install -y verilator build-essential
```
Verify installation:
```bash
verilator --version
g++ --version
```
### Repository Structure (Quick Reference)
```text
CSRV64I_SC/
├── rtl/            # SystemVerilog RTL
├── program/        # Program image (program.hex)
├── sim/            # Verilator C++ testbench
├── diagrams/       # Block diagram
├── docs/           # Architecture documentation
└── README.md
```
## Preparing a Program

The CSRV64I_SC core fetches instructions from a **simulation-only instruction memory** (`imem`), which is initialized using a hexadecimal file.

---

### Program File Location

Instruction memory is loaded from:

```text
program/program.hex
```
---
### Instruction Format

The `program.hex` file must contain **32-bit RISC-V instructions**, one instruction per line, written in **hexadecimal format**.

Each line corresponds to **one word (4 bytes)** in instruction memory.

Example:

```text
00000013
00500093
00108133
```

### Generating `program.hex`

You can generate `program.hex` in multiple ways. The simplest approach is to **manually write hex instructions**, but using a RISC-V toolchain is recommended.

---

#### Manual (Quick Tests)

For small experiments, you can manually write instructions. Can be tested Using RISC-V GNU Toolchain as well.

Example program:

```asm
addi x1, x0, 5
addi x2, x0, 7
add  x3, x1, x2
```
Corresponding program.hex:

'''text
00500093
00700113
002081b3
```
Save this file as:
```text
program/program.hex
```
---
### Running the Simulation

CSRV64I_SC is intended to be simulated using **Verilator**.  
The simulation executes instructions directly from `program/program.hex`.

---

#### Prerequisites

Make sure the following tools are installed:

- Verilator
- GNU C++ compiler (`g++` or `clang++`)
- Linux or WSL environment (recommended)

Verify Verilator installation:

```bash
verilator --version
```
### Simulation Command (Linux / WSL)

From the project root directory:

```bash
rm -rf obj_dir && \
verilator -Wall -Wno-fatal \
  --trace \
  --cc rtl/*.sv \
  --top-module csrv64i \
  --exe sim/tb.cpp && \
make -C obj_dir -f Vcsrv64i.mk && \
./obj_dir/Vcsrv64i
```
Simulation Output
During execution, the core prints register writeback activity:

```text
[WB] x1 = 5
[WB] x2 = 7
[WB] x3 = 12
```
### Viewing Waveforms (Optional Debugging)

CSRV64I_SC supports **VCD waveform generation** for signal-level inspection.

Waveforms are useful for:
- Verifying control flow
- Debugging branch decisions
- Inspecting ALU inputs/outputs
- Understanding single-cycle timing behavior

---

#### Enabling Waveform Dump

The simulation command already enables tracing using:

```bash
--trace
```
During execution, Verilator generates a file:

```text
wave.vcd
```
Viewing with GTKWave
Open the waveform file using GTKWave:

```bash
gtkwave wave.vcd
```

### Recommended Signals to Inspect
When debugging, focus on:
```text
    pc
    instr
    rd, rs1, rs2
    imm
    alu_op
    alu_result
    branch_taken
    branch_target
    wb_we
    wb_rd
    wb_data
```
Because this is a single-cycle core, all meaningful activity for an instruction happens within one clock cycle.

## Repository Usage Guidelines

CSRV64I_SC is designed primarily as an **educational and research-oriented reference**.

This repository prioritizes:
- Readability
- Architectural correctness
- Clear signal intent
- Conceptual alignment with RISC-V specifications

It is **not** intended to be a production-ready CPU core.

---

### Intended Audience

This project is suitable for:

- Students learning computer architecture
- Beginners implementing their first CPU
- Researchers exploring RISC-V internals
- RTL designers building intuition before pipelining
- Educators teaching single-cycle datapaths

---

### What This Core Is Good For

- Understanding instruction-level execution
- Tracing how RISC-V instructions flow through hardware
- Learning how decode, execute, and memory interact
- Experimenting with control logic
- Building confidence before moving to pipelined designs

---

### What This Core Is NOT Meant For

- FPGA or ASIC deployment
- High-frequency or high-performance designs
- Operating system booting
- Multi-core experiments
- Timing-accurate memory modeling

---

### Recommended Learning Path

Users are encouraged to:

1. Study the block diagram
2. Read the decoder logic carefully
3. Trace one instruction end-to-end
4. Modify the ALU or add instructions
5. Convert the core into a pipelined design
6. Add CSR, exceptions, or caches incrementally

This repository serves as a **clean starting point**, not a final destination.

## License, Attribution, and Disclaimer

### License

This project is released under the **MIT License**.

You are free to:
- Use
- Modify
- Share
- Fork
- Build upon

This applies to both educational and research use.

Please see the `LICENSE` file for full license text.

---

### Attribution

If you use this project in:
- Coursework
- Research papers
- Teaching material
- Derivative CPU designs

Attribution is appreciated but **not required** by the license.

Suggested citation:

> CoreSelva CSRV64I_SC – Single-Cycle RV64I Reference Core  
> Author: Karan Arjun S

---

### Disclaimer

This core is provided **as-is**, without warranty of any kind.

Important notes:

- Functional correctness is validated through simulation
- No formal verification is provided
- No timing or synthesis guarantees are made
- Not suitable for safety-critical systems
- Not designed for silicon tape-out

Use this core **at your own risk**.

---

### RISC-V Compliance Note

This project is **not an official RISC-V International implementation**.

- It is a learning-oriented reference
- It does not claim full compliance certification
- Instruction behavior follows the unprivileged RV64I specification

RISC-V is a registered trademark of RISC-V International.

## Future Work and Roadmap

CSRV64I_SC is intentionally minimal, but it is designed as a **foundation** for deeper exploration.

This section outlines natural extensions for learners and researchers.

---

### Near-Term Enhancements

These changes can be made without altering the overall single-cycle nature:

- Add instruction counters for debugging
- Improve testbench coverage
- Add optional waveform tracing helpers
- Add assertions for architectural invariants (x0 = 0, alignment rules)

---

### Pipelined Variant

A natural next step is converting this core into a **multi-stage pipeline**:

- IF → ID → EX → MEM → WB
- Introduce pipeline registers
- Handle data hazards
- Implement forwarding
- Add basic stalling logic

This repository can serve as the **golden reference** for functional behavior before pipelining.

---

### Extended ISA Support

Possible ISA extensions:

- RV64M (multiply/divide)
- RV64C (compressed instructions)
- RV64F / RV64D (floating point)
- Basic CSR support

Each extension should remain modular and optional.

---

### Memory System Enhancements

- Byte-enable support in data memory
- Separate instruction and data buses
- Simple cache models (for learning)
- Load/store alignment checking

---

### Verification and Research

For advanced users:

- Formal verification experiments
- Differential testing against Spike
- Property-based checking
- Microarchitectural exploration

---

### FPGA and Hardware Exploration

While this core is simulation-oriented, it can be adapted for:

- FPGA prototyping
- Timing analysis experiments
- Resource utilization studies
- Educational CPU labs

---

### Long-Term Vision

CSRV64I_SC aims to be:

- A **teaching reference**
- A **baseline research core**
- A **starting point for custom architectures**

Simplicity is the feature.
