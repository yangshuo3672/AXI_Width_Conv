// =============================================================================
// Module      : ktp_clk_gate_ctrl
// Description : Clock-gating enable generator. The top level exposes this
//               control point but keeps the current RTL clock tree ungated so
//               technology-specific ICG cells can be inserted later.
// =============================================================================

`timescale 1ns/1ps

module ktp_clk_gate_ctrl (
  input  logic clk,
  input  logic resetn,
  input  logic ckg_bypass,
  input  logic dft_mode,
  input  logic dft_glb_gt_se,
  input  logic wakeup,
  input  logic active,
  output logic clk_en
);

  logic idle_q;

  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      idle_q <= 1'b1;
    end else begin
      idle_q <= !active;
    end
  end

  assign clk_en = ckg_bypass || dft_mode || dft_glb_gt_se || wakeup || !idle_q;

endmodule
