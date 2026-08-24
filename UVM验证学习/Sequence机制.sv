1. Sequence / Sequencer / Driver 的三方关系与职责划分

 sequence    `uvm_object`（有生命周期） 只负责生成激励数据（transaction的内容和随机化），不控制时序               
 sequencer   `uvm_component`           作为Sequence 和 Driver之间的仲裁器和路由节点，管理多个 sequence 的并发请求 
 driver      `uvm_component`           只负责驱动时序，将 transaction 转换为 pin 级信号，下发到 DUT     

   重点：sequence不属于验证平台组件树，无法通过config_db按层次配置，但通过挂载到sequencer后，可以通过sequencer句柄间接获取配置

  2. Sequence的三种启动方式
     2.1 start()方法---显示启动（常用）
      
      my_sequence seq;
      seq = my_sequence::type_id::create("seq");
      seq.start(sequencer_handle, parent_sequence, priority, call_pre_post);
     
      手动控制启动时机和挂载位置.

     2.2 default_sequence---配置自动启动
        // 在 test 的 build_phase 或 end_of_elaboration_phase 中配置
       uvm_config_db#(uvm_object_wrapper)::set(this, 
         "env.agent.sequencer.run_phase",  // 路径：sequencer 的 run_phase
         "default_sequence", 
         my_sequence::type_id::get());
    
       特点： （1） 零代码启动：UVM在指定phase自动创建并启动sequence
             （2） 路径必须精准指向sequencer的phase

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







           
