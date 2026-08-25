class stb_interface_agent #(type VIF = int) extends uvm_agent;

  stb_dec::interface_agent_work_mode_e  work_mode = stb_dec::MASTER;  /// The default work mode of interface agent is MASTER
  uvm_sequencer #(uvm_sequence_item)    sqr;                         /// Generator of interface agent
  stb_driver #(VIF)                     drv;                         /// The driver of interface agent
  stb_slave_driver #(VIF)               slv_drv;                     /// The slave driver of interface agent
  stb_monitor #(VIF)                    mon;                         /// The monitor of interface agent
  uvm_reg_adapter                       adapter;                     /// The adapter for reg model
  uvm_subscriber #(uvm_sequence_item)   mon_cov;                     /// The coverage model for monitor, user must extend it and cast derive class to it
  uvm_analysis_port #(uvm_sequence_item) mon_port;                   /// The output port of monitor(agent internal port)
  bit                                   sqr_sw;                      /// The switch of sequence
  bit                                   drv_sw;                      /// The switch of driver
  bit                                   slv_drv_sw;                  /// The switch of slave driver
  bit                                   mon_sw;                      /// The switch of monitor
  bit                                   mon_cov_sw;                  /// The switch of coverage model for monitor, controlled by user
  bit                                   adapter_sw;                  /// The switch of stb_reg_adapter
  bit                                   wrapper_sw;                  /// For wrap the third-party agent, user to modify it in extension of stb_interface_agent
  string                                soma_inst_path;              /// Soma module instance path for candence agent
  string                                soma_inst_path_active;       /// Active soma module instance path for candence agent
  string                                soma_inst_path_passive;      /// Passive soma module instance path for candence agent

  `uvm_component_param_utils_begin(stb_interface_agent #(VIF))
    `uvm_field_enum(stb_dec::interface_agent_work_mode_e, work_mode, UVM_ALL_ON)
    `uvm_field_object(adapter, UVM_ALL_ON)
    `uvm_field_int(sqr_sw, UVM_ALL_ON)
    `uvm_field_int(drv_sw, UVM_ALL_ON)
    `uvm_field_int(slv_drv_sw, UVM_ALL_ON)
    `uvm_field_int(mon_sw, UVM_ALL_ON)
    `uvm_field_int(mon_cov_sw, UVM_ALL_ON)
    `uvm_field_int(adapter_sw, UVM_ALL_ON)
    `uvm_field_int(wrapper_sw, UVM_ALL_ON)
    `uvm_field_string(soma_inst_path, UVM_ALL_ON)
    `uvm_field_string(soma_inst_path_active, UVM_ALL_ON)
    `uvm_field_string(soma_inst_path_passive, UVM_ALL_ON)
  `uvm_component_utils_end

extern function new (string  name, uvm_component parent );
extern virtual function void build_phase(uvm_phase phase);
extern virtual function void connect_phase(uvm_phase phase);

endclass:stb_interface_agent

function stb_interface_agent::new(string name, uvm_component parent);

    super.new(name, parent);

    // The default value for components switch
    this.sqr_sw     = stb_dec::OFF;
    this.drv_sw     = stb_dec::OFF;
    this.slv_drv_sw = stb_dec::OFF;
    this.mon_sw     = stb_dec::OFF;
    this.mon_cov_sw = stb_dec::OFF;
    this.adapter_sw = stb_dec::OFF;
    this.wrapper_sw = stb_dec::OFF;

    this.mon_port = new("mon_port", this);  // Create mon_port because of mon_port always connect to other component
    `uvm_info(get_type_name(), "new(): mon_port has been created", UVM_MEDIUM);
    `uvm_info(get_type_name(), "new(): stb_interface_agent has been constructed", UVM_HIGH);

endfunction: new

function void stb_interface_agent::build_phase(uvm_phase phase);

    super.build_phase(phase);

    if(this.wrapper_sw == stb_dec::OFF) begin

        if(this.work_mode == stb_dec::MASTER) begin
            this.sqr_sw = stb_dec::ON;
            this.drv_sw = stb_dec::ON;
            this.mon_sw = stb_dec::ON;
        end
        else if(this.work_mode == stb_dec::REG_MASTER) begin
            this.sqr_sw = stb_dec::ON;
            this.drv_sw = stb_dec::ON;
            this.mon_sw = stb_dec::ON;
            this.adapter_sw = stb_dec::ON;
        end
        else if(this.work_mode == stb_dec::SLAVE) begin
            this.sqr_sw = stb_dec::ON;
            this.slv_drv_sw = stb_dec::ON;
            this.mon_sw     = stb_dec::ON;
        end
        else if(this.work_mode == stb_dec::MASTER_NO_MONITOR) begin
            this.sqr_sw = stb_dec::ON;
            this.drv_sw = stb_dec::ON;
        end
        else if(this.work_mode == stb_dec::ONLY_MONITOR) begin
            this.mon_sw = stb_dec::ON;
        end
        else if(this.work_mode == stb_dec::REG_MASTER_NO_MONITOR) begin
            this.sqr_sw = stb_dec::ON;
            this.drv_sw = stb_dec::ON;
            this.adapter_sw = stb_dec::ON;
        end

        if(this.sqr == null && this.sqr_sw == stb_dec::ON) begin
            this.sqr = uvm_sequencer #(uvm_sequence_item)::type_id::create("sqr", this);
            `uvm_info(get_type_name(), "build_phase(): Use uvm_sequencer to generate transaction", UVM_HIGH);
        end

        `uvm_info(get_type_name(), $sformatf("build_phase(): Current interface agent mode is:%s", this.work_mode.name), UVM_MEDIUM);

    end

    `uvm_info(get_type_name(), "build_phase(): stb_interface_agent build_phase is done", UVM_HIGH);

endfunction: build_phase

function void stb_interface_agent::connect_phase(uvm_phase phase);

  super.connect_phase(phase);

  if(this.wrapper_sw == stb_dec::OFF) begin

    if(this.drv == null && this.drv_sw == stb_dec::ON) begin
      `uvm_fatal(get_type_name(), "connect_phase(): stb_driver is null object, please make sure you have cast its extension to it");
    end

    if(this.slv_drv == null && this.slv_drv_sw == stb_dec::ON) begin
      `uvm_fatal(get_type_name(), "connect_phase(): stb_slave_driver is null object, please make sure you have cast its extension to it");
    end

    if(this.mon == null && this.mon_sw == stb_dec::ON) begin
      `uvm_fatal(get_type_name(), "connect_phase(): stb_monitor is null object, please make sure you have cast its extension to it");
    end

    if(this.mon_sw == stb_dec::ON) begin
      this.mon_port = mon.out_port;
    end

    if(this.drv_sw == stb_dec::ON) begin
      this.drv.seq_item_port.connect(this.sqr.seq_item_export);
      if(this.sqr_sw == stb_dec::ON && this.mon_sw == stb_dec::OFF) begin
        this.mon_port = this.drv.out_port;
      end
    end

    if(this.slv_drv_sw == stb_dec::ON) begin
      this.slv_drv.seq_item_port.connect(this.sqr.seq_item_export);
    end

    if(this.mon_cov_sw == stb_dec::ON && this.mon_cov != null) begin
      this.mon.out_port.connect(this.mon_cov.analysis_export);
    end

  end

  `uvm_info(get_type_name(), "connect_phase(): stb_interface_agent connect_phase is done", UVM_HIGH);

endfunction: connect_phase
