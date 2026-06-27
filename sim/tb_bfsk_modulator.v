`timescale 1ns / 1ps
// =========================================================================
// Module   : tb_bfsk_modulator (Synchronized with Google Colab Golden Model)
// =========================================================================

module tb_bfsk_modulator;

    reg  clk;
    reg  rst;
    reg  data_in;
    wire modulated_out;

    // Instantiate DUT
    bfsk_modulator #(
        .F0_DIV(50), 
        .F1_DIV(25)
    ) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .modulated_out(modulated_out)
    );

    // Tạo xung Clock 50MHz (Chu kỳ T = 20ns)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // Chuỗi 20 bit từ Google Colab: 1,0,1,1,0,0,1,0,1,0,0,1,1,1,0,1,0,0,1,0
    reg [0:19] test_sequence = 20'b10110010100111010010;
    integer i;

    // Kịch bản cấp tín hiệu
    initial begin
        // Khởi tạo hệ thống
        rst = 1;
        data_in = 0;
        #100;
        rst = 0;
        
        $display("--- BAT DAU MO PHONG BFSK ---");
        $display("Toc do truyen: 20 kbps (50 micro-giay / bit)");
        
        // Vòng lặp bơm dữ liệu tự động
        for (i = 0; i < 20; i = i + 1) begin
            data_in = test_sequence[i];
            
            // In log ra màn hình Console để theo dõi
            if (data_in == 1'b1)
                $display("Time: %0t | Truyen Bit %b (Mark - 1 MHz)", $time, test_sequence[i]);
            else
                $display("Time: %0t | Truyen Bit %b (Space - 500 kHz)", $time, test_sequence[i]);
            
            // Delay 50us cho mỗi bit (Vì Baud rate = 20,000 bps -> 1 bit mất 50,000 ns)
            #50000; 
        end

        $display("--- KET THUC MO PHONG ---");
        #1000;
        $stop;
    end

endmodule