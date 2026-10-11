`timescale 1ns/1ps

module rv32i_main_memory_g #(
    parameter int MEMORY_BYTES = 65536,
    parameter int LINE_BYTES = 16,
    parameter int LATENCY = 5,
    parameter INIT_FILE = "instruction_memory.hex"
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

    localparam int NUM_LINES = MEMORY_BYTES / LINE_BYTES;
    localparam int NUM_WORDS = MEMORY_BYTES / 4;
    localparam int LATENCY_COUNT_WIDTH = (LATENCY < 2) ? 1 : $clog2(LATENCY + 1);

    typedef enum logic [1:0] {
        M_IDLE,
        M_WAIT,
        M_RESP
    } memory_state_t;

    memory_state_t state;

    logic [127:0] memory [0:NUM_LINES-1];
    logic [31:0] instruction_words [0:NUM_WORDS-1];

    logic [31:0] saved_addr;
    logic [127:0] saved_wdata;
    logic saved_write;

    logic [LATENCY_COUNT_WIDTH-1:0] latency_count;

    integer i;
    integer j;
    integer line_index;

    initial begin
        if (MEMORY_BYTES < LINE_BYTES)
            $fatal(1, "MEMORY_BYTES must be at least LINE_BYTES");

        if ((MEMORY_BYTES % LINE_BYTES) != 0)
            $fatal(1, "MEMORY_BYTES must be divisible by LINE_BYTES");

        if (LINE_BYTES != 16)
            $fatal(1, "This module requires LINE_BYTES = 16");

        if ((MEMORY_BYTES & (MEMORY_BYTES - 1)) != 0)
            $fatal(1, "MEMORY_BYTES must be a power of two");

        if (LATENCY < 1)
            $fatal(1, "LATENCY must be at least 1");

        for (i = 0; i < NUM_LINES; i = i + 1)
            memory[i] = 128'b0;

        for (i = 0; i < NUM_WORDS; i = i + 1)
            instruction_words[i] = 32'b0;

        if (INIT_FILE != "")
            $readmemh(INIT_FILE, instruction_words);

        for (i = 0; i < NUM_LINES; i = i + 1) begin
            memory[i] = {
                instruction_words[i*4+3],
                instruction_words[i*4+2],
                instruction_words[i*4+1],
                instruction_words[i*4]
            };
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= M_IDLE;
            saved_addr <= 32'b0;
            saved_wdata <= 128'b0;
            saved_write <= 1'b0;
            latency_count <= '0;
            rdata <= 128'b0;
            ready <= 1'b0;
        end else begin
            ready <= 1'b0;

            case (state)
                M_IDLE: begin
                    if (req && !ready) begin
                        saved_addr <= addr;
                        saved_wdata <= wdata;
                        saved_write <= write;
                        latency_count <= LATENCY_COUNT_WIDTH'(LATENCY);
                        state <= M_WAIT;
                    end
                end

                M_WAIT: begin
                    if (latency_count > 1) begin
                        latency_count <= latency_count - 1'b1;
                    end else begin
                        state <= M_RESP;
                    end
                end

                M_RESP: begin
                    line_index = saved_addr / LINE_BYTES;

                    if (line_index >= 0 && line_index < NUM_LINES) begin
                        if (saved_write)
                            memory[line_index] <= saved_wdata;
                        else
                            rdata <= memory[line_index];
                    end else begin
                        rdata <= 128'b0;
                    end

                    ready <= 1'b1;
                    state <= M_IDLE;
                end

                default: begin
                    state <= M_IDLE;
                end
            endcase
        end
    end

endmodule