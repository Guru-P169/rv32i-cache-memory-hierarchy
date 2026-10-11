`timescale 1ns/1ps

module rv32i_lru_g #(
    parameter NUM_SETS = 256,
    parameter NUM_WAYS = 4,
    parameter INDEX_BITS = 8,
    parameter WAY_BITS = 2
)(
    input wire clk,
    input wire rst,

     input wire access_valid,
    input wire [INDEX_BITS-1:0] access_set,
    input wire [WAY_BITS-1:0] access_way,

    input wire [INDEX_BITS-1:0] victim_set,
    output reg [WAY_BITS-1:0] victim_way
);

    
    reg [WAY_BITS-1:0]
        recency_order [0:NUM_SETS-1][0:NUM_WAYS-1];

    reg [WAY_BITS-1:0]
        recency_next [0:NUM_WAYS-1];

    integer s;
    integer w;
    integer k;
    integer access_position;
    reg access_way_found;

   
    always @(*) begin
        victim_way = recency_order[victim_set][NUM_WAYS-1];
    end

   
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (s = 0; s < NUM_SETS; s = s + 1) begin
                for (w = 0; w < NUM_WAYS; w = w + 1) begin
                    recency_order[s][w] <= w;
                end
            end
        end else if (
            access_valid &&
            (access_set < NUM_SETS) &&
            (access_way < NUM_WAYS)
        ) begin

            access_position = 0;
            access_way_found = 1'b0;

            
            for (k = 0; k < NUM_WAYS; k = k + 1) begin
                if (
                    !access_way_found &&
                    recency_order[access_set][k] == access_way
                ) begin
                    access_position = k;
                    access_way_found = 1'b1;
                end
            end

            for (k = 0; k < NUM_WAYS; k = k + 1) begin
                recency_next[k] <= recency_order[access_set][k];
            end

            if (access_way_found) begin
                for (k = NUM_WAYS-1; k > 0; k = k - 1) begin
                    if (k <= access_position) begin
                        recency_order[access_set][k] <=
                            recency_order[access_set][k-1];
                    end
                end

                recency_order[access_set][0] <= access_way;
            end
        end
    end

endmodule