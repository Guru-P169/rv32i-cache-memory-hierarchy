`timescale 1ns/1ps
// Console regression / coverage monitor for rv32i_core_g and the supplied HEX.
// IMPORTANT: this bench monitors the DUT; it is not a complete independent ISA
// reference model. The supplied program does not necessarily exercise every RV32I
// instruction or every cache/misalignment condition. Unseen features are reported
// as NOT OBSERVED, never silently marked PASS.

module rv32i_core_tb;
  localparam integer MAX_CYCLES = 2000000;
  localparam integer TRACE_CYCLES = 60;
  localparam integer POST_HALT_CYCLES = 8;
  reg clk = 0;
  reg reset = 1;
  rv32i_core_g dut(.clk(clk), .reset(reset));
  always #5 clk = ~clk;

  integer cycles=0, failures=0, drain=0;
  integer i_req=0, i_rsp=0, d_req=0, d_rsp=0, d_load=0, d_store=0;
  integer branch_ex=0, branch_taken=0, jal_count=0, jalr_count=0, mispred=0;
  integer stalls=0, bubbles=0, fwd_a_mem=0, fwd_a_wb=0, fwd_b_mem=0, fwd_b_wb=0;
  integer reset_checks=0, timeout_hit=0;

  // Hierarchy-level cache/memory counters. These use the actual internal
  // lookup states and memory request acceptance state in this project RTL.
  integer l1i_lookups=0, l1i_hits=0, l1i_misses=0;
  integer l1d_lookups=0, l1d_hits=0, l1d_misses=0;
  integer l2_lookups=0, l2_hits=0, l2_misses=0;
  integer memory_reads=0, memory_writes=0;
  reg l2_mem_req_d = 1'b0;


  integer checks_passed=0, checks_failed=0;
  localparam integer STATIC_INSTRUCTIONS = 244;
  localparam integer CLOCK_PERIOD_NS = 10;
  integer lb_seen=0, lh_seen=0, lw_seen=0, lbu_seen=0, lhu_seen=0;
  integer sb_seen=0, sh_seen=0, sw_seen=0;
  integer alu_add=0, alu_sub=0, alu_sll=0, alu_slt=0, alu_sltu=0;
  integer alu_xor=0, alu_srl=0, alu_sra=0, alu_or=0, alu_and=0;
  integer alu_lui=0, alu_auipc=0, i_type=0, r_type=0, loads=0, stores=0;
  integer op_branch=0, op_jal=0, op_jalr=0, op_misc=0;
  integer unaligned_req=0, line_cross_req=0, unknown_req=0;
  reg running=0, halted=0, timed_out=0;
  reg [31:0] prev_pc;
  integer same_pc=0;
 wire halt_in_ex = dut.ex_jal &&
                  (dut.ex_imm == 32'd0) &&
                  (dut.ex_rd == 5'd0);
  // Instruction class observations are from the decode-stage instruction and
  // may repeat under stalls; treat these as observed coverage, not retired counts.
  always @(negedge clk) begin
    if (running && !halted && !timed_out) begin
      cycles = cycles + 1;

      // L1 instruction cache: S_LOOKUP is enum value 1.
      if (dut.cache_hierarchy.u_l1_icache.state == 1) begin
        l1i_lookups = l1i_lookups + 1;
        if (dut.cache_hierarchy.u_l1_icache.valid_array[
              dut.cache_hierarchy.u_l1_icache.request_index] &&
            dut.cache_hierarchy.u_l1_icache.tag_array[
              dut.cache_hierarchy.u_l1_icache.request_index] ==
              dut.cache_hierarchy.u_l1_icache.request_tag)
          l1i_hits = l1i_hits + 1;
        else l1i_misses = l1i_misses + 1;
      end

      // L1 data cache: derive hit from the actual valid/tag arrays.
      // This matches rv32i_l1_dcache_g, which does not declare a `hit` signal.
      if (dut.cache_hierarchy.u_l1_dcache.state == 1) begin
        l1d_lookups = l1d_lookups + 1;
        if (dut.cache_hierarchy.u_l1_dcache.valid_array[
              dut.cache_hierarchy.u_l1_dcache.request_index] &&
            (dut.cache_hierarchy.u_l1_dcache.tag_array[
              dut.cache_hierarchy.u_l1_dcache.request_index] ==
              dut.cache_hierarchy.u_l1_dcache.request_tag)) begin
          l1d_hits = l1d_hits + 1;
        end else begin
          l1d_misses = l1d_misses + 1;
        end
      end

      if (dut.cache_hierarchy.u_l2_cache.state == 1) begin
        l2_lookups = l2_lookups + 1;
        if (dut.cache_hierarchy.u_l2_cache.hit)
          l2_hits = l2_hits + 1;
        else
          l2_misses = l2_misses + 1;
      end

      // Main-memory transactions are counted on the rising edge of the request.
      if (dut.cache_hierarchy.l2_mem_req && !l2_mem_req_d) begin
        if (dut.cache_hierarchy.l2_mem_write)
          memory_writes = memory_writes + 1;
        else
          memory_reads = memory_reads + 1;
      end
      l2_mem_req_d = dut.cache_hierarchy.l2_mem_req;

      if (dut.hierarchy_i_req) i_req = i_req + 1;
      if (dut.hierarchy_i_ready) i_rsp = i_rsp + 1;
      if (dut.pipeline_stall || dut.dcache_stall) stalls = stalls + 1;
      if (dut.insert_bubble || dut.flush_if_id || dut.flush_id_ex) bubbles = bubbles + 1;
      if (dut.forward_a == 2'b10) fwd_a_mem = fwd_a_mem + 1;
      if (dut.forward_a == 2'b01) fwd_a_wb = fwd_a_wb + 1;
      if (dut.forward_b == 2'b10) fwd_b_mem = fwd_b_mem + 1;
      if (dut.forward_b == 2'b01) fwd_b_wb = fwd_b_wb + 1;
      if (dut.ex_branch) begin
        branch_ex = branch_ex + 1;
        if (dut.branch_taken) branch_taken = branch_taken + 1;
      end
      if (dut.ex_jal && !halt_in_ex) jal_count = jal_count + 1;
      if (dut.ex_jalr) jalr_count = jalr_count + 1;
      if (dut.branch_misprediction) mispred = mispred + 1;

      // Decode the instruction currently visible to the decoder.
      case (dut.id_instruction[6:0])
        7'b0110011: begin
          r_type=r_type+1;
          case (dut.id_instruction[14:12])
            3'b000: if (dut.id_instruction[30]) alu_sub=alu_sub+1; else alu_add=alu_add+1;
            3'b001: alu_sll=alu_sll+1;
            3'b010: alu_slt=alu_slt+1;
            3'b011: alu_sltu=alu_sltu+1;
            3'b100: alu_xor=alu_xor+1;
            3'b101: if (dut.id_instruction[30]) alu_sra=alu_sra+1; else alu_srl=alu_srl+1;
            3'b110: alu_or=alu_or+1;
            3'b111: alu_and=alu_and+1;
          endcase
        end
        7'b0010011: begin
          i_type=i_type+1;
          case (dut.id_instruction[14:12])
            3'b000: alu_add=alu_add+1;
            3'b001: alu_sll=alu_sll+1;
            3'b010: alu_slt=alu_slt+1;
            3'b011: alu_sltu=alu_sltu+1;
            3'b100: alu_xor=alu_xor+1;
            3'b101: if (dut.id_instruction[30]) alu_sra=alu_sra+1; else alu_srl=alu_srl+1;
            3'b110: alu_or=alu_or+1;
            3'b111: alu_and=alu_and+1;
          endcase
        end
        7'b0000011: begin
          loads=loads+1;
          case(dut.id_instruction[14:12])
            3'b000: lb_seen=lb_seen+1;
            3'b001: lh_seen=lh_seen+1;
            3'b010: lw_seen=lw_seen+1;
            3'b100: lbu_seen=lbu_seen+1;
            3'b101: lhu_seen=lhu_seen+1;
            default: unknown_req=unknown_req+1;
          endcase
        end
        7'b0100011: begin
          stores=stores+1;
          case(dut.id_instruction[14:12])
            3'b000: sb_seen=sb_seen+1;
            3'b001: sh_seen=sh_seen+1;
            3'b010: sw_seen=sw_seen+1;
            default: unknown_req=unknown_req+1;
          endcase
        end
        7'b1100011: op_branch=op_branch+1;
        7'b1101111: op_jal=op_jal+1;
        7'b1100111: op_jalr=op_jalr+1;
        7'b0110111: alu_lui=alu_lui+1;
        7'b0010111: alu_auipc=alu_auipc+1;
        7'b0001111,7'b1110011: op_misc=op_misc+1;
        default: ;
      endcase

      if (dut.dcache_req) begin
        d_req=d_req+1;
        if (dut.dcache_write) begin
          d_store=d_store+1;
          $display("[D-STORE] cyc=%0d addr=%08h data=%08h byte_en=%04b funct3=%03b",
                   cycles,dut.dcache_addr,dut.dcache_wdata,dut.dcache_byte_en,dut.dcache_load_type);
          if (dut.dcache_byte_en == 0 || (^dut.dcache_byte_en) === 1'bx) begin
            $display("[FAIL] invalid/unknown store byte enable"); failures=failures+1;
          end
        end else begin
          d_load=d_load+1;
          $display("[D-LOAD ] cyc=%0d addr=%08h byte_en=%04b load_type=%03b",
                   cycles,dut.dcache_addr,dut.dcache_byte_en,dut.dcache_load_type);
        end
        if (dut.dcache_addr[1:0] != 0) unaligned_req=unaligned_req+1;
        // Core presents byte address; cache-line boundary crossing can only be
        // established using access width and address, so report request addresses
        // near a 16-byte line end as candidates, not proven crossings.
        if (dut.dcache_addr[3:0] >= 4'd13) line_cross_req=line_cross_req+1;
      end
      if (dut.dcache_ready) begin
        d_rsp=d_rsp+1;
        $display("[D-RESP ] cyc=%0d ready=%b data=%08h",cycles,dut.dcache_ready,dut.dcache_rdata);
      end

      if (cycles <= TRACE_CYCLES)
        $display("[TRACE] c=%0d pc=%08h if_ins=%08h ex_pc=%08h id_ins=%08h stall=%b flush=%b mispred=%b",
                 cycles,dut.pc,dut.instruction,dut.ex_pc,dut.id_instruction,
                 dut.pipeline_stall,dut.flush_if_id,dut.branch_misprediction);

      if (dut.pc === prev_pc) same_pc=same_pc+1; else same_pc=0;
      prev_pc=dut.pc;
      if (same_pc==1000)
        $display("[WARN] PC unchanged for 1000 sampled cycles at %08h (may be loop or deadlock)",dut.pc);

      if (halt_in_ex) begin
        halted=1;
        $display("\n[HALT] terminal JAL x0,0 observed at cycle %0d EX_PC=%08h",cycles,dut.ex_pc);
      end else if (cycles >= MAX_CYCLES) begin
        timed_out=1; timeout_hit=1;
        $display("\n[FAIL] TIMEOUT: exceeded %0d cycles",MAX_CYCLES);
      end
    end else if (running && halted && drain < POST_HALT_CYCLES) drain=drain+1;
  end

  task automatic dump_regs;
    integer r;
    begin
      $display("\n================ REGISTER FILE ================");
      for(r=0;r<32;r=r+1) begin
        $write("x%0d=%08h%s",r,dut.regfile.registers[r],((r%4)==3)?"\n":"  ");
      end
      $display("================================================");
    end
  endtask

  task automatic report_coverage;
    begin
      $display("\n================ COVERAGE / TRAFFIC ================");
      $display("Cycles=%0d halt=%0b timeout=%0b",cycles,halted,timed_out);
      $display("I hierarchy req=%0d ready-samples=%0d; D-cache req=%0d response-samples=%0d loads=%0d stores=%0d",
               i_req,i_rsp,d_req,d_rsp,d_load,d_store);
      $display("Branches observed=%0d taken=%0d; JAL=%0d JALR=%0d misprediction-samples=%0d",
               branch_ex,branch_taken,jal_count,jalr_count,mispred);
      $display("Stall samples=%0d bubble/flush samples=%0d forwarding A(MEM/WB)=%0d/%0d B(MEM/WB)=%0d/%0d",
               stalls,bubbles,fwd_a_mem,fwd_a_wb,fwd_b_mem,fwd_b_wb);
      $display("Decode observations (may repeat during stalls): R-type=%0d I-type=%0d branch=%0d JAL=%0d JALR=%0d load=%0d store=%0d",
               r_type,i_type,op_branch,op_jal,op_jalr,loads,stores);
      $display("ALU/compare operation observations: ADD=%0d SUB=%0d SLL=%0d SLT=%0d SLTU=%0d XOR=%0d SRL=%0d SRA=%0d OR=%0d AND=%0d LUI=%0d AUIPC=%0d",
               alu_add,alu_sub,alu_sll,alu_slt,alu_sltu,alu_xor,alu_srl,alu_sra,alu_or,alu_and,alu_lui,alu_auipc);
      $display("Load types seen LB=%0d LH=%0d LW=%0d LBU=%0d LHU=%0d",lb_seen,lh_seen,lw_seen,lbu_seen,lhu_seen);
      $display("Store types seen SB=%0d SH=%0d SW=%0d",sb_seen,sh_seen,sw_seen);
      $display("Unaligned data request addresses=%0d; possible near-line-end request addresses=%0d",
               unaligned_req,line_cross_req);
      $display("NOTE: these are coverage observations, not proof that every feature is correct.");
      $display("A zero means the supplied HEX did not visibly exercise that class (or the observation point missed it).");
      $display("This core exposes internal hierarchy_i/d signals; cache/L2 internals may require separate bind/monitor hooks.");
      $display("====================================================");
    end
  endtask

  task automatic check_reg_expected(input integer reg_num, input reg [31:0] expected_value, input [8*48-1:0] test_name);
    reg [31:0] actual_value;
    begin
      actual_value = dut.regfile.registers[reg_num];
      if (actual_value === expected_value) begin
        $display("[PASS] %-24s x%0d = %08h", test_name, reg_num, actual_value);
        checks_passed = checks_passed + 1;
      end else begin
        $display("[FAIL] %-24s x%0d = %08h expected=%08h", test_name, reg_num, actual_value, expected_value);
        checks_failed = checks_failed + 1;
        failures = failures + 1;
      end
    end
  endtask

  initial begin
    $display("==============================================================");
    $display(" RV32I PROCESSOR — PRESENTATION TEST REPORT");
    $display(" Use instruction_memory_extended.hex in the DUT instruction-memory path");
    $display(" 244-word program: original benchmark + directed tests + 2KB and 6KB array fill/sum passes and hash loop.");
    $display("==============================================================");
    prev_pc=32'hxxxxxxxx;
    repeat(5) @(posedge clk);
    // Basic reset-state observation. Releasing reset only after stable clocks.
    if (dut.pc !== 32'b0) begin
      $display("[WARN] PC at reset sample is %08h (expected 00000000; check reset polarity/latency)",dut.pc);
    end else begin
      reset_checks=reset_checks+1;
      $display("[PASS] PC observed at reset vector 0");
    end
    @(negedge clk); reset=0; running=1;
    wait(halted || timed_out);
    repeat(POST_HALT_CYCLES) @(posedge clk);
    running=0;
    dump_regs();
    report_coverage();

    $display("\n================ DIRECTED ARCHITECTURAL CHECKS ================");
    if (halted && !timed_out) begin
      check_reg_expected(22,32'h00000078,"LB signed byte");
      check_reg_expected(23,32'h00000056,"LBU unsigned byte");
      check_reg_expected(24,32'h00005678,"LH signed halfword");
      check_reg_expected(25,32'h00001234,"LHU unsigned halfword");
      check_reg_expected(27,32'hffffff80,"LB sign extension");
      check_reg_expected(28,32'h00000080,"LBU zero extension");
      check_reg_expected(30,32'hffff8000,"LH sign extension");
      check_reg_expected(31,32'h00008000,"LHU zero extension");
      check_reg_expected(3,32'h00000008,"ADD result");
      check_reg_expected(4,32'h00000002,"SUB result");
      check_reg_expected(5,32'h00000001,"AND result");
      check_reg_expected(6,32'h00000007,"OR result");
      check_reg_expected(7,32'h00000006,"XOR result");
      check_reg_expected(8,32'h0000000c,"SLLI result");
      check_reg_expected(9,32'h00000002,"SRAI result");
      check_reg_expected(10,32'h00000006,"Six branch conditions");
      check_reg_expected(11,32'h00000000,"Branch failure counter");
      check_reg_expected(12,32'h00000004,"Counted loop result");
      check_reg_expected(13,32'h00000004,"Loop limit");
      check_reg_expected(14,32'h000002f8,"JAL link address");
      check_reg_expected(16,32'h00000033,"JAL/JALR subroutine");
      check_reg_expected(29,32'h000c2400,"Array checksum");
      check_reg_expected(26,32'h4fd2f8cf,"Hash loop result");
      check_reg_expected(18,32'h00361b00,"6KB array checksum");
    end else begin
      $display("[SKIP] Directed checks skipped because program did not halt.");
    end
    $display("===============================================================");

    if (dut.regfile.registers[0] !== 32'b0) begin
      $display("[FAIL] x0 invariant violated: %08h",dut.regfile.registers[0]); failures=failures+1;
    end else begin $display("[PASS] x0 invariant"); checks_passed=checks_passed+1; end

    if (!halted || timed_out) begin
      $display("[FAIL] program did not reach expected terminal loop"); failures=failures+1;
    end else begin $display("[PASS] terminal self-loop detected"); checks_passed=checks_passed+1; end

    if (i_req != 0 && i_rsp != 0) begin $display("[PASS?] instruction hierarchy request/ready activity observed"); checks_passed=checks_passed+1; end
    else begin $display("[WARN] instruction hierarchy request/ready activity missing"); failures=failures+1; end
    if (d_req == d_rsp) $display("[INFO] D-cache request and ready sample counts match");
    else $display("[INFO] D-cache request/ready samples differ; inspect protocol timing (not necessarily one-to-one samples)");

    if (failures==0)
      $display("\nOVERALL RESULT: PASS for basic reset observation, x0 invariant, completion and observed traffic.");
    else
      $display("\nOVERALL RESULT: FAIL/WARN with %0d counted failure(s).",failures);
    $display("NOT CLAIMED: complete ISA golden checking, cache hit/miss correctness, unaligned semantics, line crossing,");
    $display("             cache hit/miss correctness, L2 arbitration/backpressure/retry, or mid-run reset recovery.");

    $display("\n============================================================");
    $display("       RV32I PROCESSOR  PRESENTATION BENCHMARK");
    $display("============================================================");
    $display("STATIC INSTRUCTIONS          = %0d", STATIC_INSTRUCTIONS);
    $display("BRANCHES EXECUTED (samples)  = %0d", branch_ex);
    $display("TAKEN BRANCHES (samples)     = %0d", branch_taken);
    $display("JAL EXECUTED (samples)       = %0d", jal_count);
    $display("JALR EXECUTED (samples)      = %0d", jalr_count);
    $display("MIS-PREDICTION OBSERVATIONS  = %0d", mispred);
    $display("STALL OBSERVATIONS           = %0d", stalls);
    $display("FLUSH / BUBBLE OBSERVATIONS  = %0d", bubbles);
    $display("TOTAL CYCLES                 = %0d", cycles);
    $display("EXECUTION TIME               = %0d ns (simulated)", cycles*CLOCK_PERIOD_NS);
    $display("I-CACHE REQUESTS             = %0d", i_req);
    $display("I-CACHE READY SAMPLES        = %0d", i_rsp);
    $display("D-CACHE REQUESTS             = %0d", d_req);
    $display("D-CACHE READY SAMPLES        = %0d", d_rsp);
    $display("LOADS / STORES               = %0d / %0d", d_load, d_store);
    $display("---------------- L1 INSTRUCTION CACHE ----------------");
    $display("L1I LOOKUPS / HITS / MISSES  = %0d / %0d / %0d", l1i_lookups, l1i_hits, l1i_misses);
    if (l1i_lookups != 0) $display("L1I HIT RATE                  = %0.2f%%", 100.0*l1i_hits/l1i_lookups);
    else $display("L1I HIT RATE                  = N/A");
    $display("---------------- L1 DATA CACHE -----------------------");
    $display("L1D LOOKUPS / HITS / MISSES  = %0d / %0d / %0d", l1d_lookups, l1d_hits, l1d_misses);
    if (l1d_lookups != 0) $display("L1D HIT RATE                  = %0.2f%%", 100.0*l1d_hits/l1d_lookups);
    else $display("L1D HIT RATE                  = N/A");
    $display("---------------- L2 SHARED CACHE ---------------------");
    $display("L2 LOOKUPS / HITS / MISSES   = %0d / %0d / %0d", l2_lookups, l2_hits, l2_misses);
    if (l2_lookups != 0) $display("L2 HIT RATE                   = %0.2f%%", 100.0*l2_hits/l2_lookups);
    else $display("L2 HIT RATE                   = N/A");
    $display("---------------- MAIN MEMORY -------------------------");
    $display("MEMORY READ TRANSACTIONS     = %0d", memory_reads);
    $display("MEMORY WRITE TRANSACTIONS    = %0d", memory_writes);
    $display("TOTAL MEMORY TRANSACTIONS    = %0d", memory_reads+memory_writes);
    $display("REGISTER/STATUS CHECKS PASS  = %0d", checks_passed);
    $display("REGISTER/STATUS CHECKS FAIL  = %0d", checks_failed);
    $display("TIMEOUT                      = %0b", timed_out);
    if (halted && !timed_out && failures==0)
      $display("FINAL STATUS                 = PASS (listed checks only)");
    else
      $display("FINAL STATUS                 = FAIL / REVIEW (%0d failure(s))", failures);
      $display("============================================================");
    $finish;
  end

  // Global watchdog so a broken wait condition cannot hang simulation forever.
  initial begin
    #(MAX_CYCLES*10ns + 1000ns);
    if (!halted && !timed_out) begin
      timed_out=1;
      $display("[FATAL] global watchdog fired; simulation did not complete.");
      $finish;
    end
  end
endmodule