AXI桥检查分类：1. 握手协议  
              2. 地址合规：地址对齐、禁止跨4K边界




（一）断言的分类
     1. 立即断言，具有非时序特性，需要放在过程块中，比如initial,always.task,function等
        比如：
       always@(posedge clk)begin
         assert_my: assert(a&&b)
           $display("t% ns is true",$time);
         else 
           $error("false")
       end
    2. 并发断言，使用关键词property区分，由于断言语句会与设计模块一起执行，认为并发断言是一个连续运行的模块，在整个仿真过程中对某些关键信号或信号之间的组合关系进行检查

  （二）断言基本语法
      （1）//a为高，b也为高(交叠蕴含)
             property a_high_then_b_high;
                @(posedge clk) a |-> b;
             endproperty
          //  |-> 特点是“重叠”，即左右两侧的检查七点在同一个时钟周期。
          //步骤：时钟上升沿，检查左侧（先行算子）是否为真，如果左侧为真，则在当前这个时钟周期，立即开始检查右侧（后续算子）是否也为真
     （2）//a为高，下一个时钟周期b为高(非交叠蕴含)
              property a_high_next_cycle_b_high;
                 @(posedge clk) a |=> b; 
              endproperty
              assert_P3: assert property(a_high_next_cycle_b_high); 
          //   |=> 符号代表下一个周期检查b
     （3）//a为高，三个时钟周期b为低
          property a_high_third_cycle_b_high;
             @(posedge clk) a |-> ##3 ~b; //在避免无效错误信息出现的前提下，等价于a ##3 ~b;
          endproperty





（三）AXI传输握手协议层断言
1. AW通道：
// AWVALID 一旦拉高，必须保持直到 AWREADY
assert property (@(posedge aclk) disable iff (!aresetn)
    $rose(awvalid) |-> awvalid throughout awready[->1]);

另一种写法：
     property p_awvalid_hold_until_ready;
        @(posedge aclk) disable iff (!aresetn)
        $rose(awvalid) |-> (awvalid throughout awready[->1]);
     endproperty

     assert property (p_awvalid_hold_until_ready)
        else begin
        $error("[AXI_SVA_ERR] Time=%0t: AWVALID deasserted before AWREADY asserted! awvalid=%b, awready=%b", $time, awvalid, awready);
     end
          
// AWLEN 范围检查（AXI4 burst最大16 beat）
assert property (@(posedge aclk) disable iff (!aresetn)
    awvalid |-> awlen <= 8'd15);

// AWSIZE 不能超过总线位宽（如128bit总线，size <= 4）
assert property (@(posedge aclk) disable iff (!aresetn)
    awvalid |-> awsize <= $clog2(DATA_WIDTH/8));

// AWBURST 只允许 INCR/FIXED/WRAP（2'b00非法）
assert property (@(posedge aclk) disable iff (!aresetn)
    awvalid |-> awburst != 2'b00);

// AWADDR 对齐检查：size=4(128bit)时，addr[3:0]必须为0
assert property (@(posedge aclk) disable iff (!aresetn)
    (awvalid && awsize == 3'd4) |-> (awaddr[3:0] == 4'h0));

（2）W通道：
// WVALID 握手前不能撤下
assert property (@(posedge aclk) disable iff (!aresetn)
    $rose(wvalid) |-> wvalid throughout wready[->1]);

// WLAST 必须在最后一个beat拉高
assert property (@(posedge aclk) disable iff (!aresetn)
    (wvalid && wready && wlast) |-> (beat_cnt == awlen));

// WSTRB 在WLAST之前不能全0（至少有一个byte有效）
assert property (@(posedge aclk) disable iff (!aresetn)
    (wvalid && !wlast) |-> (wstrb != '0));

// WSTRB 必须与 AWSIZE 一致（如size=3(64bit)，strb应为8bit模式）
assert property (@(posedge aclk) disable iff (!aresetn)
    (wvalid && awvalid) |-> ($countones(wstrb) <= (1<<awsize)));

(3)B通道：
// BVALID 必须对应之前的AW（不能凭空出现）
assert property (@(posedge aclk) disable iff (!aresetn)
    $rose(bvalid) |-> ##[1:$] $past(aw_handshake, 1));

// BRESP 只能是 OKAY/EXOKAY/SLVERR/DECERR
assert property (@(posedge aclk) disable iff (!aresetn)
    bvalid |-> bresp inside {2'b00, 2'b01, 2'b10, 2'b11});

// 同ID的B响应必须按AW顺序返回（AXI协议要求）
assert property (@(posedge aclk) disable iff (!aresetn)
    (bvalid && bready && $stable(bid)) |-> 
    bid_order_fifo[bid].pop() == current_b_transaction);

（4）R通道：
 // RVALID 握手规则
assert property (@(posedge aclk) disable iff (!aresetn)
    $rose(rvalid) |-> rvalid throughout rready[->1]);

// RLAST 必须在最后一个R beat
assert property (@(posedge aclk) disable iff (!aresetn)
    (rvalid && rready && rlast) |-> (r_beat_cnt == arlen));

// 读数据位宽必须匹配总线
assert property (@(posedge aclk) disable iff (!aresetn)
    rvalid |-> $bits(rdata) == DATA_WIDTH);

// RRESP 合法性
assert property (@(posedge aclk) disable iff (!aresetn)
    rvalid |-> rresp inside {2'b00, 2'b01, 2'b10, 2'b11});

（四）CDC跨时钟域检查
  （1）格雷码指针断言：
  // 写指针格雷码每次只变1 bit
assert property (@(posedge src_aclk) disable iff (!src_aresetn)
    $changed(wptr_gray) |-> $countones(wptr_gray ^ $past(wptr_gray)) == 1);

// 读指针格雷码每次只变1 bit  
assert property (@(posedge dst_aclk) disable iff (!dst_aresetn)
    $changed(rptr_gray) |-> $countones(rptr_gray ^ $past(rptr_gray)) == 1);

// 同步后的指针不能出现多bit翻转导致的错误值（亚稳态防护）
assert property (@(posedge dst_aclk) disable iff (!dst_aresetn)
    ##2 $stable(wptr_gray_sync) |-> wptr_gray_sync inside {VALID_GRAY_CODES});

（2）复位同步断言：
 // 异步复位同步释放：两个时钟域的reset必须同步释放
assert property (@(posedge src_aclk)
    $fell(src_aresetn) |-> ##[1:10] $rose(src_aresetn) |-> 
    ##[0:5] dst_aresetn == 1'b1);

// 复位期间所有VALID必须拉低
assert property (@(posedge src_aclk)
    !src_aresetn |-> !awvalid && !wvalid && !arvalid);

（四）outstanding与out-of-order规则断言
  （1）outstanding深度
  （2）乱序规则

（五）加入打印
assert property (@(posedge aclk) disable iff (!aresetn)
    $rose(awvalid) |-> awvalid throughout awready[->1])
else 
    $error("[ASSERT FAIL][%0t] AWVALID dropped before AWREADY! awvalid=%b, awready=%b", 
           $time, awvalid, awready);


（六）burst起始地址必须对其到传输大小（AxSize）的边界
     // AWADDR 必须对齐到 2^AWSIZE
     assert property (@(posedge aclk) disable iff (!aresetn)
           $rose(awvalid) |-> (awaddr & ((1 << awsize) - 1)) == 0)
     else $error("AWADDR not aligned to AWSIZE");
     //比如Axsize是0x02，代表本次burst传输每一beat携带的数据大小是2^2=4Byte，因为每一位地址信息携带1个Byte，因此起始地址应该为4的整数倍，即只能为0x00,0x04，0x08...

（七）4K边界禁止跨越
          // AXI协议规定一个burst不能跨越4KB地址边界（页边界保护）
property p_no_4kb_cross;
    @(posedge aclk) disable iff (!aresetn)
    $rose(awvalid) |-> 
      (awaddr[31:12] == (awaddr + ((awlen + 1) << awsize)) & 32'hffff_f000 );
endproperty
assert property (p_no_4kb_cross)
else $error("[AXI_ERR] Time=%0t: Burst crosses 4KB boundary! awaddr=0x%08h", $time, awaddr);
























  
      
