`timescale 1ns/1ps

module rv32i_memory_hierarchy_g #(
    parameter int MEMORY_BYTES = 65536,
    parameter int MEMORY_LATENCY = 5,
    parameter string INIT_FILE = "instruction_memory.hex"
)(
    input logic clk,
    input logic reset,

    input logic req,
    input logic write,
    input logic [31:0] addr,
    input logic [127:0] wdata,

    output logic [127:0] rdata,
    output logic ready
);

    logic l2_mem_req;
    logic l2_mem_write;
    logic [31:0] l2_mem_addr;
    logic [127:0] l2_mem_wdata;
    logic [127:0] l2_mem_rdata;
    logic l2_mem_ready;

    rv32i_l2_cache_g #(
        .CACHE_BYTES(16384),
        .LINE_BYTES(16),
        .NUM_WAYS(4)
    ) u_l2_cache (
        .clk(clk),
        .rst(reset),

        .req(req),
        .write(write),
        .addr(addr),
        .wdata(wdata),

        .rdata(rdata),
        .ready(ready),

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