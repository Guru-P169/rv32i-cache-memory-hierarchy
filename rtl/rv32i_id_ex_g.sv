module rv32i_id_ex_g (

    input logic clk,
    input logic reset,

    input logic flush,
    input logic insert_bubble,

    input logic [31:0] id_pc,
    input logic [31:0] id_pc_plus4,

    input logic [31:0] id_rs1_value,
    input logic [31:0] id_rs2_value,

    input logic [31:0] id_imm,

    input logic [4:0] id_rs1,
    input logic [4:0] id_rs2,
    input logic [4:0] id_rd,

    
    input logic id_regwrite,
    input logic id_memread,
    input logic id_memwrite,
    input logic id_memtoreg,
    input logic id_alusrc,

    input logic id_branch,
    input logic [2:0] id_branch_type,

    input logic id_jal,
    input logic id_jalr,
    input logic id_lui,
    input logic id_auipc,

    input logic [3:0] id_alu_control,

    input logic id_uses_rs1,
    input logic id_uses_rs2,

    input logic id_predicted_taken,
    input logic [31:0] id_predicted_target,

    input logic [3:0] id_gshare_predict_index,
    output logic [3:0] ex_gshare_predict_index,

    output logic [31:0] ex_pc,
    output logic [31:0] ex_pc_plus4,

    output logic [31:0] ex_rs1_value,
    output logic [31:0] ex_rs2_value,

    output logic [31:0] ex_imm,

    output logic [4:0] ex_rs1,
    output logic [4:0] ex_rs2,
    output logic [4:0] ex_rd,

    
    output logic ex_regwrite,
    output logic ex_memread,
    output logic ex_memwrite,
    output logic ex_memtoreg,
    output logic ex_alusrc,

    output logic ex_branch,
    output logic [2:0] ex_branch_type,

    output logic ex_jal,
    output logic ex_jalr,
    output logic ex_lui,
    output logic ex_auipc,

    output logic [3:0] ex_alu_control,

    output logic ex_uses_rs1,
    output logic ex_uses_rs2,

    output logic        ex_predicted_taken,
    output logic [31:0] ex_predicted_target

);



    always_ff @(posedge clk) begin

        if (reset)
        begin

            ex_pc <= 32'b0;
            ex_pc_plus4 <= 32'b0;

            ex_rs1_value <= 32'b0;
            ex_rs2_value <= 32'b0;

            ex_imm <= 32'b0;

            ex_rs1 <= 5'b0;
            ex_rs2 <= 5'b0;
            ex_rd <= 5'b0;

            ex_regwrite <= 1'b0;
            ex_memread <= 1'b0;
            ex_memwrite <= 1'b0;
            ex_memtoreg <= 1'b0;
            ex_alusrc <= 1'b0;

            ex_branch <= 1'b0;
            ex_branch_type <= 3'b000;

            ex_jal <= 1'b0;
            ex_jalr <= 1'b0;

            ex_lui   <= 1'b0;
            ex_auipc <= 1'b0;
            ex_alu_control <= 4'b0000;

            ex_uses_rs1 <= 1'b0;
            ex_uses_rs2 <= 1'b0;

            ex_predicted_taken  <= 1'b0;
            ex_predicted_target <= 32'b0;
            ex_gshare_predict_index <= 4'b0;
        end

      
        else if (flush || insert_bubble) begin

            ex_pc<= 32'b0;
            ex_pc_plus4 <= 32'b0;

            ex_rs1_value <= 32'b0;
            ex_rs2_value <= 32'b0;

            ex_imm <= 32'b0;

            ex_rs1 <= 5'b0;
            ex_rs2 <= 5'b0;
            ex_rd <= 5'b0;

            ex_regwrite <= 1'b0;
            ex_memread <= 1'b0;
            ex_memwrite <= 1'b0;
            ex_memtoreg <= 1'b0;
            ex_alusrc <= 1'b0;

            ex_branch <= 1'b0;
            ex_branch_type <= 3'b000;

            ex_jal <= 1'b0;
            ex_jalr <= 1'b0;
            ex_lui   <= 1'b0;
            ex_auipc <= 1'b0;
            
            ex_alu_control <= 4'b0000;

            ex_uses_rs1 <= 1'b0;
            ex_uses_rs2 <= 1'b0;

            ex_predicted_taken  <= 1'b0;
            ex_predicted_target <= 32'b0;
            ex_gshare_predict_index <= 4'b0;

        end

        else begin

            ex_pc <= id_pc;
            ex_pc_plus4 <= id_pc_plus4;

            ex_rs1_value <= id_rs1_value;
            ex_rs2_value <= id_rs2_value;

            ex_imm <= id_imm;

            ex_rs1 <= id_rs1;
            ex_rs2 <= id_rs2;
            ex_rd <= id_rd;

            ex_regwrite <= id_regwrite;
            ex_memread <= id_memread;
            ex_memwrite <= id_memwrite;
            ex_memtoreg <= id_memtoreg;
            ex_alusrc <= id_alusrc;

            ex_branch <= id_branch;
            ex_branch_type <= id_branch_type;

            ex_jal <= id_jal;
            ex_jalr <= id_jalr;
            ex_lui   <= id_lui;
            ex_auipc <= id_auipc;
            
            ex_alu_control <= id_alu_control;

            ex_uses_rs1 <= id_uses_rs1;
            ex_uses_rs2 <= id_uses_rs2;

            ex_predicted_taken  <= id_predicted_taken;
            ex_predicted_target <= id_predicted_target;

            ex_gshare_predict_index <= id_gshare_predict_index;

        end

    end

    
endmodule