class apb_xaction extends stb_rw_sequence_item; 
       
       rand logic [`APB_ADDR_WIDTH - 1 :0] addr;
       rand logic [`APB_DATA_WIDTH - 1 :0] data;
       rand apb_dec::apb_dir_enum dir;
       rand bit [2:0] prot;
       rand bit [`APB_WSTRB_WIDTH -1:0] strb;
       rand bit resp;
       //< use in slave driver
       rand integer pready_delay;
       rand integer idle_num;
       rand bit seq_need_resp = 0;

       rand bit [`APB_AUSER_WIDTH - 1 :0] m_bvAuser;
       rand bit [`APB_RUSER_WIDTH - 1 :0] m_bvRuser;
       rand bit [`APB_WUSER_WIDTH - 1 :0] m_bvWuser;

       bit get_resp_flag = 0;//indicate the transaction get the resp or not

       rand bit [`HISI_VIP_APB_QOS_PORT_WIDTH -1:0 ] m_bvQos;
       rand bit [`HISI_VIP_APB_GRPID_PORT_WIDTH -1:0] m_bvGrpid;
       rand bit [`HISI_VIP_APB_VMID_PORT_WIDTH -1:0] m_bvVmid;
       rand bit [`HISI_VIP_APB_MPUBYPASS_PORT_WIDTH -1:0] m_bvMpubypass;
       rand bit [`HISI_VIP_APB_SNOOP_PORT_WIDTH -1:0] m_bvSnoop;
       rand bit [`HISI_VIP_APB_DOMAIN_PORT_WIDTH -1:0] m_bvDomain;

       rand bit compare_qos ;//indicate the qos needs to be compared or not ,in SocChecker
       rand bit compare_grpid ;//indicate the grpid needs to be compared or not ,in SocChecker
       rand bit compare_vmid ;//indicate the vmid needs to be compared or not ,in SocChecker
       rand bit compare_mpubypass;//indicate the mpubypass needs to be compared or not ,in SocChecker
       rand bit compare_snoop ;//indicate the snoop needs to be compared or not ,in SocChecker
       rand bit compare_domain ;//indicate the domain needs to be compared or not ,in SocChecker
       bit bus_check_en = 0;//indicate the bus check or not
       bit memory_check_en = 0;//indicate the memory check or not
       bit peri_dec_check_en = 0;//indicate the peri_dec check or not

        // Constructor
    `uvm_object_utils_begin(apb_xaction)
        `uvm_field_enum(apb_dec::apb_dir_enum,dir,UVM_ALL_ON)
        `uvm_field_int(addr,UVM_ALL_ON)
        `uvm_field_int(data,UVM_ALL_ON)
        `uvm_field_int(strb,UVM_ALL_ON)
        `uvm_field_int(prot,UVM_ALL_ON)
        `uvm_field_int(resp,UVM_ALL_ON)
        `uvm_field_int(pready_delay,UVM_ALL_ON)
        `uvm_field_int(idle_num,UVM_ALL_ON)
        `uvm_field_int(m_bvAuser,UVM_ALL_ON)
        `uvm_field_int(m_bvRuser,UVM_ALL_ON)
        `uvm_field_int(m_bvWuser,UVM_ALL_ON)
        `uvm_field_int(get_resp_flag,UVM_ALL_ON)
        `uvm_field_int(m_bvQos,UVM_ALL_ON)
        `uvm_field_int(m_bvGrpid,UVM_ALL_ON)
        `uvm_field_int(m_bvVmid,UVM_ALL_ON)
        `uvm_field_int(m_bvMpubypass,UVM_ALL_ON)
        `uvm_field_int(m_bvSnoop,UVM_ALL_ON)
        `uvm_field_int(m_bvDomain,UVM_ALL_ON)
        `uvm_field_int(compare_qos,UVM_ALL_ON)
        `uvm_field_int(compare_grpid,UVM_ALL_ON)
        `uvm_field_int(compare_vmid,UVM_ALL_ON)
        `uvm_field_int(compare_mpubypass,UVM_ALL_ON)
        `uvm_field_int(compare_snoop,UVM_ALL_ON)
        `uvm_field_int(compare_domain,UVM_ALL_ON)
        `uvm_field_int(bus_check_en,UVM_ALL_ON)
        `uvm_field_int(memory_check_en,UVM_ALL_ON)
        `uvm_field_int(peri_dec_check_en,UVM_ALL_ON)
    `uvm_object_utils_end

          extern function new(string name = "apb_xaction");

         constraint seq_need_resp_cons {soft this.seq_need_resp == 0;}
         constraint reasonable_pready_delay{ pready_delay == 'h0;}
         constraint idle_num_con{ idle_num == 'h0;}
            
          //  -> 属于蕴含操作符，如果左侧条件成立，则右侧约束生效。
         constraint write_strobes{
             dir == apb_dec::READ -> strb == 'h0;
             dir == apb_dec::WRITE -> strb inside {[1:15]};
         }

        constraint access_response{ resp == 'h0;}

        constraint compare_cons
        {
            compare_qos       == 1;
            compare_grpid     == 1;
            compare_vmid      == 1;
            compare_mpubypass == 1;
            compare_snoop     == 1;
            compare_domain    == 1;
        }

endclass: apb_xaction

function apb_xaction::new(string name="apb_xaction");
    super.new(name);
endfunction : new
