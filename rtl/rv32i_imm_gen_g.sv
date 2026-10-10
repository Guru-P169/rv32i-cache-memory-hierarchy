module rv32i_imm_gen_g (

    input  logic [31:0] instruction,

    output logic [31:0] immediate

);


    localparam logic [6:0] OPCODE_ITYPE = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD = 7'b0000011;
    localparam logic [6:0] OPCODE_JALR = 7'b1100111;

    localparam logic [6:0] OPCODE_STORE = 7'b0100011;

    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;

    localparam logic [6:0] OPCODE_LUI = 7'b0110111;
    localparam logic [6:0] OPCODE_AUIPC = 7'b0010111;

    localparam logic [6:0] OPCODE_JAL = 7'b1101111;

  always_comb begin

    immediate = 32'b0;

        case (instruction[6:0])

           
            OPCODE_ITYPE: 
            begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };

            end


            OPCODE_LOAD: 
            begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };

            end


            OPCODE_JALR: 
            begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };

            end



            OPCODE_STORE: 
            begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:25],
                    instruction[11:7]
                };

            end


            OPCODE_BRANCH: 
            begin
                immediate = {
                    {19{instruction[31]}},
                    instruction[31],
                    instruction[7],
                    instruction[30:25],
                    instruction[11:8],
                    1'b0
                };

            end

            OPCODE_LUI: 
            begin
                immediate = {
                    instruction[31:12],
                    12'b0
                };

            end


            OPCODE_AUIPC: 
            begin
                immediate = {
                    instruction[31:12],
                    12'b0
                };

            end


            OPCODE_JAL: 
            begin
                immediate = {
                    {11{instruction[31]}},
                    instruction[31],
                    instruction[19:12],
                    instruction[20],
                    instruction[30:21],
                    1'b0
                };

            end
            
            default: 
            begin

                immediate = 32'b0;

            end

        endcase

    end

endmodule