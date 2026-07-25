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

 
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_W-1:0] wr_ptr;
  logic [ADDR_W-1:0] rd_ptr;
  logic [CNT_W-1:0]  count;

  wire push_en = push && !full;
  wire pop_en  = pop  && !empty;

  // Show-ahead read: dout always reflects the current read pointer. The consumer
  // must qualify dout with !empty and complete pop on handshake.
  assign full  = (count == DEPTH) ? 1'b1 : 1'b0;
  assign empty = (count == 'd0) ? 1'b1 : 1'b0;
  assign level = count;
  assign dout  = mem[rd_ptr];

  // Sequential FIFO state update. Push writes the current write pointer then
  // advances it; pop advances the read pointer. Count changes only for one-sided
  // push/pop, and remains stable when both happen in the same cycle.
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      wr_ptr <= 'd0;
      rd_ptr <= 'd0;
      count  <= 'd0;   /*
      for(int i=0;i<DEPTH;i++)begin
        mem[i] <= '0;
      end             */  //decrease the area
    end else begin
      if (push_en) begin
        //mem[wr_ptr] <= din;
        wr_ptr <= (wr_ptr == DEPTH-1) ? 'd0 : wr_ptr + 1'b1;
      end

      if (pop_en) begin
        rd_ptr <= (rd_ptr == DEPTH-1) ? 'd0 : rd_ptr + 1'b1;
      end

      unique case ({push_en, pop_en})
        2'b10: count <= count + 1'b1;
        2'b01: count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end

  always_ff@(posedge clk)begin
    if(push_en)begin
      mem[wr_ptr] <= din;
    end
  end

endmodule
