//run phase中不提起objection，只做一些动态监测的代码，需要持续的并行运行
task axi_monitor::run_phase (uvm_phase phase);
  super.run_phase(phase);
  `uvm_info(get_type_name(),$sformatf("axi_monitor run_phase begin: addr_width = %0dbit; data_width = %0dbit; id_width = %0dbit",m_oMonCfg.m_enAddrWidth,m_oMonCfg.m_enDataWidth,m_oMonCfg.m_nMonIdWidth), UVM_HIGH);
  //add for validity checking of monitor config
  monitor_cfg_validity_check();
  
  m_bvAddr_range = {64{1'b1}} >> (64-m_oMonCfg.m_enAddrWidth) ;
  m_bvData_range = {1024{1'b1}} >> (1024-m_oMonCfg.m_enDataWidth) ;
  
  while(1) begin
    fork
      begin
        fork
          begin
            rcmd_thread();
          end
          begin
            rdata_ctrl();
          end
          begin
            wcmd_thread();
          end
          begin
            wdata_ctrl();
          end
          begin
            rd_wr_sequence();
          end
          begin
            cycle_cnt();
          end
          /*
          begin
            x_state_check();
          end
          */
        join_none
      end
      
      fork
        begin
          @(ITF);
          time_pre = $realtime;
          @(ITF);
          time_pos = $realtime;
          T = time_pos - time_pre;
        end
      join_none
      `ifndef ASYN_RESET_FUNC
      wait(`ITF.aresetn==0);
      disable fork;
      this.async_reset_signal();
        @(`ITF);
        this.global_cycle_cnt ++;
        `else
        wait(`ITF_BUS.aresetn==0);
        disable fork;
        this.global_cycle_cnt++;
        this.async_reset_signal();
          @(`ITF);
          `endif
          end
        join
    end
  endtask:run_phase
        
