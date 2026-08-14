//------------------------------//
//----------axi_default_seq----- ----------//
//------------------------------//
class axi_default_seq extends uvm_sequence #(uvm_sequence_item);

    `uvm_object_utils(axi_default_seq)
    `uvm_declare_p_sequencer(uvm_sequencer)

    extern function new(string name = "axi_default_seq");

    extern virtual task pre_body();

    extern virtual task body();

    extern virtual task post_body();

endClass

function axi_default_seq::new(string name = "axi_default_seq");

    super.new(name);

endfunction

task axi_default_seq::pre_body();

    if(starting_phase != null ) begin
        starting_phase.raise_objection(this);
    end

endtask: pre_body

task axi_default_seq::body();

    uvm_sequence_item trans_item;

    repeat(100) begin
        `uvm_do(req)
    end

endtask: body

task axi_default_seq::post_body();

    if(starting_phase != null ) begin
        starting_phase.drop_objection(this);
    end

endtask: post_body


class axi_sequence extends axi_default_seq ;

`uvm_object_utils(axi_sequence)
`uvm_declare_p_sequencer(uvm_sequencer)

extern function new(string name = "axi_sequence");

extern virtual task axi_decode_write(uvm_sequencer #(uvm_sequence_item) sqr,
                                     bit[`AMBA_SEQUENCE_AXI_SIZE_PORT_WIDTH - 1:0] size,//default [2:0]
                                     bit[`AMBA_SEQUENCE_AXI_ADDR_PORT_WIDTH - 1:0] address,//default [63:0]
                                     bit[`AMBA_SEQUENCE_AXI_DATA_PORT_WIDTH - 1:0] data //default [1023:0]
                                    );

extern virtual task axi_decode_read(uvm_sequencer #(uvm_sequence_item) sqr,
                                    bit[`AMBA_SEQUENCE_AXI_SIZE_PORT_WIDTH - 1:0] size,//default [2:0]
                                    bit[`AMBA_SEQUENCE_AXI_ADDR_PORT_WIDTH - 1:0] address //default [63:0]
                                   );

extern virtual task axi_decode_write_resp(uvm_sequencer #(uvm_sequence_item)   sqr,
                                          bit[`AMBA_SEQUENCE_AXI_SIZE_PORT_WIDTH - 1:0] size,//default [2:0]
                                          bit[`AMBA_SEQUENCE_AXI_ADDR_PORT_WIDTH - 1:0] address,//default [63:0]
                                          bit[`AMBA_SEQUENCE_AXI_DATA_PORT_WIDTH - 1:0] data,//default [1023:0]
                                          ref logic[ AMBA_SEQUENCE_AXI_RESP_PORT_WIDTH - 1:0] resp //default [1:0]
                                         );

extern virtual task axi_decode_read_resp(uvm_sequencer #(uvm_sequence_item)   sqr,
                                         bit[`AMBA_SEQUENCE_AXI_SIZE_PORT_WIDTH - 1:0] size,//default [2:0]
                                         bit[`AMBA_SEQUENCE_AXI_ADDR_PORT_WIDTH - 1:0] address,//default [63:0]
                                         logic[`AMBA_SEQUENCE_AXI_RESP_PORT_WIDTH - 1:0] resp //default [1:0]
                                        );
//中间有一堆task事务，不一一列举。
endclass:axi_sequence

  function axi_sequence::new(string name="axi_sequence");
    super.new(name);
  endfunction


// axi_burst_read, transmit addr/aid/burst_type/burst_length/burst_size/prot and expect_resp, output data
task axi_sequence::axi_burst_read(input uvm_sequencer #(uvm_sequence_item) sqr,
                                  input bit[`AMBA_SEQUENCE_AXI_ADDR_PORT_WIDTH - 1:0] address,
                                  output bit[`AMBA_SEQUENCE_AXI_DATA_PORT_WIDTH - 1:0] data[],
                                  input bit [`AMBA_SEQUENCE_AXI_LEN_PORT_WIDTH - 1:0] burst_length,
                                  input bit[`AMBA_SEQUENCE_AXI_BURST_PORT_WIDTH - 1:0] burst_type,
                                  input bit[`AMBA_SEQUENCE_AXI_SIZE_PORT_WIDTH - 1:0] size,
                                  input logic[`AMBA_SEQUENCE_AXI_RESP_PORT_WIDTH - 1:0] expect_resp,
                                  input logic[`AMBA_SEQUENCE_AXI_ARPROT_PORT_WIDTH - 1:0] prot = 0,
                                  input bit [`AMBA_SEQUENCE_AXI_MASTER_ID_PORT_WIDTH - 1:0] id = -1);

int success;
axi_xaction trans;
uvm_sequence_item trans_item;
trans = axi_xaction::type_id::create("trans");
uvm_create_on(trans, sqr)

trans.reasonable_enXferSize.constraint_mode(0);
success = trans.randomize with {
    trans.m_bvAddr == address;
    trans.m_enXactLength == burst_length;
    trans.m_enXferSize == size;
    trans.m_enXactBurst == burst_type;
    trans.m_enXactDir == axi_dec::DIR_READ;
    trans.m_enXactProt == prot;
    trans.m_enXactLock == axi_dec::NORMAL;
};
trans.m_enReadExp = 1;
foreach(trans.m_envReadExpResp[i]) begin
    trans.m_envReadExpResp[i] = axi_dec::axi_resp_type_enum'(expect_resp);
end

if(id != -1) begin
    trans.m_bvAid = id;
end

trans.seq_need_resp = 1;
`uvm_send(trans);

get_response(req, trans.get_transaction_id); 
if(!$cast(trans, req)) begin
    `uvm_fatal(get_type_name(), "axi_decode_write(): req is not a axi_xaction type or its extension");
end

data = new[trans.m_bvvData.size()];
foreach(trans.m_bvvData[i]) begin
    data[i] = trans.m_bvvData[i];
end

endtask：axi_burst_read

// axi_burst_write,transmit addr/data/aid/burst_type/burst_length/burst_size/prot and expect_resp
// -----------------------------------------------------------------------------------------------
task axi_sequence::axi_burst_write(input  uvm_sequencer #(uvm_sequence_item)     sqr,
                                   input bit[`AMBA_SEQUENCE_AXI_ADDR_PORT_WIDTH - 1:0] address,
                                   input bit[`AMBA_SEQUENCE_AXI_DATA_PORT_WIDTH - 1:0] data[],
                                   input bit [`AMBA_SEQUENCE_AXI_LEN_PORT_WIDTH - 1:0] burst_length,
                                   input bit[`AMBA_SEQUENCE_AXI_BURST_PORT_WIDTH - 1:0] burst_type,
                                   input bit[`AMBA_SEQUENCE_AXI_SIZE_PORT_WIDTH - 1:0] size,
                                   input logic[`AMBA_SEQUENCE_AXI_RESP_PORT_WIDTH - 1:0] expect_resp,
                                   input logic[`AMBA_SEQUENCE_AXI_AWPROT_PORT_WIDTH - 1:0] prot = 0,
                                   input bit [`AMBA_SEQUENCE_AXI_MASTER_ID_PORT_WIDTH - 1:0] id   = -1);

int success ;
axi_xaction trans;
uvm_sequence_item trans_item;
trans = axi_xaction::type_id::create("trans");
uvm_create_on(trans, sqr)

success = trans.randomize with {
    trans.m_bvAddr      == address;
    trans.m_enXactLength == burst_length;
    trans.m_enXferSize  == size;
    trans.m_enXactBurst == burst_type;
    trans.m_enXactDir   == axi_dec::DIR_WRITE;
    trans.m_enXactProt  == prot;
    trans.m_enXactLock  == axi_dec::NORMAL;
};
trans.m_enReadExp = 1;
trans.m_envReadExpResp[0] = axi_dec::axi_resp_type_enum'(expect_resp);
foreach(data[i]) begin
    trans.m_bvvData[i] = data[i];
end

if(id != -1) begin
    trans.m_bvAid   = id;
end

trans.seq_need_resp   = 1;
//the wstrb is all ones
wstrb_const_allones(size,trans.m_bvvWstrb,trans.m_enXactLength+1);
`uvm_send(trans);

get_response(req,trans.get_transaction_id); 
if(!$cast(trans,req)) begin
    `uvm_fatal(get_type_name(), "axi_decode_write(): req is not a axi_xaction type or its extension");
end

endtask:axi_burst_write

// axi_write,transmit addr/data/aid/burst_type/burst_length/burst size and other signals,with expect_resp
task axi_sequence::axi_write(input uvm_sequencer #(uvm_sequence_item) sqr,
    input bit [`AMBA_SEQUENCE_AXI_MASTER_ID_PORT_WIDTH - 1:0] id,
    input bit [`AMBA_SEQUENCE_AXI_BURST_PORT_WIDTH - 1:0] burst,
    input bit [`AMBA_SEQUENCE_AXI_LEN_PORT_WIDTH - 1:0] length,
    input bit [`AMBA_SEQUENCE_AXI_SIZE_PORT_WIDTH - 1:0] size,
    input bit [`AMBA_SEQUENCE_AXI_ADDR_PORT_WIDTH - 1:0] address,
    input bit [`AMBA_SEQUENCE_AXI_CACHE_PORT_WIDTH - 1:0] cache,
    input bit [`AMBA_SEQUENCE_AXI_AWPROT_PORT_WIDTH - 1:0] awprot,
    input bit [`AMBA_SEQUENCE_AXI_AWLOCK_PORT_WIDTH - 1:0] awlock,
    input bit [`AMBA_SEQUENCE_AXI_QOS_PORT_WIDTH - 1:0] qos,
    input bit [`AMBA_SEQUENCE_AXI_AUSER_PORT_WIDTH - 1:0] user,
    input bit [`AMBA_SEQUENCE_AXI_DATA_PORT_WIDTH - 1:0] data[],
    input bit [`AMBA_SEQUENCE_AXI_WSTRB_PORT_WIDTH - 1:0] strb[],
    input bit [`AMBA_SEQUENCE_AXI_RESP_PORT_WIDTH - 1:0] expect_resp = 2'b0,
    input bit care_resp = 1'b1
);

int success ;
axi_xaction trans;
uvm_sequence_item trans_item;
trans = axi_xaction::type_id::create("trans");

`uvm_create_on(trans, sqr)

trans.m_envResp.rand_mode(0);
trans.m_bvvData.rand_mode(0);
trans.m_bvvWstrb.rand_mode(0);
trans.valid_envResp.constraint_mode(0);
trans.reasonable_enXferSize.constraint_mode(0);
trans.reasonable_enXactCache.constraint_mode(0);
trans.reasonable_bvAid.constraint_mode(0);
trans.reasonable_bvvWstrb.constraint_mode(0);
trans.reasonable_bvvData.constraint_mode(0);
success = trans.randomize with {
    trans.m_enXactDir == axi_dec::DIR_WRITE;
    trans.m_bvAid == id;
    trans.m_enXactBurst == burst;
    trans.m_enXactLength== length;
    trans.m_enXferSize == size;
    trans.m_bvAddr == address;
    trans.m_enXactCache == cache;
    trans.m_enXactProt == awprot;
    trans.m_enXactLock == awlock;
    trans.m_bvQos == qos;
    trans.m_bvAuser == user;
};
trans.m_envResp = new[1];
trans.m_bvvData = new[length+1];
trans.m_bvvWstrb = new[length+1];

trans.m_enReadExp = care_resp;
trans.m_envReadExpResp[0] = axi_dec::axi_resp_type_enum'(expect_resp);
foreach(data[i]) begin
    trans.m_bvvData[i] = data[i];
end
foreach(strb[i]) begin
    trans.m_bvvWstrb[i] = strb[i] ;
end
trans.seq_need_resp = 1;
`uvm_send(trans);
get_response(req,trans.get_transaction_id); 
endtask:axi_write

// axi_read, transmit addr/aid/burst_type/burst_length/burst_size and other signals, with expect_resp
task axi_sequence::axi_read(input uvm_sequencer #(uvm_sequence_item) sqr,
                            input bit [AMBA_SEQUENCE_AXI_MASTER_ID_PORT_WIDTH - 1:0] id,
                            input bit [AMBA_SEQUENCE_AXI_BURST_PORT_WIDTH - 1:0] burst,
                            input bit [AMBA_SEQUENCE_AXI_LEN_PORT_WIDTH - 1:0] length,
                            input bit [AMBA_SEQUENCE_AXI_SIZE_PORT_WIDTH - 1:0] size,
                            input bit [AMBA_SEQUENCE_AXI_ADDR_PORT_WIDTH - 1:0] address,
                            input bit [AMBA_SEQUENCE_AXI_CACHE_PORT_WIDTH - 1:0] cache,
                            input bit [AMBA_SEQUENCE_AXI_ARPROT_PORT_WIDTH - 1:0] arprot,
                            input bit [AMBA_SEQUENCE_AXI_ARLOCK_PORT_WIDTH - 1:0] arlock,
                            input bit [AMBA_SEQUENCE_AXI_QOS_PORT_WIDTH - 1:0] qos,
                            input bit [AMBA_SEQUENCE_AXI_AUSER_PORT_WIDTH - 1:0] user,
                            output bit [AMBA_SEQUENCE_AXI_DATA_PORT_WIDTH - 1:0] data[],
                            input bit [AMBA_SEQUENCE_AXI_RESP_PORT_WIDTH - 1:0] expect_resp = 2'b0,
                            input bit care_resp = 1'b1
                           );

int success;
axi_xaction trans;
uvm_sequence_item trans_item;
trans = axi_xaction::type_id::create("trans");

`uvm_create_on(trans, sqr)

trans.m_envResp.rand_mode(0);
trans.m_bvvData.rand_mode(0);
trans.m_bvvWstrb.rand_mode(0);
trans.valid_envResp.constraint_mode(0);
trans.reasonable_enXferSize.constraint_mode(0);
trans.reasonable_enExactCache.constraint_mode(0);
trans.reasonable_bvAid.constraint_mode(0);
trans.reasonable_bvvWstrb.constraint_mode(0);
trans.reasonable_bvvData.constraint_mode(0);
success = trans.randomize with {
    trans.m_enXactDir == axi_dec::DIR_READ;
    trans.m_bvAid == id;
    trans.m_enXactBurst == burst;
    trans.m_enXactLength == length;
    trans.m_enXferSize == size;
    trans.m_bvAddr == address;
    trans.m_enXactCache == cache;
    trans.m_enXactProt == arprot;
    trans.m_enXactLock == arlock;
    trans.m_bvQos == qos;
    trans.m_bvAuser == user;
};
trans.m_envResp = new[length+1];
trans.m_bvvData = new[length+1];
trans.m_bvvWstrb = new[length+1];

trans.m_enReadExp = care_resp;
foreach(trans.m_envReadExpResp[i]) begin
    trans.m_envReadExpResp[i] = axi_dec::axi_resp_type_enum'(expect_resp);
end
trans.seq_need_resp = 1;
`uvm_send(trans);
get_response(req,trans.get_transaction_id); 

data = new[trans.m_bvvData.size()];
foreach(trans.m_bvvData[i]) begin
    data[i] = trans.m_bvvData[i];
end
endtask:axi_read


function void axi_sequence::wstrb_const_allones(bit[ AMBA_SEQUENCE_AXI_SIZE_PORT_WIDTH - 1:0] size, ref bit [AMBA_SEQUENCE_AXI_WSTRB_PORT_WIDTH - 1:0] wstrb[], input int len);
    for(int index=0;index<len;index++) begin
        if (size == 0) begin
            wstrb[index] = 128'h1;
        end
        if (size == 1) begin
            wstrb[index] = 128'h3;
        end
        if (size == 2) begin
            wstrb[index] = 128'hF;
        end
        if (size == 3) begin
            wstrb[index] = 128'hFF;
        end
        if (size == 4) begin
            wstrb[index] = 128'hFFFF;
        end
        if (size == 5) begin
            wstrb[index] = 128'hFFFFFFFF;
        end
        if (size == 6) begin
            wstrb[index] = 128'hFFFFFFFF_FFFFFFFF;
        end
        if (size == 7) begin
            wstrb[index] = 128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF;
        end
    end
endfunction : wstrb_const_allones
