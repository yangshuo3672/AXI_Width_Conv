1. Sequence / Sequencer / Driver 的三方关系与职责划分
| 组件 | 本质 | 职责 |
|------|------|------|
| **Sequence** | `uvm_object`（有生命周期） | **只负责生成激励数据**（transaction 的内容和随机化），不控制时序 |
| **Sequencer** | `uvm_component` | 作为 Sequence 和 Driver 之间的**仲裁器和路由节点**，管理多个 sequence 的并发请求 |
| **Driver** | `uvm_component` | **只负责驱动时序**，将 transaction 转换为 pin 级信号，下发到 DUT |
