# CSRV64I_SC Architecture

**CoreSelva Single-Cycle RV64I Reference Core**

---

## 1. Architectural Overview

CSRV64I_SC is a **single-cycle, non-pipelined RV64I processor core**.

Each instruction progresses through the entire datapath — from fetch to writeback — **within one clock cycle**.

There are **no pipeline stages**, no interlocks, and no forwarding logic.  
This makes the datapath easy to reason about and ideal for education and research.

### Conceptual Datapath
PC ↓ Instruction Memory ↓ Decoder ↓ Register File ↓ Execute (ALU / Branch / Trap) ↓ Memory Unit ↓ Writeback

---

## 2. Clocking Model

- One global clock (`clk`)
- All architectural state updates occur on the **rising edge**
- Combinational logic exists between clocked elements
- No multi-cycle operations

### Clocked State Elements

| Element | Description |
|------|-----------|
| Program Counter | Updated every cycle |
| Register File | Writeback occurs on clock edge |
| Data Memory | Writes occur on clock edge |

---

## 3. Program Counter (PC)

**Module:** `pc_fetch.sv`

### Responsibilities

- Hold the current program counter
- Increment PC by 4 for sequential execution
- Redirect PC on branch, jump, or trap

### Reset Behavior
PC ← 0x8000_0000

### Update Priority

1. Reset
2. Trap
3. Branch / Jump
4. Sequential (PC + 4)

### PC Logic

```verilog
if (reset)
    pc <= RESET_VECTOR;
else if (pc_redirect)
    pc <= pc_redirect_target;
else
    pc <= pc + 4;
```
## 4. Instruction Fetch

**Module:** `imem.sv`

### Responsibilities

- Provide the 32-bit instruction corresponding to the current PC
- Model instruction memory behavior for simulation

### Characteristics

- Instruction width: 32 bits
- Access type: Combinational read
- Alignment: Word-aligned (4 bytes)
- Intended for simulation and education only

### Addressing

The instruction memory is byte-addressed externally but indexed internally as words:
index = (PC - IMEM_BASE) >> 2

If the address is outside the valid range, a NOP instruction (`addi x0, x0, 0`) is returned.

### Initialization

- Memory is initialized to NOPs
- Program contents are loaded using `$readmemh`

---

## 5. Instruction Decode

**Module:** `decoder.sv`

### Responsibilities

- Decode opcode, funct3, and funct7 fields
- Generate register indices (`rd`, `rs1`, `rs2`)
- Generate sign-extended immediates
- Assert instruction classification signals
- Detect illegal instructions

### Decode Style

- Explicit, one-hot-style control signals
- No encoded control words
- Each instruction class has a clear boolean signal

### Instruction Classes

| Signal | Meaning |
|------|--------|
| `is_rtype` | R-type ALU instruction |
| `is_itype` | I-type ALU instruction |
| `is_load` | Load instruction |
| `is_store` | Store instruction |
| `is_branch` | Conditional branch |
| `is_jal` | Jump and link |
| `is_jalr` | Jump and link register |
| `is_lui` | Load upper immediate |
| `is_auipc` | Add upper immediate to PC |

### Illegal Instruction Detection

Any unsupported opcode or invalid funct combination asserts:
illegal_instr = 1

This triggers a trap in the execute stage.

---

## 6. Register File

**Module:** `regfile.sv`

### Structure

- 32 general-purpose registers
- Each register is 64 bits wide
- Register `x0` is hard-wired to zero

### Access Model

- Two asynchronous read ports
- One synchronous write port

### Read Behavior
rdata = (raddr == 0) ? 0 : regs[raddr]

### Write Behavior

- Write occurs on rising edge of `clk`
- Writes to `x0` are ignored

No reset is applied to the registers, as per RISC-V specification.

---

## 7. ALU Control

**Module:** `alu_control.sv`

### Responsibilities

- Translate instruction fields into an internal ALU operation code
- Support R-type and I-type ALU instructions

### Inputs

- `is_rtype`
- `is_itype`
- `is_alu`
- `funct3`
- `funct7[5]`

### Output

- `alu_op` (4-bit ALU operation selector)

### Supported Operations

| ALU Code | Operation |
|--------|-----------|
| 0 | ADD / ADDI |
| 1 | SUB |
| 2 | AND / ANDI |
| 3 | OR / ORI |
| 4 | XOR / XORI |
| 5 | SLL / SLLI |
| 6 | SRL / SRLI |
| 7 | SRA / SRAI |
| 8 | SLT / SLTI |
| 9 | SLTU / SLTIU |

---

## 8. Execute Stage

**Module:** `execute.sv`

### Responsibilities

- Perform ALU computation
- Resolve branches and jumps
- Detect traps
- Generate effective addresses for memory operations

### Operand Selection
ALU_A = rs1_data ALU_B = rs2_data (R-type) ALU_B = imm      (I-type, loads, stores)

### ALU Behavior

All RV64I base integer operations are implemented combinationally.

### Branch Resolution

- Branch condition is evaluated in the same cycle
- Branch target is computed as:
branch_target = pc + imm

### Jump Resolution

- `JAL`: `PC + imm`
- `JALR`: `(rs1 + imm) & ~1`

### Trap Handling

A trap is triggered when:

- `illegal_instr` is asserted
- ECALL instruction
- EBREAK instruction

Trap redirection target:
0x8000_0100

---

## 9. Memory Access Unit

**Module:** `mem_unit.sv`

### Purpose

- Isolate load/store data formatting logic
- Keep data memory simple and clean

### Responsibilities

- Align and shift store data
- Perform sign/zero extension for loads
- Generate data memory write enable

### Load Support

| Instruction | Description |
|-----------|-------------|
| LB | Signed byte |
| LBU | Unsigned byte |
| LH | Signed halfword |
| LHU | Unsigned halfword |
| LW | Signed word |
| LWU | Unsigned word |
| LD | 64-bit load |

### Store Handling

- Partial stores are shifted into correct byte positions
- Memory always receives full 64-bit writes

---

## 10. Data Memory

**Module:** `dmem.sv`

### Characteristics

- 64-bit wide memory array
- Byte-addressed interface
- Combinational read
- Synchronous write

### Addressing
index = (addr - DMEM_BASE) >> 3

### Notes

- No byte-enable support
- Partial store handling is fully managed by `mem_unit`
- Intended for simulation and teaching

---

## 11. Writeback

### Writeback Sources

- Load result
- ALU result
- LUI immediate
- AUIPC result
- Return address for JAL/JALR

### Priority Order

1. Load
2. ALU
3. LUI
4. AUIPC
5. JAL / JALR

### Timing

- Writeback is combinationally selected
- Register file write occurs on the rising clock edge

---

## 12. Control Flow Summary

- All control-flow decisions are resolved in one cycle
- No speculation or delayed branching
- PC redirection is handled centrally in `pc_fetch`

---

## 13. Architectural Intent

This design favors:

- Explicit control signals
- Straightforward datapath tracing
- Instruction-level transparency

Performance and synthesis efficiency are intentionally deprioritized.

---

## 14. Educational Value

CSRV64I_SC is suitable for:

- Learning RISC-V datapaths
- Verifying instruction semantics
- Extending into pipelined or multi-cycle designs
- Research and experimentation

---

## 15. Summary

CSRV64I_SC implements the RV64I base ISA using the simplest possible architecture:

- One instruction per cycle
- One clear datapath
- One obvious place for every function

This makes it an ideal reference core for education and research.