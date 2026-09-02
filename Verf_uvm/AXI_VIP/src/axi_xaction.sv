主要定义一些信号以及握手延迟，有一些信号以及delay的约束

foreach（m_nvNextRvalidDelay[index]）
  if((Dir==0)&&m_enXactionLength >= index+1)  //写并且len这个参数超过了delay   
    delay inside{0,10}????



    class axi_xaction extends stb_rw_sequence_item
      rand axi_dec::axi_length_enum m_enXcatLength;


//地址边界约束
constraint reasonable_addr_boundary {
  if (m_enXactBurst == axi_dec::BURST_FIXED) //fixed need 4k boundary
  {
    (m_bvAddr[11:0]/(1<<m_enXferSize))*(1<<m_enXferSize) + (1<<m_enXferSize) <= 4096; // keep xact within same 4KB block
  }
  if (m_enXactBurst == axi_dec::BURST_INCR) //incr need 4k boundary,add by z170803 at 2014.5.9
    (m_bvAddr[11:0]/(1<<m_enXferSize))*(1<<m_enXferSize) + ((m_enXactLength + 1) * (1<<m_enXferSize)) <= 4096; // keep xact within same 4KB block
  if (m_enXactBurst == axi_dec::BURST_WRAP )
  {
    m_enXactLength inside {
      axi_dec::LENGTH_2,
      axi_dec::LENGTH_4,
      axi_dec::LENGTH_8,
      axi_dec::LENGTH_16
    };  // wrap burst only allowed for 'power of 2' lengths
  }
  if (m_enXactBurst == axi_dec::BURST_WRAP ) // wrap requires aligned address
  {
    (m_enXferSize == axi_dec::SIZE_16BIT   ) -> m_bvAddr[0:0] == 1'b0;
    (m_enXferSize == axi_dec::SIZE_32BIT   ) -> m_bvAddr[1:0] == 2'b0;
    (m_enXferSize == axi_dec::SIZE_64BIT   ) -> m_bvAddr[2:0] == 3'b0;
    (m_enXferSize == axi_dec::SIZE_128BIT  ) -> m_bvAddr[3:0] == 4'b0;
    (m_enXferSize == axi_dec::SIZE_256BIT  ) -> m_bvAddr[4:0] == 5'b0;
    (m_enXferSize == axi_dec::SIZE_512BIT  ) -> m_bvAddr[5:0] == 6'b0;
    (m_enXferSize == axi_dec::SIZE_1024BIT ) -> m_bvAddr[6:0] == 7'b0;
  }
}

以下是图片中的代码：

constraint reasonable_DelayRange // terrible code at 2014.12.18
{
    solve delay_mode before m_nAvalidWvalidDelay;
    solve delay_mode before m_nNextAvalidDelay;
    solve delay_mode before m_nBvalidBreadyDelay;
    solve delay_mode before m_nBreadyDelay;
    solve delay_mode before m_nAvalidAreadyDelay;
    solve delay_mode before m_nDefaultAreadyDelay;
    solve delay_mode before m_nWriteBvalidDelay;
    solve delay_mode before m_nAddressRvalidDelay;
    if(delay_mode == axi_dec::NO_DELAY) {
        m_nAvalidWvalidDelay == 0;
        m_nNextAvalidDelay == 0;
        m_nBvalidBreadyDelay == 0;
        m_nBreadyDelay == 0;
        m_nAvalidAreadyDelay == 0;
        m_nDefaultAreadyDelay == 0;
        m_nWriteBvalidDelay == 0;
        m_nAddressRvalidDelay == 0;
    }
    delay_mode dist {axi_dec::NO_DELAY := 2,axi_dec::DELAY_LOW := 4,axi_dec::DELAY_HIGH := 4};
}

constraint reasonable_nAvalidWvalidDelay
{
    solve m_enXactDir before m_nAvalidWvalidDelay;
    solve delay_mode before m_nAvalidWvalidDelay;
    if(m_enXactDir == 1) { m_nAvalidWvalidDelay inside {[-10:10]}; }
    else {m_nAvalidWvalidDelay == 0;}
}

constraint reasonable_nNextAvalidDelay
{
    m_nNextAvalidDelay inside {[0:10]};
}

constraint reasonable_nBvalidBreadyDelay
{
    solve m_enXactDir before m_nBvalidBreadyDelay;
    if (m_enXactDir == 1) { m_nBvalidBreadyDelay inside {[0:10]}; }
    else {m_nBvalidBreadyDelay == 0;}
}

以下是图片中的代码：

constraint reasonable_nvReadyDelay
{
    solve delay_mode before m_nvReadyDelay;
    solve m_enXactLength before m_nvReadyDelay;
    solve m_enXactDir before m_nvReadyDelay;
    m_nvReadyDelay.size == m_enXactLength; //modify by DTS2018113005482
    if(delay_mode == axi_dec::NO_DELAY) {
        foreach(m_nvReadyDelay[idx]) {
            m_nvReadyDelay[idx] == 0;
        }
    } else {
        foreach(m_nvReadyDelay[idx]) {
            if (m_enXactDir == 0) {
                m_nvReadyDelay[idx] inside {[0:10]};
            } else {
                {m_nvReadyDelay[idx] == 0;}
            }
        }
    }
}

constraint reasonable_nBreadyDelay
{
    solve m_enXactDir before m_nBreadyDelay;
    if (m_enXactDir == 1) { m_nBreadyDelay inside {[0:10]}; }
    else { m_nBreadyDelay == 0;}
}

constraint reasonable_nvNextWvalidDelay
{
    solve delay_mode before m_nvNextWvalidDelay;
    solve m_enXactLength before m_nvNextWvalidDelay;
    solve m_enXactDir before m_nvNextWvalidDelay;
    m_nvNextWvalidDelay.size == m_enXactLength;
    if(delay_mode == axi_dec::NO_DELAY) foreach(m_nvNextWvalidDelay[index]) m_nvNextWvalidDelay[index] == 0;
    else {
        foreach(m_nvNextWvalidDelay[index])
        {
            if ((m_enXactDir == 1) && (m_enXactLength >= (index+1))) {
                m_nvNextWvalidDelay[index] inside {[0:10]};
            } else {
                m_nvNextWvalidDelay[index] == 0;
            }
        }
    }
}

