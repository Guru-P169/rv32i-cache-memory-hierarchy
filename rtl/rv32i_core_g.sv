module rv32i_core_g (
    input logic clk,
    input logic reset
);

  
    logic [31:0] pc;
    logic [31:0] next_pc;
    logic [31:0] pc_plus4;
    logic pc_write;
    logic [31:0] instruction;
    logic fetch_pending;
    logic fetch_buffer_valid;
    logic discard_fetch;
    logic [31:0] fetch_buffer_instruction;
    logic fetch_saved_predicted_taken;
    logic [31:0] fetch_saved_predicted_target;
    logic [3:0] fetch_saved_gshare_index;
    logic [31:0] fetch_saved_next_pc;
    logic [31:0] fetch_saved_pc;
    logic [31:0] fetch_saved_pc_plus4;
    logic id_instruction_valid;
    logic fetch_accept;
    logic dcache_request_active;
    logic dcache_stall;
    logic pipeline_stall;
    logic [2:0] id_mem_funct3;
    logic [2:0] ex_mem_funct3;
    logic [2:0] mem_funct3;
    logic [31:0] dcache_aligned_wdata;

    assign pc_plus4 = pc + 32'd4;




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

    logic hierarchy_i_req;
    logic [31:0] hierarchy_i_addr;
    logic [31:0] hierarchy_i_instr;
    logic hierarchy_i_ready;

    logic hierarchy_d_req;
    logic hierarchy_d_write;
    logic [31:0] hierarchy_d_addr;
    logic [31:0] hierarchy_d_wdata;
    logic [3:0] hierarchy_d_byte_en;
    logic [2:0] hierarchy_d_load_type;
    logic [31:0] hierarchy_d_rdata;
    logic hierarchy_d_ready;


    // MEM / WB   register
 
    logic [31:0] wb_alu_result;
    logic [31:0] wb_read_data;
    logic [31:0] wb_pc_plus4;

    logic [4:0] wb_rd;

    logic wb_regwrite;
    logic wb_memtoreg;

    logic wb_jal;
    logic wb_jalr;

logic icache_req;
logic [31:0] icache_addr;
logic [31:0] icache_instr;
logic icache_ready;
    

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
        .uses_rs2 (id_uses_rs2),
        .mem_funct3 (id_mem_funct3)
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

        .if_pc (fetch_saved_pc),
        .if_pc_plus4 (fetch_saved_pc_plus4),
        .if_instruction(fetch_buffer_instruction),

        .id_pc (id_pc),
        .id_pc_plus4 (id_pc_plus4),
        .id_instruction(id_instruction),
        .if_predicted_taken(fetch_saved_predicted_taken),
        .if_predicted_target(fetch_saved_predicted_target),

        .if_gshare_predict_index(fetch_saved_gshare_index),
        .id_gshare_predict_index(id_gshare_predict_index),

        .id_predicted_taken(id_predicted_taken),
        .id_predicted_target(id_predicted_target)
    );


    // ID / EX
  
    rv32i_id_ex_g id_ex (
        .clk (clk),
        .reset (reset),

        .flush (flush_id_ex),
        .insert_bubble(insert_bubble || !id_instruction_valid),
        .stall (pipeline_stall),

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
        .id_mem_funct3 (id_mem_funct3),
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
        .ex_mem_funct3 (ex_mem_funct3),
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

    assign btb_update_valid = (ex_branch || ex_jal || ex_jalr) && !dcache_stall;


    // PC NEXT LOGIC

    assign predictor_update_valid = ex_branch && !dcache_stall;

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
        next_pc = fetch_saved_next_pc;

    end

    assign if_predicted_taken =(btb_hit && btb_is_jump) ||(btb_hit && btb_is_branch && gshare_predict_taken);

assign if_predicted_target = btb_predict_target;

    // CONTROL TRANSFER


   always_comb begin
    branch_misprediction = 1'b0;

    if (!dcache_stall && (ex_branch || ex_jal || ex_jalr)) begin
        if (actual_taken != ex_predicted_taken)
            branch_misprediction = 1'b1;
        else if (actual_taken &&
                 ex_predicted_taken &&
                 (actual_target != ex_predicted_target))
            branch_misprediction = 1'b1;
    end
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

        .ifid_uses_rs1(id_instruction_valid && id_uses_rs1),
        .ifid_uses_rs2(id_instruction_valid && id_uses_rs2),

        .pc_write (hazard_pc_write),
        .if_id_write (hazard_if_id_write),
        .insert_bubble(insert_bubble)
    );

     // STALL / FLUSH PRIORITY
    assign fetch_accept = fetch_buffer_valid && !dcache_stall && hazard_if_id_write && !branch_misprediction;
always_comb begin
    if (branch_misprediction) begin
        pc_write = 1'b1;
        if_id_write = 1'b1;
    end
    else begin
        pc_write = fetch_accept && hazard_pc_write;
        if_id_write = fetch_accept && hazard_if_id_write;
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
        .stall (dcache_stall),

        .ex_alu_result(alu_result),
        .ex_store_data(ex_store_data),
        .ex_pc_plus4  (ex_pc_plus4),

        .ex_rd (ex_rd),

        .ex_regwrite  (ex_regwrite),
        .ex_memread (ex_memread),
        .ex_memwrite (ex_memwrite),
        .ex_memtoreg (ex_memtoreg),
        .ex_mem_funct3 (ex_mem_funct3),

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
        .mem_funct3 (mem_funct3),

        .mem_jal (mem_jal),
        .mem_jalr (mem_jalr)
    );


    assign dcache_req = (mem_memread || mem_memwrite) && !dcache_request_active;
    assign dcache_addr = mem_alu_result;
    assign dcache_write = mem_memwrite;
    assign dcache_load_type = mem_funct3;
    assign mem_read_data = dcache_rdata;
    assign dcache_stall = (mem_memread || mem_memwrite) && !dcache_ready;
    assign pipeline_stall = dcache_stall;

    always_comb begin
        dcache_byte_en = 4'b0000;
        dcache_aligned_wdata = mem_store_data;

        if (mem_memwrite) begin
            case (mem_funct3)
                3'b000: begin
                    dcache_byte_en = 4'b0001 << mem_alu_result[1:0];
                    dcache_aligned_wdata = mem_store_data << (8 * mem_alu_result[1:0]);
                end
                3'b001: begin
                    if (mem_alu_result[1] == 1'b0) begin
                        dcache_byte_en = 4'b0011;
                        dcache_aligned_wdata = mem_store_data;
                    end
                    else begin
                        dcache_byte_en = 4'b1100;
                        dcache_aligned_wdata = mem_store_data << 16;
                    end
                end
                3'b010: begin
                    dcache_byte_en = 4'b1111;
                    dcache_aligned_wdata = mem_store_data;
                end
                default: begin
                    dcache_byte_en = 4'b0000;
                    dcache_aligned_wdata = mem_store_data;
                end
            endcase
        end
    end

    assign dcache_wdata = dcache_aligned_wdata;

    always_ff @(posedge clk) begin
        if (reset)
            dcache_request_active <= 1'b0;
        else begin
            if (dcache_req)
                dcache_request_active <= 1'b1;
            if (dcache_ready)
                dcache_request_active <= 1'b0;
        end
    end

    rv32i_cache_hierarchy_g #(
        .MEMORY_BYTES (65536),
        .MEMORY_LATENCY (5),
        .INIT_FILE ("instruction_memory.hex")
    ) cache_hierarchy (
        .clk (clk),
        .reset (reset),
        .i_req (hierarchy_i_req),
        .i_addr (hierarchy_i_addr),
        .i_instr (hierarchy_i_instr),
        .i_ready (hierarchy_i_ready),
        .d_req (hierarchy_d_req),
        .d_write (hierarchy_d_write),
        .d_addr (hierarchy_d_addr),
        .d_wdata (hierarchy_d_wdata),
        .d_byte_en (hierarchy_d_byte_en),
        .d_load_type (hierarchy_d_load_type),
        .d_rdata (hierarchy_d_rdata),
        .d_ready (hierarchy_d_ready)
    );

    assign hierarchy_i_req = !fetch_pending && !fetch_buffer_valid && !dcache_stall && !branch_misprediction;
    assign hierarchy_i_addr = pc;
    assign hierarchy_d_req = dcache_req;
    assign hierarchy_d_write = dcache_write;
    assign hierarchy_d_addr = dcache_addr;
    assign hierarchy_d_wdata = dcache_wdata;
    assign hierarchy_d_byte_en = dcache_byte_en;
    assign hierarchy_d_load_type = dcache_load_type;
    assign dcache_rdata = hierarchy_d_rdata;
    assign dcache_ready = hierarchy_d_ready;
    assign icache_instr = hierarchy_i_instr;
    assign icache_ready = hierarchy_i_ready;
    assign icache_req = hierarchy_i_req;
    assign icache_addr = hierarchy_i_addr;
    assign instruction = icache_instr;

    always_ff @(posedge clk) begin
        if (reset) begin
            fetch_pending <= 1'b0;
            fetch_buffer_valid <= 1'b0;
            discard_fetch <= 1'b0;
            fetch_buffer_instruction <= 32'h00000013;
            fetch_saved_predicted_taken <= 1'b0;
            fetch_saved_predicted_target <= 32'b0;
            fetch_saved_gshare_index <= 4'b0;
            fetch_saved_next_pc <= 32'd4;
            fetch_saved_pc <= 32'b0;
            fetch_saved_pc_plus4 <= 32'd4;
            id_instruction_valid <= 1'b0;
        end
        else begin
            if (hierarchy_i_req) begin
                fetch_pending <= 1'b1;
                fetch_saved_predicted_taken <= if_predicted_taken;
                fetch_saved_predicted_target <= if_predicted_target;
                fetch_saved_gshare_index <= gshare_predict_index;
                fetch_saved_next_pc <= predicted_next_pc;
                fetch_saved_pc <= pc;
                fetch_saved_pc_plus4 <= pc_plus4;
            end

            if (branch_misprediction) begin
                if (fetch_pending)
                    discard_fetch <= 1'b1;
                if (fetch_buffer_valid)
                    fetch_buffer_valid <= 1'b0;
            end

            if (fetch_pending && hierarchy_i_ready) begin
                fetch_pending <= 1'b0;
                if (discard_fetch || branch_misprediction) begin
                    discard_fetch <= 1'b0;
                end
                else begin
                    fetch_buffer_instruction <= hierarchy_i_instr;
                    fetch_buffer_valid <= 1'b1;
                end
            end

            if (branch_misprediction) begin
                id_instruction_valid <= 1'b0;
            end
            else if (fetch_accept) begin
                id_instruction_valid <= 1'b1;
            end
            else if (id_instruction_valid && !dcache_stall && !insert_bubble) begin
                id_instruction_valid <= 1'b0;
            end

            if (fetch_accept)
                fetch_buffer_valid <= 1'b0;
        end
    end

    // MEM / WB
   
    rv32i_mem_wb_g mem_wb (
        .clk (clk),
        .reset (reset),
        .flush (1'b0),
        .stall (dcache_stall),

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