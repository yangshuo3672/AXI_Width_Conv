class stb_monitor #(type VIF = int) extends uvm_monitor;
    //传递VIF，子类继承该组件时，直接传递给接口类
  
   `uvm_component_param_utils(stb_monitor #(VIF))

   protected VIF bus;          ///<! Interface of monitor
   uvm_analysis_port #(uvm_sequence_item) out_port;  ///<! port of monitor to connect outside component such as rm
   uvm_sequence_item proto;    ///<! Prototype sequence item

   extern function new(string name, uvm_component parent);
   extern virtual function void build_phase(uvm_phase phase);
     
endclass: stb_monitor

function stb_monitor::new(string name, uvm_component parent);

   super.new(name, parent);

   this.proto = uvm_sequence_item::type_id::create("proto", this);
   this.out_port = new("out_port", this);
   `uvm_info(get_type_name(), "new(): stb_monitor has been constructed", UVM_HIGH);

endfunction: new

function void stb_monitor::build_phase(uvm_phase phase);

   super.build_phase(phase);

   if(!uvm_config_db#(VIF)::get(this, "", "bus", this.bus)) begin
      uvm_error(get_type_name(), "build_phase(): Virtual interface in monitor is not configured");
   end
   `uvm_info(get_type_name(), "build_phase(): stb_monitor build_phase is done", UVM_HIGH);

endfunction: build_phase
