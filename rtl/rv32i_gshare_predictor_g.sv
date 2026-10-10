module rv32i_gshare_predictor_g #(
    parameter int HISTORY_BITS = 4
) (
    input logic clk,
    input logic reset,

    input logic [31:0] predict_pc,
    output logic predict_taken,
    output logic [HISTORY_BITS-1:0] predict_index,

    input logic update_valid,
    input logic [HISTORY_BITS-1:0] update_index,
    input logic update_taken

    
);

    localparam int PHT_ENTRIES = (1 << HISTORY_BITS);

    logic [HISTORY_BITS-1:0] global_history;

    logic [1:0] pht [0:PHT_ENTRIES-1];



    integer i;

    always_comb begin

        predict_index =
            predict_pc[HISTORY_BITS+1:2] ^ global_history;

        if (pht[predict_index][1])
            predict_taken = 1'b1;
        else
            predict_taken = 1'b0;

    end



    always_ff @(posedge clk) begin

        if (reset) begin

            global_history <= '0;

            for (i = 0; i < PHT_ENTRIES; i = i + 1)
                pht[i] <= 2'b01;

        end

       else if (update_valid) begin

    if (update_taken) begin
        if (pht[update_index] != 2'b11)
            pht[update_index] <= pht[update_index] + 2'b01;
    end
    else begin
        if (pht[update_index] != 2'b00)
            pht[update_index] <= pht[update_index] - 2'b01;
    end

    global_history <=
        {global_history[HISTORY_BITS-2:0], update_taken};

    end

    end

endmodule
