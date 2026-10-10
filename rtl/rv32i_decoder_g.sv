module rv32i_decoder_g (
    input logic [31:0] instruction,

    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,

    //control signal

    output logic regwrite,
    output logic memread,
    output logic memwrite,
    output logic memtoreg,
    output logic alusrc,

    output logic branch,
    output logic [2:0] branch_type,

    output logic jal,
    output logic jalr,
    output logic lui,
    output logic auipc,
    
    output logic [3:0] alu_control,

    output logic uses_rs1,
    output logic uses_rs2

);

logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode = instruction[6:0];
assign rd = instruction[11:7];
assign funct3 = instruction[14:12];
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign funct7 = instruction[31:25];


//Opcode

localparam logic [6:0] OPCODE_RTYPE = 7'b0110011;
localparam logic [6:0] OPCODE_ITYPE = 7'b0010011;
localparam logic [6:0] OPCODE_LOAD = 7'b0000011;
localparam logic [6:0] OPCODE_STORE=7'b0100011;
localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
localparam logic [6:0] OPCODE_LUI = 7'b0110111;
localparam logic [6:0] OPCODE_AUIPC = 7'b0010111;
localparam logic [6:0] OPCODE_JAL = 7'b1101111;
localparam logic [6:0] OPCODE_JALR = 7'b1100111;

//alu control

localparam logic [3:0] ALU_ADD = 4'b0000;
localparam logic [3:0] ALU_SUB = 4'b0001;
localparam logic [3:0] ALU_SLL = 4'b0010;
localparam logic [3:0] ALU_SLT = 4'b0011;
localparam logic [3:0] ALU_SLTU = 4'b0100;
localparam logic [3:0] ALU_XOR = 4'b0101;
localparam logic [3:0] ALU_SRL = 4'b0110;
localparam logic [3:0] ALU_SRA = 4'b0111;
localparam logic [3:0] ALU_OR = 4'b1000;
localparam logic [3:0] ALU_AND = 4'b1001;


// branch type
localparam logic [2:0] BR_BEQ = 3'b000;
localparam logic [2:0] BR_BNE = 3'b001;
localparam logic [2:0] BR_BLT = 3'b100;
localparam logic [2:0] BR_BGE = 3'b101;
localparam logic [2:0] BR_BLTU = 3'b110;
localparam logic [2:0] BR_BGEU = 3'b111;

always_comb begin 

    regwrite =1'b0;
    memread =1'b0;
    memwrite = 1'b0;
    memtoreg = 1'b0;
    alusrc =1'b0;

    branch = 1'b0;
    branch_type = BR_BEQ;

    jal =1'b0;
    jalr =1'b0;
    lui = 1'b0;
    auipc = 1'b0;

    alu_control =ALU_ADD;

    uses_rs1 =1'b0;
    uses_rs2= 1'b0;


    case(opcode)

        OPCODE_RTYPE:
        begin
            regwrite =1'b1;

            uses_rs1 =1'b1;
            uses_rs2 =1'b1;
            case(funct3)

                3'b000: begin 
                    if(funct7==7'b0100000)
                        alu_control = ALU_SUB;
                    else 
                    alu_control = ALU_ADD;
                end

                3'b001:begin
                    alu_control =ALU_SLL;

                end

                3'b010:
                    alu_control= ALU_SLT;

                3'b011:
                    alu_control= ALU_SLTU;
                
                3'b100:
                    alu_control = ALU_XOR;

                3'b101:begin
                    if(funct7== 7'b0100000)
                        alu_control = ALU_SRA;
                    else
                    alu_control = ALU_SRL;
                end
                3'b110:
                    alu_control = ALU_OR;

                3'b111:
                    alu_control = ALU_AND;

            endcase

        end
        
        
        
        OPCODE_ITYPE: 
        begin
            regwrite = 1'b1;

            alusrc   = 1'b1;

            uses_rs1 = 1'b1;
            uses_rs2 = 1'b0;

            case (funct3)

                3'b000:
                    alu_control = ALU_ADD;

                3'b010:
                    alu_control = ALU_SLT;  

                3'b011:
                    alu_control = ALU_SLTU; 

                3'b100:
                    alu_control = ALU_XOR; 

                3'b110:
                    alu_control = ALU_OR;       
                3'b111:
                    alu_control = ALU_AND;      
                3'b001:
                    alu_control = ALU_SLL;      
                
                3'b101: begin

                    if (funct7 == 7'b0100000)
                    alu_control = ALU_SRA;  
                    else
                    alu_control = ALU_SRL;  

                    end

                default:
                    alu_control = ALU_ADD;

                endcase

            end


        OPCODE_LOAD: begin

                regwrite = 1'b1;

                memread  = 1'b1;

                memtoreg = 1'b1;

                alusrc   = 1'b1;

                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;

                alu_control = ALU_ADD;

            end


           
        OPCODE_STORE: 
        begin

            memwrite = 1'b1;

            alusrc   = 1'b1;

            uses_rs1 = 1'b1;
            uses_rs2 = 1'b1;

            alu_control = ALU_ADD;

            end


           

        OPCODE_BRANCH: 
        begin

            branch = 1'b1;

            uses_rs1 = 1'b1;
            uses_rs2 = 1'b1;

            branch_type = funct3;

            alu_control = ALU_SUB;

        end


        
        OPCODE_LUI: 
        begin

            regwrite = 1'b1;

            alusrc = 1'b1;

            lui = 1'b1;

            uses_rs1 = 1'b0;
            uses_rs2 = 1'b0;

            alu_control = ALU_ADD;

        end


         
        OPCODE_AUIPC: 
            begin

                regwrite = 1'b1;

                alusrc = 1'b1;

                auipc = 1'b1;

                uses_rs1 = 1'b0;
                uses_rs2 = 1'b0;

                alu_control = ALU_ADD;

            end


            
         OPCODE_JAL:
            begin

                regwrite = 1'b1;

                jal = 1'b1;

                uses_rs1 = 1'b0;
                uses_rs2 = 1'b0;

            end


            
            OPCODE_JALR: 
            begin

                regwrite = 1'b1;

                jalr = 1'b1;

                alusrc = 1'b1;

                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;

                alu_control = ALU_ADD;
            end


            
            default: 
            begin
            end





    endcase

end




endmodule
