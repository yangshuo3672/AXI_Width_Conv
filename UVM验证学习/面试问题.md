（一）论述性问题
1. 验证的流程？怎么才算验证完备？

2. 结合项目说明测试点是怎么分解的？什么流程步骤？

3. 讲解印象最深的一个测试用例？debug经历



（二）UVM专业性问题
1. 阐述UVM树形结构

2. sv和UVM提供哪些同步手段？

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

