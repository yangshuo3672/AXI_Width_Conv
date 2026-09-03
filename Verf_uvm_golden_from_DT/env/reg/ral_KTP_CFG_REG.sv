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


