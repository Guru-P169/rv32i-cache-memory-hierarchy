module rv32i_core_g (
    input logic clk,
    input logic reset
);

  
    logic [31:0] pc;
    logic [31:0] next_pc;
    logic [31:0] pc_plus4;
    logic pc_write;

    assign pc_plus4 = pc + 32'd4;


   
    logic [31:0] instruction;

    rv32i_instruction_memory_g imem (
        .address (pc),
        .instruction(instruction)
    );


    // IF / ID  register
    
    logic [31:0] id_pc;
    logic [31:0] id_pc_plus4;
    logic [31:0] id_instruction;

    
    

    logic if_predicted_taken;
    logic [31:0] if_predicted_target;

    logic id_predicted_taken;
    logic [31:0] id_predicted_target;

    logic gshare_predict_taken;
    logic btb_hit;
    logic [31:0] btb_predict_target;

    logic btb_is_branch;
    logic btb_is_jump;

    logic [3:0] gshare_predict_index;

    logic [3:0] id_gshare_predict_index;

    logic [31:0] predicted_next_pc;

    logic if_id_write;
    logic flush_if_id;


    // ID  — decoder

    logic [4:0] id_rs1;
    logic [4:0] id_rs2;
    logic [4:0] id_rd;

    logic id_regwrite;
    logic id_memread;
    logic id_memwrite;
    logic id_memtoreg;
    logic id_alusrc;

    logic id_branch;
    logic [2:0] id_branch_type;

    logic id_jal;
    logic id_jalr;
    logic id_lui;
    logic id_auipc;
    logic [3:0] id_alu_control;

    logic id_uses_rs1;
    logic id_uses_rs2;


    // register file
    
 // register file

logic [31:0] id_rs1_value;
logic [31:0] id_rs2_value;

logic [31:0] regfile_read_data1;
logic [31:0] regfile_read_data2;

logic [31:0] wb_writeback_data;
    // Immediate
   
    logic [31:0] id_imm;


    // ID / EX  register
   
    logic [31:0] ex_pc;
    logic [31:0] ex_pc_plus4;

    logic [31:0] ex_rs1_value;
    logic [31:0] ex_rs2_value;
    logic [31:0] ex_imm;

    logic [4:0] ex_rs1;
    logic [4:0] ex_rs2;
    logic [4:0] ex_rd;

    logic ex_predicted_taken;
    logic [31:0] ex_predicted_target;

    logic [3:0] ex_gshare_predict_index;

    logic ex_regwrite;
    logic ex_memread;
    logic ex_memwrite;
    logic ex_memtoreg;
    logic ex_alusrc;

    logic ex_branch;
    logic [2:0] ex_branch_type;

    logic ex_jal;
    logic ex_jalr;
    logic ex_lui; 
    logic ex_auipc;

    logic [3:0] ex_alu_control;

    logic ex_uses_rs1;
    logic ex_uses_rs2;

    logic insert_bubble;

    logic hazard_pc_write;
    logic hazard_if_id_write;

    logic flush_id_ex;


    // EX  — forwarding 
 
    logic [1:0] forward_a;
    logic [1:0] forward_b;

    logic [31:0] forwarded_rs1;
    logic [31:0] forwarded_rs2;


    // EX  — ALU
 
    logic [31:0] alu_input_a;
    logic [31:0] alu_input_b;
    logic [31:0] alu_result;


       // EX  — branch

    logic branch_taken;
    logic [31:0] branch_target;

    logic actual_taken;
    logic [31:0] actual_target;

    logic branch_misprediction;
    logic [31:0] redirect_pc;

    // EX   — JAL / JALR
  
    logic [31:0] jal_target;
    logic [31:0] jalr_target;

   


    // EX / MEM   register
    logic [31:0] mem_forward_data;

    logic [31:0] mem_alu_result;
    logic [31:0] mem_store_data;
    logic [31:0] mem_pc_plus4;

    logic [4:0] mem_rd;

    logic mem_regwrite;
    logic mem_memread;
    logic mem_memwrite;
    logic mem_memtoreg;



    logic mem_jal;
    logic mem_jalr;


    logic dcache_req;
    logic [31:0] dcache_addr;
    logic dcache_write;
    logic [31:0] dcache_wdata;
    logic [3:0]  dcache_byte_en;
    logic [2:0]  dcache_load_type;

    logic [31:0] dcache_rdata;  
    logic dcache_ready;


    logic dcache_mem_req;
    logic dcache_mem_write;
    logic [31:0] dcache_mem_addr;
    logic [127:0] dcache_mem_wdata;
    logic [127:0] dcache_mem_rdata;
    logic dcache_mem_ready;
    // training the branch predictor and BTB

    logic predictor_update_valid;
    logic predictor_update_taken;

    logic btb_update_valid;
    logic [31:0] btb_update_pc;
    logic [31:0] btb_update_target;
    logic btb_update_is_branch;


    // DATA MEMORY
    
    logic [31:0] mem_read_data;


    // MEM / WB   register
 
    logic [31:0] wb_alu_result;
    logic [31:0] wb_read_data;
    logic [31:0] wb_pc_plus4;

    logic [4:0] wb_rd;

    logic wb_regwrite;
    logic wb_memtoreg;

    logic wb_jal;
    logic wb_jalr;


    

    // PC
     
    rv32i_pc_g pc_unit (
        .clk (clk),
        .reset (reset),
        .pc_write(pc_write),
        .next_pc (next_pc),
        .pc (pc)
    );


    // decoder
   
    rv32i_decoder_g decoder (
        .instruction(id_instruction),

        .rs1 (id_rs1),
        .rs2 (id_rs2),
        .rd (id_rd),

        .regwrite (id_regwrite),
        .memread (id_memread),
        .memwrite (id_memwrite),
        .memtoreg (id_memtoreg),
        .alusrc (id_alusrc),

        .branch (id_branch),
        .branch_type (id_branch_type),

        .jal (id_jal),
        .jalr (id_jalr),
        .lui (id_lui),
        .auipc (id_auipc),

        .alu_control (id_alu_control),
        .uses_rs1 (id_uses_rs1),
        .uses_rs2 (id_uses_rs2)
    );


    // REGISTER FILE
 rv32i_register_file_g regfile (
    .clk (clk),
    .reset (reset),

    .rs1 (id_rs1),
    .read_data1 (regfile_read_data1),

    .rs2 (id_rs2),
    .read_data2 (regfile_read_data2),

    .write_enable (wb_regwrite),
    .write_rd (wb_rd),
    .write_data (wb_writeback_data)
);

   always_comb begin

    if (wb_regwrite &&
        (wb_rd != 5'd0) &&
        (wb_rd == id_rs1))
        id_rs1_value = wb_writeback_data;
    else
        id_rs1_value = regfile_read_data1;

    if (wb_regwrite &&
        (wb_rd != 5'd0) &&
        (wb_rd == id_rs2))
        id_rs2_value = wb_writeback_data;
    else
        id_rs2_value = regfile_read_data2;

end

    // immediate generator
  
    rv32i_imm_gen_g imm_gen (
        .instruction(id_instruction),
        .immediate (id_imm)
    );


    // IF / ID
       rv32i_if_id_g if_id (
        .clk (clk),
        .reset (reset),

        .flush (flush_if_id),
        .if_id_write (if_id_write),

        .if_pc (pc),
        .if_pc_plus4 (pc_plus4),
        .if_instruction(instruction),

        .id_pc (id_pc),
        .id_pc_plus4 (id_pc_plus4),
        .id_instruction(id_instruction),
        .if_predicted_taken(if_predicted_taken),
        .if_predicted_target(if_predicted_target),

        .if_gshare_predict_index(gshare_predict_index),
        .id_gshare_predict_index(id_gshare_predict_index),

        .id_predicted_taken(id_predicted_taken),
        .id_predicted_target(id_predicted_target)
    );


    // ID / EX
  
    rv32i_id_ex_g id_ex (
        .clk (clk),
        .reset (reset),

        .flush (flush_id_ex),
        .insert_bubble(insert_bubble),

        .id_pc (id_pc),
        .id_pc_plus4 (id_pc_plus4),

        .id_rs1_value (id_rs1_value),
        .id_rs2_value (id_rs2_value),

        .id_imm (id_imm),

        .id_rs1 (id_rs1),
        .id_rs2 (id_rs2),
        .id_rd (id_rd),

        .id_regwrite (id_regwrite),
        .id_memread (id_memread),
        .id_memwrite (id_memwrite),
        .id_memtoreg (id_memtoreg),
        .id_alusrc (id_alusrc),

        .id_branch (id_branch),
        .id_branch_type(id_branch_type),

        .id_jal (id_jal),
        .id_jalr (id_jalr),
        .id_lui (id_lui),
        .id_auipc (id_auipc),
        
        .id_alu_control(id_alu_control),

        .id_uses_rs1(id_uses_rs1),
        .id_uses_rs2 (id_uses_rs2),

        .id_predicted_taken(id_predicted_taken),
        .id_predicted_target(id_predicted_target),
        .id_gshare_predict_index(id_gshare_predict_index),
        .ex_pc (ex_pc),
        .ex_pc_plus4 (ex_pc_plus4),

        .ex_rs1_value (ex_rs1_value),
        .ex_rs2_value (ex_rs2_value),

        .ex_imm (ex_imm),

        .ex_rs1 (ex_rs1),
        .ex_rs2 (ex_rs2),
        .ex_rd (ex_rd),

        .ex_regwrite (ex_regwrite),
        .ex_memread (ex_memread),
        .ex_memwrite (ex_memwrite),
        .ex_memtoreg (ex_memtoreg),
        .ex_alusrc (ex_alusrc),

        .ex_branch (ex_branch),
        .ex_branch_type(ex_branch_type),

        .ex_jal (ex_jal),
        .ex_jalr (ex_jalr),
        .ex_lui   (ex_lui),
        .ex_auipc (ex_auipc),

        .ex_alu_control(ex_alu_control),

        .ex_uses_rs1  (ex_uses_rs1),
        .ex_uses_rs2  (ex_uses_rs2),

        .ex_gshare_predict_index(ex_gshare_predict_index),
        
        .ex_predicted_taken(ex_predicted_taken),
        .ex_predicted_target(ex_predicted_target)
    );


    // forwarding 
   
    rv32i_forwarding_unit_g forwarding (
        .ex_rs1 (ex_rs1),
        .ex_rs2 (ex_rs2),

        .mem_rd (mem_rd),
        .mem_regwrite(mem_regwrite),

        .wb_rd (wb_rd),
        .wb_regwrite (wb_regwrite),

        .forward_a (forward_a),
        .forward_b (forward_b)
    );

       // EX/MEM FORWARDING DATA

    always_comb begin

    if (mem_jal || mem_jalr)
        mem_forward_data = mem_pc_plus4;

    else if (mem_memtoreg)
        mem_forward_data = mem_read_data;

    else
        mem_forward_data = mem_alu_result;

end

    // FORWARDING MUX — RS1
    
    always_comb begin
        case (forward_a)

            2'b00:
                forwarded_rs1 = ex_rs1_value;

            2'b10:
                forwarded_rs1 = mem_forward_data;

            2'b01:
                forwarded_rs1 = wb_writeback_data;

            default:
                forwarded_rs1 = ex_rs1_value;

        endcase
    end


    // FORWARDING MUX — RS2
  
    always_comb begin
        case (forward_b)

            2'b00:
                forwarded_rs2 = ex_rs2_value;

            2'b10:
                forwarded_rs2 = mem_forward_data;

            2'b01:
                forwarded_rs2 = wb_writeback_data;

            default:
                forwarded_rs2 = ex_rs2_value;

        endcase
    end


    // ALU INPUT A
   
    always_comb begin

    if (ex_auipc)
        alu_input_a = ex_pc;

    else if (ex_lui)
        alu_input_a = 32'b0;

    else
        alu_input_a = forwarded_rs1;

    end


    // ALU INPUT B
 
    always_comb begin

    if (ex_alusrc)
        alu_input_b = ex_imm;

    else
        alu_input_b = forwarded_rs2;

    end



    // ALU
    
    rv32i_alu_g alu (
        .a (alu_input_a),
        .b (alu_input_b),
        .alu_control(ex_alu_control),
        .result (alu_result)
    );


    // BRANCH UNIT
  
    rv32i_branch_unit_g branch_unit (
        .branch (ex_branch),
        .branch_type(ex_branch_type),

        .rs1_value (forwarded_rs1),
        .rs2_value (forwarded_rs2),

        .pc (ex_pc),
        .immediate (ex_imm),

        .branch_taken(branch_taken),
        .branch_target(branch_target)
    );


    // JAL TARGET
  
    assign jal_target =
        ex_pc + ex_imm;


    // JALR TARGET
  
    assign jalr_target =
        (forwarded_rs1 + ex_imm) & 32'hFFFF_FFFE;


    // JUMP CONTROL
   
   


   rv32i_gshare_predictor_g #(.HISTORY_BITS(4)) gshare_predictor (
    .clk(clk),
    .reset(reset),

    .predict_pc(pc),
    .predict_taken(gshare_predict_taken),
    .predict_index(gshare_predict_index),

    .update_valid(predictor_update_valid),
    .update_index(ex_gshare_predict_index),
    .update_taken(predictor_update_taken)
);


    rv32i_btb_g #(.BTB_ENTRIES(16)) btb (
    .clk(clk),
    .reset(reset),

    .predict_pc(pc),
    .btb_hit(btb_hit),
    .predict_target(btb_predict_target),
    .btb_is_branch(btb_is_branch),
    .btb_is_jump(btb_is_jump),

    .update_valid(btb_update_valid),
    .update_pc(btb_update_pc),
    .update_target(btb_update_target),
    .update_is_branch(btb_update_is_branch)
);

    always_comb begin

    if (ex_jalr)
        btb_update_target = jalr_target;

    else if (ex_jal)
        btb_update_target = jal_target;

    else
        btb_update_target = branch_target;

end

    assign btb_update_is_branch = ex_branch;

    assign btb_update_valid = ex_branch || ex_jal || ex_jalr;


    // PC NEXT LOGIC

    assign predictor_update_valid = ex_branch;

    assign predictor_update_taken =branch_taken;

    

    assign btb_update_pc = ex_pc;

    

   always_comb begin

    if (btb_hit && btb_is_branch && gshare_predict_taken)

        predicted_next_pc = btb_predict_target;

    else if (btb_hit && btb_is_jump)

        predicted_next_pc = btb_predict_target;

    else

        predicted_next_pc = pc_plus4;

end

    always_comb begin
    if (actual_taken)
        redirect_pc = actual_target;
    else
        redirect_pc = ex_pc_plus4;
    end
   
    always_comb begin
    if (ex_jal || ex_jalr)
        actual_taken = 1'b1;
    else
        actual_taken = branch_taken;
    end

    always_comb begin
    if (ex_jalr)
        actual_target = jalr_target;
    else if (ex_jal)
        actual_target = jal_target;
    else
        actual_target = branch_target;
    end

    always_comb begin

    if (branch_misprediction)
        next_pc = redirect_pc;

    else
        next_pc = predicted_next_pc;

    end

    assign if_predicted_taken =(btb_hit && btb_is_jump) ||(btb_hit && btb_is_branch && gshare_predict_taken);

assign if_predicted_target = btb_predict_target;

    // CONTROL TRANSFER


    always_comb begin

    branch_misprediction = 1'b0;

    if (actual_taken != ex_predicted_taken)
        branch_misprediction = 1'b1;

    else if (actual_taken &&
             ex_predicted_taken &&
             actual_target != ex_predicted_target)
        branch_misprediction = 1'b1;

    end

    // FLUSH LOGIC
  
    assign flush_if_id = branch_misprediction;
    assign flush_id_ex = branch_misprediction;

    // HAZARD DETECTION
       rv32i_hazard_unit_g hazard (
        .idex_memread (ex_memread),
        .idex_rd(ex_rd),

        .ifid_rs1 (id_rs1),
        .ifid_rs2 (id_rs2),

        .ifid_uses_rs1(id_uses_rs1),
        .ifid_uses_rs2(id_uses_rs2),

        .pc_write (hazard_pc_write),
        .if_id_write (hazard_if_id_write),
        .insert_bubble(insert_bubble)
    );

    // STALL / FLUSH PRIORITY
    
    always_comb begin

    if (branch_misprediction) begin

        pc_write = 1'b1;
        if_id_write = 1'b1;

    end

    else begin

        pc_write = hazard_pc_write;
        if_id_write = hazard_if_id_write;

    end

end

    // STORE DATA
   
    logic [31:0] ex_store_data;

    assign ex_store_data = forwarded_rs2;


    // EX / MEM
    
    rv32i_ex_mem_g ex_mem (
        .clk (clk),
        .reset (reset),
        .flush (1'b0),

        .ex_alu_result(alu_result),
        .ex_store_data(ex_store_data),
        .ex_pc_plus4  (ex_pc_plus4),

        .ex_rd (ex_rd),

        .ex_regwrite  (ex_regwrite),
        .ex_memread (ex_memread),
        .ex_memwrite (ex_memwrite),
        .ex_memtoreg (ex_memtoreg),

        .ex_jal (ex_jal),
        .ex_jalr (ex_jalr),

        .mem_alu_result(mem_alu_result),
        .mem_store_data(mem_store_data),
        .mem_pc_plus4 (mem_pc_plus4),

        .mem_rd (mem_rd),

        .mem_regwrite  (mem_regwrite),
        .mem_memread (mem_memread),
        .mem_memwrite (mem_memwrite),
        .mem_memtoreg (mem_memtoreg),

        .mem_jal (mem_jal),
        .mem_jalr (mem_jalr)
    );


    // data memory
   
    rv32i_data_memory_g dmem (
        .clk (clk),
        .reset (reset),

        .address (mem_alu_result),
        .write_data(mem_store_data),

        .memread (mem_memread),
        .memwrite (mem_memwrite),

        .read_data (mem_read_data)
    );


    // MEM / WB
   
    rv32i_mem_wb_g mem_wb (
        .clk (clk),
        .reset (reset),
        .flush (1'b0),

        .mem_alu_result(mem_alu_result),
        .mem_read_data (mem_read_data),
        .mem_pc_plus4 (mem_pc_plus4),

        .mem_rd (mem_rd),

        .mem_regwrite (mem_regwrite),
        .mem_memtoreg  (mem_memtoreg),

        .mem_jal (mem_jal),
        .mem_jalr (mem_jalr),

        .wb_alu_result(wb_alu_result),
        .wb_read_data (wb_read_data),
        .wb_pc_plus4 (wb_pc_plus4),

        .wb_rd (wb_rd),

        .wb_regwrite (wb_regwrite),
        .wb_memtoreg (wb_memtoreg),

        .wb_jal (wb_jal),
        .wb_jalr (wb_jalr)
    );


    // writeback
    

    always_comb begin

        if (wb_jal || wb_jalr)
            wb_writeback_data = wb_pc_plus4;

        else if (wb_memtoreg)
            wb_writeback_data = wb_read_data;

        else
            wb_writeback_data = wb_alu_result;

    end

endmodule