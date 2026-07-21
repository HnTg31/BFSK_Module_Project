# BFSK Modulator — Verilog Project

Binary Frequency Shift Keying (BFSK) modulator implemented in
synthesisable Verilog HDL, with a parallel-to-serial data input
module, full simulation testbenches, and a **golden reference
model** for automated self-checking verification.

---

## File Map

```
bfsk_project/
│
├── bfsk_rtl_complete.v         SUBMISSION FILE — all synthesizable
│                                 RTL modules in one file:
│                                   • data_input_module
│                                   • bfsk_modulator   (flat, DUT)
│                                   • bfsk_top         (top-level)
│                                 (structural FCU/CDU/OTR version
│                                  included as a commented appendix
│                                  for report reference only)
│
├── bfsk_golden_model.v         Verification only — independent
│                                 reference model (not synthesizable)
│
├── bfsk_modulator_tb.v         Manual/waveform testbench
├── bfsk_top_tb.v               Full-system testbench (4 bytes + reset)
├── bfsk_golden_checker_tb.v    SELF-CHECKING: DUT vs golden model
│
└── Makefile
```

> **Note:** This project was consolidated into a single RTL file
> (`bfsk_rtl_complete.v`) for submission. All testbenches compile
> against this one file — there are no separate
> `freq_control_unit.v` / `counter_divider_unit.v` / etc. files
> to manage.

---

## What Is the Golden Model?

`bfsk_golden_model.v` is a **second, independently written**
implementation of the BFSK modulator's expected behaviour, coded
in a different style from the DUT so a shared coding bug is
unlikely to slip through undetected.

`bfsk_golden_checker_tb.v` drives **both** the DUT (`bfsk_modulator`,
inside `bfsk_rtl_complete.v`) and the golden model with identical
stimulus, then compares their outputs **every clock cycle
automatically**:

- Directed test: fixed 6-bit pattern (0,1,0,1,1,0)
- Stress test: rapid bit toggling near divisor boundaries
- Randomized test: 200 random bits with random hold times
- Reset-recovery test: mid-stream reset assertion

```bash
make sim_golden
```

Expected output:
```
=========================================================
 VERIFICATION SUMMARY
=========================================================
  Total cycles checked : 10511
  Mismatches found      : 0
  RESULT                : *** PASS *** (DUT matches golden model)
=========================================================
```

---

## Parameters

| Parameter  | Default | Description                             |
|------------|--------:|------------------------------------------|
| F0_DIV     | 50      | Space freq divisor — bit '0'             |
| F1_DIV     | 25      | Mark  freq divisor — bit '1'             |
| BIT_PERIOD | 2500    | Clock cycles per bit (top-level only)    |

**Frequency formula:**  `f_out = f_clk / (2 × FDIV)`

With a 50 MHz clock:
- F0_DIV = 50 → f0 = **500 kHz**  (space, bit '0')
- F1_DIV = 25 → f1 = **1 MHz**    (mark,  bit '1')

---

## Quick Start

```bash
# Install Icarus Verilog (Ubuntu/Debian)
sudo apt install iverilog gtkwave

# Run all simulations
make all

# Or run individually
make sim_flat     # basic modulator functional test
make sim_top      # full system test with data input module
make sim_golden   # automated self-checking verification (run this first)

# View waveforms
make wave_flat
make wave_top
make wave_golden  # shows DUT output vs golden model output side by side
```

---

## Verified Results

| data_in | Divisor | Output Frequency |
|---------|---------|-------------------|
| '0'     | N0 = 50 | 500 kHz           |
| '1'     | N1 = 25 | 1 MHz             |

Golden-model checker: **0 mismatches across 10,511 cycles**,
including directed, stress, randomized, and reset-recovery tests
— verified directly against `bfsk_rtl_complete.v`.

Top-level bytes transmitted in `bfsk_top_tb.v`:

| Byte | Binary     | Notes            |
|------|------------|-------------------|
| 0xA5 | 1010_0101  | Alternating       |
| 0xFF | 1111_1111  | All mark (f1)     |
| 0x00 | 0000_0000  | All space (f0)    |
| 0xB6 | 1011_0110  | Mixed pattern     |
| 0xCC | 1100_1100  | After reset test  |
