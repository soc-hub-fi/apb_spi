// Designed to be used with pulp platforms apb_spi_master

interface spi_interface #(
    parameter int unsigned ADDR_W = 32'd32,
    parameter int unsigned DATA_W = 32'd32
) (
    input logic clk
);

    logic                   spi_clk;
    logic                   spi_csn0;
    logic                   spi_sdo0;
    logic                   spi_sdi0;

    modport SPI_Master (
        input spi_sdi0,
        output spi_clk,
        output spi_csn0,
        output spi_sdo0
    );

    // Note APB_SPI_master has more spi signals but the sd card uses only a few.
    modport SPI_Slave (
        input spi_clk,
        input spi_csn0,
        input spi_sdo0,
        output spi_sdi0
    );

endinterface