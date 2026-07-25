// =============================================================================
// Module      : ktp_async_fifo
// Description : Dual-clock show-ahead FIFO for KTP CDC paths.
//               Binary pointers address storage locally. Gray-coded pointers
//               are synchronized across clock domains for full/empty detection.
// =============================================================================

`timescale 1ns/1ps

module ktp_async_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 32
) (
  input  logic             wclk,
  input  logic             wrst_n,
  input  logic             winc,
  input  logic [WIDTH-1:0] wdata,
  output logic             wfull,

  input  logic             rclk,
  input  logic             rrst_n,
  input  logic             rinc,
  output logic [WIDTH-1:0] rdata,
  output logic             rempty
);
//show-ahead fifo
  localparam int ADDR_W = $clog2(DEPTH);
  localparam int PTR_W  = ADDR_W + 1;  // r/w poniter has one extra bit 

  logic [WIDTH-1:0] mem [0:DEPTH-1];   // logic [WIDTH-1:0] mem [DEPTH]

  logic [PTR_W-1:0] wbin_curr;
  logic [PTR_W-1:0] wbin_nxt;
  logic [PTR_W-1:0] wgray_curr;
  logic [PTR_W-1:0] wgray_nxt;
  logic [PTR_W-1:0] wgray_rsync1_curr;   // wgray sync in read clock domin
  logic [PTR_W-1:0] wgray_rsync2_curr;

  logic [PTR_W-1:0] rbin_curr;
  logic [PTR_W-1:0] rbin_nxt;
  logic [PTR_W-1:0] rgray_curr;
  logic [PTR_W-1:0] rgray_nxt;
  logic [PTR_W-1:0] rgray_wsync1_curr;  // rgray sync in write clock domin
  logic [PTR_W-1:0] rgray_wsync2_curr;

  logic             wpush_en;
  logic             rpop_en;

  function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] bin);
    bin2gray = (bin >> 1) ^ bin;
  endfunction

  assign wpush_en = winc && !wfull;
  assign rpop_en  = rinc && !rempty;
  assign wbin_nxt  = wbin_curr + {{(PTR_W-1){1'b0}}, wpush_en};
  assign rbin_nxt  = rbin_curr + {{(PTR_W-1){1'b0}}, rpop_en};
  assign wgray_nxt = bin2gray(wbin_nxt);
  assign rgray_nxt = bin2gray(rbin_nxt);
    
  assign wfull  = (wgray_curr == { ~rgray_wsync2_curr[PTR_W-1:PTR_W-2], rgray_wsync2_curr[PTR_W-3:0] });  // wgray_nxt or curr ???
  assign rempty = (rgray_curr == wgray_rsync2_curr);
  assign rdata  = mem [ rbin_curr[ADDR_W-1:0] ];

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wbin_curr         <= 'd0;
      wgray_curr        <= 'd0;
      rgray_wsync1_curr <= 'd0;
      rgray_wsync2_curr <= 'd0;/*
      for(int i=0;i<DEPTH;i++)begin
        mem[i] <= 'd0;
      end                     */  //decrease the area
    end else begin
      rgray_wsync1_curr <= rgray_curr;
      rgray_wsync2_curr <= rgray_wsync1_curr;
     /* 
      if (wpush_en) begin
        mem[wbin_curr[ADDR_W-1:0]] <= wdata;
      end
     */
      wbin_curr  <= wbin_nxt;
      wgray_curr <= wgray_nxt;
    end
  end

  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rbin_curr         <= 'd0;
      rgray_curr        <= 'd0;
      wgray_rsync1_curr <= 'd0;
      wgray_rsync2_curr <= 'd0;
    end else begin
      wgray_rsync1_curr <= wgray_curr;
      wgray_rsync2_curr <= wgray_rsync1_curr;

      rbin_curr  <= rbin_nxt;
      rgray_curr <= rgray_nxt;
    end
  end

  always_ff @(posedge wclk ) begin
    if (wpush_en) begin
        mem[wbin_curr[ADDR_W-1:0]] <= wdata;
    end
  end
  

endmodule
