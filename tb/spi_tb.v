

// Create Date:    2026
// Module Name:    spi_tb
// Project Name:   SPI Controller Subsystem
// Description:    Basic Testbench for testing Phase 1 Core SPI Master (Mode 0).
// =============================================================================

`timescale 1ns / 1ps

module spi_tb;

    // Testbench Signals
    reg        clk;
    reg        rst_n;
    reg  [7:0] tx_data;
    reg        start;
    wire       ready;
    wire       done;
    wire [7:0] rx_data;
    wire       sclk;
    wire       mosi;
    reg        miso;
    wire       cs_n;

    // Instantiate the Device Under Test (DUT)
    spi_master uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .tx_data (tx_data),
        .start   (start),
        .ready   (ready),
        .done    (done),
        .rx_data (rx_data),
        .sclk    (sclk),
        .mosi    (mosi),
        .miso    (miso),
        .cs_n    (cs_n)
    );

    // 1. Clock Generation: 50 MHz clock (Period = 20ns)
    always begin
        #10 clk = ~clk;
    end

    // 2. Stimulus Generation
    initial begin
        // Setup waveform dumping for GTKWave/EDA Playground
        $dumpfile("waveforms/spi_trace.vcd");
        $dumpvars(0, spi_tb);

        // Initialize inputs
        clk     = 1'b0;
        rst_n   = 1'b0;
        tx_data = 8'h00;
        start   = 1'b0;
        miso    = 1'b0;

        // Apply Reset for 40ns
        #40;
        rst_n = 1'b1;
        #20;

        // Wait until master is ready
        wait(ready == 1'b1);
        #10;

        // Transaction 1: Send Data 8'hA5 (Binary: 10100101)
        tx_data = 8'hA5; 
        start   = 1'b1;   // Assert start pulse
        #20;
        start   = 1'b0;   // Deassert start pulse

        // Simulating incoming MISO data from a slave device
        // We change MISO on falling edges of SCLK so Master can safely sample on rising edges.
        @(negedge sclk) miso = 1'b1; // bit 7
        @(negedge sclk) miso = 1'b0; // bit 6
        @(negedge sclk) miso = 1'b1; // bit 5
        @(negedge sclk) miso = 1'b1; // bit 4
        @(negedge sclk) miso = 1'b0; // bit 3
        @(negedge sclk) miso = 1'b0; // bit 2
        @(negedge sclk) miso = 1'b1; // bit 1
        @(negedge sclk) miso = 1'b0; // bit 0 (Final sample)

        // Wait for the Master to complete the transfer
        @(posedge done);
        #40;

        $display("[TB SUCCESS] Transfer completed. Received Data: %h", rx_data);
        $finish;
    end

endmodule