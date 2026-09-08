class stb_reg_adapter extends uvm_reg_adapter;

   `uvm_object_utils(stb_reg_adapter)
   uvm_sequence_item proto;
   extern function new(string name = "stb_reg_adapter");
   extern virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
   extern virtual function void bus2reg(uvm_sequence_item bus_item,ref uvm_reg_bus_op rw);

endclass: stb_reg_adapter

function stb_reg_adapter::new(string name = "stb_reg_adapter");
   super.new(name);
endfunction: new

function uvm_sequence_item stb_reg_adapter::reg2bus(const ref uvm_reg_bus_op rw);
    stb_rw_sequence_item rw_sequence_item;
    if(this.proto == null) begin
        `uvm_fatal(get_type_name(), "reg2bus(): Required prototype argument is null");
    end

    if(!$cast(rw_sequence_item, this.proto.create()))begin
        `uvm_fatal(get_type_name(), "reg2bus(): Proto is not of type stb_rw_sequence_item or its extension");
    end
    rw_sequence_item.data = new[1];
    rw_sequence_item.n_beats = 1;
    rw_sequence_item.op_type = rw.kind;
    rw_sequence_item.addr  = rw.addr;
    rw_sequence_item.data[0] = rw.data;
    `uvm_info(get_type_name(), $sformatf("reg2bus(): Translating uvm_reg_bus_op into %s", rw_sequence_item.get_type_name()), UVM_HIGH);
    return rw_sequence_item;

endfunction: reg2bus

function void stb_reg_adapter::bus2reg(uvm_sequence_item bus_item,
    ref uvm_reg_bus_op rw);
    stb_rw_sequence_item rw_sequence_item;
    if (!$cast(rw_sequence_item, bus_item)) begin
        `uvm_fatal(get_type_name(), "bus2reg(): Bus item is not of type stb_rw_sequence_item or its extension")
    end
    rw.kind  = rw_sequence_item.op_type;
    rw.addr = rw_sequence_item.addr;
    rw.data = rw_sequence_item.data[0];
    rw.status = UVM_IS_OK;
    `uvm_info(get_type_name(), $sformatf("bus2reg(): Translating %s into uvm_reg_bus_op", rw_sequence_item.get_type_name()), UVM_HIGH);

endfunction: bus2reg
