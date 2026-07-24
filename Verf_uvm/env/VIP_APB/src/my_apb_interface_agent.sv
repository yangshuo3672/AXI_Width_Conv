`ifndef  MY_APB_INTERFACE_AGENT__SV
`define  MY_APB_INTERFACE_AGENT__SV

class my_apb_interface_agent extends stb_interface_agent #(virtual apb_interface);

    my_apb_driver           apb_drv;        // Apb driver
    apb_monitor             apb_mon;        // Apb monitor
    apb_slave_driver        apb_slv_drv;    // Apb slave driver
    apb_reg_adapter         reg_adapter;
    uvm_sequencer #(uvm_sequence_item)  apb_sqr;   
    apb_interface_agent_cfg cfg;

    `uvm_component_utils_begin(my_apb_interface_agent)
        `uvm_field_object(cfg, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual function void mapMemorySegment(bit[63:0] fromAddress, bit[63:0] toAddress);

endclass: my_apb_interface_agent

function my_apb_interface_agent::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction: new


function void my_apb_interface_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(cfg == null) begin
        cfg = apb_interface_agent_cfg::type_id::create("cfg", this);
        uvm_info(get_type_name(), "build_phase(): Randomizing my_apb_interface_agent configuration object", UVM_HIGH);
        if (!cfg.randomize()) begin
            `uvm_fatal(get_type_name(),"build_phase(): cfg.randomize() call failed!");
        end
    end

    if(this.sqr_sw == stb_dec::ON) begin
        this.apb_sqr = uvm_sequencer#(uvm_sequence_item)::type_id::create("apb_sqr", this);
        if(!$cast(this.sqr, this.apb_sqr)) begin
            `uvm_fatal(get_type_name(), "new(): apb_sqr is not a uvm_sequencer type or its extension");
        end
    end

    if(drv_sw == stb_dec::ON) begin
        apb_drv = my_apb_driver::type_id::create("apb_drv", this);
        if(!$cast(drv, apb_drv)) begin
            `uvm_fatal(get_type_name(),"new(): apb_drv is not a stb_driver type or its extension");
        end
        apb_drv.cfg = cfg.drv_cfg;
    end

    if(mon_sw == stb_dec::ON) begin
        apb_mon = apb_monitor::type_id::create("apb_mon", this);
        if(!$cast(mon, apb_mon)) begin
            `uvm_fatal(get_type_name(),"new(): apb_mon is not a stb_monitor type or its extension");
        end
        apb_mon.cfg = cfg.mon_cfg;
    end

    if(slv_drv_sw == stb_dec::ON) begin
        apb_slv_drv = apb_slave_driver::type_id::create("apb_slv_drv", this);
        if(!$cast(slv_drv, apb_slv_drv)) begin
            `uvm_fatal(get_type_name(),"new(): apb_slv_drv is not a stb slave_driver type or its extension");
        end
        apb_slv_drv.cfg = cfg.slv_drv_cfg;
    end
    if(adapter_sw == stb_dec::ON) begin
        reg_adapter = apb_reg_adapter::type_id::create("reg_adapter",,get_full_name());
        if(!$cast(adapter, reg_adapter)) begin
             `uvm_fatal(get_type_name(),"new(): reg_adapter is not a uvm_reg_adapter type or its extension");
        end
    end
endfunction:build_phase

function void my_apb_interface_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
endfunction: connect_phase

function void my_apb_interface_agent::mapMemorySegment(bit[63:0] fromAddress, bit[63:0] toAddress);
    if(!this.apb_mon.cfg.fromAddress.exists(fromAddress)) begin
        this.apb_mon.cfg.fromAddress[fromAddress] = fromAddress;
        this.apb_mon.cfg.toAddress[fromAddress] = toAddress;
    end
    else begin
        `uvm_warning(get_type_name(), "The fromAddress or the toAddress has been write before");
    end
endfunction: mapMemorySegment

`endif //MY_APB_INTERFACE_AGENT__SV
