module rv32i_btb_g #(
    parameter int BTB_ENTRIES = 16
) (
    input  logic clk,
    input  logic reset,

    input  logic [31:0] predict_pc,
    output logic btb_hit,
    output logic [31:0] predict_target,
    output logic btb_is_branch,
    output logic btb_is_jump,

    input logic update_valid,
    input logic [31:0] update_pc,
    input logic [31:0] update_target,
    input logic update_is_branch
);

    localparam int INDEX_BITS = $clog2(BTB_ENTRIES);
    localparam int TAG_BITS = 32 - INDEX_BITS - 2;

    logic branch_array [0:BTB_ENTRIES-1];

    logic [TAG_BITS-1:0] tag_array [0:BTB_ENTRIES-1];
    logic [31:0] target_array [0:BTB_ENTRIES-1];
    logic valid_array [0:BTB_ENTRIES-1];

    logic [INDEX_BITS-1:0] predict_index;
    logic [INDEX_BITS-1:0] update_index;

    logic [TAG_BITS-1:0] predict_tag;
    logic [TAG_BITS-1:0] update_tag;

    integer i;

    always_comb begin

        predict_index = predict_pc[INDEX_BITS+1:2];
        predict_tag = predict_pc[31:INDEX_BITS+2];

        btb_hit = 1'b0;
        predict_target = 32'b0;
        btb_is_branch  = 1'b0;
        btb_is_jump = 1'b0;

        if (valid_array[predict_index] &&
            tag_array[predict_index] == predict_tag) begin

            btb_hit = 1'b1;
            predict_target = target_array[predict_index];

            if (branch_array[predict_index]) begin
                btb_is_branch = 1'b1;
                btb_is_jump = 1'b0;
            end
            else begin
                btb_is_branch = 1'b0;
                btb_is_jump = 1'b1;
            end

        end

    end

    always_comb begin

        update_index = update_pc[INDEX_BITS+1:2];
        update_tag   = update_pc[31:INDEX_BITS+2];

    end

    always_ff @(posedge clk) begin

        if (reset) begin

            for (i = 0; i < BTB_ENTRIES; i = i + 1) begin

                valid_array[i]  <= 1'b0;
                tag_array[i]    <= '0;
                target_array[i] <= 32'b0;
                branch_array[i] <= 1'b0;

            end

        end

        else if (update_valid) begin

            valid_array[update_index]  <= 1'b1;
            tag_array[update_index]    <= update_tag;
            target_array[update_index] <= update_target;
            branch_array[update_index] <= update_is_branch;

        end

    end

endmodule