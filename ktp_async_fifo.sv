// =============================================================================
// Module      : ktp_async_fifo
// Description : Dual-clock show-ahead FIFO for KTP CDC paths.
//               Binary pointers address storage locally. Gray-coded pointers
//               are synchronized across clock domains for full/empty detection.
// =============================================================================

`timescale 1ns/1ps

module ktp_async_fifo #(
  parameter int WIDTH = 8,
  // Use a power-of-two depth. U2U defaults this to 32, which covers the KTP
  // 16-outstanding requirement plus CDC synchronization latency margin.
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

  localparam int ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
  localparam int PTR_W  = ADDR_W + 1;

  function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] bin);
    bin2gray = bin ^ (bin >> 1) ;
  endfunction

  logic [PTR_W-1:0] w_ptr; 
  logic [PTR_W-1:0] r_ptr; 
  logic [PTR_W-1:0] w_ptr_gray;
  logic [PTR_W-1:0] r_ptr_gray;
  logic [PTR_W-1:0] w_ptr_gray_r1;
  logic [PTR_W-1:0] r_ptr_gray_r1;
  logic [PTR_W-1:0] w_ptr_gray_r2;
  logic [PTR_W-1:0] r_ptr_gray_r2;

  always_ff@(posedge wclk or negedge wrst_n)begin
    if(!wrst_n)begin
      w_ptr <= 'd0;
      for(int i=0;i<DEPTH;i++)begin
        mem[i] <= 'd0;
      end
    end
    else if(winc && !wfull)begin
      w_ptr <= wptr + 1'b1;
      mem[w_ptr] <= wdata;
    end
    else begin
      w_ptr <= w_ptr;
      mem[w_ptr] <= mem[w_ptr];
    end
  end

  always_ff@(posedge rclk or negedge rrst_n)begin
    if(!rrst_n)begin
      r_ptr <= 'd0;
      rdata <= 'd0
    end
    else if(rinc && !rempty)begin
      r_ptr <= rptr + 1'b1;
      rdata <= mem[w_ptr] ;
    end
    else begin
      r_ptr <= r_ptr;
      rdata <= rdata;
    end
  end

assign w_ptr_gray = bin2gray(w_ptr);
assign r_ptr_gray = bin2gray(r_ptr);

always_ff(posedge rclk or negedge rrst_n)begin
  if(!rrst_n)begin
    w_ptr_gray_r1 <= 'd0;
    w_ptr_gray_r2 <= 'd0;
  end
  else begin
    w_ptr_gray_r1 <= w_ptr_gray;
    w_ptr_gray_r2 <= w_ptr_gray_r1;
  end
end

always_ff(posedge wclk or negedge wrst_n)begin
  if(!wrst_n)begin
    r_ptr_gray_r1 <= 'd0;
    r_ptr_gray_r2 <= 'd0;
  end
  else begin
    r_ptr_gray_r1 <= r_ptr_gray;
    r_ptr_gray_r2 <= r_ptr_gray_r1;
  end
end


always_comb begin
  if(!wrst_n)begin
    full <= 1'b0;
  end
  else if( w_ptr_gray =={ ~r_ptr_gray_r2[PTR_W-1:PTR_W-2], r_ptr_gray_r2} )begin
    full <= 1'b1;
  end
  else begin
    full <= 1'b0;
  end
end

always_comb begin
  if(!rrst_n)begin
    empty <= 1'b1;////
  end
  else if( r_ptr_gray == w_ptr_gray )begin
    empty <= 1'b1;
  end
  else begin
    empty <= 1'b0;
  end
end

endmodule 


/*
  localparam int ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
  localparam int PTR_W  = ADDR_W + 1;

  logic [WIDTH-1:0] mem [DEPTH];

  logic [PTR_W-1:0] wbin_q;
  logic [PTR_W-1:0] wbin_nxt;
  logic [PTR_W-1:0] wgray_q;
  logic [PTR_W-1:0] wgray_nxt;
  logic [PTR_W-1:0] wgray_rsync1_q;
  logic [PTR_W-1:0] wgray_rsync2_q;

  logic [PTR_W-1:0] rbin_q;
  logic [PTR_W-1:0] rbin_nxt;
  logic [PTR_W-1:0] rgray_q;
  logic [PTR_W-1:0] rgray_nxt;
  logic [PTR_W-1:0] rgray_wsync1_q;
  logic [PTR_W-1:0] rgray_wsync2_q;

  logic             wpush;
  logic             rpop;

  function automatic logic [PTR_W-1:0] bin2gray(input logic [PTR_W-1:0] bin);
    bin2gray = (bin >> 1) ^ bin;
  endfunction

  assign wpush     = winc && !wfull;
  assign rpop      = rinc && !rempty;
  assign wbin_nxt  = wbin_q + {{(PTR_W-1){1'b0}}, wpush};
  assign rbin_nxt  = rbin_q + {{(PTR_W-1){1'b0}}, rpop};
  assign wgray_nxt = bin2gray(wbin_nxt);
  assign rgray_nxt = bin2gray(rbin_nxt);

  // The write side sees full when its next Gray pointer would equal the read
  // pointer with the two MSBs inverted. DEPTH is expected to be a power of two.
  assign wfull = (wgray_nxt == {
    ~rgray_wsync2_q[PTR_W-1:PTR_W-2],
     rgray_wsync2_q[PTR_W-3:0]
  });

  // The read side sees empty when its next Gray pointer catches the synchronized
  // write pointer. Using next-pointer empty lets rempty update after a pop.
  assign rempty = (rgray_nxt == wgray_rsync2_q);

  // Show-ahead read data. Consumers must qualify rdata with !rempty and pop
  // only through rinc. For ASIC SRAM replacement, this maps to async-read RAM
  // behavior or a small register-file style FIFO.
  assign rdata = mem[rbin_q[ADDR_W-1:0]];

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wbin_q         <= '0;
      wgray_q        <= '0;
      rgray_wsync1_q <= '0;
      rgray_wsync2_q <= '0;
    end else begin
      rgray_wsync1_q <= rgray_q;
      rgray_wsync2_q <= rgray_wsync1_q;

      if (wpush) begin
        mem[wbin_q[ADDR_W-1:0]] <= wdata;
      end

      wbin_q  <= wbin_nxt;
      wgray_q <= wgray_nxt;
    end
  end

  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rbin_q         <= '0;
      rgray_q        <= '0;
      wgray_rsync1_q <= '0;
      wgray_rsync2_q <= '0;
    end else begin
      wgray_rsync1_q <= wgray_q;
      wgray_rsync2_q <= wgray_rsync1_q;

      rbin_q  <= rbin_nxt;
      rgray_q <= rgray_nxt;
    end
  end


endmodule

*/
