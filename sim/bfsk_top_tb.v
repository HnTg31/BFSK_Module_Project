// =============================================================
// Module   : bfsk_top_tb.v
// Function : Testbench for bfsk_top (full system)
//            (defined inside bfsk_rtl_complete.v)
//
// Compile together with bfsk_rtl_complete.v:
//   iverilog -o sim bfsk_rtl_complete.v bfsk_top_tb.v
// =============================================================

`timescale 1ns / 1ps

module bfsk_top_tb;

    reg         clk;
    reg         rst;
    reg  [7:0]  parallel_data;
    reg         load;
    wire        modulated_out;
    wire        tx_busy;
    wire        tx_done;

    bfsk_top #(
        .F0_DIV     (8'd50),
        .F1_DIV     (8'd25),
        .BIT_PERIOD (16'd100)
    ) u_dut (
        .clk           (clk),
        .rst           (rst),
        .parallel_data (parallel_data),
        .load          (load),
        .modulated_out (modulated_out),
        .tx_busy       (tx_busy),
        .tx_done       (tx_done)
    );

    initial  clk = 1'b0;
    always   #10 clk = ~clk;

    initial begin
        $dumpfile("bfsk_top.vcd");
        $dumpvars(0, bfsk_top_tb);
    end

    initial begin
        $monitor("TIME=%0t | load=%b | busy=%b | done=%b | out=%b",
                 $time, load, tx_busy, tx_done, modulated_out);
    end

    task send_byte;
        input [7:0] byte_val;
        begin
            $display("\n--- Sending byte: 0x%02X (%08b) ---", byte_val, byte_val);
            @(negedge clk);
            parallel_data = byte_val;
            load          = 1'b1;
            @(posedge clk);
            @(negedge clk);
            load          = 1'b0;
            @(posedge tx_done);
            $display("--- Byte 0x%02X transmission done at t=%0t ns ---", byte_val, $time);
            #200;
        end
    endtask

    initial begin
        $display("========================================");
        $display("  BFSK Top-Level Testbench Start");
        $display("========================================");

        rst           = 1'b1;
        load          = 1'b0;
        parallel_data = 8'h00;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;
        #50;

        send_byte(8'hA5);
        send_byte(8'hFF);
        send_byte(8'h00);
        send_byte(8'hB6);

        $display("\n--- Testing mid-transmission reset ---");
        parallel_data = 8'h55;
        load          = 1'b1;
        @(posedge clk);
        load = 1'b0;
        #500;
        rst  = 1'b1;
        @(posedge clk);
        rst  = 1'b0;
        #200;

        send_byte(8'hCC);

        $display("\n========================================");
        $display("  BFSK Top-Level Testbench Complete");
        $display("========================================");
        $finish;
    end

endmodule
