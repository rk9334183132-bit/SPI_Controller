# ⚡ Parameterized Multi-Mode SPI Master Controller

![Verilog](https://img.shields.io/badge/Language-Verilog%20HDL-blue)
![Simulation](https://img.shields.io/badge/Simulator-Icarus%20Verilog-orange)
![Waveforms](https://img.shields.io/badge/Viewer-GTKWave-green)
![Design Type](https://img.shields.io/badge/Design-Synthesizable%20IP-brightgreen)

A silicon-grade, fully parameterizable **SPI (Serial Peripheral Interface) Master Controller** subsystem designed in Verilog HDL. This IP features dynamic clock division configuration, variable data-width sizing, and support for all 4 standard SPI operational modes via structural phase lookahead edge synchronization. Includes a fully automated self-checking loopback testbench infrastructure with randomized test vectors.

---

## ◆ Features & Specifications

* **Dynamic Protocol Support:** Fully configures to SPI Mode 0, 1, 2, or 3 dynamically using runtime `CPOL` (Clock Polarity) and `CPHA` (Clock Phase) settings.
* **Parameterized Word Length:** Scalable `DATA_WIDTH` configuration with an automatic internal bit tracker utilizing bit-width optimized registers.
* **Integrated Clock Divider:** Features an internal 16-bit frequency division array to safely step down the high-speed system clock domain to match the target slave.
* **Glitch-Free Gating Matrix:** Eliminates output clock glitches at operational boundaries by managing transitions inside the system clock domain using edge lookahead strobes.
* **Standard Synchronous Handshake:** Implements a lean, deterministic parallel interface (`start`, `ready`, `done`) optimized for simple SoC or bus-wrapper attachment.

---

## ◆ Hardware Timing Waveforms

Since GitHub doesn't render `.vcd` trace files directly, here is the architectural timing relationship demonstrating how the controller shifts and samples bits on the serial lines:

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
```
SPI_Controller/
├── rtl/
│   ├── spi_master.v      # Core SPI protocol state execution engine
│   └── spi_top.v         # Structural system wrapper and port boundary isolation
├── tb/
│   └── spi_tb.v          # Advanced self-checking randomized loopback testbench
├── waveforms/
│   └── spi_trace.vcd     # Generated multi-mode simulation trace file
└── README.md             # Subsystem specification manual
