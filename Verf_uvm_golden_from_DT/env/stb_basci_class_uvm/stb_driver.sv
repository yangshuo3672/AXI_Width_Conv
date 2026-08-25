class stb_driver #(type VIF = int) extends uvm_driver #(uvm_sequence_item);
     
     //参数化Driver基类模版
     //注意：VIF属于传递进来的参数句柄，比如在子类继承的时候，有一个class my_apb_driver extends stb_driver#(virtual apb_interface);
     //具体应用可见APB VIP Driver
     //这个stb平台的代码主要为后续Driver组件开发提供基类，完成虚拟接口配置，out_port广播口例化等重复和重要操作，后续组件开发只需要将接口句柄传递进去即可，不需要在agent代码中进行配置
     
  `uvm_component_param_utils(stb_driver #(VIF))//参数化的component的工厂注册，与 `uvm_component_utils作区分
     
      protected VIF bus;  //虚拟接口句柄，受保护限制（子类可访问，外部不可访问）
      uvm_analysis_port #(uvm_sequence_item) out_port;  //广播端口，driver除了从sequencer获取item驱动DUT，还需要把驱动过的transaction广播给Scoreboard，Coverage Collector等

     extern function new(string name,
                         uvm_component parent
                        );
     extern virtual function void build_phase(uvm_phase phase);
     extern virtual task drv_random();

endclass:stb_driver

function stb_driver::new(string name, uvm_component parent);
    super.new(name, parent);
    this.out_port = new("out_port", this);//显式创建analysis port
    `uvm_info(get_type_name(), "new(): stb_driver has been constructed", UVM_HIGH);
endfunction: new

function void stb_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
  if(!uvm_config_db#(VIF)::get(this,"","bus", this.bus)) begin    //配置数据库中按层次获取虚拟接口。
        `uvm_error(get_type_name(), "build_phase(): Virtual interface in driver is not configured");
    end
    `uvm_info(get_type_name(), "build_phase(): stb_driver build_phase is done", UVM_HIGH);
endfunction: build_phase

task stb_driver::drv_random();
    `uvm_info(get_type_name(), "drv_random(): Start driver random data to DUT", UVM_HIGH);
endtask: drv_random
