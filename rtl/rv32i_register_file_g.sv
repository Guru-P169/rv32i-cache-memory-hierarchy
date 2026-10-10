module rv32i_register_file_g (

    input logic clk,
    input logic reset,

    input logic [4:0] rs1,
    output logic [31:0] read_data1,

   
    input logic [4:0] rs2,
    output logic [31:0] read_data2,

 
    input logic write_enable,
    input logic [4:0]  write_rd,
    input logic [31:0] write_data

);


    logic [31:0] registers [0:31];


    always_ff @(posedge clk) begin

        if (reset) begin

            for (int i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end

        end

        else begin

           
            if (write_enable && (write_rd != 5'd0)) 
            begin
                registers[write_rd] <= write_data;
            end

        end

    end

    always_comb begin

        if (rs1 == 5'd0)
            read_data1 = 32'b0;
        else
            read_data1 = registers[rs1];

    end
    always_comb begin

        if (rs2 == 5'd0)
            read_data2 = 32'b0;
        else
            read_data2 = registers[rs2];

    end


endmodule