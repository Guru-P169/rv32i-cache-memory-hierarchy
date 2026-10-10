module rv32i_hazard_unit_g (

    input logic idex_memread,
    input logic [4:0] idex_rd,

    input logic [4:0] ifid_rs1,
    input logic [4:0] ifid_rs2,

    input logic ifid_uses_rs1,
    input logic ifid_uses_rs2,


    output logic pc_write,
    output logic if_id_write,
    output logic insert_bubble
);

    logic load_use_hazard;

    always_comb begin

        load_use_hazard = 1'b0;

        if (idex_memread &&
            (idex_rd != 5'd0) &&
            (
                (ifid_uses_rs1 && (idex_rd == ifid_rs1)) ||(ifid_uses_rs2 && (idex_rd == ifid_rs2))
            )) begin

            load_use_hazard = 1'b1;
        end
    end


    always_comb begin

        if (load_use_hazard) begin

            
            pc_write = 1'b0;

            
            if_id_write = 1'b0;

            
            insert_bubble = 1'b1;

        end
        else begin

           
            pc_write = 1'b1;

            if_id_write = 1'b1;

            insert_bubble = 1'b0;
        end
    end

endmodule