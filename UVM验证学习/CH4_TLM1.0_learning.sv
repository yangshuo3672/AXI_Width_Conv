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
    2.1 （1） TLM三大核心端口：PORT,EXPORT,IMP
        PORT:发起操作方。主动发起一个通信操作，比如put（发送数据）和get（获取数据）。例如 uvm_blocking_put_port #(transaction) put_port;
        EXPORT：中转站。本身不执行具体操作，只是将来自PORT的请求转发给真正的执行者，常用于层次化结构中，将底层组价的IMP端口向上暴露。例如：uvm_blocking_put_export #(transaction) put_export;
        IMP（Implementation）:最终执行方，实现了PORT发起操作的具体功能，例如一个put操作最终会调用IMP所在组件的put任务或函数。例如：uvm_blocking_put_imp #(transaction, consumer) put_imp;
        连接关系：PORT->EXPORT->IMP 其中EXPORT是可选的
       
        （2）操作原理
       put(t)是发送操作，get(t)是获取操作，peek)是窥探操作。
       Port主动调用put或者get方法，
       put：数据从Port流向Imp
       get：Imp从内部取出数据并返回给Port，数据从Imp流向Port，Imp内部数据被移除
       peek：与get类似，但不会移除数据。只读取数据。不影响Imp内部存储*************************************

      （3）blocking和nonblocking原理
         （3.1）blocking：阻塞，调用会等待操作完成才返回。方法是task类型，消耗仿真时间，等待fifo有空间（put）或fifo有数据（get）时才返回
              分类：blocking_put,blocking_get,blocking_peek
          (3.2)nonblocking:非阻塞，立即返回，不等待操作完成。方法是function，不消耗时间，使用mailbox尝试操作，返回成功/失败状态
              分类：nonblocking_put()/try_put()，nonblocking_get()/try_get()，nonblocking_get()/try_get()
             返回值bit success = try_put(t),1表示返回成功。

       
   2.2 定义通信方式
        
         uvm_blocking_put_port:      阻塞式发送，调用其put（task）任务发送一个事务，改事务会一直阻塞，知道接收方成功接收。
         uvm_nonblocking_put_port:   非阻塞式发送，调用其try_put（function）函数尝试发送，立即返回是否成功。
         uvm_blocking_get_port：     阻塞式获取，调用get（task）获取一个事务，该事务一直阻塞，知道有数据可用。
         uvm_nonblocking_get_port:   非阻塞式获取，调用try_get（function）函数尝试获取，立即返回是否成功及数据
         uvm_blocking_get_peek_port/uvm_nonblocking_get_peek_port: 在get的基础上增加peek能力，即获取数据但不从队列移除
         uvm_analysis_port:          广播式发送，调用write（function）函数发送一个事务，所有连接到该端口的IMP都会接收到一份拷贝。这是一对多通信的关键。

   2.3 一对一通信实战：从Monitor到Scoreboard
      （1）第一步：定义通信事务（transcation），TLM通信的数据单元，继承自sequence_item
            class my_transaction extends uvm_sequence_item;
                 rand bit [31:0] addr;
                 rand bit [31:0] data;
                 // ... 其他字段和约束、方法
                 `uvm_object_utils(my_transaction)
            endclass
      （2）第二步：在发送方（Monitor）定义PORT
             class my_monitor extends uvm_monitor;
                 // 声明一个阻塞式put端口，参数为事务类型和本组件类型
                   uvm_blocking_put_port #(my_transaction) put_port;
 
                   function new(string name, uvm_component parent);
                     super.new(name, parent);
                     put_port = new("put_port", this); // 在构造函数中创建
                   endfunction
                  
                   task main_phase(uvm_phase phase);
                     my_transaction tr;
                     forever begin
                       // ... 采集数据到 tr
                       `uvm_info("MON", $sformatf("Captured transaction: addr=0x%0h, data=0x%0h", tr.addr, tr.data), UVM_MEDIUM)
                       // 发起阻塞式put操作。此任务会等待，直到Scoreboard侧的put任务完成。
                       put_port.put(tr);
                     end
                   endtask
            endclass
            //使用阻塞式blocking_put：对于Monitor到Scoreboard的通信，我们通常希望数据流是受控的，如果Scoreboard处理较慢，Monitor应该等待，避免数据丢失。
       （3）第三步：在接收方（Scoreboard）定义IMP并实现put方法
            class my_scoreboard extends uvm_scoreboard;
                // 声明一个阻塞式put实现端口
                uvm_blocking_put_imp #(my_transaction, my_scoreboard) put_imp;
               
                function new(string name, uvm_component parent);
                  super.new(name, parent);
                   put_imp = new("put_imp", this); //函数中创建new
                endfunction
               
                // 必须实现与端口类型对应的任务。函数签名是固定的。
                task put(my_transaction tr);
                  `uvm_info("SCB", $sformatf("Received transaction: addr=0x%0h, data=0x%0h", tr.addr, tr.data), UVM_MEDIUM)
                  // 在这里进行数据比对、检查等操作
                  compare_and_check(tr);
                endtask 
                // 其他的函数和任务...
            endclass
         （4）第四步：在顶层env连接PORT和IMP（必须在connect_phase中连接）
             class my_env extends uvm_env;
                  my_monitor monitor;
                  my_scoreboard scoreboard;
 
                  function void build_phase(uvm_phase phase);
                     super.build_phase(phase);
                     monitor = my_monitor::type_id::create("monitor", this);
                     scoreboard = my_scoreboard::type_id::create("scoreboard", this);
                  endfunction
                  
                  function void connect_phase(uvm_phase phase);
                     super.connect_phase(phase);
                     // 将monitor的port连接到scoreboard的imp
                     monitor.put_port.connect(scoreboard.put_imp);
                  endfunction
            endclass

            connect()方法在两者之间建立了通道，当monitor.put_port.put(tr)被调用时，这个调用最终会通过这个通道，最终执行scoreboadr.put(tr)任务
            省略EXPORT，在这个例子中，PORT直接连接到了IMP，如果Scoreboadr被封装到一个更底层的子环境中，那么该子环境还需要定义一个EXPORT来向上暴露这个IMP，福环境再连接PORT到这个EXPORT。
         EXPORT起到了一个接口适配器或端口转发器的作用。

  2.4 一对多广播通信：Analysis端口的威力
        在很多场景下，一个数据源需要广播给多个消费者。例如，Monitor采集到的事务（transaction），可能需要同时送给Scoreboard进行比对、送给覆盖率收集器（Coverage Collector）收集功能覆盖率、
    送给日志记录器（Logger）打印详细信息。如果为每个消费者都建立一对一的put连接，代码会非常冗余，且数据源需要知道所有消费者的信息，耦合度高。
        UVM提供了uvm_analysis_port 和 uvm_analysis_imp 专门用于这种一对多、非阻塞、广播式的通信。    
            
      2.4.0  Analysis端口的特点：
               非阻塞：analysis_port.write() 是一个函数（function），调用它会立即返回。发送方不会等待接收方处理完毕。
               广播 ：一个 analysis_port 可以连接到多个 analysis_imp 。调用一次 write() ，所有连接的IMP都会收到该事务的一份拷贝 。
               单向推送 ：数据流是单向的，从 analysis_port 到 analysis_imp 。IMP不能通过这个端口反向请求数据。
                  
      2.4.1 实战：假设我们有Monitor作为数据源，Scoreboard和Coverage Collector作为消费者。
            （1）第一步：在数据源（Monitor）定义Analysis Port
                 class my_monitor extends uvm_monitor;
                   // 声明分析端口
                    uvm_analysis_port #(my_transaction) mon_analy_port;
 
                     function new(string name, uvm_component parent);
                       super.new(name, parent);
                       mon_analy_port = new("mon_analy_port", this);
                     endfunction
 
                     task main_phase(uvm_phase phase);
                       my_transaction tr;
                       forever begin
                         // ... 采集数据到 tr
                         `uvm_info("MON", $sformatf("Broadcasting transaction"), UVM_MEDIUM)
                         // 广播数据。这是一个函数调用，立即返回。
                         mon_analy_port.write(tr);
                       end
                     endtask
                   endclass 
            （2）第二步：在消费者（SB和Coverage Collector）定义Analysis IMP并实现write方法





解释UVM中TLM通信原理中uvm_tlm_analysis_fifo的全部端口的原理，重点解释什么是port export imp put get peek blocking nonblocking，详细解释
      3. TLM中的FIFO使用
         3.1 FIFO特性
             内部有fifo缓冲区存储数据；
             有analysis_port广播端口，和多个producer（发起者）连接；
             内部有get_port/peek_port，使consumer（消费者）获取数据
         3.3 


4. TLM机制要点
   4.1 
                  
                  
           
            
