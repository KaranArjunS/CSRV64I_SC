// ============================================================
// File   : mem_unit.sv
// Author : Karan Arjun S
// Project: CoreSelva CSRV64I_SC
//
// Description:
//   Combinational memory access unit for a single-cycle RV64I core.
//
//   Responsibilities:
//     - Generate store write data
//     - Perform load sign/zero extension
//
// Notes:
//   - Assumes naturally aligned accesses
//   - Data memory provides a full 64-bit read word
//   - No byte-enable support in memory
// ============================================================

module mem_unit (

    // From execute stage
    input  logic [63:0] addr,
    input  logic [63:0] store_data,

    // From decoder
    input  logic        is_load,
    input  logic        is_store,

    input  logic        is_lb,
    input  logic        is_lh,
    input  logic        is_lw,
    input  logic        is_lwu,
    input  logic        is_lbu,
    input  logic        is_lhu,
    input  logic        is_ld,

    input  logic        is_sb,
    input  logic        is_sh,
    input  logic        is_sw,
    input  logic        is_sd,

    // From data memory
    input  logic [63:0] dmem_rdata,

    // To data memory
    output logic [63:0] dmem_wdata,
    output logic        dmem_we,

    // To writeback
    output logic [63:0] load_result
);

    logic [2:0]  byte_offset;
    logic [63:0] shifted_rdata;

    // Byte offset within 64-bit word
    assign byte_offset   = addr[2:0];
    assign shifted_rdata = dmem_rdata >> (byte_offset * 8);

    // -------------------------------------------------
    // STORE path
    // -------------------------------------------------
    always_comb begin
        dmem_we    = 1'b0;
        dmem_wdata = 64'b0;

        if (is_store) begin
            dmem_we = 1'b1;

            // Store data is shifted into position
            // Memory must accept full 64-bit writes
            if (is_sb)
                dmem_wdata = store_data << (byte_offset * 8);
            else if (is_sh)
                dmem_wdata = store_data << (byte_offset * 8);
            else if (is_sw)
                dmem_wdata = store_data << (byte_offset * 8);
            else if (is_sd)
                dmem_wdata = store_data;
        end
    end

    // -------------------------------------------------
    // LOAD path
    // -------------------------------------------------
    always_comb begin
        load_result = 64'b0;

        if (is_lb)
            load_result = {{56{shifted_rdata[7]}}, shifted_rdata[7:0]};
        else if (is_lbu)
            load_result = {56'b0, shifted_rdata[7:0]};
        else if (is_lh)
            load_result = {{48{shifted_rdata[15]}}, shifted_rdata[15:0]};
        else if (is_lhu)
            load_result = {48'b0, shifted_rdata[15:0]};
        else if (is_lw)
            load_result = {{32{shifted_rdata[31]}}, shifted_rdata[31:0]};
        else if (is_lwu)
            load_result = {32'b0, shifted_rdata[31:0]};
        else if (is_ld)
            load_result = dmem_rdata;
    end

endmodule