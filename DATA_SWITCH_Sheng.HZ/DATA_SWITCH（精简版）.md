### 一，项目介绍

​	AXI_Data_Switch用于实现AXI主从机交互时，任意数据位宽转换。AXI_Data_Switch可以分成大位宽转小位宽和小位宽转大位宽两个部分。支持axi3/axi4 和axilite协议。支持incr wrap fix三种突发类型，32-1024任意位宽转换。并且在小位宽转大位宽支持异步转换。

​	大位宽转小位宽：

​	以写过程为例：设计aw模块根据具体突发命令转换要求。对突发命令信息进行处理(地址、突发长度等)，aw通道的突发命令在突发拆分之后会有多个突发命令，因为aw通道的突发命令一般会比w通道和b通道先完成传输，所以使用fifo缓存拆分后的多个突发命令。再由w通道模块和b通道模块去读取fifo 中缓存的拆分之后的突发命令，分别完成数据位宽;/;.转换和写响应信号返回。每个模块之间均采用握手的方式传输数据。读过程类似，aw通道模块和ar通道模块复用，不同的是，数据通道返回的是多拍拼接的数据。

​	小位宽转大位宽还是以写过程为例，有主要两点不同：

​	① AW突发命令处理不同，大位宽转小位宽根据burst类型、burst_sizer和burst_length不同共十几种处理策略。小位宽转大位宽还额外支持数据填充模式和数据打包模式。数据填充模式是直接对si端的数据进行复制填满mi端的数据位宽， mi端数据拍数和si端数据拍数相等。Packing 模式则是需要累积多拍si端数据之后再由mi端一拍输出。

​	② 小位宽转大位宽还支持异步时钟数据位宽处理。因此结构也有所不同，使用异步FIFO完成AW通道数据处理和时钟转换。使用伪双口RAM实现W通道位宽转换和时钟转换。大位宽转小位宽不会出现没有输入数据或数据读空时继续读取数据，因此可以采用组合逻辑，大位宽转小位宽需要采用状态机去解决；大位宽转小位宽采用反压的方式避免数据覆盖，小位宽转大位宽采用设置水位的方式。

​	AXI_Data_Switch IP包含一个时钟域或者两个时钟域，涉及主机端时钟s_aclk和从机端时m_aclk。当主机端数据位宽大于从机端位宽时，即大位宽转小位宽模式下，要求主机端时钟和从机端时钟为同一时钟；当主机端数据位宽小于从机端位宽时，即小位宽转大位宽模式下，允许主机端时钟和从机端时钟不同，内部可进行时钟转换。根据不同brust突发方式（FIX、INCR和WRAP）和位宽倍率，制定不同拆分策略，完成数据位宽转换，并对非对齐传输进行管理，支持AXI3/4和AXI4lite协议；SI/MI数据位宽：32/64/128/256/512/1024

### 二，项目架构

#### 1. 大位宽转小位宽转化规则                                                        	

> INCR：

1. 如果窄传输的实际数据转为小位宽后依旧小于AXI的数据位宽，直接传输，不做任何改变。

2. MI beats <= 256 （MI beats <= 16）

3. MI beats > 256  （MI beats > 16 ）


> WRAP: WRAP的最大突发长度是16

1. 如果窄传输的实际数据转为小位宽后依旧小于AXI的数据位宽，直接传输，不做任何改变。

2. MI beats <= 16               

3. 16 < MI beats <= 256,  ADDR is burst-aligned

   将其拆分为一个INCR 类型的传输

4. 16 < MI beats <= 256,  ADDR is not  burst-aligned (wrapping  required)

   将其拆分长两个INCR类型传输

5. MI beats > 256 （MI beats > 16）

   对齐：      将其拆分长两个INCR类型传输

   非对齐：  拆分为两个或者三个INCR传输

> FIX:

1. 如果是窄传输，实际数据转为小位宽后依旧小于AXI的数据位宽，直接传输，不做任何改变。

2. 1 < downsize_ratio <= 16  （AXI3）或者 downsize_ratio > 1 (AXI4)

   变成INCR，增加LEN

3. downsize_ratio > 16

   变成多个变成INCR，增加LEN

> ==AXI4lite单独处理==

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250320140644791.png" alt="image-20250320140644791" style="zoom:80%;" />

​	分段传输：将大位宽数据按小位宽分段；地址生成：每次传输后地址递增M/8字节。

**注意：**

- [ ] 大位宽转小位宽时，包括事务拆分，不受 AW/ARCACHE 信号值的限制。因为没有其他替代方法可以完成事务，downsizer导致的事务拆分不能被 CACHE 限制。
- [ ] Data Width Converter 不支持直接从 1024 位缩小到 32 位。

#### 2. 小位宽转大位宽转化规则

如果是拓展模式，所有的均不改变。

以下规则基于打包模式：

> INCR：数据进行拼接

> WRAP: 非对齐会拆分成两个INCR模式。

> FIX：所有的不改变，直接传输。



### 三，项目细节

#### 1. 大位宽转小位宽

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250407234551054.png" alt="image-20250407234551054" style="zoom:50%;" />

##### ① addr_downsizer模块

**主要逻辑:**
	addr_downsize 主要负责突发命令信息的处理过程，经过大位宽转小位宽之后，单beat信号会拆分为多beat 信号，相应的突发长度也会增加，当突发长度大于最大突发长度时需要进行突发拆分，具体的拆分策略需要根据具体的突发类型和地址情况决定。

​	在突发拆分之后的命令信息处理中，最核心的时axaddr、axlen和axburst，axid 需要特殊处理，其他( axregion, axcache, axprot,axlock, axqos)信号在突发拆分时不涉及到改变，可以直传。

​	addr和axlen在突发拆分时需要根据具体的拆分策略进行计算，代码中主要通过组合逻辑进行运算。

​	axid 的特殊处理主要因为数据位宽转换模块只允许单个id突发处理，不支持多id突发处理，si端的id信号输入后存储到位宽转换模块中，后续的id信号与位宽转换模块内已存储的id进行对比，当id检测到一样则完成转换和传输，否则中断传输。

​	addr通道的突发命令在突发拆分之后会有多个突发命令，并且addr通道的突发命令一般会比w通道和b通道先完成传输，使用ffo缓存拆分后的多个突发命令，再由w通道和b通道去读取fifo 中缓存的拆分之后的突发命令。在addr通道的从机端看到结果相当于原来si端的单个突发命令转换成了多个突发命令，所以w通道和b通道的突发命令缓存fifo由addr通道控制，并且fifo的输入由addr通道的mi端输出握手信号控制。

**具体控制逻辑:**
	在addr通道的si端输一个突发命令时，设置标识信号（si_push_ in） 表示已输入了一个突发的命令信息，然后拉低s_axready 不再接受si端的突发，需要等待mi端完成当前突发的完整输出之后再拉高s_axready，重新等待si端握手输入新的突发。

​	此时需要根据具体的突发信息进行判断是否需要拆分，如果需要拆分则需要使用组合逻辑在当前拍完成拆分之后第一个拆分突发的命令信息，然后拉高m_axvalid等待mi端握手输出，同时在mi端握手输出时进行计数完成当前该si端突发命令在mi端的拆分突发的完整输出。在mi端握手输出突发信息时，同时控制w_cmd_ fifo 和b_ cmd_fifo的突发信息写入fifo。

​	但是fifo深度是有限的，并且当大位宽转小位宽的比例较大时，突发信息拆分后的数量增多，w通道和b通道读取fifo的速率小于拆分信息写入fifo的速率，需要对写入速率进行反压，避免fifo溢出。具体反压过程为当检测到fifo为满时，则将addr端的m_axvalid 拉低，等待W通道和b通道读取fifo中数据，读取后检测到fifo不为满时则重新拉高m_axvalid，等待握手输出和fifo写入。

② w_downsizer模块
	在w通道中只需要根据从w_ cmd_fifo中读取的突发命令信息完成响应的数据位宽转换。在大位宽转小位宽时，主要是对数据进行截取，因而需要对输入数据分拍完整输出之后才能允许新数据输入，避免输入数据覆盖。

​	Fifo为预取fifo, 首先需要在w_cmd_fifo输出w_ cmd_valid拉高，表示fifo中已有等待转换的突发命令，然后等待si 端s_walid 拉高，完成si端数据握手输入。根据截取信息依次截取si端当前输入数据得到mi端小位宽数据，并在mi端拉高m_wvalid 等待握手输出，计数器记录小位宽数据完整输出时，同时拉高si端的s_wready 完成下一次转换数据的握手输入，使得si端数据的握手输入和mi端的最后一个转换数据握手输出同时完成(避免等待)，然后再拉高w_cmd_ready 使得fifo当前数据输出，更新fifo输出的新突发命令信息，准备开始下一次转换过程。

##### ③ b_downsizer模块

主要逻辑:
	在b通道，bresp 信号方向为在mi端握手输入，在si端握手输出。

​	b_fifo中缓存了突发拆分的数量，当fifo的b_fifo_ valid 拉高时，则表明fifo中有等待转换的突发命令，b通道中的mi端的m_ready开始则拉高，等待接收从机返回的bresp。mi端握手输入bresp时进行计数，当计数到fifo 输出的需返回的bresp数量时，表示为拆分突发中的最后一个bresp，返回最后一个bresp。即当突发对应的最后一个bresp输入时，拉高fifo的b_ cmd_ready, 更新fifo输出的下个突发对应的拆分之后所需返回的bresp数量。并同时拉高si端的s_valid等待握手输出，等si端的svalid完成握手输出时,重新拉高m_bready，等待新的bresp输入。

##### ④ r_downsizer模块

主要逻辑:
	在r通道，rresp 与rdata同时由mi端返回到si端。mi端返回的多beat数据组成si端的单beat数据，拼接完成后, 输出当前完成转换的端数据（同时拉高r_cmd_ready, 更新r_cmd_fifo输出的突发信息），完成握手输出后，再继续拉高m_ready 等待mi端的新数据输入（和拉高r_cmd_ready, 更新r_cmd_fifo输出的突发信息）。

​	当mi端的最后一个拆分突发的最后beat输入时，拉高s_rlast，等待转换好的si端数据握手输出，输出后拉低s_rlast。 由于rresp是和rdata 同时返回，所以mi端每一拍rdata都有对应的rresp，和b通道类似，s_rresp 选取m_rresp中最差的响应进行返回和输出，在代码中即对应的值最大则作为s_rresp 输出。id 信号直接返回r_cmd_fifo输出的id。

##### ⑤ axi4lite_wr_channel_downsizer模块

主要逻辑:
	在axi4lite模式下的downszie，主机端发出的大数据位宽只能是64bits，从机端接收端的小数据位宽只能是32bits，并且突发的长度只能为1，因而在需要拆分的情况下最多只能有两个拆分突发。

##### ⑥ axi4lite_rd_channel_downsizer模块

主要逻辑:
	在拆分情况下，需要在第一个拆分突发握手输出后，需要等待mi端接收到rresp反馈之后，才能再次拉高m_arvalid，等待第二次ar握手输出，然后握手后再次将m_arvalid 拉低，并且在ar完成最后一个拆分突发握手输出后拉高s_arready，告知si端此次ar转换已完成，在si端完成握手输出rresp后拉低s_rvalid, 等待下一次转换输出。

#### 2. 小位宽转大位宽模块（同步情况）

​									**同步情况**

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250322205638946.png" alt="image-20250322205638946" style="zoom:70%;" />

##### ① addr_upsizer模块

​	upsize模式下对于地址通道信息的改变相对较少，突发长度只可能保持不变(长度为1时)或者变小，不存在突发拆分的情况，地址通道信息最多只需要变换一次。使用fifo对地址通道转换信息进行缓存，在mi端每输出一次数据则同时将该信息写入到fifo中，等待被w通道读取并进行对应的数据转换，使用fifo的非满信号进行反压，避免fifo中挤出有效数据。
​	小位宽转大位宽的具体转换方式主要分为两种，一种为expander 模式，一种为packing模式。其中expander模式是直接对si端的数据进行复制填满mi端的数据位宽，wstrb则只有原si端数据对应的wstrb进行复制，其余位宽的wstrb 保持为0, mi端数据拍数和si端数据拍数相等。Packing 模式则是需要累积多拍si端数据之后再由mi端一拍输出，wstrb则与各拍的si端数据对应，理想对齐情况下mi端的数据拍数减小mi_data_width/si_data_width倍。两种模式从地址和数据的关系来看是效果一致的， 区别在于使用不同的拍数将si端的数据写入到mi端的对应地址。
​	对于id信号的处理：当si端有id信号输入时，aw通道对输入的awid信号进行缓存，在mi端不输出id信号，在b通道的mi端输出bresp时同时将缓存的id信号输出。

##### ② w_upsizer模块

​	W通道中根据aw通道中fifo缓存的转换信息对数据进行小位宽转大位宽，主要的转换信息包括具体转换模式，第一拍数据的索引信息，si_axsize 和转换位宽后的突发长度。根据si_axsize可以确定si端每拍传输的有效数据位宽，考虑到narrow transfer的情况，可能需要多拍si数据才能积累到si_data_width 位宽的有效数据，所以在整个转换过程是以si_axsize对应的位宽作为转换的最小单位的。
​	在expander模式和packing模式下的数据时序是不一致的，也就是对s_ wready和m_valid 的控制不一致，但是都需要对si端的数据进行标记和计数，便于后续的转换。

​	在expander模式下，每输入拍si端数据都需要做一次转换， 即对mi端数据做一次赋值， 当有si端数据输入时拉高m_wvali等待mi端输出，等mi端输出后重新拉高s_wready等待si端新数据输入，对s_wready使用组合逻辑，在mi端输出数据的同拍可以拉高s_ wready,这样可以提高转换效率。

​	在expander模式中，因为每次mi端转换输出只有一拍的时间，需要完成mi端所有数据位宽是赋值填充，所以使用for循环进行赋值，复制多个电路，并行赋值。

​	在packing模式下，当输入的si端数据达到mi端完整位宽(mi端的第一拍数据不一定是完整的，因为第一索引值不一定是从0开始累积)或者si端数据已结束时，则完成一次转换并输出对应的mi端数据，此过程使用时序逻辑。对于m_wlast信号则根据fifo中读取的mi转换后突发长度，对mi端输出数据进行计数，计数到相应的突发长度则拉高last信号。对于wdata和wstrb信号，则根据si端对应的索引值进行响应赋值。

##### ③ b_upsizer模块

​	b通道在小位宽转大位宽中可以直通，因为不涉及到突发拆分的情况，都是si端的单个突发转换为mi端的单个突发。

##### ④ r_upsizer模块

​	axi3/axi4协议下的r通道，在upsize模式下，r通道读取ar通道中fifo中缓存的ar突发命令，返回r通道数据。Upszie 模式下si数据位宽大于mi端。

​	当si端输出最后一拍数据时则拉低s _valid。对si端转换后的输出数据进行计数，再与cmd_si_burst _len 比较，当计数值与r_cmd_si_burst_len 相等时则说明当前拍为突发的最后一拍，则拉高s_rlast。从m_rdata中获取s_rdata, 首先从ar通道的fifo缓存信息中读取初始的索引值，该索引值对应的单位是si_data_bytes, 在s_rdata 中获取数据时每转换一拍m_rdata，索引值的增加值为2^si_arsize, 此处的si_arsize 也从ar 通道的fifo缓存中获取。

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250323205231117.png" alt="image-20250323205231117" style="zoom:50%;" />

##### ⑤ axi4lite_wr_channel_upsizer模块

​	axi4lite模式下的upsize写通道包括aw/w/b通道，axi4lite协议对应的数据位宽只有32bits或者64bits，并且突发长度只能为1，在upsize模式中，si 端数据位宽为32bits, mi端数据位宽为64bits。在aw/w/b通道间依赖关系中，只要当aw和w都已经到达mi端时，mi端才会返回bresp。用aw_finished 和w_ finished 分别作为aw和w通道到达mi端的标记信号，并且在mi端发出bresp时(mi_b_pushin)将该标记信号拉低，等待新一轮突发的aw和w传输。

​	s_ awready 和s_ wready的逻辑是类似的，状态置1,等待初次的aw和w传输，si端输入后拉低sawready和s_wready，当aw和w到达mi端后，等mi端发出bresp时重新拉高s_awready和s_ wready等待新一轮的si端输入。当si端输入aw/w并且aw finished/w finished 信号为低(为高时说明上一次的传输在 si端还没有结束)时,拉高m_awvalid/m_wvalid, 等待mi端接收，mi端接收后拉低m_awvalid/m_wvalid。
​	Bresp由mi端传输到si端，当aw和W都已到达mi端时，拉高m_bready，表示可以接收mi端的返回的bresp, mi端输入bresp后，拉低m_bready。Mi端输入bresp后，拉高s_bvalid，si端接收bresp后，拉低s bvalid。

​	Aw通道的数据( awaddr/awprot)从si端直传到mi端，w通道的s_wdata ( 32bits=4bytes)在mi端直接整体复制填满mi端数据位宽(64bits-8bytes)，s_ wstrtb 需要根据地址进行变化，地址与mi端数据位宽( 64bits-8bytes)对齐，当地址s_awaddr[2]为1时，则si端的s_wstrb ( 4bits)放入到mi端m。wstrtb (8bits) 的高4bits中，使得有效数据能够在mi端写入对应的地址中，因为地址和数据中的有效数据要严格对应。

##### ⑥ axi4lite_rd_channel_upsizer模块

​	axi4lite模式下的upsize读通道包括ar/t通道，axi4lite 协议对应的数据位宽只有32bits或者64bits，并且突发长度只能为1，在upsizc模式中，si 端数据位宽为32bit, mi端数据位宽为64bis。

#### 3. pktfifo_upsizer模块

​	在pktfifo_upsizer模块中， 使用pktfifo来控制地址命令通道( aw/ar )和数据通道( w/r)的对应的burst数量差，该burst数量差最大值由w_pktfifo_upsizer和r_ pktfifo upsizer中缓存数据的dram和fifo深度决定。完成数据位宽转换和时钟转换。

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250407234635568.png" alt="image-20250407234635568" style="zoom:50%;" />

##### **①addr_upsizer模块:**

​	根据具体的协议和相应的控制信息进行地址变换和命令转换，并使用ID_fifo和cmd_fifo对ID信号和cmd信号进行缓存，用于控制数据和响应通道的传输。对输入的地址通道(aw/ar)信息根据位宽进行转换，输入到cmd_fifo进行缓存，等待w通道转换时进行读取使用。id_fifo对si端输入的id信号进行缓存，b通道在si端需要输出id信号是则读取id_fifo中的id信号进行输出。	

##### **②w_upsizer_pktfifo模块:**

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250407234649033.png" alt="image-20250407234649033" style="zoom:70%;" />

​	此模块的核心目标是完成对aw和w通道的数据位宽转换和时钟转换。Packetfifo的数据形式相当于一个burst 在将w数据累积完整之后再一次性输出。

​	aw通道信息在上个模块中已经完成了位宽转换，在此模块中只需要完成时钟转换，而w通道数据在此模块中需要同时完成数据转换和时钟转换。在此模块中aw数据使用异步fifo 进行缓存，w通道数据使用伪双口dram进行缓存。

​	SI 端的w通道数据根据原始aw通道信息写入dram中，并在突发结束时将对应的已完成位宽转换的aw数据写入到fifo中，MI端根据fifo中是否有数据判断是否需要开始输出。

​	W通道是数据位宽转换通过在dram中写入和读出的过程实现：数据位宽转换相当于在拼接SI端的输入数据，在写入dram时使用dram的byte_en功能控制写入数据到同一地址的不同字节中，相当于wstrb功能，在读出数据时读取给地址的完整数据；而时钟转换在使用s_clk 写入和_mclk读出dram数据的过程中已经完成。
​	aw通道数据的时钟转换通过fifo 的写入和读出实现。

​	此模块中间过程主要通过SI端状态机和MI端状态机进行控制。其中SI端状态机是为了实现在burst的wdata出现wlast时同时也完成aw的数据的输入，使burst的aw和wdata同时完成缓存。MI端状态机则是将burst 对应缓存的aw和w数据读出。先将aw数据读出，再读出对应的w数据，并且MI端状态机还有多缓存一个burst的功能，当前一个burst 的aw数据已完成读取输出时，在等待该burst的w数据读取输出的过程中(可能因为m_wready原因导致w通道未完成输出或输出较慢)，也可以输出下一个burst的aw， 继续等待前一个burst的w数据完整输出。
​	对于w通道数据的缓存过程，将dram分成buf_num个大小相等的分区，每个分区用于缓存一个burst的wdata，则将每个分区的标号作为dram写地址的高位；一个burst完成位宽转换后依旧可能有多拍数据，每个分区内的单个地址缓存完成数据位宽转换后的单拍数据，数据位宽转换后的突发beat的标号作为dram写地址的低位。在读取数据的过程中同理。

​	对于dram缓存数据的过程，还需要考虑数据覆盖(写入速率大于读出速率)和重复读取(写入速率小于读出速率)的问题。

​	数据读取是由MI状态机实现，而MI状态机的启动条件是aw_fifo为非空，并且读出aw最多领先w一个burst(MI状态机可缓存一次)， 而aw数据写入的时候是对应突发的wdata完成输入时，并且当aw _fifo 读空时MI状态机会停止转动，所以MI状态机读取数据时一定是SI端数据已经完成输入，并且不会在SI端没有输入数据或数据读空时继续读取数据。

​	当dram的写入速率大于其读出速率时,aw_fifo中剩余的aw数量则对应dram中写入超过读出的burst数量，则当该数量如果大于dram中burst可缓存的最大数量(dram分区)时，会出现还未读出的burst数据被新写入的burst数据覆盖掉，导致无法读出原burst数据，因而需要对awfifo中可剩余的aw数量进行限制，该限制值设置为bufnum-2(一般情况下该限制值最大可以设置为buf_num-1，但是因为MI状态机允许aw领先wdata一个burst，所以此处该限制值最大为buf num-2),则不会出现数据覆盖问题。

##### **③b_upsizer_pktfifo模块**

​	使用fifo完成异步时钟下的写响应跨时钟转换。

##### **④r_upsizer_pktfifo模块**

<img src="C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250325161714610.png" alt="image-20250325161714610" style="zoom:67%;" />



