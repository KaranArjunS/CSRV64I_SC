// ============================================================
// File   : alu_control.sv
// Author : Karan Arjun S
// Project: CoreSelva CSRV64I_SC
//
// Description:
//   ALU control unit for RV64I base integer instructions.
//
//   Generates ALU operation codes for:
//     - R-type ALU instructions
//     - I-type ALU immediate instructions
//
// Notes:
//   - Load, store, branch, and jump instructions do not use this block
//   - Shift amount is taken from imm[5:0] in the execute stage
// ============================================================

module alu_control (
    input  logic        is_rtype,
    input  logic        is_itype,
    input  logic        is_alu,
    input  logic [2:0]  funct3,
    input  logic        funct7_5,   // instr[30]

    output logic [3:0]  alu_op
);

    // -------------------------------------------------
    // ALU operation encoding
    // -------------------------------------------------
    localparam ALU_ADD  = 4'd0;
    localparam ALU_SUB  = 4'd1;
    localparam ALU_AND  = 4'd2;
    localparam ALU_OR   = 4'd3;
    localparam ALU_XOR  = 4'd4;
    localparam ALU_SLL  = 4'd5;
    localparam ALU_SRL  = 4'd6;
    localparam ALU_SRA  = 4'd7;
    localparam ALU_SLT  = 4'd8;
    localparam ALU_SLTU = 4'd9;

    // -------------------------------------------------
    // Decode logic
    // -------------------------------------------------
    always_comb begin
        // Default safe operation
        alu_op = ALU_ADD;

        // -----------------------------
        // R-type ALU instructions
        // -----------------------------
        if (is_rtype) begin
            case (funct3)
                3'b000: alu_op = funct7_5 ? ALU_SUB : ALU_ADD; // ADD / SUB
                3'b111: alu_op = ALU_AND;
                3'b110: alu_op = ALU_OR;
                3'b100: alu_op = ALU_XOR;
                3'b001: alu_op = ALU_SLL;
                3'b101: alu_op = funct7_5 ? ALU_SRA : ALU_SRL; // SRA / SRL
                3'b010: alu_op = ALU_SLT;
                3'b011: alu_op = ALU_SLTU;
                default: alu_op = ALU_ADD;
            endcase
        end

        // -----------------------------
        // I-type ALU immediate
        // -----------------------------
        else if (is_itype && is_alu) begin
            case (funct3)
                3'b000: alu_op = ALU_ADD;   // ADDI
                3'b111: alu_op = ALU_AND;   // ANDI
                3'b110: alu_op = ALU_OR;    // ORI
                3'b100: alu_op = ALU_XOR;   // XORI
                3'b001: alu_op = ALU_SLL;   // SLLI
                3'b101: alu_op = funct7_5 ? ALU_SRA : ALU_SRL; // SRAI / SRLI
                3'b010: alu_op = ALU_SLT;   // SLTI
                3'b011: alu_op = ALU_SLTU;  // SLTIU
                default: alu_op = ALU_ADD;
            endcase
        end
    end

endmodule