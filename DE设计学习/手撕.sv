//轮询仲裁设计
module rr_arbiter_4bit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] req,
    output reg  [3:0] grant
);
    reg [1:0] pointer;  // 优先级指针，指向当前最高优先级
    // 双热码掩码：从 pointer 开始，到最高位为 1
    wire [3:0] mask;
    // 根据 pointer 生成掩码
    assign mask = (pointer == 2'd0) ? 4'b1111 :
                  (pointer == 2'd1) ? 4'b1110 :
                  (pointer == 2'd2) ? 4'b1100 :
                                      4'b1000;
    // 仲裁逻辑：先看 pointer 及以上的请求，再看 pointer 以下的请求
    wire [3:0] req_high = req & mask;        // pointer 及以上
    wire [3:0] req_low  = req & ~mask;       // pointer 以下
    always @(*) begin
        if (req_high != 4'b0000)
            grant = req_high & (~req_high + 1'b1);  // 取最低位 1
        else if (req_low != 4'b0000)
            grant = req_low & (~req_low + 1'b1);    // 取最低位 1
        else
            grant = 4'b0000;
    end
    // 更新 pointer：指向当前获胜者的下一位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pointer <= 2'd0;
        else if (grant != 4'b0000) begin
            case (grant)
                4'b0001: pointer <= 2'd1;
                4'b0010: pointer <= 2'd2;
                4'b0100: pointer <= 2'd3;
                4'b1000: pointer <= 2'd0;
                default: pointer <= pointer;
            endcase
        end
    end
endmodule
