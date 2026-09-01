
class apb_interface_agent_cfg extends uvm_object;

  rand apb_driver_cfg         drv_cfg;
  rand apb_monitor_cfg        mon_cfg;
  rand apb_slave_driver_cfg   slv_drv_cfg;

  rand bit rdata_x_statue_check_enable;
  rand bit resp_check_enable;
  rand bit addr_range_check_enable;    
  rand int addr_width;               
  rand int data_width ;             

  rand bit bus_check_enable ;
  rand bit memory_check_enable ;
  rand bit peri_dec_check_enable ;

  constraint check_enable_cons {
    soft this.rdata_x_statue_check_enable == 1'b1;    
    soft this.resp_check_enable == 1'b1;              
    soft this.addr_range_check_enable == 1'b1;        
    soft this.addr_width == 32;                      
    soft this.data_width == 32;                      
  }

  constraint mon_check_type_cons{
    bus_check_enable == 1'b1;
    memory_check_enable == 1'b1 ;
    peri_dec_check_enable == 1'b0 ;
  }

  `uvm_object_utils_begin(apb_interface_agent_cfg)
    `uvm_field_object(drv_cfg, UVM_ALL_ON)
    `uvm_field_object(mon_cfg, UVM_ALL_ON)
    `uvm_field_int(rdata_x_statue_check_enable, UVM_ALL_ON)
    `uvm_field_int(resp_check_enable, UVM_ALL_ON)
    `uvm_field_int(addr_range_check_enable, UVM_ALL_ON)
    `uvm_field_int(addr_width, UVM_ALL_ON)
    `uvm_field_int(data_width, UVM_ALL_ON)
    `uvm_field_int(bus_check_enable,UVM_ALL_ON)
    `uvm_field_int(memory_check_enable,UVM_ALL_ON)
    `uvm_field_int(peri_dec_check_enable,UVM_ALL_ON)
  `uvm_object_utils_end

  extern function new(string name = "apb_interface_agent_cfg");
  extern function void pre_randomize();
  extern function void post_randomize();

endclass: apb_interface_agent_cfg

function apb_interface_agent_cfg::new(string name = "apb_interface_agent_cfg");
    super.new(name);

    drv_cfg = apb_driver_cfg::type_id::create("drv_cfg");
    if (!drv_cfg.randomize()) begin
        `uvm_fatal(get_type_name(),"drv_cfg.randomize() call failed!")
    end

    mon_cfg = apb_monitor_cfg::type_id::create("mon_cfg");
    if (!mon_cfg.randomize()) begin
        `uvm_fatal(get_type_name(),"mon_cfg.randomize() call failed!")
    end

    slv_drv_cfg = apb_slave_driver_cfg::type_id::create("slv_drv_cfg");
    if (!slv_drv_cfg.randomize()) begin
        `uvm_fatal(get_type_name(),"slv_drv_cfg.randomize() call failed!")
    end

endfunction: new

function void apb_interface_agent_cfg::pre_randomize();
    super.pre_randomize();
    //-----------------------------------------------------------------------------//
    // Deciding whether complete it or not base on project requirement             //
    //-----------------------------------------------------------------------------//
endfunction: pre_randomize

function void apb_interface_agent_cfg::post_randomize();
    super.post_randomize();
    //-------------------------------------------------------------------------------//
    // Deciding whether complete it or not base on project requirement               //
    //-------------------------------------------------------------------------------//
    drv_cfg.rdata_x_statue_check_enable = rdata_x_statue_check_enable;
    drv_cfg.resp_check_enable           = resp_check_enable;
    mon_cfg.rdata_x_statue_check_enable = rdata_x_statue_check_enable;
    mon_cfg.resp_check_enable           = resp_check_enable;
    mon_cfg.addr_range_check_enable     = addr_range_check_enable;

    drv_cfg.addr_width                  = addr_width;
    mon_cfg.addr_width                  = addr_width;
    slv_drv_cfg.addr_width              = addr_width;
    drv_cfg.data_width                  = data_width;
    mon_cfg.data_width                  = data_width;
    slv_drv_cfg.data_width              = data_width;

    mon_cfg.bus_check_en                = bus_check_enable ;
    mon_cfg.memory_check_en             = memory_check_enable ;
    mon_cfg.peri_dec_check_en           = peri_dec_check_enable ;
endfunction: post_randomize
