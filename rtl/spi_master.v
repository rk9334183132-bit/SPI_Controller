module spi_master #(
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    cpol,
    input  wire                    cpha,
    input  wire [15:0]             clk_div,
    input  wire [DATA_WIDTH-1:0]   tx_data,
    input  wire                    start,
    output reg                     ready,
    output reg                     done,
    output reg  [DATA_WIDTH-1:0]   rx_data,
    output reg                     sclk,
    output reg                     mosi,
    input  wire                    miso,
    output reg                     cs_n
);

    localparam IDLE     = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam TRAILING = 2'b10;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [$clog2(DATA_WIDTH+1)-1:0] bit_cnt;

    reg [DATA_WIDTH-1:0] shift_reg_tx;
    reg [DATA_WIDTH-1:0] shift_reg_rx;
    
    reg spi_clk_reg;
    reg last_sclk;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt     <= 16'd0;
            spi_clk_reg <= 1'b0;
        end else if (state != IDLE) begin
            if (clk_cnt >= (clk_div - 1'b1)) begin
                clk_cnt     <= 16'd0;
                spi_clk_reg <= ~spi_clk_reg;
            end else begin
                clk_cnt     <= clk_cnt + 1'b1;
            end
        end else begin
            clk_cnt     <= 16'd0;
            spi_clk_reg <= cpol;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_sclk <= 1'b0;
        end else begin
            last_sclk <= spi_clk_reg;
        end
    end

    wire rising_edge  = (last_sclk == 1'b0 && spi_clk_reg == 1'b1);
    wire falling_edge = (last_sclk == 1'b1 && spi_clk_reg == 1'b0);

    wire sample_edge = (cpha == 1'b0) ? 
                       ((cpol == 1'b0) ? rising_edge  : falling_edge) : 
                       ((cpol == 1'b0) ? falling_edge : rising_edge);

    wire shift_edge  = (cpha == 1'b0) ? 
                       ((cpol == 1'b0) ? falling_edge : rising_edge) : 
                       ((cpol == 1'b0) ? rising_edge  : falling_edge);

    always @(*) begin
        if (cs_n)
            sclk = cpol;
        else
            sclk = spi_clk_reg;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            ready        <= 1'b1;
            done         <= 1'b0;
            cs_n         <= 1'b1;
            mosi         <= 1'b0;
            bit_cnt      <= 0;
            shift_reg_tx <= 0;
            shift_reg_rx <= 0;
            rx_data      <= 0;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    cs_n  <= 1'b1;
                    mosi  <= 1'b0;
                    
                    if (start) begin
                        ready        <= 1'b0;
                        cs_n         <= 1'b0;
                        shift_reg_tx <= tx_data;
                        bit_cnt      <= DATA_WIDTH;
                        
                        if (cpha == 1'b0) begin
                            mosi <= tx_data[DATA_WIDTH-1];
                        end
                        state <= TRANSFER;
                    end
                end

                TRANSFER: begin
                    if (sample_edge) begin
                        shift_reg_rx <= {shift_reg_rx[DATA_WIDTH-2:0], miso};
                        if (cpha == 1'b1) begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end

                    if (shift_edge) begin
                        if (cpha == 1'b0) begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                        
                        if ((cpha == 1'b0 && bit_cnt == 1) || (cpha == 1'b1 && bit_cnt == 0)) begin
                            state <= TRAILING;
                        end else begin
                            if (cpha == 1'b0) begin
                                shift_reg_tx <= {shift_reg_tx[DATA_WIDTH-2:0], 1'b0};
                                mosi         <= shift_reg_tx[DATA_WIDTH-2];
                            end else begin
                                mosi         <= shift_reg_tx[DATA_WIDTH-1];
                                shift_reg_tx <= {shift_reg_tx[DATA_WIDTH-2:0], 1'b0};
                            end
                        end
                    end
                end

                TRAILING: begin
                    if (clk_cnt == (clk_div - 1'b1)) begin
                        cs_n    <= 1'b1;
                        done    <= 1'b1;
                        ready   <= 1'b1;
                        rx_data <= shift_reg_rx;
                        mosi    <= 1'b0;
                        state   <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
