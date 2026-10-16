`timescale 1ns/1ps

module rv32i_l2_cache_g #(
    parameter int CACHE_BYTES = 16384,
    parameter int LINE_BYTES = 16,
    parameter int NUM_WAYS = 4
) (
    input logic clk,
    input logic rst,

    input logic req,
    input logic write,
    input logic [31:0] addr,
    input logic [127:0] wdata,

    output logic [127:0] rdata,
    output logic ready,

    output logic mem_req,
    output logic mem_write,
    output logic [31:0] mem_addr,
    output logic [127:0] mem_wdata,
    input logic [127:0] mem_rdata,
    input logic mem_ready
);

    localparam int NUM_SETS = CACHE_BYTES / (LINE_BYTES * NUM_WAYS);
    localparam int OFFSET_BITS = $clog2(LINE_BYTES);
    localparam int INDEX_BITS = $clog2(NUM_SETS);
    localparam int WAY_BITS = $clog2(NUM_WAYS);
    localparam int TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;

    logic [127:0] data_array [0:NUM_SETS-1][0:NUM_WAYS-1];
    logic [TAG_BITS-1:0] tag_array [0:NUM_SETS-1][0:NUM_WAYS-1];
    logic valid_array [0:NUM_SETS-1][0:NUM_WAYS-1];
    logic dirty_array [0:NUM_SETS-1][0:NUM_WAYS-1];

    logic [31:0] request_addr;
    logic [127:0] request_wdata;
    logic request_write;

    logic [INDEX_BITS-1:0] request_index;
    logic [TAG_BITS-1:0] request_tag;

    logic [31:0] refill_addr;
    logic [31:0] victim_addr;

    logic hit;
    logic [WAY_BITS-1:0] hit_way;

    logic invalid_found;
    logic [WAY_BITS-1:0] invalid_way;
    logic [WAY_BITS-1:0] lru_victim_way;
    logic [WAY_BITS-1:0] victim_way;

    logic [WAY_BITS-1:0] active_way;
    logic [127:0] victim_line;
    logic [31:0] saved_victim_addr;
    logic [127:0] response_data;

    logic lru_access_valid;

    typedef enum logic [2:0] {
        S_IDLE,
        S_LOOKUP,
        S_WRITEBACK,
        S_REFILL,
        S_RESP
    } state_t;

    state_t state;

    integer i;
    integer j;
    integer w;

    always_comb begin
        request_index = request_addr[OFFSET_BITS + INDEX_BITS - 1:OFFSET_BITS];
        request_tag = request_addr[31:OFFSET_BITS + INDEX_BITS];

        refill_addr = {
            request_addr[31:OFFSET_BITS],
            {OFFSET_BITS{1'b0}}
        };

        hit = 1'b0;
        hit_way = '0;
        invalid_found = 1'b0;
        invalid_way = '0;

        for (w = NUM_WAYS - 1; w >= 0; w = w - 1) begin
            if (
                valid_array[request_index][w] &&
                tag_array[request_index][w] == request_tag
            ) begin
                hit = 1'b1;
                hit_way = w[WAY_BITS-1:0];
            end

            if (!valid_array[request_index][w]) begin
                invalid_found = 1'b1;
                invalid_way = w[WAY_BITS-1:0];
            end
        end

        victim_way = invalid_found ? invalid_way : lru_victim_way;

        victim_addr = {
            tag_array[request_index][victim_way],
            request_index,
            {OFFSET_BITS{1'b0}}
        };

        mem_req = 1'b0;
        mem_write = 1'b0;
        mem_addr = refill_addr;
        mem_wdata = victim_line;

        case (state)
            S_WRITEBACK: begin
                mem_req = 1'b1;
                mem_write = 1'b1;
                mem_addr = saved_victim_addr;
                mem_wdata = victim_line;
            end

            S_REFILL: begin
                mem_req = 1'b1;
                mem_write = 1'b0;
                mem_addr = refill_addr;
            end

            default: begin
                mem_req = 1'b0;
            end
        endcase

        ready = (state == S_RESP);
        rdata = (state == S_RESP) ? response_data : 128'b0;

        lru_access_valid = (state == S_RESP);
    end

    rv32i_lru_g #(
        .NUM_SETS(NUM_SETS),
        .NUM_WAYS(NUM_WAYS),
        .INDEX_BITS(INDEX_BITS),
        .WAY_BITS(WAY_BITS)
    ) u_lru (
        .clk(clk),
        .rst(rst),

        .access_valid(lru_access_valid),
        .access_set(request_index),
        .access_way(active_way),

        .victim_set(request_index),
        .victim_way(lru_victim_way)
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;

            request_addr <= 32'b0;
            request_wdata <= 128'b0;
            request_write <= 1'b0;

            active_way <= '0;
            victim_line <= 128'b0;
            saved_victim_addr <= 32'b0;
            response_data <= 128'b0;

            for (i = 0; i < NUM_SETS; i = i + 1) begin
                for (j = 0; j < NUM_WAYS; j = j + 1) begin
                    data_array[i][j] <= 128'b0;
                    tag_array[i][j] <= '0;
                    valid_array[i][j] <= 1'b0;
                    dirty_array[i][j] <= 1'b0;
                end
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (req) begin
                        request_addr <= addr;
                        request_wdata <= wdata;
                        request_write <= write;
                        state <= S_LOOKUP;
                    end
                end

                S_LOOKUP: begin
                    if (hit) begin
                        active_way <= hit_way;

                        if (request_write) begin
                            data_array[request_index][hit_way] <= request_wdata;
                            dirty_array[request_index][hit_way] <= 1'b1;
                        end else begin
                            response_data <= data_array[request_index][hit_way];
                        end

                        state <= S_RESP;
                    end else begin
                        active_way <= victim_way;

                        if (
                            valid_array[request_index][victim_way] &&
                            dirty_array[request_index][victim_way]
                        ) begin
                            victim_line <= data_array[request_index][victim_way];
                            saved_victim_addr <= victim_addr;
                            state <= S_WRITEBACK;
                        end else if (request_write) begin
                            data_array[request_index][victim_way] <= request_wdata;
                            tag_array[request_index][victim_way] <= request_tag;
                            valid_array[request_index][victim_way] <= 1'b1;
                            dirty_array[request_index][victim_way] <= 1'b1;
                            state <= S_RESP;
                        end else begin
                            state <= S_REFILL;
                        end
                    end
                end

                S_WRITEBACK: begin
                    if (mem_ready) begin
                        dirty_array[request_index][active_way] <= 1'b0;

                        if (request_write) begin
                            data_array[request_index][active_way] <= request_wdata;
                            tag_array[request_index][active_way] <= request_tag;
                            valid_array[request_index][active_way] <= 1'b1;
                            dirty_array[request_index][active_way] <= 1'b1;
                            state <= S_RESP;
                        end else begin
                            state <= S_REFILL;
                        end
                    end
                end

                S_REFILL: begin
                    if (mem_ready) begin
                        data_array[request_index][active_way] <= mem_rdata;
                        tag_array[request_index][active_way] <= request_tag;
                        valid_array[request_index][active_way] <= 1'b1;
                        dirty_array[request_index][active_way] <= 1'b0;
                        response_data <= mem_rdata;
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
