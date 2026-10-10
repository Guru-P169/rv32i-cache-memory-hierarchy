module rv32i_instruction_memory_g #(
    parameter int IMEM_DEPTH = 256  
) (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    logic [31:0] memory [0:IMEM_DEPTH-1];

    initial begin
        $readmemh("instruction_memory.hex", memory);
    end   
  
 
    always_comb begin

        if (address[31:2] < IMEM_DEPTH)
            instruction = memory[address[31:2]];
        else
            instruction = 32'h0000_0013;

    end

endmodule