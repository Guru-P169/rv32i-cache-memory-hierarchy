
module rv32i_l1_dcache_g #(
    parameter int CACHE_BYTES = 1024,
    parameter int LINE_BYTES = 16
) (
    input  logic clk,
    input  logic reset,

    input  logic cpu_req,
    input  logic cpu_write,
    input  logic [31:0]  cpu_addr,
    input  logic [31:0]  cpu_wdata,
    input  logic [3:0] cpu_byte_en,
    input  logic [2:0] cpu_load_type,
    output logic [31:0]  cpu_rdata,
    output logic cpu_ready,

    output logic mem_req,
    output logic mem_write,
    output logic [31:0]  mem_addr,
    output logic [127:0] mem_wdata,
    input  logic [127:0] mem_rdata,
    input  logic mem_ready
);

    localparam int NUM_LINES = CACHE_BYTES / LINE_BYTES;
    localparam int OFFSET_BITS = $clog2(LINE_BYTES);
    localparam int INDEX_BITS = $clog2(NUM_LINES);
    localparam int TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;

    localparam logic [2:0] LOAD_BYTE   = 3'b000;
    localparam logic [2:0] LOAD_HALF   = 3'b001;
    localparam logic [2:0] LOAD_WORD   = 3'b010;
    localparam logic [2:0] LOAD_BYTE_U = 3'b100;
    localparam logic [2:0] LOAD_HALF_U = 3'b101;

    logic [127:0] data_array [0:NUM_LINES-1];
    logic [TAG_BITS-1:0] tag_array [0:NUM_LINES-1];
    logic valid_array [0:NUM_LINES-1];
    logic dirty_array [0:NUM_LINES-1];

    logic [31:0] request_addr;
    logic [31:0] request_wdata;
    logic [3:0] request_byte_en;
    logic [2:0] request_load_type;
    logic request_write;

    logic [INDEX_BITS-1:0] request_index;
    logic [OFFSET_BITS-1:0] request_offset;
    logic [TAG_BITS-1:0] request_tag;

    logic [31:0] refill_addr;
    logic [31:0] victim_addr;

    logic [127:0] selected_line;
    logic [31:0] selected_word;
    logic [31:0] formatted_rdata;
    logic [127:0] updated_line;

    logic [127:0] victim_line;
    logic [31:0] saved_victim_addr;
    logic [127:0] refill_data;

    typedef enum logic [3:0] {
        S_IDLE,
        S_LOOKUP,
        S_WRITEBACK,
        S_WAIT_WRITEBACK,
        S_REFILL,
        S_WAIT_REFILL,
        S_ACCESS,
        S_RESP
    } state_t;

    state_t state;

    integer i;
    integer b;

    always_comb begin
        request_index = request_addr[OFFSET_BITS + INDEX_BITS - 1:OFFSET_BITS];
        request_offset = request_addr[OFFSET_BITS-1:0];
        request_tag = request_addr[31:OFFSET_BITS + INDEX_BITS];

        refill_addr = {
            request_addr[31:OFFSET_BITS],
            {OFFSET_BITS{1'b0}}
        };

        victim_addr = {
            tag_array[request_index],
            request_index,
            {OFFSET_BITS{1'b0}}
        };

        selected_line = data_array[request_index];

        case (request_offset[3:2])
            2'd0: selected_word = selected_line[31:0];
            2'd1: selected_word = selected_line[63:32];
            2'd2: selected_word = selected_line[95:64];
            2'd3: selected_word = selected_line[127:96];
            default: selected_word = 32'b0;
        endcase

        case (request_load_type)
            LOAD_BYTE: begin
                case (request_offset[1:0])
                    2'd0: formatted_rdata = {{24{selected_word[7]}}, selected_word[7:0]};
                    2'd1: formatted_rdata = {{24{selected_word[15]}}, selected_word[15:8]};
                    2'd2: formatted_rdata = {{24{selected_word[23]}}, selected_word[23:16]};
                    default: formatted_rdata = {{24{selected_word[31]}}, selected_word[31:24]};
                endcase
            end

            LOAD_HALF: begin
                if (request_offset[1])
                    formatted_rdata = {{16{selected_word[31]}}, selected_word[31:16]};
                else
                    formatted_rdata = {{16{selected_word[15]}}, selected_word[15:0]};
            end

            LOAD_WORD: formatted_rdata = selected_word;

            LOAD_BYTE_U: begin
                case (request_offset[1:0])
                    2'd0: formatted_rdata = {24'b0, selected_word[7:0]};
                    2'd1: formatted_rdata = {24'b0, selected_word[15:8]};
                    2'd2: formatted_rdata = {24'b0, selected_word[23:16]};
                    default: formatted_rdata = {24'b0, selected_word[31:24]};
                endcase
            end

            LOAD_HALF_U: begin
                if (request_offset[1])
                    formatted_rdata = {16'b0, selected_word[31:16]};
                else
                    formatted_rdata = {16'b0, selected_word[15:0]};
            end

            default: formatted_rdata = selected_word;
        endcase

        updated_line = selected_line;

        for (b = 0; b < 4; b = b + 1) begin
            if (request_byte_en[b]) begin
                updated_line[(request_offset[3:2] * 32) + (b * 8) +: 8]
                    = request_wdata[(b * 8) +: 8];
            end
        end

        mem_req = 1'b0;
        mem_write = 1'b0;
        mem_addr = refill_addr;
        mem_wdata = selected_line;

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

        cpu_ready = (state == S_RESP);
        cpu_rdata = (state == S_RESP && !request_write) ? formatted_rdata : 32'b0;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;

            request_addr <= 32'b0;
            request_wdata <= 32'b0;
            request_byte_en <= 4'b0;
            request_load_type <= LOAD_WORD;
            request_write <= 1'b0;

            victim_line <= 128'b0;
            saved_victim_addr <= 32'b0;
            refill_data <= 128'b0;

            for (i = 0; i < NUM_LINES; i = i + 1) begin
                data_array[i] <= 128'b0;
                tag_array[i] <= '0;
                valid_array[i] <= 1'b0;
                dirty_array[i] <= 1'b0;
            end
        end else begin
            case (state)
                S_IDLE: begin
                    if (cpu_req) begin
                        request_addr <= cpu_addr;
                        request_wdata <= cpu_wdata;
                        request_byte_en <= cpu_byte_en;
                        request_load_type <= cpu_load_type;
                        request_write <= cpu_write;
                        state <= S_LOOKUP;
                    end
                end

                S_LOOKUP: begin
                    if (
                        valid_array[request_index] &&
                        tag_array[request_index] == request_tag
                    ) begin
                        state <= S_ACCESS;
                    end else if (
                        valid_array[request_index] &&
                        dirty_array[request_index]
                    ) begin
                        victim_line <= data_array[request_index];
                        saved_victim_addr <= victim_addr;
                        state <= S_WRITEBACK;
                    end else begin
                        state <= S_REFILL;
                    end
                end

                S_WRITEBACK: begin
                    if (mem_ready)
                        state <= S_WAIT_WRITEBACK;
                end

                S_WAIT_WRITEBACK: begin
                    if (!mem_ready) begin
                        dirty_array[request_index] <= 1'b0;
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
                        dirty_array[request_index] <= 1'b0;
                        state <= S_ACCESS;
                    end
                end

                S_ACCESS: begin
                    if (request_write) begin
                        data_array[request_index] <= updated_line;
                        dirty_array[request_index] <= 1'b1;
                    end

                    state <= S_RESP;
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

