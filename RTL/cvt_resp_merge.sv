// =============================================================================
// Module      : cvt_resp_merge
// =============================================================================

`timescale 1ns/1ps

module cvt_resp_merge #(
  parameter int ID_WIDTH     = 8,
  parameter int USER_WIDTH   = 16,
  parameter int BUFFER_DEPTH = 16,  //支持最高outstanding为16
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
  //fifo width，restore merged rdata/id/rresp，upstream ur_ready_o反压fifo pop.
  localparam int OUT_W = ID_WIDTH + 128 + USER_WIDTH + 2 + 1;
  localparam int IDX_W = (BUFFER_DEPTH <= 1) ? 1 : $clog2(BUFFER_DEPTH);//存储buffer index位宽4.

  logic [BUFFER_DEPTH-1:0]      buffer_valid_q;
  logic [ID_WIDTH-1:0]          buffer_id_q   [BUFFER_DEPTH];
  logic [63:0]                  buffer_data_q [BUFFER_DEPTH];   //buffer只暂存完整128数据的低64bit，高64bit（id判断）到来后立即拼接并申请写入fifo
  logic [USER_WIDTH-1:0]        buffer_user_q [BUFFER_DEPTH];
  logic [1:0]                   buffer_resp_q [BUFFER_DEPTH];

  //buffer状态指示信号
  logic [BUFFER_DEPTH-1:0]      match_vec;  //16-bit vector，buffers
  logic [BUFFER_DEPTH-1:0]      free_vec;
  logic                         match_found;
  logic                         free_found;
  logic [IDX_W-1:0]             match_idx;
  logic [IDX_W-1:0]             free_idx;

  logic [OUT_W-1:0]             out_fifo_din;
  logic [OUT_W-1:0]             out_fifo_dout;
  logic                         out_fifo_full;
  logic                         out_fifo_empty;
  logic                         out_fifo_push;
  logic                         out_fifo_pop;
  logic [1:0]                   merged_resp;
  logic                         handshake_r_i;

  // B channel is width independent. pure ready-valid pass-through
  assign ub_valid_o = ub_valid_i;
  assign ub_ready_i = ub_ready_o;
  assign ubid_o     = ubid_i;
  assign ubuser_o   = ubuser_i;
  assign ubresp_o   = ubresp_i;

  // first/low 64bit read data/id/user/resp stored in look-up table buffer.
  // when the same ID arrives,merge and push fifo.
  // allow read data interleaving
  always_comb begin
    match_vec   = '0;
    free_vec    = '0;
    match_found = 1'b0;
    free_found  = 1'b0;
    match_idx   = '0;
    free_idx    = '0;
   //one-hot
    for (int i = 0; i < BUFFER_DEPTH; i++) begin
      match_vec[i] = buffer_valid_q[i] && (buffer_id_q[i] == urid_i);  //one-hot
      free_vec[i]  = !buffer_valid_q[i];       //buffer_valid_q : this table index restore valid low 64-bit id/data/user/resp
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

  // A new ID needs a free table buffer. A matched ID output FIFO then complete a 128-bit read beat.
  assign ur_ready_i = match_found ? !out_fifo_full : free_found;
  assign handshake_r_i     = ur_valid_i && ur_ready_i;

  // Spec:FS004.003: if either 64-bit response has an error, return the first error.
  //  OKAY: 2'b00.   SLVERR: 2'b10.  DECERR:2'b11.    no EXOKEY 
  assign merged_resp = (buffer_resp_q[match_idx] != 2'b00) ? buffer_resp_q[match_idx] : urresp_i;
  assign out_fifo_push = handshake_r_i && match_found;
  
  assign out_fifo_din  = {
    urid_i,
    {urdata_i, buffer_data_q[match_idx]},
    buffer_user_q[match_idx],
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
      buffer_valid_q <= '0;
      for (int i = 0; i < BUFFER_DEPTH; i++) begin
        buffer_id_q[i]   <= '0;
        buffer_data_q[i] <= '0;
        buffer_user_q[i] <= '0;
        buffer_resp_q[i] <= '0;
      end
    end else if (handshake_r_i) begin  //dowmstream ur_valid_i && ur_ready_i;
      if (match_found) begin
        buffer_valid_q[match_idx] <= 1'b0;
      end 
      else begin
        // First half for this read ID: keep it until the matching second half arrives. 
        // free_idx : the next low-64 bit will restore in last released table buffer[i]
        buffer_valid_q[free_idx] <= 1'b1;
        buffer_id_q[free_idx]    <= urid_i;
        buffer_data_q[free_idx]  <= urdata_i;
        buffer_user_q[free_idx]  <= uruser_i;
        buffer_resp_q[free_idx]  <= urresp_i;
      end
    end
  end

endmodule
