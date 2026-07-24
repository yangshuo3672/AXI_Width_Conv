`ifndef HARNESS_SV
`define HARNESS_SV

module harness;
  logic clk_m = 0;
  logic clk_s = 0;
  logic rst_n;
  logic rst_n_syn_m , rst_n_syn_s;

  logic ktp_irpt_ns;
  logic dft_mode = 1'b0;
  logic dft_glb_gt_se = 1'b0;

  KTP u_ktp(
     .aclk_s       (clk_m),
     .aresetn_s    (rst_n_syn_m),
     .aclk_m       (clk_s),
     .aresetn_m    (rst_n_syn_s),
     .ktp_irpt_ns  (ktp_irpt_ns),
     .dft_mode     (dft_mode),
     .dft_glb_gt_se(dft_glb_gt_se)
  );

  integer a;

  realtime frequency_m; // Mhz
  realtime clk_name_period_m; // ns
  realtime frequency_s; // Mhz
  realtime clk_name_period_s; // ns

  initial begin
      a = $urandom_range(0,1);
      if(a==0) begin
          frequency_m = 1000;//Mhz
          clk_name_period_m = 1000.0/frequency_m;//ns
          frequency_s = 800;//Mhz
          clk_name_period_s = 1000.0/frequency_s;//ns
      end
      else begin
          frequency_m = 800;//Mhz
          clk_name_period_m = 1000.0/frequency_m;//ns
          frequency_s = 1000;//Mhz
          clk_name_period_s = 1000.0/frequency_s;//ns
      end
  end

  `stb_clk_gen(clk_s, 0, clk_name_period_s, 0.5, 0.1, CLK_NOR, 0)
  `stb_clk_gen(clk_m, 0, clk_name_period_m, 0.5, 0.1, CLK_NOR, 0)
  `stb_rst_n_gen(rst_n, 0, 100)
  RST_SYNC_VER U_RST_SYNC_VER0(.rst_out_n(rst_n_syn_m),.rst_in_n(rst_n),.clk(clk_m));
  RST_SYNC_VER U_RST_SYNC_VER1(.rst_out_n(rst_n_syn_s),.rst_in_n(rst_n),.clk(clk_s));

  // STB_HARNESS_INSTANCE_BEGIN
  // 接口实例化
  axi_interface u_axi_if_m[axi2axi_env_dec::AXI_MST_NUM](
      .clk     (clk_m),
      .aresetn (rst_n_syn_m)
  );

  axi_interface u_axi_if_s[axi2axi_env_dec::AXI_SLV_NUM](
      .clk     (clk_s),
      .aresetn (rst_n_syn_s)
  );

  apb_interface u_apb_if_m[axi2axi_env_dec::APB_MST_NUM] (
      .PClk     (clk_m),
      .rst_n    (rst_n_syn_m)
  );

  //apb_interface u_apb_if_m[axi2axi_env_dec::APB_MST_NUM] (
  //    .PClk     (clk_s),
  //    .rst_n    (rst_n_syn_s)
  //);

  `AXI_MST_BIND   // connect u_axi_if_m to ktp top port
  `AXI_SLVBIND
  `CFG_MST_BIND

  //对所有axi_interface实例动态绑定一个axi_debug模块，用于实时监控AXI握手信号，辅助波形调试和协议检查。常用于断言。
  //bind <目标模块名> <需要绑定的模块名> <实例名>
  //bind支持隐式名称匹配，自动在目标模块中查找同名信号。默认将axi_debug的同名端口连接到当前axi_if实例的同名信号上。
  bind axi_interface axi_debug u_axi_debug (
    aclk,
    aresetn,
    
    awvalid,
    awaddr,
    awid,
    awlen,
    awsize,
    awready,
    
    wvalid,
    wlast,
    wready,
    
    bvalid,
    bid,
    bready,
    
    arvalid,
    araddr,
    arid,
    arlen,
    arsize,
    arready,
    
    rvalid,
    rready,
    rid,
    rlast
  );

  //UVM接口传递核心：
  initial begin
       // STB_HARNESS_SET_INTERFACE_START
       virtual axi_interface v_axi_mst_if[axi2axi_env_dec::AXI_MST_NUM];

       virtual axi_interface v_axi_slv_if[axi2axi_env_dec::AXI_SLV_NUM];

       virtual apb_interface v_apb_mst_if[axi2axi_env_dec::APB_MST_NUM];

       v_axi_mst_if = u_axi_if_m;   //将物理接口句柄赋给virtual接口
       foreach(v_axi_mst_if[i]) begin
            uvm_config_db #(virtual axi_interface)::set(null, $sformatf("*.axi_mst_if_agent[%0d]*", i), "bus", v_axi_mst_if[i]);
       end
       v_axi_slv_if = u_axi_if_s;
       foreach(v_axi_slv_if[i]) begin
         uvm_config_db #(virtual axi_interface)::set(null, $sformatf("*.axi_slv_if_agent[%0d]*", i), "bus", v_axi_slv_if[i]);
       end
       v_apb_mst_if = u_apb_if_m;
       foreach(v_apb_mst_if[i]) begin
         uvm_config_db #(virtual apb_interface)::set(null, $sformatf("*.apb_mst_if_agent[%0d]*", i), "bus", v_apb_mst_if[i]);
       end

       // STB_HARNESS_SET_INTERFACE_END
       //打印时间格式：ns，3位小数
       $timeformat(-9,3,"ns",12);
       //启动UVM
       run_test();
   end


   initial begin //global timeout check
     for(iny i = 1;i<=100;i++)begin
         #100us;
       $display ("Simulation goes %d x 100ns",i);
     end
     `uvm_fatal("harness","global time out!")
   end


endmodule :harness

`endif




  
