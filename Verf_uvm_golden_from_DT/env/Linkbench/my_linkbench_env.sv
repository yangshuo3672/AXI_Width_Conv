
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


