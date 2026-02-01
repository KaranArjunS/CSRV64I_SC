// ============================================================
// File   : csrv64i.sv
// Author : Karan Arjun S
// Project: CoreSelva CSRV64I_SC
//
// Description:
//   Simulation top for a single-cycle, non-pipelined RV64I core.
//
//   Implemented datapath:
//     Fetch → Decode → Register File → Execute → Memory → Writeback
//
//   ISA scope:
//     - Unprivileged RV64I base instructions
//     - No CSR, no interrupts, no MMU, no cache
//
// Notes:
//   - ALU control derived directly from instruction fields
//   - Assumes naturally aligned memory accesses
//   - Data memory supports full-width writes only
// ============================================================

module csrv64i (

    input  logic clk,
    input  logic reset,

);

    // Writeback trace (simulation aid)
    always_ff @(posedge clk) begin
        if (wb_we)
            $display("[WB] x%0d = %0d", wb_rd, wb_data);
    end

    // =========================================================
    // FETCH
    // =========================================================
    logic [63:0] pc;
    logic [63:0] imem_addr;
    logic [31:0] instr;

    logic        pc_redirect;
    logic [63:0] pc_redirect_target;

    // =========================================================
    // DECODE
    // =========================================================
    logic [4:0]  rd, rs1, rs2;
    logic [63:0] imm;

    logic is_rtype, is_itype, is_stype, is_btype;
    logic is_utype, is_jtype;
    logic is_load, is_store, is_branch;
    logic is_jal, is_jalr, is_lui, is_auipc, is_alu;
    logic illegal_instr;

    logic is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu;
    logic is_lb, is_lh, is_lw, is_lbu, is_lhu, is_lwu;
    logic is_sb, is_sh, is_sw, is_sd;
    logic is_ecall, is_ebreak;

    // LD is inferred when load is asserted without sub-width qualifiers
    logic is_ld;
    assign is_ld = is_load & ~(is_lb | is_lh | is_lw | is_lbu | is_lhu | is_lwu);

    // =========================================================
    // REGISTER FILE
    // =========================================================
    logic [63:0] rs1_data, rs2_data;

    // =========================================================
    // ALU CONTROL
    // =========================================================
    logic [3:0] alu_op;
    logic [2:0] funct3;
    logic       funct7_5;

    // Instruction fields used directly (single-cycle safe)
    assign funct3   = instr[14:12];
    assign funct7_5 = instr[30];

    // =========================================================
    // EXECUTE
    // =========================================================
    logic [63:0] alu_result;
    logic [63:0] ex_addr;
    logic [63:0] ex_store_data;

    logic        branch_taken;
    logic [63:0] branch_target;

    logic        trap;
    logic [63:0] trap_target;

    // =========================================================
    // MEMORY
    // =========================================================
    logic [63:0] dmem_wdata;
    logic        dmem_we;
    logic [63:0] dmem_rdata;
    logic [63:0] load_result;

    // Any store instruction triggers write enable
    assign dmem_we = is_store;

    // =========================================================
    // WRITEBACK
    // =========================================================
    logic        wb_we;
    logic [4:0]  wb_rd;
    logic [63:0] wb_data;

    // Single-cycle writeback selection
    always_comb begin
        wb_we   = 1'b0;
        wb_rd   = rd;
        wb_data = 64'd0;

        if (is_load) begin
            wb_we   = 1'b1;
            wb_data = load_result;
        end
        else if (is_alu) begin
            wb_we   = 1'b1;
            wb_data = alu_result;
        end
        else if (is_lui) begin
            wb_we   = 1'b1;
            wb_data = imm;
        end
        else if (is_auipc) begin
            wb_we   = 1'b1;
            wb_data = pc + imm;
        end
        else if (is_jal || is_jalr) begin
            wb_we   = 1'b1;
            wb_data = pc + 64'd4;
        end
    end

    // =========================================================
    // PC REDIRECTION
    // =========================================================
    assign pc_redirect        = trap | branch_taken;
    assign pc_redirect_target = trap ? trap_target : branch_target;

    // =========================================================
    // MODULE INSTANTIATIONS
    // =========================================================

    pc_fetch pc_fetch_inst (
        .clk                (clk),
        .reset              (reset),
        .pc_redirect        (pc_redirect),
        .pc_redirect_target (pc_redirect_target),
        .pc                 (pc),
        .imem_addr          (imem_addr)
    );

    imem imem_inst (
        .addr  (imem_addr),
        .instr (instr)
    );

    decoder decoder_inst (
        .instr         (instr),
        .rd            (rd),
        .rs1           (rs1),
        .rs2           (rs2),
        .imm           (imm),
        .is_rtype      (is_rtype),
        .is_itype      (is_itype),
        .is_stype      (is_stype),
        .is_btype      (is_btype),
        .is_utype      (is_utype),
        .is_jtype      (is_jtype),
        .is_load       (is_load),
        .is_store      (is_store),
        .is_branch     (is_branch),
        .is_jal        (is_jal),
        .is_jalr       (is_jalr),
        .is_lui        (is_lui),
        .is_auipc      (is_auipc),
        .is_alu        (is_alu),
        .is_beq        (is_beq),
        .is_bne        (is_bne),
        .is_blt        (is_blt),
        .is_bge        (is_bge),
        .is_bltu       (is_bltu),
        .is_bgeu       (is_bgeu),
        .is_lb         (is_lb),
        .is_lh         (is_lh),
        .is_lw         (is_lw),
        .is_lbu        (is_lbu),
        .is_lhu        (is_lhu),
        .is_lwu        (is_lwu),
        .is_sb         (is_sb),
        .is_sh         (is_sh),
        .is_sw         (is_sw),
        .is_sd         (is_sd),
        .is_ecall      (is_ecall),
        .is_ebreak     (is_ebreak),
        .illegal_instr (illegal_instr)
    );

    regfile regfile_inst (
        .clk    (clk),
        .we     (wb_we),
        .waddr  (wb_rd),
        .wdata  (wb_data),
        .raddr1 (rs1),
        .rdata1 (rs1_data),
        .raddr2 (rs2),
        .rdata2 (rs2_data)
    );

    alu_control alu_ctrl (
        .is_rtype (is_rtype),
        .is_itype (is_itype),
        .is_alu   (is_alu),
        .funct3   (funct3),
        .funct7_5 (funct7_5),
        .alu_op   (alu_op)
    );

    execute execute_inst (
        .rs1_data      (rs1_data),
        .rs2_data      (rs2_data),
        .imm           (imm),
        .pc            (pc),
        .rd            (rd),
        .is_rtype      (is_rtype),
        .is_alu        (is_alu),
        .is_load       (is_load),
        .is_store      (is_store),
        .is_branch     (is_branch),
        .is_jal        (is_jal),
        .is_jalr       (is_jalr),
        .is_auipc      (is_auipc),
        .is_lui        (is_lui),
        .is_beq        (is_beq),
        .is_bne        (is_bne),
        .is_blt        (is_blt),
        .is_bge        (is_bge),
        .is_bltu       (is_bltu),
        .is_bgeu       (is_bgeu),
        .is_ecall      (is_ecall),
        .is_ebreak     (is_ebreak),
        .illegal_instr (illegal_instr),
        .alu_op        (alu_op),
        .alu_result    (alu_result),
        .ex_addr       (ex_addr),
        .ex_store_data (ex_store_data),
        .branch_taken  (branch_taken),
        .branch_target (branch_target),
        .trap          (trap),
        .trap_target   (trap_target)
    );

    mem_unit mem_unit_inst (
        .addr        (ex_addr),
        .store_data  (ex_store_data),
        .is_store    (is_store),
        .is_lb       (is_lb),
        .is_lh       (is_lh),
        .is_lw       (is_lw),
        .is_lwu      (is_lwu),
        .is_lbu      (is_lbu),
        .is_lhu      (is_lhu),
        .is_ld       (is_ld),
        .is_sb       (is_sb),
        .is_sh       (is_sh),
        .is_sw       (is_sw),
        .is_sd       (is_sd),
        .dmem_rdata  (dmem_rdata),
        .dmem_wdata  (dmem_wdata),
        .dmem_we     (dmem_we),
        .load_result (load_result)
    );

    dmem dmem_inst (
        .clk   (clk),
        .addr  (ex_addr),
        .wdata (dmem_wdata),
        .we    (dmem_we),
        .rdata (dmem_rdata)
    );

endmodule