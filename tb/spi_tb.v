`timescale 1ns / 1ps

module spi_tb;

    parameter TEST_DATA_WIDTH = 8;
    
    reg                        clk;
    reg                        rst_n;
    reg                        cfg_cpol;
    reg                        cfg_cpha;
    reg [15:0]                 cfg_clk_div;
    reg [TEST_DATA_WIDTH-1:0]  sys_tx_data;
    reg                        sys_start;
    
    wire                       sys_ready;
    wire                       sys_done;
    wire [TEST_DATA_WIDTH-1:0] sys_rx_data;
    wire                       spi_sclk;
    wire                       spi_mosi;
    wire                       spi_miso;
    wire                       spi_cs_n;

    integer test_vectors_run  = 0;
    integer test_vectors_pass = 0;
    integer error_count       = 0;
    integer mode_index        = 0;
    
    reg [TEST_DATA_WIDTH-1:0]  tx_shadow_queue;

    spi_top #(.DATA_WIDTH(TEST_DATA_WIDTH)) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .cfg_cpol    (cfg_cpol),
        .cfg_cpha    (cfg_cpha),
        .cfg_clk_div (cfg_clk_div),
        .sys_tx_data (sys_tx_data),
        .sys_start   (sys_start),
        .sys_ready   (sys_ready),
        .sys_done    (sys_done),
        .sys_rx_data (sys_rx_data),
        .spi_sclk    (spi_sclk),
        .spi_mosi    (spi_mosi),
        .spi_miso    (spi_miso),
        .spi_cs_n    (spi_cs_n)
    );

    assign spi_miso = spi_mosi;

    always begin
        #10 clk = ~clk;
    end

    initial begin
        $dumpfile("waveforms/spi_trace.vcd");
        $dumpvars(0, spi_tb);

        clk         = 1'b0;
        rst_n       = 1'b0;
        cfg_cpol    = 1'b0;
        cfg_cpha    = 1'b0;
        cfg_clk_div = 16'd4;
        sys_tx_data = 0;
        sys_start   = 1'b0;

        #40;
        rst_n = 1'b1;
        #20;

        $display("=================================================");
        $display("   STARTING INDUSTRIAL SPI SCOREBOARD CHECKER    ");
        $display("=================================================");

        for (mode_index = 0; mode_index < 4; mode_index = mode_index + 1) begin
            case(mode_index)
                0: begin cfg_cpol = 1'b0; cfg_cpha = 1'b0; $display("\n>>> TESTING SPI MODE 0 (CPOL=0, CPHA=0) <<<"); end
                1: begin cfg_cpol = 1'b0; cfg_cpha = 1'b1; $display("\n>>> TESTING SPI MODE 1 (CPOL=0, CPHA=1) <<<"); end
                2: begin cfg_cpol = 1'b1; cfg_cpha = 1'b0; $display("\n>>> TESTING SPI MODE 2 (CPOL=1, CPHA=0) <<<"); end
                3: begin cfg_cpol = 1'b1; cfg_cpha = 1'b1; $display("\n>>> TESTING SPI MODE 3 (CPOL=1, CPHA=1) <<<"); end
            endcase
            
            #40;

            repeat (5) begin
                wait(sys_ready == 1'b1);
                @(posedge clk);
                
                sys_tx_data     = $urandom % (2**TEST_DATA_WIDTH);
                tx_shadow_queue = sys_tx_data;
                sys_start       = 1'b1;
                
                @(posedge clk);
                sys_start       = 1'b0;
                
                @(posedge sys_done);
                #10;
                
                test_vectors_run = test_vectors_run + 1;
                
                if (sys_rx_data === tx_shadow_queue) begin
                    $display("[SUCCESS] TX Data: %h | RX Data: %h Matched perfectly.", tx_shadow_queue, sys_rx_data);
                    test_vectors_pass = test_vectors_pass + 1;
                end else begin
                    $display("[CRITICAL ERROR] Mismatch found! Expected: %h | Captured: %h", tx_shadow_queue, sys_rx_data);
                    error_count = error_count + 1;
                end
                #40;
            end
        end

        $display("\n=================================================");
        $display("          VERIFICATION EXECUTION COMPLETE        ");
        $display("=================================================");
        $display(" TOTAL TRANSACTIONS EVALUATED: %d", test_vectors_run);
        $display(" TOTAL PASSED VERIFICATIONS  : %d", test_vectors_pass);
        $display(" TOTAL DETECTED ENGINES FAILS: %d", error_count);
        $display("=================================================");
        
        if (error_count == 0 && test_vectors_pass == test_vectors_run) begin
            $display(" >>> FINAL SUBSYSTEM SIMULATION STATUS: PASSED <<<");
        end else begin
            $display(" >>> FINAL SUBSYSTEM SIMULATION STATUS: FAILED <<<");
        end
        $display("=================================================\n");
        
        $finish;
    end

endmodule
