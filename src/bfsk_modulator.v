`timescale 1ns / 1ps
// =========================================================================
// Module   : bfsk_modulator (Advanced Architecture - Glitch Free)
// Nhóm     : 5
// System   : Master Clock 50MHz | Tín hiệu ra: Sóng vuông (Square Wave)
// =========================================================================

module bfsk_modulator #(
    parameter F0_DIV = 8'd50, // f0 = 500 kHz (Bit 0) -> Đếm 50 nhịp
    parameter F1_DIV = 8'd25  // f1 = 1 MHz (Bit 1)   -> Đếm 25 nhịp
)(
    input  wire clk,           // Xung nhịp hệ thống 50MHz
    input  wire rst,           // Reset đồng bộ (Active High)
    input  wire data_in,       // Dữ liệu nhị phân đầu vào
    output reg  modulated_out  // Ngõ ra điều chế BFSK
);

    // Thanh ghi nội bộ
    reg [7:0] counter;
    reg [7:0] active_N; // Shadow Register (IQ200: Chống Glitch)
    
    // Combinational Logic: Tính toán N mục tiêu dựa trên data_in
    wire [7:0] target_N;
    assign target_N = (data_in == 1'b1) ? F1_DIV : F0_DIV;

    // Synchronous Logic
    always @(posedge clk) begin
        if (rst) begin
            counter       <= 8'd0;
            active_N      <= F0_DIV; // Mặc định khởi tạo là f0
            modulated_out <= 1'b0;
        end else begin
            // BƯỚC 1: CHỐT HỆ SỐ TẦN SỐ (Shadow Register Logic)
            // Chỉ cập nhật tần số mới khi counter bắt đầu chu kỳ mới (counter == 0)
            if (counter == 8'd0) begin
                active_N <= target_N;
            end

            // BƯỚC 2: BỘ ĐẾM VÀ TẠO SÓNG (Divider & Toggle Logic)
            // Sử dụng active_N thay vì target_N để tránh xung rác
            if (counter >= (active_N - 1)) begin
                counter       <= 8'd0;
                modulated_out <= ~modulated_out; // Đảo trạng thái tạo sóng vuông
            end else begin
                counter       <= counter + 8'd1;
            end
        end
    end

endmodule