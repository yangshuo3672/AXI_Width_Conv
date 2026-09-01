// 文件名：axi_bubble_checker.sv
module axi_bubble_checker(
    input clk,
    input rst_n,
    input wvalid,
    input wready,
    input wlast
);
    // 定义检查使能开关，默认值为 0 (关闭)
    bit en_chk = 0; 

    // 核心断言逻辑：如果开启了检查，且发生了非最后一拍的握手，下一拍 Valid 必须拉高
    property p_axi_w_no_bubble;
        @(posedge clk) disable iff (!rst_n || !en_chk)
        (wvalid && wready && !wlast) |=> wvalid;
    endproperty

    // 触发断言报错
    CHK_W_BUBBLE: assert property(p_axi_w_no_bubble) 
        else $error("[BUBBLE_CHECK] Violation: Bubble detected in Slave AXI Write Data Channel!");

endmodule



axi_bubble_checker u_slv_bubble_chk (
    .clk      (clk_m),              // 接下游时钟 (0.8GHz)
    .rst_n    (rstn_syn_m),         // 接下游复位
    
    // 接你在 vip_bind_macro 中找到的物理宏。
    // 如果编译报错不认识宏，替换为宏展开后的绝对物理路径 (比如 tb_top.dut.xx_wvalid)
    .wvalid   ( `slv_wvalid ), 
    .wready   ( `slv_wready ),      
    .wlast    ( `slv_wlast )
);

`ifndef TC_SANITY__SV
`define TC_SANITY__SV

`define tc_name tc_sanity

class `axi2axi_env_cfg(`tc_name) extends axi2axi_env_cfg;

    `uvm_object_utils(`axi2axi_env_cfg(`tc_name))

    function new(string name = "name");
        super.new(name);
    endfunction

    // 环境配置
    function void post_randomize();
        super.post_randomize();

        ////////////////////////////////////////////////////////////////////////////////////////////////////
        //                                              Master 环境配置
        ////////////////////////////////////////////////////////////////////////////////////////////////////

        // 覆盖率开关
        axi_mst_if_agent_cfg[0].mon_cfg.funcov_enable = 0;
        // 关闭 Slave 端 Monitor 的功能覆盖率
        axi_slv_if_agent_cfg[0].mon_cfg.funcov_enable = 0;
        
        // 乱序功能开启
        axi_mst_if_agent_cfg[0].out_of_bresp = 1;
        axi_mst_if_agent_cfg[0].out_of_rresp = 1;
        
        // Master 支持的读交织深度设为 16
        axi_mst_if_agent_cfg[0].rdintrlv_depth = 16;
        // 【修正】不支持写交织 (原代码拼写错误 writnrlV_depth)
        axi_mst_if_agent_cfg[0].wrintrlv_depth = 1;

        axi_mst_if_agent_cfg[0].wr_outstanding = 16;
        axi_mst_if_agent_cfg[0].rd_outstanding = 16;

        // 【关键修正】全局延迟使能。为了验证极致满载、绝对无气泡，强制设为 1 (关闭 VIP 随机延迟)
        axi_mst_if_agent_cfg[0].no_delay_enable = 1; 
        
        // 设为 0 表示开启VIP内部的协议异常检查
        axi_mst_if_agent_cfg[0].disable_exception_check = 0;
        // 设为 0 表示开启 4K 边界越界检查。
        axi_mst_if_agent_cfg[0].disable_exception_write_4kexceed_check = 0;
        // 不支持4K边界处理 (这很好，4K split 必然会导致气泡)
        axi_mst_if_agent_cfg[0].skip_4k_boundary_split = 1;
        
        // 控制 Master 在作为接收方时，RREADY 和 BREADY 默认保持为高电平，实现最高吞吐量。
        axi_mst_if_agent_cfg[0].mst_drv_cfg.m_enDefaultReady = axi_dec::VMT_BOOLEAN_TRUE;
        
        // 当地址通道的 Valid 信号为低时，不要保持 Address 等信息信号不变。
        axi_mst_if_agent_cfg[0].mst_drv_cfg.ainfo_hold_when_invalid = axi_dec::VMT_FALSE;
        // 当 Valid 为低时，让 Address/ID 等信号随机翻转
        axi_mst_if_agent_cfg[0].mst_drv_cfg.ainfo_random_when_invalid = axi_dec::VMT_TRUE;
        // 当写数据 Valid 为低时，让写数据通道（WDATA, WSTRB）随机翻转。
        axi_mst_if_agent_cfg[0].mst_drv_cfg.winfo_random_when_invalid = axi_dec::VMT_TRUE;
        // 当 Valid 为低时，让 LAST 信号随机翻转
        axi_mst_if_agent_cfg[0].mst_drv_cfg.last_random_when_invalid = axi_dec::VMT_TRUE;

        ////////////////////////////////////////////////////////////////////////////////////////////////////
        //                                              Slave 环境配置
        ////////////////////////////////////////////////////////////////////////////////////////////////////

        // Slave 允许乱序返回 B 和 R 响应
        axi_slv_if_agent_cfg[0].out_of_bresp = 1;
        axi_slv_if_agent_cfg[0].out_of_rresp = 1;
        // Slave 支持的最大读交织和写交织深度
        axi_slv_if_agent_cfg[0].rdintrlv_depth = 16;
        axi_slv_if_agent_cfg[0].wrintrlv_depth = 16;
        
        axi_slv_if_agent_cfg[0].wn_outstanding = 16;
        axi_slv_if_agent_cfg[0].rd_outstanding = 16;

        // 【关键修正】Slave 端同样设为 1，关闭所有随机协议延迟，确保最快响应
        axi_slv_if_agent_cfg[0].no_delay_enable = 1;

        axi_slv_if_agent_cfg[0].disable_exception_check = 0;
        axi_slv_if_agent_cfg[0].disable_exception_write_4kexceed_check = 0;
        axi_slv_if_agent_cfg[0].skip_4k_boundary_split = 1;
        
        // 强制 Slave VIP 的读地址、写地址、写数据通道的 READY 信号在默认状态下全部拉高。
        axi_slv_if_agent_cfg[0].slv_drv_cfg.m_enDefaultArready = axi_dec::VMT_BOOLEAN_TRUE;
        axi_slv_if_agent_cfg[0].slv_drv_cfg.m_enDefaultAwready = axi_dec::VMT_BOOLEAN_TRUE;
        axi_slv_if_agent_cfg[0].slv_drv_cfg.m_enDefaultWready = axi_dec::VMT_BOOLEAN_TRUE;
        
        // 当 Slave 没有有效响应发出时，让 B 和 R 通道的信号随机跳变。
        axi_slv_if_agent_cfg[0].slv_drv_cfg.binfo_random_when_invalid = axi_dec::VMT_TRUE;
        axi_slv_if_agent_cfg[0].slv_drv_cfg.rinfo_random_when_invalid = axi_dec::VMT_TRUE;
        axi_slv_if_agent_cfg[0].m_enMemoryDefaultPattern = axi_dec::PATTERN_RANDOM;

    endfunction
endclass: `axi2axi_env_cfg(`tc_name)


// 声明测试用例类 tc_sanity 继承自 tc_base
class `tc_name extends tc_base;

    `axi2axi_env_cfg(`tc_name) axi2axi_env_cfg;

    `uvm_component_utils_begin(`tc_name)
    `uvm_field_object(axi2axi_env_cfg, UVM_ALL_ON)
    `uvm_component_utils_end
    
    ktp_axi_driver_callback my_axi_drv_cb;
    ktp_axi_slave_driver_callback my_axi_slv_drv_cb;
    KTP_CSTR ktp_cstr;

    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual function void end_of_elaboration_phase(uvm_phase phase);
    extern virtual task reset_phase(uvm_phase phase);
    extern virtual task configure_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
    extern virtual task shutdown_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);

endclass: `tc_name

function `tc_name::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void `tc_name::build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    this.axi2axi_env_cfg = `axi2axi_env_cfg(`tc_name)::type_id::create("axi2axi_env_cfg", this);
    if (!this.axi2axi_env_cfg.randomize()) begin
        `uvm_fatal(get_type_name(), "build_phase(): Unable to randomize cfg in testcase.");
    end
    this.env.cfg = this.axi2axi_env_cfg;

    this.my_axi_drv_cb = ktp_axi_driver_callback::type_id::create("my_axi_drv_cb");
    if (!this.my_axi_drv_cb.randomize()) begin
        `uvm_fatal(get_type_name(), "build_phase(): Unable to randomize my_axi_drv_cb in testcase.");
    end
    this.my_axi_slv_drv_cb = ktp_axi_slave_driver_callback::type_id::create("ktp_axi_slv_drv_cb");
    if (!this.my_axi_slv_drv_cb.randomize()) begin
        `uvm_fatal(get_type_name(), "build_phase(): Unable to randomize my_axi_slv_drv_cb in testcase.");
    end

    // 满载发包 Callback 配置 (全部设为 0，这部分配置非常完美)
    my_axi_drv_cb.next_avalid_delay = 0;
    my_axi_drv_cb.avalid_wvalid_delay = 0;
    my_axi_drv_cb.next_wvalid_delay = 0;
    my_axi_drv_cb.bvalid_bready_delay = 0;
    my_axi_drv_cb.bready_delay = 0;
    my_axi_drv_cb.rvalid_rready_delay = 0;
    my_axi_drv_cb.ready_delay = 0;
    
    my_axi_slv_drv_cb.avalid_aready_delay = 0;
    my_axi_slv_drv_cb.default_ready_delay = 0;
    my_axi_slv_drv_cb.wvalid_wready_delay = 0;
    my_axi_slv_drv_cb.default_wready_delay = 0;
    my_axi_slv_drv_cb.write_bvalid_delay = 0;
    my_axi_slv_drv_cb.address_rvalid_delay = 0;
    my_axi_slv_drv_cb.next_rvalid_delay = 0;
    
    ktp_cstr = new();

endfunction

function void `tc_name::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    uvm_callbacks #(axi_driver,axi_driver_callbacks)::add(env.axi_mst_if_agent[0].axi_mst_drv, my_axi_drv_cb);
    uvm_callbacks #(axi_slave_driver,axi_slave_driver_callbacks)::add(env.axi_slv_if_agent[0].axi_slv_drv, my_axi_slv_drv_cb);
endfunction: connect_phase

function void `tc_name::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "end_of_elaboration_phase finished", UVM_HIGH);
endfunction

task `tc_name::reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    phase.raise_objection(this);
    phase.drop_objection(this);
endtask: reset_phase

task `tc_name::configure_phase(uvm_phase phase);
    super.configure_phase(phase);
    phase.raise_objection(this);
    phase.drop_objection(this);
endtask: configure_phase


// =========================================================================
// 发包操作 (包含下游无气泡检查开关的动态控制)
// =========================================================================
task `tc_name::main_phase(uvm_phase phase);
    logic [1023:0] wdata [];
    logic [1023:0] rdata [];
    bit   [ 127:0] w_strb [];
    axi_sequence u_axi_seq;

    super.main_phase(phase);
    phase.raise_objection(this);
    
    u_axi_seq = axi_sequence::type_id::create("u_axi_seq", this);
    `uvm_info(get_type_name(), $sformatf("send seq to drv"), UVM_NONE)

    assert(ktp_cstr.randomize());

    // -------------------------------------------------------------------
    // [探针控制] 1. 开启下游写数据通道的气泡检查
    // 【注意】: "tb_top" 请替换为你实际包含探针模块的顶层 module 名称 (如 harness)
    // -------------------------------------------------------------------
    $root.tb_top.u_slv_bubble_chk.en_chk = 1; 

    // 发送单笔随机写事务 (此时上游 1.2G 以 0 延迟疯狂灌入 FIFO)
    u_axi_seq.axi_write(env.axi_mst_if_agent[0].sqr, ktp_cstr.addr, 
                1, ktp_cstr.length, 4, ktp_cstr.awcache, ktp_cstr.awprot, 0, ktp_cstr.awqos, ktp_cstr.awuser, wdata, w_strb, 0, 0);

    // -------------------------------------------------------------------
    // [探针控制] 2. 延迟等待下游彻底发完
    // 由于下游(0.8G)比上游(1.2G)慢，axi_write 任务返回时，下游总线上可能还没发完。
    // 等待足够长的时间，确保最后一次握手结束。
    // -------------------------------------------------------------------
    #10us; 
    
    // [探针控制] 3. 及时关闭检查，避免对后续其他操作产生误报
    $root.tb_top.u_slv_bubble_chk.en_chk = 0; 
    // -------------------------------------------------------------------


    // 发送单笔随机读事务 (修复了原代码中的 ktp_cstr.argos 笔误为 arqos)
    u_axi_seq.axi_read(env.axi_mst_if_agent[0].sqr, ktp_cstr.id, 
                1, ktp_cstr.length, 4, ktp_cstr.arcache, ktp_cstr.arprot, 0, ktp_cstr.arqos, ktp_cstr.aruser, rdata, 0, 0);

    // 死等 100 微秒，确保数据完全跑完
    #100us;
    
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "main_phase(): main_phase finished", UVM_HIGH);

endtask: main_phase

task `tc_name::shutdown_phase(uvm_phase phase);
    super.shutdown_phase(phase);
    phase.raise_objection(this);
    phase.drop_objection(this);
endtask: shutdown_phase

function void `tc_name::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "report_phase(): report_phase finished", UVM_HIGH);
endfunction: report_phase

`undef tc_name

`endif
