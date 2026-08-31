1. Sequence / Sequencer / Driver 的三方关系与职责划分

 sequence    `uvm_object`（有生命周期） 只负责生成激励数据（transaction的内容和随机化），不控制时序               
 sequencer   `uvm_component`           作为Sequence 和 Driver之间的仲裁器和路由节点，管理多个 sequence 的并发请求 
 driver      `uvm_component`           只负责驱动时序，将 transaction 转换为 pin 级信号，下发到 DUT     

   重点：sequence不属于验证平台组件树，无法通过config_db按层次配置，但通过挂载到sequencer后，可以通过sequencer句柄间接获取配置

  2. Sequence的三种启动方式
     （1） start()方法---显示启动（常用）
      
         my_sequence seq;
         seq = my_sequence::type_id::create("seq");
         seq.start(sequencer_handle, parent_sequence, priority, call_pre_post);
     
         手动控制启动时机和挂载位置.

     （2）default_sequence---配置自动启动
            // 在 test 的 build_phase 或 end_of_elaboration_phase 中配置
            uvm_config_db#(uvm_object_wrapper)::set(this, 
            "env.agent.sequencer.run_phase",  // 路径：sequencer 的 run_phase
            "default_sequence", 
            my_sequence::type_id::get());
    
          特点：  零代码启动：UVM在指定phase自动创建并启动sequence
                  路径必须精准指向sequencer的phase

     （3）`uvm_do()宏启动---在sequence中启动子sequence
                   // 在父 sequence 的 body() 中启动子 sequence
                  task body();
                      my_sub_sequence sub_seq;    
                      // 方式 A：先创建，再用 uvm_do 启动
                      sub_seq = my_sub_sequence::type_id::create("sub_seq");
                      `uvm_do(sub_seq)  // 自动挂载到当前 sequence 的 m_sequencer
                      // 方式 B：带约束启动
                      `uvm_do_with(sub_seq, {addr == 32'h1000;})
                      // 方式 C：一键启动（无需提前 create）
                      `uvm_do_on(sub_seq, p_sequencer)  // 指定挂载到特定 sequencer
                  endtask
           
                 // `uvm_do(seq) 展开后：
                 sub_seq = my_sub_sequence::type_id::create("sub_seq");
                 start_item(sub_seq);
                 sub_seq.randomize();
                 finish_item(sub_seq);

3. sequence和driver握手方式
（1）第一种： get_next_item() + item_done()：最常用
sequence                    sequencer                    driver
   |                            |                           |
   | start_item(req)            |                           |
   |--------------------------->|                           |
   |                            | 仲裁                      |
   | finish_item(req)           |                           |
   |--------------------------->|                           |
   |                            |<---- get_next_item(req) --|
   |                            |------ req --------------->|
   |                            |                           | 驱动DUT
   |                            |<------ item_done() -------|
   |<----- transaction完成 -----|                            |

 其中sequence这样写:
     task body();
         req = my_transaction::type_id::create("req");
         start_item(req);
         assert(req.randomize());
         finish_item(req);
     endtask
 driver这样写：
       task run_phase(uvm_phase phase);
           forever begin
               seq_item_port.get_next_item(req);
               drive_to_dut(req);
               seq_item_port.item_done();
           end
       endtask
  核心：get_next_item() 得到 transaction后，这个transaction仍然属于当前正在处理的item。只有driver调用item_done();sequencer才认为当前transaction已经处理完成，
        可以继续处理下一个transaction。get_next_item和item_done必须成对出现。
  
  (2)第二种：get()：driver 取走 transaction
  task run_phase(uvm_phase phase);
      forever begin
          seq_item_port.get(req);
          drive_to_dut(req);
      end
  endtask
  与第一种区别：get_next_item()只是拿到这个item进行处理，后面必须跟item_done(); get()相当于我已经把这个transaction从sequencer中取走了。
  
  (3)第三种：需要返回 response 时。例如 AXI read transaction，driver 除了接受 request，还需要把 response 返回 sequence。
       seq_item_port.get_next_item(req);
       drive_req(req);
       rsp = my_transaction::type_id::create("rsp");
       collect_response(rsp);
       rsp.set_id_info(req);
       seq_item_port.item_done(rsp);
   在sequence中：
       start_item(req);
       assert(req.randomize());
       finish_item(req);
       get_response(rsp);




4. m_sequencer 和 p_sequencer 有什么区别
   总结：m_sequencer 是 UVM 自动给 sequence 保存的“通用 sequencer 句柄”；p_sequencer 是为了让 sequence 能方便访问“具体类型 sequencer 中自定义的成员”。
   m_sequencer是sequence内部自带的基类句柄，类型比较泛。 比如：uvm_sequencer_base m_sequencer;
   p_sequencer是用户指定具体类型后的sequencer句柄。  比如：`uvm_declare_p_sequencer(my_virtual_sequencer)



5.Virtual Sequence 和 Virtual Sequencer 是什么？为什么需要它们？
    virtual sequencer本身通常不直接产生transaction，而是负责协调多个interface上的普通sequence。
    （1） virtual sequencer本身不直接与任何物理接口（driver）连接，因此它不产生真实的时序信号。
          它的内部只包含各个子agent的物理sequencer的句柄，为virtual sequence提供访问各个sequencer的途径。
          例如：class axi_virtual_sequencer extends uvm_sequencer;
                    axi_master_sequencer    m_master_seqer; // 指向上游128-bit主控
                    axi_slave_sequencer     m_slave_seqer;  // 指向下游64-bit从机
                    // 可能还有时钟/复位相关的sequencer
                endclass
     （2）virtual sequence
         派生自uvm_sequence，但运行在virtual sequencer上
         它的核心作用是通过p_sequencer（指向Virtual Sequencer的指针）拿到各个Physical Sequencer的句柄，然后派生（fork）子序列（Child Sequence）到这些Physical Sequencer上去执行。
    （3）作用
         在没有Virtual机制的环境里，如果顶层Test想要同时控制Master发送数据、Slave产生反压，它必须同时拿到Master和Slave的Sequencer，并分别启动Sequence。这会导致测试用例代码极度冗余，且协调时序极难控制。

6. 多个 sequence 同时启动在一个 sequencer 上时，怎么决定谁先发送？ ---- sequencer仲裁机制
   （1）使用仲裁方法：

     




 7. Sequence 中 objection 应该在哪里 raise/drop？pre_body/post_body 还推荐吗？
 
老代码经常看到：
task pre_body();
    if(starting_phase != null)
        starting_phase.raise_objection(this);
endtask
task post_body();
    if(starting_phase != null)
        starting_phase.drop_objection(this);
endtask

但现代工程中更推荐：由 test 或 phase 控制 objection：
task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.agent.seqr);
    phase.drop_objection(this);
endtask

原因是：
生命周期更明确；
sequence 可以被多个环境复用；
避免 sequence 自己管理 objection 导致仿真退出难以控制。







    
4.random和postrandom  为了循环产生不同的数

           
