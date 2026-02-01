# CSRV64I_SC  
**CoreSelva Single-Cycle RV64I Reference Core**

## Overview

**CSRV64I_SC** is a **single-cycle, non-pipelined RV64I processor core** written in SystemVerilog.

This project is designed as a **clean educational and research reference**, prioritizing architectural clarity and correctness over performance or optimization.

Each instruction completes in **one clock cycle**, following the conceptual datapath:

---

## Design Philosophy

This core is intentionally simple and explicit.

Key principles:
- One module per architectural responsibility
- No hidden control logic
- No microcode
- No speculation or out-of-order behavior
- Signal names reflect architectural meaning

The RTL is written to closely resemble textbook datapaths while remaining executable.

---

## ISA Support

### Supported
- RISC-V RV64I base integer instruction set
- Unprivileged instructions only

### Not Supported
- CSR instructions
- Privileged modes (M/S/U)
- Interrupts or exceptions beyond simple traps
- MMU or virtual memory
- Caches
- Floating-point (F/D)
- Atomics (A)
- Compressed instructions (C)

---

## Core Characteristics

| Feature | Description |
|------|------------|
| Architecture | Single-cycle |
| Pipeline | None |
| Register file | 32 × 64-bit |
| Endianness | Little-endian |
| Reset vector | `0x8000_0000` |
| Trap vector | `0x8000_0100` |
| Memory model | Idealized (simulation-oriented) |
| Intended use | Education & research |

---

## Module Overview

| Module | Description |
|------|------------|
| `csrv64i.sv` | Top-level integration |
| `pc_fetch.sv` | Program counter and control-flow redirection |
| `decoder.sv` | Instruction decoding and control generation |
| `regfile.sv` | Integer register file |
| `alu_control.sv` | ALU operation selection |
| `execute.sv` | ALU, branches, jumps, traps |
| `mem_unit.sv` | Load/store data handling |
| `imem.sv` | Instruction memory (simulation only) |
| `dmem.sv` | Data memory (simulation only) |

---

## Instruction Flow

For every instruction, the following happens in a single cycle:

1. **Fetch**  
   Instruction fetched from instruction memory using PC

2. **Decode**  
   Opcode, register indices, immediates, and control signals generated

3. **Register Read**  
   Source registers read asynchronously

4. **Execute**  
   ALU operation, branch/jump resolution, trap detection

5. **Memory Access**  
   Load or store operation if required

6. **Writeback**  
   Result written to destination register

---

## Memory Model

This core uses **idealized memories** for clarity:

### Instruction Memory
- 32-bit wide
- Combinational read
- Loaded using `$readmemh`
- Word-aligned access

### Data Memory
- 64-bit wide
- Byte-addressed
- Combinational read
- Synchronous write
- No byte enables

Partial loads and stores are handled in `mem_unit`.

---

## Simulation

### Requirements
- Verilator
- C++ compiler (g++ or clang)
- Linux or WSL recommended

### Example Run
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

Simulation Output:
During simulation, register writeback activity is printed to the terminal:
```bash
[WB] x<rd> = <value>
```
This provides a simple execution trace that makes it easy to follow instruction behavior cycle by cycle.


## Educational Scope

CSRV64I_SC is built as a **didactic reference**, not a performance core.

It is intended to help readers:

- Understand the RV64I instruction set at the RTL level
- Visualize a complete single-cycle datapath
- Learn how decode, execute, memory, and writeback interact
- Use the core as a baseline for more advanced designs

All logic is explicit and traceable.  
There are no implicit FSMs or hidden micro-operations.

---

## Known Limitations (Intentional)

The following limitations are **by design**:

- Single-cycle architecture with long critical path
- No pipeline hazards (not required in single-cycle designs)
- No timing-accurate memory modeling
- No misaligned access checks
- No CSR or privileged instruction support
- No exception cause encoding (single trap vector only)
- Instruction and data memories are simulation-oriented

These choices are made to preserve clarity and readability.

---

## Intended Audience

This project is suitable for:

- Students learning computer architecture
- Engineers new to RISC-V
- Researchers prototyping CPU concepts
- Educators teaching datapath design
- Anyone wanting a minimal, readable RV64I core

---

## Project Structure
CSRV64I_SC/
├── rtl/
│   ├── csrv64i.sv
│   ├── pc_fetch.sv
│   ├── decoder.sv
│   ├── regfile.sv
│   ├── alu_control.sv
│   ├── execute.sv
│   ├── mem_unit.sv
│   ├── imem.sv
│   └── dmem.sv
│
├── sim/
│   └── tb.cpp
│
├── program/
│   └── program.hex
│
└── README.md

---

## Extending This Core

CSRV64I_SC is designed to be extended.

Common next steps include:

- Adding RV64M (MUL/DIV) instructions
- Converting the core into a 5-stage pipeline
- Adding CSR support
- Replacing memories with FPGA SRAM interfaces
- Adding formal verification checks

This core can be used as a **golden reference** for correctness when scaling complexity.

---

## Roadmap (CoreSelva)

Planned future work:

- **CSRV64IM_5P** — 5-stage pipelined RV64IM core
- Linux-capable RV64 core
- Formal verification experiments
- FPGA-oriented memory and bus interfaces
- Power and performance exploration variants

---

## License

MIT License

This project is free for educational, research, and commercial use.

---

## Author

**Karan Arjun S**  
Project: **CoreSelva**

## License

This project is licensed under the MIT License.

Project homepage: https://coreselva.com
