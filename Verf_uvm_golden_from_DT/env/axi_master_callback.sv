class wr_constraint;
    rand bit [15:0] wstrb;
    rand bit [127:0] wdata;
    constraint axi_wstrb_const {
        wstrb == 16'hff;
    }
endclass

class ktp_axi_driver_callback extends axi_driver_callbacks;

    `uvm_object_utils(ktp_axi_driver_callback)

    int avalid_wvalid_delay;
    int next_wvalid_delay;
    int next_avalid_delay;
    int bvalid_bready_delay;
    int bready_delay;
    int rvalid_rready_delay;
    int rready_delay;

    wr_constraint wr_cstr;

    function new(string name = "my_driver_callback");
        super.new(name);
        wr_cstr = new();
    endfunction

    virtual function void process_StartedAddressCbF (axi_driver oRvmModel, axi_xaction oVipXact, ref bit drop );
        `uvm_info(get_type_name(),"reconfigure AXI master driver transaction delay",UVM_DEBUG);

        foreach(oVipXact.m_nvNextWvalidDelay[i]) begin
            oVipXact.m_nvNextWvalidDelay[i] = next_wvalid_delay;
        end
        oVipXact.m_nAvalidWvalidDelay = avalid_wvalid_delay;
        oVipXact.m_nNextAvalidDelay = next_avalid_delay;
        oVipXact.m_nBvalidBreadyDelay = bvalid_bready_delay;
        oVipXact.m_nBreadyDelay = bready_delay;
        foreach(oVipXact.m_nvRvalidRreadyDelay[i]) begin
            oVipXact.m_nvRvalidRreadyDelay[i] = rvalid_rready_delay;
        end
        foreach(oVipXact.m_nvRreadyDelay[i]) begin
            oVipXact.m_nvRreadyDelay[i] = rready_delay;
        end
        foreach(oVipXact.m_bvvWstrb[i]) begin
            wr_cstr.randomize();
            oVipXact.m_bvvWstrb[i] = wr_cstr.wstrb;
        end
        foreach(oVipXact.m_bvvData[i]) begin
            wr_cstr.randomize();
            oVipXact.m_bvvData[i] = wr_cstr.wdata;
        end
    endfunction
endclass:ktp_axi_driver_callback
