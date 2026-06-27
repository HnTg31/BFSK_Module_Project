# Xóa thư viện cũ
if {[file exists work]} {
    vdel -lib work -all
}

# Tạo thư viện mới
vlib work
vmap work work

# Compile files
vlog -work work bfsk_modulator.v
vlog -work work tb_bfsk_modulator.v

# Khởi chạy mô phỏng
vsim -voptargs=+acc work.tb_bfsk_modulator

# --- Cấu hình Waveform ---
add wave -noupdate -divider -height 25 "System Signals"
add wave -noupdate -color White /tb_bfsk_modulator/clk
add wave -noupdate -color Red /tb_bfsk_modulator/rst

add wave -noupdate -divider -height 25 "Data & Modulated Output"
add wave -noupdate -color Green -radix binary /tb_bfsk_modulator/data_in
add wave -noupdate -color Cyan -radix binary /tb_bfsk_modulator/modulated_out

add wave -noupdate -divider -height 25 "Internal RTL States"
add wave -noupdate -color Orange -radix unsigned /tb_bfsk_modulator/uut/counter
add wave -noupdate -color Yellow -radix unsigned /tb_bfsk_modulator/uut/active_N
add wave -noupdate -color {Violet Red} -radix unsigned /tb_bfsk_modulator/uut/target_N

# Setup hiển thị
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -datasetprefix 0
configure wave -rowmargin 4

# Chạy mô phỏng và Zoom
run -all
wave zoom full