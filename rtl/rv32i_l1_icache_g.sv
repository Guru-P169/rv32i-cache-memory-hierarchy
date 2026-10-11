`timescale 1ns/1ps

module rv32i_l1_icache_g #(
    parameter int CACHE_BYTES = 1024,
    parameter int LINE_BYTES = 16
) (
    input logic clk,
    input logic reset,

    input logic cpu_req,
    input logic [31:0] cpu_pc,
    output logic [31:0] cpu_instr,
    output logic cpu_ready,

    output logic mem_req,
    output logic [31:0]  mem_addr,
    input logic [127:0] mem_rdata,
    input logic mem_ready
);

    localparam int NUM_LINES = CACHE_BYTES / LINE_BYTES;
    localparam int OFFSET_BITS = $clog2(LINE_BYTES);
    localparam int INDEX_BITS = $clog2(NUM_LINES);
    localparam int TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;

    logic [127:0] data_array [0:NUM_LINES-1];
    logic [TAG_BITS-1:0] tag_array [0:NUM_LINES-1];
    logic valid_array [0:NUM_LINES-1];

    logic [31:0] request_pc;
    logic [INDEX_BITS-1:0] request_index;
    logic [OFFSET_BITS-1:0] request_offset;
    logic [TAG_BITS-1:0] request_tag;

    logic [31:0] refill_addr;
    logic [127:0] refill_data;
    logic [31:0] selected_instruction;

    typedef enum logic [2:0] {
        S_IDLE,
        S_LOOKUP,
        S_REFILL,
        S_WAIT_REFILL,
        S_RESP
    } state_t;

    state_t state;

    integer i;

    always_comb begin
        request_index = request_pc[OFFSET_BITS + INDEX_BITS - 1:OFFSET_BITS];
        request_offset = request_pc[OFFSET_BITS-1:0];
        request_tag = request_pc[31:OFFSET_BITS + INDEX_BITS];

        refill_addr = {
            request_pc[31:OFFSET_BITS],
            {OFFSET_BITS{1'b0}}
        };

        selected_instruction = 32'h00000013;

        case (request_offset)
            4'd0: selected_instruction = data_array[request_index][31:0];
            4'd4: selected_instruction = data_array[request_index][63:32];
            4'd8: selected_instruction = data_array[request_index][95:64];
            4'd12: selected_instruction = data_array[request_index][127:96];
            default: selected_instruction = 32'h00000013;
        endcase

        mem_req = (state == S_REFILL);
        mem_addr = refill_addr;

        cpu_ready = (state == S_RESP);
        cpu_instr = 32'h00000013;

        if (state == S_RESP) begin
            if (
                valid_array[request_index] &&
                tag_array[request_index] == request_tag
            )
                cpu_instr = selected_instruction;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            request_pc <= '0;
            refill_data <= '0;

            for (i = 0; i < NUM_LINES; i = i + 1) begin
                data_array[i] <= '0;
                tag_array[i] <= '0;
                valid_array[i] <= 1'b0;
            end
        end else begin
            case (state)

                S_IDLE: begin

                    if (cpu_req) begin
                        request_pc <= cpu_pc;
                        state <= S_LOOKUP;
                    end

                end

                S_LOOKUP: begin
                    if (
                        valid_array[request_index] &&
                        tag_array[request_index] == request_tag
                    ) begin
                        state <= S_RESP;
                    end else begin
                        state <= S_REFILL;
                    end
                end

                S_REFILL: begin
                    if (mem_ready) begin
                        refill_data <= mem_rdata;
                        state <= S_WAIT_REFILL;
                    end
                end

                S_WAIT_REFILL: begin
                    if (!mem_ready) begin
                        data_array[request_index] <= refill_data;
                        tag_array[request_index] <= request_tag;
                        valid_array[request_index] <= 1'b1;
                        state <= S_RESP;
                    end

                end

                S_RESP: begin

                    state <= S_IDLE;
                end

                default: begin

                    state <= S_IDLE;

                end
            endcase
        end
    end

endmodule