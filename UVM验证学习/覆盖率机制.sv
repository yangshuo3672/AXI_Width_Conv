1. 分类
（1）代码覆盖率：衡量测试激励对DUT代码的遍历程度，无需手动编写。
   Line Coverage               行覆盖率        每一行 HDL 代码是否被执行             
   Toggle Coverage             信号翻转覆盖率   每个 bit 是否发生过 0→1 和 1→0 的跳变  
   FSM Coverage                状态机覆盖率     所有状态是否被进入，所有状态转移是否发生        
   Branch/Condition Coverage   分支/条件覆盖率  `if/else`、`case` 的每个分支是否被触发 
   Expression Coverage*        表达式覆盖率     逻辑表达式中各条件的组合是否被覆盖       

（2）功能覆盖率：手动编写，衡量验证激励对设计规格中功能的覆盖率
    列出功能点清单，再转化成covergroup，看最后哪些bin没有被hit

（3）断言覆盖率：介于代码和功能之间，描述协议和时序规则



2. 如何规划功能覆盖率的bin（仓）：最小统计单位
       bin的本质是将Spec中的功能点映射为可量化的取值区间
       在covergroup中，每个coverpoint会按取值划分为若干个bin，每次采样时，如果变量值落入某个bin中，则该bin的计数器+1
                           覆盖率 = 已命中的bin/总bin数

      划分类型：
         （1）自动bin：SV自动按位宽均分，如addr位宽为N，自动生成N个bin
         （2）用户显示自定义取值范围：bins low = {[0:100]};
          (3) 转换bin：记录状态和值得转义序列，比如bins idle_to_busy (IDLE=>BUSY);
          (4)忽略bin：不计入覆盖率统计  ignore_bins reserved = {7,8};
          (5)非法bin：若命中报错  illegal_bins impossible = {2'b11};

3.
          
          
       

      

