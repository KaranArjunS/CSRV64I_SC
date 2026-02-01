// ============================================================
// File   : execute.sv
// Author : Karan Arjun S
// Project: CoreSelva CSRV64I_SC
//
// Description:
//   Execute stage for a single-cycle RV64I core.
//
//   Responsibilities:
//     - ALU operation
//     - branch and jump decision
//     - trap detection and redirection
//     - address generation for loads/stores
//
// Notes:
//   - Purely combinational logic
//   - clk/reset reserved for future pipelining
// ============================================================

module execute (

    // ---------- From Decode / Regfile ----------
    input  logic [63:0] rs1_data,
    input  logic [63:0] rs2_data,
    input  logic [63:0] imm,
    input  logic [63:0] pc,
    input  logic [4:0]  rd,

    // ---------- Control ----------
    input  logic        is_rtype,
    input  logic        is_alu,
    input  logic        is_load,
    input  logic        is_store,
    input  logic        is_branch,
    input  logic        is_jal,
    input  logic        is_jalr,
    input  logic        is_auipc,
    input  logic        is_lui,

    input  logic        is_beq,
    input  logic        is_bne,
    input  logic        is_blt,
    input  logic        is_bge,
    input  logic        is_bltu,
    input  logic        is_bgeu,

    input  logic        is_ecall,
    input  logic        is_ebreak,
    input  logic        illegal_instr,

    input  logic [3:0]  alu_op,

    // ---------- Outputs ----------
    output logic [63:0] alu_result,
    output logic [63:0] ex_addr,
    output logic [63:0] ex_store_data,

    output logic        branch_taken,
    output logic [63:0] branch_target,

    output logic        trap,
    output logic [63:0] trap_target
);

    // -------------------------------------------------
    // Trap vector (bare-metal fixed address)
    // -------------------------------------------------
    localparam logic [63:0] TRAP_VECTOR = 64'h0000_0000_8000_0100;

    // -------------------------------------------------
    // Operand selection
    // -------------------------------------------------
    logic [63:0] alu_a, alu_b;

    always_comb begin
        alu_a = rs1_data;

        // R-type uses rs2, others use immediate
        if (is_lui)
            alu_b = 64'b0;
        else if (is_rtype)
            alu_b = rs2_data;
        else
            alu_b = imm;
    end

    // -------------------------------------------------
    // ALU (RV64I base operations)
    // -------------------------------------------------
    always_comb begin
        alu_result = 64'b0;

        case (alu_op)
            4'd0: alu_result = alu_a + alu_b;                  // ADD / ADDI
            4'd1: alu_result = alu_a - alu_b;                  // SUB
            4'd2: alu_result = alu_a & alu_b;                  // AND / ANDI
            4'd3: alu_result = alu_a | alu_b;                  // OR / ORI
            4'd4: alu_result = alu_a ^ alu_b;                  // XOR / XORI
            4'd5: alu_result = alu_a << alu_b[5:0];            // SLL / SLLI
            4'd6: alu_result = alu_a >> alu_b[5:0];            // SRL / SRLI
            4'd7: alu_result = $signed(alu_a) >>> alu_b[5:0];  // SRA / SRAI
            4'd8: alu_result = ($signed(alu_a) < $signed(alu_b)); // SLT / SLTI
            4'd9: alu_result = (alu_a < alu_b);                // SLTU / SLTIU
            default: alu_result = alu_a + alu_b;
        endcase
    end

    // -------------------------------------------------
    // Trap detection
    // -------------------------------------------------
    always_comb begin
        trap        = 1'b0;
        trap_target = 64'b0;

        if (illegal_instr || is_ecall || is_ebreak) begin
            trap        = 1'b1;
            trap_target = TRAP_VECTOR;
        end
    end

    // -------------------------------------------------
    // Branch and jump resolution
    // -------------------------------------------------
    always_comb begin
        branch_taken  = 1'b0;
        branch_target = 64'b0;

        if (trap) begin
            branch_taken  = 1'b1;
            branch_target = trap_target;
        end
        else if (is_branch) begin
            if (is_beq)  branch_taken = (rs1_data == rs2_data);
            if (is_bne)  branch_taken = (rs1_data != rs2_data);
            if (is_blt)  branch_taken = ($signed(rs1_data) <  $signed(rs2_data));
            if (is_bge)  branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
            if (is_bltu) branch_taken = (rs1_data <  rs2_data);
            if (is_bgeu) branch_taken = (rs1_data >= rs2_data);

            branch_target = pc + imm;
        end
        else if (is_jal) begin
            branch_taken  = 1'b1;
            branch_target = pc + imm;
        end
        else if (is_jalr) begin
            branch_taken  = 1'b1;
            branch_target = (rs1_data + imm) & ~64'd1;
        end
    end

    // -------------------------------------------------
    // Address generation
    // -------------------------------------------------
    assign ex_addr       = alu_result;  // effective address for load/store
    assign ex_store_data = rs2_data;    // store data

endmodule