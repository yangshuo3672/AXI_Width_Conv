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
      //  %%%%%%%%%%%%%%%
      //  Coding end
  
endfunction: post_randomize 

`endif
    
