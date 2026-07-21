// =============================================================
// Module   : bfsk_modulator_tb.v
// Function : Testbench for bfsk_modulator
//            (defined inside bfsk_rtl_complete.v)
//
// Compile together with bfsk_rtl_complete.v:
//   iverilog -o sim bfsk_rtl_complete.v bfsk_modulator_tb.v
// =============================================================

`timescale 1ns / 1ps

module bfsk_modulator_tb;

    reg  clk;
    reg  rst;
    reg  data_in;
    wire modulated_out;

    bfsk_modulator #(
        .F0_DIV (8'd50),
        .F1_DIV (8'd25)
    ) u_dut (
        .clk           (clk),
        .rst           (rst),
        .data_in       (data_in),
        .modulated_out (modulated_out)
    );

    initial  clk = 1'b0;
    always   #10 clk = ~clk;

    initial begin
        $timeformat(-9, 0, " ns", 10);
        $dumpfile("bfsk_modulator.vcd");
        $dumpvars(0, bfsk_modulator_tb);
    end

    initial begin
        $monitor("TIME=%0t | rst=%b | data_in=%b | modulated_out=%b",
                 $time, rst, data_in, modulated_out);
    end

    initial begin
        $display("=== BFSK Modulator Testbench Start ===");

        rst      = 1'b1;
        data_in  = 1'b0;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;

        data_in = 1'b0;  #2000;
        data_in = 1'b1;  #2000;
        data_in = 1'b0;  #2000;
        data_in = 1'b1;  #2000;
        data_in = 1'b1;  #2000;
        data_in = 1'b0;  #2000;

        rst = 1'b1;  #100;
        rst = 1'b0;

        data_in = 1'b1;  #2000;
        data_in = 1'b0;  #2000;

        $display("=== BFSK Modulator Testbench End ===");
        $finish;
    end

    real last_edge_ns, curr_edge_ns, period_ns;
    initial last_edge_ns = 0.0;

    always @(posedge modulated_out) begin
        curr_edge_ns = $realtime;
        if (last_edge_ns > 0.0) begin
            period_ns = curr_edge_ns - last_edge_ns;
            $display("  [CHECK] t=%.0f ns | Full-period=%.0f ns | f_out=%.0f kHz | data_in=%b",
                curr_edge_ns, period_ns,
                (period_ns > 0) ? (1_000_000.0 / period_ns) : 0.0,
                data_in);
        end
        last_edge_ns = curr_edge_ns;
    end

endmodule
