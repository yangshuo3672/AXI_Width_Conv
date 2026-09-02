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

4.objection机制*****
       phase.raise_objection(this);
       //...
       phase.drop_objection(this);
   objection机制一般只适用于12个run-time的子phase中，由于run_phase与其他12个动态运行的phase是并行运行的，如果这12个phase有objection被提起，那么run_phase根本不需要raise_objection就可以自动执行。
       UVM.page.150：
        （1）如果mian_phase提起了raise，run_phase没有raise_objection，那么run phase自动执行
       
        （2）如果run_phase提起了objection，main_phase没有raise_objection，那么mian_phase不会执行，仿真时间完全由run_phase决定了。
        原因：由于main_phase没有raise_objection，他会在0时刻全部消耗仿真时间的代码都被kill掉，测试只剩下run_phase在跑。
       
5.为什么不推荐main phase和run phase同时使用？
   因为12个动态运行的phase和run_phase是并行关系，混合使用会造成时序竞争和objection管理混乱。
   如果说run_phase提前结束，而另外的run-time phase运行依赖于run_phase实例化的组件，那么继续运行会报错。
   推荐只使用12个run-time phase，不使用run_phase。
   如果混合使用，可以main_phase用于virtual sequence的显示控制（使用raise_objection），而run_phase用于被动的，需要全称运行的组件，不raise_objection。

6. build_phase阶段出现ERROR会直接终止仿真
7. build_phase执行是自上而下、为什么
8. 
      
       


  
