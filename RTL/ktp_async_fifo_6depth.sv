// =============================================================================
// Module      : ktp_async_fifo_6depth
// Description : 固定深度为 6 的异步 show-ahead FIFO。
//
// 设计说明：
//   1. 本模块只允许通过 WIDTH 修改数据位宽，FIFO 深度固定为 6。
//   2. memory 阵列真实深度就是 6，不使用 8 深度物理阵列。
//   3. 标准异步 FIFO 的二进制自然计数 + Gray 转换方式只适合 2 的幂深度。
//      深度为 6 时如果直接按 6 回绕，回绕点 Gray 码可能多 bit 跳变。
//   4. 本模块使用 12 状态循环 Gray 指针：
//        - 指针状态数 = 2 * FIFO_DEPTH = 12
//        - 前 6 个状态访问 mem[0] ~ mem[5]
//        - 后 6 个状态再次访问 mem[0] ~ mem[5]
//      这样既可以区分空和满，又保证每次指针跳变只有 1 bit。
//   5. rdata 为 show-ahead 输出：当 rempty 为 0 时，rdata 已经是当前可读数据。
//
// 注意：
//   - 本模块的 12 状态 Gray 序列专用于深度 6，不建议改成其他深度。
//   - 不复位 memory 阵列，复位后 rempty 为 1，未写入的数据不会被读取。
// =============================================================================

`timescale 1ns/1ps

module ktp_async_fifo_6depth #(
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

  localparam int FIFO_DEPTH = 6;
  localparam int PTR_STATES = 12;
  localparam int ADDR_W     = 3;  // mem 地址范围 0~5，需要 3 bit
  localparam int PTR_W      = 4;  // 12 个指针状态，需要 4 bit 编码

  localparam logic [PTR_W-1:0] DEPTH_PTR = 4'd6;
  localparam logic [PTR_W-1:0] LAST_PTR  = 4'd11;

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

  // 12 状态循环 Gray 表。相邻状态和回绕状态均只有 1 bit 变化。
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
        4'd8  : ptr2gray = 4'b1111;
        4'd9  : ptr2gray = 4'b1011;
        4'd10 : ptr2gray = 4'b1001;
        4'd11 : ptr2gray = 4'b1000;
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
        4'b1111: gray2ptr = 4'd8;
        4'b1011: gray2ptr = 4'd9;
        4'b1001: gray2ptr = 4'd10;
        4'b1000: gray2ptr = 4'd11;
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
        dist_tmp = {1'b0, write_ptr} + 5'd12 - {1'b0, read_ptr};
      end
      ptr_distance = dist_tmp[PTR_W-1:0];
    end
  endfunction

  // 写侧根据同步后的读指针计算占用量。该判断保守但不会写溢出。
  assign rptr_wsync = gray2ptr(rgray_wsync2_curr);
  assign wused      = ptr_distance(wptr_curr, rptr_wsync);
  assign wfull      = (wused >= DEPTH_PTR);

  assign wpush_en   = winc && !wfull;
  assign wptr_nxt   = wpush_en ? ptr_inc(wptr_curr) : wptr_curr;
  assign wgray_nxt  = ptr2gray(wptr_nxt);

  // 读侧空判断直接比较同步后的写 Gray 指针和本地读 Gray 指针。
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
