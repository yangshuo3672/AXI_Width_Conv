1. 时钟生成
module clock_gen #(
    parameter real FREQ_MHz = 100.0  // 时钟频率
)(
    output logic clk
);

    localparam real PERIOD_NS = 1000.0 / FREQ_MHz;  // 周期(ns)
    localparam integer HALF_PERIOD = $rtoi(PERIOD_NS / 2.0);

    // 时钟生成
    initial clk = 1'b0;
    always #(HALF_PERIOD) clk = ~clk;

endmodule
