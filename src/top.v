module top (
    input  ext_clk,    // Chân thạch anh 27MHz vật lý trên board
    input  btn_rst,    // Nút nhấn S1 trên board (Ấn vào = mức 0)
    input  btn_data,   // Nút nhấn S2 cấp dữ liệu (Ấn vào = mức 0)
    output led_fsk,    // Đèn LED1 chớp tắt theo sóng FSK để quan sát
    output led_lock,   // Đèn LED2 sáng để báo hiệu PLL đã nhân tần ổn định
    output out_fsk     // Xuất sóng FSK ra chân Header IO chân 38 để đo đạc
);

    wire clk_50m;      // Đường clock 50.14MHz sau khi qua rPLL
    wire pll_lock;     // Tín hiệu báo rPLL đã khóa tần số thành công
    wire sys_rst;      // Reset đồng bộ (Active High)
    wire sys_data;     // Dữ liệu sau khi đảo logic nút nhấn

    // Nút nhấn vật lý trên Tang Nano 9K mặc định là Active Low (Thả ra = 1, Ấn vào = 0)
    // Ta đảo logic (~ ) để chuyển về Active High cho đúng với thiết kế lý thuyết ban đầu
    assign sys_rst  = ~btn_rst;  
    assign sys_data = ~btn_data; 

    // 1. Gọi bộ nhân tần số rPLL (Cú pháp khớp chính xác với file Gowin vừa tự sinh)
    Gowin_rPLL u_pll (
        .clkout(clk_50m),     // Xuất xung nhịp ~50MHz cấp cho lõi FSK
        .clkin(ext_clk),      // Nhận xung nhịp 27MHz từ thạch anh
        .lock(pll_lock)       // Xuất tín hiệu báo trạng thái ổn định
    );

    // 2. Gọi bộ điều chế lõi BFSK Modulator của nhóm 5
    bfsk_modulator u_bfsk (
        .clk(clk_50m),
        .rst(sys_rst),
        .data_in(sys_data),
        .modulated_out(out_fsk)
    );

    // 3. Hiển thị trạng thái hoạt động lên hệ thống đèn LED của Board
    assign led_fsk  = ~out_fsk;  // LED1 chớp tắt theo nhịp sóng FSK (LED sáng ở mức 0)
    assign led_lock = ~pll_lock; // LED2 sáng cố định khi PLL đã "khóa" tần số 50MHz thành công

endmodule