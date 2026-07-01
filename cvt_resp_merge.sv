// =============================================================================
// Module      : cvt_resp_merge
// Description : UIF-64 response path converter back to UIF-128.
//               B responses are passed through. R data is merged by ID so
//               interleaved read responses from different IDs can be accepted.
// =============================================================================

`timescale 1ns/1ps

module cvt_resp_merge #(
  parameter int ID_WIDTH     = 8,
  parameter int USER_WIDTH   = 16,
  parameter int BUFFER_DEPTH = 16,
  parameter int OUT_DEPTH    = 16
) (
  input  logic                  clk,
  input  logic                  resetn,

  // UIF-128 write response to upstream.
  output logic                  ub_valid_o,
  input  logic                  ub_ready_o,
  output logic [ID_WIDTH-1:0]   ubid_o,
  output logic [USER_WIDTH-1:0] ubuser_o,
  output logic [1:0]            ubresp_o,

  // UIF-64 write response from downstream.
  input  logic                  ub_valid_i,
  output logic                  ub_ready_i,
  input  logic [ID_WIDTH-1:0]   ubid_i,
  input  logic [USER_WIDTH-1:0] ubuser_i,
  input  logic [1:0]            ubresp_i,

  // UIF-128 read data to upstream.
  output logic                  ur_valid_o,
  input  logic                  ur_ready_o,
  output logic                  urlast_o,
  output logic [ID_WIDTH-1:0]   urid_o,
  output logic [127:0]          urdata_o,
  output logic [USER_WIDTH-1:0] uruser_o,
  output logic [1:0]            urresp_o,

  // UIF-64 read data from downstream.
  input  logic                  ur_valid_i,
  output logic                  ur_ready_i,
  input  logic                  urlast_i,
  input  logic [ID_WIDTH-1:0]   urid_i,
  input  logic [63:0]           urdata_i,
  input  logic [USER_WIDTH-1:0] uruser_i,
  input  logic [1:0]            urresp_i
);

  localparam int OUT_W = ID_WIDTH + 128 + USER_WIDTH + 2 + 1;
  localparam int IDX_W = (BUFFER_DEPTH <= 1) ? 1 : $clog2(BUFFER_DEPTH);

  logic [BUFFER_DEPTH-1:0]      partial_valid_q;
  logic [ID_WIDTH-1:0]          partial_id_q   [BUFFER_DEPTH];
  logic [63:0]                  partial_data_q [BUFFER_DEPTH];
  logic [USER_WIDTH-1:0]        partial_user_q [BUFFER_DEPTH];
  logic [1:0]                   partial_resp_q [BUFFER_DEPTH];

  logic [BUFFER_DEPTH-1:0]      match_vec;
  logic [BUFFER_DEPTH-1:0]      free_vec;
  logic                         match_found;
  logic                         free_found;
  logic [IDX_W-1:0]               match_idx;
  logic [IDX_W-1:0]               free_idx;

  logic [OUT_W-1:0]             out_fifo_din;
  logic [OUT_W-1:0]             out_fifo_dout;
  logic                         out_fifo_full;
  logic                         out_fifo_empty;
  logic                         out_fifo_push;
  logic                         out_fifo_pop;
  logic [1:0]                   merged_resp;
  logic                         take_r;

  // B channel is width independent. pure ready-valid pass-through
  //写响应通道不不携带数据信息，直接透传.无写响应延迟，增加带宽。
  assign ub_valid_o = ub_valid_i;
  assign ub_ready_i = ub_ready_o;
  assign ubid_o     = ubid_i;
  assign ubuser_o   = ubuser_i;
  assign ubresp_o   = ubresp_i;

  // The first 64-bit read beat of a 128-bit pair is stored in the partial table.
  // When a later beat with the same ID arrives, the two halves are merged. This
  // allows read data for different IDs to be interleaved by the downstream side.
  always_comb begin
    match_vec   = '0;
    free_vec    = '0;
    match_found = 1'b0;
    free_found  = 1'b0;
    match_idx   = '0;
    free_idx    = '0;

    for (int i = 0; i < BUFFER_DEPTH; i++) begin
      match_vec[i] = partial_valid_q[i] && (partial_id_q[i] == urid_i);
      free_vec[i]  = !partial_valid_q[i];
    end

    for (int i = 0; i < BUFFER_DEPTH; i++) begin
      if (match_vec[i] && !match_found) begin
        match_found = 1'b1;
        match_idx   = i[IDX_W-1:0];
      end
      if (free_vec[i] && !free_found) begin
        free_found = 1'b1;
        free_idx   = i[IDX_W-1:0];
      end
    end
  end

  // A new ID needs a free partial table entry. A matching ID needs output FIFO
  // space because it will complete a 128-bit read beat immediately.
  assign ur_ready_i = match_found ? !out_fifo_full : free_found;
  assign take_r     = ur_valid_i && ur_ready_i;
  // Per spec, if either 64-bit response has an error, return the first error
  // observed in the pair. OKAY is encoded as 2'b00.
  assign merged_resp = (partial_resp_q[match_idx] != 2'b00) ? partial_resp_q[match_idx] : urresp_i;
  assign out_fifo_push = take_r && match_found;
  // The earlier 64-bit beat becomes bits [63:0]; the later beat becomes
  // bits [127:64]. User follows the first returned beat as required by spec.
  assign out_fifo_din  = {
    urid_i,
    {urdata_i, partial_data_q[match_idx]},
    partial_user_q[match_idx],
    merged_resp,
    urlast_i
  };

  ktp_sync_fifo #(
    .WIDTH(OUT_W),
    .DEPTH(OUT_DEPTH)
  ) u_read_out_fifo (
    .clk    (clk),
    .resetn (resetn),
    .push   (out_fifo_push),
    .din    (out_fifo_din),
    .full   (out_fifo_full),
    .pop    (out_fifo_pop),
    .dout   (out_fifo_dout),
    .empty  (out_fifo_empty),
    .level  ()
  );

  assign ur_valid_o  = !out_fifo_empty;
  assign out_fifo_pop = ur_valid_o && ur_ready_o;

  // Show-ahead FIFO output is valid whenever the FIFO is non-empty. The upstream
  // side samples these fields only with ur_valid_o && ur_ready_o.
  assign {
    urid_o,
    urdata_o,
    uruser_o,
    urresp_o,
    urlast_o
  } = out_fifo_dout;

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      partial_valid_q <= '0;
      for (int i = 0; i < BUFFER_DEPTH; i++) begin
        partial_id_q[i]   <= '0;
        partial_data_q[i] <= '0;
        partial_user_q[i] <= '0;
        partial_resp_q[i] <= '0;
      end
    end else if (take_r) begin
      if (match_found) begin
        // Second half received: the completed 128-bit beat has been pushed to
        // the output FIFO, so this partial entry can be reused.
        partial_valid_q[match_idx] <= 1'b0;
      end else begin
        // First half for this ID: keep it until the matching second half
        // arrives. Spec disallows duplicate outstanding same-ID read commands,
        // so one partial entry per active ID is sufficient.
        partial_valid_q[free_idx] <= 1'b1;
        partial_id_q[free_idx]    <= urid_i;
        partial_data_q[free_idx]  <= urdata_i;
        partial_user_q[free_idx]  <= uruser_i;
        partial_resp_q[free_idx]  <= urresp_i;
      end
    end
  end

endmodule
