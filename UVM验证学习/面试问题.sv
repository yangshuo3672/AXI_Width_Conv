（一）论述性问题
1. 验证的流程？怎么才算验证完备？
   （1）理解设计规格书spec，识别关键功能、性能指标、接口协议
   （2）
2. 结合项目说明测试点是怎么分解的？什么流程步骤？

3. 讲解印象最深的一个测试用例？debug经历
 


（二）UVM专业性问题
1. 阐述UVM树形结构

UVM树形结构的依据是组件的实例化，不是继承关系决定的。
结构：
uvm_root (uvm_top)  ← 树的根节点，全局唯一，由UVM自动创建
│
└── uvm_test_top    ← 用户创建的 test 实例，由 run_test("my_test") 挂载到根节点
    │
    └── my_env      ← uvm_env
        │
        ├── my_scoreboard      ← uvm_component
        │   └── (各种 analysis_imp)
        │
        ├── my_ref_model       ← uvm_component
        │
        └── my_agent           ← uvm_agent
            │
            ├── my_driver      ← uvm_driver
            ├── my_monitor     ← uvm_monitor
            └── my_sequencer   ← uvm_sequencer
                │
                └── (sequence 在运行时动态挂载到 sequencer 下)
                   
2. 解释uvm_component 与 uvm_object 以及UVM   中常用类的继承关系。
   uvm_object是最基本的类，几乎所有的UVM类都继承自它。uvm_component叶派生自它。
   uvm_component所特有的特性：（1）通过new的时候指定parent参数形成UVM树形结构   （2）有phase自动执行的特点

   继承关系：
   重点：派生自uvm_object的类包括：uvm_sequence_item uvm_sequence config uvm_component uvm_phase 
uvm_void  ←── 最顶层抽象基类，无任何成员
│
├── uvm_object  ←── 所有UVM对象的基类（有create/clone/print等）
│   │
│   ├── uvm_report_object  ←── 加入报告机制（uvm_info/warning/error）
│   │   │
│   │   └── uvm_component  ←── ★ 树形组件基类（有phase/parent/name）
│   │       │
│   │       ├── uvm_test          ←── 测试顶层 --- 所有的测试用例派生自此。任何一个派生出的测试用例都要实例化env，只有如此，当此时用例在运行时，才可以正常发数据到DUT。
|   |       |—— uvm_root
│   │       ├── uvm_env           ←── 环境容器
│   │       ├── uvm_agent         ←── 协议代理 --- agent只是把monitor和driver封装到一起，根据配置参数值来对组件的实例化做改变，主要是从可重用性的较低考虑。如果不考虑重用，agent可有可无。
│   │       ├── uvm_driver        ←── 驱动器 --- 相比uvm_component，增加了几个变量：req，rsp，rsp_port,seq_item_port,seq_item_port_if.  具体见白皮书pg59
│   │       ├── uvm_monitor       ←── 监视器 --- 没有做任何扩充
│   │       ├── uvm_sequencer     ←── 序列器 --- 做了很多扩充
│   │       ├── uvm_scoreboard    ←── 计分板
│   │       ├── uvm_subscriber    ←── 订阅者（用于coverage）
│   │       └── uvm_reg_block     ←── 寄存器块（RAL）
│   │
│   ├── uvm_transaction
│   │   └── uvm_sequence_item     ←── ★ 数据包/事务基类
│   │
│   ├── uvm_sequence_base
│   │   └── uvm_sequence          ←── ★ 序列基类
│   │
│   ├── uvm_reg  /  uvm_reg_field  ←── 寄存器模型
│   │
│   └── uvm_barrier / uvm_event    ←── 同步机制
│   │
│   └── my_cfg    ←── 配置类（规范验证平台的行为准则）
└── uvm_port_base  ←── TLM端口基类（通常不直接使用）
    └── uvm_port / uvm_export / uvm_imp  ←── TLM通信端口
                   
3. 介绍UVM域的自动化

4. frok jion三类语句的区别是什么？如何终止后台残留线程？disable frok的作用域是什么

5. 介绍单例模式，单例模式有什么好处

6. `uvm_do(req) 宏的具体内容是什么？

7. 验证环境有哪些组件？构建顺序是什么？

8. interface是怎么传递到组件中的？在哪一层传？为什么不能传真实物理接口？
   （1）在顶层uvm_config_db
   （2）interface为什么用virtual 
    interface是真实的硬件结构在top里面例化了，而env中的组件是class是软件，不能够直接访问硬件中的接口，因此采用virtual达到一个句柄的效果让组件能够访问驱动interface
    
9. 讲一下对virtual sequence、sequencer的理解

10. phase机制从上到下有哪些？哪些自顶而下？run_phase 和 main_phase可以同时使用吗？

11. AXI slave VIP的memory模型是怎么搭建的？用的什么数组？

12.sequence和driver握手机制

13. 静态变量动态变量的考察：举了一个task的例子，task是延迟时间，一次传动态变量一次传静态变量

14. function和task的区别；ref形参的理解

15. TLM通信，举具体的使用例子

16.  sv和UVM提供哪些同步手段？

17. 与uvm_object相关的宏
   （1）`uvm_object_utils()   将直接或间接派生自uvm_object的类注册到factory
   （2）`uvm_object_param_utils() 将直接或间接派生自uvm_object的参数化注册到factory
   （3）`uvm_object_utils_begin()  *** `uvm_object_utils_end   当需要filed_automation机制时，需要此宏
18. 与uvm_component相关的宏
   （1）`uvm_component_utils()   将直接或间接派生自uvm_component的类注册到factory
   （2）`uvm_component_param_utils() 将直接或间接派生自uvm_component的参数化注册到factory
   （3）`uvm_component_utils_begin()  *** `uvm_component_utils_end   当需要filed_automation机制时，需要此宏
   eg: `uvm_object_utils_begin(axi_interface_agent_cfg)
             `uvm_field_int(addr_width , UVM_ALL_ON)
             `uvm_field_int(dataA_width , UVM_ALL_ON)
      `uvm_object_utils_end


19. override机制是什么？分为哪几类？应用场景有哪些？
   （1）不修改原有验证环境代码，通过 UVM Factory，把原本要创建的类替换成另一个派生类。
       eg: 原有创建了: base_driver drv;  drv = base_driver::type_id::create("drv", this);
           若配置了: base_driver::type_id::set_type_override(error_inject_driver::get_type());
           那么Factory机制会在创建前查找该组件有没有被override，如果被重载，实际创建的对象就是error_inject_driver
    (2) 分类：Type Override 和 Instance Override
   Type Override: 某一种类型，全局替换成另一种类型。比如将原有的driver修改为错误注入driver(Callback)，上述例子就是。
       Instance Override: 只替换某一个特定层次路径下的实例。
       eg: base_driver::type_id::set_inst_override(error_driver::get_type(),"env.master_agent.drv");  //只替换了master_agent下的drv
   （3）错误注入测试或者想更改其中过一个Agent
注意：override必须在组件创建之前，否则重载不生效。
   
20. 
      

   

