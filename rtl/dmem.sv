// ============================================================
// File   : dmem.sv
// Author : Karan Arjun S
// Project: CoreSelva CSRV64I_SC
//
// Description:
//   Simple single-cycle data memory.
//
//   Features:
//     - 64-bit word storage
//     - Byte-addressed interface
//     - Combinational read
//     - Synchronous write
//
// Notes:
//   - No byte enables
//   - Partial store handling is done in mem_unit
//   - Intended for simulation and teaching
// ============================================================

module dmem (

    input  logic        clk,
    input  logic [63:0] addr,
    input  logic [63:0] wdata,
    input  logic        we,
    output logic [63:0] rdata
);

    // ---------------------------------------------------------
    // Parameters
    // ---------------------------------------------------------
    localparam int DMEM_DEPTH = 1024;   // 1024 × 64-bit = 8 KB
    localparam logic [63:0] DMEM_BASE = 64'h0;

    // ---------------------------------------------------------
    // Memory array
    // ---------------------------------------------------------
    logic [63:0] mem [0:DMEM_DEPTH-1];
    logic [$clog2(DMEM_DEPTH)-1:0] index;

    // ---------------------------------------------------------
    // Combinational READ
    // ---------------------------------------------------------
    always_comb begin
        rdata = 64'b0;
        index = '0;

        if (addr >= DMEM_BASE) begin
            index = (addr - DMEM_BASE) >> 3; // byte → 64-bit word
            if (index < DMEM_DEPTH)
                rdata = mem[index];
        end
    end

    // ---------------------------------------------------------
    // Sequential WRITE
    // ---------------------------------------------------------
    always_ff @(posedge clk) begin
        if (we) begin
            index = (addr - DMEM_BASE) >> 3; // byte → 64-bit word
            if (index < DMEM_DEPTH)
                mem[index] <= wdata;
        end
    end

endmodule