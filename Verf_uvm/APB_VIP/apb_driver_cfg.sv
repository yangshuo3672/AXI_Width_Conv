`ifndef APB_DRIVER_CFG__SV
`define APB_DRIVER_CFG__SV

//apb interface agent driver configuration
//This class contains the configuration for the apb interface agent driver

//这个APB agent配置类包含的配置项包括：位宽、开启不定态检查，响应检查使能、idle态驱动为什么
class apb_driver_cfg extends uvm_object;

  bit rdata_x_statue_check_enable = 1'b1;
  bit resp_check_enable           = 1'b1;
  bit [1:0] do_idle_state         = 2'b0; //0: drive 0  //1: drive random //2: stable //3: NONE

  int pready_cnt = 500;           //Add for jira833
  int addr_width = 32 ;           //Add for jira1000
  int data_width = 32 ;           //Add for jira1000
  //-------------------------------Coding end-------------------------------//

  //注册到工厂
  `uvm_object_utils_begin(apb_driver_cfg)
      `uvm_field_int(rdata_x_statue_check_enable, UVM_ALL_ON)
      `uvm_field_int(resp_check_enable, UVM_ALL_ON)
      `uvm_field_int(do_idle_state, UVM_ALL_ON)
      `uvm_field_int(pready_cnt, UVM_ALL_ON)
      `uvm_field_int(addr_width, UVM_ALL_ON)
      `uvm_field_int(data_width, UVM_ALL_ON)
  `uvm_object_utils_end


  extern function new (string name = "apb_driber_cfg" );
  extern function void pre_randomize();
  extern function void post_randomize();

endclass:apb_driver_cfg

function apb_driver_cfg::new(string name = "apb_driver_cfg");
   super.new(name);
endfunction: new

function void apb_driver_cfg::pre_randomize;
  super.pre_randomize();
endfunction: pre_randomzie


function void apb_driver_cfg::post_randomize;
  super.post_randomize();
endfunction: post_randomzie


`endif


    


  
