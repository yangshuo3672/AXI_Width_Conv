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

以下是根据图片内容生成的原文：

// APB Monitor Transactor Class
class apb_monitor extends stb_monitor#(virtual apb_interface);
  `ifdef FCOV_ON
    apb_xaction       apb_fcov_xaction;
    apb_fcov          fcov;
  `endif
    
  apb_monitor_cfg   cfg;
  bit [`APB_ADDR_WIDTH - 1:0] addr_range;
  bit [`APB_DATA_WIDTH - 1:0] data_range;

  `uvm_component_utils(apb_monitor)
  `uvm_register_cb(apb_monitor,apb_monitor_callbacks)

  extern function new(string name, uvm_component parent);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task sample_apb(ref apb_xaction tr);
  extern virtual task main_task();
endclass: apb_monitor

function apb_monitor::new(srting          name,
                          uvm_component    parent );
    super.new(name,parent);
    `ifdef FCOV_ON
       fcov = apb_fcov::type_id::create("apb_fcov_instance",this);
    `endif
endfunction:new

//问题：monitor在仿真中的task phase中一直源源不断地采集数据，那么如何结束仿真呢？？？
// --------------------------------------------------------------------------
// run_phase() - Monitor the APB bus, and invoke callbacks
// --------------------------------------------------------------------------
task apb_monitor::run_phase(uvm_phase phase);
    apb_xaction tr;
    super.run_phase(phase);
    // Main Monitor Loop
    while(1) begin
        fork
            begin
                fork
                    begin
                        main_task();
                    end
                join_none
`ifndef ASYN_RESET_FUNC
                wait (`APB_MONITOR_IF.rst_n == 0) ;
                disable fork;
                @( `APB_MONITOR_IF);
                wait (`APB_MONITOR_IF.rst_n == 1);
                @( `APB_MONITOR_IF);
`else
                wait (`APB_MONITOR_BUS.rst_n == 0);
                disable fork;
                wait (`APB_MONITOR_BUS.rst_n == 1);
                @( `APB_MONITOR_IF);
`endif
            end
        join
    end
endtask: run_phase

以下是图片中的代码：

// sample_apb() - Monitor and Sample the APB bus when a valid transaction occurs
task apb_monitor::main_task();
  apb_xaction tr;
    
  uvm_info(get_type_name(), "sample_stimulus_data(): Start", UVM_HIGH);
  if(this.proto.get_type_name() == "UVM_sequence_item") begin
    this.proto = apb_xaction::type_id::create("proto", this);
    `uvm_info(get_type_name(), "sample_stimulus_data(): Proto be created in apb_monitor", UVM_HIGH);
  end

  addr_range = {`APB_ADDR_WIDTH{1'b1}} >> (`APB_ADDR_WIDTH - cfg.addr_width);
  data_range = {`APB_DATA_WIDTH{1'b1}} >> (`APB_DATA_WIDTH - cfg.data_width);

  while(1) begin
    if(!cast(tr,this.proto.clone()))begin          //LAB5
      `uvm_error(get_type_name(),"this.proto's TYPE is not apb_xaction ot it's extends");
    end

    // Pre-Rx Callback
    `uvm_do_callbacks(apb_monitor,apb_monitor_callbacks,monitor_pre_rx(this, tr));
    // Sample the bus using the apb_sample() task
    sample_apb(tr);
    tr.get_resp_flag = 1;
    out_port.write(tr);
    `uvm_do_callbacks(apb_monitor,apb_monitor_callbacks ,monitor_post_rx(this, tr));   
    // Printthe transaction in debug mode
    `uvm_info(get_type_name(), $sformatf("Monitor =>%s",tr.sprint()),UVM_HIGH);
  end
endtask

task apb_monitor::sample_apb(ref apb_xaction tr);
  bit $sel;
  bit Rd_nWr;
  int pready_delay_cnt=0;
  bit [`APB_ADDR_WIDTH - 1 : 0] addr;
  int cnt;
  bit addr_find_flag ;
  string str = "";
  string str_tmp="";

  addr_find_flag=0 ;
  cnt = 0;
  // Wait for the device to be selected
  do begin
    @(`APB_MONITOR_IF);
  end
  while(`APB_MONITOR_IF.PSel !== '1'b1);
  //add for DTS2018110108555
  tr.bus_check_en     = cfg.bus_check_en;
  tr.memory_check_en  = cfg.memory_check_en;
  tr.peri_dec_check_en = cfg.peri_dec_check_en;

  tr.addr = `APB_MONITOR_IF.PAddr & addr_range;
  tr.dir  = `APB_MONITOR_IF.PWrite;
  tr.m_bvAuser = `APB_MONITOR_IF.PAuser;
  //add for x_state_check,DTS2019051404652
  `APB_X_CHECK(`APB_MONITOR_IF.PAddr ,"PAddr")
  `APB_X_CHECK(`APB_MONITOR_IF.PAuser,"PAuser")
  //add for cmd callback,DTS2019051303955
  `uvm_do_callbacks(apb_monitor,apb_monitor_callbacks ,monitor_addr_rx(this, tr));

  fork
    begin
      @(`APB_MONITOR_IF);
      if (`APB_MONITOR_IF.PEnable !== 1'b1) begin
        `uvm_error(get_type_name(),"PEnable is not asserted one cycle after SET_UP state!");
      end
    end
    // Wait for latch enable
    do begin
      @(`APB_MONITOR_IF);
      pready_delay_cnt++;
      cnt++;
      if(cnt == cfg.pready_cnt) begin
        `uvm_error(get_type_name(), $sformatf("sample_apb():Has not wait for pready in %0d cycles", cfg.pready_cnt));
        break;
      end
    end
    while(`APB_MONITOR_IF.PReady === 1'b0);
  join

 // Read/Write cycle decision
Rd_nWr = !`APB_MONITOR_IF.PWrite;

addr= `APB_MONITOR_IF.PAddr;
if(cfg.addr_range_check_enable == 1'b1) begin
    if (cfg.fromAddress.num()) begin
        foreach(cfg.fromAddress[i]) begin
            if(( cfg.fromAddress[i]<= addr )&&(addr <= cfg.toAddress[i])) begin
                addr_find_flag =1 ;
                break;
            end
        end
    end
    if(!addr_find_flag) begin
        foreach(cfg.fromAddress[i]) begin
            $format(str_tmp,"The fromaddress[%0h]=%0h ",i,cfg.fromAddress[i]);
            if (str_tmp.len <30) str_tmp = {str_tmp,{{(30-str_tmp.len()){" "}}};
            $format(str,"%s%s; the toaddress[%0h]=%0h ",str,str_tmp,i,cfg.toAddress[i]);
        end
        `uvm_error(get_type_name(), $sformatf("addr is over range, addr is %0h ,but the addr ranege is : %s ",addr,str));
    end
end

// Read cycle - Store current transaction parameters
if(Rd_nWr == 1) begin
    tr.dir = apb_dec::READ;
    tr.data = `APB_MONITOR_IF.PRData & data_range;
    tr.addr = `APB_MONITOR_IF.PAddr & addr_range;
    tr.resp = `APB_MONITOR_IF.PSlvErr;
    tr.prot = `APB_MONITOR_IF.PProt;
    tr.m_bvRuser = `APB_MONITOR_IF.PRuser;
    tr.m_bvQos = `APB_MONITOR_IF.PQos;
    tr.m_bvGrpid = `APB_MONITOR_IF.PGrpid;
    tr.m_bvVmid = `APB_MONITOR_IF.PVmid;
    tr.m_bvMpubypass = `APB_MONITOR_IF.PMpubypass;
    tr.m_bvSnoop = `APB_MONITOR_IF.PSnoop;
    tr.m_bvDomain = `APB_MONITOR_IF.PDomain;
    tr.pready_delay = pready_delay_cnt-2;

    if(cfg.rdata_x_statue_check_enable == 1'b1) begin
        if(!($isunknown(tr.data)))begin
            `uvm_info(get_type_name(), "rdata is OK!!!" , UVM_HIGH);
        end
        else begin
            `uvm_error(get_type_name(),$sformatf("rdata has X state ,rdata=%h",tr.data));
        end
    end

    if(cfg.resp_check_enable == 1'b1) begin
        if(tr.resp == 1'b0)begin
            `uvm_info(get_type_name(), "rdata and resp is OK!!!" , UVM_HIGH);
        end
        else begin
            `uvm_error(get_type_name(),$sformatf("rdata has X state or resp is err ,rdata=%h,resp=%h",tr.data, tr.resp));
        end
    end

    `APB_X_CHECK(`APB_MONITOR_IF.PProt ,"PProt")
    `APB_X_CHECK(`APB_MONITOR_IF.PRuser ,"PRuser")
end

以下是图片中的代码原文：

// Write Cycle - Store current transaction parameters
if(Rd_nWr == 0) begin
    tr.dir = apb_dec::WRITE;
    tr.data = `APB_MONITOR_IF.PWData & data_range;
    tr.addr = `APB_MONITOR_IF.PAddr & addr_range;
    tr.resp = `APB_MONITOR_IF.PSLVErr;
    tr.prot = `APB_MONITOR_IF.PProt;
    tr.strb = `APB_MONITOR_IF.PStrb;
    tr.m_bvWuser = `APB_MONITOR_IF.PWuser;
    tr.m_bvQos = `APB_MONITOR_IF.PQos;
    tr.m_bvGrpid = `APB_MONITOR_IF.PGrpid;
    tr.m_bvVmid = `APB_MONITOR_IF.PVmid;
    tr.m_bvMpubypass = `APB_MONITOR_IF.PMpubypass;
    tr.m_bvSnoop = `APB_MONITOR_IF.PSnoop;
    tr.m_bvDomain = `APB_MONITOR_IF.PDomain;
    tr.pready_delay = pready_delay_cnt-2;

    if(cfg.resp_check_enable == 1'b1) begin
        if(tr.resp == 1'b1) begin
            `uvm_error(get_type_name(),$sformatf("resp is err ,resp=%h", tr.resp));
        end
        else begin
            `uvm_info(get_type_name(), "resp is OK!!!", UVM_HIGH);
        end
    end

    `APB_X_CHECK(`APB_MONITOR_IF.PWData,"PWData")
    `APB_X_CHECK(`APB_MONITOR_IF.PStrb ,"PStrb")
    `APB_X_CHECK(`APB_MONITOR_IF.PProt ,"PProt")
    `APB_X_CHECK(`APB_MONITOR_IF.PWuser,"PWuser")
end

`ifdef FCOV_ON
    $cast(apb_fcov_xaction,tr.clone());
    fcov.cover_apb_fcov(0,1,apb_fcov_xaction);
    fcov.cover_apb_fcov(1,1,apb_fcov_xaction);
`endif
endtask: sample_apb

                                            
`endif
