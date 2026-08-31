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
          (4) 忽略bin：不计入覆盖率统计  ignore_bins reserved = {7,8};
          (5) 非法bin：若命中报错  illegal_bins impossible = {2'b11};

3.覆盖率收集流程
   测试点分解
   搭建功能覆盖率模型： 定义触发事件-->定义covergroup-->定义coverpoint-->定义cross-->根据触发事件，编写覆盖率收集代码
   收集功能覆盖率

4. 覆盖率收敛步骤
      （1）冒烟测试阶段：主要做方案与验证平台环境开发，功能覆盖率很低
      （2）功能收敛：前期准备完成后，功能覆盖率急剧上升，随着随机的全面展开，通过自动化收集，大部分覆盖点将被覆盖
      （3）定向随机补充：当功能覆盖率收集到一定阶段后，往往会存在一些边界场景，通过大量随机依然很难冲击到。这些边界场景可能在现有随机平台冲击到的概率很低，
                        也有可能随机根本就冲击不到。对于概率很低的点，我们需要构建定向随机平台，提升冲击概率，完成一部分边界场景的收集。

5.如何完成功能覆盖率模型？
      covergroup本身语法简单易懂，但是要做好covergroup需要对验证环境和DUT的接口、规格、测试点非常了解。如何收集以及哪些组合，才能保证覆盖点真实有效。
  （1）功能覆盖率模型（covergroup）
      covergroup就是把语言描述的功能进行抽象，提取属性并对属性的取值划分，在恰当的时候记录各个属性取值的出现情况，以及一些必要的组合，给功能覆盖率分析提供统计的对象和流程。
      为避免添加covergroup对环境带来太大改动，需要独立出来一个class，选择合适的组件例化这些类。
      提供FCOV宏参数开关控制，能全局或者局部控制，便于有些时候关闭FCOV以提高仿真效率

   （2）覆盖点（coverpoint）
         coverpoint是覆盖率模型中基于某一个触发事件收集的变量或表达式，将需要关注的功能点对应到具体的参数取值上，定义为coverpoint或者cross(组合覆盖点)，并列出关心的取值空间（bins）
         coverpoint关注一下几类：1）主控下发的配置参数 2）输入输出的数据流 3）逻辑内部需要关注点  4）以上几点的必要组合
      
    
6. AXI VIP的覆盖率种类
    （1）协议层覆盖：验证AXI协议的基本规范是否被满足
         握手信号覆盖、突发类型覆盖、突发长度覆盖、突发大小覆盖、交叉覆盖、
    （2）事务层覆盖
         读写事务、ID、outstanding、out-of-order、interleaving
    （3）
收集的功能点：
axi_wr_id: 验证上游写id是否能够覆盖0-8’hff
axi_wr_addr: 验证写地址能否覆盖0-32’hfff_f7f0
axi_wr_size: 验证写size能否覆盖4
axi_wr_resp: 验证写响应能否覆盖okay和slverror和decerror
axi_bresp：验证写响应返回状态
axi_wr_ots_num: 验证写通道的outstanding能力
axi_wr_ooo_num: 验证乱序深度
axi_rd_id： 验证上游读id能否覆盖0-8’hff
axi_rd_addr：验证读地址能否覆盖0-32’hffff_f7f0
axi_rd_size：验证读size能否覆盖4
axi_rd_resp：验证读响应能否覆盖okay和error
axi_rresp：验证读响应返回的状态
axi_rd_ots_num：验证写通道的outstanding能力
axi_rd_ooo_num：验证乱序深度
mst_awvalidwvaliddelay：验证上游aw和w通道之间的相位关系
mst_awvalidawreadydelay：验证上游aw通道中valid对ready的反压延时
mst_arvalidarreadydelay：验证上游ar通道中valid对ready的反压延时
mst_bvalidbreadydelay：验证上游b通道中valid对ready的反压延时
slv_awvalidwvaliddelay：验证下游aw和w通道之间的相位关系
slv_awvalidawreadydelay：验证下游aw通道中valid对ready的反压延时
slv_arvalidarreadydelay：验证下游ar通道中valid对ready的反压延时
slv_bvalidbreadydelay：验证下游b通道中valid对ready的反压延时


   


5. 交叉覆盖cross
         coverpoint统计单个变量的分布
         cross统计多个变量组合在一起时的分布

6. 几种关键字
         
         
         
          
          
       

      

