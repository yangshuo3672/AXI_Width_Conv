//覆盖率配置项
class axi_monitor_funfcov_cfg extends uvm_object;

    bit[HISI_VIP_AXI_ADDR_PORT_WIDTH - 1 : 0] addr_min = 32'h0;
    bit[HISI_VIP_AXI_ADDR_PORT_WIDTH - 1 : 0] addr_max = 32'hffff_ffff;
    bit[HISI_VIP_AXI_MONITOR_ID_PORT_WIDTH - 1:0] id_min = 4'h0;
    bit[HISI_VIP_AXI_MONITOR_ID_PORT_WIDTH - 1:0] id_max = 4'hf;

    int outstanding_min = 1;
    int outstanding_max = 16;
    int interleave_depth_min = 1;
    int interleave_depth_max = 1;
    int out_of_order_depth_min = 1;
    int out_of_order_depth_max = 1;
    //握手延迟（负数：valid先于ready）
    int avalid_aready_delay_neg_max = -10;
    int avalid_aready_delay_neg_min = -1;
    int avalid_aready_delay_pos_min = 1;
    int avalid_aready_delay_pos_max = 10;
    int wvalid_wready_delay_neg_min = -1;
    int wvalid_wready_delay_neg_max = -10;
    int wvalid_wready_delay_pos_min = 1;
    int wvalid_wready_delay_pos_max = 10;
    int rvalid_rready_delay_neg_max = -10;
    int rvalid_rready_delay_neg_min = -1;
    int rvalid_rready_delay_pos_min = 1;
    int rvalid_rready_delay_pos_max = 10;
    int bvalid_bready_delay_neg_min = -1;
    int bvalid_bready_delay_neg_max = -10;
    int bvalid_bready_delay_pos_min = 1;
    int bvalid_bready_delay_pos_max = 10;

    int next_avalid_delay_pos_min = 0;
    int next_avalid_delay_pos_max = 10;
    int next_aready_delay_pos_min = 0;
    int next_aready_delay_pos_max = 10;
    int next_wvalid_delay_pos_min = 0;
    int next_wvalid_delay_pos_max = 10;
    int next_rvalid_delay_pos_min = 0;
    int next_rvalid_delay_pos_max = 10;
    int avalid_wvalid_delay_neg_min = -1;
    int avalid_wvalid_delay_neg_max = -10;
    int avalid_wvalid_delay_pos_min = 1;
    int avalid_wvalid_delay_pos_max = 10;
    int bready_delay_pos_min = 0;
    int bready_delay_pos_max = 10;
    int rready_delay_pos_min = 0;
    int rready_delay_pos_max = 10;
    int avalid_rvalid_delay_pos_min = 0;
    int avalid_rvalid_delay_pos_max = 10;
    int avalid_bvalid_delay_pos_min = 0;
    int avalid_bvalid_delay_pos_max = 10;

    bit instance_cover = 1'b1;

      // 1. 工厂注册宏
    `uvm_object_utils_begin(axi_monitor_funfcov_cfg)
        // 地址范围
        `uvm_field_int(addr_min, UVM_ALL_ON)
        `uvm_field_int(addr_max, UVM_ALL_ON)
        // ID 范围
        `uvm_field_int(id_min, UVM_ALL_ON)
        `uvm_field_int(id_max, UVM_ALL_ON)
        // Outstanding / Interleave / OoO 深度
        `uvm_field_int(outstanding_min, UVM_ALL_ON)
        `uvm_field_int(outstanding_max, UVM_ALL_ON)
        `uvm_field_int(interleave_depth_min, UVM_ALL_ON)
        `uvm_field_int(interleave_depth_max, UVM_ALL_ON)
        `uvm_field_int(out_of_order_depth_min, UVM_ALL_ON)
        `uvm_field_int(out_of_order_depth_max, UVM_ALL_ON)

        // AW 通道握手延迟
        `uvm_field_int(avalid_aready_delay_neg_max, UVM_ALL_ON)
        `uvm_field_int(avalid_aready_delay_neg_min, UVM_ALL_ON)
        `uvm_field_int(avalid_aready_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(avalid_aready_delay_pos_max, UVM_ALL_ON)
        // W 通道握手延迟
        `uvm_field_int(wvalid_wready_delay_neg_min, UVM_ALL_ON)
        `uvm_field_int(wvalid_wready_delay_neg_max, UVM_ALL_ON)
        `uvm_field_int(wvalid_wready_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(wvalid_wready_delay_pos_max, UVM_ALL_ON)
        // R 通道握手延迟
        `uvm_field_int(rvalid_rready_delay_neg_max, UVM_ALL_ON)
        `uvm_field_int(rvalid_rready_delay_neg_min, UVM_ALL_ON)
        `uvm_field_int(rvalid_rready_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(rvalid_rready_delay_pos_max, UVM_ALL_ON)
        // B 通道握手延迟
        `uvm_field_int(bvalid_bready_delay_neg_min, UVM_ALL_ON)
        `uvm_field_int(bvalid_bready_delay_neg_max, UVM_ALL_ON)
        `uvm_field_int(bvalid_bready_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(bvalid_bready_delay_pos_max, UVM_ALL_ON)
        // 连续事务间隔
        `uvm_field_int(next_avalid_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(next_avalid_delay_pos_max, UVM_ALL_ON)
        `uvm_field_int(next_aready_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(next_aready_delay_pos_max, UVM_ALL_ON)
        `uvm_field_int(next_wvalid_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(next_wvalid_delay_pos_max, UVM_ALL_ON)
        `uvm_field_int(next_rvalid_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(next_rvalid_delay_pos_max, UVM_ALL_ON)
        // 跨通道延迟
        `uvm_field_int(avalid_wvalid_delay_neg_min, UVM_ALL_ON)
        `uvm_field_int(avalid_wvalid_delay_neg_max, UVM_ALL_ON)
        `uvm_field_int(avalid_wvalid_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(avalid_wvalid_delay_pos_max, UVM_ALL_ON)
        `uvm_field_int(bready_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(bready_delay_pos_max, UVM_ALL_ON)
        `uvm_field_int(rready_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(rready_delay_pos_max, UVM_ALL_ON)
        `uvm_field_int(avalid_rvalid_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(avalid_rvalid_delay_pos_max, UVM_ALL_ON)
        `uvm_field_int(avalid_bvalid_delay_pos_min, UVM_ALL_ON)
        `uvm_field_int(avalid_bvalid_delay_pos_max, UVM_ALL_ON)
        // 覆盖开关
        `uvm_field_int(instance_cover, UVM_ALL_ON)
    `uvm_object_utils_end

endclass：axi_monitor_funfcov_cfg

function axi_monitor_funfcov_cfg::new(string name = "axi_monitor_funfcov_cfg");
  super.new(name);
endfunction:new

//使用uvm_field_int注册，可以支持自动copy compare print pack record等操作，宏展开后，这些字段会被纳入UVM的Field Automatic机制

  
