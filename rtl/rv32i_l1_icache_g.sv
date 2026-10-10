`timescale 1ns/1ps

module rv32i_l1_icache_g #(
    parameter int CACHE_LINES = 64,
    parameter int LINE_BYTES  = 16
) (
    input  logic         clk,
    input  logic         reset,

    input  logic         cpu_req,
    input  logic [31:0]  cpu_pc,
    output logic [31:0]  cpu_instr,
    output logic         cpu_ready,

    output logic         mem_req,
    output logic [31:0]  mem_addr,
    input  logic [127:0] mem_rdata,
    input  logic         mem_ready
);

    localparam int INDEX_BITS  = 6;
    localparam int OFFSET_BITS = 4;
    localparam int TAG_BITS    = 22;

    typedef enum logic [2:0] {
        S_IDLE,
        S_LOOKUP,
        S_REFILL_REQ,
        S_REFILL_WAIT,
        S_RESP
    } state_t;

    state_t state;

    logic [127:0] data_array [0:CACHE_LINES-1];
    logic [TAG_BITS-1:0] tag_array [0:CACHE_LINES-1];
    logic                valid_array [0:CACHE_LINES-1];

    logic [31:0] request_pc;

    logic [INDEX_BITS-1:0]  request_index;
    logic [OFFSET_BITS-1:0] request_offset;
    logic [TAG_BITS-1:0]    request_tag;

    logic [31:0] refill_base_addr;

    logic cache_hit;

    integer i;

    always_comb begin
        request_index =
            request_pc[9:4];

        request_offset =
            request_pc[3:0];

        request_tag =
            request_pc[31:10];

        refill_base_addr =
            {request_pc[31:4], 4'b0000};
    end

    always_comb begin
        cache_hit =
            valid_array[request_index] &&
            (tag_array[request_index] == request_tag);
    end

    always_comb begin
        cpu_instr = 32'h00000013;
        cpu_ready = 1'b0;

        mem_req   = 1'b0;
        mem_addr  = refill_base_addr;

        case (state)

            S_IDLE: begin
                cpu_ready = 1'b0;
            end

            S_LOOKUP: begin
                if (cache_hit) begin
                    cpu_ready = 1'b1;

                    case (request_offset)

                        4'h0:
                            cpu_instr =
                                data_array[request_index][31:0];

                        4'h4:
                            cpu_instr =
                                data_array[request_index][63:32];

                        4'h8:
                            cpu_instr =
                                data_array[request_index][95:64];

                        4'hC:
                            cpu_instr =
                                data_array[request_index][127:96];

                        default:
                            cpu_instr = 32'h00000013;

                    endcase
                end
            end

            S_REFILL_REQ: begin
                mem_req  = 1'b1;
                mem_addr = refill_base_addr;
            end

            S_REFILL_WAIT: begin
                mem_req  = 1'b0;
                mem_addr = refill_base_addr;
            end

            S_RESP: begin
                cpu_ready = 1'b1;

                case (request_offset)

                    4'h0:
                        cpu_instr =
                            data_array[request_index][31:0];

                    4'h4:
                        cpu_instr =
                            data_array[request_index][63:32];

                    4'h8:
                        cpu_instr =
                            data_array[request_index][95:64];

                    4'hC:
                        cpu_instr =
                            data_array[request_index][127:96];

                    default:
                        cpu_instr = 32'h00000013;

                endcase
            end

            default: begin
                cpu_ready = 1'b0;
                cpu_instr = 32'h00000013;
                mem_req   = 1'b0;
            end

        endcase
    end

    always_ff @(posedge clk) begin

        if (reset) begin

            state      <= S_IDLE;
            request_pc <= 32'b0;

            for (i = 0; i < CACHE_LINES; i = i + 1) begin
                data_array[i]  <= 128'b0;
                tag_array[i]   <= '0;
                valid_array[i] <= 1'b0;
            end

        end
        else begin

            case (state)

                S_IDLE: begin

                    if (cpu_req) begin
                        request_pc <= cpu_pc;
                        state      <= S_LOOKUP;
                    end

                end

                S_LOOKUP: begin

                    if (cache_hit) begin
                        state <= S_RESP;
                    end
                    else begin
                        state <= S_REFILL_REQ;
                    end

                end

                S_REFILL_REQ: begin

                    state <= S_REFILL_WAIT;

                end

                S_REFILL_WAIT: begin

                    if (mem_ready) begin

                        data_array[request_index] <= mem_rdata;

                        tag_array[request_index] <=
                            request_tag;

                        valid_array[request_index] <=
                            1'b1;

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