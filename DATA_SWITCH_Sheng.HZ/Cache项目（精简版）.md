## 一，项目背景

​	设计一款三级data cache。client与cache、cache内部之间采用四个独立通道（请求通道、写数据通道、写响应通、读响应通道）；每个通道之间采用握手的方式交互，支持突发传输；支持乱序执行和乱序响应；client到L1的数据位宽为512，L1_L2数据位宽256，L2_L3数据位宽128，L3_MEM数据位宽为32;cache line为512。

## 二，项目介绍：

#### 1. instruction buffer	

​	L1 cache前加入了instruction buffer。将突发的请求拆分，并做对齐处理，将每beat数据对应一个cache_line，然后每条指令进行同地址读写冲突处理，分情况将数据转发、指令合并、指令依赖，依赖是指只有当前面的指令完成，此指令才可以进行发射；完成依赖处理后进入load store queue，load store queue采用环形队列，head tail维护顺序发射指令，实现队列的保序管理，每条指令发射后并不会清除，直至指令完成后标记标记提交，然后解除依赖。指令提交时，从head到tail进行遍历，分别找到两个load/store完成指令，进行提交。

​	提交的时候设置flag位，需要等待拆分的多条指令全部完成才可以进行提交；

#### 2. L1cache

​	L1 Cache负责接收instruction buffer的请求和数据，并发出对应响应；及向l2发送请求和数据，并接受对应的响应。L1 Cache中包含MSHR、Cache Array、Tag Array、victim write buffer等模块。

​	L1cache整体采用非阻塞（non-blocking）的设计，当L1接收请求时，同时与write back buffer和Cache Array进行逐个比较，如果命中进行读写响应，如果没有命中，将读写请求保存在MSHR中，然后向l2发送读请求，当收到L2cache的读响应时，将读响应的数据返回至MSHR中，再向instruction buffer发送读写响应。MSHR中的数据在cache端口空闲时写入Cache Array后。

​	当cache array满的时，采用伪最近最少使用替换策略，剔除一条cache_line。如果该cache_line的数据是dirty，则放入write back buffer，当写请求端口空闲时，将Dirty的数据写入L2cache，Dirty的Cache line逐级向下传递，保证数据的一正确性。并且write back buffer支持命中，命中后的数据放入MSHR等待时机重新写回cache array；

​	L2/L3的架构和L1基本相同。 



#### 3. 验证

​	验证采用成员之间交叉验证，根据DE文档编写DV文档和vlpan，整体采用灰盒验证，收集功能覆盖率和代码覆盖率，将关键信号采用 断言引出，验证内部模块是否正常允许。先验证L1、L2、L3，搭建的平台是可复用的，几乎一致。

## 三，项目细节：

   



![](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20250719114459402.png)

instruction buffer：

具备以下功能：

1. Split模块的主要功能是：处理来自client的请求，在本周期完成指令的拆分，如果请求是Burst = 1；每次突发的数据对应一条指令，则将load/store指令拆分成两条相邻的指令，每条指令操作一个cache line，但保留last信号区分数据和指令的关系。为防止数据溢出，存储FIFO设置水位（MAX-1），数据未达到水位的时候，持续拉高会拉高cli_l1_req_rdy，持续接收数据，达到水位后不允许接收数据；

2. Depend模块的主要功能是对Split的指令进行依赖处理，并存入load store queue，处理方案如表；

   ![00c8a158d941013313fbc1ceda8071d](D:\wechatdocument\WeChat Files\wxid_5zx0twp0x60x22\FileStorage\Temp\00c8a158d941013313fbc1ceda8071d.jpg)

3. LSQ模块是一个环形缓冲区（FIFO），由head和tail指针管理。head指向最早待处理的事务，而tail指向最新入队的事务。通过这两个指针，可以确定队列的满/空状态，并控制事务的入队和出队操作，实现队列的保序管理，确保事务按提交顺序处理；核心功能可以分为指令接收、指令发射、数据接收、响应接收、内部更新；

​	a. 指令接收，接收depend模块的指令，并预留数据位；

​	b. 指令发射：自head向tail查询state == 01（待发射指令），进行顺序发送；为方便后续模块处理，采用req通道和wdata通道同时均握手完成，再将数据和指令同时发送；

​	c. 数据接收，数据接收分为client数据和l1数据接收：

​		ⅰ. client数据：client数据和指令是分离突发的，并没有响应的ID，根据store顺序进行填充；

​		ⅱ. l1数据：由于架构设计，接收l1数据响应不会有拥堵的情况，接收l1数据后标记可提交，并查询依赖，根据具体的依赖情况，进行解除依赖和数据转发；

​	d. 响应接收：接收l1的写响应后标记可提交，并检查依赖情况，解除依赖；

​	e. 内部更新，head指针始终指向未发射的第一条指令，当该指令完成时，向下查询两条指令进行清除，更新	    head指针；

4. Commited模块的主要功能是查询LSQ中已完成的指令，提交至client，wresp和rresp并行查询，如果是burst = 0的指令，该指令处于等待提交阶段即可提交，如果burst =1的指令，需要等待两条拆分均完成，才可以进行提交；完成指令提交后，将valid置1，标志该指令可以清除；

**L1cache、L2cache和L3cache大致类似，仅仅容量不同：**

​	L1 Cache负责接收l2的请求和数据，并发出对应响应；及向l2发送请求和数据，并接受对应的响应。L1 Cache中包含MSHR、Cache Array、Tag Array、victim write buffer等模块。

MSHR：由于我们采用非阻塞（non-blocking）的设计，当Cache miss时需要用MSHR记录miss的请求，包括请求地址、请求类型、请求id、请求数据、数据掩码和收集/发送标志位和MSHR整体的有效位。同时，由于本次Cache系统设计需要支持burst传输，当数据没有接收完成时，即使Cache hit也会将对应的指令保存在MSHR中，等数据完成后再写入Cache。本级的MSHR深度为上一级 MSHR深度加上一级 write back buffer深度，从而保证了上一级发送给本级的每条指令都有足够的空间存储，因此不会堵塞。

Cache Array：我们的Cache采用多路组相连，每一路对应一个bank，每个bank例化一块SRAM，由于使用了多个bank，因此在同一个周期中如果需要对SRAM进行多次读写，可以强制写入在未被使用的bank中进行，从而提高效率。我们使用寄存器搭建了一个SRAM模块，其模仿了单端口SRAM的读写行为，每周期只能进行一次读或写。

Tag Array：Tag Array中主要保存了Cache Array中对应地址Cache line的状态，包括是否valid和dirty，以及对应的Tag。

Victim Write Buffer：当Cache Array中dirty的Cache line被替换时，其需要写入下一级cache，因此我们将其数据和地址先保存在VWB中，并逐个向下写入。同时，当接收上一级的请求时，我们会将地址与VWB中的entry进行比较，如果命中则将该entry放到MSHR中并向上响应，响应完成后重新写入本级Cache，从而让VWB具有了victim cache的功能。

ID buffer：为了实现读响应和写数据的burst，设计了一个rresp_id buffer和wdata_id buffer，如果本周期发送了对应请求前半段的数据，则将对应的flag拉高并将此时的mshr_id保存在ID buffer中，下个时钟沿到来时优先检查是否存在需要发送的后半段数据，如果有则优先发送，如果没有则正常轮询MSHR和write back buffer。

替换策略：我们采用伪最少使用策略，由于该cache采用多路组相连缓存，通过树状结构优化传统PLRU的硬件复杂度和性能。Tree-PLRU 将缓存行的访问信息组织成二叉树结构，每个节点表示两个缓存行之间的优先级关系。当缓存行被访问时，从叶子节点向上更新树的路径，标记该行的使用状态。树的更新规则确保每次访问后，被访问行的优先级提升，未被访问行的优先级降低。当需要替换时，直接从树的根节点获取当前伪 LRU 行（最可能被淘汰的行）。

包含策略：当从数据从mem向上传递时，逐级写入Cache Array；当发生Cache替换时，不考虑其是否包含在上级Cache中。Dirty的Cache line逐级向下传递，从下级读取的cache line标记为clean。





