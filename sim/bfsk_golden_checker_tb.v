// =============================================================
// Module   : bfsk_golden_checker_tb.v
// Function : SELF-CHECKING TESTBENCH
//
//            Instantiates the DUT (bfsk_modulator, from
//            bfsk_rtl_complete.v) side-by-side with the golden
//            model (bfsk_golden_model.v), drives both with
//            identical stimulus, and compares outputs every
//            clock cycle automatically.
//
// Compile together with bfsk_rtl_complete.v and bfsk_golden_model.v:
//   iverilog -o sim bfsk_rtl_complete.v bfsk_golden_model.v bfsk_golden_checker_tb.v
// =============================================================

`timescale 1ns / 1ps

module bfsk_golden_checker_tb;

    reg  clk;
    reg  rst;
    reg  data_in;

    wire dut_out;
    wire gold_out;

    integer total_checks;
    integer mismatch_count;
    integer i;

    bfsk_modulator #(
        .F0_DIV (8'd50),
        .F1_DIV (8'd25)
    ) u_dut (
        .clk           (clk),
        .rst           (rst),
        .data_in       (data_in),
        .modulated_out (dut_out)
    );

    bfsk_golden_model #(
        .F0_DIV (8'd50),
        .F1_DIV (8'd25)
    ) u_gold (
        .clk      (clk),
        .rst      (rst),
        .data_in  (data_in),
        .gold_out (gold_out)
    );

    initial clk = 1'b0;
    always  #10 clk = ~clk;

    initial begin
        $timeformat(-9, 0, " ns", 10);
        $dumpfile("bfsk_golden_check.vcd");
        $dumpvars(0, bfsk_golden_checker_tb);
    end

    always @(posedge clk) begin
        if (!rst) begin
            total_checks = total_checks + 1;
            if (dut_out !== gold_out) begin
                mismatch_count = mismatch_count + 1;
                $display("  [MISMATCH] t=%0t | data_in=%b | dut_out=%b  gold_out=%b  <-- FAIL",
                          $time, data_in, dut_out, gold_out);
            end
        end
    end

    initial begin
        total_checks   = 0;
        mismatch_count = 0;

        $display("=========================================================");
        $display(" BFSK GOLDEN MODEL VERIFICATION — Self-Checking Testbench");
        $display("=========================================================");

        rst     = 1'b1;
        data_in = 1'b0;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;

        $display("\n-- Directed test: 0,1,0,1,1,0 --");
        data_in = 1'b0; #2000;
        data_in = 1'b1; #2000;
        data_in = 1'b0; #2000;
        data_in = 1'b1; #2000;
        data_in = 1'b1; #2000;
        data_in = 1'b0; #2000;

        $display("-- Directed test: rapid bit toggling --");
        for (i = 0; i < 10; i = i + 1) begin
            data_in = i[0];
            #200;
        end

        $display("-- Randomized test: 200 random bits --");
        for (i = 0; i < 200; i = i + 1) begin
            data_in = $random;
            #(($urandom % 1500) + 200);
        end

        $display("-- Reset-recovery test --");
        rst = 1'b1;
        #100;
        rst = 1'b0;
        data_in = 1'b1; #2000;
        data_in = 1'b0; #2000;

        $display("\n=========================================================");
        $display(" VERIFICATION SUMMARY");
        $display("=========================================================");
        $display("  Total cycles checked : %0d", total_checks);
        $display("  Mismatches found     : %0d", mismatch_count);
        if (mismatch_count == 0)
            $display("  RESULT               : *** PASS *** (DUT matches golden model)");
        else
            $display("  RESULT               : *** FAIL *** (%0d mismatches)", mismatch_count);
        $display("=========================================================");

        $finish;
    end

endmodule
