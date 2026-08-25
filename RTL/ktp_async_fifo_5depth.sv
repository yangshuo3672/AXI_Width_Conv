// Notes:
//   - The 10-state Gray sequence is dedicated to depth 5.
//   - The memory array is not reset. After reset rempty is 1, so unwritten data
//     is not read.
// =============================================================================

`timescale 1ns/1ps

module ktp_async_fifo_5depth #(
  parameter int WIDTH = 8
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

  localparam int FIFO_DEPTH = 5;
  localparam int PTR_STATES = 10;
  localparam int ADDR_W     = 3;  // mem address range 0..4 needs 3 bits
  localparam int PTR_W      = 4;  // 10 pointer states need 4 bits

  localparam logic [PTR_W-1:0] DEPTH_PTR = 4'd5;
  localparam logic [PTR_W-1:0] LAST_PTR  = 4'd9;

  logic [WIDTH-1:0] mem [0:FIFO_DEPTH-1];

  logic [PTR_W-1:0] wptr_curr;
  logic [PTR_W-1:0] wptr_nxt;
  logic [PTR_W-1:0] wgray_curr;
  logic [PTR_W-1:0] wgray_nxt;
  logic [PTR_W-1:0] wgray_rsync1_curr;
  logic [PTR_W-1:0] wgray_rsync2_curr;

  logic [PTR_W-1:0] rptr_curr;
  logic [PTR_W-1:0] rptr_nxt;
  logic [PTR_W-1:0] rgray_curr;
  logic [PTR_W-1:0] rgray_nxt;
  logic [PTR_W-1:0] rgray_wsync1_curr;
  logic [PTR_W-1:0] rgray_wsync2_curr;

  logic [PTR_W-1:0] rptr_wsync;
  logic [PTR_W-1:0] wused;

  logic             wpush_en;
  logic             rpop_en;

  // 10-state cyclic Gray table. Neighboring states and the wrap transition
  // change by only one bit.
  function automatic logic [PTR_W-1:0] ptr2gray(input logic [PTR_W-1:0] ptr);
    begin
      unique case (ptr)
        4'd0  : ptr2gray = 4'b0000;
        4'd1  : ptr2gray = 4'b0001;
        4'd2  : ptr2gray = 4'b0011;
        4'd3  : ptr2gray = 4'b0010;
        4'd4  : ptr2gray = 4'b0110;
        4'd5  : ptr2gray = 4'b0111;
        4'd6  : ptr2gray = 4'b0101;
        4'd7  : ptr2gray = 4'b1101;
        4'd8  : ptr2gray = 4'b1001;
        4'd9  : ptr2gray = 4'b1000;
        default: ptr2gray = 4'b0000;
      endcase
    end
  endfunction

  function automatic logic [PTR_W-1:0] gray2ptr(input logic [PTR_W-1:0] gray);
    begin
      unique case (gray)
        4'b0000: gray2ptr = 4'd0;
        4'b0001: gray2ptr = 4'd1;
        4'b0011: gray2ptr = 4'd2;
        4'b0010: gray2ptr = 4'd3;
        4'b0110: gray2ptr = 4'd4;
        4'b0111: gray2ptr = 4'd5;
        4'b0101: gray2ptr = 4'd6;
        4'b1101: gray2ptr = 4'd7;
        4'b1001: gray2ptr = 4'd8;
        4'b1000: gray2ptr = 4'd9;
        default : gray2ptr = 4'd0;
      endcase
    end
  endfunction

  function automatic logic [PTR_W-1:0] ptr_inc(input logic [PTR_W-1:0] ptr);
    begin
      ptr_inc = (ptr == LAST_PTR) ? '0 : (ptr + 4'd1);
    end
  endfunction

  function automatic logic [ADDR_W-1:0] ptr2addr(input logic [PTR_W-1:0] ptr);
    logic [PTR_W-1:0] addr_tmp;
    begin
      addr_tmp = (ptr >= DEPTH_PTR) ? (ptr - DEPTH_PTR) : ptr;
      ptr2addr = addr_tmp[ADDR_W-1:0];
    end
  endfunction

  function automatic logic [PTR_W-1:0] ptr_distance(
    input logic [PTR_W-1:0] write_ptr,
    input logic [PTR_W-1:0] read_ptr
  );
    logic [PTR_W:0] dist_tmp;
    begin
      if (write_ptr >= read_ptr) begin
        dist_tmp = {1'b0, write_ptr} - {1'b0, read_ptr};
      end else begin
        dist_tmp = {1'b0, write_ptr} + 5'd10 - {1'b0, read_ptr};
      end
      ptr_distance = dist_tmp[PTR_W-1:0];
    end
  endfunction

  // Write side uses the synchronized read pointer to compute occupancy. The
  // result is conservative when the synchronized pointer lags, but prevents
  // overflow.
  assign rptr_wsync = gray2ptr(rgray_wsync2_curr);
  assign wused      = ptr_distance(wptr_curr, rptr_wsync);
  assign wfull      = (wused >= DEPTH_PTR);

  assign wpush_en   = winc && !wfull;
  assign wptr_nxt   = wpush_en ? ptr_inc(wptr_curr) : wptr_curr;
  assign wgray_nxt  = ptr2gray(wptr_nxt);

  // Read side empty detection compares synchronized write Gray pointer with the
  // local read Gray pointer.
  assign rempty     = (rgray_curr == wgray_rsync2_curr);
  assign rpop_en    = rinc && !rempty;
  assign rptr_nxt   = rpop_en ? ptr_inc(rptr_curr) : rptr_curr;
  assign rgray_nxt  = ptr2gray(rptr_nxt);

  assign rdata      = mem[ptr2addr(rptr_curr)];

  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wptr_curr         <= '0;
      wgray_curr        <= ptr2gray('0);
      rgray_wsync1_curr <= ptr2gray('0);
      rgray_wsync2_curr <= ptr2gray('0);
    end else begin
      rgray_wsync1_curr <= rgray_curr;
      rgray_wsync2_curr <= rgray_wsync1_curr;

      if (wpush_en) begin
        mem[ptr2addr(wptr_curr)] <= wdata;
      end

      wptr_curr  <= wptr_nxt;
      wgray_curr <= wgray_nxt;
    end
  end

  always_ff @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rptr_curr         <= '0;
      rgray_curr        <= ptr2gray('0);
      wgray_rsync1_curr <= ptr2gray('0);
      wgray_rsync2_curr <= ptr2gray('0);
    end else begin
      wgray_rsync1_curr <= wgray_curr;
      wgray_rsync2_curr <= wgray_rsync1_curr;

      rptr_curr  <= rptr_nxt;
      rgray_curr <= rgray_nxt;
    end
  end

endmodule
