1. 组件之间如何通信？
   如果monitor想向scoreboard传递一个数据，如何传递？
   1.1 方法一：使用全局变量
       在某个包（package）或者module中定义一个my_transcation类型的全局变量global_tr，Monitor采集到数据后，直接赋值给global_tr，Scoreboard则在一个循环中循环检测
    global_tr的值是否发生变化，一旦变化就取出比对。
       // 危险示范：全局变量通信
         package risky_pkg;
            my_transaction global_tr; // 全局变量
         endpackage

         class my_monitor extends uvm_monitor;
            task main_phase(uvm_phase phase);
              // ... 采集数据
              risky_pkg::global_tr = captured_tr; // 直接修改全局变量
            endtask
         endclass

         class my_scoreboard extends uvm_scoreboard;
            task main_phase(uvm_phase phase);
               forever begin
                  @(risky_pkg::global_tr); // 等待全局变量变化（依赖事件触发，不可靠）
                  compare(risky_pkg::global_tr);
               end
           endtask
        endclass
   致命缺陷：1.缺乏访问控制：平台内任何组件、任何地方都可以随意读写这个全局变量，团队开发中不经意的赋值导致覆盖掉关键数据，且bug隐蔽，难以定位
            2.同步机制脆弱：使用@(global_tr)事件触发，如果monitor和scoreboard等待事件之前就已经赋值了，可能导致错过这次数据更新
            3.可复用性为零：组件之间被绑定在全局变量中，想在其他项目中使用这些组件，需要把整套依赖搬过去。

        1.2 方法二：公共变量与直接引用
            可以在scoreboard中定义一个public的transaction的句柄，然后在Monitor中获取sb的实例并直接修改他
            class my_scoreboard extends uvm_scoreboard;
                 // 将数据句柄暴露为公共成员
                 public my_transaction sb_tr;
                 // ...
            endclass
 
            class my_monitor extends uvm_monitor;
                // 持有对scoreboard的引用
                my_scoreboard sb_ref;
 
                function void build_phase(uvm_phase phase);
                   super.build_phase(phase);
                   // 通常通过config_db或其他方式获取scoreboard的指针
                   if(!uvm_config_db#(my_scoreboard)::get(this, "", "sb_ref", sb_ref)) begin
                     `uvm_error("NOCONFIG", "Failed to get scoreboard handle")
                   end
                endfunction
 
                task main_phase(uvm_phase phase);
                   // ... 采集数据
                   sb_ref.sb_tr = captured_tr; // 通过引用直接修改
                endtask
            endclass
         缺陷: 1. Monitor可以通过sb_ref这个句柄，访问Scoreboa中的全部public成员和方法，容易误改
              2. Monitor需要显示知道Scoreboard的类型并获取其引用，增加组件之间编译依赖和链接复杂度



2. TLM机制
    TLM机制不是一个具体的类，而是一个基于接口interface和端口port的通信规范，核心是将通信规范化。组件不需要操作数据或实例化并调用对方的方法，而是通过标准端口发出请求。
端口连接在connect_phase中统一建立。
    2.1 TLM三大核心端口：PORT,EXPORT,IMP
        PORT:发起操作方。主动发起一个通信操作，比如put（发送数据）和get（获取数据）
        EXPORT：中转站。本身不执行具体操作，只是将来自PORT的请求转发给真正的执行者，常用于层次化结构中，将底层组价的IMP端口向上暴露
        IMP（Implementation）:最终执行方，实现了PORT发起操作的具体功能，例如一个put操作最终会调用IMP所在组件的put任务或函数
        连接关系：PORT->EXPORT->IMP 其中EXPORT是可选的
      
         

