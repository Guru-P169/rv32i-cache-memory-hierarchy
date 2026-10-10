module rv32i_mem_wb_g (
    input logic clk,
    input logic reset,
    input logic flush,
 
    input logic [31:0] mem_alu_result,
    input logic [31:0] mem_read_data,
    input logic [31:0] mem_pc_plus4,

    input logic [4:0] mem_rd,

    input logic mem_regwrite,
    input logic mem_memtoreg,

    input logic mem_jal,
    input logic mem_jalr,

   
    output logic [31:0] wb_alu_result,
    output logic [31:0] wb_read_data,
    output logic [31:0] wb_pc_plus4,

    output logic [4:0] wb_rd,

    output logic wb_regwrite,
    output logic wb_memtoreg,

    output logic wb_jal,
    output logic wb_jalr
);

    always_ff @(posedge clk) begin

        if (reset) 
        begin

            wb_alu_result <= 32'b0;
            wb_read_data <= 32'b0;
            wb_pc_plus4 <= 32'b0;

            wb_rd <= 5'b0;

            wb_regwrite <= 1'b0;
            wb_memtoreg <= 1'b0;

            wb_jal <= 1'b0;
            wb_jalr <= 1'b0;
        end


        else if (flush) begin

            wb_alu_result <= 32'b0;
            wb_read_data <= 32'b0;
            wb_pc_plus4 <= 32'b0;

            wb_rd <= 5'b0;

            wb_regwrite <= 1'b0;
            wb_memtoreg <= 1'b0;

            wb_jal <= 1'b0;
            wb_jalr <= 1'b0;
        end

        else begin

            wb_alu_result <= mem_alu_result;
            wb_read_data <= mem_read_data;
            wb_pc_plus4 <= mem_pc_plus4;

            wb_rd <= mem_rd;

            wb_regwrite <= mem_regwrite;
            wb_memtoreg <= mem_memtoreg;

            wb_jal <= mem_jal;
            wb_jalr <= mem_jalr;
        end
    end

endmodule