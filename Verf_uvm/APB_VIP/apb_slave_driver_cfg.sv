int addr_width = 32;
int data_width = 32;
`uvm_object_utils_begin(apb_slave_driver_cfg);
    `uvm_filed_int(addr_width,UVM_ALL_ON);
    `uvm_filed_int(data_width,UVM_ALL_ON);
`uvm_object_utils_end
