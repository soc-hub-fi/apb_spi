

module vip_apb_driver #( 
    parameter int unsigned ADDR_W = 32'd32,
    parameter int unsigned DATA_W = 32'd32
) (
  input logic clk,
  apb_interface.APB_Master apb_mst
);
  assign apb_mst.PCLK = clk;

  localparam time TA = 2ns; // after clk edge, when values are driven
  localparam time TT = 8ns; // after clk edgewhen values are read/sampled

// this task reads from an APB4 slave, acts as master
    task read(
      input  logic [11:0] addr,
      output  logic [31:0] data,
    );
      
      apb_mst.PADDR   = #TA addr;
      apb_mst.PWRITE  = #TA 1'b0;
      apb_mst.PSEL    = #TA 1'b1;
      apb_mst.PENABLE = #TA 1'b1;

      while (!apb_mst.PREADY) begin
        // Wait for clk edge and proceed to evaluation time "TT"
        @(posedge clk);
        #TT;
      end

      data  = apb_mst.PRDATA;
      @(posedge clk);
      apb_mst.PADDR   = #TA '0;
      apb_mst.PSEL    = #TA 1'b0;
      apb_mst.PENABLE = #TA 1'b0;
     
    endtask

     // this task writes to an APB4 slave, acts as master
    task write(
      input  logic [11:0] addr,
      input  logic [31:0] data,
    );
      
      apb_mst.PADDR   = #TA addr;
      apb_mst.PWDATA  = #TA data;
      apb_mst.PWRITE  = #TA 1'b1;
      apb_mst.PSEL    = #TA 1'b1;
      @(posedge clk);
      apb_mst.PENABLE = #TA 1'b1;
      #TT;

      while (!apb_mst.PREADY) begin
        // Wait for clk edge and proceed to evaluation time "TT"
        @(posedge clk);
        #TT;
      end
      apb_mst.PENABLE = #TA 1'b0;
      @(posedge clk);
      apb_mst.PADDR   = #TA '0;
      apb_mst.PWDATA  = #TA '0;
      apb_mst.PWRITE  = #TA 1'b0;
      apb_mst.PSEL    = #TA 1'b0;

    endtask

endmodule : vip_apb_driver