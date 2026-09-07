`ifndef RAL_KTP_CFG_REG
`define RAL_KTP_CFG_REG

`define KTP_CFG_REG_TOP_PATH harness.u_ktp.U_KTP_CFG_REG_0

import uvm_pkg::*;

class ral_reg_KTP_CFG_REG_REG_KTP_GLB_CTRL_bkdr extends uvm_reg_backdoor;

    function new(string name);
        super.new(name);
    endfunction

    virtual task read(uvm_reg_item rw);
        do_pre_read(rw);
        begin
            rw.value[0] = `UVM_REG_DATA_WIDTH'h0;
            rw.value[0][0:0] = KTP_CFG_REG_TOP_PATH.U_RW_REG_H0.data_out[0:0];
        end
        rw.status = UVM_IS_OK;
        do_post_read(rw);
    endtask

    virtual task write(uvm_reg_item rw);
        do_pre_write(rw);
        begin
            `KTP_CFG_REG_TOP_PATH.U_RW_REG_H0.data_out[0:0] = rw.value[0][0:0];
        end
        rw.status = UVM_IS_OK;
        do_post_write(rw);
    endtask

endclass

class ral_reg_KTP_CFG_REG_REG_KTP_GLB_CTRL extends uvm_reg;
    rand uvm_reg_field ckg_bypass;
    uvm_reg_field rsv_0;

    constraint ckg_bypass_common {
    }

    function new(string name = "KTP_CFG_REG_REG_KTP_GLB_CTRL");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction: new

    virtual function void build();
        this.ckg_bypass = uvm_reg_field::type_id::create("ckg_bypass", , get_full_name());
        this.ckg_bypass.configure(this, 1, 0, "RW", 0, 1'h0, 1, 1, 0);
        this.rsv_0 = uvm_reg_field::type_id::create("rsv_0", , get_full_name());
        this.rsv_0.configure(this, 31, 1, "RO", 0, 31'h00000000, 1, 0, 0);
    endfunction: build

    `uvm_object_utils(ral_reg_KTP_CFG_REG_REG_KTP_GLB_CTRL)

endclass : ral_reg_KTP_CFG_REG_REG_KTP_GLB_CTRL

class ral_reg_KTP_CFG_REG_REG_KTP_IRPT_MSK_bkdr extends uvm_reg_backdoor;

    function new(string name);
        super.new(name);
    endfunction

    virtual task read(uvm_reg_item rw);
        do_pre_read(rw);
        begin
            rw.value[0] = `UVM_REG_DATA_WIDTH'h0;
            rw.value[0][0:0] = `KTP_CFG_REG_TOP_PATH.U_RW_REG_H10.data_out[0:0];
            rw.value[0][1:1] = `KTP_CFG_REG_TOP_PATH.U_RW_REG_H10.data_out[1:1];
        end
        rw.status = UVM_IS_OK;
        do_post_read(rw);
    endtask

    virtual task write(uvm_reg_item rw);
        do_pre_write(rw);
        begin
            `KTP_CFG_REG_TOP_PATH.U_RW_REG_H10.data_out[0:0] = rw.value[0][0:0];
            `KTP_CFG_REG_TOP_PATH.U_RW_REG_H10.data_out[1:1] = rw.value[0][1:1];
        end
        rw.status = UVM_IS_OK;
        do_post_write(rw);
    endtask

endclass

class ral_reg_KTP_CFG_REG_REG_KTP_IRPT_MSK extends uvm_reg;
    rand uvm_reg_field ktp_rresp_err_irpt_msk;
    rand uvm_reg_field ktp_wresp_err_irpt_msk;
    uvm_reg_field rsv_0;

    constraint ktp_rresp_err_irpt_msk_common {
    }

    constraint ktp_wresp_err_irpt_msk_common {
    }

    function new(string name = "KTP_CFG_REG_REG_KTP_IRPT_MSK");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction: new

    virtual function void build();
        this.ktp_rresp_err_irpt_msk = uvm_reg_field::type_id::create("ktp_rresp_err_irpt_msk", , get_full_name());
        this.ktp_rresp_err_irpt_msk.configure(this, 1, 0, "RW", 0, 1'h1, 1, 1, 0);
        this.ktp_wresp_err_irpt_msk = uvm_reg_field::type_id::create("ktp_wresp_err_irpt_msk", , get_full_name());
        this.ktp_wresp_err_irpt_msk.configure(this, 1, 1, "RW", 0, 1'h1, 1, 1, 0);
        this.rsv_0 = uvm_reg_field::type_id::create("rsv_0", , get_full_name());
        this.rsv_0.configure(this, 30, 2, "RO", 0, 30'h00000000, 1, 0, 0);
    endfunction: build

    `uvm_object_utils(ral_reg_KTP_CFG_REG_REG_KTP_IRPT_MSK)

endclass : ral_reg_KTP_CFG_REG_REG_KTP_IRPT_MSK

class ral_reg_KTP_CFG_REG_REG_KTP_IRPT_RAW extends uvm_reg;
    uvm_reg_field ktp_rresp_err_irpt_raw;
    uvm_reg_field ktp_wresp_err_irpt_raw;
    uvm_reg_field rsv_0;

    function new(string name = "KTP_CFG_REG_REG_KTP_IRPT_RAW");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction: new

    virtual function void build();
        this.ktp_rresp_err_irpt_raw = uvm_reg_field::type_id::create("ktp_rresp_err_irpt_raw", , get_full_name());
        this.ktp_rresp_err_irpt_raw.configure(this, 1, 0, "RO", 0, 1'h0, 1, 0, 0);
        this.ktp_wresp_err_irpt_raw = uvm_reg_field::type_id::create("ktp_wresp_err_irpt_raw", , get_full_name());
        this.ktp_wresp_err_irpt_raw.configure(this, 1, 1, "RO", 0, 1'h0, 1, 0, 0);
        this.rsv_0 = uvm_reg_field::type_id::create("rsv_0", , get_full_name());
        this.rsv_0.configure(this, 30, 2, "RO", 0, 30'h00000000, 1, 0, 0);
    endfunction: build

    `uvm_object_utils(ral_reg_KTP_CFG_REG_REG_KTP_IRPT_RAW)

endclass : ral_reg_KTP_CFG_REG_REG_KTP_IRPT_RAW

class ral_reg_KTP_CFG_REG_REG_KTP_IRPT_STAT extends uvm_reg;
    uvm_reg_field ktp_rresp_err_irpt_stat;
    uvm_reg_field ktp_wresp_err_irpt_stat;
    uvm_reg_field rsv_0;

    function new(string name = "KTP_CFG_REG_REG_KTP_IRPT_STAT");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction: new

    virtual function void build();
        this.ktp_rresp_err_irpt_stat = uvm_reg_field::type_id::create("ktp_rresp_err_irpt_stat", , get_full_name());
        this.ktp_rresp_err_irpt_stat.configure(this, 1, 0, "RO", 0, 1'h0, 1, 0, 0);
        this.ktp_wresp_err_irpt_stat = uvm_reg_field::type_id::create("ktp_wresp_err_irpt_stat", , get_full_name());
        this.ktp_wresp_err_irpt_stat.configure(this, 1, 1, "RO", 0, 1'h0, 1, 0, 0);
        this.rsv_0 = uvm_reg_field::type_id::create("rsv_0", , get_full_name());
        this.rsv_0.configure(this, 30, 2, "RO", 0, 30'h00000000, 1, 0, 0);
    endfunction: build

    `uvm_object_utils(ral_reg_KTP_CFG_REG_REG_KTP_IRPT_STAT)

endclass : ral_reg_KTP_CFG_REG_REG_KTP_IRPT_STAT

class ral_reg_KTP_CFG_REG_REG_KTP_IRPT_CLR extends uvm_reg;
    rand uvm_reg_field ktp_rresp_err_irpt_clr;
    rand uvm_reg_field ktp_wresp_err_irpt_clr;
    uvm_reg_field rsv_0;

    constraint ktp_rresp_err_irpt_clr_common {
    }
    constraint ktp_wresp_err_irpt_clr_common {
    }

    function new(string name = "KTP_CFG_REG_REG_KTP_IRPT_CLR");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction: new

    virtual function void build();
        this.ktp_rresp_err_irpt_clr = uvm_reg_field::type_id::create("ktp_rresp_err_irpt_clr", , get_full_name());
        this.ktp_rresp_err_irpt_clr.configure(this, 1, 0, "WO", 0, 1'h0, 1, 1, 0);
        this.ktp_wresp_err_irpt_clr = uvm_reg_field::type_id::create("ktp_wresp_err_irpt_clr", , get_full_name());
        this.ktp_wresp_err_irpt_clr.configure(this, 1, 1, "WO", 0, 1'h0, 1, 1, 0);
        this.rsv_0 = uvm_reg_field::type_id::create("rsv_0", , get_full_name());
        this.rsv_0.configure(this, 30, 2, "RO", 0, 30'h00000000, 1, 0, 0);
    endfunction: build

    `uvm_object_utils(ral_reg_KTP_CFG_REG_REG_KTP_IRPT_CLR)

endclass : ral_reg_KTP_CFG_REG_REG_KTP_IRPT_CLR

class ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_0 extends uvm_reg;
    uvm_reg_field addr_for_error_read_command;

    function new(string name = "KTP_CFG_REG_REG_KTP_DBG_INFO_0");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction: new

    virtual function void build();
        this.addr_for_error_read_command = uvm_reg_field::type_id::create("addr_for_error_read_command", , get_full_name());
        this.addr_for_error_read_command.configure(this, 32, 0, "RO", 0, 32'h00000000, 1, 0, 1);
    endfunction: build

    `uvm_object_utils(ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_0)

endclass : ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_0

class ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_1 extends uvm_reg;
    uvm_reg_field addr_for_error_write_command;

    function new(string name = "KTP_CFG_REG_REG_KTP_DBG_INFO_1");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction: new

    virtual function void build();
        this.addr_for_error_write_command = uvm_reg_field::type_id::create("addr_for_error_write_command", , get_full_name());
        this.addr_for_error_write_command.configure(this, 32, 0, "RO", 0, 32'h00000000, 1, 0, 1);
    endfunction: build

    `uvm_object_utils(ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_1)

endclass : ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_1

class ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_2 extends uvm_reg;
    uvm_reg_field arid_for_error_read_command;
    uvm_reg_field awid_for_error_write_command;

    function new(string name = "KTP_CFG_REG_REG_KTP_DBG_INFO_2");
        super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
    endfunction: new

    virtual function void build();
        this.arid_for_error_read_command = uvm_reg_field::type_id::create("arid_for_error_read_command", , get_full_name());
        this.arid_for_error_read_command.configure(this, 16, 0, "RO", 0, 16'h0000, 1, 0, 1);
        this.awid_for_error_write_command = uvm_reg_field::type_id::create("awid_for_error_write_command", , get_full_name());
        this.awid_for_error_write_command.configure(this, 16, 16, "RO", 0, 16'h0000, 1, 0, 1);
    endfunction: build

    `uvm_object_utils(ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_2)

endclass : ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_2

class ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_3 extends uvm_reg;

    virtual function void build();
    endfunction: build

    `uvm_object_utils(ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_3)

endclass : ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_3


//********************************************reg_block********************************************//
class ral_block_KTP_CFG_REG extends uvm_reg_block;

    rand ral_reg_KTP_CFG_REG_REG_KTP_GLB_CTRL REG_KTP_GLB_CTRL;
    rand ral_reg_KTP_CFG_REG_REG_KTP_IRPT_MSK REG_KTP_IRPT_MSK;
    rand ral_reg_KTP_CFG_REG_REG_KTP_IRPT_RAW REG_KTP_IRPT_RAW;
    rand ral_reg_KTP_CFG_REG_REG_KTP_IRPT_STAT REG_KTP_IRPT_STAT;
    rand ral_reg_KTP_CFG_REG_REG_KTP_IRPT_CLR REG_KTP_IRPT_CLR;
    rand ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_0 REG_KTP_DBG_INFO_0;
    rand ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_1 REG_KTP_DBG_INFO_1;
    rand ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_2 REG_KTP_DBG_INFO_2;
    rand ral_reg_KTP_CFG_REG_REG_KTP_DBG_INFO_3 REG_KTP_DBG_INFO_3;

    rand uvm_reg_field REG_KTP_GLB_CTRL_ckg_bypass;
    uvm_reg_field ckg_bypass;
    uvm_reg_field REG_KTP_GLB_CTRL_rsv_0;
    rand uvm_reg_field REG_KTP_IRPT_MSK_ktp_rresp_err_irpt_msk;
    rand uvm_reg_field ktp_rresp_err_irpt_msk;
    rand uvm_reg_field REG_KTP_IRPT_MSK_ktp_wresp_err_irpt_msk;
    rand uvm_reg_field ktp_wresp_err_irpt_msk;
    uvm_reg_field REG_KTP_IRPT_MSK_rsv_0;
    uvm_reg_field REG_KTP_IRPT_RAW_ktp_rresp_err_irpt_raw;
    uvm_reg_field ktp_rresp_err_irpt_raw;
    uvm_reg_field REG_KTP_IRPT_RAW_ktp_wresp_err_irpt_raw;
    uvm_reg_field ktp_wresp_err_irpt_raw;
    uvm_reg_field REG_KTP_IRPT_RAW_rsv_0;
    uvm_reg_field REG_KTP_IRPT_STAT_ktp_rresp_err_irpt_stat;
    uvm_reg_field ktp_rresp_err_irpt_stat;
    uvm_reg_field REG_KTP_IRPT_STAT_ktp_wresp_err_irpt_stat;
    uvm_reg_field ktp_wresp_err_irpt_stat;
    uvm_reg_field REG_KTP_IRPT_STAT_rsv_0;
    rand uvm_reg_field REG_KTP_IRPT_CLR_ktp_rresp_err_irpt_clr;
    rand uvm_reg_field ktp_rresp_err_irpt_clr;
    rand uvm_reg_field REG_KTP_IRPT_CLR_ktp_wresp_err_irpt_clr;
    rand uvm_reg_field ktp_wresp_err_irpt_clr;
    uvm_reg_field REG_KTP_IRPT_CLR_rsv_0;
    uvm_reg_field REG_KTP_DBG_INFO_0_addr_for_error_read_command;
    uvm_reg_field addr_for_error_read_command;
    uvm_reg_field REG_KTP_DBG_INFO_1_addr_for_error_write_command;
    uvm_reg_field addr_for_error_write_command;
    uvm_reg_field REG_KTP_DBG_INFO_2_arid_for_error_read_command;
    uvm_reg_field arid_for_error_read_command;
    uvm_reg_field REG_KTP_DBG_INFO_2_awid_for_error_write_command;
    uvm_reg_field awid_for_error_write_command;
    uvm_reg_field REG_KTP_DBG_INFO_3_awready_for_upstream;
    uvm_reg_field awready_for_upstream;
    uvm_reg_field REG_KTP_DBG_INFO_3_arready_for_upstream;
    uvm_reg_field arready_for_upstream;
    uvm_reg_field REG_KTP_DBG_INFO_3_wready_for_upstream;
    uvm_reg_field wready_for_upstream;
    uvm_reg_field REG_KTP_DBG_INFO_3_rvalid_for_upstream;
    uvm_reg_field rvalid_for_upstream;
    uvm_reg_field REG_KTP_DBG_INFO_3_bvalid_for_upstream;
    uvm_reg_field bvalid_for_upstream;
   uvm_reg_field REG_KTP_DBG_INFO_3_awvalid_for_downstream;
   uvm_reg_field awvalid_for_downstream;
   uvm_reg_field REG_KTP_DBG_INFO_3_arvalid_for_downstream;
   uvm_reg_field arvalid_for_downstream;
   uvm_reg_field REG_KTP_DBG_INFO_3_wvalid_for_downstream;
   uvm_reg_field wvalid_for_downstream;
   uvm_reg_field REG_KTP_DBG_INFO_3_rready_for_downstream;
   uvm_reg_field rready_for_downstream;
   uvm_reg_field REG_KTP_DBG_INFO_3_bready_for_downstream;
   uvm_reg_field bready_for_downstream;
   uvm_reg_field REG_KTP_DBG_INFO_3_awwvalid_for_axi2uif;
   uvm_reg_field awwvalid_for_axi2uif;
   uvm_reg_field REG_KTP_DBG_INFO_3_awwready_for_axi2uif;
   uvm_reg_field awwready_for_axi2uif;
   uvm_reg_field REG_KTP_DBG_INFO_3_afifo_full_for_aww_master_side;
   uvm_reg_field afifo_full_for_aww_master_side;
   uvm_reg_field REG_KTP_DBG_INFO_3_afifo_empty_for_aww_slave_side;
   uvm_reg_field afifo_empty_for_aww_slave_side;
   uvm_reg_field REG_KTP_DBG_INFO_3_afifo_full_for_ar_master_side;
   uvm_reg_field afifo_full_for_ar_master_side;
   uvm_reg_field REG_KTP_DBG_INFO_3_afifo_empty_for_ar_slave_side;
   uvm_reg_field afifo_empty_for_ar_slave_side;
   uvm_reg_field REG_KTP_DBG_INFO_3_afifo_full_for_b_slave_side;
   uvm_reg_field afifo_full_for_b_slave_side;
   uvm_reg_field REG_KTP_DBG_INFO_3_afifo_empty_for_b_master_side;
   uvm_reg_field afifo_empty_for_b_master_side;
   uvm_reg_field REG_KTP_DBG_INFO_3_afifo_full_for_r_slave_side;
   uvm_reg_field afifo_full_for_r_slave_side;
   uvm_reg_field REG_KTP_DBG_INFO_3_afifo_empty_for_r_master_side;
   uvm_reg_field afifo_empty_for_r_master_side;
   uvm_reg_field REG_KTP_DBG_INFO_3_awwvalid_for_uif2axi;
   uvm_reg_field awwvalid_for_uif2axi;
   uvm_reg_field REG_KTP_DBG_INFO_3_awwready_for_uif2axi;
   uvm_reg_field awwready_for_uif2axi;
   uvm_reg_field REG_KTP_DBG_INFO_3_rsv_0;

   function new(string name = "KTP_CFG_REG");
       super.new(name, build_coverage(UVM_NO_COVERAGE));
   endfunction: new

virtual function void build();
    this.default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 0);
    this.REG_KTP_GLB_CTRL = ral_reg_KTP_CFG_REG_REG_KTP_GLB_CTRL::type_id::create("REG_KTP_GLB_CTRL",,get_full_name());
    this.REG_KTP_GLB_CTRL.configure(this, null, "");
    this.REG_KTP_GLB_CTRL.build();
        this.REG_KTP_GLB_CTRL.add_hdl_path('{
            '{"HDL_REG_KTP_GLB_CTRL", -1, -1}
        });
    this.default_map.add_reg(this.REG_KTP_GLB_CTRL, `UVM_REG_ADDR_WIDTH'h0, "RW", 0);
        this.REG_KTP_GLB_CTRL_ckg_bypass = this.REG_KTP_GLB_CTRL.ckg_bypass;
        this.ckg_bypass = this.REG_KTP_GLB_CTRL.ckg_bypass;
        this.REG_KTP_GLB_CTRL_rsv_0 = this.REG_KTP_GLB_CTRL.rsv_0;
    this.REG_KTP_IRPT_MSK = ral_reg_KTP_CFG_REG_REG_KTP_IRPT_MSK::type_id::create("REG_KTP_IRPT_MSK",,get_full_name());
    this.REG_KTP_IRPT_MSK.configure(this, null, "");
    this.REG_KTP_IRPT_MSK.build();
        this.REG_KTP_IRPT_MSK.add_hdl_path('{
            '{"HDL_REG_KTP_IRPT_MSK", -1, -1}
        });
    this.default_map.add_reg(this.REG_KTP_IRPT_MSK, `UVM_REG_ADDR_WIDTH'h10, "RW", 0);
    this.REG_KTP_IRPT_MSK_ktp_rresp_err_irpt_msk = this.REG_KTP_IRPT_MSK.ktp_rresp_err_irpt_msk;
    this.ktp_rresp_err_irpt_msk = this.REG_KTP_IRPT_MSK.ktp_rresp_err_irpt_msk;
    this.REG_KTP_IRPT_MSK_ktp_wresp_err_irpt_msk = this.REG_KTP_IRPT_MSK.ktp_wresp_err_irpt_msk;
    this.ktp_wresp_err_irpt_msk = this.REG_KTP_IRPT_MSK.ktp_wresp_err_irpt_msk;
    this.REG_KTP_IRPT_MSK_rsv_0 = this.REG_KTP_IRPT_MSK.rsv_0;
    this.REG_KTP_IRPT_RAW = ral_reg_KTP_CFG_REG_REG_KTP_IRPT_RAW::type_id::create("REG_KTP_IRPT_RAW",,get_full_name());
    this.REG_KTP_IRPT_RAW.configure(this, null, "");
    this.REG_KTP_IRPT_RAW.build();
    this.default_map.add_reg(this.REG_KTP_IRPT_RAW, `UVM_REG_ADDR_WIDTH'h14, "RO", 0);
        this.REG_KTP_IRPT_RAW_ktp_rresp_err_irpt_raw = this.REG_KTP_IRPT_RAW.ktp_rresp_err_irpt_raw;
        this.ktp_rresp_err_irpt_raw = this.REG_KTP_IRPT_RAW.ktp_rresp_err_irpt_raw;
        this.REG_KTP_IRPT_RAW_ktp_wresp_err_irpt_raw = this.REG_KTP_IRPT_RAW.ktp_wresp_err_irpt_raw;
        this.ktp_wresp_err_irpt_raw = this.REG_KTP_IRPT_RAW.ktp_wresp_err_irpt_raw;
        this.REG_KTP_IRPT_RAW_rsv_0 = this.REG_KTP_IRPT_RAW.rsv_0;
    this.REG_KTP_IRPT_STAT = ral_reg_KTP_CFG_REG_REG_KTP_IRPT_STAT::type_id::create("REG_KTP_IRPT_STAT",,get_full_name());
    this.REG_KTP_IRPT_STAT.configure(this, null, "");
    this.REG_KTP_IRPT_STAT.build();
    this.default_map.add_reg(this.REG_KTP_IRPT_STAT, `UVM_REG_ADDR_WIDTH'h18, "RO", 0);
        this.REG_KTP_IRPT_STAT_ktp_rresp_err_irpt_stat = this.REG_KTP_IRPT_STAT.ktp_rresp_err_irpt_stat;
        this.ktp_rresp_err_irpt_stat = this.REG_KTP_IRPT_STAT.ktp_rresp_err_irpt_stat;
        this.REG_KTP_IRPT_STAT_ktp_wresp_err_irpt_stat = this.REG_KTP_IRPT_STAT.ktp_wresp_err_irpt_stat;
        this.ktp_wresp_err_irpt_stat = this.REG_KTP_IRPT_STAT.ktp_wresp_err_irpt_stat;
        this.REG_KTP_IRPT_STAT_rsv_0 = this.REG_KTP_IRPT_STAT.rsv_0;
    this.REG_KTP_IRPT_CLR = ral_reg_KTP_CFG_REG_REG_KTP_IRPT_CLR::type_id::create("REG_KTP_IRPT_CLR",,get_full_name());
    this.REG_KTP_IRPT_CLR.configure(this, null, "");
    this.REG_KTP_IRPT_CLR.build();
    this.default_map.add_reg(this.REG_KTP_IRPT_CLR, `UVM_REG_ADDR_WIDTH'h1c, "RW", 0);
        this.REG_KTP_IRPT_CLR_ktp_rresp_err_irpt_clr = this.REG_KTP_IRPT_CLR.ktp_rresp_err_irpt_clr;
        this.ktp_rresp_err_irpt_clr = this.REG_KTP_IRPT_CLR.ktp_rresp_err_irpt_clr;
        this.REG_KTP_IRPT_CLR_ktp_wresp_err_irpt_clr = this.REG_KTP_IRPT_CLR.ktp_wresp_err_irpt_clr;
        this.ktp_wresp_err_irpt_clr = this.REG_KTP_IRPT_CLR.ktp_wresp_err_irpt_clr;
        this.REG_KTP_IRPT_CLR_rsv_0 = this.REG_KTP_IRPT_CLR.rsv_0;

    //中间是其他寄存器，不一一列举了

    //setting up backdoor access...
    begin
        ral_reg_KTP_CFG_REG_REG_KTP_GLB_CTRL_bkdr bkdr = new(this.REG_KTP_GLB_CTRL.get_full_name());
        this.REG_KTP_GLB_CTRL.set_backdoor(bkdr);
    end
    begin
        ral_reg_KTP_CFG_REG_REG_KTP_IRPT_MSK_bkdr bkdr = new(this.REG_KTP_IRPT_MSK.get_full_name());
        this.REG_KTP_IRPT_MSK.set_backdoor(bkdr);
    end
endfunction : build

    `uvm_object_utils(ral_block_KTP_CFG_REG)

endclass : ral_block_KTP_CFG_REG


