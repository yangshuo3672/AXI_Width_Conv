`ifndef AXI2AXI_ENV_CFG__SV
`define AXI2AXI_ENV_CFG__SV

class axi2axi_env_cfg extends linkbench_env_cfg#(axi2axi_env_dec);

  `uvm_object_utile_begin(axi2axi_env_cfg)
  `uvm_object_utils_end

  extern function new(string name = "axi2axi_env_cfg" );
  extern function void pre_randomize();
  extern function void post_randomize();

endclass:axi2axi_env_cfg

function axi2axi_env_cfg::new(string name = "axi2axi_env_cfg");
      super.new(name);
endfunction: new

function void axi2axi_env_cfg::pre_randomize();
    super.pre_randomize();
endfunction: pre_randomize 

function void axi2axi_env_cfg::post_randomize();
    super.post_randomize();
endfunction: post_randomize 

`endif
    
