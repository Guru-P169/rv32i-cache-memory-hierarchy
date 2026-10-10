module rv32i_forwarding_unit_g (
    input logic [4:0] ex_rs1,
    input logic [4:0] ex_rs2,

    input logic [4:0] mem_rd,
    input logic mem_regwrite,

    input logic [4:0] wb_rd,
    input logic wb_regwrite,

    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    // 00 - ID/EX register value
    // 10 - forward  EX/MEM
    // 01 - forward  MEM/WB
   
    always_comb begin

       
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (mem_regwrite &&(mem_rd != 5'd0) &&(mem_rd == ex_rs1)) 
        begin
            forward_a = 2'b10;
        end

        
        else if (wb_regwrite &&(wb_rd != 5'd0) &&(wb_rd == ex_rs1)) 
        begin
            forward_a = 2'b01;
        end

        


        if (mem_regwrite &&(mem_rd != 5'd0) &&(mem_rd == ex_rs2)) 
        begin
            forward_b = 2'b10;
        end

        
        else if (wb_regwrite &&(wb_rd != 5'd0) &&(wb_rd == ex_rs2)) 
        begin

            forward_b = 2'b01;
        end

    end

endmodule