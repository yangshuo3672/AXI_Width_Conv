
class my_linkbench_env #(type T = linkbench_env_dec) extends uvm_env;
  
   typedef my_linkbench_env #(T) this_type;
   linkbench_env_cfg#(T) linkbench_cfg;
   // @mst_agent
   my_apb_interface_agent apb_mst_if_agent[];
   ahb_interface_agent ahb_mst_if_agent[];
   axi_interface_agent axi_mst_if_agent[];
   // @slv_agent
   my_apb_interface_agent apb_slv_if_agent[];
   ahb_interface_agent ahb_slv_if_agent[];
   axi_interface_agent axi_slv_if_agent[];

   linkbench_virtual_sequencer#(T) vsqr ;

   // @ local
   axi_ext_dir_sequence axi_direct_drv_library[];
   ahb_ext_dir_sequence ahb_direct_drv_library[];
   apb_ext_dir_sequence apb_direct_drv_library[];

   hisi_axi_c_bus_drv hisi_axi_drv[];
   hisi_ahb_c_bus_drv hisi_ahb_drv[];
   hisi_apb_c_bus_drv hisi_apb_drv[];

   // @ local
   ahb_sb_cb ahb_cb[];
   axi_sb_cb axi_cb[];

   ahb_common_sb ahb_sb[];
   axi_common_sb axi_sb[];

   `uvm_component_param_utils_begin(this_type)
   `uvm_component_utils_end

    extern function new(string name, uvm_component parent);
    //extern virtual function void get_linkbench_env_cfg();
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual function void end_of_elaboration_phase(uvm_phase phase);
    extern virtual task reset_phase(uvm_phase phase);
    extern virtual task configure_phase(uvm_phase phase);
    extern virtual task shutdown_phase(uvm_phase phase);
    extern virtual function void check_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
    extern virtual function void get_linkbench_env_cfg();

endclass: axi2axi_env


function my_linkbench_env::new(string name, uvm_component parent);
    super.new(name, parent);//调用父类uvm_component,注册到UVM树
endfunction: new

function void my_linkbench_env::get_linkbench_env_cfg();
    return;
endfunction:get_linkbench_env_cfg

以下是图片中的代码：

function void my_linkbench_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
//Changed by YS
    //if(this.linkbench_cfg == null)begin
    //  linkbench_cfg = linkbench_env_cfg#(T)::type_id::create("linkbench_cfg");
    //end
//end Change
    get_linkbench_env_cfg();
    if(this.linkbench_cfg == null) begin
        `uvm_fatal(get_type_name(), $sformatf("build_phase(): the my_linkbench_env need a linkbench_env_cfg, please confirm"))
    end
    `uvm_info(get_type_name(), $sformatf("build_phase(): The env configure display: 
%s", this.linkbench_cfg.sprint()), UVM_HIGH);

    //@mst_agent
    apb_mst_if_agent                  = new[T::APB_MST_NUM];                   /// < The apb_if_agent
    ahb_mst_if_agent                  = new[T::AHB_MST_NUM];                   /// < The ahb_if_agent
    axi_mst_if_agent                  = new[T::AXI_MST_NUM];                   /// < The axi_if_agent

    //@slv_agent
    apb_slv_if_agent                  = new[T::APB_SLV_NUM];                   /// < The apb_if_agent
    ahb_slv_if_agent                  = new[T::AHB_SLV_NUM];                   /// < The ahb_if_agent
    axi_slv_if_agent                  = new[T::AXI_SLV_NUM];                   /// < The axi_if_agent

    //@Q local
    axi_direct_drv_library            = new[T::AXI_MST_NUM];
    ahb_direct_drv_library            = new[T::AHB_MST_NUM];
    apb_direct_drv_library            = new[T::APB_MST_NUM];

    hisi_axi_drv                      = new[T::AXI_MST_NUM];
    hisi_ahb_drv                      = new[T::AHB_MST_NUM];
    hisi_apb_drv                      = new[T::APB_MST_NUM];

    //@Q local
    ahb_cb                            = new[T::AHB_MST_NUM];
    axi_cb                            = new[T::AXI_MST_NUM];

    ahb_sb                            = new[T::AHB_MST_NUM];
    axi_sb                            = new[T::AXI_MST_NUM];

this.vsqr = linkbench_virtual_sequencer#(T)::type_id::create("vsqr", this);

// @create apb_mst_if_agent
foreach(this.linkbench_cfg.apb_mst_if_agent_sw[i]) begin
    if(this.linkbench_cfg.apb_mst_if_agent_sw[i] == stb_dec::ON) begin
        this.apb_mst_if_agent[i] = my_apb_interface_agent::type_id::create($sformatf("apb_mst_if_agent[%0d]", i), this);
        this.apb_mst_if_agent[i].work_mode = this.linkbench_cfg.apb_mst_if_agent_work_mode[i];
        this.apb_mst_if_agent[i].cfg = this.linkbench_cfg.apb_mst_if_agent_cfg[i];
        `uvm_info(get_type_name(), $sformatf("build_phase():apb_mst_if_agent[%0d] has been constructed", i), UVM_HIGH);
    end
end

// @create ahb_mst_if_agent
foreach(this.linkbench_cfg.ahb_mst_if_agent_sw[i]) begin
    if(this.linkbench_cfg.ahb_mst_if_agent_sw[i] == stb_dec::ON) begin
        this.ahb_mst_if_agent[i] = ahb_interface_agent::type_id::create($sformatf("ahb_mst_if_agent[%0d]", i), this);
        this.ahb_mst_if_agent[i].work_mode = this.linkbench_cfg.ahb_mst_if_agent_work_mode[i];
        this.ahb_mst_if_agent[i].cfg = this.linkbench_cfg.ahb_mst_if_agent_cfg[i];
        `uvm_info(get_type_name(), $sformatf("build_phase():ahb_mst_if_agent[%0d] has been constructed", i), UVM_HIGH);
    end
end

// @create axi_mst_if_agent
foreach(this.linkbench_cfg.axi_mst_if_agent_sw[i]) begin
    if(this.linkbench_cfg.axi_mst_if_agent_sw[i] == stb_dec::ON) begin
        this.axi_mst_if_agent[i] = axi_interface_agent::type_id::create($sformatf("axi_mst_if_agent[%0d]", i), this);
        this.axi_mst_if_agent[i].work_mode = this.linkbench_cfg.axi_mst_if_agent_work_mode[i];
        this.axi_mst_if_agent[i].cfg = this.linkbench_cfg.axi_mst_if_agent_cfg[i];
        `uvm_info(get_type_name(), $sformatf("build_phase():axi_mst_if_agent[%0d] has been constructed", i), UVM_HIGH);
    end
end

// @create apb_slv_if_agent
foreach(this.linkbench_cfg.apb_slv_if_agent_sw[i]) begin
    if(this.linkbench_cfg.apb_slv_if_agent_sw[i] == stb_dec::ON) begin
        this.apb_slv_if_agent[i] = my_apb_interface_agent::type_id::create($sformatf("apb_slv_if_agent[%0d]", i), this);
        this.apb_slv_if_agent[i].work_mode = this.linkbench_cfg.apb_slv_if_agent_work_mode[i];
        this.apb_slv_if_agent[i].cfg = this.linkbench_cfg.apb_slv_if_agent_cfg[i];
        `uvm_info(get_type_name(), $sformatf("build_phase():apb_slv_if_agent[%0d] has been constructed", i), UVM_HIGH);
    end
end

// @create ahb_slv_if_agent
foreach(this.linkbench_cfg.ahb_slv_if_agent_sw[i]) begin
    if(this.linkbench_cfg.ahb_slv_if_agent_sw[i] == stb_dec::ON) begin
        this.ahb_slv_if_agent[i] = ahb_interface_agent::type_id::create($sformatf("ahb_slv_if_agent[%0d]", i), this);
        this.ahb_slv_if_agent[i].work_mode = this.linkbench_cfg.ahb_slv_if_agent_work_mode[i];
        this.ahb_slv_if_agent[i].cfg = this.linkbench_cfg.ahb_slv_if_agent_cfg[i];
        `uvm_info(get_type_name(), $sformatf("build_phase():ahb_slv_if_agent[%0d] has been constructed", i), UVM_HIGH);
    end
end

// @create axi_slv_if_agent
foreach(this.linkbench_cfg.axi_slv_if_agent_sw[i]) begin
    if(this.linkbench_cfg.axi_slv_if_agent_sw[i] == stb_dec::ON) begin
        this.axi_slv_if_agent[i] = axi_interface_agent::type_id::create($sformatf("axi_slv_if_agent[%0d]", i), this);
        this.axi_slv_if_agent[i].work_mode = this.linkbench_cfg.axi_slv_if_agent_work_mode[i];
        this.axi_slv_if_agent[i].cfg = this.linkbench_cfg.axi_slv_if_agent_cfg[i];
        `uvm_info(get_type_name(), $sformatf("build_phase():axi_slv_if_agent[%0d] has been constructed", i), UVM_HIGH);
    end
end

`uvm_info(get_type_name(),"build_phase():build_phase() finished",UVM_HIGH);
endfunction:build_phase
                                         

function void my_linkbench_env::connect_phase(uvm_phase phase);

   super.connect_phase(phase);

   //handle_connect vsqr.apb_mst_sqr -> apb_mst_if_agent.sqr
   foreach (this.linkbench_cfg.apb_mst_if_agent_sw[i])
   if(this.linkbench_cfg.apb_mst_if_agent_sw[i] == stb_dec::ON) begin
      this.vsqr.apb_mst_sqr[i] = this.apb_mst_if_agent[i].sqr;
   end

   //handle_connect vsqr.ahb_mst_sqr -> ahb_mst_if_agent.sqr
   foreach(this.linkbench_cfg.ahb_mst_if_agent_sw[i])
   if(this.linkbench_cfg.ahb_mst_if_agent_sw[i] == stb_dec::ON) begin
      this.vsqr.ahb_mst_sqr[i] = this.ahb_mst_if_agent[i].sqr;
   end

   //handle_connect vsqr.axi_mst_sqr -> axi mst_if_agent.sqr
   foreach(this.linkbench_cfg.axi_mst_if_agent_sw[i])
   if(this.linkbench_cfg.axi_mst_if_agent_sw[i] == stb_dec::ON) begin
      this.vsqr.axi_mst_sqr[i] = this.axi_mst_if_agent[i].sqr;
   end

   foreach(axi_direct_drv_library[i])
   if(this.linkbench_cfg.axi_mst_if_agent_sw[i] == stb_dec::ON) begin
      axi_direct_drv_library[i] = axi_ext_dir_sequence::type_id::create($sformatf("axi_drv_lib%0d",i));
      axi_direct_drv_library[i].p_sequencer = this.axi_mst_if_agent[i].sqr;
      hisi_axi_drv[i]=new(axi_direct_drv_library[i]);
      hisi_axi_drv[i].vip_id = i;
      uvm_config_db#(c_bus_base)::set(uvm_root::get(), "global_direct_drv", $psprintf("hisi_axi_drv%0d",i), this.hisi_axi_drv[i]);
   end

   `uvm_info(get_type_name(), $sformatf("hello %0d, size0 %0d, size1 %0d", T::AHB_MST_NUM, $size(ahb_direct_drv_library), $size(ahb_mst_if_agent)), UVM_NONE)

   foreach(ahb_direct_drv_library[i])
   if(this.linkbench_cfg.ahb_mst_if_agent_sw[i] == stb_dec::ON) begin
      ahb_direct_drv_library[i] = ahb_ext_dir_sequence::type_id::create($sformatf("ahb_drv_lib%0d",i));
      ahb_direct_drv_library[i].p_sequencer = this.ahb_mst_if_agent[i].sqr;
      hisi_ahb_drv[i]=new(ahb_direct_drv_library[i]);
      uvm_config_db#(c_bus_base)::set(uvm_root::get(), "global_direct_drv", $psprintf("hisi_ahb_drv%0d",i), this.hisi_ahb_drv[i]);
   end

   foreach(apb_direct_drv_library[i])
   if(this.linkbench_cfg.apb_mst_if_agent_sw[i] == stb_dec::ON) begin
      apb_direct_drv_library[i] = apb_ext_dir_sequence::type_id::create($sformatf("apb_drv_lib%0d",i));
      apb_direct_drv_library[i].p_sequencer = this.apb_mst_if_agent[i].sqr;
      hisi_apb_drv[i]=new(apb_direct_drv_library[i]);
      uvm_config_db#(c_bus_base)::set(uvm_root::get(), "global_direct_drv", $psprintf("hisi_apb_drv%0d",i), this.hisi_apb_drv[i]);
   end

  foreach(ahb_sb[sb_index])
    if(this.linkbench_cfg.ahb_slv_if_agent_sw[sb_index] == stb_dec::ON) begin
        this.ahb_sb[sb_index] = new($psprintf("ahb_sb%0d",sb_index),"../th/pmap/memory_map/name_addr_mask_cpu.txt");
        ahb_cb[sb_index]= new(ahb_sb[sb_index],$psprintf("hisi_amba_ahb_cb%0d",sb_index));
        uvm_callbacks #(ahb_driver)::add(ahb_mst_if_agent[sb_index].ahb_drv,ahb_cb[sb_index]);
    end

  foreach(axi_sb[sb_index])
     if(this.linkbench_cfg.axi_mst_if_agent_sw[sb_index] == stb_dec::ON) begin
        axi_sb[sb_index] = new($psprintf("axi_sb%0d",sb_index));
        axi_cb[sb_index]= new(axi_sb[sb_index],$psprintf("hisi_amba_axi_cb%0d",sb_index),axi_dec::axi_data_bus_width_enum'(this.linkbench_cfg.axi_mst_if_agent_cfg[sb_index].data_width));
        uvm_callbacks #(axi_driver)::add(axi_mst_if_agent[sb_index].axi_mst_drv,axi_cb[sb_index]);
     end

`uvm_info(get_type_name(), "connect_phase() finished", UVM_HIGH);
endfunction




                                         //end_of_elaboration ,reset,configure等phase不做其他设计
