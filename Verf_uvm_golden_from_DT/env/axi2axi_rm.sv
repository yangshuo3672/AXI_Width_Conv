`ifndef AXI2AXI_RM_SV
`define AXI2AXI_RM_SV
`define FULL_ADDR 64'hffff_ffff_ffff_ffff

class axi2axi_rm extends stb_function_component #(2, 2);
  `ifdef FCOV_ON
    ktp_fcov fcov;
  `endif

  `uvm_component_utils_begin(axi2axi_rm)
  `uvm_component_utils_end

  extern function new(string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

  /** \brief The axi_xaction processing thread */
  extern virtual task axi_xaction_0_process();
  extern virtual task axi_xaction_1_process();

  extern function strb_change(input [127:0] wstrb, input [31:0] size, output [127:0] strb);
endclass: axi2axi_rm

function axi2axi_rm::new(string name, uvm_component parent);
  super.new(name, parent);
  `ifdef FCOV_ON
    this.fcov = ktp_fcov::type_id::create("fcov", this);
  `endif
endfunction: new

function void axi2axi_rm::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction: build_phase

task axi2axi_rm::run_phase(uvm_phase phase);
  super.run_phase(phase);
  `uvm_info(get_type_name(), $sformatf("begin the RM"), UVM_HIGH);

  fork
    axi_xaction_0_process();
    axi_xaction_1_process();
  join_none
endtask:run_phase

    task axi2axi_rm::axi_xaction_0_process();

    uvm_sequence_item axi_in_tr;
    axi_xaction       axi_xaction_in;
    ktp_xaction       rm_out_tr;

    fork
        while(1) begin
            uvm_info(get_type_name(), $sformatf("print the RM INPORT NUM 0"), UVM_HIGH);

            this.in_port[0].get(axi_in_tr);

            rm_out_tr = ktp_xaction::type_id::create();

            if(!$cast(axi_xaction_in, axi_in_tr)) begin
                `uvm_fatal(get_type_name(), "axi_xaction_0_process:rm received packet is not a axi_xaction type or its extension");
            end
            `uvm_info(get_type_name(), $sformatf("this is an AXI TRANSACTION from master"), UVM_HIGH);
            `uvm_info("RM_SPRINT", $sformatf("print transaction from master at rm 
%s", axi_xaction_in.sprint()), UVM_HIGH);

            if (axi_xaction_in.m_enXactDir == axi_dec::DIR_WRITE) begin
                `uvm_info(get_type_name(), $sformatf("print the length = %0d & size = %0d from slave", axi_xaction_in.m_enXactLength, axi_xaction_in.m_enXferSize), UVM_HIGH);
                case (axi_xaction_in.m_enXactBurst)
                    axi_dec::BURST_INCR:
                    begin
                        `uvm_info(get_type_name(), $sformatf("RM get write xaction, w_addr = %0d", axi_xaction_in.m_bvAddr), UVM_HIGH);
                        rm_out_tr.w_id_q.push_back(axi_xaction_in.m_bvAid);
                        rm_out_tr.w_addr_q.push_back(axi_xaction_in.m_bvAddr);
                        rm_out_tr.w_qos_q.push_back(axi_xaction_in.m_bvQos);
                        rm_out_tr.w_region_q.push_back(axi_xaction_in.m_bvRegion);
                        rm_out_tr.w_domain_q.push_back(axi_xaction_in.m_bvDomain);
                        rm_out_tr.w_cache_q.push_back(axi_xaction_in.m_enXactCache);
                        rm_out_tr.w_prot_q.push_back(axi_xaction_in.m_enXactProt);
                        rm_out_tr.w_snoop_q.push_back(axi_xaction_in.m_bvSnoop);
                        rm_out_tr.w_user_q.push_back(axi_xaction_in.m_bvAuser);
                        foreach(axi_xaction_in.m_bvvData[i]) begin
                            rm_out_tr.w_data_q.push_back(axi_xaction_in.m_bvvData[i][63:0]);
                            rm_out_tr.w_data_q.push_back(axi_xaction_in.m_bvvData[i][127:64]);
                        end
                        foreach (axi_xaction_in.m_envResp[i])begin
                            rm_out_tr.w_resp_q.push_back(axi_xaction_in.m_envResp[i]);
                        end
                        `ifdef FCov_ON
                            ktp_fcov_xaction rm_cov = ktp_fcov_xaction::type_id::create();
                            rm_cov.axi_wlen     = axi_xaction_in.m_enXactLength;
                            rm_cov.axi_wid      = axi_xaction_in.m_bvAid;
                            rm_cov.axi_waddr    = axi_xaction_in.m_bvAddr;
                            rm_cov.axi_woutstanding = axi_xaction_in.outstanding;
                            foreach(axi_xaction_in.m_bvvData[i]) begin

rm_cov.axi_wdata = axi_xaction_in.m_bvvData[i];
end
foreach(axi_xaction_in.m_envResp[i]) begin
    rm_cov.axi_wresp = axi_xaction_in.m_envResp[i];
end
this.fcov.write(rm_cov);
end
endif
end
axi_dec::BURST_FIXED:
begin
    `uvm_info("TYPEWARNING", "BURST_FIXED is not supported in KTP", UVM_LOW);
end
axi_dec::BURST_WRAP:
begin
    `uvm_info("TYPEWARNING", "BURST_WRAP is not supported in KTP", UVM_HIGH);
end
endcase
end
else if (axi_xaction_in.m_enXactDir == axi_dec::DIR_READ) begin
    case (axi_xaction_in.m_enXactBurst)
        axi_dec::BURST_INCR:
        begin
            `uvm_info(get_type_name(), $sformatf("RM get read xaction, r_addr = %0d", axi_xaction_in.m_bvAddr), UVM_HIGH);
            rm_out_tr.r_id_q.push_back(axi_xaction_in.m_bvAid);
            rm_out_tr.r_addr_q.push_back(axi_xaction_in.m_bvAddr);
            rm_out_tr.r_qos_q.push_back(axi_xaction_in.m_bvQos);
            rm_out_tr.r_region_q.push_back(axi_xaction_in.m_bvRegion);
            rm_out_tr.r_domain_q.push_back(axi_xaction_in.m_bvDomain);
            rm_out_tr.r_cache_q.push_back(axi_xaction_in.m_enXactCache);
            rm_out_tr.r_prot_q.push_back(axi_xaction_in.m_enXactProt);
            rm_out_tr.r_snoop_q.push_back(axi_xaction_in.m_bvSnoop);
            rm_out_tr.r_user_q.push_back(axi_xaction_in.m_bvAuser);
            foreach(axi_xaction_in.m_bvvData[i]) begin
                rm_out_tr.r_data_q.push_back(axi_xaction_in.m_bvvData[i][63:0]);
                rm_out_tr.r_data_q.push_back(axi_xaction_in.m_bvvData[i][127:64]);
            end
            foreach (axi_xaction_in.m_envResp[i]) begin
                rm_out_tr.r_resp_q.push_back(axi_xaction_in.m_envResp[i]);
            end
            `ifdef FCOV_ON begin
                ktp_fcov_xaction rm_cov = ktp_fcov_xaction::type_id::create();
                rm_cov.axi_rlen = axi_xaction_in.m_enXactLength;
                rm_cov.axi_rid = axi_xaction_in.m_bvAid;
                rm_cov.axi_raddr = axi_xaction_in.m_bvAddr;
                rm_cov.axi_routstanding = axi_xaction_in.outstanding;
                foreach(axi_xaction_in.m_bvvData[i]) begin
                    rm_cov.axi_rdata = axi_xaction_in.m_bvvData[i];
                end
                foreach(axi_xaction_in.m_envResp[i]) begin
                    rm_cov.axi_rresp = axi_xaction_in.m_envResp[i];
                end
            `endif
        end
    endcase
end

      end
this.fcov.write(rm_cov);
`endif
end
end
axi_dec::BURST_FIXED:
begin
`uvm_info("TYPEWARNING", "BURST_FIXED is not surported in KTP", UVM_LOW);
end
axi_dec::BURST_WRAP:
begin
`uvm_info("TYPEWARNING", "BURST_WRAP is not surported in KTP", UVM_HIGH);
end
default : begin
`uvm_info(get_type_name(), $sformatf("this is a reserved burst type"), UVM_HIGH);
end
endcase
end

`uvm_info(get_type_name(), $sformatf("send the rm transaction from AXI MASTER to CHECKER
"), UVM_HIGH);
#20ns;
this.out_port[0].put(rm_out_tr);
end
join_none
endtask : axi_xaction_0_process

task axi2axi_rm::axi_xaction_1_process();

uvm_sequence_item axi_in_tr;
axi_xaction axi_xaction_in;
ktp_xaction rm_out_tr;

fork
while(1) begin

this.in_port[1].get(axi_in_tr);
`uvm_info(get_type_name(), $sformatf("print the RM INPORT NUM 1"), UVM_HIGH);

rm_out_tr = ktp_xaction::type_id::create();

if(!$cast(axi_xaction_in, axi_in_tr)) begin
`uvm_fatal(get_type_name(), "axi_xaction_0_process:rm received packet is not a axi_xaction type or its extension");
end

`uvm_info(get_type_name(), $sformatf("this is an AXI TRANSACTION from slave"), UVM_HIGH);
`uvm_info("RM_SPRINT", $sformatf("print transaction from slave at rm 
%s", axi_xaction_in.sprint()), UVM_HIGH);

if (axi_xaction_in.m_enXactDir == axi_dec::DIR_WRITE) begin


  uvm_info(get_type_name(), $sformatf("print the length = %0d & size = %0d from slave", axi_xaction_in.m_enXactLength, axi_xaction_in.m_enXferSize), UVM_HIGH);
case (axi_xaction_in.m_enXactBurst)
    axi_dec::BURST_INCR:
        begin
            `uvm_info(get_type_name(), $sformatf("RM get write xaction from slave , w_addr = %0d", axi_xaction_in.m_bvAddr), UVM_DEBUG);
            rm_out_tr.w_id_q.push_back(axi_xaction_in.m_bvAid);
            rm_out_tr.w_addr_q.push_back(axi_xaction_in.m_bvAddr);
            rm_out_tr.w_qos_q.push_back(axi_xaction_in.m_bvQos);
            rm_out_tr.w_region_q.push_back(axi_xaction_in.m_bvRegion);
            rm_out_tr.w_domain_q.push_back(axi_xaction_in.m_enXactDomain);
            rm_out_tr.w_cache_q.push_back(axi_xaction_in.m_enXactCache);
            rm_out_tr.w_prot_q.push_back(axi_xaction_in.m_enXactProt);
            rm_out_tr.w_snoop_q.push_back(axi_xaction_in.m_bvSnoop);
            rm_out_tr.w_user_q.push_back(axi_xaction_in.m_bvAuser);
            foreach(axi_xaction_in.m_bvvData[i]) begin
                rm_out_tr.w_data_q.push_back(axi_xaction_in.m_bvvData[i]);
                `uvm_info(get_type_name(), $sformatf("RM get write xaction from slave, w_data = %0d", axi_xaction_in.m_bvvData[i]), UVM_DEBUG);
            end
            foreach(axi_xaction_in.m_envResp[i])begin
                rm_out_tr.w_resp_q.push_back(axi_xaction_in.m_envResp[i]);
            end
            `ifdef FCOV_ON
                ktp_fcov_xaction rm_cov = ktp_fcov_xaction::type_id::create();
                rm_cov.axi_wlen     = axi_xaction_in.m_enXactLength;
                rm_cov.axi_wid      = axi_xaction_in.m_bvAid;
                rm_cov.axi_waddr    = axi_xaction_in.m_bvAddr;
                rm_cov.axi_woutstanding = axi_xaction_in.outstanding;
                foreach(axi_xaction_in.m_bvvData[i]) begin
                    rm_cov.axi_wdata = axi_xaction_in.m_bvvData[i];
                end
                foreach(axi_xaction_in.m_envResp[i]) begin
                    rm_cov.axi_wresp = axi_xaction_in.m_envResp[i];
                end
                this.fcov.write(rm_cov);
            `endif
        end
    axi_dec::BURST_FIXED:
        begin
            `uvm_info("TYPEWARNING", "BURST_FIXED is not surported in KTP", UVM_LOW);
        end
    axi_dec::BURST_WRAP:
        begin
            `uvm_info("TYPEWARNING", "BURST_WRAP is not surported in KTP", UVM_HIGH);
        end
endcase
else if (axi_xaction_in.m_enXactDir == axi_dec::DIR_READ) begin
    case (axi_xaction_in.m_enXactBurst)
        axi_dec::BURST_INCR:
            begin

`uvm_info(get_type_name(), $sformatf("RM get read xaction from slave, r_addr = %0d", axi_xaction_in.m_bvAddr), UVM_HIGH);
rm_out_tr.r_id_q.push_back(axi_xaction_in.m_bvAid);
rm_out_tr.r_addr_q.push_back(axi_xaction_in.m_bvAddr);
rm_out_tr.r_qos_q.push_back(axi_xaction_in.m_bvQos);
rm_out_tr.r_region_q.push_back(axi_xaction_in.m_bvRegion);
rm_out_tr.r_domain_q.push_back(axi_xaction_in.m_bvDomain);
rm_out_tr.r_cache_q.push_back(axi_xaction_in.m_enXactCache);
rm_out_tr.r_prot_q.push_back(axi_xaction_in.m_enXactProt);
rm_out_tr.r_snoop_q.push_back(axi_xaction_in.m_bvSnoop);
rm_out_tr.r_user_q.push_back(axi_xaction_in.m_bvAuser);
foreach(axi_xaction_in.m_bvvData[i]) begin
    rm_out_tr.r_data_q.push_back(axi_xaction_in.m_bvvData[i]);
    `uvm_info(get_type_name(), $sformatf("RM get read xaction from slave, w_data = %0d", axi_xaction_in.m_bvvData[i]), UVM_DEBUG);
end
foreach(axi_xaction_in.m_envResp[i]) begin
    rm_out_tr.r_resp_q.push_back(axi_xaction_in.m_envResp[i]);
end
`ifdef FCOV_ON
    ktp_fcov_xaction rm_cov = ktp_fcov_xaction::type_id::create();
    rm_cov.axi_rlen = axi_xaction_in.m_enXactLength;
    rm_cov.axi_rid = axi_xaction_in.m_bvAid;
    rm_cov.axi_raddr = axi_xaction_in.m_bvAddr;
    rm_cov.axi_routstanding = axi_xaction_in.outstanding;
    foreach(axi_xaction_in.m_bvvData[i]) begin
        rm_cov.axi_rdata = axi_xaction_in.m_bvvData[i];
    end
    foreach(axi_xaction_in.m_envResp[i]) begin
        rm_cov.axi_rresp = axi_xaction_in.m_envResp[i];
    end
    this.fcov.write(rm_cov);
`endif
end
axi_dec::BURST_FIXED:
begin
    `uvm_info("TYPEWARNING", "BURST_FIXED is not surported in KTP", UVM_LOW);
end
axi_dec::BURST_WRAP:
begin
    `uvm_info("TYPEWARNING", "BURST_WRAP is not surported in KTP", UVM_HIGH);
end
default : begin
    `uvm_info(get_type_name(), $sformatf("this is a reserved burst type"), UVM_HIGH);
end
endcase
end

`uvm_info(get_type_name(), $sformatf("send the rm transaction from AXI MASTER to CHECKER
"), UVM_HIGH);
this.out_port[1].put(rm_out_tr);

end
join_none

endtask : axi_xaction_1_process

`endif

                                     

              

      

    

  
