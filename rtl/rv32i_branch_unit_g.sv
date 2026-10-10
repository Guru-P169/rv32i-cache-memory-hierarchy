module rv32i_branch_unit_g (

    input logic branch,
    input logic [2:0] branch_type,

    input logic [31:0] rs1_value,
    input logic [31:0] rs2_value,

    input logic [31:0] pc,
    input logic [31:0] immediate,

    output logic branch_taken,
    output logic [31:0] branch_target
);

    always_comb 
    begin
        branch_target = pc + immediate;
    end

    always_comb begin

        branch_taken = 1'b0;

        if (branch) begin

            case (branch_type)

                
                3'b000:
                    branch_taken = (rs1_value == rs2_value);

                
                3'b001:
                    branch_taken = (rs1_value != rs2_value);

             
                3'b100:
                    branch_taken = ($signed(rs1_value) <$signed(rs2_value));

                
                3'b101:
                    branch_taken = ($signed(rs1_value) >= $signed(rs2_value));

             
                3'b110:
                    branch_taken = (rs1_value < rs2_value);

           
                3'b111:
                    branch_taken = (rs1_value >= rs2_value);

                default:
                    branch_taken = 1'b0;

            endcase
        end
    end

endmodule