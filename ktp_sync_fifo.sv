// =============================================================================
// Module      : ktp_sync_fifo
// Description : Small single-clock show-ahead FIFO used by KTP protocol blocks.
// =============================================================================

`timescale 1ns/1ps

module ktp_sync_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 4
) (
  input  logic             clk,
  input  logic             resetn,

  input  logic             push,
  input  logic [WIDTH-1:0] din,
  output logic             full,

  input  logic             pop,
  output logic [WIDTH-1:0] dout,
  output logic             empty,

  output logic [$clog2(DEPTH+1)-1:0] level
);

  localparam int ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
  localparam int CNT_W  = $clog2(DEPTH + 1);
  localparam logic [ADDR_W-1:0] LAST_ADDR   = DEPTH - 1;
  localparam logic [CNT_W-1:0]  DEPTH_COUNT = DEPTH;

  // Storage and binary pointers. This FIFO is single-clock, so no gray-code
  // pointer crossing is needed here.
  logic [WIDTH-1:0] mem [DEPTH];
  logic [ADDR_W-1:0] wr_ptr;
  logic [ADDR_W-1:0] rd_ptr;
  logic [CNT_W-1:0]  count;

  // Guard the user request with current FIFO state. Upstream modules may leave
  // push/pop asserted combinationally, but only legal operations change state.
  wire push_en = push && !full;
  wire pop_en  = pop  && !empty;

  // Show-ahead read: dout always reflects the current read pointer. The consumer
  // must qualify dout with !empty and complete pop on handshake.
  assign full  = (count == DEPTH_COUNT);
  assign empty = (count == '0);
  assign level = count;
  assign dout  = mem[rd_ptr];

  // Sequential FIFO state update. Push writes the current write pointer then
  // advances it; pop advances the read pointer. Count changes only for one-sided
  // push/pop, and remains stable when both happen in the same cycle.
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;
      for(int i=0;i<DEPTH;i++)begin
        mem[i] <= '0;
      end
    end else begin
      if (push_en) begin
        mem[wr_ptr] <= din;
        wr_ptr <= (wr_ptr == LAST_ADDR) ? '0 : wr_ptr + 1'b1;
      end

      if (pop_en) begin
        rd_ptr <= (rd_ptr == LAST_ADDR) ? '0 : rd_ptr + 1'b1;
      end

      unique case ({push_en, pop_en})
        2'b10: count <= count + 1'b1;
        2'b01: count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end


endmodule
