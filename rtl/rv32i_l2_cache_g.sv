`timescale 1ns/1ps

module rv32i_cache_hierarchy_g #(
    parameter int MEMORY_BYTES = 65536,
    parameter int MEMORY_LATENCY = 5,
    parameter string INIT_FILE = "instruction_memory.hex"
)(
    input logic clk,
    input logic reset,

    input logic i_req,
    input logic [31:0] i_addr,
    output logic [31:0] i_instr,
    output logic i_ready,

    input logic d_req,
    input logic d_write,
    input logic [31:0] d_addr,
    input logic [31:0] d_wdata,
    input logic [3:0] d_byte_en,
    input logic [2:0] d_load_type,
    output logic [31:0] d_rdata,
    output logic d_ready
);

    logic ic_mem_req;
    logic [31:0] ic_mem_addr;
    logic [127:0] ic_mem_rdata;
    logic ic_mem_ready;

    logic dc_mem_req;
    logic dc_mem_write;
    logic [31:0] dc_mem_addr;
    logic [127:0] dc_mem_wdata;
    logic [127:0] dc_mem_rdata;
    logic dc_mem_ready;

    logic arb_l2_req;
    logic arb_l2_write;
    logic [31:0] arb_l2_addr;
    logic [127:0] arb_l2_wdata;
    logic [127:0] arb_l2_rdata;
    logic arb_l2_ready;

    logic l2_mem_req;
    logic l2_mem_write;
    logic [31:0] l2_mem_addr;
    logic [127:0] l2_mem_wdata;
    logic [127:0] l2_mem_rdata;
    logic l2_mem_ready;

    rv32i_l1_icache_g #(
        .CACHE_BYTES(1024),
        .LINE_BYTES(16)
    ) u_l1_icache (
        .clk(clk),
        .reset(reset),

        .cpu_req(i_req),
        .cpu_pc(i_addr),
        .cpu_instr(i_instr),
        .cpu_ready(i_ready),

        .mem_req(ic_mem_req),
        .mem_addr(ic_mem_addr),
        .mem_rdata(ic_mem_rdata),
        .mem_ready(ic_mem_ready)
    );

    rv32i_l1_dcache_g #(
        .CACHE_BYTES(2048),
        .LINE_BYTES(16)
    ) u_l1_dcache (
        .clk(clk),
        .reset(reset),

        .cpu_req(d_req),
        .cpu_write(d_write),
        .cpu_addr(d_addr),
        .cpu_wdata(d_wdata),
        .cpu_byte_en(d_byte_en),
        .cpu_load_type(d_load_type),
        .cpu_rdata(d_rdata),
        .cpu_ready(d_ready),

        .mem_req(dc_mem_req),
        .mem_write(dc_mem_write),
        .mem_addr(dc_mem_addr),
        .mem_wdata(dc_mem_wdata),
        .mem_rdata(dc_mem_rdata),
        .mem_ready(dc_mem_ready)
    );

    rv32i_l2_arbiter_g u_l2_arbiter (
        .clk(clk),
        .rst(reset),

        .ic_req(ic_mem_req),
        .ic_write(1'b0),
        .ic_addr(ic_mem_addr),
        .ic_wdata(128'b0),
        .ic_rdata(ic_mem_rdata),
        .ic_ready(ic_mem_ready),

        .dc_req(dc_mem_req),
        .dc_write(dc_mem_write),
        .dc_addr(dc_mem_addr),
        .dc_wdata(dc_mem_wdata),
        .dc_rdata(dc_mem_rdata),
        .dc_ready(dc_mem_ready),

        .l2_req(arb_l2_req),
        .l2_write(arb_l2_write),
        .l2_addr(arb_l2_addr),
        .l2_wdata(arb_l2_wdata),
        .l2_rdata(arb_l2_rdata),
        .l2_ready(arb_l2_ready)
    );

    rv32i_l2_cache_g #(
        .CACHE_BYTES(16384),
        .LINE_BYTES(16),
        .NUM_WAYS(4)
    ) u_l2_cache (
        .clk(clk),
        .rst(reset),

        .req(arb_l2_req),
        .write(arb_l2_write),
        .addr(arb_l2_addr),
        .wdata(arb_l2_wdata),

        .rdata(arb_l2_rdata),
        .ready(arb_l2_ready),

        .mem_req(l2_mem_req),
        .mem_write(l2_mem_write),
        .mem_addr(l2_mem_addr),
        .mem_wdata(l2_mem_wdata),
        .mem_rdata(l2_mem_rdata),
        .mem_ready(l2_mem_ready)
    );

    rv32i_main_memory_g #(
        .MEMORY_BYTES(MEMORY_BYTES),
        .LINE_BYTES(16),
        .LATENCY(MEMORY_LATENCY),
        .INIT_FILE(INIT_FILE)
    ) u_main_memory (
        .clk(clk),
        .reset(reset),

        .req(l2_mem_req),
        .write(l2_mem_write),
        .addr(l2_mem_addr),
        .wdata(l2_mem_wdata),

        .rdata(l2_mem_rdata),
        .ready(l2_mem_ready)
    );

endmodule