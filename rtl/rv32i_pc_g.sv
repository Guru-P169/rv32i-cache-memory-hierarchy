module rv32i_pc_g (
    input  logic clk,
    input  logic reset,
    input  logic pc_write,
    input  logic [31:0] next_pc,

    output logic [31:0] pc
);

    always_ff @(posedge clk) begin

        if (reset) begin
            pc <= 32'b0;
        end

        else if (pc_write) begin
            pc <= next_pc;
        end
    end

endmodule