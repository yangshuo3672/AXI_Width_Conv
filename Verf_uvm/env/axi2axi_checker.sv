`ifndef AXI2AXI_BASIC_CHECKER__SV
`define AXI2AXI_BASIC_CHECKER__SV

class axi2axi_basic_checker extends stb_basic_checker;

  extern function new(string name,
                      uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);
endclass: axi2axi_basic_checker

function axi2axi_basic_checker::new(string name,
                                    uvm_component parent
                                   );

  super.new(name, parent);
endfunction: new

function void axi2axi_basic_checker::build_phase(uvm_phase phase);

  super.build_phase(phase);
endfunction: build_phase

function void axi2axi_basic_checker::connect_phase(uvm_phase phase);

  super.connect_phase(phase);
endfunction: connect_phase

task axi2axi_basic_checker::run_phase(uvm_phase phase);

  //do nothing
  //super.run_phase(phase);
endtask: run_phase

function void axi2axi_basic_checker::check_phase(uvm_phase phase);

  //do nothing
  //super.check_phase(phase);
endfunction: check_phase

`endif
