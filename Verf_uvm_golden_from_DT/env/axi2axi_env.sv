/*env 负责"搭台子"——把验证平台所需的所有组件（Agent、Scoreboard、Checker、Reference Model、Coverage Collector等）创建出来、连接起来，形成一个完整、可运行的验证环境。
uvm_test (tc_base/tc_sanity)test_case中的tc_base负责声明和创建env
    └── env (axi2axi_env / my_env)
            ├── axi_mst_if_agent[0]  (Master VIP Agent)
            ├── axi_slv_if_agent[0]  (Slave VIP Agent)
            ├── apb_mst_if_agent[0]  (APB Agent, 若有)
            ├── rm (Reference Model)
            ├── checker / scoreboard
            └── coverage collector (可选)
Test 决定"测什么"（配置参数、启动哪个 sequence）
Env 决定"用什么测"（创建哪些组件、怎么连）
Agent 决定"怎么协议交互"（driver、sequencer、monitor）

通过env_cfg控制创建几个 agent、开不开 checker、开不开 coverage，一套env适应不同场景。
总结：env 是 UVM 验证平台的"集成中心"和"连接枢纽"。它在 build_phase 中创建 agent、RM、checker 等所有子组件，
      在 connect_phase 中把它们的 TLM 端口连起来，并通过 uvm_config_db 把 test 下发的配置传递到最底层的 agent。test 负责"定义测试意图"，
      env 负责"把意图落地成可运行的验证平台"。
*/
class axi2axi_env extends my_linkbench_env #(axi2axi_env_dec);

    //AXI if agent的创建在父类linkbench_env中创建
    axi2axi_env_cfg             cfg;//env配置类实例化
    axi2axi_checker             checker_inst;//checker实例化
    axi2axi_rm                  rm;//参考模型实例化

    //fifo begin： TLM 通信中的"缓冲队列"；在 env 中充当 Monitor→RM→Checker数据流的中转站。它们的作用是解耦生产者（Monitor/RM）和消费者（RM/Checker）的时序，防止数据因处理速度不匹配而丢失。
    uvm_tlm_analysis_fifo #(uvm_sequence_item)  axi_mst_if2rm_port_fifo;   //Master Monitor → RM 的 FIFO
    uvm_tlm_analysis_fifo #(uvm_sequence_item)  axi_slv_if2rm_port_fifo;   //Slave Monitor → RM 的 FIFO
    uvm_tlm_analysis_fifo #(uvm_sequence_item)  rm_out_port_fifo[2];       // RM → Checker 的 FIFO（两个输出端口）
    //fifo finished
    /*为什么需要fifo缓存？
      Monitor 的 analysis_port 是"广播写"（非阻塞，零延时），而 RM 的 in_port.get() 是"阻塞读"。如果 Monitor 发数据时 RM 还没执行到 get()，数据就会丢失。
      加入fifo后，通过fifo内部队列自动缓存，RM.get从队列头部取（阻塞直到取到数据）
    */

    ral_block_KTP_CFG_REG         regmodel;//寄存器模型例化

    `uvm_component_utils_begin(axi2axi_env)
        `uvm_field_object(cfg, UVM_ALL_ON)
    `uvm_component_utils_end

    extern function new(string name, uvm_component parent);

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual function void end_of_elaboration_phase(uvm_phase phase);
    extern virtual task reset_phase(uvm_phase phase);
    extern virtual task configure_phase(uvm_phase phase);
    extern virtual task shutdown_phase(uvm_phase phase);
    extern virtual function void check_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
    extern virtual function void get_linkbench_env_cfg();

endclass: axi2axi_env


function axi2axi_env::new(string name, uvm_component parent);
    super.new(name, parent);//调用父类uvm_component,注册到UVM树
    apb_mst_if_agent = new[1];//提前分配APB Master agent的数组空间，值new了数组句柄，还没有创建
endfunction: new

function void axi2axi_env::build_phase(uvm_phase phase);
    super.build_phase(phase);
    //random cfg TODO
    if(this.cfg == null)begin//检查配置是否被上层（test）通过uvm_config_db传入，若没有set传入（为null），env自己创建一个并随机化.
        this.cfg = axi2axi_env_cfg::type_id::create("axi2axi_env_cfg",this);
    if(!cfg.randomize())begin//先执行随机化，再将返回值取反。若随机化成功则返回1.
        `uvm_fatal (get_type_name(), "build_phase(): Unable to randomize env_cfg in env");
        end
    end

    //regmodel new
  regmodel = ral_block_KTP_CFG_REG::type_id::create("reg_model",this);//寄存器模型已经注册到工厂，通过type_id创建寄存器模型对象，挂到UVM树下；可以override
  regmodel.configure(null,"harness");//配置后门访问路径，null表示从顶层开始，harness是DUT环境中的层次化名（比如harness.DUT）
  regmodel.build();//根据寄存器定义，递归创建所有uvm_reg和uvm_reg_field
  regmodel.lock_model();//锁定模型，防止运行时动态添加/删除寄存器，提高访问效率
  regmodel.reset();//将所有寄存器的monitor值和desired值复位到硬件reset值

    //rm and checker创建，build_phase只创建即可，connect phase才进行连接
    this.checker_inst = axi2axi_checker::type_id::create("checker_inst", this);
    this.rm = axi2axi_rm::type_id::create("rm", this);
    `uvm_info(get_type_name(), "build_phase(): rm checker has been constructed", UVM_HIGH);
    //rm and checker finished

  //rm fifo new:TLM fifo创建。因为uvm_tlm_analysis_fifo是UVM标准类，直接使用new(new,parent)创建。虽然他是uvm_component派生，但一般不通过Factory覆盖，所以不需要type_id::create
  //$sformatf：动态生成实例名，方便在uvm_top.print_topology()识别
    this.axi_mst_if2rm_port_fifo= new($sformatf("axi_mst_if2rm_port_fifo"), this);
    this.axi_slv_if2rm_port_fifo= new($sformatf("axi_slv_if2rm_port_fifo"), this);
    this.rm_out_port_fifo[0] = new($sformatf("rm_out_port_fifo[0]"), this);
    this.rm_out_port_fifo[1] = new($sformatf("rm_out_port_fifo[1]"), this);
    // rm new finished
    /*$sformatf是SV的系统函数，和$display $write一样，是编译器内置的。作用是将格式化的字符串写到变量中（而不是直接打印到屏幕），返回一个string
      string str = $sformatf（"test"），那么str的值就是test
    */
    `uvm_info(get_type_name(), "build_phase(): build_phase() finished", UVM_HIGH);
endfunction: build_phase

function void axi2axi_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  //analysis_export或者是analysis_export这些端口是 uvm_tlm_analysis_fifo 内部已经封装好的成员变量，实例化 FIFO 后直接通过 . 访问即可。//
  // rm fifo connect to interface monitor begin
  //将mst/slv-agent-Mointor的数据发送到if2rm_fifo
  this.axi_mst_if_agent[0].mon_port.connect(this.axi_mst_if2rm_port_fifo.analysis_export);//将AXI agent的monitor端口连接到if2rm_fifo的接收端analysis_export
  this.axi_slv_if_agent[0].mon_port.connect(this.axi_slv_if2rm_port_fifo.analysis_export);//Monitor只管发送，不管对方有没有准备好，FIFO内部队列自动维护队列缓存。


  // rm fifo connect to rm input begin
  //将if2rm_fifo中的数据发送到RM的in_port[]
    this.rm.in_port[0].connect(this.axi_mst_if2rm_port_fifo.blocking_get_peek_export);//fifo提供
  this.rm.in_port[1].connect(this.axi_slv_if2rm_port_fifo.blocking_get_peek_export);
 

  // rm connect to rm out fifo begin
  //
  this.rm.out_port[0].connect(this.rm_out_port_fifo[0].blocking_put_export);
  this.rm.out_port[1].connect(this.rm_out_port_fifo[1].blocking_put_export);


  // rm out fifo connect to checker begin
  this.checker_inst.in_port[0].connect(this.rm_out_port_fifo[0].blocking_get_peek_export);
  this.checker_inst.in_port[1].connect(this.rm_out_port_fifo[1].blocking_get_peek_export);


  `uvm_info(get_type_name(), "connect_phase() finished", UVM_HIGH);
  regmodel.default_map.set_sequencer(apb_mst_if_agent[0].apb_sqr, apb_mst_if_agent[0].reg_adapter);//frontdoor access
  regmodel.default_map.set_auto_predict(1);
  `uvm_info(get_type_name(), "connect_phase() finished", UVM_HIGH);

endfunction: connect_phase
