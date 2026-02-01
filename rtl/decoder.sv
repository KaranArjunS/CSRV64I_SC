// ============================================================
// File   : decoder.sv
// Author : Karan Arjun S
// Project: CoreSelva CSRV64I_SC
//
// Description:
//   RV64I instruction decoder for a single-cycle core.
//
//   Decodes opcode, funct3, funct7 and generates:
//     - register indices
//     - sign-extended immediates
//     - instruction class flags
//
// Notes:
//   - Only unprivileged RV64I base instructions are decoded
//   - No CSR or privileged instruction support
// ============================================================

module decoder (
    input  logic [31:0] instr,

    output logic [4:0]  rd,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [63:0] imm,

    output logic is_rtype,
    output logic is_itype,
    output logic is_stype,
    output logic is_btype,
    output logic is_utype,
    output logic is_jtype,

    output logic is_load,
    output logic is_store,
    output logic is_branch,
    output logic is_jal,
    output logic is_jalr,
    output logic is_lui,
    output logic is_auipc,
    output logic is_alu,

    output logic is_beq,
    output logic is_bne,
    output logic is_blt,
    output logic is_bge,
    output logic is_bltu,
    output logic is_bgeu,

    output logic is_lb,
    output logic is_lh,
    output logic is_lw,
    output logic is_ld,
    output logic is_lbu,
    output logic is_lhu,
    output logic is_lwu,

    output logic is_sb,
    output logic is_sh,
    output logic is_sw,
    output logic is_sd,

    output logic is_ecall,
    output logic is_ebreak,

    output logic illegal_instr
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    always_comb begin
        // ---------------- defaults ----------------
        rd = 0; rs1 = 0; rs2 = 0; imm = 0;

        is_rtype = 0; is_itype = 0; is_stype = 0;
        is_btype = 0; is_utype = 0; is_jtype = 0;

        is_load = 0; is_store = 0; is_branch = 0;
        is_jal = 0; is_jalr = 0; is_lui = 0;
        is_auipc = 0; is_alu = 0;

        is_beq = 0; is_bne = 0; is_blt = 0;
        is_bge = 0; is_bltu = 0; is_bgeu = 0;

        is_lb = 0; is_lh = 0; is_lw = 0; is_ld = 0;
        is_lbu = 0; is_lhu = 0; is_lwu = 0;

        is_sb = 0; is_sh = 0; is_sw = 0; is_sd = 0;

        is_ecall = 0; is_ebreak = 0;

        illegal_instr = 0;

        case (opcode)

        // ================= R-type =================
        7'b0110011: begin
            rd  = instr[11:7];
            rs1 = instr[19:15];
            rs2 = instr[24:20];
            is_rtype = 1;
            is_alu   = 1;

            case ({funct7, funct3})
                {7'b0000000,3'b000}, // ADD
                {7'b0100000,3'b000}, // SUB
                {7'b0000000,3'b111}, // AND
                {7'b0000000,3'b110}, // OR
                {7'b0000000,3'b100}, // XOR
                {7'b0000000,3'b001}, // SLL
                {7'b0000000,3'b101}, // SRL
                {7'b0100000,3'b101}, // SRA
                {7'b0000000,3'b010}, // SLT
                {7'b0000000,3'b011}: ; // SLTU
                default: illegal_instr = 1;
            endcase
        end

        // ================= I-type ALU =================
        7'b0010011: begin
            rd  = instr[11:7];
            rs1 = instr[19:15];
            imm = {{52{instr[31]}}, instr[31:20]};
            is_itype = 1;
            is_alu   = 1;

            case (funct3)
                3'b000, // ADDI
                3'b010, // SLTI
                3'b011, // SLTIU
                3'b100, // XORI
                3'b110, // ORI
                3'b111: ; // ANDI

                3'b001: if (funct7 != 7'b0000000) illegal_instr = 1; // SLLI
                3'b101: if (!(funct7 == 7'b0000000 || funct7 == 7'b0100000))
                             illegal_instr = 1; // SRLI/SRAI
                default: illegal_instr = 1;
            endcase
        end

        // ================= LOAD =================
        7'b0000011: begin
            rd  = instr[11:7];
            rs1 = instr[19:15];
            imm = {{52{instr[31]}}, instr[31:20]};
            is_load = 1;

            case (funct3)
                3'b000: is_lb  = 1;
                3'b001: is_lh  = 1;
                3'b010: is_lw  = 1;
                3'b011: is_ld  = 1;
                3'b100: is_lbu = 1;
                3'b101: is_lhu = 1;
                3'b110: is_lwu = 1;
                default: illegal_instr = 1;
            endcase
        end

        // ================= STORE =================
        7'b0100011: begin
            rs1 = instr[19:15];
            rs2 = instr[24:20];
            imm = {{52{instr[31]}}, instr[31:25], instr[11:7]};
            is_store = 1;

            case (funct3)
                3'b000: is_sb = 1;
                3'b001: is_sh = 1;
                3'b010: is_sw = 1;
                3'b011: is_sd = 1;
                default: illegal_instr = 1;
            endcase
        end

        // ================= BRANCH =================
        7'b1100011: begin
            rs1 = instr[19:15];
            rs2 = instr[24:20];
            imm = {{51{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            is_branch = 1;

            case (funct3)
                3'b000: is_beq  = 1;
                3'b001: is_bne  = 1;
                3'b100: is_blt  = 1;
                3'b101: is_bge  = 1;
                3'b110: is_bltu = 1;
                3'b111: is_bgeu = 1;
                default: illegal_instr = 1;
            endcase
        end

        // ================= JAL =================
        7'b1101111: begin
            rd  = instr[11:7];
            imm = {{43{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            is_jal = 1;
        end

        // ================= JALR =================
        7'b1100111: begin
            rd  = instr[11:7];
            rs1 = instr[19:15];
            imm = {{52{instr[31]}}, instr[31:20]};
            is_jalr = 1;
        end

        // ================= LUI =================
        7'b0110111: begin
            rd  = instr[11:7];
            imm = {instr[31:12], 12'b0};
            is_lui = 1;
        end

        // ================= AUIPC =================
        7'b0010111: begin
            rd  = instr[11:7];
            imm = {instr[31:12], 12'b0};
            is_auipc = 1;
        end

        // ================= SYSTEM =================
        7'b1110011: begin
            if (instr == 32'h00000073)      is_ecall  = 1;
            else if (instr == 32'h00100073) is_ebreak = 1;
            else illegal_instr = 1;
        end

        default: illegal_instr = 1;

        endcase
    end

endmodule