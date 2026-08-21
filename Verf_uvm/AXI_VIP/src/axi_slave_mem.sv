class axi_slave_mem extends uvm_object;
   typedef bit [`HISI_VIP_AXI_ADDR_MEM_WIDTH:0] addr_t;
   axi_slave_driver_cfg oVipCfg;
   logic [7:0] mem [addr_t] = '{default : 'hx};
   logic [7:0] mem_fix [addr_t][$];
   
   bit     mem_not_override;
   
   `uvm_object_utils_begin(axi_slave_mem)
      `uvm_field_object(oVipCfg, UVM_ALL_ON)
   `uvm_object_utils_end
   extern function new(string name = "axi_slave_mem");
   /**
    * Used to set a specify address's value
    * - StreamId : Useless parameter
    * - addr     : specific address
    * - width    : the width of this write transaction
    * - data     : specific write data
    * - mask     : specific write data mask, 1 bit mask a byte , '1' forbid to write into memory
    *              '0' allow to write into memory. only support "16'hffff,16'hff00,16'h00ff"
    */
   extern virtual task set_mem(bit [`HISI_VIP_AXI_ADDR_MEM_WIDTH:0] addr, int width = 128,
                               bit [`HISI_VIP_AXI_DATA_PORT_WIDTH-1:0] data, bit [`HISI_VIP_AXI_WSTRB_PORT_WIDTH-1:0] mask, input bit[1:0] burst_type = 1);
   /**
    * Used to get a specify address's value
    * - StreamId : Useless parameter
    * - addr     : specific address
    * - width    : the width of this read transaction
    * - data     : specific read data
    */
   extern virtual task get_mem(bit [`HISI_VIP_AXI_ADDR_MEM_WIDTH:0] addr, input int width = 128, ref logic [`HISI_VIP_AXI_DATA_PORT_WIDTH-1:0] data, input bit[1:0] burst_type = 1);
endclass:axi_slave_mem

function axi_slave_mem::new(string name = "axi_slave_mem");
   super.new(name);
   mem_not_override = 0;
endfunction

task axi_slave_mem::set_mem(bit [`HISI_VIP_AXI_ADDR_MEM_WIDTH:0] addr, int width = 128,
                            bit [`HISI_VIP_AXI_DATA_PORT_WIDTH-1:0] data, bit [`HISI_VIP_AXI_WSTRB_PORT_WIDTH-1:0] mask, input bit[1:0] burst_type = 1);
    bit prot = addr[`HISI_VIP_AXI_ADDR_MEM_WIDTH];
    //add for DTS2018102202882
    if(oVipCfg.mem_prot_check == 1'b0) begin
        addr = addr[`HISI_VIP_AXI_ADDR_MEM_WIDTH-1:0];
    end
    `uvm_info(get_type_name(),$sformatf("AXI Write Memory Address 'h%0x,Data is 'h%0x,Mask is 'h%0x,Width is %0d,Prot is %0d, mem_prot_check = %0d",addr,data,mask,width,prot,oVipCfg.mem_prot_check),UVM_HIGH);
    for (int j = 0;j<(width/8); j++) begin
        if(mask[j] ==1'b0) begin
            if(oVipCfg.mem_type == 1'b0) begin
                if(burst_type == 0) begin
                    mem_fix[addr+j].push_back(data >> (j*8));
                end
                else begin
                    mem[addr+j] = (data >> (j*8));
                end
            end
            else begin
                mem[addr+j] = (data >> (j*8));
            end
        end
    end
endtask: set_mem

task axi_slave_mem::get_mem(bit [`HISI_VIP_AXI_ADDR_MEM_WIDTH:0] addr, input int width = 128, ref logic [`HISI_VIP_AXI_DATA_PORT_WIDTH-1:0] data, input bit[1:0] burst_type = 1);
    logic [7:0] data_tmp[127:0];
    bit prot = addr[`HISI_VIP_AXI_ADDR_MEM_WIDTH];
    //add for DTS2018102202882
    if(oVipCfg.mem_prot_check == 1'b0) begin
        addr = addr[`HISI_VIP_AXI_ADDR_MEM_WIDTH-1:0];
    end

    for(int i = 0;i<(width/8);i++) begin
        if(oVipCfg.mem_type == 1'b0) begin//Add for jira662
            bit exists_or_not = 0;
            if(burst_type == 0) begin
                exists_or_not = mem_fix.exists(addr + i);
            end
            else begin
                exists_or_not = mem.exists(addr + i);
            end
            if (!exists_or_not) begin
                if (oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_X) begin
                    data_tmp[i] = 8'hxx;
                end
                else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_ONE) begin
                    data_tmp[i] = 8'hff;
                end
                else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_A5) begin
                    data_tmp[i] = 8'ha5;
                end
                else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_5A) begin
                    data_tmp[i] = 8'h5a;
                end
                else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_ZERO) begin
                    data_tmp[i] = 8'h00;
                end
                else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_INCR) begin
                    data_tmp[i] = addr + i;
                end
                else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_DECR) begin
                    data_tmp[i] = 8'hff - ((addr + i) & 32'hff);
                end
                else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_RANDOM) begin
                    data_tmp[i] = {$random}%256;
                end
                else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_CFG) begin //add for memory cfg data,DTS2019052100499
                    data_tmp[i] = oVipCfg.data_cfg;
                end
            end
        end
        else begin
            if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_X) begin
                data_tmp[i] = 8'hxx;
            end
            else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_ONE) begin
                data_tmp[i] = 8'hff;
            end
            else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_A5) begin
                data_tmp[i] = 8'ha5;
            end
            else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_5A) begin
                data_tmp[i] = 8'h5a;
            end
            else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_ZERO) begin
                data_tmp[i] = 8'h00;
            end
            else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_INCR) begin
                data_tmp[i] = addr + i;
            end
            else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_DECR) begin
                data_tmp[i] = 8'hff - ((addr + i) & 32'hff);
            end
            else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_RANDOM) begin
                data_tmp[i] = {$random}%256;
            end
            else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_CFG) begin //add for memory cfg data,DTS2019052100499
                data_tmp[i] = oVipCfg.data_cfg;
            end
           else begin
               `uvm_error(get_type_name(),"This Version doesn't support such m_enMemoryDefaultPattern yet");
           end
           if(burst_type == 0) begin //Add for DTS07053
               if(oVipCfg.fixed_warning_en == 1'b1) begin
                   `uvm_warning(get_type_name(),"The FIFO can not support read empty");
               end
           end else begin
               mem[addr + i] = data_tmp[i];
           end
           end else begin
           if(burst_type == 0) begin
               data_tmp[i] = mem_fix[addr + i].pop_front();
               if(mem_fix[addr + i].size == 0) begin 
                   mem_fix.delete(addr + i);
               end
           end else begin
               data_tmp[i] = mem[addr + i];
           end
           end else begin
           bit exists_or_not = 0;
           exists_or_not = mem.exists(addr + i);
           if (!exists_or_not) begin
              if (oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_X) begin
                 data_tmp[i] = 8'hxx;
              end
              else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_ONE) begin
                 data_tmp[i] = 8'hff;
              end
              else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_A5) begin
                 data_tmp[i] = 8'ha5;
              end
              else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_5A) begin
                 data_tmp[i] = 8'h5a;
              end
              else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_ZERO) begin
                 data_tmp[i] = 8'h00;
              end
              else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_INCR) begin
                 data_tmp[i] = addr + i;
              end
              else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_DECR) begin
                 data_tmp[i] = 8'hff - ((addr + i) & 32'hff);
              end
              else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_RANDOM) begin
                 data_tmp[i] = {$random}%256;
              end
              else if(oVipCfg.m_enMemoryDefaultPattern == axi_dec::PATTERN_CFG) begin //add for memory cfg data,DTS2019052100499
                 data_tmp[i] = oVipCfg.data_cfg;
              end
              else begin
                 `uvm_error(get_type_name(),"This Version doesn't support such m_enMemoryDefaultPattern yet");
              end
              mem[addr + i] = data_tmp[i];//Add for DTS07053
           end
           else begin
              data_tmp[i] = mem[addr + i];
           end
           data[((i+1)*8 -1) -: 8] = data_tmp[i];
           end
           `uvm_info(get_type_name(),$sformatf("AXI Read Memory Address 'h%0x,Data is 'h%0x,Prot is %0d, mem_prot_check = %0d",addr,data,prot,oVipCfg.mem_prot_check),UVM_HIGH);
           endtask: get_mem
