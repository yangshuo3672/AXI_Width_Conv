
Transaction（事务） 是 UVM 验证平台的核心数据结构，用于封装 DUT 的输入激励 和 输出响应。它派生自 uvm_sequence_item，并通过随机化（randomization）生成多样化的测试场景。

 1.Transaction 的作用
（1）封装协议数据（如以太网帧、AXI 事务、寄存器读写等）。
（2）支持随机化（通过 rand 修饰变量，生成随机测试数据）。
（3）提供数据对比（用于 Scoreboard 检查 DUT 输出是否符合预期）。
（4）支持序列化/反序列化（用于跨组件传递数据）。

2. Transaction 的基本结构
(1) 定义 Transaction 类
Transaction 必须派生自 uvm_sequence_item，并通过 uvm_object_utils 注册到工厂：

class my_transaction extends uvm_sequence_item;
    // 定义协议字段（可随机化）
    rand bit [47:0] src_mac;  // 源 MAC 地址
    rand bit [47:0] dst_mac;  // 目的 MAC 地址
    rand bit [15:0] eth_type; // 以太网类型
    rand byte      payload[]; // 动态数组存储负载
    rand bit [31:0] crc;      // CRC 校验码

    // 注册到工厂并启用 Field Automation
    `uvm_object_utils_begin(my_transaction)
        `uvm_field_int(src_mac, UVM_ALL_ON)      // 注册字段
        `uvm_field_int(dst_mac, UVM_ALL_ON)
        `uvm_field_int(eth_type, UVM_ALL_ON)
        `uvm_field_array_int(payload, UVM_ALL_ON)
        `uvm_field_int(crc, UVM_ALL_ON)
    `uvm_object_utils_end

    // 构造函数
    function new(string name = "my_transaction");
        super.new(name);
    endfunction

    // 自定义约束（限制随机化范围）
    constraint valid_payload {
        payload.size() inside {[64:1500]};  // 以太网帧负载长度限制
    }

    // 计算 CRC（后处理）
    function void post_randomize();
        crc = calc_crc();  // 自定义 CRC 计算函数
    endfunction
endclass
UVM Transaction 详解
Transaction（事务） 是 UVM 验证平台的核心数据结构，用于封装 DUT 的输入激励 和 输出响应。它派生自 uvm_sequence_item，并通过随机化（randomization）生成多样化的测试场景。
1. Transaction 的作用
封装协议数据（如以太网帧、AXI 事务、寄存器读写等）。
支持随机化（通过 rand 修饰变量，生成随机测试数据）。
提供数据对比（用于 Scoreboard 检查 DUT 输出是否符合预期）。
支持序列化/反序列化（用于跨组件传递数据）。
2. Transaction 的基本结构
(1) 定义 Transaction 类
Transaction 必须派生自 uvm_sequence_item，并通过 uvm_object_utils 注册到工厂：
class my_transaction extends uvm_sequence_item;
    // 定义协议字段（可随机化）
    rand bit [47:0] src_mac;  // 源 MAC 地址
    rand bit [47:0] dst_mac;  // 目的 MAC 地址
    rand bit [15:0] eth_type; // 以太网类型
    rand byte      payload[]; // 动态数组存储负载
    rand bit [31:0] crc;      // CRC 校验码

    // 注册到工厂并启用 Field Automation
    `uvm_object_utils_begin(my_transaction)
        `uvm_field_int(src_mac, UVM_ALL_ON)      // 注册字段
        `uvm_field_int(dst_mac, UVM_ALL_ON)
        `uvm_field_int(eth_type, UVM_ALL_ON)
        `uvm_field_array_int(payload, UVM_ALL_ON)
        `uvm_field_int(crc, UVM_ALL_ON)
    `uvm_object_utils_end

    // 构造函数
    function new(string name = "my_transaction");
        super.new(name);
    endfunction

    // 自定义约束（限制随机化范围）
    constraint valid_payload {
        payload.size() inside {[64:1500]};  // 以太网帧负载长度限制
    }

    // 计算 CRC（后处理）
    function void post_randomize();
        crc = calc_crc();  // 自定义 CRC 计算函数
    endfunction
endclass

(2) Field Automation 机制

UVM提供的uvm_field_*宏，自动实现一下功能
uvm_field_int ：注册整数类型字段  uvm_field_int(src_mac, UVM_ALL_ON)
uvm_field_array_int ：注册动态数组类型字段  uvm_field_array_int(payload, UVM_ALL_ON)
uvm_field_enum ： 注册枚举类型字段  uvm_field_enum(packet_type, UVM_ALL_ON)

标志位（UVM_ALL_ON 包含以下所有功能）：
UVM_PRINT：支持 print() 打印字段。
UVM_COMPARE：支持 compare() 比较字段。
UVM_COPY：支持 copy() 复制字段。
UVM_RECORD：支持波形记录（如 $dumpvars）。

3. Transaction 的随机化
(1) 随机化字段
通过 rand 修饰变量，并使用 randomize() 生成随机数据：

my_transaction tr;
tr = new("tr");
assert(tr.randomize());  // 随机化所有 rand 变量

(2) 添加约束
在 Transaction 类中定义 constraint，限制随机化范围：

constraint valid_mac {
    src_mac != 48'h0;      // 源 MAC 不能为全 0
    dst_mac != 48'hFFFF;   // 目的 MAC 不能为全 1
}

(3) 后处理（post_randomize）
在随机化完成后自动调用，用于计算校验值、调整字段等：

function void post_randomize();
    crc = calc_crc(src_mac, dst_mac, payload);  // 计算 CRC
endfunction

4. Transaction 的常用操作
(1) 打印 Transaction
tr.print();  // 使用 UVM 默认格式打印

(2) 比较 Transaction
my_transaction tr1, tr2;
if (!tr1.compare(tr2)) begin
    `uvm_error("COMPARE", "Transactions mismatch!")
end

(3) 复制 Transaction
my_transaction tr_copy;
tr_copy = tr1.copy();  // 深拷贝

(4) 序列化（Pack/Unpack）
byte byte_stream[];
tr.pack(byte_stream);  // 序列化
tr.unpack(byte_stream); // 反序列化

5. Transaction 在验证平台中的流动
（1）Sequence 生成 Transaction：

class my_sequence extends uvm_sequence;
    task body();
        my_transaction tr;
        `uvm_do(tr)  // 自动随机化并发送给 Sequencer
    endtask
endclass

（2）Driver 接收并驱动到 DUT：

task my_driver::run_phase(uvm_phase phase);
    forever begin
        seq_item_port.get_next_item(req);  // 从 Sequencer 获取 Transaction
        drive_to_dut(req);                // 驱动到 DUT 接口
        seq_item_port.item_done();
    end
endtask

（3）Monitor 捕获 DUT 输出并生成 Transaction：

task my_monitor::run_phase(uvm_phase phase);
    forever begin
        my_transaction tr;
        // 从 DUT 接口捕获信号并填充 tr
        ap.write(tr);  // 发送给 Scoreboard
    end
endtask



