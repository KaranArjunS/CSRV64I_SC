// ============================================================
// File   : regfile.sv
// Author : Karan Arjun S
// Project: CoreSelva CSRV64I_SC
//
// Description:
//   RV64I integer register file.
//
//   Features:
//     - 32 registers × 64 bits
//     - x0 hard-wired to zero
//     - Two asynchronous read ports
//     - One synchronous write port
//
// Notes:
//   - No reset on registers (architecturally correct)
//   - Write occurs on rising clock edge
//   - No internal forwarding or bypassing
// ============================================================

module regfile (

    input  logic        clk,

    // ---------------- Write port ----------------
    input  logic        we,
    input  logic [4:0]  waddr,
    input  logic [63:0] wdata,

    // ---------------- Read port 1 ----------------
    input  logic [4:0]  raddr1,
    output logic [63:0] rdata1,

    // ---------------- Read port 2 ----------------
    input  logic [4:0]  raddr2,
    output logic [63:0] rdata2
);

    // Register storage (x0–x31)
    logic [63:0] regs [0:31];

    // -------------------------------------------------
    // Asynchronous read
    // -------------------------------------------------
    assign rdata1 = (raddr1 == 5'd0) ? 64'd0 : regs[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 64'd0 : regs[raddr2];

    // -------------------------------------------------
    // Synchronous write
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (we && (waddr != 5'd0)) begin
            regs[waddr] <= wdata;
        end
    end

endmodule