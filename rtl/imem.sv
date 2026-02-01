// ============================================================
// File   : imem.sv
// Author : Karan Arjun S
// Project: CoreSelva CSRV64I_SC
//
// Description:
//   Simulation instruction memory for a single-cycle RV64I core.
//
//   Features:
//     - 32-bit instruction width
//     - Word-aligned access
//     - Combinational read
//
// Notes:
//   - Intended for simulation only
//   - Program loaded via $readmemh
//   - No access protection or timing model
// ============================================================

module imem (
    input  logic [63:0] addr,
    output logic [31:0] instr
);

    localparam int IMEM_DEPTH = 1024;
    localparam logic [63:0] IMEM_BASE = 64'h0000_0000_8000_0000;

    logic [31:0] mem [0:IMEM_DEPTH-1];
    logic [31:0] index;

    // -------------------------------------------------
    // Program initialization (simulation only)
    // -------------------------------------------------
    initial begin
        integer i;
        for (i = 0; i < IMEM_DEPTH; i = i + 1)
            mem[i] = 32'h00000013; // NOP (addi x0, x0, 0)

        $readmemh("program/program.hex", mem);

        $display("[IMEM] Program loaded:");
        for (i = 0; i < 8; i = i + 1)
            $display("  mem[%0d] = %h", i, mem[i]);
    end

    // -------------------------------------------------
    // Combinational instruction fetch
    // -------------------------------------------------
    always_comb begin
        instr = 32'h00000013; // Default NOP

        if (addr >= IMEM_BASE) begin
            index = (addr - IMEM_BASE) >> 2; // Word index

            if (index < IMEM_DEPTH)
                instr = mem[index];
        end
    end

endmodule