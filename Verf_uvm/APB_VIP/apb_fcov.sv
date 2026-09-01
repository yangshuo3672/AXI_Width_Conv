class apb_fcov extends uvm_component;
  `uvm_component_utils(apb_fcov)
  apb_xaction cur_req_transfer;

  covergroup req_transfer_ended_apb3;
    option.per_instance = 1;
    option.comment = "Transfer ended when PSELx, PENABLE and PREADY asserted";

    // transfer direction (READ or WRITE)
    direction: coverpoint cur_req_transfer.dir {
      option.comment = "transfer direction (READ or WRITE)";
      bins write_cmd = {1};
      bins read_cmd  = {0};
    }

    // transfer response(APB 3.0)
    slvresp: coverpoint cur_req_transfer.resp {
      option.comment = "transfer response";
      bins resp_ok  = {0};
      bins resp_err = {1};
    }

    // transfer duration in clock cycles(APB 3.0)
    duration: coverpoint cur_req_transfer.pready_delay {
      option.comment = "transfer duration in clock cycles";
      bins BIN_NO_DELAY = {0};
      bins BIN_1_1 = {[1:1]};
      bins BIN_2_2 = {[2:2]};
      bins BIN_3_3 = {[3:3]};
      bins BIN_4_4 = {[4:4]};
      bins BIN_5_5 = {[5:5]};
      bins BIN_6_6 = {[6:6]};
      bins BIN_BIG_DELAY = {[7:32'd65535]};
    }

    // This is a cross coverage of - direction, slvresp
    cross_direction_slvresp : cross direction, slvresp {
      option.comment = "This is a cross coverage of - direction, slvresp";
    }

    // This is a cross coverage of - duration, slvresp
    cross_duration_slvresp : cross duration, slvresp {
      option.comment = "This is a cross coverage of - duration, slvresp";
    }

    // This is a cross coverage of - direction, duration
    cross_direction_duration : cross direction, duration {
      option.comment = "This is a cross coverage of - direction, duration";
    }
  endgroup:req_transfer_ended_apb3

  covergroup req_transfer_ended_apb4;
    option.per_instance = 1;
    // transfer response(APB 4.0)
    strobes: coverpoint cur_req_transfer.strb iff(cur_req_transfer.dir == 1) {
        option.comment = "transfer response";
        ignore_bins ig_strobe = {0};
    }

    // transfer PPROT[0] (APB 4.0)
    privileged: coverpoint cur_req_transfer.prot[0] {
        option.comment = "transfer PPROT[0] (APB 4.0)";
    }

    // transfer PPROT[1] (APB 4.0)
    secure: coverpoint cur_req_transfer.prot[1] {
        option.comment = "transfer PPROT[1] (APB 4.0)";
    }

    // transfer PPROT[2] (APB 4.0)
    dataOrinstr: coverpoint cur_req_transfer.prot[2] {
        option.comment = "transfer PPROT[2] (APB 4.0)";
    }

    // This is a cross coverage of - privileged, secure, dataOrinstr
    cross_privileged_secure_dataOrinstr : cross privileged, secure, dataOrinstr {
        option.comment = "This is a cross coverage of - privileged, secure, dataOrinstr";
    }

endgroup: req_transfer_ended_apb4

extern function new(string name = "apb_fcov", uvm_component parent);

extern virtual function void cover_apb_fcov(input cover_group_id,input cov_enable,input apb_xaction tr);

endclass:apb_fcov

function apb_fcov::new(string name = "apb_fcov", uvm_component parent);
    super.new(name, parent);
    this.req_transfer_ended_apb3 = new();
    this.req_transfer_ended_apb3.set_inst_name($sformatf("%s.req_transfer_ended_apb3", get_full_name()));
    this.req_transfer_ended_apb4 = new();
    this.req_transfer_ended_apb4.set_inst_name($sformatf("%s.req_transfer_ended_apb4", get_full_name()));
endfunction:new

function void apb_fcov::cover_apb_fcov(input cover_group_id,input cov_enable,input apb_xaction tr);
    cur_req_transfer = tr;
    case (cover_group_id)
        0: begin
            if (cov_enable == 1) begin
                req_transfer_ended_apb3.sample();
            end
        end
        1: begin
            if (cov_enable == 1) begin
                req_transfer_ended_apb4.sample();
            end
        end
    endcase
endfunction:cover_apb_fcov
