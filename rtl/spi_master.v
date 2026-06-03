// =============================================================================
// Company:        Targeting RTL/VLSI Internships
// Engineer:       Your Name
// 
// Create Date:    2026
// Module Name:    spi_master
// Project Name:   SPI Controller Subsystem
// Target Devices: Synthesizable FPGAs / ASICs
// Description:    Core SPI Master supporting 8-bit transfers in SPI Mode 0 
//                 (CPOL = 0, CPHA = 0).
// =============================================================================

module spi_master (
    input  wire       clk,          // System Clock
    input  wire       rst_n,        // Asynchronous Active-Low Reset
    
    // User/System Interface
    input  wire [7:0] tx_data,      // Parallel Data to transmit
    input  wire       start,        // Kickstart transfer trigger
    output reg        ready,        // Transmitter is ready for new data
    output reg        done,         // Pulse indicating transfer completion
    output reg  [7:0] rx_data,      // Parallel Data received
    
    // SPI Physical Interface
    output reg        sclk,         // SPI Serial Clock
    output reg        mosi,         // Master Output Slave Input
    input  wire       miso,         // Master Input Slave Output
    output reg        cs_n          // Chip Select (Active Low)
);

    // Finite State Machine (FSM) States
    localparam IDLE   = 2'b00;
    localparam LEAD   = 2'b01; // Setup time before SCLK starts
    localparam TRAIL  = 2'b10; // Hold time after SCLK ends

    reg [1:0] state;
    reg [2:0] bit_cnt;         // Tracks 0 to 7 bits
    reg [7:0] shift_reg_tx;    // Internal TX Shift Register
    reg [7:0] shift_reg_rx;    // Internal RX Shift Register
    reg       sclk_en;         // Enables SCLK generation
    reg       clk_div;         // Simple toggle for SCLK generation (Sys_Clk / 2)

    // -------------------------------------------------------------------------
    // 1. Clock Generation (Simple Divider for Mode 0)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 1'b0;
        end else if (sclk_en) begin
            clk_div <= ~clk_div;
        end else begin
            clk_div <= 1'b0;
        end
    end

    // In Mode 0, SCLK is idle low.
    always @(*) begin
        sclk = clk_div;
    end

    // Detect internal SCLK edges for shifting and sampling
    wire sclk_rising  = (sclk_en && !clk_div &&  ~clk_div); // Lookahead for rising edge
    wire sclk_falling = (sclk_en &&  clk_div &&   clk_div); // Lookahead for falling edge

    // -------------------------------------------------------------------------
    // 2. Core FSM and Control Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            ready        <= 1'b1;
            done         <= 1'b0;
            cs_n         <= 1'b1;
            sclk_en      <= 1'b0;
            bit_cnt      <= 3'd0;
            shift_reg_tx <= 8'h00;
            shift_reg_rx <= 8'h00;
            rx_data      <= 8'h00;
            mosi         <= 1'b0;
        end else begin
            done <= 1'b0; // Default pulse

            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    cs_n  <= 1'b1;
                    mosi  <= 1'b0;
                    if (start) begin
                        ready        <= 1'b0;
                        cs_n         <= 1'b0;
                        shift_reg_tx <= tx_data;
                        state        <= LEAD;
                    end
                end

                LEAD: begin
                    // Drive first MSB bit right away (Mode 0 setup)
                    mosi    <= shift_reg_tx[7];
                    sclk_en <= 1'b1;
                    
                    // Synchronize state transition with the clock generation
                    if (clk_div == 1'b1) begin 
                        bit_cnt <= 3'd7;
                        state   <= TRAIL;
                    end
                end

                TRAIL: begin
                    // Mode 0: Sample MISO on Rising Edge
                    if (sclk_en && !clk_div) begin 
                        shift_reg_rx <= {shift_reg_rx[6:0], miso};
                    end
                    
                    // Mode 0: Shift/Drive MOSI on Falling Edge
                    if (sclk_en && clk_div) begin
                        if (bit_cnt == 3'd0) begin
                            sclk_en <= 1'b0;
                            cs_n    <= 1'b1;
                            done    <= 1'b1;
                            rx_data <= {shift_reg_rx[6:0], miso}; // Capture final bit
                            state   <= IDLE;
                        end else begin
                            bit_cnt      <= bit_cnt - 1'b1;
                            shift_reg_tx <= {shift_reg_tx[6:0], 1'b0};
                            mosi         <= shift_reg_tx[6]; 
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule