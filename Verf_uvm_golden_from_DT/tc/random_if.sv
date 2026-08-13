`ifndef KTP_CSTR_SV
`define KTP_CSTR_SV
//
//随机赋值接口
class KTP_CSTR;
    randc bit [ 7:0] id;
    rand  bit [ 2:0] length;
    rand  bit [127:0] data;
    rand  bit [31:0] addr;
//    rand  bit [17:0] awuser;
//    rand  bit [17:0] aruser;
    rand  bit [3:0] awcache;
    rand  bit [3:0] arcache;
    rand  bit [17:0] awuser;
    rand  bit [17:0] aruser;
    rand  bit [3:0] awqos;
    rand  bit [3:0] arqos;
    rand  bit [2:0] awprot;
    rand  bit [2:0] arprot;
//    rand  bit [3:0] awqos;
//    rand  bit [3:0] arqos;

    constraint rand_cfg{
      length inside {[0:7]}; 
      addr[3:0] == 4'd0;//地址十六字节对齐
        ({2'b0,addr[11:0]} + ({11'b0,length} + 1) * 14'd16) < 14'd4000;
    }
endclass: KTP_CSTR
`endif
