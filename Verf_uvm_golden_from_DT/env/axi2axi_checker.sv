`ifndef AXI2AXI_CHECKER__SV
`define AXI2AXI_CHECKER__SV

/** \brief  Checker class
This checker class provide the following default behaviour:
-get data output from a reference model through rm to checker channel
-get data output from the design through monitor to checker channel
-complete data checking automatically using scoreboard
*/
class axi2axi_checker extends stb_function_component #(2, 0);

    stb_basic_scoreboard              order_sb[];             ///<! In-order scoreboard (can be substituted by out-of-order scoreboard)
    axi2axi_basic_checker             basic_chk[];            ///<! Basic common checker, User can change it base on project requirement
    ktp_xaction                       slave_xaction;
    ktp_xaction                       master_xaction;
//typedef struct {
//    bit [7:0] data[$];
//} data_blk;

    rand bit [ 8:0] sw_id_q[$];
    rand bit [31:0] sw_addr_q[$];
    rand bit [63:0] sw_data_q[$];
    rand bit [ 1:0] sw_resp_q[$];
    rand bit [ 3:0] sw_qos_q[$];
    rand bit [ 3:0] sw_region_q[$];
    rand bit [ 1:0] sw_domain_q[$];
    rand bit [ 3:0] sw_cache_q[$];
    rand bit [ 2:0] sw_prot_q[$];
    rand bit [ 2:0] sw_snoop_q[$];
    rand bit [17:0] sw_user_q[$];

    rand bit [ 8:0] sr_id_q[$];
    rand bit [31:0] sr_addr_q[$];
    rand bit [63:0] sr_data_q[$];
    rand bit [ 1:0] sr_resp_q[$];
    rand bit [ 3:0] sr_qos_q[$];
    rand bit [ 3:0] sr_region_q[$];
    rand bit [ 1:0] sr_domain_q[$];
    rand bit [ 3:0] sr_cache_q[$];
    rand bit [ 2:0] sr_prot_q[$];
    rand bit [ 3:0] sr_snoop_q[$];
    rand bit [17:0] sr_user_q[$];

  //-------------------------------------------------------------------------------
// Define the member variables base on project requirement
//-------------------------------------------------------------------------------
//----------------Coding begin-----------------------------------------------
//----------------Coding end-------------------------------------------------

`uvm_component_utils_begin(axi2axi_checker)
    //-------------------------------------------------------------------------------
    // Add variables into field-automation base on project requirement
    //-------------------------------------------------------------------------------
    //----------------Coding begin-----------------------------------------------
    //----------------Coding end-------------------------------------------------
`uvm_component_utils_end

/** \brief new
  * Constructor
  */
extern function new(string name, uvm_component parent);

/** \brief build_phase
  * Calls super.build_phase(phase) to enable automatic get config and create object
  */
extern virtual function void build_phase(uvm_phase phase);

/** \brief connect_phase
  * To connect component
  */
extern virtual function void connect_phase(uvm_phase phase);

//-------------------------------------------------------------------------------
// Define the functions or task base on project requirement
//-------------------------------------------------------------------------------
//----------------Coding begin-----------------------------------------------
extern virtual task run_phase(uvm_phase phase);
extern virtual task check_data();

extern virtual function void check_phase(uvm_phase phase);
//----------------Coding end-------------------------------------------------

endclass: axi2axi_checker

function axi2axi_checker::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction: new

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
     // ------------------------------------------------------- Coding begin -------------------------------------------------------
`uvm_info(get_type_name(), "check_phase(): check_phase() start", UVM_HIGH);
//check whether there are any unmatch datas in the queues
if (sw_id_q.size != 0) begin
    `uvm_error(get_type_name(), $sformatf("there still %0d numbers of write ids in the slave queue", sw_id_q.size));
end
if (sr_id_q.size != 0) begin
    `uvm_error(get_type_name(), $sformatf("there still %0d numbers of read ids in the slave queue", sr_id_q.size));
end
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
if (sr_user_q.size != 0) begin
    `uvm_error(get_type_name(), $sformatf("there still %0d numbers of read user in the slave queue", sr_user_q.size));
end
if (sw_user_q.size != 0) begin
    `uvm_error(get_type_name(), $sformatf("there still %0d numbers of write user in the slave queue", sw_user_q.size));
end
if (sw_snoop_q.size != 0) begin
    `uvm_error(get_type_name(), $sformatf("there still %0d numbers of write snoop in the slave queue", sw_snoop_q.size));
end
if (sr_snoop_q.size != 0) begin
    `uvm_error(get_type_name(), $sformatf("there still %0d numbers of read snoop in the slave queue", sr_snoop_q.size));
end
// ------------------------------------------------------- Coding end -------------------------------------------------------
`uvm_info(get_type_name(), "check_phase(): check_phase() finished", UVM_HIGH);
endfunction





task axi2axi_checker::check_data();
    bit [ 8:0] sw_id_tmp;
    bit [31:0] sw_addr_tmp;
    bit [63:0] sw_data_tmp;
    bit [1:0]  sw_resp_tmp;
    bit [3:0]  sw_qos_tmp;
    bit [3:0]  sw_region_tmp;
    bit [1:0]  sw_domain_tmp;
    bit [3:0]  sw_cache_tmp;
    bit [2:0]  sw_prot_tmp;
    bit [2:0]  sw_snoop_tmp;
    bit [17:0] sw_user_tmp;

    bit [ 8:0] sr_id_tmp;
    bit [31:0] sr_addr_tmp;
    bit [63:0] sr_data_tmp;
    bit [1:0]  sr_resp_tmp1;
    bit [1:0]  sr_resp_tmp0;
    bit [3:0]  sr_qos_tmp;
    bit [3:0]  sr_region_tmp;
    bit [1:0]  sr_domain_tmp;
    bit [3:0]  sr_cache_tmp;
    bit [2:0]  sr_prot_tmp;
    bit [3:0]  sr_snoop_tmp;
    bit [17:0] sr_user_tmp;

    uvm_sequence_item master_in_tr;
    uvm_sequence_item slave_in_tr;
  fork
    //SLAVE: push/store the slave xaction to the slv_queues
    while(1) begin
        this.in_port[1].get(slave_in_tr);  // get transaction from slave port
        `uvm_info(get_type_name(), $sformatf("get the transaction from slave"), UVM_HIGH);
        if (!$cast(this.slave_xaction, slave_in_tr)) begin
            `uvm_fatal(get_type_name(), "check data: data from slave is not a slave_xaction type");
        end
    end

    foreach(slave_xaction.w_id_q[i]) begin
    uvm_info(get_type_name(), $sformatf("Push the w_id from slave = %0h", slave_xaction.w_id_q[i]), UVM_HIGH);
    sw_id_q.push_back(slave_xaction.w_id_q[i]);
end
foreach(slave_xaction.w_addr_q[i]) begin
    `uvm_info(get_type_name(), $sformatf("Push the w_addr from slave = %0h", slave_xaction.w_addr_q[i]), UVM_HIGH);
    sw_addr_q.push_back(slave_xaction.w_addr_q[i]);
end
foreach(slave_xaction.w_data_q[i])begin
    `uvm_info(get_type_name(), $sformatf("Push the w_data[%0d] from slave = %0h", i, slave_xaction.w_data_q[i]), UVM_HIGH);
    sw_data_q.push_back(slave_xaction.w_data_q[i]);
end
foreach(slave_xaction.w_resp_q[i])begin
    `uvm_info(get_type_name(), $sformatf("Push the w_resp from slave = %0h", slave_xaction.w_resp_q[i]), UVM_HIGH);
    sw_resp_q.push_back(slave_xaction.w_resp_q[i]);
end
foreach(slave_xaction.w_qos_q[i])begin
    `uvm_info(get_type_name(), $sformatf("Push the w_qos from slave = %0h", slave_xaction.w_qos_q[i]), UVM_HIGH);
    sw_qos_q.push_back(slave_xaction.w_qos_q[i]);
end
foreach(slave_xaction.w_region_q[i])begin
    `uvm_info(get_type_name(), $sformatf("Push the w_region from slave = %0h", slave_xaction.w_region_q[i]), UVM_HIGH);
    sw_region_q.push_back(slave_xaction.w_region_q[i]);
end
foreach(slave_xaction.w_domain_q[i])begin
    `uvm_info(get_type_name(), $sformatf("Push the w_domain from slave = %0h", slave_xaction.w_domain_q[i]), UVM_HIGH);
    sw_domain_q.push_back(slave_xaction.w_domain_q[i]);
end
foreach(slave_xaction.w_cache_q[i])begin
    `uvm_info(get_type_name(), $sformatf("Push the w_cache from slave = %0h", slave_xaction.w_cache_q[i]), UVM_HIGH);
    sw_cache_q.push_back(slave_xaction.w_cache_q[i]);
end
foreach(slave_xaction.w_prot_q[i])begin
    `uvm_info(get_type_name(), $sformatf("Push the w_prot from slave = %0h", slave_xaction.w_prot_q[i]), UVM_HIGH);
    sw_prot_q.push_back(slave_xaction.w_prot_q[i]);
end
foreach(slave_xaction.w_snoop_q[i])begin
    `uvm_info(get_type_name(), $sformatf("Push the w_snoop from slave = %0h", slave_xaction.w_snoop_q[i]), UVM_HIGH);
    sw_snoop_q.push_back(slave_xaction.w_snoop_q[i]);
end
foreach(slave_xaction.w_user_q[i])begin
    `uvm_info(get_type_name(), $sformatf("Push the w_user from slave = %0h", slave_xaction.w_user_q[i]), UVM_HIGH);
    sw_user_q.push_back(slave_xaction.w_user_q[i]);
end

  //read
foreach(slave_xaction.r_id_q[i]) begin
  uvm_info(get_type_name(), $sformatf("Push the r_id from slave = %0h", slave_xaction.r_id_q[i]), UVM_HIGH);
  sr_id_q.push_back(slave_xaction.r_id_q[i]);
end
foreach(slave_xaction.r_addr_q[i]) begin
  `uvm_info(get_type_name(), $sformatf("Push the r_addr from slave = %0h", slave_xaction.r_addr_q[i]), UVM_HIGH);
  sr_addr_q.push_back(slave_xaction.r_addr_q[i]);
end
foreach(slave_xaction.r_data_q[i])begin
  `uvm_info(get_type_name(), $sformatf("Push the r_data[%0d] from slave = %0h", i, slave_xaction.r_data_q[i]), UVM_HIGH);
  sr_data_q.push_back(slave_xaction.r_data_q[i]);
end
foreach(slave_xaction.r_resp_q[i])begin
  `uvm_info(get_type_name(), $sformatf("Push the r_resp from slave = %0h", slave_xaction.r_resp_q[i]), UVM_HIGH);
  sr_resp_q.push_back(slave_xaction.r_resp_q[i]);
end
foreach(slave_xaction.r_qos_q[i])begin
  `uvm_info(get_type_name(), $sformatf("Push the r_qos from slave = %0h", slave_xaction.r_qos_q[i]), UVM_HIGH);
  sr_qos_q.push_back(slave_xaction.r_qos_q[i]);
end
foreach(slave_xaction.r_region_q[i])begin
  `uvm_info(get_type_name(), $sformatf("Push the r_region from slave = %0h", slave_xaction.r_region_q[i]), UVM_HIGH);
  sr_region_q.push_back(slave_xaction.r_region_q[i]);
end
foreach(slave_xaction.r_domain_q[i])begin
  `uvm_info(get_type_name(), $sformatf("Push the r_domain from slave = %0h", slave_xaction.r_domain_q[i]), UVM_HIGH);
  sr_domain_q.push_back(slave_xaction.r_domain_q[i]);
end
foreach(slave_xaction.r_cache_q[i])begin
  uvm_info(get_type_name(), $sformatf("Push the r_cache from slave = %0h", slave_xaction.r_cache_q[i]), UVM_HIGH);
  sr_cache_q.push_back(slave_xaction.r_cache_q[i]);
end
foreach(slave_xaction.r_prot_q[i])begin
  `uvm_info(get_type_name(), $sformatf("Push the r_prot from slave = %0h", slave_xaction.r_prot_q[i]), UVM_HIGH);
  sr_prot_q.push_back(slave_xaction.r_prot_q[i]);
end
foreach(slave_xaction.r_snoop_q[i])begin
  `uvm_info(get_type_name(), $sformatf("Push the r_snoop from slave = %0h", slave_xaction.r_snoop_q[i]), UVM_HIGH);
  sr_snoop_q.push_back(slave_xaction.r_snoop_q[i]);
end
foreach(slave_xaction.r_user_q[i])begin
  `uvm_info(get_type_name(), $sformatf("Push the r_user from slave = %0h", slave_xaction.r_user_q[i]), UVM_HIGH);
  sr_user_q.push_back(slave_xaction.r_user_q[i]);
end
end

//MASTER
while(1) begin
  this.in_port[0].get(master_in_tr); // get transaction from master port
  `uvm_info(get_type_name(), $sformatf("get the transaction from master"), UVM_HIGH);
  if (!$cast(this.master_xaction, master_in_tr)) begin
    `uvm_fatal(get_type_name(), "check data: data from master is not a master_xaction type");
  end

  while (master_xaction.w_addr_q.size() != 0) begin
    //print the information of master_write_xaction
    `uvm_info(get_type_name(), $sformatf("print the w_id  from master = %0h", master_xaction.w_id_q[0]), UVM_HIGH);
    `uvm_info(get_type_name(), $sformatf("print the w_addr from master = %0h", master_xaction.w_addr_q[0]), UVM_HIGH);
    foreach(master_xaction.w_data_q[i]) begin
      `uvm_info(get_type_name(), $sformatf("print the w_data[%0d] from master = %0h", i, master_xaction.w_data_q[i]), UVM_HIGH);
    end
    foreach(master_xaction.w_resp_q[i]) begin
      `uvm_info(get_type_name(), $sformatf("print the w_resp[%0d] from master = %0h", i, master_xaction.w_resp_q[i]), UVM_HIGH);
    end
    `uvm_info(get_type_name(), $sformatf("print the size of Xaction addr from master w_addr_q.size = %0d", master_xaction.w_addr_q.size()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("print the size of Xaction data from master w_data_q.size = %0d", master_xaction.w_data_q.size()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("print the size of Xaction resp from master w_resp_q.size = %0d", master_xaction.w_resp_q.size()), UVM_LOW);
    //pop the slave xaction from the queue and compare with the master
    foreach (master_xaction.w_id_q[i]) begin
      sw_id_tmp = sw_id_q.pop_front();
      if(master_xaction.w_id_q[i] != sw_id_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check write id mismatch, Master id = 64'h%0h,Slave id = 64'h%0h",master_xaction.w_id_q[i],sw_id_tmp));
      end
      else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write id successfully, id = 2'h%0h",sw_id_tmp),UVM_LOW);
      end
    end

    foreach (master_xaction.w_addr_q[i]) begin
    sw_addr_tmp = sw_addr_q.pop_front();
    if(master_xaction.w_addr_q[i] != sw_addr_tmp)begin
        `uvm_error("CMPERROR",$sformatf("Check write addr mismatch, Master addr = 32'h%0h,Slave addr = 32'h%0h",master_xaction.w_addr_q[i],sw_addr_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write addr successfully, Addr = 32'h%0h",sw_addr_tmp),UVM_LOW);
    end
end
foreach (master_xaction.w_data_q[i])begin
    sw_data_tmp = sw_data_q.pop_front();
    if(master_xaction.w_data_q[i] != sw_data_tmp)begin
        `uvm_error("CMPERROR",$sformatf("Check write data mismatch, Master data[%0d] = 64'h%0h,Slave data[%0d] = 64'h%0h", i,master_xaction.w_data_q[i], i,sw_data_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write data successfully, data[%0d]= %0h", i,sw_data_tmp),UVM_LOW);
    end
end
foreach (master_xaction.w_resp_q[i]) begin
    sw_resp_tmp = sw_resp_q.pop_front();
    if(master_xaction.w_resp_q[i] != sw_resp_tmp)begin
        `uvm_error("CMPERROR",$sformatf("Check write resp mismatch, Master resp[%0d] = 2'h%0h,Slave resp[%0d] = 2'h%0h", i,master_xaction.w_resp_q[i], i,sw_resp_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write resp[%0d] successfully, resp = 2'h%0h", i, sw_resp_tmp),UVM_LOW);
    end
end
foreach (master_xaction.w_qos_q[i]) begin
    sw_qos_tmp = sw_qos_q.pop_front();
    if(master_xaction.w_qos_q[i]!= sw_qos_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check write qos mismatch, Master qos = 64'h%0h,Slave qos = 64'h%0h",master_xaction.w_qos_q[i],sw_qos_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write qos successfully, qos = 2'h%0h",sw_qos_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.w_region_q[i]) begin
    sw_region_tmp = sw_region_q.pop_front();
    if(master_xaction.w_region_q[i] != sw_region_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check write region mismatch, Master region = 64'h%0h,Slave region = 64'h%0h",master_xaction.w_region_q[i],sw_region_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write region successfully, region = 2'h%0h",sw_region_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.w_domain_q[i]) begin
    sw_domain_tmp = sw_domain_q.pop_front();
    if(master_xaction.w_domain_q[i] != sw_domain_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check write domain mismatch, Master domain = 64'h%0h,Slave domain = 64'h%0h",master_xaction.w_domain_q[i],sw_domain_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write domain successfully, domain = 2'h%0h",sw_domain_tmp),UVM_MEDIUM);
    end
end

foreach (master_xaction.w_cache_q[i]) begin
    sw_cache_tmp = sw_cache_q.pop_front();
    if(master_xaction.w_cache_q[i] != sw_cache_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check write cache mismatch, Master cache = 64'h%0h,Slave cache = 64'h%0h",master_xaction.w_cache_q[i],sw_cache_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write cache successfully, cache = 2'h%0h",sw_cache_tmp),UVM_MEDIUM);
    end
end

foreach (master_xaction.w_prot_q[i]) begin
    sw_prot_tmp = sw_prot_q.pop_front();
    if(master_xaction.w_prot_q[i] != sw_prot_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check write prot mismatch, Master prot = 64'h%0h,Slave prot = 64'h%0h",master_xaction.w_prot_q[i],sw_prot_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write prot successfully, prot = 2'h%0h",sw_prot_tmp),UVM_MEDIUM);
    end
end

foreach (master_xaction.w_snoop_q[i]) begin
    sw_snoop_tmp = sw_snoop_q.pop_front();
    if(master_xaction.w_snoop_q[i] != sw_snoop_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check write snoop mismatch, Master snoop = 4'h%0h,Slave snoop = 4'h%0h",master_xaction.w_snoop_q[i],sw_snoop_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write snoop successfully, snoop = 4'h%0h",sw_snoop_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.w_user_q[i]) begin
    sw_user_tmp = sw_user_q.pop_front();
    if(master_xaction.w_user_q[i] != sw_user_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check write user mismatch, Master user = 64'h%0h,Slave user = 64'h%0h",master_xaction.w_user_q[i],sw_user_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check write user successfully, user = 18'h%0h",sw_user_tmp),UVM_MEDIUM);
    end
end
master_xaction.w_addr_q.delete();//TODO:??

end

//print the information of master read_xaction
while (master_xaction.r_addr_q.size != 0) begin
    `uvm_info(get_type_name(), $sformatf("print the r_id   from master = %0h", master_xaction.r_id_q[0]), UVM_HIGH);
    `uvm_info(get_type_name(), $sformatf("print the r_addr from master = %0h", master_xaction.r_addr_q[0]), UVM_HIGH);
    foreach(master_xaction.w_data_q[i])begin
        `uvm_info(get_type_name(), $sformatf("print the r_data[%0d] from master = %0h", i, master_xaction.r_data_q[i]), UVM_HIGH);
    end
    foreach(master_xaction.w_resp_q[i])begin
        `uvm_info(get_type_name(), $sformatf("print the r_resp[%0d] from master = %0h", i, master_xaction.r_resp_q[i]), UVM_HIGH);
    end
    `uvm_info(get_type_name(), $sformatf("print the size of Xaction addr from master r_addr_q.size = %0d", master_xaction.r_addr_q.size()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("print the size of Xaction data from master r_data_q.size = %0d", master_xaction.r_data_q.size()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("print the size of Xaction resp from master r_resp_q.size = %0d", master_xaction.r_resp_q.size()), UVM_LOW);
end

//pop the slave xaction from the queue and compare with the master 
foreach (master_xaction.r_id_q[i]) begin
    sr_id_tmp = sr_id_q.pop_front();
    if(master_xaction.r_id_q[i] != sr_id_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check read id mismatch, Master id = 64'h%0h,Slave id = 64'h%0h",master_xaction.r_id_q[i],sr_id_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check read id successfully, id = 2'h%0h",sr_id_tmp),UVM_LOW);
    end
end
foreach (master_xaction.r_addr_q[i]) begin
    sr_addr_tmp = sr_addr_q.pop_front();
    if(master_xaction.r_addr_q[i] != sr_addr_tmp)begin
        `uvm_error("CMPERROR",$sformatf("Check read addr mismatch, Master addr = 32'h%0h,Slave addr = 32'h%0h",master_xaction.r_addr_q[i],sr_addr_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check read addr successfully, Addr = 32'h%0h",sr_addr_tmp),UVM_LOW);
    end
end
foreach (master_xaction.r_data_q[i])begin
    sr_data_tmp = sr_data_q.pop_front();
    if(master_xaction.r_data_q[i] != sr_data_tmp)begin
        `uvm_error("CMPERROR",$sformatf("Check read data mismatch, Master data[%0d] = 64'h%0h,Slave data[%0d] = 64'h%0h", i,master_xaction.r_data_q[i], i,sr_data_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check read data successfully, data[%0d] = %0h", i,sr_data_tmp),UVM_LOW);
    end
end
foreach (master_xaction.r_qos_q[i]) begin
    sr_qos_tmp = sr_qos_q.pop_front();
    if(master_xaction.r_qos_q[i] != sr_qos_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check read qos mismatch, Master qos = 64'h%0h,Slave qos = 64'h%0h",master_xaction.r_qos_q[i],sr_qos_tmp));
    end
    else begin
        uvm_info("CMPSUCCESS",$sformatf("Check read qos successfully, qos = 2'h%0h",sr_qos_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.r_region_q[i]) begin
    sr_region_tmp = sr_region_q.pop_front();
    if(master_xaction.r_region_q[i] != sr_region_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check read region mismatch, Master region = 64'h%0h,Slave region = 64'h%0h",master_xaction.r_region_q[i],sr_region_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check read region successfully, region = 2'h%0h",sr_region_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.r_domain_q[i]) begin
    sr_domain_tmp = sr_domain_q.pop_front();
    if(master_xaction.r_domain_q[i] != sr_domain_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check read domain mismatch, Master domain = 64'h%0h,Slave domain = 64'h%0h",master_xaction.r_domain_q[i],sr_domain_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check read domain successfully, domain = 2'h%0h",sr_domain_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.r_cache_q[i]) begin
    sr_cache_tmp = sr_cache_q.pop_front();
    if(master_xaction.r_cache_q[i] != sr_cache_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check read cache mismatch, Master cache = 64'h%0h,Slave cache = 64'h%0h",master_xaction.r_cache_q[i],sr_cache_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check read cache successfully, cache = 2'h%0h",sr_cache_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.r_prot_q[i]) begin
    sr_prot_tmp = sr_prot_q.pop_front();
    if(master_xaction.r_prot_q[i] != sr_prot_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check read prot mismatch, Master prot = 64'h%0h,Slave prot = 64'h%0h",master_xaction.r_prot_q[i],sr_prot_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check read prot successfully, prot = 2'h%0h",sr_prot_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.r_snoop_q[i]) begin
    sr_snoop_tmp = sr_snoop_q.pop_front();
    if(master_xaction.r_snoop_q[i] != sr_snoop_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check read snoop mismatch, Master snoop = 4'h%0h,Slave snoop = 4'h%0h",master_xaction.r_snoop_q[i],sr_snoop_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check read snoop successfully, snoop = 4'h%0h",sr_snoop_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.r_user_q[i]) begin
    sr_user_tmp = sr_user_q.pop_front();
    if(master_xaction.r_user_q[i] != sr_user_tmp) begin
        `uvm_error("CMPERROR",$sformatf("Check read user mismatch, Master user = 64'h%0h,Slave user = 64'h%0h",master_xaction.r_user_q[i],sr_user_tmp));
    end
    else begin
        `uvm_info("CMPSUCCESS",$sformatf("Check read user successfully, user = 18'h%0h",sr_user_tmp),UVM_MEDIUM);
    end
end
foreach (master_xaction.r_resp_q[i]) begin
    sr_resp_tmp0 = sr_resp_q.pop_front;
    sr_resp_tmp1 = sr_resp_q.pop_front;
    if (sr_resp_tmp0 != 0) begin
        if(master_xaction.r_resp_q[i] != (sr_resp_tmp0)) begin //| sr_resp_tmp1)) begin
            `uvm_error("CMPERROR", $sformatf("Check read resp mismatch! Master resp[%0d] = 2'h%0h, but slave resp[%0d] = 2'h%0h.", i, master_xaction.r_resp_q[i], i, sr_resp_tmp0 | sr_resp_tmp1));
        end
        else begin
            `uvm_info("CMPSUCCESS", $sformatf("Check read resp successfully! Resp = 2'h%0h.", i, master_xaction.r_resp_q[i]), UVM_LOW);
        end
    end
    else begin
        if(master_xaction.r_resp_q[i] != (sr_resp_tmp1)) begin
            `uvm_error("CMPERROR", $sformatf("Check read resp mismatch! Master resp[%0d] = 2'h%0h, but slave resp[%0d] = 2'h%0h.", i, master_xaction.r_resp_q[i], i, sr_resp_tmp0 | sr_resp_tmp1));
        end
        else begin
            `uvm_info("CMPSUCCESS", $sformatf("Check read resp successfully! Resp[%0d] = 2'h%0h.", i , master_xaction.r_resp_q[i]), UVM_LOW);
        end
    end
end

master_xaction.r_addr_q.delete();
end
    end //while？？
  join


endtask：check_data

`endif
