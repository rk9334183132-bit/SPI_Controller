module spi_top #(
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    cfg_cpol,
    input  wire                    cfg_cpha,
    input  wire [15:0]             cfg_clk_div,
    input  wire [DATA_WIDTH-1:0]   sys_tx_data,
    input  wire                    sys_start,
    output wire                    sys_ready,
    output wire                    sys_done,
    output wire [DATA_WIDTH-1:0]   sys_rx_data,
    output wire                    spi_sclk,
    output wire                    spi_mosi,
    input  wire                    spi_miso,
    output wire                    spi_cs_n
);

    spi_master #(.DATA_WIDTH(DATA_WIDTH)) spi_core_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .cpol    (cfg_cpol),
        .cpha    (cfg_cpha),
        .clk_div (cfg_clk_div),
        .tx_data (sys_tx_data),
        .start   (sys_start),
        .ready   (sys_ready),
        .done    (sys_done),
        .rx_data (sys_rx_data),
        .sclk    (spi_sclk),
        .mosi    (spi_mosi),
        .miso    (spi_miso),
        .cs_n    (spi_cs_n)
    );

endmodule
