`ifndef AXI2AXI_ENV__SV
`define AXI2AXI_ENV__SV

class axi2axi_env extends my_linkbench_env #(axi2axi_env_dec);

    axi2axi_env_cfg        cfg;                          /// The configuration of blk_a environment
    // rm checker begin
    axi2axi_checker        checker_inst;                 /// The checker
    axi2axi_rm             rm;                           /// The RM
    // rm checker finished

    // fifo begin
    uvm_tlm_analysis_fifo #(uvm_sequence_item)   axi_mst_if2rm_port_fifo;   /// The fifo of axi if_agent monitor to rm
    uvm_tlm_analysis_fifo #(uvm_sequence_item)   axi_slv_if2rm_port_fifo;   /// The fifo of axi_if_agent monitor to rm
    uvm_tlm_analysis_fifo #(uvm_sequence_item)   rm_out_port_fifo[2];       /// The fifo of rm 2checker
    // fifo finished

    `uvm_component_utils_begin(axi2axi_env)
        `uvm_field_object(cfg, UVM_ALL_ON)
    `uvm_component_utils_end

  extern function new(string        name ,
                     uvm_component  parent
                     );

  extern virtual function void      build_base(uvm_phase phase);
  extern virtual function void      connect_base(uvm_phase phase);
  extern virtual function void      end_of_elaboration_base(uvm_phase phase);
    
  extern virtual task     reset_base(uvm_phase phase);
  extern virtual task     configure_base(uvm_phase phase);
  extern virtual task     shutdown_base(uvm_phase phase);

  extern virtual function void      check_base(uvm_phase phase);
  extern virtual function void      report_base(uvm_phase phase);

endclass:axi2axi_env

    function axi2axi_env::new(string        name,
                             uvm_component  parent
                             );
          super.new(name,parent);
    endfunction:new

    //***************************function build_phase***********************//
    function void axi2axi_env::build_phase(uvm_phase phase);

    super.build_phase(phase);

    //rm and checker new
    this.checker_inst = axi2axi_checker::type_id::create("checker_inst", this);
    this.rm = axi2axi_rm::type_id::create("rm", this);
    `uvm_info(get_type_name(), "build_phase(): rm checker has been constructed", UVM_HIGH);
    //rm and checker finished

    //rm fifo new
    this.axi_mst_if2rm_port_fifo= new($sformatf("axi_mst_if2rm_port_fifo"), this);
    this.axi_slv_if2rm_port_fifo= new($sformatf("axi_slv_if2rm_port_fifo"), this);
    this.rm_out_port_fifo[0]    = new($sformatf("rm_out_port_fifo[0]"), this);
    this.rm_out_port_fifo[1]    = new($sformatf("rm_out_port_fifo[1]"), this);
    // rm new finished

    `uvm_info(get_type_name(), "build_phase(): build_phase() finished", UVM_HIGH);

endfunction : build_phase


//***************************function connect_phase***********************//
function void axi2axi_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // rm fifo connectet to interface monitor begin
    this.axi_mst_if_agent[0].mon_port.connect(this.axi_mst_if2rm_port_fifo.analysis_export);
    this.axi_slv_if_agent[0].mon_port.connect(this.axi_slv_if2rm_port_fifo.analysis_export);
    //rm fifo connectet to interface monitor finished

    //rm fifo connectet to rm input begin
    this.rm.in_port[0].connect(this.axi_mst_if2rm_port_fifo.blocking_get_peek_export);
    this.rm.in_port[1].connect(this.axi_slv_if2rm_port_fifo.blocking_get_peek_export);
    //rm fifo connectet to rm input finished

    //rm connectet to rm out fifo begin
    this.rm.out_port[0].connect(this.rm_out_port_fifo[0].blocking_put_export);
    this.rm.out_port[1].connect(this.rm_out_port_fifo[1].blocking_put_export);
    //rm connectet to rm out fifo finish

    //rm out fifo connect to checker begin
    this.checker_inst.in_port[0].connect(this.rm_out_port_fifo[0].blocking_get_peek_export);
    this.checker_inst.in_port[1].connect(this.rm_out_port_fifo[1].blocking_get_peek_export);
    //rm out fifo connect to checker finish

    `uvm_info(get_type_name(), "connect_phase() finished", UVM_HIGH);

endfunction: connect_phase

//***************************function end_of_elaboration_phase***********************//
function void axi2axi_env::end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);
    // Extend end_of_elaboration_phase() based on project requirement
    // Coding begin
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Coding end

    `uvm_info(get_type_name(), "end_of_elaboration_phase(): end_of_elaboration_phase() finished", UVM_HIGH);
endfunction: end_of_elaboration_phase

//***************************task reset_phase***********************//
task axi2axi_env::reset_phase(uvm_phase phase);

  super.reset_phase(phase);
  phase.raise_objection(this);
  // Reset DUT registers value based on project requirement
  // It is suggested to reset the UVC in run_phase() of corresponding UVC
  // Coding begin
  //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // Coding end

  phase.drop_objection(this);
  `uvm_info(get_type_name(), "reset_phase(): reset_phase() finished", UVM_HIGH);
endtask: reset_phase

//***************************task configure_phase***********************//
task axi2axi_env::configure_phase(uvm_phase phase);
  
  super.configure_phase(phase);
  phase.raise_objection(this);
  // Configure DUT registers value based on project requirement                   //
  // Coding begin-----------------------------------------------------------------//
  //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // Coding end-------------------------------------------------------------------//

  phase.drop_objection(this);
  uvm_info(get_type_name(), "configure_phase(): configure_phase() finished", UVM_HIGH);
endtask: configure_phase

//***************************task shutdown_phase***********************//
task axi2axi_env::shutdown_phase(uvm_phase phase);

  super.shutdown_phase(phase);
  phase.raise_objection(this);
// Extend shutdown_phase() based on project requirement                       
//Coding begin
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//Coding end

  phase.drop_objection(this);
  `uvm_info(get_type_name(), "shutdown_phase(): shutdown_phase() finished", UVM_HIGH);
endtask: shutdown_phase

//***************************function check_phase***********************//
function void axi2axi_env::check_phase(uvm_phase phase);
  super.check_phase(phase);

  // Extend check_phase() based on project requirement
  // Coding begin
  //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // Coding end
  `uvm_info(get_type_name(), "check_phase(): check_phase() finished", UVM_HIGH);
endfunction: check_phase


//***************************report check_phase***********************//
function void axi2axi_env::report_phase(uvm_phase phase);
  super.report_phase(phase);

  // Make reports in this phase based on project requirement
  // Coding begin
  //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  // Coding end
  `uvm_info(get_type_name(), "report_phase(): report_phase() finished", UVM_HIGH);
endfunction: report_phase

`endif














    
    
    
