1.组件之间的交互方式
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






2. Sequence机制相关内容
      
       
