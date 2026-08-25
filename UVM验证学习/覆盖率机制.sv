1. 分类
（1）代码覆盖率：衡量测试激励对DUT代码的遍历程度，无需手动编写。
   Line Coverage               行覆盖率        每一行 HDL 代码是否被执行             
   Toggle Coverage             信号翻转覆盖率   每个 bit 是否发生过 0→1 和 1→0 的跳变  
   FSM Coverage                状态机覆盖率     所有状态是否被进入，所有状态转移是否发生        
   Branch/Condition Coverage   分支/条件覆盖率  `if/else`、`case` 的每个分支是否被触发 
   Expression Coverage*        表达式覆盖率     逻辑表达式中各条件的组合是否被覆盖       

（2）功能覆盖率：手动编写，衡量验证激励对设计规格中功能的覆盖率
     

