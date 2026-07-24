`ifndef MY_APB_DRIVER__SV
`define MY_APB_DRIVER__SV

`define APB_MASTER_IF   this.bus.Master.master_cb
`define APB_MASTER_BUS  bus

//APB Master Xcator Class
//APB Master Callback Class
typedef class my_apb_driver;

class apb_driver_callbacks extends uvm_callback;
    extern function new(string name = "apb_driver_callbacks");
    extern virtual task master_pre_tx(my_apb_driver     xactor,
                                      ref apb_xaction   trans ,
                                      ref bit           drop  );
//add for cmd callback,DTS2019051303955
    extern virtual task master_addr_tx(my_apb_driver xactor,
                                       apb_xaction   trans);

    extern virtual task master_post_tx(my_apb_driver xactor,
                                       apb_xaction   trans);
    `uvm_object_utils(apb_driver_callbacks)
endclass: apb_driver_callbacks

      
function apb_driver_callbacks::new(string name = "apb_driver_callbacks");
    super.new(name);
    `uvm_info(get_type_name(),"coming into the function of the new",UVM_HIGH);
endfunction: new

task apb_driver_callbacks::master_pre_tx(my_apb_driver xactor,
                                         ref apb_xaction trans,
                                         ref bit       drop);
endtask
   
task apb_driver_callbacks::master_addr_tx(my_apb_driver xactor,
                                          apb_xaction   trans);
endtask

task apb_driver_callbacks::master_post_tx(my_apb_driver xactor,
                                          apb_xaction   trans);
endtask


class my_apb_driver extends stb_driver#(virtual apb_interface);

    apb_driver_cfg cfg;
    bit [`APB_ADDR_WIDTH - 1:0] addr_range; //Add for jira1000
    bit [`APB_DATA_WIDTH - 1:0] data_range; //Add for jira1000
    bit seq_get=1'b0;

    `uvm_component_utils_begin(my_apb_driver)
        `uvm_field_object(cfg, UVM_ALL_ON)
    `uvm_component_utils_end

    `uvm_register_cb(my_apb_driver,apb_driver_callbacks)
    int seq_need_resp;

    extern function new(string           name, 
                        uvm_component    parent );
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern protected virtual task do_read(ref apb_xaction tr);
    extern protected virtual task do_write(apb_xaction tr);
    extern protected virtual task do_idle();
    extern virtual function void reset();
    extern virtual function void asyn_reset();
    extern protected virtual task main_task(ref apb_xaction tr);

endclass: my_apb_driver

//new() - Constructor

function  my_apb_driver::new(string         name,
                             uvm_component  parent );
  super.new(name , parent);
  seq_need_resp = 0;
endfunction:new


function  void my_apb_driver::build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_config_db#(int)::get(this,"","seq_need_resp",seq_need_resp));
endfunction:build_phase

function void my_apb_driver::reset();
    `APB_MASTER_IF.PAddr  <= 0;
    `APB_MASTER_IF.PSel   <= 0;
    `APB_MASTER_IF.PWData <= 0;
    `APB_MASTER_IF.PEnable <= 0;
    `APB_MASTER_IF.PWrite <= 0;
    `APB_MASTER_IF.PStrb  <= 0;
    `APB_MASTER_IF.PProt  <= 0;
    `APB_MASTER_IF.PAuser <= 0;
    `APB_MASTER_IF.PWuser <= 0;
    `APB_MASTER_IF.PQos   <= 0;
    `APB_MASTER_IF.PGrpid <= 0;
    `APB_MASTER_IF.PVmid  <= 0;
    `APB_MASTER_IF.PMpubypass <= 0;
    `APB_MASTER_IF.PSnoop <= 0;
    `APB_MASTER_IF.PDomain <= 0;
endfunction

function void my_apb_driver::asyn_reset ();
    `APB_MASTER_BUS.PAddr  = 0;
    `APB_MASTER_BUS.PSel   = 0;
    `APB_MASTER_BUS.PWData = 0;
    `APB_MASTER_BUS.PEnable = 0;
    `APB_MASTER_BUS.PWrite = 0;
    `APB_MASTER_BUS.PStrb  = 0;
    `APB_MASTER_BUS.PProt  = 0;
    `APB_MASTER_BUS.PAuser = 0;
    `APB_MASTER_BUS.PWuser = 0;
    `APB_MASTER_BUS.PQos   = 0;
    `APB_MASTER_BUS.PGrpid = 0;
    `APB_MASTER_BUS.PVmid  = 0;
    `APB_MASTER_BUS.PMpubypass = 0;
    `APB_MASTER_BUS.PSnoop = 0;
    `APB_MASTER_BUS.PDomain = 0;
endfunction

// ------------------------------------------------------------------
// run() - run_phase
// ------------------------------------------------------------------
// Runs forever to switch APB transaction to corresponding read/write/idle command
// ------------------------------------------------------------------

task my_apb_driver::run_phase(uvm_phase phase);

    apb_xaction        tr;
    super.run_phase(phase);

    // Main loop to drive the APB Bus

    reset();

    while(1) begin
        fork
            begin
                fork
                    begin
                        main_task(tr);
                    end
                join_none

                `ifndef ASYN_RESET_FUNC
                    wait (`APB_MASTER_IF.rst_n == 0);
                    disable fork;
                    @ (`APB_MASTER_IF);
                    if (this.seq_get) begin
                        if((seq_need_resp == 1) || (tr.seq_need_resp == 1)) begin
                            this.seq_item_port.put_response(tr);
                        end
                        this.seq_item_port.item_done();
                    end
                    this.seq_get=1'b0;
                    reset();
                    wait (`APB_MASTER_IF.rst_n == 1);
                    @(`APB_MASTER_IF);
                `else
                    wait (`APB_MASTER_BUS.rst_n == 0);
                    disable fork;
                    if (this.seq_get) begin
                        if((seq_need_resp == 1) || (tr.seq_need_resp == 1)) begin
                            this.seq_item_port.put_response(tr);
                        end
                        this.seq_item_port.item_done();
                    end
                    this.seq_get=1'b0;
                    asyn_reset();
                    wait (`APB_MASTER_BUS.rst_n == 1);
                    @(`APB_MASTER_IF);
                `endif
            end
        join
    end
endtask: run_phase
                      
                      
//do_dile()-Put yhe APB Bus into Idle Mode
task my_apb_driver::main_task(ref apb_xaction tr);
  uvm_sequence_item     tmp_tr;
  apb_xaction           out_tr;
  bit                   drop;

  addr_range = {`APB_ADDR_WIDTH{1'b1}} >> (`APB_ADDR_WIDTH - cfg.addr_width);
  data_range = {`APB_DATA_WIDTH{1'b1}} >> (`APB_DATA_WIDTH - cfg.data_width);

  while (1) begin
    #0;

    if(seq_item_port.has_do_available())begin
      seq_item_port.get_next_item(tmp_tr);
      this.seq_get=1'b1;
      `uvm_info(get_type_name(), $sformatf("The tmp_tr get from seqr is \n:%s",tmp_tr.sprint()),UVM_HIGH);

      if(!$cast(tr,tmp_tr)) begin
        `uvm_fatal(get_type_name(),"apb_xaction is not extends uvm_sequence_item,not accord with VIP rules");
      end

      // Pre-Tx callback
      `uvm_do_callbacks(my_apb_driver,apb_driver_callbacks, master_pre_tx(this, tr, drop));

      if(!$cast(out_tr, tr.clone())) begin
        `uvm_fatal(get_type_name(), "Tr cast failed!!!");
      end
      //this.out_port.write(out_tr);
      // `uvm_info(get_type_name(), $sformatf("The driver out_port tr is \n:%s",out_tr.sprint()),UVM_HIGH);

      if(tr.idle_num!=0)begin
        repeat(tr.idle_num) @(`APB_MASTER_IF);
      end

      // Process the transaction
      case (tr.dir)
        apb_dec::READ: begin
          do_read(tr);
        end
        apb_dec::WRITE: begin
          do_write(tr);
        end
        default: do_idle();
      endcase
      
      if((seq_need_resp == 1) || (tr.seq_need_resp == 1)) begin
         this.seq_item_port.put_response(tr);
      end
      this.seq_item_port.item_done();
      this.seq_get=1'b0;

      //Add for jira557 begin
      `ifdef UVM_DISABLE_AUTO_ITEM_RECORDING
          tr.end_tr(0);
      `endif
      //Add for jira557 end

      `uvm_do_callbacks(my_apb_driver,apb_driver_callbacks, master_post_tx(this, tr));     //LAB4

      tr.get_resp_flag = 1;
      this.out_port.write(tr);
      `uvm_info(get_type_name(), $sformatf("The driver out_port tr is \n:%s",tr.sprint()),UVM_HIGH);
      // Debug Print
      `uvm_info(get_type_name(), $sformatf("master callback master_post_tx \n:%s",tr.sprint()),UVM_HIGH);
      end
      else begin
          do_idle();
      end
  end
endtask

task my_apb_driver::do_idle();
    if(cfg.do_idle_state == 0) begin
        `APB_MASTER_IF.PAddr <= 0;
        `APB_MASTER_IF.PSel <= 0;
        `APB_MASTER_IF.PWData <= 0;
        `APB_MASTER_IF.PEnable <= 0;
        `APB_MASTER_IF.PWrite <= 0;
        `APB_MASTER_IF.PStrb <= 0;
        `APB_MASTER_IF.PProt <= 0;
        `APB_MASTER_IF.PAuser <= 0;
        `APB_MASTER_IF.PWuser <= 0;
        `APB_MASTER_IF.PQos <= 0;
        `APB_MASTER_IF.PGrpid <= 0;
        `APB_MASTER_IF.PVmid <= 0;
        `APB_MASTER_IF.PMpubypass <= 0;
        `APB_MASTER_IF.PSnoop <= 0;
        `APB_MASTER_IF.PDomain <= 0;
        @(`APB_MASTER_IF);
    end
    else if(cfg.do_idle_state == 1) begin
        `APB_MASTER_IF.PAddr <= $random;
        `APB_MASTER_IF.PSel <= 0;
        `APB_MASTER_IF.PWData <= $random;
        `APB_MASTER_IF.PEnable <= $random;
        `APB_MASTER_IF.PWrite <= $random;
        `APB_MASTER_IF.PStrb <= $random;
        `APB_MASTER_IF.PProt <= $random;
        `APB_MASTER_IF.PAuser <= $random;
        `APB_MASTER_IF.PWuser <= $random;
        `APB_MASTER_IF.PQos <= $random;
        `APB_MASTER_IF.PGrpid <= $random;
        `APB_MASTER_IF.PVmid <= $random;
        `APB_MASTER_IF.PMpubypass <= $random;
        `APB_MASTER_IF.PSnoop <= $random;
        `APB_MASTER_IF.PDomain <= $random;
        @(`APB_MASTER_IF);
    end
    else if(cfg.do_idle_state == 2) begin
        `APB_MASTER_IF.PSel <= 0;
        `APB_MASTER_IF.PEnable <= 0;
        @(`APB_MASTER_IF);
    end
    else begin
        @(`APB_MASTER_IF);
      `uvm_error(get_type_name(), $sformatf("do_idle()::do_idle_state is not available, do_idle_state=%0h", cfg.do_idle_state));
    end
endtask: do_idle


// do_read() - Issue a APB Read Cycle
//
//   - drives the address bus,
//   - select the  bus,
//   - assert Penable signal,
//   - read the data and return it.
//
task my_apb_driver::do_read(ref apb_xaction tr);
//
//===================== Please Write Your own code below =====================
//
endtask: do_read

// do_write() - Issue an APB Write Cycle
//
//   - Drive the address bus,
//   - Select the  bus,
//   - Drive data bus,
//   - Assert Penable signal
//
task my_apb_driver::do_write(apb_xaction tr);
//
//===================== Please Write Your own code below =====================
//
endtask: do_write

`endif //MY_APB_DRIVER__SV







                      

      
