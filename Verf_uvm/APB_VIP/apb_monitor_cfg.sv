`ifndef APB_MONITOR_CFG_SV
`define APB_MONITOR_CFG_SV

class apb_monitor_cfg extends uvm_object;

    bit rdata_x_statue_check_enable = 1'b1;
    bit resp_check_enable = 1'b1;
    bit [63:0] fromAddress[bit [63:0]];   //Add by z228374 for jira514
    bit [63:0] toAddress[bit [63:0]];     //Add by z228374 for jira514
    bit addr_range_check_enable;
    int pready_cnt = 500;                 //Add for jira833
    int addr_width = 32;                  //Add for jira1000
    int data_width = 32;                  //Add for jira1000
    //add for DTS2018110108555
    bit bus_check_en = 0;                 //indicate the bus check or not
    bit memory_check_en = 0;              //indicate the memory check or not
    bit peri_dec_check_en = 0;            //indicate the peri_dec check or not

    `uvm_object_utils_begin(apb_monitor_cfg)

        `uvm_field_int(rdata_x_statue_check_enable, UVM_ALL_ON)
        `uvm_field_int(resp_check_enable, UVM_ALL_ON)
        `uvm_field_int(addr_range_check_enable, UVM_ALL_ON)
        `uvm_field_int(pready_cnt, UVM_ALL_ON)
        `uvm_field_int(bus_check_en, UVM_ALL_ON)
        `uvm_field_int(memory_check_en, UVM_ALL_ON)
        `uvm_field_int(peri_dec_check_en, UVM_ALL_ON)

    `uvm_object_utils_end

endclass

`endif
