（一）RM参考模型
$cast(axi_xaction_in, axi_in_tr)强制拷贝的目的？意义？
Cast强制拷贝，将一个基类变量直接赋值给一个子类变量则是非法的，只有用到cast强制转换才可以赋值。
Reference Model分为了两个进程，process0抓取来自master端的读写数据，送到RM进行处理。Process1抓起来自slave端的数据，送到RM进行处理。
