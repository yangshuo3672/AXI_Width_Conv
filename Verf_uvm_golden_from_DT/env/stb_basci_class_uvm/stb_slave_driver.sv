class stb_slave_driver #(type VIF = int) extends uvm_driver #(uvm_sequence_item);

`uvm_component_param_utils(stb_slave_driver #(VIF))

protected VIF bus;              /// < Interface of slave driver
extern function new(string name,
                    uvm_component parent
                   );
extern virtual function void build_phase(uvm_phase phase);

endclass:stb_slave_driver

function stb_slave_driver::new(string name,
                               uvm_component parent
                              );

super.new(name, parent);
`uvm_info(get_type_name(), "new(): stb_slave_driver has been constructed", UVM_HIGH);

endfunction: new

function void stb_slave_driver::build_phase(uvm_phase phase);

super.build_phase(phase);

if(!uvm_config_db#(VIF)::get(this, "", "bus", this.bus)) begin
`uvm_error(get_type_name(),"build_phase(): Virtual interface in slave driver is not configured");
end
`uvm_info(get_type_name(), "build_phase(): stb_slave_driver build_phase is done", UVM_HIGH);

endfunction: build_phase
