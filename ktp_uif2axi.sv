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

  logic in_write_burst_q;
  logic write_first_beat;
  logic write_fire;

  assign write_first_beat = !in_write_burst_q;

  // Accept the first UIF write beat only when both AXI AW and AXI W can move.
  // Middle beats only depend on AXI W ready.
  assign uaww_ready = write_first_beat ? (awready_m && wready_m) : wready_m;
  assign write_fire = uaww_valid && uaww_ready;

  assign awvalid_m = uaww_valid && write_first_beat && wready_m;
  assign awid_m     = uawid;
  assign awaddr_m   = uawaddr;
  assign awlen_m    = uawlen;
  assign awsize_m   = uawsize;
  assign awburst_m  = uawburst;
  assign awlock_m   = uawlock;
  assign awcache_m  = uawcache;
  assign awprot_m   = uawprot;
  assign awuser_m   = uawuser;
  assign awqos_m    = uawqos;
  assign awregion_m = uawregion;
  assign awdomain_m = uawdomain;
  assign awsnoop_m  = uawsnoop;
  assign awbar_m    = uawbar;

  assign wvalid_m = uaww_valid && (write_first_beat ? awready_m : 1'b1);
  assign wdata_m  = uwdata;
  assign wstrb_m  = uwstrb;
  assign wuser_m  = uwuser;
  assign wlast_m  = uwlast;

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      in_write_burst_q <= 1'b0;
    end else if (write_fire) begin
      in_write_burst_q <= !uwlast;
    end
  end

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
