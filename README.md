# Parameterized Multi-Mode SPI Master Controller

## Overview
This repository contains a silicon-grade, fully synthesizable **SPI (Serial Peripheral Interface) Master Controller** implemented in Verilog HDL. Designed with industry-standard digital design methodologies, the controller features full parameterization of data width, dynamic clock division, and runtime support for all four standard SPI modes (Modes 0, 1, 2, and 3). 

A comprehensive self-checking, loopback-enabled testbench environment is included to automate verification across all mode matrices using randomized stimulus.

## Key Hardware Features
* **Full SPI Mode Support:** Configurable Clock Polarity (`CPOL`) and Clock Phase (`CPHA`) parameters supporting Mode 0, Mode 1, Mode 2, and Mode 3.
* **Fully Parameterized Data Width:** Scalable `DATA_WIDTH` supporting standard 8, 16, 32, or custom bit lengths.
* **Dynamic Clock Divider:** A 16-bit parameterizable internal clock divider allowing safe SCLK derivation from high-frequency system clocks.
* **Robust FSM Control:** Clean 3-state Finite State Machine (`IDLE`, `TRANSFER`, `TRAILING`) utilizing safe lookahead strobe triggers for clock edge detection to eliminate glitching.
* **Clean Handshaking Interface:** Handshake signals (`start`, `ready`, `done`) simplify connection to a system-level SoC bus wrapper.

---

## Architecture Block Diagram

```text
       +-----------------------------------------------------------------------+
       |                              spi_top                                  |
       |                                                                       |
       |   -- cfg_cpol ----------> +-------------------------------------+     |
       |   -- cfg_cpha ----------> |             spi_master              |     |
       |   -- cfg_clk_div -------> |             (Core Engine)           |     |
       |                           |                                     |     |
       |   -- sys_tx_data [7:0] -> |  +---------------+                  |     |
       |   -- sys_start ---------> |  | Shift Reg TX  | ---> mosi -------|------> (To Slave)
       |   <- sys_ready ---------- |  +---------------+                  |     |
       |   <- sys_done ----------- |                                     |     |
       |   <- sys_rx_data [7:0] -- |  +---------------+                  |     |
       |                           |  | Shift Reg RX  | <--- miso -------|------- (From Slave)
       |                           |  +---------------+                  |     |
       |                           |                                     |     |
       |   -- clk ---------------> |  +---------------+                  |     |
       |   -- rst_n -------------> |  | Clock Divider | ---> sclk -------|------> (To Slave)
       |                           |  +---------------+                  |     |
       |                           |                                     |     |
       |                           |  +---------------+                  |     |
       |                           |  |  Control FSM  | ---> cs_n -------|------> (To Slave)
       |                           |  +---------------+                  |     |
       |                           +-------------------------------------+     |
       +-----------------------------------------------------------------------+
