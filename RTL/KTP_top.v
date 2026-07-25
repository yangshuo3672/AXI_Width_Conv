// =============================================================================
// Module      : ktp_top
// Description : AXI 128-bit slave to AXI 64-bit master bridge.
//               Data path:
//                 AXI2UIF -> CVT -> U2U -> UIF2AXI
//               Control path:
//                 APB config/status, error interrupt, and debug readback.
// =============================================================================

`timescale 1ns/1ps

module ktp_top (
  input  wire         aresetn_s,
  input  wire         aclk_s,
  input  wire         aresetn_m,
  input  wire         aclk_m,

  input  wire         dft_mode,
  input  wire         dft_glb_gt_se,

  input  wire         psel,
  input  wire         penable,
  input  wire         pwrite,
  input  wire [11:0]  paddr,
  input  wire [31:0]  pwdata,
  input  wire [3:0]   pstrb,
  input  wire [2:0]   pprot,
  output wire [31:0]  prdata,
  output wire         pslverr,
  output wire         pready,

  output wire         ktp_irpt_ns,

  input  wire         arvalid_s,
  output wire         arready_s,
  input  wire [7:0]   arid_s,
  input  wire [31:0]  araddr_s,
  input  wire [3:0]   arlen_s,
  input  wire [2:0]   arsize_s,
  input  wire [1:0]   arburst_s,
  input  wire         arlock_s,
  input  wire [3:0]   arcache_s,
  input  wire [2:0]   arprot_s,
  input  wire [15:0]  aruser_s,
  input  wire [3:0]   arqos_s,
  input  wire [3:0]   arregion_s,
  input  wire [1:0]   ardomain_s,
  input  wire [3:0]   arsnoop_s,
  input  wire [1:0]   arbar_s,

  output wire         rvalid_s,
  input  wire         rready_s,
  output wire         rlast_s,
  output wire [7:0]   rid_s,
  output wire [127:0] rdata_s,
  output wire [15:0]  ruser_s,
  output wire [1:0]   rresp_s,

  input  wire         awvalid_s,
  output wire         awready_s,
  input  wire [7:0]   awid_s,
  input  wire [31:0]  awaddr_s,
  input  wire [3:0]   awlen_s,
  input  wire [2:0]   awsize_s,
  input  wire [1:0]   awburst_s,
  input  wire         awlock_s,
  input  wire [3:0]   awcache_s,
  input  wire [2:0]   awprot_s,
  input  wire [15:0]  awuser_s,
  input  wire [3:0]   awqos_s,
  input  wire [3:0]   awregion_s,
  input  wire [1:0]   awdomain_s,
  input  wire [2:0]   awsnoop_s,
  input  wire [1:0]   awbar_s,

  input  wire         wvalid_s,
  output wire         wready_s,
  input  wire         wlast_s,
  input  wire [127:0] wdata_s,
  input  wire [15:0]  wstrb_s,
  input  wire [15:0]  wuser_s,

  output wire         bvalid_s,
  input  wire         bready_s,
  output wire [7:0]   bid_s,
  output wire [15:0]  buser_s,
  output wire [1:0]   bresp_s,

  output wire         arvalid_m,
  input  wire         arready_m,
  output wire [7:0]   arid_m,
  output wire [31:0]  araddr_m,
  output wire [3:0]   arlen_m,
  output wire [2:0]   arsize_m,
  output wire [1:0]   arburst_m,
  output wire         arlock_m,
  output wire [3:0]   arcache_m,
  output wire [2:0]   arprot_m,
  output wire [15:0]  aruser_m,
  output wire [3:0]   arqos_m,
  output wire [3:0]   arregion_m,
  output wire [1:0]   ardomain_m,
  output wire [3:0]   arsnoop_m,
  output wire [1:0]   arbar_m,

  input  wire         rvalid_m,
  output wire         rready_m,
  input  wire         rlast_m,
  input  wire [7:0]   rid_m,
  input  wire [63:0]  rdata_m,
  input  wire [15:0]  ruser_m,
  input  wire [1:0]   rresp_m,

  output wire         awvalid_m,
  input  wire         awready_m,
  output wire [7:0]   awid_m,
  output wire [31:0]  awaddr_m,
  output wire [3:0]   awlen_m,
  output wire [2:0]   awsize_m,
  output wire [1:0]   awburst_m,
  output wire         awlock_m,
  output wire [3:0]   awcache_m,
  output wire [2:0]   awprot_m,
  output wire [15:0]  awuser_m,
  output wire [3:0]   awqos_m,
  output wire [3:0]   awregion_m,
  output wire [1:0]   awdomain_m,
  output wire [2:0]   awsnoop_m,
  output wire [1:0]   awbar_m,

  output wire         wvalid_m,
  input  wire         wready_m,
  output wire         wlast_m,
  output wire [63:0]  wdata_m,
  output wire [7:0]   wstrb_m,
  output wire [15:0]  wuser_m,

  input  wire         bvalid_m,
  output wire         bready_m,
  input  wire [7:0]   bid_m,
  input  wire [15:0]  buser_m,
  input  wire [1:0]   bresp_m
);

  localparam int ID_WIDTH   = 8;
  localparam int ADDR_WIDTH = 32;
  localparam int USER_WIDTH = 16;

  wire ckg_bypass;
  wire clk_en;
  //wire unused_pprot = ^pprot;
  wire ckg_bypass; 

  //assign  
    
  wire u128_aww_valid, u128_aww_ready;
  wire [7:0] u128_awid;
  wire [31:0] u128_awaddr;
  wire [3:0] u128_awlen;
  wire [2:0] u128_awsize;
  wire [1:0] u128_awburst;
  wire u128_awlock;
  wire [3:0] u128_awcache;
  wire [2:0] u128_awprot;
  wire [15:0] u128_awuser;
  wire [3:0] u128_awqos;
  wire [3:0] u128_awregion;
  wire [1:0] u128_awdomain;
  wire [2:0] u128_awsnoop;
  wire [1:0] u128_awbar;
  wire [127:0] u128_wdata;
  wire [15:0] u128_wstrb;
  wire [15:0] u128_wuser;
  wire u128_wlast;
  wire u128_b_valid, u128_b_ready;
  wire [7:0] u128_bid;
  wire [15:0] u128_buser;
  wire [1:0] u128_bresp;
  wire u128_ar_valid, u128_ar_ready;
  wire [7:0] u128_arid;
  wire [31:0] u128_araddr;
  wire [3:0] u128_arlen;
  wire [2:0] u128_arsize;
  wire [1:0] u128_arburst;
  wire u128_arlock;
  wire [3:0] u128_arcache;
  wire [2:0] u128_arprot;
  wire [15:0] u128_aruser;
  wire [3:0] u128_arqos;
  wire [3:0] u128_arregion;
  wire [1:0] u128_ardomain;
  wire [3:0] u128_arsnoop;
  wire [1:0] u128_arbar;
  wire u128_r_valid, u128_r_ready, u128_rlast;
  wire [7:0] u128_rid;
  wire [127:0] u128_rdata;
  wire [15:0] u128_ruser;
  wire [1:0] u128_rresp;

  wire u64_s_aww_valid, u64_s_aww_ready;
  wire [7:0] u64_s_awid;
  wire [31:0] u64_s_awaddr;
  wire [3:0] u64_s_awlen;
  wire [2:0] u64_s_awsize;
  wire [1:0] u64_s_awburst;
  wire u64_s_awlock;
  wire [3:0] u64_s_awcache;
  wire [2:0] u64_s_awprot;
  wire [15:0] u64_s_awuser;
  wire [3:0] u64_s_awqos;
  wire [3:0] u64_s_awregion;
  wire [1:0] u64_s_awdomain;
  wire [2:0] u64_s_awsnoop;
  wire [1:0] u64_s_awbar;
  wire [63:0] u64_s_wdata;
  wire [7:0] u64_s_wstrb;
  wire [15:0] u64_s_wuser;
  wire u64_s_wlast;
  wire u64_s_b_valid, u64_s_b_ready;
  wire [7:0] u64_s_bid;
  wire [15:0] u64_s_buser;
  wire [1:0] u64_s_bresp;
  wire u64_s_ar_valid, u64_s_ar_ready;
  wire [7:0] u64_s_arid;
  wire [31:0] u64_s_araddr;
  wire [3:0] u64_s_arlen;
  wire [2:0] u64_s_arsize;
  wire [1:0] u64_s_arburst;
  wire u64_s_arlock;
  wire [3:0] u64_s_arcache;
  wire [2:0] u64_s_arprot;
  wire [15:0] u64_s_aruser;
  wire [3:0] u64_s_arqos;
  wire [3:0] u64_s_arregion;
  wire [1:0] u64_s_ardomain;
  wire [3:0] u64_s_arsnoop;
  wire [1:0] u64_s_arbar;
  wire u64_s_r_valid, u64_s_r_ready, u64_s_rlast;
  wire [7:0] u64_s_rid;
  wire [63:0] u64_s_rdata;
  wire [15:0] u64_s_ruser;
  wire [1:0] u64_s_rresp;

  wire u64_m_aww_valid, u64_m_aww_ready;
  wire [7:0] u64_m_awid;
  wire [31:0] u64_m_awaddr;
  wire [3:0] u64_m_awlen;
  wire [2:0] u64_m_awsize;
  wire [1:0] u64_m_awburst;
  wire u64_m_awlock;
  wire [3:0] u64_m_awcache;
  wire [2:0] u64_m_awprot;
  wire [15:0] u64_m_awuser;
  wire [3:0] u64_m_awqos;
  wire [3:0] u64_m_awregion;
  wire [1:0] u64_m_awdomain;
  wire [2:0] u64_m_awsnoop;
  wire [1:0] u64_m_awbar;
  wire [63:0] u64_m_wdata;
  wire [7:0] u64_m_wstrb;
  wire [15:0] u64_m_wuser;
  wire u64_m_wlast;
  wire u64_m_b_valid, u64_m_b_ready;
  wire [7:0] u64_m_bid;
  wire [15:0] u64_m_buser;
  wire [1:0] u64_m_bresp;
  wire u64_m_ar_valid, u64_m_ar_ready;
  wire [7:0] u64_m_arid;
  wire [31:0] u64_m_araddr;
  wire [3:0] u64_m_arlen;
  wire [2:0] u64_m_arsize;
  wire [1:0] u64_m_arburst;
  wire u64_m_arlock;
  wire [3:0] u64_m_arcache;
  wire [2:0] u64_m_arprot;
  wire [15:0] u64_m_aruser;
  wire [3:0] u64_m_arqos;
  wire [3:0] u64_m_arregion;
  wire [1:0] u64_m_ardomain;
  wire [3:0] u64_m_arsnoop;
  wire [1:0] u64_m_arbar;
  wire u64_m_r_valid, u64_m_r_ready, u64_m_rlast;
  wire [7:0] u64_m_rid;
  wire [63:0] u64_m_rdata;
  wire [15:0] u64_m_ruser;
  wire [1:0] u64_m_rresp;

  wire [31:0] dbg_info_3;
  assign dbg_info_3 = {
    10'b0,
    u64_m_aww_ready, u64_m_aww_valid,
    !u64_s_r_valid, !u64_m_r_ready,
    !u64_s_b_valid, !u64_m_b_ready,
    !u64_m_ar_valid, !u64_s_ar_ready,
    !u64_m_aww_valid, !u64_s_aww_ready,
    u128_aww_ready, u128_aww_valid,
    bready_m, rready_m, wvalid_m, arvalid_m, awvalid_m,
    bvalid_s, rvalid_s, wready_s, arready_s, awready_s
  };

  ktp_axi2uif #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(128),
    .STRB_WIDTH(16),
    .USER_WIDTH(USER_WIDTH),
    .AW_FIFO_DEPTH(16),
    .W_FIFO_DEPTH(16),
    .AR_FIFO_DEPTH(16)
  ) u_axi2uif (
    .aclk(aclk_s),
    .aresetn(aresetn_s),
    .arvalid_s(arvalid_s),
    .arready_s(arready_s),
    .arid_s(arid_s),
    .araddr_s(araddr_s),
    .arlen_s(arlen_s),
    .arsize_s(arsize_s),
    .arburst_s(arburst_s),
    .arlock_s(arlock_s),
    .arcache_s(arcache_s),
    .arprot_s(arprot_s),
    .aruser_s(aruser_s),
    .arqos_s(arqos_s),
    .arregion_s(arregion_s),
    .ardomain_s(ardomain_s),
    .arsnoop_s(arsnoop_s),
    .arbar_s(arbar_s),
    .rvalid_s(rvalid_s),
    .rready_s(rready_s),
    .rlast_s(rlast_s),
    .rid_s(rid_s),
    .rdata_s(rdata_s),
    .ruser_s(ruser_s),
    .rresp_s(rresp_s),
    .awvalid_s(awvalid_s),
    .awready_s(awready_s),
    .awid_s(awid_s),
    .awaddr_s(awaddr_s),
    .awlen_s(awlen_s),
    .awsize_s(awsize_s),
    .awburst_s(awburst_s),
    .awlock_s(awlock_s),
    .awcache_s(awcache_s),
    .awprot_s(awprot_s),
    .awuser_s(awuser_s),
    .awqos_s(awqos_s),
    .awregion_s(awregion_s),
    .awdomain_s(awdomain_s),
    .awsnoop_s(awsnoop_s),
    .awbar_s(awbar_s),
    .wvalid_s(wvalid_s),
    .wready_s(wready_s),
    .wlast_s(wlast_s),
    .wdata_s(wdata_s),
    .wstrb_s(wstrb_s),
    .wuser_s(wuser_s),
    .bvalid_s(bvalid_s),
    .bready_s(bready_s),
    .bid_s(bid_s),
    .buser_s(buser_s),
    .bresp_s(bresp_s),
    .uaww_valid(u128_aww_valid),
    .uaww_ready(u128_aww_ready),
    .uawid(u128_awid),
    .uawaddr(u128_awaddr),
    .uawlen(u128_awlen),
    .uawsize(u128_awsize),
    .uawburst(u128_awburst),
    .uawlock(u128_awlock),
    .uawcache(u128_awcache),
    .uawprot(u128_awprot),
    .uawuser(u128_awuser),
    .uawqos(u128_awqos),
    .uawregion(u128_awregion),
    .uawdomain(u128_awdomain),
    .uawsnoop(u128_awsnoop),
    .uawbar(u128_awbar),
    .uwdata(u128_wdata),
    .uwstrb(u128_wstrb),
    .uwuser(u128_wuser),
    .uwlast(u128_wlast),
    .ub_valid(u128_b_valid),
    .ub_ready(u128_b_ready),
    .ubid(u128_bid),
    .ubuser(u128_buser),
    .ubresp(u128_bresp),
    .uar_valid(u128_ar_valid),
    .uar_ready(u128_ar_ready),
    .uarid(u128_arid),
    .uaraddr(u128_araddr),
    .uarlen(u128_arlen),
    .uarsize(u128_arsize),
    .uarburst(u128_arburst),
    .uarlock(u128_arlock),
    .uarcache(u128_arcache),
    .uarprot(u128_arprot),
    .uaruser(u128_aruser),
    .uarqos(u128_arqos),
    .uarregion(u128_arregion),
    .uardomain(u128_ardomain),
    .uarsnoop(u128_arsnoop),
    .uarbar(u128_arbar),
    .ur_valid(u128_r_valid),
    .ur_ready(u128_r_ready),
    .urlast(u128_rlast),
    .urid(u128_rid),
    .urdata(u128_rdata),
    .uruser(u128_ruser),
    .urresp(u128_rresp)
  );

  cvt #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .R_BUF_DEPTH(16),
    .R_OUT_DEPTH(16)
  ) u_cvt (
    .aclk(aclk_s),
    .aresetn(aresetn_s),
    .uaww_valid_s(u128_aww_valid),
    .uaww_ready_s(u128_aww_ready),
    .uawid_s(u128_awid),
    .uawaddr_s(u128_awaddr),
    .uawlen_s(u128_awlen),
    .uawsize_s(u128_awsize),
    .uawburst_s(u128_awburst),
    .uawlock_s(u128_awlock),
    .uawcache_s(u128_awcache),
    .uawprot_s(u128_awprot),
    .uawuser_s(u128_awuser),
    .uawqos_s(u128_awqos),
    .uawregion_s(u128_awregion),
    .uawdomain_s(u128_awdomain),
    .uawsnoop_s(u128_awsnoop),
    .uawbar_s(u128_awbar),
    .uwdata_s(u128_wdata),
    .uwstrb_s(u128_wstrb),
    .uwuser_s(u128_wuser),
    .uwlast_s(u128_wlast),
    .ub_valid_s(u128_b_valid),
    .ub_ready_s(u128_b_ready),
    .ubid_s(u128_bid),
    .ubuser_s(u128_buser),
    .ubresp_s(u128_bresp),
    .uar_valid_s(u128_ar_valid),
    .uar_ready_s(u128_ar_ready),
    .uarid_s(u128_arid),
    .uaraddr_s(u128_araddr),
    .uarlen_s(u128_arlen),
    .uarsize_s(u128_arsize),
    .uarburst_s(u128_arburst),
    .uarlock_s(u128_arlock),
    .uarcache_s(u128_arcache),
    .uarprot_s(u128_arprot),
    .uaruser_s(u128_aruser),
    .uarqos_s(u128_arqos),
    .uarregion_s(u128_arregion),
    .uardomain_s(u128_ardomain),
    .uarsnoop_s(u128_arsnoop),
    .uarbar_s(u128_arbar),
    .ur_valid_s(u128_r_valid),
    .ur_ready_s(u128_r_ready),
    .urlast_s(u128_rlast),
    .urid_s(u128_rid),
    .urdata_s(u128_rdata),
    .uruser_s(u128_ruser),
    .urresp_s(u128_rresp),
    .uaww_valid_m(u64_s_aww_valid),
    .uaww_ready_m(u64_s_aww_ready),
    .uawid_m(u64_s_awid),
    .uawaddr_m(u64_s_awaddr),
    .uawlen_m(u64_s_awlen),
    .uawsize_m(u64_s_awsize),
    .uawburst_m(u64_s_awburst),
    .uawlock_m(u64_s_awlock),
    .uawcache_m(u64_s_awcache),
    .uawprot_m(u64_s_awprot),
    .uawuser_m(u64_s_awuser),
    .uawqos_m(u64_s_awqos),
    .uawregion_m(u64_s_awregion),
    .uawdomain_m(u64_s_awdomain),
    .uawsnoop_m(u64_s_awsnoop),
    .uawbar_m(u64_s_awbar),
    .uwdata_m(u64_s_wdata),
    .uwstrb_m(u64_s_wstrb),
    .uwuser_m(u64_s_wuser),
    .uwlast_m(u64_s_wlast),
    .ub_valid_m(u64_s_b_valid),
    .ub_ready_m(u64_s_b_ready),
    .ubid_m(u64_s_bid),
    .ubuser_m(u64_s_buser),
    .ubresp_m(u64_s_bresp),
    .uar_valid_m(u64_s_ar_valid),
    .uar_ready_m(u64_s_ar_ready),
    .uarid_m(u64_s_arid),
    .uaraddr_m(u64_s_araddr),
    .uarlen_m(u64_s_arlen),
    .uarsize_m(u64_s_arsize),
    .uarburst_m(u64_s_arburst),
    .uarlock_m(u64_s_arlock),
    .uarcache_m(u64_s_arcache),
    .uarprot_m(u64_s_arprot),
    .uaruser_m(u64_s_aruser),
    .uarqos_m(u64_s_arqos),
    .uarregion_m(u64_s_arregion),
    .uardomain_m(u64_s_ardomain),
    .uarsnoop_m(u64_s_arsnoop),
    .uarbar_m(u64_s_arbar),
    .ur_valid_m(u64_s_r_valid),
    .ur_ready_m(u64_s_r_ready),
    .urlast_m(u64_s_rlast),
    .urid_m(u64_s_rid),
    .urdata_m(u64_s_rdata),
    .uruser_m(u64_s_ruser),
    .urresp_m(u64_s_rresp)
  );

  u2u #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .FIFO_DEPTH(32)
  ) u_u2u (
    .aclk_s(aclk_s),
    .aresetn_s(aresetn_s),
    .aclk_m(aclk_m),
    .aresetn_m(aresetn_m),
    .uaww_valid_s(u64_s_aww_valid),
    .uaww_ready_s(u64_s_aww_ready),
    .uawid_s(u64_s_awid),
    .uawaddr_s(u64_s_awaddr),
    .uawlen_s(u64_s_awlen),
    .uawsize_s(u64_s_awsize),
    .uawburst_s(u64_s_awburst),
    .uawlock_s(u64_s_awlock),
    .uawcache_s(u64_s_awcache),
    .uawprot_s(u64_s_awprot),
    .uawuser_s(u64_s_awuser),
    .uawqos_s(u64_s_awqos),
    .uawregion_s(u64_s_awregion),
    .uawdomain_s(u64_s_awdomain),
    .uawsnoop_s(u64_s_awsnoop),
    .uawbar_s(u64_s_awbar),
    .uwdata_s(u64_s_wdata),
    .uwstrb_s(u64_s_wstrb),
    .uwuser_s(u64_s_wuser),
    .uwlast_s(u64_s_wlast),
    .ub_valid_s(u64_s_b_valid),
    .ub_ready_s(u64_s_b_ready),
    .ubid_s(u64_s_bid),
    .ubuser_s(u64_s_buser),
    .ubresp_s(u64_s_bresp),
    .uar_valid_s(u64_s_ar_valid),
    .uar_ready_s(u64_s_ar_ready),
    .uarid_s(u64_s_arid),
    .uaraddr_s(u64_s_araddr),
    .uarlen_s(u64_s_arlen),
    .uarsize_s(u64_s_arsize),
    .uarburst_s(u64_s_arburst),
    .uarlock_s(u64_s_arlock),
    .uarcache_s(u64_s_arcache),
    .uarprot_s(u64_s_arprot),
    .uaruser_s(u64_s_aruser),
    .uarqos_s(u64_s_arqos),
    .uarregion_s(u64_s_arregion),
    .uardomain_s(u64_s_ardomain),
    .uarsnoop_s(u64_s_arsnoop),
    .uarbar_s(u64_s_arbar),
    .ur_valid_s(u64_s_r_valid),
    .ur_ready_s(u64_s_r_ready),
    .urlast_s(u64_s_rlast),
    .urid_s(u64_s_rid),
    .urdata_s(u64_s_rdata),
    .uruser_s(u64_s_ruser),
    .urresp_s(u64_s_rresp),
    .uaww_valid_m(u64_m_aww_valid),
    .uaww_ready_m(u64_m_aww_ready),
    .uawid_m(u64_m_awid),
    .uawaddr_m(u64_m_awaddr),
    .uawlen_m(u64_m_awlen),
    .uawsize_m(u64_m_awsize),
    .uawburst_m(u64_m_awburst),
    .uawlock_m(u64_m_awlock),
    .uawcache_m(u64_m_awcache),
    .uawprot_m(u64_m_awprot),
    .uawuser_m(u64_m_awuser),
    .uawqos_m(u64_m_awqos),
    .uawregion_m(u64_m_awregion),
    .uawdomain_m(u64_m_awdomain),
    .uawsnoop_m(u64_m_awsnoop),
    .uawbar_m(u64_m_awbar),
    .uwdata_m(u64_m_wdata),
    .uwstrb_m(u64_m_wstrb),
    .uwuser_m(u64_m_wuser),
    .uwlast_m(u64_m_wlast),
    .ub_valid_m(u64_m_b_valid),
    .ub_ready_m(u64_m_b_ready),
    .ubid_m(u64_m_bid),
    .ubuser_m(u64_m_buser),
    .ubresp_m(u64_m_bresp),
    .uar_valid_m(u64_m_ar_valid),
    .uar_ready_m(u64_m_ar_ready),
    .uarid_m(u64_m_arid),
    .uaraddr_m(u64_m_araddr),
    .uarlen_m(u64_m_arlen),
    .uarsize_m(u64_m_arsize),
    .uarburst_m(u64_m_arburst),
    .uarlock_m(u64_m_arlock),
    .uarcache_m(u64_m_arcache),
    .uarprot_m(u64_m_arprot),
    .uaruser_m(u64_m_aruser),
    .uarqos_m(u64_m_arqos),
    .uarregion_m(u64_m_arregion),
    .uardomain_m(u64_m_ardomain),
    .uarsnoop_m(u64_m_arsnoop),
    .uarbar_m(u64_m_arbar),
    .ur_valid_m(u64_m_r_valid),
    .ur_ready_m(u64_m_r_ready),
    .urlast_m(u64_m_rlast),
    .urid_m(u64_m_rid),
    .urdata_m(u64_m_rdata),
    .uruser_m(u64_m_ruser),
    .urresp_m(u64_m_rresp)
  );

  ktp_uif2axi #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(64),
    .STRB_WIDTH(8),
    .USER_WIDTH(USER_WIDTH)
  ) u_uif2axi (
    .aclk(aclk_m),
    .aresetn(aresetn_m),
    .uaww_valid(u64_m_aww_valid),
    .uaww_ready(u64_m_aww_ready),
    .uawid(u64_m_awid),
    .uawaddr(u64_m_awaddr),
    .uawlen(u64_m_awlen),
    .uawsize(u64_m_awsize),
    .uawburst(u64_m_awburst),
    .uawlock(u64_m_awlock),
    .uawcache(u64_m_awcache),
    .uawprot(u64_m_awprot),
    .uawuser(u64_m_awuser),
    .uawqos(u64_m_awqos),
    .uawregion(u64_m_awregion),
    .uawdomain(u64_m_awdomain),
    .uawsnoop(u64_m_awsnoop),
    .uawbar(u64_m_awbar),
    .uwdata(u64_m_wdata),
    .uwstrb(u64_m_wstrb),
    .uwuser(u64_m_wuser),
    .uwlast(u64_m_wlast),
    .ub_valid(u64_m_b_valid),
    .ub_ready(u64_m_b_ready),
    .ubid(u64_m_bid),
    .ubuser(u64_m_buser),
    .ubresp(u64_m_bresp),
    .uar_valid(u64_m_ar_valid),
    .uar_ready(u64_m_ar_ready),
    .uarid(u64_m_arid),
    .uaraddr(u64_m_araddr),
    .uarlen(u64_m_arlen),
    .uarsize(u64_m_arsize),
    .uarburst(u64_m_arburst),
    .uarlock(u64_m_arlock),
    .uarcache(u64_m_arcache),
    .uarprot(u64_m_arprot),
    .uaruser(u64_m_aruser),
    .uarqos(u64_m_arqos),
    .uarregion(u64_m_arregion),
    .uardomain(u64_m_ardomain),
    .uarsnoop(u64_m_arsnoop),
    .uarbar(u64_m_arbar),
    .ur_valid(u64_m_r_valid),
    .ur_ready(u64_m_r_ready),
    .urlast(u64_m_rlast),
    .urid(u64_m_rid),
    .urdata(u64_m_rdata),
    .uruser(u64_m_ruser),
    .urresp(u64_m_rresp),
    .arvalid_m(arvalid_m),
    .arready_m(arready_m),
    .arid_m(arid_m),
    .araddr_m(araddr_m),
    .arlen_m(arlen_m),
    .arsize_m(arsize_m),
    .arburst_m(arburst_m),
    .arlock_m(arlock_m),
    .arcache_m(arcache_m),
    .arprot_m(arprot_m),
    .aruser_m(aruser_m),
    .arqos_m(arqos_m),
    .arregion_m(arregion_m),
    .ardomain_m(ardomain_m),
    .arsnoop_m(arsnoop_m),
    .arbar_m(arbar_m),
    .rvalid_m(rvalid_m),
    .rready_m(rready_m),
    .rlast_m(rlast_m),
    .rid_m(rid_m),
    .rdata_m(rdata_m),
    .ruser_m(ruser_m),
    .rresp_m(rresp_m),
    .awvalid_m(awvalid_m),
    .awready_m(awready_m),
    .awid_m(awid_m),
    .awaddr_m(awaddr_m),
    .awlen_m(awlen_m),
    .awsize_m(awsize_m),
    .awburst_m(awburst_m),
    .awlock_m(awlock_m),
    .awcache_m(awcache_m),
    .awprot_m(awprot_m),
    .awuser_m(awuser_m),
    .awqos_m(awqos_m),
    .awregion_m(awregion_m),
    .awdomain_m(awdomain_m),
    .awsnoop_m(awsnoop_m),
    .awbar_m(awbar_m),
    .wvalid_m(wvalid_m),
    .wready_m(wready_m),
    .wlast_m(wlast_m),
    .wdata_m(wdata_m),
    .wstrb_m(wstrb_m),
    .wuser_m(wuser_m),
    .bvalid_m(bvalid_m),
    .bready_m(bready_m),
    .bid_m(bid_m),
    .buser_m(buser_m),
    .bresp_m(bresp_m)
  );

  ktp_cfg_reg #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .TRACK_ID_COUNT(256)
  ) u_cfg_reg (
    .clk(aclk_s),
    .resetn(aresetn_s),
    .psel(psel),
    .penable(penable),
    .pwrite(pwrite),
    .paddr(paddr),
    .pwdata(pwdata),
    .pstrb(pstrb),
    .prdata(prdata),
    .pslverr(pslverr),
    .pready(pready),
    .ckg_bypass(ckg_bypass),
    .ktp_irpt_ns(ktp_irpt_ns),
    .aw_fire(awvalid_s && awready_s),
    .aw_id(awid_s),
    .aw_addr(awaddr_s),
    .b_fire(bvalid_s && bready_s),
    .b_id(bid_s),
    .b_resp(bresp_s),
    .ar_fire(arvalid_s && arready_s),
    .ar_id(arid_s),
    .ar_addr(araddr_s),
    .r_fire(rvalid_s && rready_s),
    .r_last(rlast_s),
    .r_id(rid_s),
    .r_resp(rresp_s),
    .dbg_info_3(dbg_info_3)
  );

  ktp_clk_gate_ctrl u_clk_gate_ctrl (
    .clk(aclk_s),
    .resetn(aresetn_s),
    .ckg_bypass(ckg_bypass),
    .dft_mode(dft_mode),
    .dft_glb_gt_se(dft_glb_gt_se),
    .wakeup(awvalid_s || arvalid_s || wvalid_s),
    .active(u128_aww_valid || u128_ar_valid || u128_b_valid || u128_r_valid ||
            u64_s_aww_valid || u64_s_ar_valid || u64_s_b_valid || u64_s_r_valid),
    .clk_en(clk_en_unused)
  );

endmodule
