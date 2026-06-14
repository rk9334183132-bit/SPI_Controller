# ⚡ Parameterized Multi-Mode SPI Master Controller

![Verilog](https://img.shields.io/badge/Language-Verilog%20HDL-blue)
![Simulation](https://img.shields.io/badge/Simulator-Icarus%20Verilog-orange)
![Waveforms](https://img.shields.io/badge/Viewer-GTKWave-green)
![License](https://img.shields.io/badge/Design-Synthesizable%20IP-brightgreen)

A silicon-grade, fully parameterizable **SPI (Serial Peripheral Interface) Master Controller** subsystem designed in Verilog HDL. This IP features dynamic clock division configuration, variable data-width sizing, and support for all 4 standard SPI operational modes via structural phase lookahead edge synchronization. Includes a fully automated self-checking loopback testbench infrastructure with randomized test vectors.

---

## 🚀 Key Hardware Features

* **🎛️ Complete 4-Mode Matrix:** Fully supports runtime protocol selection via `CPOL` (Clock Polarity) and `CPHA` (Clock Phase) parameters.
* **📐 Fully Parameterized Data Width:** Scalable hardware word frames (`DATA_WIDTH`) with an auto-scaling internal countdown bit tracker.
* **🕒 Dynamic Clock Divider Matrix:** Integrates a internal 16-bit step counter to derive custom $SCLK$ lines safely from high-speed system oscillators.
* **🚫 Glitch-Free Clock Gating:** Eliminates output clock glitches at startup/shutdown boundaries by processing edges in the system clock domain.
* **🤝 Clean Handshake Pipeline:** Simple structural interface (`start`, `ready`, `done`) designed for direct attachment to SoC bus wrappers.

---

## 📊 Hardware Timing Waveforms

Since GitHub doesn't open `.vcd` files directly, here is how the controller shifts and samples bits based on edge configurations:

### Protocol Timing Mechanics (Mode 0 vs Mode 1)
```text
                    ____   Transaction Active   ___________________________
cs_n               |    \____________________  ...  _______________________/
                        |                    |      |
sclk (Idle Low)    _____|      /---\        /-\     |      /---\
                        \_____/     \______/   \.../______/     \__________
                        |     |     |      |   |    |     |     |
mosi (Mode 0)      XXXXX| Bit 7     | Bit 6    | ...| Bit 0     |XXXXXXXXXX
                        |     |     |      |   |    |     |     |
   [Action M0]          ^Shift      ^Sample    ^Shift     ^Sample   ^Idle
                        |           |          |          |
mosi (Mode 1)      XXXXXXXXXXX\ Bit 7     / Bit 6   ... \ Bit 0 /XXXXXXXXXX
                        |     |     |      |   |    |     |     |
   [Action M1]                ^Shift       ^Sample        ^Shift    ^Sample
SPI_Controller/
├── rtl/
│   ├── spi_master.v      # Core SPI protocol state execution engine
│   └── spi_top.v         # Structural system wrapper and port boundary isolation
├── tb/
│   └── spi_tb.v          # Advanced self-checking randomized loopback testbench
├── waveforms/
│   └── spi_trace.vcd     # Generated multi-mode simulation trace file
└── README.md             # Subsystem specification manual
