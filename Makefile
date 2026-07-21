# =============================================================
# Makefile — BFSK Modulator Project
# RTL Source: bfsk_rtl_complete.v (single consolidated file)
# Tools: Icarus Verilog (iverilog), GTKWave (gtkwave)
#
# Targets:
#   make sim_flat    - Simulate modulator (manual/waveform inspection)
#   make sim_top     - Simulate full top-level system
#   make sim_golden  - Self-checking testbench vs golden model
#   make wave_flat   - Open modulator waveform
#   make wave_top    - Open top-level waveform
#   make wave_golden - Open DUT-vs-golden comparison waveform
#   make all         - Run all simulations
#   make clean       - Remove generated files
# =============================================================

.PHONY: all sim_flat sim_top sim_golden wave_flat wave_top wave_golden clean help

RTL = bfsk_rtl_complete.v

all: sim_flat sim_top sim_golden

sim_flat:
	@echo "\n>>> BFSK Modulator — manual waveform testbench"
	iverilog -o sim_flat_out $(RTL) bfsk_modulator_tb.v
	vvp sim_flat_out
	@echo ">>> VCD: bfsk_modulator.vcd"

sim_top:
	@echo "\n>>> Top-Level System (Data Input Module + Modulator)"
	iverilog -o sim_top_out $(RTL) bfsk_top_tb.v
	vvp sim_top_out
	@echo ">>> VCD: bfsk_top.vcd"

sim_golden:
	@echo "\n>>> Golden Model Verification (DUT vs Reference)"
	iverilog -o sim_golden_out $(RTL) bfsk_golden_model.v bfsk_golden_checker_tb.v
	vvp sim_golden_out
	@echo ">>> VCD: bfsk_golden_check.vcd"

wave_flat:
	gtkwave bfsk_modulator.vcd &

wave_top:
	gtkwave bfsk_top.vcd &

wave_golden:
	gtkwave bfsk_golden_check.vcd &

clean:
	rm -f *.vcd sim_flat_out sim_top_out sim_golden_out

help:
	@echo "BFSK Modulator Project — Makefile targets:"
	@echo "  make sim_flat    Modulator functional testbench"
	@echo "  make sim_top     Full system with Data Input Module"
	@echo "  make sim_golden  Self-checking testbench vs golden model"
	@echo "  make wave_flat   Open bfsk_modulator.vcd in GTKWave"
	@echo "  make wave_top    Open bfsk_top.vcd in GTKWave"
	@echo "  make wave_golden Open bfsk_golden_check.vcd in GTKWave"
	@echo "  make clean       Remove build artefacts"
