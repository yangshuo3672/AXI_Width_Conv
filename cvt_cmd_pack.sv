// =============================================================================
// Module      : cvt_cmd_pack
// Description : UIF-128 request path width converter to UIF-64.
//               - AW/AR size 4 is converted to size 3.
//               - AW/AR len is converted with len_out = len_in * 2 + 1.
//               - Each 128-bit W beat is sent as low 64 bits, then high 64 bits.
// =============================================================================

`timescale 1ns/1ps

module cvt_cmd_pack #(
  parameter int ID_WIDTH   = 8,
  parameter int ADDR_WIDTH = 32,
  parameter int USER_WIDTH = 16
) (
  input  logic                  clk,
  input  logic                  resetn,

  // UIF-128 write request from upstream.
  input  logic                  uaww_valid_i,
  output logic                  uaww_ready_i,
  input  logic [ID_WIDTH-1:0]   uawid_i,
  input  logic [ADDR_WIDTH-1:0] uawaddr_i,
  input  logic [3:0]            uawlen_i,
  input  logic [2:0]            uawsize_i,
  input  logic [1:0]            uawburst_i,
  input  logic                  uawlock_i,
  input  logic [3:0]            uawcache_i,
  input  logic [2:0]            uawprot_i,
  input  logic [USER_WIDTH-1:0] uawuser_i,
  input  logic [3:0]            uawqos_i,
  input  logic [3:0]            uawregion_i,
  input  logic [1:0]            uawdomain_i,
  input  logic [2:0]            uawsnoop_i,
  input  logic [1:0]            uawbar_i,
  input  logic [127:0]          uwdata_i,
  input  logic [15:0]           uwstrb_i,
  input  logic [USER_WIDTH-1:0] uwuser_i,
  input  logic                  uwlast_i,

  // UIF-64 write request to downstream.
  output logic                  uaww_valid_o,
  input  logic                  uaww_ready_o,
  output logic [ID_WIDTH-1:0]   uawid_o,
  output logic [ADDR_WIDTH-1:0] uawaddr_o,
  output logic [3:0]            uawlen_o,
  output logic [2:0]            uawsize_o,
  output logic [1:0]            uawburst_o,
  output logic                  uawlock_o,
  output logic [3:0]            uawcache_o,
  output logic [2:0]            uawprot_o,
  output logic [USER_WIDTH-1:0] uawuser_o,
  output logic [3:0]            uawqos_o,
  output logic [3:0]            uawregion_o,
  output logic [1:0]            uawdomain_o,
  output logic [2:0]            uawsnoop_o,
  output logic [1:0]            uawbar_o,
  output logic [63:0]           uwdata_o,
  output logic [7:0]            uwstrb_o,
  output logic [USER_WIDTH-1:0] uwuser_o,
  output logic                  uwlast_o,

  // UIF-128 read address from upstream.
  input  logic                  uar_valid_i,
  output logic                  uar_ready_i,
  input  logic [ID_WIDTH-1:0]   uarid_i,
  input  logic [ADDR_WIDTH-1:0] uaraddr_i,
  input  logic [3:0]            uarlen_i,
  input  logic [2:0]            uarsize_i,
  input  logic [1:0]            uarburst_i,
  input  logic                  uarlock_i,
  input  logic [3:0]            uarcache_i,
  input  logic [2:0]            uarprot_i,
  input  logic [USER_WIDTH-1:0] uaruser_i,
  input  logic [3:0]            uarqos_i,
  input  logic [3:0]            uarregion_i,
  input  logic [1:0]            uardomain_i,
  input  logic [3:0]            uarsnoop_i,
  input  logic [1:0]            uarbar_i,

  // UIF-64 read address to downstream.
  output logic                  uar_valid_o,
  input  logic                  uar_ready_o,
  output logic [ID_WIDTH-1:0]   uarid_o,
  output logic [ADDR_WIDTH-1:0] uaraddr_o,
  output logic [3:0]            uarlen_o,
  output logic [2:0]            uarsize_o,
  output logic [1:0]            uarburst_o,
  output logic                  uarlock_o,
  output logic [3:0]            uarcache_o,
  output logic [2:0]            uarprot_o,
  output logic [USER_WIDTH-1:0] uaruser_o,
  output logic [3:0]            uarqos_o,
  output logic [3:0]            uarregion_o,
  output logic [1:0]            uardomain_o,
  output logic [3:0]            uarsnoop_o,
  output logic [1:0]            uarbar_o
);

  typedef struct packed {
    logic [ID_WIDTH-1:0]   id;
    logic [ADDR_WIDTH-1:0] addr;
    logic [3:0]            len;
    logic [1:0]            burst;
    logic                  lock;
    logic [3:0]            cache;
    logic [2:0]            prot;
    logic [USER_WIDTH-1:0] user;
    logic [3:0]            qos;
    logic [3:0]            region;
    logic [1:0]            domain;
    logic [2:0]            snoop;
    logic [1:0]            bar;
    logic [63:0]           data_hi;
    logic [7:0]            strb_hi;
    logic [USER_WIDTH-1:0] wuser;
    logic                  last;
  } write_hold_t;

  write_hold_t hold_q;
  logic        hold_valid_q;
  logic        low_fire;
  logic        high_fire;


  //上游传输一笔数据只需valid_i和ready_i握手一次；下游需要valid_o和ready_o在传输低64bit和高64bit数据各握手一次。
  // One input write beat produces two output write beats. The low half is driven
  // directly from the upstream payload. The high half is stored in hold_q, so
  // upstream is backpressured until the stored high half has been accepted.
  assign uaww_ready_i = !hold_valid_q && uaww_ready_o;      //写上一笔数据的高64bit时，要反压上游的ready信号
  assign uaww_valid_o = hold_valid_q ? 1'b1 : uaww_valid_i;

  // Sideband fields are unchanged except AxSIZE/AxLEN. For the held high half,
  // reuse the sideband captured with the low half so the second downstream beat
  // belongs to the same converted burst command.
  assign uawid_o      = hold_valid_q ? hold_q.id     : uawid_i;
  assign uawaddr_o    = hold_valid_q ? hold_q.addr   : uawaddr_i;
  assign uawlen_o     = hold_valid_q ? hold_q.len    : {uawlen_i[2:0], 1'b1};
  assign uawsize_o    = 3'd3;
  assign uawburst_o   = hold_valid_q ? hold_q.burst  : uawburst_i;
  assign uawlock_o    = hold_valid_q ? hold_q.lock   : uawlock_i;
  assign uawcache_o   = hold_valid_q ? hold_q.cache  : uawcache_i;
  assign uawprot_o    = hold_valid_q ? hold_q.prot   : uawprot_i;
  assign uawuser_o    = hold_valid_q ? hold_q.user   : uawuser_i;
  assign uawqos_o     = hold_valid_q ? hold_q.qos    : uawqos_i;
  assign uawregion_o  = hold_valid_q ? hold_q.region : uawregion_i;
  assign uawdomain_o  = hold_valid_q ? hold_q.domain : uawdomain_i;
  assign uawsnoop_o   = hold_valid_q ? hold_q.snoop  : uawsnoop_i;
  assign uawbar_o     = hold_valid_q ? hold_q.bar    : uawbar_i;
  assign uwdata_o     = hold_valid_q ? hold_q.data_hi : uwdata_i[63:0];
  assign uwstrb_o     = hold_valid_q ? hold_q.strb_hi : uwstrb_i[7:0];
  assign uwuser_o     = hold_valid_q ? hold_q.wuser   : uwuser_i;
  assign uwlast_o     = hold_valid_q ? hold_q.last    : 1'b0;      //只有传输高64位时，才输出上游的last信号，传输低64时恒为0

  // low_fire accepts a new 128-bit beat and emits its low 64 bits in the same
  // cycle. high_fire completes the conversion by emitting the stored high half.
  assign low_fire  = uaww_valid_i && uaww_ready_i;  //128bit UIF信号握手时，传输低64bit数据和对应的命令
  assign high_fire = hold_valid_q && uaww_ready_o;

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      hold_q       <= '0;
      hold_valid_q <= 1'b0;
    end else begin
      if (low_fire) begin
        // capture uaw/uw's cmd/data needed for the high 64 trans. uwlast is moved to this high 64 trans.  
        hold_q.id      <= uawid_i;
        hold_q.addr    <= uawaddr_i;
        hold_q.len     <= {uawlen_i[2:0], 1'b1};
        hold_q.burst   <= uawburst_i;
        hold_q.lock    <= uawlock_i;
        hold_q.cache   <= uawcache_i;
        hold_q.prot    <= uawprot_i;
        hold_q.user    <= uawuser_i;
        hold_q.qos     <= uawqos_i;
        hold_q.region  <= uawregion_i;
        hold_q.domain  <= uawdomain_i;
        hold_q.snoop   <= uawsnoop_i;
        hold_q.bar     <= uawbar_i;
        hold_q.data_hi <= uwdata_i[127:64];//reg high half
        hold_q.strb_hi <= uwstrb_i[15:8];
        hold_q.wuser   <= uwuser_i;
        hold_q.last    <= uwlast_i;       //reg current wlast
        hold_valid_q   <= 1'b1;
      end else if (high_fire) begin
        hold_valid_q <= 1'b0;
      end
    end
  end

  // Read cmd do not carry data
  assign uar_valid_o  = uar_valid_i;
  assign uar_ready_i  = uar_ready_o;
  assign uarid_o      = uarid_i;
  assign uaraddr_o    = uaraddr_i;
  assign uarlen_o     = {uarlen_i[2:0], 1'b1};
  assign uarsize_o    = 3'd3;
  assign uarburst_o   = uarburst_i;
  assign uarlock_o    = uarlock_i;
  assign uarcache_o   = uarcache_i;
  assign uarprot_o    = uarprot_i;
  assign uaruser_o    = uaruser_i;
  assign uarqos_o     = uarqos_i;
  assign uarregion_o  = uarregion_i;
  assign uardomain_o  = uardomain_i;
  assign uarsnoop_o   = uarsnoop_i;
  assign uarbar_o     = uarbar_i;

endmodule
