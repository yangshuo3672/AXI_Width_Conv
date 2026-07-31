`ifndef TC_wvalid_wready_DELAY_SV
`define TC_wvalid_wready_DELAY_SV

`define tc_name tc_wvld_wrdy_delay

class `axi2axi_env_cfg(`tc_name) extends axi2axi_env_cfg;

  `uvm_object_utils(`axi2axi_env_cfg(`tc_name))

  function new(string name = "name");
    super.new(name);
  endfunction

  function void post_randomize();
    super.post_randomize();

    axi_mst_if_agent_cfg[0].mon_cfg.funcov_enable = 0;
    axi_slv_if_agent_cfg[0].mon_cfg.funcov_enable = 0;

    axi_mst_if_agent_cfg[0].out_of_bresp = 1;
    axi_mst_if_agent_cfg[0].out_of_rresp = 1;
    axi_mst_if_agent_cfg[0].rdintrlv_depth = 16;
    axi_mst_if_agent_cfg[0].wrintrlv_depth = 1;
    axi_mst_if_agent_cfg[0].wr_outstanding = 16;
    axi_mst_if_agent_cfg[0].rd_outstanding = 16;
    axi_mst_if_agent_cfg[0].no_delay_enable = 0;
    axi_mst_if_agent_cfg[0].disable_exception_check = 0;
    axi_mst_if_agent_cfg[0].disable_exception_write_4kexceed_check = 0;
    axi_mst_if_agent_cfg[0].skip_4k_boundary_split = 1;
    axi_mst_if_agent_cfg[0].mst_drv_cfg.m_enDefaultBready = axi_dec::VMT_BOOLEAN_TRUE;
    axi_mst_if_agent_cfg[0].mst_drv_cfg.m_enDefaultBready = axi_dec::VMT_BOOLEAN_TRUE;
    axi_mst_if_agent_cfg[0].mst_drv_cfg.ainfo_hold_when_invalid = axi_dec::VMT_FALSE;
    axi_mst_if_agent_cfg[0].mst_drv_cfg.ainfo_random_when_invalid = axi_dec::VMT_TRUE;
    axi_mst_if_agent_cfg[0].mst_drv_cfg.winfo_random_when_invalid = axi_dec::VMT_TRUE;
    axi_mst_if_agent_cfg[0].mst_drv_cfg.last_random_when_invalid = axi_dec::VMT_TRUE;

    axi_slv_if_agent_cfg[0].out_of_bresp = 1;
    axi_slv_if_agent_cfg[0].out_of_rresp = 1;
    axi_slv_if_agent_cfg[0].rdintrlv_depth = 16;
    axi_slv_if_agent_cfg[0].wrintrlv_depth = 1;
    axi_slv_if_agent_cfg[0].wr_outstanding = 16;
    axi_slv_if_agent_cfg[0].rd_outstanding = 16;
    axi_slv_if_agent_cfg[0].no_delay_enable = 0;
    axi_slv_if_agent_cfg[0].disable_exception_check = 0;
    axi_slv_if_agent_cfg[0].disable_exception_write_4kexceed_check = 0;
    axi_slv_if_agent_cfg[0].skip_4k_boundary_split = 1;
    axi_slv_if_agent_cfg[0].slv_drv_cfg.m_enDefaultArready = axi_dec::VMT_BOOLEAN_TRUE;
    axi_slv_if_agent_cfg[0].slv_drv_cfg.m_enDefaultAwready = axi_dec::VMT_BOOLEAN_TRUE;
    axi_slv_if_agent_cfg[0].slv_drv_cfg.m_enDefaultWready = axi_dec::VMT_BOOLEAN_TRUE;
    axi_slv_if_agent_cfg[0].slv_drv_cfg.binfo_random_when_invalid = axi_dec::VMT_TRUE;
    axi_slv_if_agent_cfg[0].slv_drv_cfg.rinfo_random_when_invalid = axi_dec::VMT_TRUE;

    axi_slv_if_agent_cfg[0].m_enMemoryDefaultPattern = axi_dec::PATTERN_RANDOM;

  endfunction

endclass

`endif
endfunction

endclass: `axi2axi_env_cfg(`tc_name)

class `tc_name extends tc_base;

    `axi2axi_env_cfg(`tc_name) axi2axi_env_cfg;

    `uvm_component_utils_begin(`tc_name)
        `uvm_field_object(axi2axi_env_cfg, UVM_ALL_ON)
    `uvm_component_utils_end

    ktp_axi_driver_callback my_axi_drv_cb;
    ktp_axi_slave_driver_callback my_axi_slv_drv_cb;

    KTP_CSTR ktp_cstr;

    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual function void end_of_elaboration_phase(uvm_phase phase);
    extern virtual task reset_phase(uvm_phase phase);
    extern virtual task configure_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
    extern virtual task shutdown_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);

endclass: `tc_name

function `tc_name::new(string name,
                       uvm_component parent
                      );

    super.new(name,parent);

endfunction

function void `tc_name::build_phase(uvm_phase phase);

    super.build_phase(phase);

    this.axi2axi_env_cfg = `axi2axi_env_cfg(`tc_name)::type_id::create("axi2axi_env_cfg", this);
    if (!this.axi2axi_env_cfg.randomize()) begin
        `uvm_fatal(get_type_name(), "build_phase(): Unable to randomize cfg in testcase.");
    end
    this.env.cfg = this.axi2axi_env_cfg;

    this.my_axi_drv_cb = ktp_axi_driver_callback::type_id::create("my_axi_drv_cb");
    if (!this.my_axi_drv_cb.randomize()) begin
        `uvm_fatal(get_type_name(), "build_phase(): Unable to randomize my_axi_drv_cb in testcase.");
    end
    this.my_axi_slv_drv_cb = ktp_axi_slave_driver_callback::type_id::create("ktp_axi_slv_drv_cb");
    if (!this.my_axi_slv_drv_cb.randomize()) begin

   `uvm_fatal(get_type_name(), "build_phase(): Unable to randomize my_axi_slv_drv_cb in testcase.");
end

my_axi_drv_cb.next_avalid_delay = 0;
my_axi_drv_cb.avalid_wvalid_delay = 0;
my_axi_drv_cb.next_wvalid_delay = 0;
my_axi_drv_cb.bvalid_bready_delay = 0;
my_axi_drv_cb.bready_delay = 0;
my_axi_drv_cb.rvalid_rready_delay = 0;
my_axi_drv_cb.rready_delay = 0;

my_axi_slv_drv_cb.avalid_aready_delay = 0;
my_axi_slv_drv_cb.default_aready_delay = 0;
my_axi_slv_drv_cb.wvalid_wready_delay = $urandom_range(0,50);
my_axi_slv_drv_cb.default_wready_delay = 0;
my_axi_slv_drv_cb.write_bvalid_delay = 0;
my_axi_slv_drv_cb.address_rvalid_delay = 0;
my_axi_slv_drv_cb.next_rvalid_delay = 0;

ktp_cstr = new();

endfunction

function void `tc_name::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    uvm_callbacks #(axi_driver, axi_driver_callbacks)::add(env.axi_mst_if_agent[0].axi_mst_drv, my_axi_drv_cb);
    uvm_callbacks #(axi_slave_driver, axi_slave_driver_callbacks)::add(env.axi_slv_if_agent[0].axi_slv_drv, my_axi_slv_drv_cb);
endfunction: connect_phase

function void `tc_name::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "end_of_elaboration_phase(): end_of_elaboration_phase finished", UVM_HIGH);
endfunction

task `tc_name::reset_phase(uvm_phase phase);
    super.reset_phase(phase);
    phase.raise_objection(this);
    
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "reset_phase(): reset_phase finished", UVM_HIGH);
endtask: reset_phase

task `tc_name::configure_phase(uvm_phase phase);
    super.configure_phase(phase);
    phase.raise_objection(this);
    
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "configure phase(): configure phase finished", UVM_HIGH);
endtask: configure_phase

task `tc_name::main_phase(uvm_phase phase);
    logic [1023:0] rdata [];
    logic [1023:0] wdata [];
    bit  [ 127:0] w_strb [];
    axi_sequence u_axi_seq;

    super.main_phase(phase);
    phase.raise_objection(this);

    u_axi_seq = axi_sequence::type_id::create("u_axi_seq", this);

    `uvm_info(get_type_name(), $sformatf("send seq to drv"), UVM_NONE)
    for(int i = 0; i < 32; i = i + 1) begin
        fork
            automatic int m = i;
            assert(ktp_cstr.randomize());
            u_axi_seq.axi_write(env.axi_mst_if_agent[0].sqr, ktp_cstr.id, 1, ktp_cstr.length, 4, ktp_cstr.addr, 0, 0, 0, 0, 0, wdata, w_strb, 0, 0);
            u_axi_seq.axi_read(env.axi_mst_if_agent[0].sqr, ktp_cstr.id, 1, ktp_cstr.length, 4, ktp_cstr.addr, 0, 0, 0, 0, 0, rdata, 0, 0);
        join_none
    end

    #100us;
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "main_phase(): main_phase finished", UVM_HIGH);
endtask: main_phase

task `tc_name::shutdown_phase(uvm_phase phase);

    super.shutdown_phase(phase);
    phase.raise_objection(this);

    phase.drop_objection(this);
    `uvm_info(get_type_name(), "shutdown_phase(): shutdown_phase finished", UVM_HIGH);
endtask: shutdown_phase

function void `tc_name::report_phase(uvm_phase phase);

    super.report_phase(phase);

    `uvm_info(get_type_name(), "report_phase(): report_phase finished", UVM_HIGH);
endfunction: report_phase

undef tc_name
`endif

      
  
