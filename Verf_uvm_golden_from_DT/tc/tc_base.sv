class tc_base extends uvm_test;

    `uvm_component_utils(tc_base)

    axi2axi_env env;

    c_bus_base XM[axi2axi_env_dec::AXI_MST_NUM];

    extern function new(string name = "tc_base", uvm_component parent);

    extern virtual function void build_phase(uvm_phase phase);

    extern virtual function void connect_phase(uvm_phase phase);

    extern virtual function void end_of_elaboration_phase(uvm_phase phase);

    extern virtual task shutdown_phase(uvm_phase phase);

    extern virtual function void check_phase(uvm_phase phase);

    extern virtual task end_of_sim_chk();
  
    extern virtual task end_of_sim_chk();

    extern virtual function void report_phase(uvm_phase phase);

    extern virtual function void pre_abort();
endclass

function tc_base::new(string name = "tc_base", uvm_component parent);
    super.new(name, parent);
endfunction: new

function void tc_base::build_phase(uvm_phase phase);
    super.build_phase(phase);
    this.env = axi2axi_env::type_id::create("env", this);
endfunction: build_phase

function void tc_base::connect_phase(uvm_phase phase);

    super.connect_phase(phase);

endfunction: connect_phase

function void tc_base::end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);

    if ($test$plusargs("UVM_VERBOSITY=UVM_DEBUG")) begin
        uvm_top.print_topology();
        factory.print();
    end

    foreach (XM[i]) begin
        uvm_config_db#( c_bus_base ) ::get( uvm_root::get( ), "global_direct_drv",$psprintf( "hisi_axi_drv%0d",i ), XM[i] );
    end

    `uvm_info(get_type_name(), "end_of_elaboration_phase(): end_of_elaboration_phase() finished", UVM_HIGH);

endfunction: end_of_elaboration_phase

task tc_base::shutdown_phase(uvm_phase phase);

    super.shutdown_phase(phase);

    phase.raise_objection(this);

    end_of_sim_chk();
    `uvm_info(get_type_name(), "shutdown_phase(): end_of_sim_chk() execute", UVM_HIGH);

    phase.drop_objection(this);
    `uvm_info(get_type_name(), "shutdown_phase(); shutdown_phase() finished", UVM_HIGH);

endtask: shutdown_phase

function void tc_base::check_phase(uvm_phase phase);

    super.check_phase(phase);

    if ($test$plusargs("UVM_VERBOSITY=UVM_DEBUG")) begin
        check_config_usage();
    end

    `uvm_info(get_type_name(), "check_phase(): check_phase() finished", UVM_HIGH);

endfunction: check_phase

task tc_base::end_of_sim_chk();

//........................................................................//
// Check DUT registers value based on project requirement                //
//........................................................................//
//................................Coding begin................................//
//................................Coding end..................................//

`uvm_info(get_type_name(), "end_of_sim_chk(): end_of_sim_chk finished", UVM_HIGH);

endtask: end_of_sim_chk

function void tc_base::report_phase(uvm_phase phase);

   uvm_report_server report_svr = uvm_report_server::get_server();
   int count_fatal = report_svr.get_severity_count(UVM_FATAL);
   int count_err = report_svr.get_severity_count(UVM_ERROR);
   int count_warning = report_svr.get_severity_count(UVM_WARNING);

   super.report_phase(phase);
   if(count_fatal == 0) begin
      if(count_err == 0) begin
         `uvm_info(get_type_name(), $sformatf("Simulation PASSED at%15t (%0d warnings) ",$realtime, count_warning), UVM_NONE);
      end
      else begin
         `uvm_info(get_type_name(), $sformatf("Simulation *FAILED* at%15t (%0d errors, %0d warnings) ", $realtime, count_err, count_warning), UVM_NONE);
      end
   end
   else begin
      `uvm_info(get_type_name(), $sformatf("Simulation *FAILED* at%15t (%0d fatals, %0d errors, %0d warnings) ", $realtime, count_fatal, count_err, count_warning), UVM_NONE);
   end

endfunction: report_phase

function void tc_base::pre_abort();
    uvm_report_server report_svr = uvm_report_server::get_server();
    int count_fatal = report_svr.get_severity_count(UVM_FATAL);
    int count_err = report_svr.get_severity_count(UVM_ERROR);
    int count_warning = report_svr.get_severity_count(UVM_WARNING);
    `uvm_info(get_type_name(), $sformatf("Simulation *FAILED* at%15t  (%0d fatals, %0d errors, %0d warnings) ", $realtime, count_fatal, count_err, count_warning), UVM_NONE);
endfunction: pre_abort
