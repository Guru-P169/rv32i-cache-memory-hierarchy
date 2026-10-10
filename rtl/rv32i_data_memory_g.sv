module rv32i_data_memory_g #(
    parameter int DMEM_DEPTH = 256
) (
    input logic clk,
    input logic reset,

    input  logic [31:0] address,
    input  logic [31:0] write_data,

    input  logic memread,
    input  logic memwrite,

    output logic [31:0] read_data
);

     
    logic [31:0] memory [0:DMEM_DEPTH-1];

    integer i;

    always_ff @(posedge clk) begin

        if (reset) begin

            for (i = 0; i < DMEM_DEPTH; i = i + 1)
                memory[i] <= 32'b0;

        end

        else begin

            if (memwrite) 
            begin

                if (address[31:2] < DMEM_DEPTH)
                    memory[address[31:2]] <= write_data;

            end

        end

    end


    always_comb begin

        if (memread) begin

            if (address[31:2] < DMEM_DEPTH)
                read_data = memory[address[31:2]];
            else
                read_data = 32'b0;

        end

        else begin
            read_data = 32'b0;
        end

    end

endmodule