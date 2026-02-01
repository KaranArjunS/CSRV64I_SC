// ============================================================
// File   : pc_fetch.sv
// Author : Karan Arjun S
// Project: CoreSelva CSRV64I_SC
//
// Description:
//   Program counter logic for a single-cycle RV64I core.
//
//   Responsibilities:
//     - Hold current PC
//     - Handle sequential execution
//     - Apply control-flow redirection (branch/jump/trap)
//
// Notes:
//   - PC increments by 4 bytes
//   - Reset vector is fixed for bare-metal execution
// ============================================================

module pc_fetch (

    input  logic        clk,
    input  logic        reset,

    // Control-flow redirection
    input  logic        pc_redirect,
    input  logic [63:0] pc_redirect_target,

    // Outputs
    output logic [63:0] pc,
    output logic [63:0] imem_addr
);

    // -------------------------------------------------
    // Program Counter register
    // -------------------------------------------------
    always_ff @(posedge clk) begin
        if (reset)
            pc <= 64'h0000_0000_8000_0000;   // Reset vector
        else if (pc_redirect)
            pc <= pc_redirect_target;       // Branch / jump / trap
        else
            pc <= pc + 64'd4;               // Sequential fetch
    end

    // -------------------------------------------------
    // Instruction memory address
    // -------------------------------------------------
    assign imem_addr = pc;

endmodule