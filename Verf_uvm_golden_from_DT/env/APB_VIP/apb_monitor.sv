`ifndef APB_MONITOR__SV
`define APB_MONITOR__SV

`define APB_MONITOR_IF this.bus.Monitor.monitor_cb
`define APB_MONITOR_BUS bus

//..................................................................................
// APB Monitor Callback Class
//..................................................................................

typedef class apb_monitor;

class apb_monitor_callbacks extends uvm_callback;

    extern function new(string name = "apb_monitor_callbacks");
    extern virtual task monitor_pre_rx(apb_monitor     apb_mon,
                                       ref apb_xaction trans);
    //add for cmd callback,DTS2019051303955
    extern virtual task monitor_addr_rx(apb_monitor     apb_mon,
                                        apb_xaction     trans);

    extern virtual task monitor_post_rx(apb_monitor     apb_mon,
                                        apb_xaction     trans);
    `uvm_object_utils(apb_monitor_callbacks)

endclass: apb_monitor_callbacks

function apb_monitor_callbacks::new(string name = "apb_monitor_callbacks");

    super.new(name);
    `uvm_info(get_type_name(),"coming into the function of the new",UVM_HIGH);

endfunction: new

task apb_monitor_callbacks::monitor_pre_rx(apb_monitor     apb_mon,
                                           ref apb_xaction trans);
endtask

task apb_monitor_callbacks::monitor_addr_rx(apb_monitor     apb_mon,
                                            apb_xaction     trans);
endtask

task apb_monitor_callbacks::monitor_post_rx(apb_monitor     apb_mon,
                                            apb_xaction     trans);
endtask

