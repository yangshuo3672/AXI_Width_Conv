// =============================================================================
// Module      : ktp_uif2axi
// Description : UIF-64 master-side adapter to AXI4/ACE-Lite 64-bit master.
//               UIF combines AW and W on the first write beat. This module
//               splits that format back to AXI AW and W channels.
// =============================================================================

`timescale 1ns/1ps

module ktp_uif2axi #(
  parameter int ID_WIDTH   = 8,
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 64,
  parameter int STRB_WIDTH = DATA_WIDTH / 8,
  parameter int USER_WIDTH = 16
) (
  input  logic                    aclk,
  input  logic                    aresetn,

  // UIF write request channel.
  input  logic                    uaww_valid,
  output logic                    uaww_ready,
  input  logic [ID_WIDTH-1:0]     uawid,
  input  logic [ADDR_WIDTH-1:0]   uawaddr,
  input  logic [3:0]              uawlen,
  input  logic [2:0]              uawsize,
  input  logic [1:0]              uawburst,
  input  logic                    uawlock,
  input  logic [3:0]              uawcache,
  input  logic [2:0]              uawprot,
  input  logic [USER_WIDTH-1:0]   uawuser,
  input  logic [3:0]              uawqos,
  input  logic [3:0]              uawregion,
  input  logic [1:0]              uawdomain,
  input  logic [2:0]              uawsnoop,
  input  logic [1:0]              uawbar,
  input  logic [DATA_WIDTH-1:0]   uwdata,
  input  logic [STRB_WIDTH-1:0]   uwstrb,
  input  logic [USER_WIDTH-1:0]   uwuser,
  input  logic                    uwlast,

  // UIF write response channel.
  output logic                    ub_valid,
  input  logic                    ub_ready,
  output logic [ID_WIDTH-1:0]     ubid,
  output logic [USER_WIDTH-1:0]   ubuser,
  output logic [1:0]              ubresp,

  // UIF read address channel.
  input  logic                    uar_valid,
  output logic                    uar_ready,
  input  logic [ID_WIDTH-1:0]     uarid,
  input  logic [ADDR_WIDTH-1:0]   uaraddr,
  input  logic [3:0]              uarlen,
  input  logic [2:0]              uarsize,
  input  logic [1:0]              uarburst,
  input  logic                    uarlock,
  input  logic [3:0]              uarcache,
  input  logic [2:0]              uarprot,
  input  logic [USER_WIDTH-1:0]   uaruser,
  input  logic [3:0]              uarqos,
  input  logic [3:0]              uarregion,
  input  logic [1:0]              uardomain,
  input  logic [3:0]              uarsnoop,
  input  logic [1:0]              uarbar,

  // UIF read data channel.
  output logic                    ur_valid,
  input  logic                    ur_ready,
  output logic                    urlast,
  output logic [ID_WIDTH-1:0]     urid,
  output logic [DATA_WIDTH-1:0]   urdata,
  output logic [USER_WIDTH-1:0]   uruser,
  output logic [1:0]              urresp,

  // AXI master read address channel.
  output logic                    arvalid_m,
  input  logic                    arready_m,
  output logic [ID_WIDTH-1:0]     arid_m,
  output logic [ADDR_WIDTH-1:0]   araddr_m,
  output logic [3:0]              arlen_m,
  output logic [2:0]              arsize_m,
  output logic [1:0]              arburst_m,
  output logic                    arlock_m,
  output logic [3:0]              arcache_m,
  output logic [2:0]              arprot_m,
  output logic [USER_WIDTH-1:0]   aruser_m,
  output logic [3:0]              arqos_m,
  output logic [3:0]              arregion_m,
  output logic [1:0]              ardomain_m,
  output logic [3:0]              arsnoop_m,
  output logic [1:0]              arbar_m,

  // AXI master read data channel.
  input  logic                    rvalid_m,
  output logic                    rready_m,
  input  logic                    rlast_m,
  input  logic [ID_WIDTH-1:0]     rid_m,
  input  logic [DATA_WIDTH-1:0]   rdata_m,
  input  logic [USER_WIDTH-1:0]   ruser_m,
  input  logic [1:0]              rresp_m,

  // AXI master write address channel.
  output logic                    awvalid_m,
  input  logic                    awready_m,
  output logic [ID_WIDTH-1:0]     awid_m,
  output logic [ADDR_WIDTH-1:0]   awaddr_m,
  output logic [3:0]              awlen_m,
  output logic [2:0]              awsize_m,
  output logic [1:0]              awburst_m,
  output logic                    awlock_m,
  output logic [3:0]              awcache_m,
  output logic [2:0]              awprot_m,
  output logic [USER_WIDTH-1:0]   awuser_m,
  output logic [3:0]              awqos_m,
  output logic [3:0]              awregion_m,
  output logic [1:0]              awdomain_m,
  output logic [2:0]              awsnoop_m,
  output logic [1:0]              awbar_m,

  // AXI master write data channel.
  output logic                    wvalid_m,
  input  logic                    wready_m,
  output logic                    wlast_m,
  output logic [DATA_WIDTH-1:0]   wdata_m,
  output logic [STRB_WIDTH-1:0]   wstrb_m,
  output logic [USER_WIDTH-1:0]   wuser_m,

  // AXI master write response channel.
  input  logic                    bvalid_m,
  output logic                    bready_m,
  input  logic [ID_WIDTH-1:0]     bid_m,
  input  logic [USER_WIDTH-1:0]   buser_m,
  input  logic [1:0]              bresp_m
);


  localparam int AW_W = ID_WIDTH + ADDR_WIDTH + 4 + 3 + 2 + 1 + 4 + 3
                      + USER_WIDTH + 4 + 4 + 2 + 3 + 2;                 
  localparam int W_W  = DATA_WIDTH + STRB_WIDTH + USER_WIDTH + 1;   

  logic uif_first_write_beat;
  logic uif_write_fire;
  logic aw_skid_ready_o;
  logic w_skid_ready_o;
  
always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        uif_first_write_beat <= 1'b1;
    end
    else if (uwlast && uif_write_fire) begin
        uif_first_write_beat <= 1'b1;
    end
    else if(uif_first_write_beat && uif_write_fire)begin
        uif_first_write_beat <= 1'b0;
    end
    else begin
        uif_first_write_beat <= uif_first_write_beat;
    end
end
  
assign uaww_ready = uif_first_write_beat ? (aw_skid_ready_o && w_skid_ready_o) : w_skid_ready_o; //(!aw_fifo_full && !w_fifo_full) : (!w_fifo_full);
assign uif_write_fire = uaww_valid && uaww_ready;

logic [AW_W-1:0] aw_skid_din;
logic [AW_W-1:0] aw_skid_dout;
logic [W_W-1:0]  w_skid_din;
logic [W_W-1:0]  w_skid_dout;

assign { awid_m, awaddr_m, awlen_m, awsize_m, awburst_m, awlock_m, awcache_m,awprot_m,awuser_m, awqos_m, awregion_m, awdomain_m, awsnoop_m, awbar_m } = aw_skid_dout;
assign { wdata_m, wstrb_m, wuser_m, wlast_m } = w_skid_dout;

assign aw_skid_din = { uwid, uawaddr, uawlen, uawsize, uawburst, uawlock, uawcache,uawprot, uawuser, uawqos, uawregion, uawdomain, uawsnoop, uawbar };
assign w_skid_din = { uwdata, uwstrb, uwuser, uwlast };

assign awsize_m = 3'd3;
assign awburst_m = 2'd1;
assign awlock_m = 1'd0;
assign wstrb_m = 8'hff;

//out skid buffer
wire aw_skid_valid_i = uif_first_write_beat && uif_write_fire;
wire w_skid_valid_i = uaww_valid && uif_write_fire;

ktp_skid_buffer #(
    .WIDTH(AW_W)
)u_aw_skid_buffer(
    .clk        (aclk),
    .resetn     (aresetn),
    //skid upstream
    .valid_i    (aw_skid_valid_i ),
    .ready_o    (aw_skid_ready_o),
    .data_i     (aw_skid_din),
    //skid downstream
    .valid_o    (awvalid_m),
    .ready_i    (awready_m),
    .data_o     (aw_skid_dout)
);

ktp_skid_buffer #(
    .WIDTH(W_W)
)u_w_skid_buffer(
    .clk        (aclk),
    .resetn     (aresetn),
    //skid upstream
    .valid_i    (w_skid_valid_i ),
    .ready_o    (w_skid_ready_o),
    .data_i     (w_skid_din),
    //skid downstream
    .valid_o    (wvalid_m),
    .ready_i    (wready_m),
    .data_o     (w_skid_dout)
);

//******************************************AR/B/R Channel Bypass**************************************//
  assign uar_ready  = arready_m;
  assign arvalid_m  = uar_valid;
  assign arid_m     = uarid;
  assign araddr_m   = uaraddr;
  assign arlen_m    = uarlen;
  assign arsize_m   = uarsize;
  assign arburst_m  = uarburst;
  assign arlock_m   = uarlock;
  assign arcache_m  = uarcache;
  assign arprot_m   = uarprot;
  assign aruser_m   = uaruser;
  assign arqos_m    = uarqos;
  assign arregion_m = uarregion;
  assign ardomain_m = uardomain;
  assign arsnoop_m  = uarsnoop;
  assign arbar_m    = uarbar;

  assign ub_valid = bvalid_m;
  assign bready_m = ub_ready;
  assign ubid     = bid_m;
  assign ubuser   = buser_m;
  assign ubresp   = bresp_m;

  assign ur_valid = rvalid_m;
  assign rready_m = ur_ready;
  assign urlast   = rlast_m;
  assign urid     = rid_m;
  assign urdata   = rdata_m;
  assign uruser   = ruser_m;
  assign urresp   = rresp_m;

endmodule
