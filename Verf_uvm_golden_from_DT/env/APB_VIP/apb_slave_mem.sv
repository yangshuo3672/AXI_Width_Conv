class apb_slave_mem extends uvm_object;
    `uvm_object_utils(apb_slave_mem)

    typedef bit [`APB_MEM_WIDTH-1:0] addr_t;
    logic [7:0] mem [addr_t] = '{default : 'hx};

    extern function new(string name ="apb_slave_mem");

    extern task set_mem(int stream_id, bit [`APB_MEM_WIDTH-1:0] addr,bit [`APB_DATA_WIDTH-1:0] data, bit[`APB_WSTRB_WIDTH-1:0] strb,int width=32);
    extern task get_mem(int stream_id, bit [`APB_MEM_WIDTH-1:0] addr, ref logic [`APB_DATA_WIDTH-1:0] data,input int width=32);

endclass : apb_slave_mem

function apb_slave_mem::new(string name="apb_slave_mem");
    super.new(name);
endfunction : new

task apb_slave_mem::set_mem(int stream_id, bit [`APB_MEM_WIDTH-1:0] addr, bit [`APB_DATA_WIDTH-1:0] data, bit[`APB_WSTRB_WIDTH-1:0] strb,int width=32);
    int i =0 ;
    for(i=0;i<(width/8);i++)begin
        if (strb[i]== 1'b1) begin
            mem[addr+i]=data[(i+1)*8 -1 -:8];
        end
    end
    `uvm_info(get_type_name(),$sformatf("Write Memory Address %0x,Data is %0x,Strb is %0x",addr,data,strb),UVM_HIGH);
endtask : set_mem

task apb_slave_mem::get_mem(int stream_id, bit [`APB_MEM_WIDTH-1:0] addr,ref logic [`APB_DATA_WIDTH-1:0] data,input int width =32);
    logic [7:0]  data_tmp[127:0];
    for(int i=0;i<(width/8);i++)begin
        if (!mem.exists(addr+i)) begin
            data_tmp[i] = $urandom_range(0, 255);
            mem[addr+i] = data_tmp[i] ;
        end
        else begin
            data_tmp[i] = mem[addr+i];
        end
    end
    for(int i=0;i<(width/8);i++)begin
        data[(i+1)*8-1 -:8] = data_tmp[i];
    end
    `uvm_info(get_type_name(),$sformatf("Read Memory Address %0x,Data is %0x",addr,data),UVM_HIGH);
endtask : get_mem

    /*
这段代码定义了一个名为 `apb_slave_mem` 的类，继承自 `uvm_object`。该类包含一个内存
数组 `mem`，以及两个外部任务 `set_mem` 和 `get_mem`，用于设置和获取内存中的数据。`set_mem` 任务根据地址和数据写入内存，
      而 `get_mem` 任务从内存中读取数据并返回。如果读取的地址不存在，则生成随机数据。
      */
