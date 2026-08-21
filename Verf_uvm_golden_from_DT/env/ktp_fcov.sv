class ktp_fcov_xaction extends stb_sequence_item;
  int axi_wlen;
  int axi_wid;
  int axi_waddr;
  int axi_wdata;
  int axi_woutstanding;
//   int axi_wout_of_order;
  int axi_wresp;

  int axi_rlen;
  int axi_rid;
  int axi_raddr;
  int axi_rdata;
  int axi_routstanding;
//   int axi_rout_of_order;
  int axi_rresp;

  `uvm_object_utils_begin(ktp_fcov_xaction)
    `uvm_field_int(axi_wlen, UVM_ALL_ON)
    `uvm_field_int(axi_wid, UVM_ALL_ON)
    `uvm_field_int(axi_waddr, UVM_ALL_ON)
    `uvm_field_int(axi_wdata, UVM_ALL_ON)
    `uvm_field_int(axi_woutstanding, UVM_ALL_ON)
//     `uvm_field_int(axi_wout_of_order, UVM_ALL_ON)
    `uvm_field_int(axi_wresp, UVM_ALL_ON)

    `uvm_field_int(axi_rlen, UVM_ALL_ON)
    `uvm_field_int(axi_rid, UVM_ALL_ON)
    `uvm_field_int(axi_raddr, UVM_ALL_ON)
    `uvm_field_int(axi_rdata, UVM_ALL_ON)
    `uvm_field_int(axi_routstanding, UVM_ALL_ON)
//     `uvm_field_int(axi_rout_of_order, UVM_ALL_ON)
    `uvm_field_int(axi_rresp, UVM_ALL_ON)

  `uvm_object_utils_end

  function new(string name = "ktp_fcov_xaction");
    super.new(name);
  endfunction: new

endclass

class ktp_fcov extends uvm_subscriber #(uvm_sequence_item);
  ktp_fcov_xaction rm_cov;

  `uvm_component_utils_begin(ktp_fcov)
  `uvm_component_utils_end
  covergroup ktp_wr;
    option.per_instance = 1;
    axi_wlen: coverpoint rm_cov.axi_wlen {
        bins axi_wlen_1 = {4'h0};
        bins axi_wlen_2 = {4'h1};
        bins axi_wlen_3 = {4'h2};
        bins axi_wlen_4 = {4'h3};
        bins axi_wlen_5 = {4'h4};
        bins axi_wlen_6 = {4'h5};
        bins axi_wlen_7 = {4'h6};
        bins axi_wlen_8 = {4'h7};
    }
    axi_wid: coverpoint rm_cov.axi_wid {
        bins axi_wid_min = {8'h0};
        bins axi_wid_mid_low = {[8'h1 : 8'h7f]};
        bins axi_wid_mid_high = {[8'h80:8'hfe]};
        bins axi_wid_max = {8'hff};
    }
    axi_wdata: coverpoint rm_cov.axi_wdata {
        bins axi_wdata_groups[16] = {[0 : 32'hffffffff]};
    }
    axi_waddr: coverpoint rm_cov.axi_waddr {
        bins axi_waddr_min = {32'h0};
        bins axi_waddr_groups[16] = {[32'h10:32'hFFFFFF7E]};
        bins axi_waddr_max = {32'hFFFFFF70};
    }
    axi_wresp: coverpoint rm_cov.axi_wresp {
        bins axi_wresp_okay = {2'b00};
        bins axi_wresp_slverr = {2'b10};
        bins axi_wresp_decerr = {2'b11};
    }
    axi_woutstanding: coverpoint rm_cov.axi_woutstanding {
        bins axi_woutstanding_groups[4] = {[0:16]};
    }
endgroup
  covergroup ktp_rd;
    option.per_instance = 1;
    axi_rlen: coverpoint rm_cov.axi_rlen {
        bins axi_rlen_1 = {4'h0};
        bins axi_rlen_2 = {4'h1};
        bins axi_rlen_3 = {4'h2};
        bins axi_rlen_4 = {4'h3};
        bins axi_rlen_5 = {4'h4};
        bins axi_rlen_6 = {4'h5};
        bins axi_rlen_7 = {4'h6};
        bins axi_rlen_8 = {4'h7};
    }
    axi_rid: coverpoint rm_cov.axi_rid {
        bins axi_rid_min = {8'h0};
        bins axi_rid_mid_low = {[8'h1:8'h7f]};
        bins axi_rid_mid_high = {[8'h80:8'hfe]};
        bins axi_rid_max = {8'hff};
    }
    axi_rdata: coverpoint rm_cov.axi_rdata {
        bins axi_rdata_groups[16] = {[0 : 32'hffffffff]};
    }
    axi_raddr: coverpoint rm_cov.axi_raddr {
        bins axi_raddr_min = {32'h0};
        bins axi_raddr_groups[16] = {[32'h10:32'hFFFFFF7E]};
        bins axi_raddr_max = {32'hFFFFFFF0};
    }
    axi_rresp: coverpoint rm_cov.axi_rresp {
        bins axi_rresp_okay = {2'b00};
        bins axi_rresp_slverr = {2'b10};
        bins axi_rresp_decerr = {2'b11};
    }
    axi_routstanding: coverpoint rm_cov.axi_routstanding {
        bins axi_routstanding_groups[4] = {[0:16]};
    }
endgroup

extern function new(string name,
                    uvm_component parent
                   );
extern virtual function void write(uvm_sequence_item t);
endclass
  function ktp_fcov::new(string name, uvm_component parent);
    super.new(name, parent);

    ktp_wr = new();       // Create the coverage object
    ktp_wr.set_inst_name("ktp_wr");
    ktp_rd = new();       // Create the coverage object
    ktp_rd.set_inst_name("ktp_rd");
endfunction: new

function void ktp_fcov::write(uvm_sequence_item t);
    if(!$cast(this.rm_cov, t.clone())) begin
        `uvm_fatal(get_type_name(), "write(): item is not a ktp_fcov_xaction type or its extension");
    end

    `uvm_info(get_type_name(), $sformatf("Write cov: 
%s", this.rm_cov.sprint()), UVM_MEDIUM);

    ktp_wr.sample();
    ktp_rd.sample();
endfunction: write
