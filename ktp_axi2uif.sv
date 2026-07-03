// =============================================================================
// Module      : ktp_axi2uif
// Description : AXI4/ACE-Lite 128-bit slave-side protocol adapter to UIF-128.
//               UIF couples AW with the first W beat on uaww_*.
// =============================================================================

//spec：1.AXI : 不支持写间插；最大outstanding为16；Qos、User、Region、Domain、Cache、Barrier等随路信号透传；
//      2.UIF： AW与W通道合并，使用同一组握手信号uww_vaild/ready；写命令与对应写数据的第一拍同周期发送；valid-ready握手；

`timescale 1ns/1ps

module ktp_axi2uif #(
  parameter int ID_WIDTH        = 8,
  parameter int ADDR_WIDTH      = 32,
  parameter int DATA_WIDTH      = 128,
  parameter int STRB_WIDTH      = DATA_WIDTH / 8,
  parameter int USER_WIDTH      = 16,
  parameter int AW_FIFO_DEPTH   = 16,  //AW/AR FIFO深度16，可满足最高缓存16笔outstanding读写事务
  parameter int W_FIFO_DEPTH    = 16,
  parameter int AR_FIFO_DEPTH   = 16
) (
  input  logic                    aclk,
  input  logic                    aresetn,

  // AXI slave read address channel
  input  logic                    arvalid_s,
  output logic                    arready_s,
  input  logic [ID_WIDTH-1:0]     arid_s,
  input  logic [ADDR_WIDTH-1:0]   araddr_s,
  input  logic [3:0]              arlen_s,
  input  logic [2:0]              arsize_s,
  input  logic [1:0]              arburst_s,
  input  logic                    arlock_s,
  input  logic [3:0]              arcache_s,
  input  logic [2:0]              arprot_s,
  input  logic [USER_WIDTH-1:0]   aruser_s,
  input  logic [3:0]              arqos_s,
  input  logic [3:0]              arregion_s,
  input  logic [1:0]              ardomain_s,
  input  logic [3:0]              arsnoop_s,
  input  logic [1:0]              arbar_s,

  // AXI slave read data channel
  output logic                    rvalid_s,
  input  logic                    rready_s,
  output logic                    rlast_s,
  output logic [ID_WIDTH-1:0]     rid_s,
  output logic [DATA_WIDTH-1:0]   rdata_s,
  output logic [USER_WIDTH-1:0]   ruser_s,
  output logic [1:0]              rresp_s,

  // AXI slave write address channel
  input  logic                    awvalid_s,
  output logic                    awready_s,
  input  logic [ID_WIDTH-1:0]     awid_s,
  input  logic [ADDR_WIDTH-1:0]   awaddr_s,
  input  logic [3:0]              awlen_s,
  input  logic [2:0]              awsize_s,
  input  logic [1:0]              awburst_s,
  input  logic                    awlock_s,
  input  logic [3:0]              awcache_s,
  input  logic [2:0]              awprot_s,
  input  logic [USER_WIDTH-1:0]   awuser_s,
  input  logic [3:0]              awqos_s,
  input  logic [3:0]              awregion_s,
  input  logic [1:0]              awdomain_s,
  input  logic [2:0]              awsnoop_s,
  input  logic [1:0]              awbar_s,

  // AXI slave write data channel
  input  logic                    wvalid_s,
  output logic                    wready_s,
  input  logic                    wlast_s,
  input  logic [DATA_WIDTH-1:0]   wdata_s,
  input  logic [STRB_WIDTH-1:0]   wstrb_s,
  input  logic [USER_WIDTH-1:0]   wuser_s,

  // AXI slave write response channel
  output logic                    bvalid_s,
  input  logic                    bready_s,
  output logic [ID_WIDTH-1:0]     bid_s,
  output logic [USER_WIDTH-1:0]   buser_s,
  output logic [1:0]              bresp_s,

  // UIF write channel: AW sideband is valid on the first data beat of each burst.
  output logic                    uaww_valid,
  input  logic                    uaww_ready,
  output logic [ID_WIDTH-1:0]     uawid,
  output logic [ADDR_WIDTH-1:0]   uawaddr,
  output logic [3:0]              uawlen,
  output logic [2:0]              uawsize,
  output logic [1:0]              uawburst,
  output logic                    uawlock,
  output logic [3:0]              uawcache,
  output logic [2:0]              uawprot,
  output logic [USER_WIDTH-1:0]   uawuser,
  output logic [3:0]              uawqos,
  output logic [3:0]              uawregion,
  output logic [1:0]              uawdomain,
  output logic [2:0]              uawsnoop,
  output logic [1:0]              uawbar,
  output logic [DATA_WIDTH-1:0]   uwdata,
  output logic [STRB_WIDTH-1:0]   uwstrb,
  output logic [USER_WIDTH-1:0]   uwuser,
  output logic                    uwlast,

  // UIF write response channel
  input  logic                    ub_valid,
  output logic                    ub_ready,
  input  logic [ID_WIDTH-1:0]     ubid,
  input  logic [USER_WIDTH-1:0]   ubuser,
  input  logic [1:0]              ubresp,

  // UIF read address channel
  output logic                    uar_valid,
  input  logic                    uar_ready,
  output logic [ID_WIDTH-1:0]     uarid,
  output logic [ADDR_WIDTH-1:0]   uaraddr,
  output logic [3:0]              uarlen,
  output logic [2:0]              uarsize,
  output logic [1:0]              uarburst,
  output logic                    uarlock,
  output logic [3:0]              uarcache,
  output logic [2:0]              uarprot,
  output logic [USER_WIDTH-1:0]   uaruser,
  output logic [3:0]              uarqos,
  output logic [3:0]              uarregion,
  output logic [1:0]              uardomain,
  output logic [3:0]              uarsnoop,
  output logic [1:0]              uarbar,

  // UIF read data channel
  input  logic                    ur_valid,
  output logic                    ur_ready,
  input  logic                    urlast,
  input  logic [ID_WIDTH-1:0]     urid,
  input  logic [DATA_WIDTH-1:0]   urdata,
  input  logic [USER_WIDTH-1:0]   uruser,
  input  logic [1:0]              urresp
);

  localparam int AW_W = ID_WIDTH + ADDR_WIDTH + 4 + 3 + 2 + 1 + 4 + 3
                      + USER_WIDTH + 4 + 4 + 2 + 3 + 2;                  //88
  localparam int AR_W = ID_WIDTH + ADDR_WIDTH + 4 + 3 + 2 + 1 + 4 + 3
                      + USER_WIDTH + 4 + 4 + 2 + 4 + 2;                  //89
  localparam int W_W  = DATA_WIDTH + STRB_WIDTH + USER_WIDTH + 1;        //153

  logic [AW_W-1:0] aw_fifo_din;
  logic [AW_W-1:0] aw_fifo_dout;
  logic            aw_fifo_full;
  logic            aw_fifo_empty;
  logic            aw_fifo_push;
  logic            aw_fifo_pop;

  logic [AR_W-1:0] ar_fifo_din;
  logic [AR_W-1:0] ar_fifo_dout;
  logic            ar_fifo_full;
  logic            ar_fifo_empty;
  logic            ar_fifo_push;
  logic            ar_fifo_pop;

  logic [W_W-1:0]  w_fifo_din;
  logic [W_W-1:0]  w_fifo_dout;
  logic            w_fifo_full;
  logic            w_fifo_empty;
  logic            w_fifo_push;
  logic            w_fifo_pop;

  logic [AW_W-1:0] active_aw;
  logic            in_write_burst;
  logic            first_write_beat;
  // Combinational packing
  assign aw_fifo_din = { awid_s, awaddr_s, awlen_s, awsize_s, awburst_s, awlock_s, awcache_s,awprot_s, awuser_s, awqos_s, awregion_s, awdomain_s, awsnoop_s, awbar_s   };
  assign w_fifo_din  = { wdata_s, wstrb_s, wuser_s, wlast_s  };
  assign ar_fifo_din = { arid_s, araddr_s, arlen_s, arsize_s, arburst_s, arlock_s, arcache_s, arprot_s, aruser_s, arqos_s, arregion_s, ardomain_s, arsnoop_s, arbar_s  };

 //FIFO非满时，上游AXI侧发起AW/W/AR 事务（valid）即可push FIFO.  valid&ready握手一拍就是一笔地址/数据，
  assign awready_s    = !aw_fifo_full;
  assign wready_s     = !w_fifo_full;
  assign arready_s    = !ar_fifo_full;
  assign aw_fifo_push = awvalid_s && awready_s;
  assign w_fifo_push  = wvalid_s  && wready_s;
  assign ar_fifo_push = arvalid_s && arready_s;

  ktp_sync_fifo #(
    .WIDTH(AW_W),
    .DEPTH(AW_FIFO_DEPTH)
  ) u_aw_fifo (
    .clk    (aclk),
    .resetn (aresetn),
    .push   (aw_fifo_push),
    .din    (aw_fifo_din),
    .full   (aw_fifo_full),
    .pop    (aw_fifo_pop),
    .dout   (aw_fifo_dout),
    .empty  (aw_fifo_empty),
    .level  ()
  );

  ktp_sync_fifo #(
    .WIDTH(W_W),
    .DEPTH(W_FIFO_DEPTH)
  ) u_w_fifo (
    .clk    (aclk),
    .resetn (aresetn),
    .push   (w_fifo_push),
    .din    (w_fifo_din),
    .full   (w_fifo_full),
    .pop    (w_fifo_pop),
    .dout   (w_fifo_dout),
    .empty  (w_fifo_empty),
    .level  ()
  );

  ktp_sync_fifo #(
    .WIDTH(AR_W),
    .DEPTH(AR_FIFO_DEPTH)
  ) u_ar_fifo (
    .clk    (aclk),
    .resetn (aresetn),
    .push   (ar_fifo_push),
    .din    (ar_fifo_din),
    .full   (ar_fifo_full),
    .pop    (ar_fifo_pop),
    .dout   (ar_fifo_dout),
    .empty  (ar_fifo_empty),
    .level  ()
  );
  //
  wire write_can_move   = first_write_beat ? 
                          (!aw_fifo_empty && !w_fifo_empty) : ( !w_fifo_empty );   //若为第一beat，需要aw/w fifo需都非空；若不是第一beat，仅w fifo非空可取数据即可.
  wire write_fire       = uaww_valid && uaww_ready;  //uif写请求与下游握手，记为一笔uif写事件.
  wire current_wlast    = w_fifo_dout[0];  //wlast_s 判断当前是不是

  assign uaww_valid = write_can_move;  //aw和w fifo内数据状态满足move条件，发起uif写请求.
  assign aw_fifo_pop = write_fire && first_write_beat;  //uif发起写请求且当前为first beat，pop aw fifo数据。
  assign w_fifo_pop  = write_fire ;                     //每个burst AW pop一次，W pop awlen次。
  // UIF write output rule:
  // - First beat can be sent only when both AW and W FIFO contain an entry.
  // - Middle beats only need W data because the AW context is already active.

  // Sequential burst context:
  // Capture AW on the first successful UIF write beat, then hold it stable for
  // all following beats of the same burst. Clear the burst state when WLAST is
  // accepted by the downstream UIF stage.
 /*
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      first_write_beat <= 1'b1;     //复位状态下默认第一beat
    end else if (write_fire) begin
      if (first_write_beat) begin
        //active_aw <= aw_fifo_dout;
      end
       if (current_wlast) begin
        first_write_beat <= 1'b1;
      end else begin
        first_write_beat <= 1'b0;
      end
    end
  end

*/
//检测wlast下降沿，当wlast拉高后，不能立即判断first_write_beat=1；因为可能最后一拍wdata和对应的wlast到来后，后级反压没有相应，导致不能立即开始下一个burst事务。
logic current_wlast_d1;

always_ff@(posedge aclk or negedge aresetn)begin
   if(!aresetn)begin
     current_wlast_d1 <= 1'b0;
   end
   else begin
    current_wlast_d1 <= current_wlast;
   end
end

//如果遇到下游uawwready延迟多个周期响应，first_write_beat会在wlast_s拉高的下一个周期就拉高，导致uaww_valid错误判断，可能过早拉低。因此first_write_beat要去判断wlast的下降沿。
always_ff@(posedge aclk or negedge aresetn)begin
   if(!aresetn)begin
     first_write_beat <= 1'b0;
   end
   else if( ~current_wlast && current_wlast_d1 )begin
     first_write_beat <= 1'b1;
   end
   else if(first_write_beat && write_fire)begin   //first beat and pop aw fifo，then first_write_beat=0
     first_write_beat <= 1'b0;
   end
   else begin
     first_write_beat <= first_write_beat;
   end
end

//register aw 
always_ff@(posedge aclk or negedge aresetn)begin
   if(!aresetn)begin
      active_aw <= '0;
   end
   else if(first_write_beat)begin
     active_aw <= aw_fifo_dout;
   end
   else begin
     active_aw <= active_aw; 
   end
end
  // During the first beat, drive AW directly from the FIFO head. During later beats, drive the registered context captured above.
  wire [AW_W-1:0] selected_aw = first_write_beat ? aw_fifo_dout : active_aw;

  // Combinational unpacking to the UIF write channel. 
  assign {uawid, uawaddr, uawlen, uawsize, uawburst, uawlock, uawcache, uawprot,uawuser, uawqos, uawregion, uawdomain, uawsnoop, uawbar} = selected_aw;
  assign {uwdata, uwstrb, uwuser, uwlast} = w_fifo_dout;

  // AR channel is an ordinary valid-ready FIFO path; it is independent of the
  assign uar_valid  = !ar_fifo_empty;
  assign ar_fifo_pop = uar_valid && uar_ready;

  assign { uarid, uaraddr, uarlen, uarsize, uarburst, uarlock, uarcache, uarprot,uaruser, uarqos, uarregion, uardomain, uarsnoop, uarbar} = ar_fifo_dout;

  // B and R return channels already match UIF timing semantics, so they are
  // pure combinational valid-ready pass-throughs in this clock domain.
  assign bvalid_s = ub_valid;
  assign ub_ready = bready_s;
  assign bid_s    = ubid;
  assign buser_s  = ubuser;
  assign bresp_s  = ubresp;

  assign rvalid_s = ur_valid;
  assign ur_ready = rready_s;
  assign rlast_s  = urlast;
  assign rid_s    = urid;
  assign rdata_s  = urdata;
  assign ruser_s  = uruser;
  assign rresp_s  = urresp;

endmodule
