主要定义一些信号以及握手延迟，有一些信号以及delay的约束

foreach（m_nvNextRvalidDelay[index]）
  if((Dir==0)&&m_enXactionLength >= index+1)  //写并且len这个参数超过了delay   
    delay inside{0,10}????
