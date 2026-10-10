`timescale 1ns / 1ps
// ============================================================================
//  Branch-prediction core (gshare + BTB) testbench
//  - Self-checking against a golden RV32I reference model (values generated
//    from the same instruction_memory.hex used by both projects)
//  - All benchmark statistics are counted live during simulation
//    (sampled at the EX stage, where branches/jumps are resolved)
// ============================================================================
module rv32i_core_tb;

    localparam real CLK_PERIOD         = 10.0;          // ns
    localparam logic [31:0] HALT_INSTR = 32'h0000006f;  // jal x0, 0
    localparam int  MAX_CYCLES         = 200000;
    localparam int  DRAIN_CYCLES       = 5;
    localparam int  IMEM_WORDS         = 256;           // = IMEM_DEPTH in rtl
    localparam bit  VERBOSE            = 1'b0;          // 1 = per-cycle trace

    // Golden-model runtime counts for this program (architectural, so they
    // must match on ANY correct core, predicted or not)
    localparam int EXP_BRANCHES = 5191;
    localparam int EXP_TAKEN    = 4774;
    localparam int EXP_JUMPS    = 3966;

    logic clk;
    logic reset;

    rv32i_core_g dut (.clk(clk), .reset(reset));

    initial clk = 1'b0;
    always #(CLK_PERIOD/2.0) clk = ~clk;

    // ---------------------------------------------------------------- counters
    int  static_instructions;
    int  branches_executed;
    int  taken_branches;
    int  jumps_executed;
    int  mispredictions;
    int  total_cycles;
    bit  running;
    bit  halted;
    int  pass_count;
    int  fail_count;

    // halt = "jal x0, 0" reaching EX (EX is never squashed, so this is committed)
    wire halt_in_ex = dut.ex_jal && (dut.ex_imm == 32'd0) && (dut.ex_rd == 5'd0);

    // Sample mid-cycle: all combinational signals are stable, no race with
    // the DUT's posedge flops.
    always @(negedge clk) begin
        if (running && !halted) begin
            total_cycles++;

            if (halt_in_ex) begin
                halted = 1'b1;
            end
            else begin
                if (dut.ex_branch)                 branches_executed++;
                if (dut.ex_branch && dut.branch_taken) taken_branches++;
                if (dut.ex_jal || dut.ex_jalr)     jumps_executed++;
                if (dut.branch_misprediction)      mispredictions++;
            end

            if (VERBOSE)
                $display("C=%0d PC=%08h IF=%08h EX_PC=%08h BR=%0b TK=%0b J=%0b%s",
                         total_cycles, dut.pc, dut.instruction, dut.ex_pc,
                         dut.ex_branch, dut.branch_taken, (dut.ex_jal|dut.ex_jalr),
                         dut.branch_misprediction ? " MISPREDICT" : "");
        end
    end

    // -------------------------------------------------------------- main flow
    initial begin
        static_instructions = 0;
        branches_executed   = 0;
        taken_branches      = 0;
        jumps_executed      = 0;
        mispredictions      = 0;
        total_cycles        = 0;
        running             = 1'b0;
        halted              = 1'b0;
        pass_count          = 0;
        fail_count          = 0;

        reset = 1'b1;
        repeat (3) @(posedge clk);
        #1;
        // count loaded (non-X) words in instruction memory
        for (int i = 0; i < IMEM_WORDS; i++)
            if (!$isunknown(dut.imem.memory[i])) static_instructions++;

        reset   = 1'b0;
        running = 1'b1;

        wait (halted || total_cycles >= MAX_CYCLES);

        if (!halted) begin
            $display("\n[TB] TIMEOUT after %0d cycles - HALT never reached EX", total_cycles);
            fail_count++;
        end

        repeat (DRAIN_CYCLES) @(posedge clk);   // let MEM/WB commit
        #1;
        report();
        $finish;
    end

    // ------------------------------------------------------------------ report
    task automatic report();
        $display("\n========================================");
        $display("      BRANCH PREDICTION BENCHMARK");
        $display("========================================");
        $display("STATIC INSTRUCTIONS        = %0d", static_instructions);
        $display("BRANCHES EXECUTED          = %0d", branches_executed);
        $display("TAKEN BRANCHES             = %0d", taken_branches);
        $display("JUMPS EXECUTED             = %0d", jumps_executed);
        $display("MIS-PREDICTIONS            = %0d", mispredictions);
        $display("TOTAL CYCLES               = %0d", total_cycles);
        $display("EXECUTION TIME             = %0.0f ns", total_cycles * CLK_PERIOD);
        $display("");

        check_reg( 1, 32'h00000002);
        check_reg( 2, 32'h00000190);
        check_reg( 3, 32'h00000191);
        check_reg( 4, 32'h00000001);
        check_reg( 5, 32'h000342a9);
        check_reg( 6, 32'h00000001);
        check_reg( 7, 32'h12345002);
        check_reg( 8, 32'h000001b6);
        check_reg( 9, 32'h00000080);
        check_reg(10, 32'h091a2805);
        check_reg(11, 32'h00006855);
        check_reg(12, 32'h00000015);
        check_reg(13, 32'h00000048);
        check_reg(14, 32'h00000242);
        check_reg(15, 32'h00034285);
        check_reg(16, 32'h00034287);
        check_reg(17, 32'h00012351);
        check_reg(18, 32'h000001f5);
        check_reg(19, 32'h0000f4ae);
        check_reg(20, 32'h0001e942);
        check_reg(21, 32'h00000001);
        check_reg(22, 32'h00000257);
        check_reg(23, 32'h00000001);
        check_reg(24, 32'hfffcbd84);
        check_reg(25, 32'h00000001);
        check_reg(26, 32'h00000140);
        check_reg(27, 32'h00000001);
        check_reg(28, 32'h00000001);
        check_reg(29, 32'h0003427b);
        check_reg(30, 32'h00000200);
        check_reg(31, 32'h00000100);
        check_mem(64, 32'h0003427b);
        check_mem(65, 32'h00000001);
        check_mem(128, 32'h00000003);
        check_mem(129, 32'h00000005);
        check_mem(130, 32'h00000009);
        check_mem(131, 32'h0000000f);
        check_mem(132, 32'h00000017);
        check_mem(133, 32'h00000021);
        check_mem(134, 32'h0000002d);
        check_mem(135, 32'h0000003b);
        check_mem(136, 32'h0000004b);
        check_mem(137, 32'h0000005d);
        check_mem(138, 32'h00000071);
        check_mem(139, 32'h00000087);
        check_mem(140, 32'h0000009f);
        check_mem(141, 32'h000000b9);
        check_mem(142, 32'h000000d5);
        check_mem(143, 32'h000000f3);
        check_mem(144, 32'h00000113);
        check_mem(145, 32'h00000135);
        check_mem(146, 32'h00000159);
        check_mem(147, 32'h0000017f);
        check_mem(148, 32'h000001a7);
        check_mem(149, 32'h000001d1);
        check_mem(150, 32'h000001fd);
        check_mem(151, 32'h0000022b);
        check_mem(152, 32'h0000025b);
        check_mem(153, 32'h0000028d);
        check_mem(154, 32'h000002c1);
        check_mem(155, 32'h000002f7);
        check_mem(156, 32'h0000032f);
        check_mem(157, 32'h00000369);
        check_mem(158, 32'h000003a5);
        check_mem(159, 32'h000003e3);
        check_mem(160, 32'h00000423);
        check_mem(161, 32'h00000465);
        check_mem(162, 32'h000004a9);
        check_mem(163, 32'h000004ef);
        check_mem(164, 32'h00000537);
        check_mem(165, 32'h00000581);
        check_mem(166, 32'h000005cd);
        check_mem(167, 32'h0000061b);
        check_mem(168, 32'h0000066b);
        check_mem(169, 32'h000006bd);
        check_mem(170, 32'h00000711);
        check_mem(171, 32'h00000767);
        check_mem(172, 32'h000007bf);
        check_mem(173, 32'h00000819);
        check_mem(174, 32'h00000875);
        check_mem(175, 32'h000008d3);
        check_mem(176, 32'h00000933);
        check_mem(177, 32'h00000995);
        check_mem(178, 32'h000009f9);
        check_mem(179, 32'h00000a5f);
        check_mem(180, 32'h00000ac7);
        check_mem(181, 32'h00000b31);
        check_mem(182, 32'h00000b9d);
        check_mem(183, 32'h00000c0b);
        check_mem(184, 32'h00000c7b);
        check_mem(185, 32'h00000ced);
        check_mem(186, 32'h00000d61);
        check_mem(187, 32'h00000dd7);
        check_mem(188, 32'h00000e4f);
        check_mem(189, 32'h00000ec9);
        check_mem(190, 32'h00000f45);
        check_mem(191, 32'h00000fc3);

        check_count("BRANCHES EXECUTED", branches_executed, EXP_BRANCHES);
        check_count("TAKEN BRANCHES",    taken_branches,    EXP_TAKEN);
        check_count("JUMPS EXECUTED",    jumps_executed,    EXP_JUMPS);

        $display("");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("RESULT = %s", (fail_count == 0) ? "PASS" : "FAIL");
        $display("========================================");
    endtask

    task automatic check_reg(input int n, input logic [31:0] exp);
        logic [31:0] act;
        act = dut.regfile.registers[n];
        if (act === exp) begin
            $display("PASS: x%0d = %08h", n, act); pass_count++;
        end else begin
            $display("FAIL: x%0d = %08h (expected %08h)", n, act, exp); fail_count++;
        end
    endtask

    task automatic check_mem(input int idx, input logic [31:0] exp);
        logic [31:0] act;
        act = dut.dmem.memory[idx];
        if (act === exp) begin
            $display("PASS: MEM[%0d] = %08h", idx, act); pass_count++;
        end else begin
            $display("FAIL: MEM[%0d] = %08h (expected %08h)", idx, act, exp); fail_count++;
        end
    endtask

    task automatic check_count(input string name, input int act, input int exp);
        if (act == exp) begin
            $display("PASS: %s = %0d", name, act); pass_count++;
        end else begin
            $display("FAIL: %s = %0d (expected %0d)", name, act, exp); fail_count++;
        end
    endtask

endmodule
