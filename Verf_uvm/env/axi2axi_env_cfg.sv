`ifndef AXI2AXI_ENV_CFG__SV
`define AXI2AXI_ENV_CFG__SV

//environment configuration
//This class contains the configuration for blk_a environment

class axi2axi_env_cfg extends linkbench_env_cfg#(axi2axi_env_dec);

  // Declare the variables base on project requirement.
  // Coding begin 
  //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // rand int  post_consent;
  // rand int  sim_timeout;
  // Coding end
  
  // Declare variables constraints base on project requirement
  // Coding begin
  //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // constraint post_consent_cons;
  // constraint sim_timeout_cons;
  // Coding end
  
  `uvm_object_utile_begin(axi2axi_env_cfg)

  //Add variables into fiels-automation base on project requirement
  //Coding begin
  //%%%%%%%%%%%%%%%%%%%
  //Coding end
  
  `uvm_object_utils_end

  //new() Constructos
  extern function new(string name = "axi2axi_env_cfg" );
  extern function void pre_randomize();     //Handle random data information before randomize
  extern function void post_randomize();    //Handle random data information after randomize

  //Add task or function base on project requirement
  //Coding begin
  //%%%%%%%%%%%%%%%%%
  //Coding end

endclass:axi2axi_env_cfg

//Implement constraints base on project requirement
//Coding begin
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//constraint axi2axi_env_cfg::post_consent_cons{ this.post_consent = 0 ;}
//Coding end

function axi2axi_env_cfg::new(string name = "axi2axi_env_cfg");
      super.new(name);
      //  Add the initial of variables base on project requiement
      //  Coding begin
      //  %%%%%%%%%%%%%%%
      //  Coding end
  
endfunction: new

function void axi2axi_env_cfg::pre_randomize();
    super.pre_randomize();
      //  Extend pre_randomize() base on project requiement
      //  Coding begin
      //  %%%%%%%%%%%%%%%
      //  Coding end
  
endfunction: pre_randomize 

function void axi2axi_env_cfg::post_randomize();
    super.post_randomize();
      //  Extend post_randomize() base on project requiement
      //  Coding begin
this.axi_mst_if_agent_cfg[0].data_width = 'd128;
this.axi_mst_if_agent_cfg[0].addr_width = 'd32;
this.axi_mst_if_agent_cfg[0].id_width = 'd8;
this.axi_mst_if_agent_cfg[0].wrid_width = 'd8;
this.axi_mst_if_agent_cfg[0].rdid_width = 'd8;

this.axi_slv_if_agent_cfg[0].data_width = 'd64;
this.axi_slv_if_agent_cfg[0].addr_width = 'd32;
this.axi_slv_if_agent_cfg[0].id_width = 'd8;
this.axi_slv_if_agent_cfg[0].wrid_width = 'd8;
this.axi_slv_if_agent_cfg[0].rdid_width = 'd8;

//APB
this.apb_mst_if_agent_cfg[0].data_width = 'd32;
this.apb_mst_if_agent_cfg[0].addr_width = 'd12;
this.apb_mst_if_agent_work_mode[0] = stb_dec::REG_MASTER_NO_MONITOR;//TODO
this.apb_mst_if_agent_sw[0] = stb_dec::ON;

//mon
this.axi_mst_if_agent_cfg[0].mon_cfg.fcov_cfg.out_of_order_depth_max = 16;
this.axi_mst_if_agent_cfg[0].mon_cfg.fcov_cfg.interleave_depth_max = 16;
this.axi_mst_if_agent_cfg[0].mon_cfg.fcov_cfg.addr_max = 32'hffffffff;
this.axi_mst_if_agent_cfg[0].mon_cfg.fcov_cfg.id_max = 8'hff;

this.axi_slv_if_agent_cfg[0].mon_cfg.fcov_cfg.out_of_order_depth_max = 16;
this.axi_slv_if_agent_cfg[0].mon_cfg.fcov_cfg.interleave_depth_max = 16;
this.axi_slv_if_agent_cfg[0].mon_cfg.fcov_cfg.addr_max = 32'hffffffff;
this.axi_slv_if_agent_cfg[0].mon_cfg.fcov_cfg.id_max = 8'hff;
      //  %%%%%%%%%%%%%%%
      //  Coding end
  
endfunction: post_randomize 

`endif
    
