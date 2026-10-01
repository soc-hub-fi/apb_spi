// Designed to be used with pulp platforms apb_spi_master

interface apb_interface #(
    parameter int unsigned ADDR_W = 32'd32,
    parameter int unsigned DATA_W = 32'd32
) (
);

    logic                      PCLK;
    logic                      PRESETn;
    logic [ADDR_W-1:0] PADDR;
    logic [DATA_W - 1:0]       PWDATA;
    logic                      PWRITE;
    logic                      PSEL;
    logic                      PENABLE;
    logic [DATA_W - 1:0]       PRDATA;
    logic                      PREADY;
    logic                      PSLVERR;


    modport APB_Master (
        input PRDATA, PREADY, PSLVERR,
        output PCLK, PRESETn, PADDR, PWDATA, PWRITE, PSEL, PENABLE
    );

    modport APB_Slave (
        input PCLK, PRESETn, PADDR, PWDATA, PWRITE, PSEL, PENABLE, 
        output PRDATA, PREADY, PSLVERR
    );

endinterface