// =============================================================================
// Module      : cvt
// Description : UIF-128 to UIF-64 data-width converter in the upstream clock
//               domain. Request conversion is handled by cvt_cmd_pack; response
//               conversion is handled by cvt_resp_merge.
// =============================================================================

`timescale 1ns/1ps

module cvt #(
  parameter int ID_WIDTH     = 8,
  parameter int ADDR_WIDTH   = 32,
  parameter int USER_WIDTH   = 16,
  parameter int R_BUF_DEPTH  = 16,
  parameter int R_OUT_DEPTH  = 16
) (
  input  logic                  aclk,
  input  logic                  aresetn,

  // UIF-128 write request from AXI2UIF.
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
  input  logic [127:0]          uwdata_s,
  input  logic [15:0]           uwstrb_s,
  input  logic [USER_WIDTH-1:0] uwuser_s,
  input  logic                  uwlast_s,

  // UIF-128 write response to AXI2UIF.
  output logic                  ub_valid_s,
  input  logic                  ub_ready_s,
  output logic [ID_WIDTH-1:0]   ubid_s,
  output logic [USER_WIDTH-1:0] ubuser_s,
  output logic [1:0]            ubresp_s,

  // UIF-128 read address from AXI2UIF.
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

  // UIF-128 read data to AXI2UIF.
  output logic                  ur_valid_s,
  input  logic                  ur_ready_s,
  output logic                  urlast_s,
  output logic [ID_WIDTH-1:0]   urid_s,
  output logic [127:0]          urdata_s,
  output logic [USER_WIDTH-1:0] uruser_s,
  output logic [1:0]            urresp_s,

  // UIF-64 write request to U2U.
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

  // UIF-64 write response from U2U.
  input  logic                  ub_valid_m,
  output logic                  ub_ready_m,
  input  logic [ID_WIDTH-1:0]   ubid_m,
  input  logic [USER_WIDTH-1:0] ubuser_m,
  input  logic [1:0]            ubresp_m,

  // UIF-64 read address to U2U.
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

  // UIF-64 read data from U2U.
  input  logic                  ur_valid_m,
  output logic                  ur_ready_m,
  input  logic                  urlast_m,
  input  logic [ID_WIDTH-1:0]   urid_m,
  input  logic [63:0]           urdata_m,
  input  logic [USER_WIDTH-1:0] uruser_m,
  input  logic [1:0]            urresp_m
);

  // Forward request path:
  // AXI2UIF already serialized AXI AW/W into UIF-128. This block keeps the same
  // UIF valid-ready contract while changing command size/len and splitting each
  // 128-bit write data beat into two 64-bit downstream beats.
  cvt_cmd_pack #(
    .ID_WIDTH   (ID_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .USER_WIDTH (USER_WIDTH)
  ) u_cmd_pack (
    .clk          (aclk),
    .resetn       (aresetn),
    .uaww_valid_i (uaww_valid_s),
    .uaww_ready_i (uaww_ready_s),
    .uawid_i      (uawid_s),
    .uawaddr_i    (uawaddr_s),
    .uawlen_i     (uawlen_s),
    .uawsize_i    (uawsize_s),
    .uawburst_i   (uawburst_s),
    .uawlock_i    (uawlock_s),
    .uawcache_i   (uawcache_s),
    .uawprot_i    (uawprot_s),
    .uawuser_i    (uawuser_s),
    .uawqos_i     (uawqos_s),
    .uawregion_i  (uawregion_s),
    .uawdomain_i  (uawdomain_s),
    .uawsnoop_i   (uawsnoop_s),
    .uawbar_i     (uawbar_s),
    .uwdata_i     (uwdata_s),
    .uwstrb_i     (uwstrb_s),
    .uwuser_i     (uwuser_s),
    .uwlast_i     (uwlast_s),
    .uaww_valid_o (uaww_valid_m),
    .uaww_ready_o (uaww_ready_m),
    .uawid_o      (uawid_m),
    .uawaddr_o    (uawaddr_m),
    .uawlen_o     (uawlen_m),
    .uawsize_o    (uawsize_m),
    .uawburst_o   (uawburst_m),
    .uawlock_o    (uawlock_m),
    .uawcache_o   (uawcache_m),
    .uawprot_o    (uawprot_m),
    .uawuser_o    (uawuser_m),
    .uawqos_o     (uawqos_m),
    .uawregion_o  (uawregion_m),
    .uawdomain_o  (uawdomain_m),
    .uawsnoop_o   (uawsnoop_m),
    .uawbar_o     (uawbar_m),
    .uwdata_o     (uwdata_m),
    .uwstrb_o     (uwstrb_m),
    .uwuser_o     (uwuser_m),
    .uwlast_o     (uwlast_m),
    .uar_valid_i  (uar_valid_s),
    .uar_ready_i  (uar_ready_s),
    .uarid_i      (uarid_s),
    .uaraddr_i    (uaraddr_s),
    .uarlen_i     (uarlen_s),
    .uarsize_i    (uarsize_s),
    .uarburst_i   (uarburst_s),
    .uarlock_i    (uarlock_s),
    .uarcache_i   (uarcache_s),
    .uarprot_i    (uarprot_s),
    .uaruser_i    (uaruser_s),
    .uarqos_i     (uarqos_s),
    .uarregion_i  (uarregion_s),
    .uardomain_i  (uardomain_s),
    .uarsnoop_i   (uarsnoop_s),
    .uarbar_i     (uarbar_s),
    .uar_valid_o  (uar_valid_m),
    .uar_ready_o  (uar_ready_m),
    .uarid_o      (uarid_m),
    .uaraddr_o    (uaraddr_m),
    .uarlen_o     (uarlen_m),
    .uarsize_o    (uarsize_m),
    .uarburst_o   (uarburst_m),
    .uarlock_o    (uarlock_m),
    .uarcache_o   (uarcache_m),
    .uarprot_o    (uarprot_m),
    .uaruser_o    (uaruser_m),
    .uarqos_o     (uarqos_m),
    .uarregion_o  (uarregion_m),
    .uardomain_o  (uardomain_m),
    .uarsnoop_o   (uarsnoop_m),
    .uarbar_o     (uarbar_m)
  );

  // Return response path:
  // Write responses do not change width and can be passed through. Read data
  // returns as 64-bit beats, so the merge block pairs beats with the same ID and
  // emits one 128-bit upstream beat when both halves are available.
  cvt_resp_merge #(
    .ID_WIDTH     (ID_WIDTH),
    .USER_WIDTH   (USER_WIDTH),
    .BUFFER_DEPTH (R_BUF_DEPTH),
    .OUT_DEPTH    (R_OUT_DEPTH)
  ) u_resp_merge (
    .clk        (aclk),
    .resetn     (aresetn),
    .ub_valid_o (ub_valid_s),
    .ub_ready_o (ub_ready_s),
    .ubid_o     (ubid_s),
    .ubuser_o   (ubuser_s),
    .ubresp_o   (ubresp_s),
    .ub_valid_i (ub_valid_m),
    .ub_ready_i (ub_ready_m),
    .ubid_i     (ubid_m),
    .ubuser_i   (ubuser_m),
    .ubresp_i   (ubresp_m),
    .ur_valid_o (ur_valid_s),
    .ur_ready_o (ur_ready_s),
    .urlast_o   (urlast_s),
    .urid_o     (urid_s),
    .urdata_o   (urdata_s),
    .uruser_o   (uruser_s),
    .urresp_o   (urresp_s),
    .ur_valid_i (ur_valid_m),
    .ur_ready_i (ur_ready_m),
    .urlast_i   (urlast_m),
    .urid_i     (urid_m),
    .urdata_i   (urdata_m),
    .uruser_i   (uruser_m),
    .urresp_i   (urresp_m)
  );

endmodule
