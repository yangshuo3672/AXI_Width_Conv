### 一，项目介绍

​	AXI_Data_Switch用于实现AXI主从机交互时，任意数据位宽转换。AXI_Data_Switch可以分成大位宽转小位宽和小位宽转大位宽两个部分。

​	大位宽转小位宽：

​	以写过程为例：设计aw模块根据具体突发命令转换要求。对突发命令信息进行处理(地址、突发长度等)，aw通道的突发命令在突发拆分之后会有多个突发命令，因为aw通道的突发命令一般会比w通道和b通道先完成传输，所以使用fifo缓存拆分后的多个突发命令。再由w通道模块和b通道模块去读取fifo 中缓存的拆分之后的突发命令，分别完成数据位宽转换和写响应信号返回。每个模块之间均采用握手的方式传输数据。读过程类似，aw通道模块和ar通道模块复用，不同的是，数据通道返回的是多拍拼接的数据。

​	小位宽转大位宽还是以写过程为例，有主要两点不同：

​	① AW突发命令处理不同，大位宽转小位宽根据burst类型、burst_sizer和burst_length不同共十几种处理策略。小位宽转大位宽还额外支持数据填充模式和数据打包模式。数据填充模式是直接对si端的数据进行复制填满mi端的数据位宽， mi端数据拍数和si端数据拍数相等。Packing 模式则是需要累积多拍si端数据之后再由mi端一拍输出。

​	② 小位宽转大位宽还支持异步时钟数据位宽处理。因此结构也有所不同，使用异步FIFO完成AW通道数据处理和时钟转换。使用伪双口RAM实现W通道位宽转换和时钟转换。大位宽转小位宽不会出现没有输入数据或数据读空时继续读取数据，因此可以采用组合逻辑，大位宽转小位宽需要采用状态机去解决；大位宽转小位宽采用反压的方式避免数据覆盖，小位宽转大位宽采用设置水位的方式。

​	

​	AXI_Data_Switch IP包含一个时钟域或者两个时钟域，涉及主机端时钟s_aclk和从机端时m_aclk。当主机端数据位宽大于从机端位宽时，即大位宽转小位宽模式下，要求主机端时钟和从机端时钟为同一时钟；当主机端数据位宽小于从机端位宽时，即小位宽转大位宽模式下，允许主机端时钟和从机端时钟不同，内部可进行时钟转换。根据不同brust突发方式（FIX、INCR和WRAP）和位宽倍率，制定不同拆分策略，完成数据位宽转换，并对非对齐传输进行管理，支持AXI3/4和AXI4lite协议；SI/MI数据位宽：32/64/128/256/512/1024

根据AXI4 设计大位宽转小位宽模块，分析以下公式含义（SI为大位宽端，MI为小位宽端）:



### 二，项目架构

![image-20250318215526487](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250318215526487.png)

#### 1. 大位宽转小位宽转化规则

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250320133046911.png" alt="image-20250320133046911" style="zoom:80%;" />

​                                                         <img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250320133109505.png" alt="image-20250320133109505" style="zoom:80%;" /> 	

> INCR：

1. 如果窄传输的实际数据转为小位宽后依旧小于AXI的数据位宽，直接传输，不做任何改变。

2. MI beats <= 256 （MI beats <= 16）

   | Transcation |                   LEN                    | ADDR      | BURST | LOCK         |
   | :---------: | :--------------------------------------: | --------- | :---: | ------------ |
   |      1      | si.downsize_LEN  -  mi.AlignedAdjustment | No Change | INCR  | s_axi_a*lock |

   **`si.SizeMask = (2^si.SIZE) – 1` : 生成大端地址对齐掩码。**

   - 用于提取大端地址在传输大小内的偏移量。例如，`si.SIZE=4`（16字节），掩码为`0xF`（低4位），地址`0x1234 & SizeMask = 0x4`

   **`mi.AlignedAdjust ment= (si.ADDR & si.SizeMask & ~mi.ByteMask) / mi.Bytes` ：计算地址未对齐时的调整量。**

   - - `si.ADDR & si.SizeMask`：获取大端地址在其传输大小内的偏移量。
     - `& ~mi.ByteMask`：进一步与小端地址对齐掩码的非操作结合，提取未对齐部分。
     - 除以`mi.Bytes`：将偏移量转换为小端传输次数调整量。

   - **示例**：若大端地址偏移为`0x0C`，小端对齐要求为8字节（`mi.ByteMask=0x7`），则`0x0C & 0xF & ~0x7 = 0x08`，调整量为`0x08/8 = 1`

     注意非对齐传输：

     master进行非对齐传输处理：AW/AW通道地址是非对齐的，W/R通道 `WSTRB` 标记无效数据位。

     <img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250320165052557.png" alt="image-20250320165052557" style="zoom:80%;" />

3. MI beats > 256  （MI beats > 16 ）

   |               Transcation                |                             LEN                              |                             ADDR                             | BURST | LOCK |
   | :--------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: | :---: | ---- |
   | ceil  ((si.downsize_LEN+1 ) / max_beats) | first = max_beats -  mi.AlignedAdjust ment - 1  ;                                                last =  si.downsize_LEN %  max_beats;                  others =  max_beats - 1 | first = si.ADDR;              transaction i =  (si.ADDR &  ~si.SizeMask ) + ((i-1) *  max_beats*mi.Bytes) | INCR  | 0    |

​	当突发长度需要拆分时，不支持通过模块进行独占访问。如果 awlock 或 arlock 信号指示独占访问写入或读取事务，并且进行突发长	度拆分时， AXI DATA SWITCH 更改所有输出事务中的锁定信号，以指示正常访问 （0）

> WRAP: WRAP的最大突发长度是16

1. 如果窄传输的实际数据转为小位宽后依旧小于AXI的数据位宽，直接传输，不做任何改变。

2.  MI beats <= 16               

   | Transcation |       LEN       | ADDR      | BURST | LOCK         |
   | :---------: | :-------------: | --------- | :---: | ------------ |
   |      1      | si.downsize_LEN | No Change | WRAP  | s_axi_a*lock |

3.  16 < MI beats <= 256,  ADDR is burst-aligned

   | Transcation |     LEN      | ADDR      | BURST | LOCK         |
   | :---------: | :----------: | --------- | :---: | ------------ |
   |      1      | si.wrap1_LEN | No Change | INCR  | s_axi_a*lock |

   `si.wrap1_LEN = si.burst_bytes / mi.Bytes - 1`

   其中：

   如果`start address`是和`burst`对齐，那么最大地址只会达到`upper_boundary-1`，不会发生`wrap`，此时的行为就和`INCR`一致。 

   `si.burst_bytes = 2**si.SIZE * (si.LEN+1)`：si端传输的总字节数；

4. 16 < MI beats <= 256,  ADDR is not  burst-aligned (wrapping  required)

   | Transcation |                             LEN                              |                             ADDR                             | BURST | LOCK |
   | :---------: | :----------------------------------------------------------: | :----------------------------------------------------------: | :---: | ---- |
   |      2      | first =  si.wrap1_LEN ;                  second =  si.wrap2_LEN | first = si.ADDR;                                          second =  si.wrap_address | INCR  | 0    |

   第一次突发为：初始地址到回环上边界的部分；第二部分是从回环下边界到起始地址的部分。

   **突发长度计算：**

   `si.wrap1_LEN = (si.burst_bytes - (si.ADDR & si.burst_mask)) / mi.Bytes - 1`

   `si.wrap2_LEN = (si.ADDR & si.burst_mask) / mi.Bytes - 1 `

   解析：

   `si.burst_bytes = 2**si.SIZE * (si.LEN+1)`：si端传输的总字节数；

   `si.burst_mask = si.burst_bytes - 1`：获取总字节数目的掩码；

   `si.ADDR & si.burst_mask` ：获取大端地址在其传输大小内的偏移量，除以`mi.Bytes` 获得需要突发的次数；

   **突发地址更改：**

   `si.wrap_address = si.ADDR & ~si.burst_mask ` 获得未对齐的部分，进行突发

5. MI beats > 256 （MI beats > 16）

   | Aligned |                         Transcation                          | LEN             |                             ADDR                             | BURST | LOCK |
   | :-----: | :----------------------------------------------------------: | --------------- | :----------------------------------------------------------: | ----- | ---- |
   |   YES   |            ceil  ((si.wrap1_LEN+1) /  max_beats)             | all = max_beats | first = si.ADDR; transaction i =  (si.ADDR &  ~si.SizeMask ) + ((i-1) *  max_beats*mi.Bytes) | INCR  | 0    |
   |   NO    | ceil  ((si.wrap1_LEN+1) /  max_beats) + ceil  ((si.wrap2_LEN+1) /  max_beats) | all = max_beats |       first = si.ADDR; (others  TBD, wrap as required)       | INCR  | 0    |

> FIX:

1. 如果是窄传输，实际数据转为小位宽后依旧小于AXI的数据位宽，直接传输，不做任何改变。

2.  1 < downsize_ratio <= 16  （AXI3）或者 downsize_ratio > 1 (AXI4)

   | Transcation |                             LEN                             | ADDR          | BURST | LOCK |
   | :---------: | :---------------------------------------------------------: | ------------- | :---: | :--: |
   |  si.LEN+1   | all =  max(si.conv_ratio  -  mi.AlignedAdjust ment  - 1, 0) | all = si.ADDR | INCR  |  0   |

3.   downsize_ratio > 16

   |                         Transcation                          |                             LEN                              |                             ADDR                             | BURST | LOCK |
   | :----------------------------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: | :---: | :--: |
   | (si.LEN+1) *  int((si.conv_ratio  -  mi.AlignedAdjustme nt) / max_beats) | first =  (si.conv_ratio  -  mi.AlignedAdjust ment  - 1) %  max_beats;   others =  max_beats - 1 | first = si.ADDR;                  (others  TBD, repeat si.ADDR or  increment as needed) | INCR  |  0   |

> ==AXI4lite单独处理==

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250320140644791.png" alt="image-20250320140644791" style="zoom:80%;" />

对齐：

|                           Formula                            | Transcation |                ADDR                |
| :----------------------------------------------------------: | :---------: | :--------------------------------: |
| Write &&  ~s_axi_awaddr[2] &&  (s_axi_wstrb[7:4] != 0) &&  (s_axi_wstrb[3:0] != 0)                                                                           或者Read &&  ~s_axi_araddr[2] |      2      | first = si.ADDR; second  = si.ADDR |
|    Write &&  ~s_axi_awaddr[2] &&  (s_axi_wstrb[7:4] == 0)    |      1      |              si.ADDR               |

​	AXI-Lite 协议要求地址对齐到数据总线宽度。例如，如果数据总线宽度为 32 位，则地址必须是 4 字节对齐。在这种情况下，  AWADDR[1:0]  （即最低两位）通常为 0，因为它们不影响 4 字节对齐的地址。  AWADDR[2]   则表示地址的第 3 位，当数据总线位宽是64位的时候

非对齐：

|                           Formula                            |                            Result                            | Transcation |       ADDR       |
| :----------------------------------------------------------: | :----------------------------------------------------------: | :---------: | :--------------: |
| Write &&  (s_axi_awaddr[2] or ((s_axi_wstrb[7:4] != 0)  && (s_axi_wstrb[3:0] ==  0))) | One  transaction  with  m_axi_awaddr  = s_axi_awaddr or 'b100;  m_axi_wdata =  s_axi_wdata[63: 32 |      1      | si.ADDR or `b100 |
|                   Read && s_axi_araddr[2]                    | Transaction not  modified;  s_axi_rdata[63: 32] =  m_axi_rdata;  s_axi_rdata[31: 0]  undetermined |      1      | si.ADDR or `b100 |

**注意：**

- [ ] 大位宽转小位宽时，包括事务拆分，不受 AW/ARCACHE 信号值的限制。因为没有其他替代方法可以完成事务，downsizer导致的事务拆分不能被 CACHE 限制。
- [ ] Data Width Converter 不支持直接从 1024 位缩小到 32 位。

#### 2. 小位宽转大位宽转化规则

如果是拓展模式，所有的均不改变。以下规则基于打包模式：

> INCR：S_AXI_A*CACHE[1] （）

| Transcation |      LEN      | ADDR      | BURST | LOCK |
| :---------: | :-----------: | --------- | :---: | :--: |
|      1      | mi.upsize_LEN | No change | INCR  |  0   |

> WRAP:

​	转换成两个INCR模式。

> FIX：所有的不改变，直接传输。



### 三，项目细节

#### 1. 大位宽转小位宽

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250320215109371.png" alt="image-20250320215109371" style="zoom:50%;" />

##### ① addr_downsizer模块

**主要逻辑:**
	addr downsize 主要负责突发命令信息的处理过程，经过大位宽转小位宽之后，单beat信号会拆分为多beat 信号，相应的突发长度也会增加，当突发长度大于最大突发长度时需要进行突发拆分，具体的拆分策略需要根据具体的突发类型和地址情况决定。

​	在突发拆分之后的命令信息处理中，最核心的时axaddr和axlen，其次需要特殊处理的时axid，另外axburst也需要根据具体的突发拆分情况判断是否需要改变突发类型，其他( axregion, axcache, axprot,axlock, axqos)信号在突发拆分时不涉及到改变，可以直传。

​	addr和axlen在突发拆分时需要根据具体的拆分策略进行计算，代码中主要通过组合逻辑进行运算，具体主要为移位运算，节省逻辑。axid 的特殊处理主要因为数据位宽转换模块只允许单个id突发处理，不支持多id突发处理，其中位宽转换模块的si端有id信号，mi端没有id信号，si端的id信号输入后存储到位宽转换模块中，后续的id信号与位宽转换模块内已存储的id进行对比，当id检测到一样则完成转换和传输，否则中断传输。

​	addr通道的突发命令在突发拆分之后会有多个突发命令，并且addr通道的突发命令一般会比w通道和b通道先完成传输，所以需要使用ffo缓存拆分后的多个突发命令，再由w通道和b通道去读取fifo 中缓存的拆分之后的突发命令。在addr通道的从机端看到结果相当于原来si端的单个突发命令转换成了多个突发命令，因而addr通道mi端每输出一次突发命令都需要进行缓存，所以w通道和b通道的突发命令缓存fifo由addr通道控制，并且fifo的输入由addr通道的mi端输出握手信号控制。

**具体控制逻辑:**
	在addr通道的si端输入单个突发命令时，即si_push_ in 拉高则已输入了一个突发的命令信息，则拉低s_axready 不再接受si端的突发，需要等待mi端完成当前突发的完整输出之后再拉高s_axready，重新等待si端握手输入新的突发。

​	此时需要根据具体的突发信息进行判断是否需要拆分，如果需要拆分则需要使用组合逻辑在当前拍完成拆分之后第一个拆分突发的命令信息，然后拉高m_axvalid等待mi端握手输出，同时在mi端握手输出时进行计数，根据计数判断当前时第几个拆分突发，并完成相应的拆分突发命令信息的转换，当计数到最后一个拆分突发命令并在mi端输出时计数清零，完成当前该si端突发命令在mi端的拆分突发的完整输出。在mi端握手输出突发信息时，需要同时控制w cmd_ fifo 和b_ cmd ffo的突发信息写入ffo。

​	但是ffo深度是有限的，并且当大位宽转小位宽的比例较大时，突发信息拆分后的数量增加较大，w通道和b通道读取ffo的速率一般会小于拆分信息写入ffo的速率，则此时ffo有可能会被写满并溢出，因而需要根据fifo的是否为满对写入速率进行反压，即通过ffo为满时控制ffo暂时先被写入，等w通道和b通道读取了ffo 中数据后再继续写入，避免溢出ffo中的有效数据。具体反压过程为当检测到fifo为满时，则将addr端的m_axvalid 拉低，等待W通道和b通道读取ffo中数据，读取后检测到ffo不为满时则重新拉高m_axvalid，等待握手输出和fifo写入，此处重新拉高m _axvalid 信号需要一个标记信号， 表示因为当前可能已经对应si端单个突发的多个突发命令可能刚好在mi端输出到中间就暂停输出了，因而不会再出现si push in 作为标记，所以需要一个表示当前si端单个突发对应的多个拆分突发在mi端还未完整输出的标记信号continue，来重新拉高m_axvalid，继续完成之前的握手输出，反压过程结束。

##### ② w_downsizer模块

主要逻辑:
	在w通道中只需要根据从w_ cmd_fifo中读取的突发命令信息完成响应的数据位宽转换。在大位宽转小位宽时，主要是对数据进行截取，因而需要对输入数据分拍完整输出之后才能允许新数据输入，避免输入数据覆盖。

​	主要逻辑过程为w_cmd_ fifo突发命令和si端握手输入以及mi端握手输出的顺序逻辑控制。Fifo为预取fifo, 首先需要在w_cmd_fifo输出w_ cmd_valid拉高，表示fifo中已有等待转换的突发命令时，根据fifo输出端的突发命令运算得到当前截取起始信息(与地址相关)，然后等待si 端s_walid 拉高，当其为高时说明si端有数据等待握手输入，并且根据AXI协议s_wvalid已经拉高，必须至少完成一次握手才能拉低，此时根据截取信息依次截取si端当前输入数据得到mi端小位宽数据，并在mi端拉高m_wvalid 等待握手输出，同时计数输出数据，当前si 端输入数据对应的mi端小位宽数据完整输出时，同时拉高si端的s_wready 完成当前si端数据的握手输入。si端数据的握手输入和mi端的最后一个转换数据握手输出同时完成(这种方法避免显示输入si端数据等待mi端完成输出)，然后再拉高w_cmd_ready 使得ffo当前数据输出，更新ffo输出的新突发命令信息，并等待s_wvalid 拉高得到新的si端输入数据，准备开始下一次转换过程。

##### ③ b_downsizer模块

主要逻辑:
	在b通道，bresp 信号方向为在mi端握手输入，在si端握手输出。

​	主要为b_fifo握手输出和si端握手输入以及mi端握手输出的顺序逻辑控制。首先b_fifo中缓存了突发拆分的数量，即突发拆分后需要返回的bresp数量，当fifo的b_fifo_ valid 拉高时，则表明fifo中有等待转换的突发命令，b通道中的mi端的m_ready开始则拉高，等待接收从机返回的bresp。当mi端握手输入bresp时进行计数，当计数到fifo 输出的需返回的bresp数量时，表示为拆分突发中的最后一个bresp，则将此bresp通过到si端，因为这些返回的bresp 都只是对应si端的的单个突发，所以只能返回最后一个bresp。即当突发对应的最后一一个bresp输入时，拉高ffo的b_ cmd_ready, 更新fifo输出的下个突发对应的拆分之后所需返回的bresp数量。并同时拉高si端的s_valid等待握手输出，等si端的svalid完成握手输出时,重新拉高m_bready，等待新的bresp输入。

​	此处在最后一个bresp输入后就拉高b_ cmd_ready 更新fifo输出命令信息，是为了让新的命令信息在下一轮bresp输入前出现完成输出。按照正常逻辑来说也可以放到si端svalid完成握手输出之后再拉高b_ cmd ready, 但是因为fifo更新数据要在b_cmd_ready 握手之后，所以放到s valid 握手输出之后如果马上出现新的bresp输入，有可能出现bresp输入时fifo输出信息还未完成更新，要后一拍，可能出现逻辑问题，所以不采用这种逻辑设计。

##### ④ r_downsizer模块

主要逻辑:
	在r通道，rresp 与rdata同时由mi端返回到si端。当cmd_ fifo 的r_cmd_valid 为高时输出经过拆分的新突发信息，则有突发在等待转换，当mi端返回数据，mi端先拉高m_ready握手输入，从机返回的突发都是已拆分后的突发，而主机需要收到的是多个拆分突发对应的单个突发读数据和读响应（采用计数器的方式）。mi端返回的多beat数据组成si端的单beat数据，当mi端读数据输入达到si端的单beat数量时则拉高s_rvalid, 输出当前完成转换的si端数据（同时拉高r_cmd_ready, 更新r_cmd_fifo输出的突发信息），完成握手输出后，再继续拉高m_ready 等待mi端的新数据输入（和拉高r_cmd_ready, 更新r_cmd_fifo输出的突发信息）。

​	在r_cmd_fifo输出的突发信息中有当前突发是否为最后拆分突发的标记，当mi端的最后一个拆分突发的最后
beat输入时，拉高s_rlast，等待转换好的si端数据握手输出，输出后即完成了si 端的单突发的最后一beat 数据输出，则拉低s_rlast。 由于rresp是和rdata 同时返回，所以mi端每一拍rdata都有对应的rresp，和b通道类似，s resp 选取m_rresp中最差的响应进行返回和输出，在代码中即对应的值最大则作为s_rresp 输出。id 信号直接返回r_cmd_fifo输出的id。

##### ⑤ axi4lite_wr_channel_downsizer模块

主要逻辑:
	在axi4lite模式下的downszie，主机端发出的大数据位宽只能是64bits，从机端接收端的小数据位宽只能是32bits，并且突发的长度只能为1，因而在需要拆分的情况下最多只能有两个拆分突发。需要注意的是，决定具体拆分模式的信息分别为s_awaddr[2]和 s_wstrb 这两个信息，分别属于aw通道和w通道，其中s_ awaddr[2]确定突发地址在与8对齐时是属于低4还是高4地址中，s_ wstrb 用于判断64bits数据中(8byte数据)低4byte和高4byte字节分别是否为有效数据。

​	在写通道中，具体分为三种模式，分别为lite_split_downsize、lite low_ order_write_downsize和lite_unaligned_downsizc。其中只有lite_split_downsize模式需要在mi端拆分为2个burst, 其它两种模式在mi端保持1个burst。

​	在程序中，因为需要同时根据aw和w通道信息才能确定具体的拆分模式，所以需要等到aw和w都出现有效数据时，才能开始转换，并且根据协议aw相对于w的顺序可先可后，因而程序中根据s_ awvalid 和s_wvalid 作为转换开始的标记s_ transaction_cmd_updated并拉高，并且在si端握手输出bresp后拉低，表示此次转换已结束，等待下一次aw和w都输入有效数据时再次拉高s fransaction 重新开始进行转换。对于aw通道，转换后在mi端完成最
后一个拆分突发输出之后拉高s_ awready,告诉si端此次aw转换已完成，并等待下一次转换的aw有效数据。对于w通道也是类似，转后在mi端完成最后一个拆分突发输出之后拉高s_wTeady,告诉si端此次w转换已完成，并等待下一次转换的w有效数据。需要注意的是，在拆分情况下，mi端出现多个(2个)拆分突发，在从机端来看相当于将收到多个突发，对于aw通道和w通道的第二个拆分突发，需要(因为是axi4lite)在mi端收到(握手)第一个拆分突发对应的bresp之后才能输出第二个拆分突发给mi端，当从机返回m bvalid则意味着从机以收到上一次的aw和w,则模块就可以拉高下一个拆分突发的valid信号了。对于b通道，从机每收到一次aw和w信息都会返回一次bresp,但对于si端应当只有收到当前突发对应的一次bresp,因而需要对mi端返回的bresp进行判断，当判断为最后一次拆分突发对应的bresp时拉高s _bvalid, si 端输出bresp,等待握手。

##### ⑥ axi4lite_rd_channel_downsizer模块

主要逻辑:
	axi4lite模式下的读通道downszie，主要涉及到两种拆分模式，分别为lite_ split_downsize和litec unaligned downsize, 并且只需要根据ar 通道信息中的s_araddr[2]进行判断。当s_ arvalid 拉高有效时即可判断出具体的拆分模式进行转换，因而以s_ arvalid 拉高时拉高转换开始标记s_transaction cmd_ updated, 在si端接收到rresp返回时拉低s_transaction_ cmd_ updated 表示此次转换结束。
	对于突发拆分的情况，ar 通道的处理过程与aw通道类似，出现拆分模式则会在mi端出现两个拆分突发。当s_ arvalid为高时，则可以开始进行转换，此时拉高m_arvalid等待mi端握手输出，在完成mi端握手输出后拉低m arvalid,但是在拆分情况下，需要在第一个拆分突发握手输出后，需要等待mi端接收到resp反馈之后，才能再次拉高m_arvalid等待第二次ar握手输出，然后握手后再次将m_arvalid 拉低，并且在ar完成最后一个拆分突发握手输出后拉高s_arready,告知si端此次ar转换已完成。对于r通道，在mi端完成ar握手输出后拉高m ready 等待rresp的握手输入，握手输入后拉低m rready，并且在最后一次mready握手输入后拉高s_valid等待握手输出resep到si端，在si端完成握手输出rresp后拉低s_rvalid, 等待下一次转换输出。

#### 2. 小位宽转大位宽模块

​									**同步情况**

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250322205638946.png" alt="image-20250322205638946" style="zoom:70%;" />

##### ① addr_upsizer模块

​	upsize模式下对于地址通道信息的改变相对较少，因为是小位宽转大位宽，所以突发长度只可能保持不变(长度为1时)或者变小，不存在突发拆分的情况，所以所有的地址通道信息最多只需要变换一次。因为地址通道信息传输比数据通道更快完成，所以使用fifo对地址通道转换信息进行缓存，在mi端每输出一次数据则同时将该信息写入到fifo中，等待被w通道读取并进行对应的数据转换，需要使用fifo的非满信号进行反压，当ffo存满时停止mi端输出即ffo的输入，避免fifo中挤出有效数据，在fifo为满时等待w通道读取fifo后，此时fifo非满，可以继续输出mi端的转换信息，需要一个标记信号mi_axpop_ out_continue 重新拉高mi_ax_valid, 恢复到之前的正常传输过程。
​	此模块小位宽转大位宽的具体转换方式主要分为两种，一种为expander 模式，一种为packing模式。其中expander模式是直接对si端的数据进行复制填满mi端的数据位宽，wstrb则只有原si端数据对应的wstrb进行复制，其余位宽的wstrb 保持为0, mi端数据拍数和si端数据拍数相等。Packing 模式则是需要累积多拍si端数据之后再由mi端一拍输出，wstrb则与各拍的si端数据对应，理想对齐情况下mi端的数据拍数减小mi_data_width/si_data_width倍。两种模式从地址和数据的关系来看是效果一致的， 区别在于使用不同的拍数将si端的数据写入到mi端的对应地址。

​	对于两种模式的设置选择，代码中的参数有一定的逻辑关系。首先是upsize_mode参数优先级最高，0对应repeat_expand_upsize (任意突发模式都为expander 模式): 1 对应cmd_set_packing_upsize (根据突发信号对应转换模式，当为iner或wrap突发时，cache[1]=1时使用packing模式，cache[1]=0 时使用expander模式； fixed 模式只有expander模式)。在aw通道中需要根据具体的突发信息和参数设置确定最终使用的expander 模式还是packing 模式完成数据转换，并将该指示信息写入fifo 中，w通道在转换时读取信息并完成响应的转换。
​	对于id信号的处理，当si端有id信号输入时，aw通道对输入的awid信号进行缓存，在mi端不输出id信号，在b通道的mi端输出bresp时同时将缓存的id信号输出。

##### ② w_upsizer模块

​	W通道中根据aw通道中fifo缓存的转换信息对数据进行小位宽转大位宽，主要的转换信息包括具体转换模式，第一拍数据的索引信息，si_axsize 和转换位宽后的突发长度。根据si_axsize可以确定si端每拍传输的有效数据位宽，考虑到narrow transfer的情况，可能需要多拍si数据才能积累到si_data_width 位宽的有效数据，所以在整个转换过程是以si_axsize对应的位宽作为转换的最小单位的。
​	首先，当aw通道中的fifo有数据输出时说明有突发信息等待进行转换，则开始等待w通道中的si端数据进行转换。在expander模式和packing模式下的数据时序是不一致的，也就是对s_ wready和m_valid 的控制不一致，但是都需要对si端的数据进行标记和计数，便于后续的转换。Si端索引值的标记首先涉及到突发第一拍数据的索引 值，该值和具体的awaddr和si_awsize 有关系，从aw通道中fifo读取，之后每输入一拍si端数据则累加si_awsize
的值，因为只计si端传输的有效数据，后续则根据数据对应的索引值进行mi端的数据填充进行转换。

​	在expander模式下，每输入拍si端数据都需要做一次转换， 即对mi端数据做一次赋值， 当有si端数据输入时拉高m_wvali等待mi端输出，等mi端输出后重新拉高s_wready等待si端新数据输入，本来可以对s_wready使用组合逻辑，在mi端输出数据的同拍可以拉高s_ wready,这样可以提高转换效率，但是由于后续数据转换填充时两种模式在代码上需要使用相同的逻辑类型，所以这里还是使用时序逻辑，转换效率则相对较低。

​	在packing模式下，当输入的si端数据达到mi端完整位宽(mi端的第一拍数据不一定是完整的，因为第一索引值不一定是从0开始累积)或者si端数据已结束时，则完成一次转换并输出对应的mi端数据，此过程使用时序逻辑。对于m_wlast信号则根据fifo中读取的mi转换后突发长度，对mi端输出数据进行计数，计数到相应的突发长度则拉高last信号。对于wdata和wstrb信号，则根据si端对应的索引值进行响应赋值。

​	在expander模式中，因为每次mi端转换输出只有一拍的时间，需要完成mi端所有数据位宽是赋值填充，所以
使用for循环进行赋值，复制多个电路，并行赋值。

##### ③ b_upsizer模块

​	b通道在小位宽转大位宽中可以直通，因为不涉及到突发拆分的情况，都是si端的单个突发转换为mi端的单个突发，bid 需要从aw通道中缓存id中读取后在si端输出。

##### ④ r_upsizer模块

​	axi3/axi4协议下的r通道，在upsize模式下，r通道读取ar通道中fifo中缓存的ar突发命令，返回r通道数据。Upszie 模式下si数据位宽大于mi端，所以需要对mi端返回的数据进行截取，packing 和expander的模式区别在于mi端返回数据时对应的拍数。主要逻辑顺序为ar通道中的fifo有输出数据，表明有ar信息等待读取，当mi端m rvalid 为高时，说明mi端有数据等待转换，此时可以进行转换输出，等当前拍mi端数据完成在si端的转换和输出时，拉高m ready 进行握手告知mi端当前数据已完成转换，等待下一拍mi端数据的输出。等到si端输出当前突发的最后一拍数据时， 拉高r_cmd_ready进行与ar通道中的fifo握手，告知当前突发已完成转换，并更新一次突发的对应ar信息。
​	首先是r_cmd_ready，当si端收到当前突发的最后一个r通道数据后，拉高r_cmd_ready进行握手，更新ar通道中fifo输出的新突发是ar相关信息。当r_cmd_valid为高时，表明ar通道已经存在已完成的突发信息，此时可以根据fifo的输出信息进行数据位宽转换，当m_rvalid为高时，则s_ rvalid 也为高，相当于在数据转换中将mi端数据打了一拍。

​	无论是packing模式还是expander模式都是这样，当si端输出最后一拍数据时则拉低s _valid。对si端转换后的输出数据进行计数，再与cmd_si_burst _len 比较，当计数值与r_cmd_si_burst_len 相等时则说明当前拍为突发的最后一拍，则拉高s_rlast。从m_rdata中获取s_rdata, 首先从ar通道的fifo缓存信息中读取初始的索引值，
该索引值对应的单位是si_data_bytes, 在s_rdata 中获取数据时每转换一拍m_rdata，索引值的增加值为2^si_arsize, 此处的si_arsize 也从ar 通道的fifo缓存中获取，并且mi_data_bytes≥2si arsize。

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250323205231117.png" alt="image-20250323205231117" style="zoom:50%;" />

##### ⑤ axi4lite_wr_channel_upsizer模块

​	axi4lite模式下的upsize写通道包括aw/w/b通道，axi4lite协议对应的数据位宽只有32bits或者64bits，并且突发长度只能为1，在upsize模式中，si 端数据位宽为32bits, mi端数据位宽为64bits。在aw/w/b通道间依赖关系中，只要当aw和w都已经到达mi端时，mi端才会返回bresp，并且aw和w之间没有直接依赖关系。用aw_finished 和w_ finished 分别作为aw和w通道到达mi端的标记信号，并且在mi端发出bresp时(mi_b_pushin)将该标记信号拉低，等待新一轮突发的aw和w传输。s_ awrcady 和s_ wready的逻辑是类似的，状态置1,等待初次的aw和w传输，si端输入后拉低sawready和s_wready，当aw和w到达mi端后，等mi端发出bresp时重新拉高s_awready和s_ wready等待新一轮的si端输入。当si端输入aw/w并且aw finished/w finished 信号为低(为高时说明上一次的传输在 si端还没有结束)时,拉高m_awvalid/m_wvalid, 等待mi端接收，mi端接收后拉低m_awvalid/m_wvalid。
​	Bresp由mi端传输到si端，当aw和W都已到达mi端时，拉高m_bready，表示可以接收mi端的返回的bresp, mi端输入bresp后，拉低m_bready。Mi端输入bresp后，拉高s_bvalid，si端接收bresp后，拉低s bvalid。Aw通道的数据( awaddr/awprot)从si端直传到mi端，w通道的s wdata ( 32bits=4bytes)在mi端直接整体复制填满mi端数据位宽(64bits-8bytes)，s_ wstrtb 需要根据地址进行变化，地址与mi端数据位宽( 64bits-8bytes)对齐，当地址
s_awaddr[2]为1时，则si端的s_wstrb ( 4bits)放入到mi端m。wstrtb (8bits) 的高4bits中，使得有效数据能够在mi端写入对应的地址中，因为地址和数据中的有效数据要严格对应。

##### ⑥ axi4lite_rd_channel_upsizer模块

​	axi4lite模式下的upsize读通道包括ar/t通道，axi4lite 协议对应的数据位宽只有32bits或者64bits，并且突发长度只能为1，在upsizc模式中，si 端数据位宽为32bit, mi端数据位宽为64bis。在arltr 通道间依赖关系中，只要当ar已经到达mi端时，mi端才会返回resp。用ar_finshed信号作为ar到达mi端的标记，当mi端返回resp时则拉低ar_finished。S_aready初始值为1,等待初次ar传输，当ar写入si端时拉低s_ aready, 当ar finished 为高且mi端发出resp时，重新拉高s arrcady 等待ar写入。当ar_ finished为低时表示当前的ar为到达mi端，此时ar输入到si端则拉高m arvalid等待mi端接收ar, mi 端接收到ar则拉低m_arvalid。 当mi端完成ar接收时，拉高m ready等待mi端发出resp, resp 写入到mi端则拉低m ready。Mi端输入rresp时拉高s yvalid, 等待si端接收，si 端接收resep后拉低
s _rvalid.ar通道的数据s araddr/s arprot 直传到mi端.R通道的m resp直传到si端, s_rdata则需要根据地址返回对应的数据，当s araddr[2]为 1时返回m rdata (64bits=8bytecs)中的高4bytcs数据，当s_aradr[2]为 0时返回m rdata 中的低4bytes数据。

##### ⑦ pktfifo_upsizer模块

​	在pktfifo_upsizer模块中， 使用pktfifo来控制地址命令通道( aw/ar )和数据通道( w/r)的对应的burst数量差，该burst数量差最大值由w_pktfifo_upsizer和r_ pktfifo upsizer中缓存数据的dram和fifo深度决定。完成数据位宽转换和时钟转换。

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250323104709089.png" alt="image-20250323104709089" style="zoom:50%;" />

**addr_upsizer模块:**

​	根据具体的协议和相应的控制信息进行地址变换和命令转换，并使用ID_fifo和cmd_fifo对ID信号和cmd信号进行缓存，用于控制数据和响应通道的传输。对输入的地址通道(aw/ar)信息根据位宽进行转换，转换后在mi端进行输出，输出的同时也将该转换好的地址命令信息输入到cmd_fifo进行缓存，等待w通道转换时进行读取使用。id_fifo对si端输入的id信号进行缓存，b通道在si端需要输出id信号是则读取id_fifo中的id信号进行输出。	

**w_upsizer_pktfifo模块:**

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250324161545455.png" alt="image-20250324161545455" style="zoom:60%;" />

​	此模块的核心目标是完成对aw和w通道的数据位宽转换和时钟转换。Packetfifo的数据形式相当于一个burst 在将w数据累积完整之后再一次性输出，对于单transfer的burst的数据中间不需要花时间等待。

​	aw的数据在前面已通过axi3axi4_aw_ upsizer 完成了转换，再将转换后的aw数据作为此模块的aw输入； w通道则直接输入进行处理。aw的输入数据已经完成了数据位宽转换，在此模块中只需要完成时钟转换，而w通道数据在此模块中需要同时完成数据转换和时钟转换。
​	在此模块中aw数据使用fifo 进行缓存，w通道数据使用dram进行缓存。

​	基本框架为，SI 端的w通道数据写入dram中，并在突发结束时将burst对应的已完成位宽转换的aw数据写入到fifo中，MI端根据fifo中是否有数据判断是否需要开始输出。W通道是数据位宽转换通过在dram中写入和读出的过程实现：数据位宽转换相当于在拼接SI端的输入数据，在写入dram时使用dram的byte_en功能控制写入数据到同一地址的不同字节中，相当于wstrb功能，在读出数据时读取给地址的完整数据；而时钟转换在使用s_clk 写入和_mclk读出dram数据的过程中已经完成。
​	aw通道数据的时钟转换通过fifo 的写入和读出实现。此模块中间过程主要通过SI端状态机和MI端状态机进行控制。其中SI端状态机是为了实现在burst的wdata出现wlast时同时也完成aw的数据的输入，使burst的aw和wdata同时完成缓存。MI端状态机则是将burst 对应缓存的aw和w数据读出。先将aw数据读出，再读出对应的w数据，并且MI端状态机还有多缓存一个burst的功能，当前一个burst 的aw数据已完成读取输出时，在等待该burst的w数据读取输出的过程中(可能因为m_wready原因导致w通道未完成输出或输出较慢)，也可以输出下一个burst的aw， 继续等待前一个burst的w数据完整输出。
​	对于w通道数据的缓存过程，将dram分成buf_num个大小相等的分区，每个分区用于缓存一个burst的wdata，则将每个分区的标号作为dram写地址的高位；一个burst完成位宽转换后依旧可能有多拍数据，每个分区内的单个地址缓存完成数据位宽转换后的单拍数据，数据位宽转换后的突发beat的标号作为dram写地址的低位。在读取数据的过程中同理。

​	对于dram缓存数据的过程，还需要考虑数据覆盖(写入速率大于读出速率)和重复读取(写入速率小于读出速率)的问题。

​	数据读取是由MI状态机实现，而MI状态机的启动条件是aw_fifo为非空，并且读出aw最多领先w一个burst(MI状态机可缓存一次)， 而aw数据写入的时候是对应突发的wdata完成输入时，并且当aw _fifo 读空时MI状态机会停止转动，所以MI状态机读取数据时一定是SI端数据已经完成输入，并且不会在SI端没有输入数据或数据读空时继续读取数据。

​	当dram的写入速率大于其读出速率时,aw fifo中剩余的aw数量则对应dram中写入超过读出的burst数量，则当该数量如果大于dram中burst可缓存的最大数量(dram分区)时，会出现还未读出的burst数据被新写入的burst数据覆盖掉，导致无法读出原burst数据，因
而需要对awfifo中可剩余的aw数量进行限制，该限制值设置为bufnum-2(一般情况下该限制值最大可以设置为buf num-1，但是因为MI状态机允许aw领先wdata一个burst，所以此处该限制值最大为buf num-2),则不会出现数据覆盖问题。

### 

