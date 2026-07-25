// =============================================================================
// Module      : u2u
// Description : UIF-64 asynchronous clock-domain bridge.
//               The four UIF channels are independent:
//               - AWW and AR flow from slave clock domain to master clock domain.
//               - B and R flow from master clock domain to slave clock domain.
// =============================================================================

`timescale 1ns/1ps

module u2u #(
  parameter int ID_WIDTH   = 8,
  parameter int ADDR_WIDTH = 32,
  parameter int USER_WIDTH = 16,
  parameter int FIFO_DEPTH = 32
) (
  input  logic                  aclk_s,
  input  logic                  aresetn_s,
  input  logic                  aclk_m,
  input  logic                  aresetn_m,

  // UIF-64 write request from CVT, slave clock domain.
  input  logic                  uaww_valid_s,
  output logic                  uaww_ready_s,
  input  logic [ID_WIDTH-1:0]   uawid_s,
  input  logic [ADDR_WIDTH-1:0] uawaddr_s,
  input  logic [3:0]            uawlen_s,
  input  logic [2:0]            uawsize_s,
  input  logic [1:0]            uawburst_s,
  input  logic                  uawlock_s,
  input  logic [3:0]            uawcache_s,
  input  logic [2:0]            uawprot_s,
  input  logic [USER_WIDTH-1:0] uawuser_s,
  input  logic [3:0]            uawqos_s,
  input  logic [3:0]            uawregion_s,
  input  logic [1:0]            uawdomain_s,
  input  logic [2:0]            uawsnoop_s,
  input  logic [1:0]            uawbar_s,
  input  logic [63:0]           uwdata_s,
  input  logic [7:0]            uwstrb_s,
  input  logic [USER_WIDTH-1:0] uwuser_s,
  input  logic                  uwlast_s,

  // UIF-64 write response to CVT, slave clock domain.
  output logic                  ub_valid_s,
  input  logic                  ub_ready_s,
  output logic [ID_WIDTH-1:0]   ubid_s,
  output logic [USER_WIDTH-1:0] ubuser_s,
  output logic [1:0]            ubresp_s,

  // UIF-64 read address from CVT, slave clock domain.
  input  logic                  uar_valid_s,
  output logic                  uar_ready_s,
  input  logic [ID_WIDTH-1:0]   uarid_s,
  input  logic [ADDR_WIDTH-1:0] uaraddr_s,
  input  logic [3:0]            uarlen_s,
  input  logic [2:0]            uarsize_s,
  input  logic [1:0]            uarburst_s,
  input  logic                  uarlock_s,
  input  logic [3:0]            uarcache_s,
  input  logic [2:0]            uarprot_s,
  input  logic [USER_WIDTH-1:0] uaruser_s,
  input  logic [3:0]            uarqos_s,
  input  logic [3:0]            uarregion_s,
  input  logic [1:0]            uardomain_s,
  input  logic [3:0]            uarsnoop_s,
  input  logic [1:0]            uarbar_s,

  // UIF-64 read data to CVT, slave clock domain.
  output logic                  ur_valid_s,
  input  logic                  ur_ready_s,
  output logic                  urlast_s,
  output logic [ID_WIDTH-1:0]   urid_s,
  output logic [63:0]           urdata_s,
  output logic [USER_WIDTH-1:0] uruser_s,
  output logic [1:0]            urresp_s,

  // UIF-64 write request to UIF2AXI, master clock domain.
  output logic                  uaww_valid_m,
  input  logic                  uaww_ready_m,
  output logic [ID_WIDTH-1:0]   uawid_m,
  output logic [ADDR_WIDTH-1:0] uawaddr_m,
  output logic [3:0]            uawlen_m,
  output logic [2:0]            uawsize_m,
  output logic [1:0]            uawburst_m,
  output logic                  uawlock_m,
  output logic [3:0]            uawcache_m,
  output logic [2:0]            uawprot_m,
  output logic [USER_WIDTH-1:0] uawuser_m,
  output logic [3:0]            uawqos_m,
  output logic [3:0]            uawregion_m,
  output logic [1:0]            uawdomain_m,
  output logic [2:0]            uawsnoop_m,
  output logic [1:0]            uawbar_m,
  output logic [63:0]           uwdata_m,
  output logic [7:0]            uwstrb_m,
  output logic [USER_WIDTH-1:0] uwuser_m,
  output logic                  uwlast_m,

  // UIF-64 write response from UIF2AXI, master clock domain.
  input  logic                  ub_valid_m,
  output logic                  ub_ready_m,
  input  logic [ID_WIDTH-1:0]   ubid_m,
  input  logic [USER_WIDTH-1:0] ubuser_m,
  input  logic [1:0]            ubresp_m,

  // UIF-64 read address to UIF2AXI, master clock domain.
  output logic                  uar_valid_m,
  input  logic                  uar_ready_m,
  output logic [ID_WIDTH-1:0]   uarid_m,
  output logic [ADDR_WIDTH-1:0] uaraddr_m,
  output logic [3:0]            uarlen_m,
  output logic [2:0]            uarsize_m,
  output logic [1:0]            uarburst_m,
  output logic                  uarlock_m,
  output logic [3:0]            uarcache_m,
  output logic [2:0]            uarprot_m,
  output logic [USER_WIDTH-1:0] uaruser_m,
  output logic [3:0]            uarqos_m,
  output logic [3:0]            uarregion_m,
  output logic [1:0]            uardomain_m,
  output logic [3:0]            uarsnoop_m,
  output logic [1:0]            uarbar_m,

  // UIF-64 read data from UIF2AXI, master clock domain.
  input  logic                  ur_valid_m,
  output logic                  ur_ready_m,
  input  logic                  urlast_m,
  input  logic [ID_WIDTH-1:0]   urid_m,
  input  logic [63:0]           urdata_m,
  input  logic [USER_WIDTH-1:0] uruser_m,
  input  logic [1:0]            urresp_m
);

  localparam int AWW_W = ID_WIDTH + ADDR_WIDTH + 4 + 3 + 2 + 1 + 4 + 3
                       + USER_WIDTH + 4 + 4 + 2 + 3 + 2
                       + 64 + 8 + USER_WIDTH + 1;
  localparam int AR_W  = ID_WIDTH + ADDR_WIDTH + 4 + 3 + 2 + 1 + 4 + 3
                       + USER_WIDTH + 4 + 4 + 2 + 4 + 2;
  localparam int B_W   = ID_WIDTH + USER_WIDTH + 2;
  localparam int R_W   = 1 + ID_WIDTH + 64 + USER_WIDTH + 2;

  logic [AWW_W-1:0] aww_fifo_wdata;
  logic [AWW_W-1:0] aww_fifo_rdata;
  logic             aww_fifo_full;
  logic             aww_fifo_empty;
  logic             aww_fifo_winc;
  logic             aww_fifo_rinc;

  logic [AR_W-1:0]  ar_fifo_wdata;
  logic [AR_W-1:0]  ar_fifo_rdata;
  logic             ar_fifo_full;
  logic             ar_fifo_empty;
  logic             ar_fifo_winc;
  logic             ar_fifo_rinc;

  logic [B_W-1:0]   b_fifo_wdata;
  logic [B_W-1:0]   b_fifo_rdata;
  logic             b_fifo_full;
  logic             b_fifo_empty;
  logic             b_fifo_winc;
  logic             b_fifo_rinc;

  logic [R_W-1:0]   r_fifo_wdata;
  logic [R_W-1:0]   r_fifo_rdata;
  logic             r_fifo_full;
  logic             r_fifo_empty;
  logic             r_fifo_winc;
  logic             r_fifo_rinc;

  assign aww_fifo_wdata = {
    uawid_s, uawaddr_s, uawlen_s, uawsize_s, uawburst_s, uawlock_s,
    uawcache_s, uawprot_s, uawuser_s, uawqos_s, uawregion_s, uawdomain_s,
    uawsnoop_s, uawbar_s, uwdata_s, uwstrb_s, uwuser_s, uwlast_s
  };

  assign uaww_ready_s = !aww_fifo_full;
  assign aww_fifo_winc = uaww_valid_s && uaww_ready_s;
  assign uaww_valid_m = !aww_fifo_empty;
  assign aww_fifo_rinc = uaww_valid_m && uaww_ready_m;

  assign {
    uawid_m, uawaddr_m, uawlen_m, uawsize_m, uawburst_m, uawlock_m,
    uawcache_m, uawprot_m, uawuser_m, uawqos_m, uawregion_m, uawdomain_m,
    uawsnoop_m, uawbar_m, uwdata_m, uwstrb_m, uwuser_m, uwlast_m
  } = aww_fifo_rdata;

  ktp_async_fifo #(
    .WIDTH (AWW_W),
    .DEPTH (FIFO_DEPTH)
  ) u_aww_fifo (
    .wclk    (aclk_s),
    .wrst_n  (aresetn_s),
    .winc    (aww_fifo_winc),
    .wdata   (aww_fifo_wdata),
    .wfull   (aww_fifo_full),
    .rclk    (aclk_m),
    .rrst_n  (aresetn_m),
    .rinc    (aww_fifo_rinc),
    .rdata   (aww_fifo_rdata),
    .rempty  (aww_fifo_empty)
  );

  assign ar_fifo_wdata = {
    uarid_s, uaraddr_s, uarlen_s, uarsize_s, uarburst_s, uarlock_s,
    uarcache_s, uarprot_s, uaruser_s, uarqos_s, uarregion_s, uardomain_s,
    uarsnoop_s, uarbar_s
  };

  assign uar_ready_s = !ar_fifo_full;
  assign ar_fifo_winc = uar_valid_s && uar_ready_s;
  assign uar_valid_m = !ar_fifo_empty;
  assign ar_fifo_rinc = uar_valid_m && uar_ready_m;

  assign {
    uarid_m, uaraddr_m, uarlen_m, uarsize_m, uarburst_m, uarlock_m,
    uarcache_m, uarprot_m, uaruser_m, uarqos_m, uarregion_m, uardomain_m,
    uarsnoop_m, uarbar_m
  } = ar_fifo_rdata;

  ktp_async_fifo #(
    .WIDTH (AR_W),
    .DEPTH (FIFO_DEPTH)
  ) u_ar_fifo (
    .wclk    (aclk_s),
    .wrst_n  (aresetn_s),
    .winc    (ar_fifo_winc),
    .wdata   (ar_fifo_wdata),
    .wfull   (ar_fifo_full),
    .rclk    (aclk_m),
    .rrst_n  (aresetn_m),
    .rinc    (ar_fifo_rinc),
    .rdata   (ar_fifo_rdata),
    .rempty  (ar_fifo_empty)
  );

  assign b_fifo_wdata = {ubid_m, ubuser_m, ubresp_m};
  assign ub_ready_m = !b_fifo_full;
  assign b_fifo_winc = ub_valid_m && ub_ready_m;
  assign ub_valid_s = !b_fifo_empty;
  assign b_fifo_rinc = ub_valid_s && ub_ready_s;
  assign {ubid_s, ubuser_s, ubresp_s} = b_fifo_rdata;

  ktp_async_fifo #(
    .WIDTH (B_W),
    .DEPTH (FIFO_DEPTH)
  ) u_b_fifo (
    .wclk    (aclk_m),
    .wrst_n  (aresetn_m),
    .winc    (b_fifo_winc),
    .wdata   (b_fifo_wdata),
    .wfull   (b_fifo_full),
    .rclk    (aclk_s),
    .rrst_n  (aresetn_s),
    .rinc    (b_fifo_rinc),
    .rdata   (b_fifo_rdata),
    .rempty  (b_fifo_empty)
  );

  assign r_fifo_wdata = {urlast_m, urid_m, urdata_m, uruser_m, urresp_m};
  assign ur_ready_m = !r_fifo_full;
  assign r_fifo_winc = ur_valid_m && ur_ready_m;
  assign ur_valid_s = !r_fifo_empty;
  assign r_fifo_rinc = ur_valid_s && ur_ready_s;
  assign {urlast_s, urid_s, urdata_s, uruser_s, urresp_s} = r_fifo_rdata;

  ktp_async_fifo #(
    .WIDTH (R_W),
    .DEPTH (FIFO_DEPTH)
  ) u_r_fifo (
    .wclk    (aclk_m),
    .wrst_n  (aresetn_m),
    .winc    (r_fifo_winc),
    .wdata   (r_fifo_wdata),
    .wfull   (r_fifo_full),
    .rclk    (aclk_s),
    .rrst_n  (aresetn_s),
    .rinc    (r_fifo_rinc),
    .rdata   (r_fifo_rdata),
    .rempty  (r_fifo_empty)
  );

endmodule
