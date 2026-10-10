module rv32i_if_id_g(
    input logic clk,
    input logic reset,

    input logic flush,
    input logic if_id_write,

    input logic [31:0] if_pc,
    input logic [31:0] if_pc_plus4,
    input logic [31:0] if_instruction,

    input logic [3:0] if_gshare_predict_index,
    output logic [3:0] id_gshare_predict_index,

    output logic [31:0] id_pc,
    output logic [31:0] id_pc_plus4,
    output logic [31:0] id_instruction,


    input logic if_predicted_taken,
    input  logic [31:0] if_predicted_target,

    output logic id_predicted_taken,
    output logic [31:0] id_predicted_target

);

localparam logic [31:0] NOP = 32'h0000_0013;

always_ff @(posedge clk ) 
begin
    
    if(reset)
    begin
        id_pc <= 32'b0;
        id_pc_plus4 <= 32'b0;
        id_instruction <= NOP;
        id_predicted_taken <= 1'b0;
        id_predicted_target <= 32'b0;
        id_gshare_predict_index <= 4'b0;

    end

    else if(flush)
    begin
        id_pc <= 32'b0;
        id_pc_plus4 <= 32'b0;
        id_instruction <= NOP;
        id_predicted_taken <= 1'b0;
        id_predicted_target <= 32'b0;
        id_gshare_predict_index <= 4'b0;
    end

    else if(if_id_write)
    begin
        id_pc <= if_pc;
        id_pc_plus4 <= if_pc_plus4;
        id_instruction <= if_instruction;
        id_predicted_taken  <= if_predicted_taken;
        id_predicted_target <= if_predicted_target;
        id_gshare_predict_index <= if_gshare_predict_index;

    end


end

endmodule
