# HiKTPV100 规格说明书

  该项目为设计AXI异步位宽转换桥

## 2.1 功能

master -- AXI 128bit data（1GHz）--- HiKTPV100 IP --- AXI 64bit data（800MHz）-- slave
req --

## 2.2 规格

### 2.2.1 时钟复位

| 编号 | 规格描述 |
|------|----------|
| HiKTPV100.FS001.001 | 上游和下游各一个输入时钟，两个时钟为异步关系，收敛频率均不低于1GHz@0.8v； |
| HiKTPV100.FS001.002 | 上游和下游各一个输入复位，异步复位，同步撤离到对应时钟域（注意：异步桥不可以单边复位，两个复位需同时有效，请思考为什么）；异步复位同步撤离由外部实现，设计无需考虑； |
   （注释：上游和下游各自的复位信号独立生效，通过同步器在自己的时钟域内完成安全释放，既保证了复位的响应速度，又避免了跨时钟域场景下的亚稳态风险）
| HiKTPV100.FS001.003 | 上下游的时钟频率之间无约束关系，支持上游时钟频率大于或小于下游的场景； |

### 2.2.2 支持协议

| 编号 | 规格描述 |
|------|----------|
| HiKTPV100.FS002.001 | 支持ACE-Lite，AXI4协议，不支持AXI3协议； |
| HiKTPV100.FS002.002 | 地址位宽32bit，上游数据位宽128bit，下游数据位宽64bit； |
| HiKTPV100.FS002.003 | 不支持写数据间插； |
| HiKTPV100.FS002.004 | 不支持上游下发同ID读命令或同ID写命令，但是允许同时下发的读命令和写命令ID相同； |
| HiKTPV100.FS002.005 | 支持不同ID读命令的读数据间插； |
| HiKTPV100.FS002.006 | 支持不同ID的读写响应乱序返回； |
| HiKTPV100.FS002.007 | 只支持INCR传输； |
| HiKTPV100.FS002.008 | 上游Burst Length支持0~7，下游Burst Length支持0~15，不支持超长Burst； |
| HiKTPV100.FS002.009 | 不支持地址非对齐命令，即上游下发命令的地址一定可以被16Byte整除； |
| HiKTPV100.FS002.010 | 不支持Narrow命令，即上游下发命令的SIZE=4； |
| HiKTPV100.FS002.011 | 支持的读写最大Outstanding为各16，即同时最多只能接收16个上游下发的读命令和16个上游下发的写命令； |
| HiKTPV100.FS002.012 | 支持协议中的Qos、User、Region、Domain、Cache、Barrier等随路信号透传； |

### 2.2.3 包格式

| 编号 | 规格描述 |
|------|----------|
| HiKTPV100.FS003.001 | 内部数据流采用UIF协议，即写命令通道和写数据通道合并，写命令和对应写数据的第一拍同周期发送，其余和AXI协议一致； |
| HiKTPV100.FS003.002 | UIF协议采用Valid-Ready握手实现数据传输； |

### 2.2.4 位宽转换

| 编号 | 规格描述 |
|------|----------|
| HiKTPV100.FS004.001 | 对于INCR命令，将命令转换为输出端口位宽（即SIZE=3）的INCR发送； |
| HiKTPV100.FS004.002 | 对于任意命令，不需要对命令进行拆分，即收到一个 SIZE=4的命令，下发一个SIZE=3的命令，两个命令总数据量相同； |
| HiKTPV100.FS004.003 | 如果向上游返回的响应需要由多拍下游收到的响应Merge，任何一个响应有Error，则向上返回第一个有Error的响应；支持下游回OKAY、SLVERR、DECERR，不支持回EXOKAY； |
| HiKTPV100.FS004.004 | 向上游返回Buser和Ruser时，Merge完的User以下游返回的两拍中的第一拍为准； |
| HiKTPV100.FS004.005 | 对于数据的转换，Wdata从128bit转换为2拍64bit时，先下发128bit数据中的低64bit；Rdata从2拍64bit转换为128bit时，先收到的64bit数据放在128bit的低64bit位置； |

### 2.2.5 自动门控

| 编号 | 规格描述 |
|------|----------|
| HiKTPV100.FS005.001 | 上游时钟支持自动门控，收到上游操作或者有操作正在进行时打开上游时钟，在没有操作正在进行时自动关闭上游时钟； |
| HiKTPV100.FS005.002 | 支持通过寄存器配置打开或关闭自动门控，关闭自动门控时上游时钟常开； |
| HiKTPV100.FS005.003 | 下游时钟不支持自动门控； |

### 2.2.6 性能

| 编号 | 规格描述 |
|------|----------|
| HiKTPV100.FS006.001 | 跨异步传输不引入额外性能损失，即高频向低频传输，且高频时钟域带宽>=低频时钟域带宽时，低频时钟域数据传输无气泡； |
| HiKTPV100.FS006.002 | 位宽转换不引入额外性能损失，即高位宽向低位宽传输，且高位宽侧带宽>=低位宽侧带宽时，低位宽侧数据传输无气泡； |

### 2.2.7 可维可测

| 编号 | 规格描述 |
|------|----------|
| HiKTPV100.FS007.001 | 支持检测到下游返回ERROR响应时上报电平中断； |
| HiKTPV100.FS007.002 | 中断可以通过寄存器配置屏蔽，可以通过寄存器写1清除； |
| HiKTPV100.FS007.003 | 支持记录发生错误的命令及其相关信息（ADDR/ID），并通过寄存器回读；发生错误时只记录第一笔出错命令的地址和ID（读写错误信息均需独立记录），中断clear以后可以再次记录； |
| HiKTPV100.FS007.004 | 支持通过寄存器回读内部FIFO的空满状态及各Valid-Ready接口的握手状态； |

### 2.2.8 配置接口

| 编号 | 规格描述 |
|------|----------|
| HiKTPV100.FS008.001 | 支持APB4.0接口访问内部寄存器； |
| HiKTPV100.FS008.002 | 地址位宽12bit，数据位宽32bit； |
| HiKTPV100.FS008.003 | 不区分安全/非安全寄存器读写； |
| HiKTPV100.FS008.004 | 不支持pstrb，pstrb != 4'b1111的寄存器写操作无效； |
| HiKTPV100.FS008.005 | 不支持返回pslverr； ||

#  3.概要设计
## 3.1 顶层端口
（1）时钟复位: aclk_s, aresetn_s, aclk_m, aresetn_m
（2）DFT : dft_mode , dft_glb_gt_se
（3）APB: APB4寄存器配置端口
（4）AXI4 salve接口，数据位宽128，地址位宽32，id位宽8，len位宽4，size位宽3，burst位宽2，cache位宽4，prot位宽3；
     AXI4 master接口，数据位宽64，地址位宽32，id位宽8，len位宽4，size位宽3，burst位宽2，cache位宽4，prot位宽3；

## 3.2 模块划分
   AXI2UIF: AXI4协议转UIF协议
   U2U: UIF协议跨时钟域异步桥
   CVT: UIF协议位宽转换桥
   UIF2AXI: UIF协议转AXI4协议
   注: UIF协议对AXI协议做了约束，将写命令通道和写数据通道合并，并且规定写命令必须和该写命令对应的第一拍写数据同周期发送。
  
  整体数据流位axi-master（128bit） ---    | axi-slave（128）    KTP模块    axi-master（64）| --- axi-slave（64bit）

  KTP模块由两个时钟域组成，分别是作为输入的salve和作为输出的master

   模块间的传输数据步骤为：AXI-128bit位宽的信号输入给 AXI2UIF 模块，输出产生UIF-128（slave时钟域）端口信号；UIF-128（slave时钟域）信号输入到CVT模块，生成UIF-64（slave时钟域）的端口信号；UIF-64（slave时钟域）信号输入到U2U模块做跨时钟域转换，生成UIF-64（master时钟域）;UIF-64（master时钟域）信号输入给UIF2AXI模块，生成AXI-64信号。其中slave时钟域位1GHz，master时钟域位800MHz。
   APB配置接口用于配置CVT模块，注意由于CVT模块两侧信号都采用salve时钟域，所以APB的时钟也使用slave侧的时钟域。

## 3.3 UIF协议解释

UIF协议是KTP模块的内部协议格式，对AXI协议做了约束，将写命令通道和写数据通道合并，并且规定写命令必须和该写命令对应的第一拍写数据同周期发送,可以避免产生死锁。

写通道：uaww_valid,uaww_raedy,uawaddr,uwdata,uwlast
写响应通道： ub_valid, ub_ready,ubresp
读地址通道：uar_valid,uar_ready,uaraddr
读数据通道：ur_valid,ur_ready,urdata,urlast

## 3.4模块设计

### 3.4.1 AXI2UIF
    
   （1）valid-ready握手
   AXI和UIF协议都采用valid-ready握手进行数据交互，该握手允许双向反压，只有两边同时拉高才会发生数据传输。所以对于发送方，吧valid拉高为1的同时必须保证数据有效，如果对方没有准备好ready，数据必须保持。对于接收方，把ready拉高为1必须保证当拍可以接收数据，如果发送没有准备好valid和数据，则当拍不能采样无效数据。
   （2）AW和W通道的耦合。
    UIF协议要求写命令和第一拍写数据必须同周期发送，但是AXI协议允许写命令和第一拍写数据不在同一周期，有些master会设计成写命令发送后才发送数据，且AW个W通道路径上可能存在不同级数的register slice，所以AW和W到达AXI2UIF模块的时间节点可能不同，所以参考设计必须能够处理AXI4协议的不同传输场景。
      设计要求能够处理的场景包括: (1) awvalid和wvalid同时到达  （2）wvalid早于awvalid到达
                                （3） awvalid遭遇wvalid到达  （4）awvalid到达前数据fifo已满，允许反压wvalid

    注意：AXI2UIF模块用于接收UIF-128（salve时钟域）的信号，将其转换为UIF-64（slave时钟域）

### 3.4.2 U2U模块

  U2U模块完成UIF信号的跨时钟域转换，将UIF-64(slave时钟域  定义为clk_a)转换为UIF-64（master时钟域,定义为clk_b）
  UIF协议定义了四个独立的通道，通道之间没有时序约束关系，因此基于UIF协议的异步桥通常可以使用4个异步FIFO实现。

  信号传输流程如下  ：   AWW_UP ---> AFIFO_AWW --->AWW_DOWN
                       AR_UP  --->  AFIFO_AR  --->AR_DOWN
                       R_UP  <---  AFIFO_R  <--- R_DOWN
                       B_UP  <--- AFOFP_B <--- B_DOWN
异步FIFO的端口包括：
异步FIFO设计要点：
  （1）地址同步
      异步FIFO设计要避免空读满写，所以再读写各自手中与都要知道FIFO的空满状态，而空满状态设计读写指针的比较，需要将读写指针分别同步到对面时钟域。注意FIFO的读写指针是二进制编码的多bit信号，打拍时需要转换成格雷码
  （2）FIFO深度
      异步FIFO需要将读写地址同步到对端，数据写入到可以读出有延迟，读出之后有空间再写入又有延迟，所以如果要实现流水线连续读写，对异步fifo的深度有最小要求。

### 3.4.3 CVT模块
   CVT模块将上游的UIF-128信号转换为下游的UIF-64，在这个过程中要做到三个基本功能：1. 命令的转换 2.数据的拆分  3. 响应的拼接
    当前存在一种参考结构: 分别由两个模块cmd_pack resp_merge组成，其中数据流向为：
                              UIF128 req ---> cmd_pack ---> UIF64 req
                              UIF64 RESP ---> resp_merge ---> UIF_resp 
    cmd_pack根据位宽转换原则对输入的命令/数据进行处理，resp_merge模块对返回的数据/响应进行拼接，凑齐一拍上游位宽的数据/响应后返回一拍数据/响应

    CVT设计要点：
  #### 1.cmd_pack主要实现命令的转换，接收到上游下发的一个命令。cmd_pack对命令的size和len进行转换，转换原则是前后的命令的数据量和地址完全一致。
      KTP支持上游下发的操作如下: 128位FULL SIZE操作;Burst length位0-7;地址位16的整数倍（16Byte对齐）;
      KTP支持下游下发的操作如下: 64位FULL SIZE操作;Burst length位0-15;地址位16的整数倍（16Byte对齐）;
      因此KTP不涉及需要将一个命令拆分为多个命令的情况，也不涉及地址不对齐情况的拼接。所以cmd_pack只需要对Axsize和Axlen进行处理，其余信号均可以不做处理直接下发。
      处理方法如下: SIZE信号: 将输入值4转为3输出。
                    LENGTH信号: 输出length的的值=输入length的两倍+1
      例如，收到的命令如下: ADDR=0 SIZE=4 LEN=1。该命令被转换为ADDR=0 SIZE=3 LEN=3。

  #### 2.resp_merge实现读数据的重组和响应的合并，所以需要存储空间保存暂时不能向上返回的读数据和响应。
    下游响应支持乱序返回和间插返回，故存储空间需要足够的深度，否则会因为无法接收下游返回的数据，同时存储空间中的数据也无法向上游返回，导致死锁。本设计支持最大outstanding为16，故buffer需要的深度为16。
   以下是resp_merge处理响应和读数据的流程:
      (1)如果受到一个写响应，直接将写响应向上透传。
    （2）收到一个读响应（包含读数据），resp_merge通过响应的id和存有有效数据的buffer进行比较，判断该id对应的数据是否已经保存在buffer中
    (3)如果该响应的id没有找到匹配的buffer行，说明buffer中没有保存该id对应的数据，为该id分配一个新的buffer行，并将数据写入该buffer行；
    （4）如果该读响应的id找到匹配的buffer行，说明buffer中保存了该id的读数据，将匹配的buffer行保存的数据与该读响应的数据拼接，作为向上游返回的128bit读数据。

   以下是一个简单的数据操作流程：
      在resp merge模块中有一个多行存储单元（使用item表示存储地址）。
     （1）初始状态所有存储项无效
     （2）下游返回一拍读数据，且该读数据ID（ID1）未分配，则分配一个新的存储空间item1，写入ID、读数据和响应信号到该存储空间。
     （3）下游返回又一拍读数据，且该读数据的ID（ID2）未分配，则分配一个新的存储空间item2，写入ID、读数据和响应信号到该存储空间。
     （4）下游返回一拍读数据，且该读数据的ID（ID1）已经分配，则将数据写入已分配(ID1)所在的空间item1。
     （5）此时item1存储的数据已经足够向上游返回一拍读数据，将读数据向上游返回，同时失效ID1和item1。注意此时如果下游同时返回一拍读数据，则将item失效和分配item可以并行执行，提高效率。
       
       该方式可以使用查找表操作实现逻辑，当一个新的响应进入resp_merge模块时，将每个item保存的ID和新响应的ID作比较。如果二者的ID "等于"且item为有效，则
该item对应的hit信号为高，将所有item的hit信号拼接，即可以得到查找结果的OenHot格式。如果查找条件为其他条件，可以将"等于"换为其他条件。该查找逻辑适用于item之间没有相互耦合的场景。

## 3.4.7 寄存器空间划分（32位）
  偏移地址      类型   名称                bit位                         描述        
(1)
   0x0000       RW   KTP_GLB_CTRL        [31:1]--reserved          
                                         [0]--ckg_bypass               0x0:clock gating enable  0x1:clock gating bypass  复位值：0x0

(2)
   0x0010       RW   KTP_IRPT_NS_MSK     [31:1]--reserved
                                         [0]--ktp_irpt_ns_msk          non-secure interrupt mask 0x0:interrupt enable  0x1:interrupt disable    复位值：0x1

(3)
   0x0014       RO   KTP_IRPT_NS_RAW     [31:1]--reserved
                                         [0]--ktp_irpt_ns_raw          KTP non-secure interrupt raw states  复位值：0x0

（4）
   0x0018       RO   KTP_IRPT_NS_STAT    [31:1]--reserved
                                         [0]--ktp_irpt_ns_stat         KTP non-secure interrupt mask states  复位值：0x0
                                      
（5）
   0x001c       WO   KTP_IRPT_NS_CLR     [31:1]--reserved
                                         [0]--ktp_irpt_ns_stat         0X0:interrupt hold  0x1:interrupt clear  复位值：0x0

（6）
   0x0100       RO  KTP_DEBUG_INFO_0     [31:0] dbg_info_0             Debug port info data 0 复位值：0x00000000
                                      
（7）
   0x0104       RO  KTP_DEBUG_INFO_1     [31:0] dbg_info_1             Debug port info data 1 复位值：0x00000000

（8）
   0x0108       RO  KTP_DEBUG_INFO_2     [31:0] dbg_info_2             Debug port info data 2 复位值：0x00000000
                                      
（0）
   0x010c       RO  KTP_DEBUG_INFO_3     [31:0] dbg_info_3             Debug port info data 3 复位值：0x00000000





  
  
  该IP不需要进行AXI协议格式的校验，默认按传来的格式争取处理。
   要点注意：
   slave侧AXI口:（1）上游的arsize/awsize[2:0]必须为3'd4，否则不支持。即不支持narrow传输。那么wstrb必须全1。
                （2）上游的burst length支持0-7，所以arlen/awlen为3bit位宽即可？  设计中给的是4bit
                （3）不支持地址非对齐，即上游下发的awaddr/araddr[31:0]必须是可以被16整除，负责无效。0x00，0x10，0x20....
                （4）不支持上游下发同ID的读命令和写命令。即在一笔burst传输未结束时，上游再次下发的id不能与该id相同。但是读通道和写通道之间不用管，id可以一致。（缓存进行中的传输id，下次事务来之前与缓存中的全部id作比较）
                （5）不支持写数据间插（当前burst的wdata全部传完才能开始传下一次burst的wdata）
