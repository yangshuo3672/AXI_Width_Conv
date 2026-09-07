1. 将一个队列的数据倒叙放入另一个空队列
（1）内置方法reverse()：使用内建函数，高级。
    task automatic reverse_builtin();
        int q_src[$] = '{1, 2, 3, 4, 5};
        int q_dst[$];
        q_dst = q_src;      // 先拷贝
        q_dst.reverse();    // 原地反转
        $display("[Builtin] q_dst = %p", q_dst);
    endtask
（2）for循环遍历，使用内建函数size获取队列大小：for循环倒序，逻辑明确，且不改变原队列内容
    task automatic reverse_for_loop();
        int q_src[$] = '{1, 2, 3, 4, 5};
        int q_dst[$];
        for (int i = q_src.size() - 1; i >= 0; i--) begin
            q_dst.push_back(q_src[i]);
        end
        $display("[ForLoop] q_dst = %p", q_dst);
    endtask
（3）使用foreach+push_front 前推。但是性能开销巨大：push_front每次插入头部，后续元素都要后移，
    task automatic reverse_push_front();
        int q_src[$] = '{1, 2, 3, 4, 5};
        int q_dst[$];
        // foreach 正序遍历，但每次插到头部，自然形成倒序
        foreach (q_src[i]) begin
            q_dst.push_front(q_src[i]);
        end
        $display("[PushFront] q_dst = %p", q_dst);
    endtask
（4）pop_back —— 会清空原队列，需提前备份
    task automatic reverse_pop_back();
        int q_src[$] = '{1, 2, 3, 4, 5};
        int q_dst[$];
        int q_tmp[$] = q_src;  // 必须备份，否则原数据丢失
      
        while (q_tmp.size() > 0) begin
            q_dst.push_back(q_tmp.pop_back());
        end
        $display("[PopBack] q_dst = %p, q_src preserved = %p", q_dst, q_src);
    endtask
（5）const ref + ref —— 工程化最佳实践，性能最优
    task automatic reverse_ref(
        const ref int src_q[$],  // const ref: 保证不修改源队列
        ref int       dst_q[$]   // ref: 直接操作外部目标队列，零拷贝
    );
        dst_q.delete();  // 确保目标队列为"空"
        for (int i = src_q.size() - 1; i >= 0; i--) begin
            dst_q.push_back(src_q[i]);
        end
    endtask
 为什么方式（5）最优？
   性能：sv中队列作为input参数时，默认会深拷贝整个队列，如果元素多，开销巨大。ref只传地址，只有一个开销
   安全性：const ref保证函数内部绝不可能意外修改源队列，编译器会检查
   语义清晰：调用者看到ref就知道这个task会修改外部变量
       
2.队列内建方法
       eg： int q[$]=`{1,2,3,4,5}; 从左到右位置依次是0 1 2 ... 4
       （1）q.size(), 元素个数
       （2）q.insert(i,val) ,在i位置插入值val
        (3) q.delet(i)删除位置i的值，q.delete()清空队列
       （4）q.put(i,val),等同于insert
       （5）q.get(i),获取第i位置的值（不删除）
        (6) q.push_front(val)头部插入；q.push_back(val)尾部插入
       （7）q.pop_front,移除头部元素；q.pop_back,移除尾部元素
       （8）q.find_index with(item==3),输出队列中值为3的元素全部匹配的索引
       （9）q.find_first_index with(item>5),返第一个满足条件的索引；q.find_last_index with(item<8),返最后一个满足条件的索引
       （10）q.find with(cond),返回所有匹配的元素；find_first with(cond)，第一个匹配的元素；find_last with(cond)，最后一个匹配的元素
       （11）q.sort(),升序排序； q.rsort(),降序排序 ；q.shuffle(),随机打乱
        (12) q.reverse() 反转队列
       
           

       
3.深拷贝和浅拷贝
     （1）浅拷贝：复制句柄(指针)，指向同一块内存；obj_b = obj_a 就是浅拷贝
        sv中默认行为全是浅拷贝，类句柄赋值都是浅拷贝；动态数组和队列在类内是句柄
        例如，两个动态数组 p1=p2 就属于浅拷贝，因为p1和p2指向同一个对象，如果改变p2的值，p1的值也改变。
     （2）深拷贝：递归复制所有成员的实际数据，创建全新对象。自定义copy函数
     例如：对数组进行=直接赋值，属于深拷贝；q2[0]=999
     class Packet;
       int id;
       int payload[$];  // 动态数组/队列在类内部是句柄
     endclass
     Packet pkt_q1[$];
     Packet pkt_q2[$];
     pkt_q1.push_back(new());
     pkt_q2 = pkt_q1;  // 队列本身深拷贝了，但里面的 Packet 句柄是浅拷贝！
     pkt_q2[0].id = 999;
     $display(pkt_q1[0].id);  // 999！因为两个队列第0个元素指向同一个 Packet 对象
