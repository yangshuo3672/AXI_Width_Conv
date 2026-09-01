
class apb_reg_adapter extends stb_reg_adapter;
  `uvm_object_utils(apb_reg_adapter)
  extern function new(string name = "apb_reg_adapter");
  extern virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
  extern virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
endclass: apb_reg_adapter

function apb_reg_adapter::new(string name = "apb_reg_adapter");
  super.new(name);
  this.provides_responses = 1 ;
endfunction: new

function uvm_sequence_item apb_reg_adapter::reg2bus(const ref uvm_reg_bus_op rw);
  apb_xaction rw_access = apb_xaction::type_id::create("rw_access");
  rw_access.dir     = (rw.kind == UVM_READ) ? apb_dec::READ : apb_dec::WRITE;
  rw_access.addr    = rw.addr;
  rw_access.data    = rw.data[31:0];
  rw_access.strb    = 4'hf;
  if (this.provides_responses==1)begin
    rw_access.seq_need_resp = 1;
  end
  `uvm_info(get_type_name(), $sformatf("reg2bus(): Translating uvm_reg_bus_op into %s:
 %s", rw_access.get_type_name(), rw_access.sprint()), UVM_HIGH);
  return rw_access;
endfunction: reg2bus

function void apb_reg_adapter::bus2reg(uvm_sequence_item bus_item,  ref uvm_reg_bus_op rw);
  apb_xaction rw_access;
  if (!$cast(rw_access, bus_item)) begin
    `uvm_fatal(get_type_name(), "bus2reg(): Bus item is not of type apb_xaction or its extension");
    return;
  end

  rw.kind   = (rw_access.dir == apb_dec::READ) ? UVM_READ : UVM_WRITE;
  rw.addr   = rw_access.addr;
  rw.data   = rw_access.data[31:0];

  if (this.provides_responses==1)begin
    rw_access.seq_need_resp = 1;
  end
  if(rw_access.resp != 1'b0) begin
    rw.status = UVM_NOT_OK;
    `uvm_error(get_type_name(),$sformatf("Resp is not OK! resp is %0h", rw_access.resp));
  end
  else begin
    rw.status = UVM_IS_OK;
  end
  `uvm_info(get_type_name(), $sformatf("bus2reg(): Translating %s into uvm_reg_bus_op %s:
 %s", rw_access.get_type_name(), rw_access.get_type_name(), rw_access.sprint()), UVM_HIGH);
endfunction: bus2reg
