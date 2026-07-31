`ifndef KTP_XACTION__SV
`define KTP_XACTION__SV

class ktp_xaction extends stb_sequence_item;
//write

rand bit [3:0] w_qos_q[$];
rand bit [3:0] w_region_q[$];
rand bit [1:0] w_domain_q[$];
rand bit [3:0] w_cache_q[$];
rand bit [2:0] w_prot_q[$];
rand bit [2:0] w_snoop_q[$];
rand bit [17:0] w_user_q[$];
rand bit [ 8:0] w_id_q[$];
rand bit [31:0] w_addr_q[$];
rand bit [63:0] w_data_q[$];
rand bit [1:0] w_resp_q[$];
//read

rand bit [3:0] r_qos_q[$];
rand bit [3:0] r_region_q[$];
rand bit [1:0] r_domain_q[$];
rand bit [3:0] r_cache_q[$];
rand bit [2:0] r_prot_q[$];
rand bit [3:0] r_snoop_q[$];
rand bit [17:0] r_user_q[$];
rand bit [ 8:0] r_id_q[$];
rand bit [31:0] r_addr_q[$];
rand bit [63:0] r_data_q[$];
rand bit [1:0] r_resp_q[$];

`uvm_object_utils_begin(ktp_xaction)

`uvm_object_utils_end

function new (string name = "ktp_xaction");
super.new (name);
endfunction

extern virtual function void do_pack(uvm_packer packer);

extern virtual function void do_unpack(uvm_packer packer);

extern function void pre_randomize();

extern function void post_randomize();
endclass

function void ktp_xaction::do_pack(uvm_packer packer);
 super.do_pack(packer);
endfunction:do_pack

function void ktp_xaction::do_unpack(uvm_packer packer);
    super.do_unpack(packer);
endfunction:do_unpack

function void ktp_xaction::pre_randomize();
endfunction:pre_randomize

function void ktp_xaction::post_randomize();
endfunction:post_randomize
`endif



  
