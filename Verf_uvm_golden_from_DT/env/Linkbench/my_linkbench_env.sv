
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

