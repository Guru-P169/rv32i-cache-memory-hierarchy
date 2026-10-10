module rv32i_ex_mem_g (
    input logic clk,
    input logic reset,
    input logic flush,

    input logic [31:0] ex_alu_result,
    input logic [31:0] ex_store_data,
    input logic [31:0] ex_pc_plus4,

    input logic [4:0]  ex_rd,

   
    input logic ex_regwrite,
    input logic ex_memread,
    input logic ex_memwrite,
    input logic ex_memtoreg,

    input logic ex_jal,
    input logic ex_jalr,
 
    output logic [31:0] mem_alu_result,
    output logic [31:0] mem_store_data,
    output logic [31:0] mem_pc_plus4,

    output logic [4:0] mem_rd,

 
    output logic mem_regwrite,
    output logic mem_memread,
    output logic mem_memwrite,
    output logic mem_memtoreg,

    output logic mem_jal,
    output logic mem_jalr
);

    always_ff @(posedge clk) begin

        if (reset) 
        begin

            mem_alu_result <= 32'b0;
            mem_store_data <= 32'b0;
            mem_pc_plus4 <= 32'b0;

            mem_rd <= 5'b0;

            mem_regwrite<= 1'b0;
            mem_memread<= 1'b0;
            mem_memwrite<= 1'b0;
            mem_memtoreg<= 1'b0;

            mem_jal<= 1'b0;
            mem_jalr<= 1'b0;

        end

        else if (flush) begin

            mem_alu_result <= 32'b0;
            mem_store_data <= 32'b0;
            mem_pc_plus4 <= 32'b0;

            mem_rd <= 5'b0;

            mem_regwrite <= 1'b0;
            mem_memread <= 1'b0;
            mem_memwrite <= 1'b0;
            mem_memtoreg <= 1'b0;

            mem_jal <= 1'b0;
            mem_jalr <= 1'b0;

        end

        else begin


            mem_alu_result <= ex_alu_result;
            mem_store_data <= ex_store_data;
            mem_pc_plus4 <= ex_pc_plus4;

            mem_rd <= ex_rd;

            mem_regwrite <= ex_regwrite;
            mem_memread <= ex_memread;
            mem_memwrite <= ex_memwrite;
            mem_memtoreg <= ex_memtoreg;

            mem_jal <= ex_jal;
            mem_jalr <= ex_jalr;

        end

    end

endmodule