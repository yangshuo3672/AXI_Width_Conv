（一）组件之间的交互方式
  1.1 uvm_config_db--全局数据配置库、全局公告栏
      基于层次路径和字符串名称进行参数传递，解决上层组件如何向下层组件传递信息，无需通过构造函数层层传参。
      成对出现：
      （1）uvm_config_db#(类型)::set(上下文, 目标路径, 字段名, 值);
      （2）uvm_config_db#(类型)::get(上下文, 目标路径, 字段名, 接收变量);                                      |
           1）上下文：发起set/get的组件句柄，通常写this或者null（顶层），在顶层null等价于uvm_root::get()，即uvm_top
           2）目标路径：UVM组件层次路径，支持通配符*
           3）字段名：自定义字符串，说明这个值是创给目标中的哪个成员的 --- set/get函数中的这个值必须严格匹配
           4）类型：参数化的数据类型，编译期间严格匹配，get时类型不匹配则失败       
      1.1.1 传递虚拟接口 virtual interface
            uvm测试环境的顶层属于module，可以直接实例化interface；但UVM的组件是class，无法直接实例化interface，必须通过虚拟接口句柄作为中间桥梁。
            eg：
                // top_tb.sv (module 层)
                   initial begin
                       uvm_config_db#(virtual axi_if)::set(null, "*", "axi_vif", axi_if_inst);
                       run_test("my_test");
                   end
               // axi_agent.sv (class 层)
                  function void build_phase(uvm_phase phase);
                       if (!uvm_config_db#(virtual axi_if)::get(this, "", "axi_vif", vif))
                          `uvm_fatal("NOVIF", "virtual interface not found")
                  endfunction
       1.1.2 传递配置对象
             不同测试用例需要不同的位宽、频率等配置，在test_case中创建配置对象并广播，下层组件get后按配置例化

  1.2 TLM(Transcation Level Model)
       传递事务级信息，而不是单个信号。

  1.3 Mailbox
      Mailbox属于进程间通信的一种方式，也可以用于组件之间通信，它可以看成是一个先进先出 （ first in first out，FIFO） 的存储数组。
      使用put将一个或者多个进程把数据送入一个mailbox， 使用get将一个或者多个进程从maibox读出数据。客户进程可以被挂起，直至 mailbox有可用的数据，以实现生产进程和客户进程的同步。
      VIP中对于非主数据通路的业务报文收发，其他辅助类报文信息，可以选择使用mailbox方式

  1.4 event
      UVM组件之间的常规通信方式是TLM机制，但对于一些偶然触发的数据传输，并且需要立即响应，这时可以使用uvm_event的方式，进行跨组件传输数据报文/信息。
      主要用于用户验证环境和VIP之间的一些协同操作，比如验证环境需要等待VIP处理某个特定报文的时刻，再决定下一步的DUT行为或环境激励行为，此时就可以使用uvm_event方式建立跨组件通信的渠道。
      VIP需要规划实现多种Event事件，将业务收发报文处理过程中的一些关键节点信息使用uvm_event的方式进行触发，给用户提供一种交互操作的介入方式。
      按照协议分层，在每个以agent为粒度的组件中设置event_pool和对应的event事件，在这些组件中，均需要使用uvm_event_pool例化一个event_pool本Agent的全局资源池和uvm_event例化数个本Agent对应的Event变量。
      一个典型的运转场景如上图所示：
         1.aaa_layer_agent组件设计了一个event_pool，为模块发送/接收报文行为分别定义2个uvm_event变量，注册在event_pool中；
         2.验证环境的sequence中设计一个seq_aaa_event_pool，为aaa_layer_agent模块发送/接收报文行为分别定义2个uvm_event变量，注册在seq_aaa_event_pool中；
         3.在sequence中将seq_aaa_event_pool和aaa_layer_agent的event_pool关联在一起（同句柄）；
         4.aaa_layer_agent每次收发报文时使用trigger方式进行一次对应的event触发，且将收发的报文在触发时进行传参；
         5.sequence中使用wait_trigger_data方式等待VIP中的触发，同时获取报文，以供sequence中函数/进程使用（比如等待VIP中收/发某种匹配内容的报文时这个时刻，sequence中进行精确的注错/复位等操作）






（二） 海思AXI VIP Feature特性
      2.1 协议特性 Protocal Features
           AX3/4,原子操作，outstanding深度可配，interleaving深度可配，Ordering Check，4K边界地址检查，跨4K边界拆分，排他操作，拍他深度可配，
           每条通道valid-ready延迟可控，安全模式和非安全模式检查
      2.2 环境特性
           支持工作模式MASTER，SLAVE，MASTER_NO_MONITOR,ONLY_MONITOR,REG_MASTER_NO_MONITOR,REG_MASTER
           封装基本读写操作函数
           支持AXI的背靠背测试
           支持功能覆盖率
           支持多种类型的callbacks函数
           支持prot供用户环境连接

（三）VIP集成
      3.1 env环境集成
           （1）VIP声明：一个master 一个slave
           
            stb_dec::interface_agent_work_mode_e  axi_slv_if_agent_work_mode[]; ///!< The apb_if_agent work mode 工作模式数组声明，赋值在下方，创建VIP时江该配置传递给VIP的work_mode参数
            stb_dec::interface_agent_work_mode_e  axi_mst_if_agent_work_mode[]; ///!< The axi_if_agent work mode
           
            axi_interface_agent   axi_mst_if_agent[];
            axi_interface_agent   axi_slv_if_agent[];
            axi2axi_env_cfg       cfg;
            axi2axi_checker       checker_inst;
            axi2axi_rm            rm;
            uvm_tlm_analysis_fifo #(uvm_sequence_item)  axi_mst_if2rm_port_fifo;   //Master Monitor → RM 的 FIFO
            uvm_tlm_analysis_fifo #(uvm_sequence_item)  axi_slv_if2rm_port_fifo;   //Slave Monitor → RM 的 FIFO
            uvm_tlm_analysis_fifo #(uvm_sequence_item)  rm_out_port_fifo[2];

          foreach (axi_mst_if_agent_work_mode[i])
               this.axi_mst_if_agent_work_mode[i] = stb_dec::MASTER;
          foreach (axi_slv_if_agent_work_mode[i])
               this.axi_slv_if_agent_work_mode[i] = stb_dec::SLAVE;
         （2）VIP实例化 //创建、实例化VIP
          foreach(this.linkbench_cfg.axi_mst_if_agent_sw[i]) begin
              if(this.linkbench_cfg.axi_mst_if_agent_sw[i] == stb_dec::ON) begin
                  this.axi_mst_if_agent[i] = axi_interface_agent::type_id::create($sformatf("axi_mst_if_agent[%0d]", i), this);
                  this.axi_mst_if_agent[i].work_mode = this.linkbench_cfg.axi_mst_if_agent_work_mode[i];
                  this.axi_mst_if_agent[i].cfg = this.linkbench_cfg.axi_mst_if_agent_cfg[i];
                  `uvm_info(get_type_name(), $sformatf("build_phase():axi_mst_if_agent[%0d] has been constructed", i), UVM_HIGH);
              end
          end
         （3）VIP port连接
           //master_vip.mon_port--->if2rm_fifo--->rm.in_port[0]--->rm_out_port_fifo[0]--->checker_inst.in_port[0];之间都是阻塞传递
           this.axi_mst_if_agent[0].mon_port.connect(this.axi_mst_if2rm_port_fifo.analysis_export);//master vip--->if2rm_fifo
           this.rm.in_port[0].connect(this.axi_mst_if2rm_port_fifo.blocking_get_peek_export);//if2rm_fifo--->rm.in_port[0]
           this.rm.out_port[0].connect(this.rm_out_port_fifo[0].blocking_put_export);//rm.out_port[0]--->rm_out_port_fifo[0]
           this.checker_inst.in_port[0].connect(this.rm_out_port_fifo[0].blocking_get_peek_export);//rm_out_port_fifo[0]--->checker_inst.in_port[0]

           //传递与master一致，rm和checker端口改为[1]即可
           this.axi_slv_if_agent[0].mon_port.connect(this.axi_slv_if2rm_port_fifo.analysis_export);
           this.rm.in_port[1].connect(this.axi_slv_if2rm_port_fifo.blocking_get_peek_export);
           this.rm.out_port[1].connect(this.rm_out_port_fifo[1].blocking_put_export);
           this.checker_inst.in_port[1].connect(this.rm_out_port_fifo[1].blocking_get_peek_export);

(四)激励发送
   步骤：axi_sequence声明-----axi_sequence实例化,使用type_id创建-----通过axi_sequence中的task发送激励

（五）xaction激励类介绍
     
     什么是反压：代表valid已经来了，我想要valid等多久？
     
     激励配置包括读写指示，addr、id、size、burst等端口信号
     
     Avalid_Wvalid_Delay: 写命令和写数据之间的延迟，正数命令在前。
     
     Next_Avlid_Delay: 连续两个写命令（读命令）之间的延迟。也就是master发起读写命令之间的延迟
     Next_Wvalid_Delay: 连续两个写数据之间的延迟。
     
     Bvalid_Bready_Delay: Bready反压的延迟。想要此参数生效需要修改axi_driver_cfg中的bready信号默认值改为0
     Bready_Delay: 从Bresp握手到下一次Bready的延迟。
     Rvalid_Rready_Delay: 各拍Rready反压Rvalid的延迟。想要此参数生效需要修改axi_driver_cfg中的rready信号默认值改为0
     Ready_Delay: 从各拍Rresp握手到下一次Ready的延迟。
     Avlid_Aready_Delay：Axready反压Axvalid的延迟。
     Default_Aready_Delay: 从Axaddr握手到下一次Wready的延迟。
     Wvalid_Wready_Delay: 各派Wready反压Wvalid的延迟。
     Default_Wready_Delay: 从Wdata握手到下一次Wready的延迟。

     Write_Bvalid_Delay: 从收到写命令和写数据到给出Bresp的延迟。
     Address_Rvalid_Delay: 从收到读命令到给出第一拍Rdata的延迟。
     Next_Rvalid_Delay:连续两拍读数据之间的延迟; 也就是slave发起两笔有效返回数据之间的延迟。

     注意：关于ready的所有延迟，均也有axi_driver_cfg或者axi_slave_driver_cfg对各信号的ready默认值决定

  （六）配置类介绍
     6.1 axi_interface_agent_cfg配置项
         addr、id、data位宽，outstanding深度，interleaving深度，是否有delay信号使能总开关，
         out_of_rresp、out_of_bresp：读写响应乱序开关
         所有的检查总开关，
         读操作4K边界检查开关、读wrap操作时length检查开关，读地址非对齐检查开关，exclusive非法检查开关
         写操作4K边界检查开关、写wrap操作时length检查开关，写地址非对齐检查开关
         INCR操作协议检查开关，FIX操作协议检查开关，WRAP操作协议检查开关，Wstrb检查开关
         高性能driver使能
         跳过4K边界拆分使能

     6.2 axi_driver_cfg配置项
         aw和w通道对其开关：关闭时根据配置的delay来发送
         Bready和Rready默认值设置
         ainfo_hold_when_invalid: A通道valid无效时信号保持开关
         ainfo_random_when_invalid: A通道valid无效时信号随机开关
         winfo_random_when_invalid: W通道valid无效时信号随机开关
         MaxDelay： 读写操作timeout时间，从发出操作到返回的最大时间
         Inject_awlen_error_en: awlen错误注入使能开关，可在callback中注入awlen异常场景

     6.3 axi_slave_driver_cfg配置项
         rresp_order_en、bresp_order_en: R、B通道的resp顺序返回；优先级高于out_of_rresp和out_of_bresp
         Awready、Arready、Wready默认值设置
         mem_type: slave_mem的类型。0表示在FIXED操作时，mem为fifo模式；1表示在FIXED操作时，mem不为fifo模式
         binfo、rinfo等在valid无效是通道上其他信号的随机开关

     6.4 aix_monitor_cfg配置项
         主要是检查开关，其中包括：
         X态检查使能、rdata X态检查使能
         所有检查开关使能
         读操作4K边界检查使能
         读wrap操作length检查使能
         读操作地址非对齐检查使能
         写操作。。。。
         功能覆盖率使能开关
         最大timeout使能开关
         wlast、rlast检查开关


     （七）callback介绍
           VIP提供了很多callback接口方便用户使用
           7.1 axi_driver_callback
               （1）axi_driver刚从port获得aix_xaction后，通过该callback可以在命令发出前对其做出修改，可对各种握手delay作出修改。

               （2）错误注入：Driver驱动burst length到总线awlen上之前，在该callback可以注入awlen错误，构造length和wdata拍数不符合协议场景

           7.2  axi_slave_driver_callback
                (1) axi_slave_driver刚开始采集命令，在此callback中可修改Ready的Delay值
                (2) 已经采完一个命令，可修改ready delay值
                (3) 即将返回响应， 可控制响应时OKAY还是ERROR，也可以修改响应通道握手的valid delay值     

     总结：callback可以在driver已经采样完成之后，将想要修改的值修改，并且可以刻意制造异常场景用于检测
     












           
      
       
