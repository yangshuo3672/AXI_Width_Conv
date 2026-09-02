1. 如何结束仿真时间？
   因为在monitor和driver中通常需要使用循环持续监测或者发送激励，所以不能在这些组件中提起raise_objection
   可以有以下几种方式驱动仿真的结束：
    （1）sequence次数驱动 
      sequence.body()
        class main_sequence extends uvm_sequence #(transaction);
           virtual task body();
               raise_objection();  // ✅ sequence控制
               repeat(1000) begin
               `uvm_do(req)
               end
                drop_objection();  // ✅ 测试次数完成后结束
          endtask
       endclass
        （2）事件驱动
        在test中的main_phase中设置固定仿真时长或者特定触发条件
        （3）覆盖率驱动
          在scoreboard比对完成或covergroup等待覆盖率收敛后结束

2.set_drain_time：设置排空时间

            task base_test::main_phase(uvm_phase phase)
              phase.phase_done.set_drain_time(this,200);//设置200ns的排空时间，也就是当main_phase中的所有objection被drop之后，会继续等待200ns跳转到下一phase
            endtask
    其中phase_done是uvm_phase中内定义的一个成员变量，phase.raise_objection和phase.drop_objection本质上就是调用phase_done的
    当UVM在main_phase检测到所有objection被drop之后，会检查有没有设置drain时间。

3.phase的跳转
  eg：
            task my_driver::main_phase(uvm_phase phase)
              `uvm_info("driver","main_phase", UVM_LOW)
              fork
                while(1)begin
                  seq_item_port.get_next_item(req);
                  driver_one_pkt(req);
                  seq_item_port.item_done();
                end
                begin
                  @(negedge vif.rst_n);
                  phase.jump(uvm_reset_phase::get());//当main_phase一旦检测到复位生效，马上跳转到reset_phase
                end
              join
            endtask

    注意：跳转到前面的build_phase到start_of_sim_phase是不可行的，跳转run_phase也是不可行的。只能在12个run_time phase内跳转或者跳转到task phase后面的function phase（如final_phase）

  4. 

  
