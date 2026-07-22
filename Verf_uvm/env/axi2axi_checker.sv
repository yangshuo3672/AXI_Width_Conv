`ifndef AXI2AXI_CHECKER__SV
`define AXI2AXI_CHECKER__SV

class axi2axi_checker extends stb_function_component #(2, 0);

   stb_basic_scoreboard        order_sb[];          // In-order scoreboard
   axi2axi_basic_checker       basic_chk[];         // Basic common checker
   dummy_xaction               slave_xaction;       // Dummy transaction for slave side
   dummy_xaction               master_xaction;      // Dummy transaction for master side

// typedef struct {
//     bit [7:0] data[$];
// } data_blk;
   bit [7:0]     sw_data_q[$];
   bit [7:0]     sr_data_q[$];
   bit [127:0]   sw_addr_q[$];
   bit [127:0]   sr_addr_q[$];
   bit [31:0]    sw_resp_q[$];
   bit [31:0]    sr_resp_q[$];

  `uvm_component_utils_begin(axi2axi_checker)
  `uvm_component_utils_end

  extern function new(string name,
                     uvm_component parent 
                     );
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

  extern virtual task run_phase(uvm_phase phase);
  extern virtual task check_data();
    
  extern virtual function void check_phase(uvm_phase phase);

endclass:axi2axi_checker

function axi2axi_checker::new(string name,
                                 uvm_component parent
                                 );
      super.new(name, parent);
endfunction:new

function void axi2axi_checker::build_phase(uvm_phase phase);

    super.build_phase(phase);

    this.order_sb = new[1];
    foreach(this.order_sb[i]) begin
        this.order_sb[i] = stb_basic_scoreboard::type_id::create($sformatf("order_sb[%0d]", i), this);
    end

    this.basic_chk = new[1];
    foreach(this.basic_chk[i]) begin
        //this.basic_chk[i] = stb_basic_checker::type_id::create($sformatf("basic_chk[%0d]", i), this);
        this.basic_chk[i] = new($sformatf("basic_chk[%0d]", i), this);
        this.basic_chk[i].scoreboard = this.order_sb[i];
        this.basic_chk[i].is_disabled = 1'b1;
    end

endfunction: build_phase

function void axi2axi_checker::connect_phase(uvm_phase phase);

    int in_port_offset = this.basic_chk.size();
    super.connect_phase(phase);

    foreach(this.basic_chk[i]) begin
        this.basic_chk[i].in_port[0].connect(this.in_port[i]);
        this.basic_chk[i].in_port[1].connect(this.in_port[i + in_port_offset]);
    end

endfunction: connect_phase

task axi2axi_checker::run_phase(uvm_phase phase);
    this.check_data();
endtask: run_phase
    
    
function void axi2axi_checker::check_phase(uvm_phase phase);
  
      super.check_phase(phase);
     `uvm_info(get_type_name(),"check_phase(): check_phase() start",UVM_HIGH);
  
     if (sw_data_q.size != 0) begin
         `uvm_error(get_type_name(), $sformatf("there still %0d numbers of write datas in the slave queue", sw_data_q.size));
     end
     if (sr_data_q.size != 0) begin
         `uvm_error(get_type_name(), $sformatf("there still %0d numbers of read datas in the slave queue", sr_data_q.size));
     end
     if (sw_addr_q.size != 0) begin
         `uvm_error(get_type_name(), $sformatf("there still %0d numbers of write addresses in the slave queue", sw_addr_q.size));
     end
     if (sr_addr_q.size != 0) begin
         `uvm_error(get_type_name(), $sformatf("there still %0d numbers of read addresses in the slave queue", sr_addr_q.size));
     end

  `uvm_info(get_type_name(),"check_phase(): check_phase() finished",UVM_HIGH);

endfunction:check_phase

task axi2axi_checker::check_data();

  //bit [7:0] sw_data_q[$];
  //bit [7:0] sr_data_q[$];
  //bit [35:0] sw_addr_q[$];
  //bit [35:0] sr_addr_q[$];
  int             sw_index_q[$];
  int             mw_index_q[$];
  bit [7:0]       scw_data_q[$];
  bit [3:0]       scw_resp_q[$];
  bit [7:0]       mcw_data_q[$];
  bit [3:0]       mcw_resp_q[$];
  int             sr_index_q[$];
  int             mr_index_q[$];
  bit [7:0]       scr_data_q[$];
  bit [3:0]       scr_resp_q[$];
  bit [7:0]       mcr_data_q[$];
  bit [3:0]       mcr_resp_q[$];
  bit             mrerror_mask = 0;
  bit             srerror_mask = 0;
  bit             mwerror_mask = 0;
  bit             swerror_mask = 0;
  bit [127:0]     wcheck_addr;
  bit [127:0]     rcheck_addr;
  //while(1) begin
  uvm_sequence_item master_in_tr;
  uvm_sequence_item slave_in_tr;

fork
    while(1) begin
      this.in_port[1].get(slave_in_tr);                   // get transaction from slave port
        `uvm_info(get_type_name(), $sformatf("get the transaction from slave"), UVM_HIGH);
        if (!cast(this.slave_xaction, slave_in_tr)) begin
            `uvm_fatal(get_type_name(), "check data: data from slave is not a slave_xaction type");
        end
        
        foreach(slave_xaction.w_addr_q[i]) begin
            `uvm_info(get_type_name(), $sformatf("print the w_addr from slave = %0h", slave_xaction.w_addr_q[i]), UVM_DEBUG);
            `uvm_info(get_type_name(), $sformatf("print the w_data from slave = %0h", slave_xaction.w_data_q[i]), UVM_DEBUG);
            `uvm_info(get_type_name(), $sformatf("print the w_resp from slave = %0h", slave_xaction.w_resp_q[i]), UVM_DEBUG);
        end
        
        foreach(slave_xaction.r_addr_q[i]) begin
            `uvm_info(get_type_name(), $sformatf("print the r_addr from slave = %0h", slave_xaction.r_addr_q[i]), UVM_DEBUG);
            `uvm_info(get_type_name(), $sformatf("print the r_data from slave = %0h", slave_xaction.r_data_q[i]), UVM_DEBUG);
            `uvm_info(get_type_name(), $sformatf("print the r_resp from slave = %0h", slave_xaction.r_resp_q[i]), UVM_DEBUG);
        end
    end //end while(1)

  while(1) begin
    this.in_port[0].get(master_in_tr);                       // get transaction from master port
    `uvm_info(get_type_name(), $sformatf("get the transaction from master"), UVM_HIGH);
    if (!$cast(this.master_xaction, master_in_tr)) begin
        `uvm_fatal(get_type_name(), "check data: data from master is not a master_xaction type");
    end

    foreach (master_xaction.w_addr_q[i]) begin
        `uvm_info(get_type_name(), $sformatf("print the w_addr from master = %0h", master_xaction.w_addr_q[i]), UVM_DEBUG);
        `uvm_info(get_type_name(), $sformatf("print the w_data from master = %0h", master_xaction.w_data_q[i]), UVM_DEBUG);
        `uvm_info(get_type_name(), $sformatf("print the w_resp from master = %0h", master_xaction.w_resp_q[i]), UVM_DEBUG);
    end

    foreach (master_xaction.r_addr_q[i]) begin
        `uvm_info(get_type_name(), $sformatf("print the r_addr from master = %0h", master_xaction.r_addr_q[i]), UVM_DEBUG);
        `uvm_info(get_type_name(), $sformatf("print the r_data from master = %0h", master_xaction.r_data_q[i]), UVM_DEBUG);
        `uvm_info(get_type_name(), $sformatf("print the r_resp from master = %0h", master_xaction.r_resp_q[i]), UVM_DEBUG);
    end

    while (master_xaction.w_addr_q.size != 0) begin
        `uvm_info(get_type_name(), $sformatf("print the w_addr from master = %0h", master_xaction.w_addr_q[0]), UVM_HIGH);
        `uvm_info(get_type_name(), $sformatf("print the w_data from master = %0h", master_xaction.w_data_q[0]), UVM_HIGH);
        //check the addr data rsp, if mismatch, print error

        // check write finish
    end

    while (master_xaction.r_addr_q.size != 0) begin
        `uvm_info(get_type_name(), $sformatf("print the r_addr from master = %0h", master_xaction.r_addr_q[0]), UVM_HIGH);
        `uvm_info(get_type_name(), $sformatf("print the r_data from master = %0h", master_xaction.r_data_q[0]), UVM_HIGH);
        //check the addr data rsp, if mismatch, print error

        // check read finish
    end
  end //end while(1)

join

endtask:check_data

`endif
    
  





    
