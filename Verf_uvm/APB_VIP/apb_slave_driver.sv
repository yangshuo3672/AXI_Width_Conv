`ifndef APB_SLAVE_DRIVER__SV
`define APB_SLAVE_DRIVER__SV

`define APB_SLAVE_IF this.bus.Slave.slave_cb
`define APB_SLAVE_BUS bus
typedef class apb_slave_driver;

class apb_slave_driver_callbacks extends uvm_callback;

    extern function new(string name = "apb_slave_driver_callbacks");

    extern virtual function void process_EndedAddressCbF(apb_slave_driver apb_slv_drv, apb_xaction trans);

    extern virtual function void process_BeforeResponseCbF(apb_slave_driver apb_slv_drv, apb_xaction trans);

    extern virtual function void process_EndedCbF(apb_slave_driver apb_slv_drv, apb_xaction trans);

    `uvm_object_utils(apb_slave_driver_callbacks)

endclass : apb_slave_driver_callbacks

function apb_slave_driver_callbacks::new(string name = "apb_slave_driver_callbacks");

    super.new(name);
    `uvm_info(get_type_name(),"coming into the function of the new",UVM_HIGH);

endfunction: new

function void apb_slave_driver_callbacks::process_EndedAddressCbF(apb_slave_driver apb_slv_drv, apb_xaction trans);
endfunction

function void apb_slave_driver_callbacks::process_BeforeResponseCbF(apb_slave_driver apb_slv_drv, apb_xaction trans);
endfunction

function void apb_slave_driver_callbacks::process_EndedCbF(apb_slave_driver apb_slv_drv, apb_xaction trans);
endfunction

class apb_slave_driver extends stb_slave_driver#(virtual apb_interface);
  apb_slave_driver_cfg cfg;
  apb_slave_mem slave_model;
  uvm_sequence_item proto;
  bit [`APB_ADDR_WIDTH - 1:0] addr_range; 
  bit [`APB_DATA_WIDTH - 1:0] data_range; 
  int aligned_range ;

  `uvm_component_utils_begin(apb_slave_driver)
    `uvm_field_object(cfg, UVM_ALL_ON)
  `uvm_component_utils_end

  `uvm_register_cb(apb_slave_driver,apb_slave_driver_callbacks)

  extern function new(string name, uvm_component parent);
  extern function apb_slave_mem get_apb_slave_mem();
  extern task run_phase(uvm_phase phase);
  extern function void reset();
  extern function void asyn_reset();
  extern protected virtual task main_task();

endclass : apb_slave_driver

function apb_slave_driver::new(string name, uvm_component parent);
  super.new(name,parent);
  this.slave_model = apb_slave_mem::type_id::create("slave_model", this);
  this.proto = uvm_sequence_item::type_id::create("proto", this);
endfunction : new

function apb_slave_mem apb_slave_driver::get_apb_slave_mem();
  get_apb_slave_mem = this.slave_model;
endfunction : get_apb_slave_mem

以下是图片中的代码：

task apb_slave_driver::run_phase(uvm_phase phase);

  super.run_phase(phase);

  forever begin

    fork
      begin
        fork
          begin
            main_task();
          end
        join_none

        `ifndef ASYN_RESET_FUNC
          wait(`APB_SLAVE_IF.rst_n == 0);
          disable fork;
          @( `APB_SLAVE_IF);
          reset();
          wait (`APB_SLAVE_IF.rst_n == 1 );
          @( `APB_SLAVE_IF);
        `else
          wait(`APB_SLAVE_BUS.rst_n == 0);
          disable fork;
          asyn_reset();
          wait (`APB_SLAVE_BUS.rst_n == 1 );
          @( `APB_SLAVE_IF);
        `endif
      end
    join
  end
endtask : run_phase

以下是图片中的代码：

task apb_slave_driver::main_task();
    addr_range = {'APB_ADDR_WIDTH{1'b1}} >> (`APB_ADDR_WIDTH - cfg.addr_width);
    data_range = {'APB_DATA_WIDTH{1'b1}} >> (`APB_DATA_WIDTH - cfg.data_width);
    aligned_range = cfg.data_width/8 ;

    while (1) begin
        apb_xaction tr;
        logic [`APB_DATA_WIDTH-1:0]rdata;

        do begin
            @(`APB_SLAVE_IF);
        end
        while(`APB_SLAVE_IF.PSel != 1'b1);
//Add by z228374
        if(this.proto.get_type_name() == "uvm_sequence_item") begin
            this.proto = apb_xaction::type_id::create("proto", this);
            `uvm_info(get_type_name(), "run_phase(): Proto be created in apb slave driver", UVM_HIGH);
        end
        if(!$cast(tr, this.proto.clone())) begin
            `uvm_fatal(get_type_name(), $sformatf("tr.get_type_name is %0s, proto.get_type_name is %0s", tr.get_type_name(), proto.get_type_name()));
        end
//Add by z228374

        if(!tr.randomize()) begin
            `uvm_fatal(get_type_name(), "The transcation has randomize failed!!!");
        end

        $cast(tr.dir, `APB_SLAVE_IF.PWrite);
        tr.addr = `APB_SLAVE_IF.PAddr & addr_range;
        tr.prot = `APB_SLAVE_IF.PProt;
        tr.m_bvAuser = `APB_SLAVE_IF.PAuser;
        tr.m_bvQos = `APB_SLAVE_IF.PQos;
        tr.m_bvGrpid = `APB_SLAVE_IF.PGrpid;
        tr.m_bvVmid = `APB_SLAVE_IF.PVmid;
        tr.m_bvMpubypass = `APB_SLAVE_IF.PMpubypass;
        tr.m_bvSnoop = `APB_SLAVE_IF.PSnoop;
        tr.m_bvDomain = `APB_SLAVE_IF.PDomain;
        if (`APB_SLAVE_IF.PWrite == 1'b1) begin
            tr.data = `APB_SLAVE_IF.PWData & data_range;
            tr.strb = `APB_SLAVE_IF.PStrb;
            tr.m_bvWuser = `APB_SLAVE_IF.PWuser;
        end
        if (`APB_SLAVE_IF.PEnable !== 1'b0) begin
            `uvm_fatal(get_type_name(),"PEnable is asserted in SET_UP state!");
        end

        if((tr.addr%(aligned_range))!=0) begin
            `uvm_warning(get_type_name(),"PAddr is not aligned to the data bus width!");
        end
        `uvm_do_callbacks(apb_slave_driver,apb_slave_driver_callbacks, process_EndedAddressCbF(this,tr))
        `uvm_do_callbacks(apb_slave_driver,apb_slave_driver_callbacks, process_BeforeResponseCbF(this,tr))
        fork
          begin
            @(`APB_SLAVE_IF);
            if (`APB_SLAVE_IF.PEnable !== 1'b1) begin
              `uvm_error(get_type_name(),"PEnable is not asserted one cycle after SET_UP state!");
            end
          end
          begin
            //@(posedge `APB_SLAVE_IF.PEnable);
            if (tr.pready_delay != 0) begin
              `APB_SLAVE_IF.PReady <= 1'b0;
              repeat(tr.pready_delay) @(`APB_SLAVE_IF);
            end
            `APB_SLAVE_IF.PReady <= 1'b1;
            if (`APB_SLAVE_IF.PWrite == 1'b1) begin
              this.slave_model.set_mem(0,(tr.addr/aligned_range)*aligned_range,tr.data,tr.strb,cfg.data_width);
              `APB_SLAVE_IF.PSlvErr <= tr.resp;
            end
            else begin
              this.slave_model.get_mem(0,(tr.addr/aligned_range)*aligned_range,rdata,cfg.data_width);
              tr.data = rdata;
              `APB_SLAVE_IF.PRData <= tr.data & data_range;
              `APB_SLAVE_IF.PSlvErr <= tr.resp;
              `APB_SLAVE_IF.PRuser <= tr.m_bvRuser;
            end
            @(`APB_SLAVE_IF);
          end
        join
      
        if (`APB_SLAVE_IF.PEnable !== 1'b1) begin
          `uvm_error(get_type_name(),"PEnable is de-asserted before the end of the transfer!");
        end
        if ((`APB_SLAVE_IF.PWrite != tr.dir) || ((`APB_SLAVE_IF.PAddr & addr_range) != tr.addr) || (`APB_SLAVE_IF.PProt != tr.prot))begin
          `uvm_error(get_type_name(),"The cmd info is changed before the end of the transfer!");
        end
        if ((tr.dir == apb_dec::WRITE) && ((`APB_SLAVE_IF.PWData != tr.data) || (`APB_SLAVE_IF.PStrb != tr.strb))) begin
          `uvm_error(get_type_name(),"The data info is changed before the end of the write transfer!");
        end
        `uvm_do_callbacks(apb_slave_driver,apb_slave_driver_callbacks, process_EndedCbF(this,tr));
        `uvm_info(get_type_name(), $sformatf("The slave_driver tr is :%s",tr.sprint()),UVM_HIGH);
        //`APB_SLAVE_IF.PReady <= {$random}%2;
        APB_SLAVE_IF.PReady <= $urandom_range(1);
      end
endtask

function void apb_slave_driver::reset();
    `APB_SLAVE_IF.PRData <= 32'h0;
    `APB_SLAVE_IF.PSlvErr <= 1'b0;
    `APB_SLAVE_IF.PReady <= 1'b0;
    `APB_SLAVE_IF.PRuser <= 64'h0;
endfunction : reset

function void apb_slave_driver::asyn_reset();
    `APB_SLAVE_BUS.PRData = 32'h0;
    `APB_SLAVE_BUS.PSlvErr = 1'b0;
    `APB_SLAVE_BUS.PReady = 1'b0;
    `APB_SLAVE_BUS.PRuser = 64'h0;
endfunction

`endif //APB_SLAVE_DRIVER_SV          
