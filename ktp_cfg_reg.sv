// =============================================================================
// Module      : ktp_cfg_reg
// Description : APB4-lite configuration/status registers, interrupt generation,
//               and slave-side command tracking for error address capture.
// =============================================================================

`timescale 1ns/1ps

module ktp_cfg_reg #(
  parameter int ID_WIDTH       = 8,
  parameter int ADDR_WIDTH     = 32,
  parameter int TRACK_ID_COUNT = 256
) (
  input  logic                  clk,
  input  logic                  resetn,

  input  logic                  psel,
  input  logic                  penable,
  input  logic                  pwrite,
  input  logic [11:0]           paddr,
  input  logic [31:0]           pwdata,
  input  logic [3:0]            pstrb,
  output logic [31:0]           prdata,
  output logic                  pslverr,
  output logic                  pready,

  output logic                  ckg_bypass,
  output logic                  ktp_irpt_ns,

  input  logic                  aw_fire,
  input  logic [ID_WIDTH-1:0]   aw_id,
  input  logic [ADDR_WIDTH-1:0] aw_addr,
  input  logic                  b_fire,
  input  logic [ID_WIDTH-1:0]   b_id,
  input  logic [1:0]            b_resp,

  input  logic                  ar_fire,
  input  logic [ID_WIDTH-1:0]   ar_id,
  input  logic [ADDR_WIDTH-1:0] ar_addr,
  input  logic                  r_fire,
  input  logic                  r_last,
  input  logic [ID_WIDTH-1:0]   r_id,
  input  logic [1:0]            r_resp,

  input  logic [31:0]           dbg_info_3
);

  localparam logic [11:0] REG_GLB_CTRL  = 12'h000;
  localparam logic [11:0] REG_IRPT_MSK  = 12'h010;
  localparam logic [11:0] REG_IRPT_RAW  = 12'h014;
  localparam logic [11:0] REG_IRPT_STAT = 12'h018;
  localparam logic [11:0] REG_IRPT_CLR  = 12'h01c;
  localparam logic [11:0] REG_DBG_0     = 12'h100;
  localparam logic [11:0] REG_DBG_1     = 12'h104;
  localparam logic [11:0] REG_DBG_2     = 12'h108;
  localparam logic [11:0] REG_DBG_3     = 12'h10c;

  logic [TRACK_ID_COUNT-1:0]      aw_valid_q;
  logic [TRACK_ID_COUNT-1:0]      ar_valid_q;
  logic [ADDR_WIDTH-1:0]          aw_addr_q [TRACK_ID_COUNT];
  logic [ADDR_WIDTH-1:0]          ar_addr_q [TRACK_ID_COUNT];

  logic [1:0]                     irpt_msk_q;
  logic [1:0]                     irpt_raw_q;
  logic [ADDR_WIDTH-1:0]          err_rd_addr_q;
  logic [ADDR_WIDTH-1:0]          err_wr_addr_q;
  logic [ID_WIDTH-1:0]            err_rd_id_q;
  logic [ID_WIDTH-1:0]            err_wr_id_q;

  logic                           apb_access;
  logic                           apb_write;
  logic                           valid_write_strobe;
  logic [1:0]                     irpt_clr_pulse;
  logic                           r_error_fire;
  logic                           b_error_fire;

  assign apb_access         = psel && penable;
  assign apb_write          = apb_access && pwrite;
  assign valid_write_strobe = (pstrb == 4'b1111);
  assign pready             = 1'b1;
  assign pslverr            = 1'b0;

  assign b_error_fire = b_fire && (b_resp != 2'b00);
  assign r_error_fire = r_fire && (r_resp != 2'b00);
  assign ktp_irpt_ns  = |(irpt_raw_q & ~irpt_msk_q);
  assign irpt_clr_pulse = (apb_write && valid_write_strobe && (paddr == REG_IRPT_CLR)) ? pwdata[1:0] : 2'b00;

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      ckg_bypass   <= 1'b0;
      irpt_msk_q   <= 2'b11;
      irpt_raw_q   <= 2'b00;
      err_rd_addr_q <= '0;
      err_wr_addr_q <= '0;
      err_rd_id_q   <= '0;
      err_wr_id_q   <= '0;
      aw_valid_q    <= '0;
      ar_valid_q    <= '0;
      for (int i = 0; i < TRACK_ID_COUNT; i++) begin
        aw_addr_q[i] <= '0;
        ar_addr_q[i] <= '0;
      end
    end else begin
      if (apb_write && valid_write_strobe) begin
        unique case (paddr)
          REG_GLB_CTRL: ckg_bypass <= pwdata[0];
          REG_IRPT_MSK: irpt_msk_q <= pwdata[1:0];
          default: begin
          end
        endcase
      end

      if (aw_fire) begin
        aw_valid_q[aw_id] <= 1'b1;
        aw_addr_q[aw_id]  <= aw_addr;
      end
      if (ar_fire) begin
        ar_valid_q[ar_id] <= 1'b1;
        ar_addr_q[ar_id]  <= ar_addr;
      end

      if (b_error_fire && !irpt_raw_q[1]) begin
        err_wr_addr_q <= aw_addr_q[b_id];
        err_wr_id_q   <= b_id;
      end
      if (r_error_fire && !irpt_raw_q[0]) begin
        err_rd_addr_q <= ar_addr_q[r_id];
        err_rd_id_q   <= r_id;
      end

      irpt_raw_q[1] <= (irpt_raw_q[1] && !irpt_clr_pulse[1]) || b_error_fire;
      irpt_raw_q[0] <= (irpt_raw_q[0] && !irpt_clr_pulse[0]) || r_error_fire;

      if (b_fire) begin
        aw_valid_q[b_id] <= 1'b0;
      end
      if (r_fire && r_last) begin
        ar_valid_q[r_id] <= 1'b0;
      end
    end
  end

  always_comb begin
    unique case (paddr)
      REG_GLB_CTRL:  prdata = {31'b0, ckg_bypass};
      REG_IRPT_MSK:  prdata = {30'b0, irpt_msk_q};
      REG_IRPT_RAW:  prdata = {30'b0, irpt_raw_q};
      REG_IRPT_STAT: prdata = {30'b0, (irpt_raw_q & ~irpt_msk_q)};
      REG_IRPT_CLR:  prdata = 32'b0;
      REG_DBG_0:     prdata = err_rd_addr_q;
      REG_DBG_1:     prdata = err_wr_addr_q;
      REG_DBG_2:     prdata = {16'b0, err_wr_id_q, err_rd_id_q};
      REG_DBG_3:     prdata = dbg_info_3;
      default:       prdata = 32'b0;
    endcase
  end

endmodule
