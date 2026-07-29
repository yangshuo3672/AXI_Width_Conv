`ifndef AXI2AXI_RM__SV
`define AXI2AXI_RM__SV
`define FULL_ADDR 64'hffff_ffff_ffff_ffff

//Reference Model:Complete handing data from monitor port,and then send to checker

//***********************************************************class axi2axi_rm*****************************************//
class axi2axi_rm extends stb_function_component #(2, 2);

// Define the member variables base on project requirement
//Coding begin
//%%%%%%%%%%%%%%%%%%%%%%%%
//Coding end
// rand int pkt_len; // Define the packet length

//uvm_component_utils_** 宏： UVM的component注册宏，用于注册component到factory
//uvm_field_** 宏: 一般用于把成员变量加入到field automation,提供的作用有copy compare print pack unpack record
/*
uvm_field_int(var, FLAG)	注册整型变量
uvm_field_real(var, FLAG)	注册 real 类型
uvm_field_string(var, FLAG)	注册字符串
uvm_field_enum(T, var, FLAG)	注册枚举
uvm_field_object(var, FLAG)	注册 UVM object 句柄
uvm_field_array_int(var, FLAG)	注册动态整型数组
uvm_field_queue_int(var, FLAG)	注册整型队列
uvm_field_sarray_int(var, FLAG)	注册静态数组
注册后，UVM会自动为这些变量提供copy() compare() print() pack()/unpack() record() clone()（object才有）等功能，配合uvm_config_db#(T)::set/get，这些字段也可以参与配置自动化。
*/
`uvm_component_utils_begin(axi2axi_rm)
// Add variables into field-automation base on project requirement
//Coding begin
//%%%%%%%%%%%%%%%%%%%%%
//Coding end
`uvm_component_utils_end

//extern: 占位符或预告，告诉编译器，这个函数的具体代码不在这里，在类的外面或者另一个文件
//function new：构造类的函数，当这个类被实例化(创建对象)时，new函数会自动执行，用于给对象的变量赋初值
//string name：名称参数，代表这个组件在UVM层次结构树中的实例名称，比如rm env agent等
//uvm_component parent:父级参数，UVM组件句柄，代表这个组件的上一层父组件（比如可以把agent的parent设为env）
//这是组件（component）与对象（object）的核心区别—————只有组件有这个parent用于构建树形结构，实现配置传递（config_db）和报告（report）层次
extern function new(string	name,
                    uvm_component	parent
                   );

extern virtual function void build_phase(uvm_phase phase); //Calls super.build_phase(phase) to enable automatic get config and create object
extern virtual task run_phase(uvm_phase phase);//Components implement behavior that is exhibited for the entire run-time,across the various run-time phases 

//axi_xaction processing threas
extern virtual task axi_xaction_0_process();
extern virtual task axi_xaction_1_process();

extern function strb_change(input [127:0] wstrb, input [31:0] size, output [127:0] strb);
  
//Define the function or task base on project requirement
//Coding begin
//%%%%%%%%%%%%%%%%%%%%%  
//Coding end

endclass: axi2axi_rm
//**********************************************************************************************************************//

//****************************************************function new******************************************************//

//类的外部实现定义，真正的函数体。
//调用父类构造函数，再进行成员变量初始化
function axi2axi_rm::new(string	name,
                         uvm_component parent
                        );
  super.new(name, parent);
endfunction: new

//************************************************function build_phase****************************************************//
//只调用了父类build_phase
function void axi2axi_rm::build_phase(uvm phase phase);
    super.build phase(phase);
endfunction: build_phase

//****************************************************task run_phase******************************************************//

task axi2axi_rm::run_phase(uvm_phase phase);
   super.run_phase(phase);
   `uvm_info(get_type_name(), $sformatf("begin the RM"), UVM HIGH);
   fork
       axi_xaction_0_process();
       axi_xaction_1_process();
   join none
endtask: run_phase

//**********************************************task axi_xaction_0_process**************************************************// 
 
task axi2axi_rm::axi_xaction_0_process();
    
    uvm_sequence_item   axi_in_tr;
    axi_xaction	        axi_xaction_in;	    ///< Rm input transaction
    dummy_xaction 	    rm_out_tr;	        ///< Rm output transaction

  bit [63:0]	   w_addr_q[$];
  bit	[7:0]	     w_data_q[$];
  bit	[163:0]	   r_addr_q[$];
  bit	[7:0]	     r_data_q[$];
  bit	[1023:0]   w_data;
  bit	[1023:0]   r_data;
  bit	[63:0]	   alian_addr;
  bit	[63:0]	   wrap_addr;
  bit	[63:0]	   start_addr;
  bit	[63:0]	   end_addr;
  bit	[127:0]	   c_wstrb;
  bit	           valid_mask;
    //fork
 fork
    while(1) begin
       `uvm_info(get_type_name(),$sformatf("print the RM INPORT NUM 0"), UVM_HIGH);
       
      this.in_port[0].get(axi_in_tr);       // Get rm input transaction from port;
    
    	rm_out_tr = dummy_xaction::type_id::create();
    
      if(!$cast(axi_xaction_in, axi_in_tr)) begin
        `uvm_fatal(get_type_name(), "axi_xaction_0_process:rm received packet is not a axi_xaction type or its extension");
      end
      
      //Add process to handle rm input transaction(from monitor to rm). base on project requirement	
      //Coding begin
      //%%%%%%%%%%%%%%%%%%
      //....................
      `uvm_info(get_type_name(), $sformatf("this is an AXI TRANSACTION from master"), UVM_HIGH);	
      `uvm_info(get_type_name(), $sformatf("print transaction from master at rm \n%s", axi_xaction_in.sprint()), UVM_DEBUG);	
      
      if (axi_xaction_in.m_enXactDir == axi_dec::DIR_WRITE) begin
        `uvm_info(get_type_name(), $sformatf("print the length = %0d & size = %0d from master", axi_xaction_in.m_enXactLength, axi_xaction_in.m_enXferSize), UVM_HIGH);
         case (axi_xaction_in.m_enXactBurst)
            axi_dec::BURST_INCR:
                begin // INCR burst
                
                end
           axi_dec::BURST FIXED:
             begin // FIXED burst

             end
          axi_dec::BURST WRAP:	
             begin // WRAP burst
               `uvm_info(get_type_name(), $sformatf("print the length = %0d", axi_xaction_in.m_enXactLength), UVM_HIGH);
             end
          endcase
      end  //if
      else if (axi_xaction_in.m_enXactDir == axi_dec::DIR_READ) begin
        case (axi_xaction_in.m_enXactBurst)
               axi_dec::BURST_INCR:
                 begin              // INCR burst

                 end
               axi_dec::BURST_FIXED:
                 begin             // FIXED burst

                 end
               axi dec::BURST_WRAP:
                 begin // WRAP burst

                 end
               default : 
                 begin
                   `uvm_info(get_type_name(), $sformatf("this is a reserved burst type"), UVM_HIGH);
                end
          endcase
       end  //else if
      
      //Coding end
      `uvm_info(get_type_name(), $sformatf("send the rm transaction from AXI MASTER to CHECKER\n"), UVM_HIGH);
      #20ns;
      this.out_port[0].put(rm_out_tr);	 // Put rm handled transaction to port
      //Coding end
    end //while (1)
join_none
  
endtask:axi_xaction_0_process



//**********************************************task axi_xaction_1_process**************************************************// 
 
task axi2axi_rm::axi_xaction_1_process();
    
    uvm_sequence_item   axi_in_tr;
    axi_xaction	        axi_xaction_in;	    ///< Rm input transaction
    dummy_xaction 	    rm_out_tr;	        ///< Rm output transaction

  bit [63:0]	   w_addr_q[$];
  bit	[7:0]	     w_data_q[$];
  bit	[163:0]	   r_addr_q[$];
  bit	[7:0]	     r_data_q[$];
  bit	[1023:0]   w_data;
  bit	[1023:0]   r_data;
  bit	[63:0]	   alian_addr;
  bit	[63:0]	   wrap_addr;
  bit	[63:0]	   start_addr;
  bit	[63:0]	   end_addr;
  bit	[127:0]	   c_wstrb;
  bit	           valid_mask;
    //fork
 fork
    while(1) begin
       //`uvm_info(get_type_name(),$sformatf("print the RM INPORT NUM 0"), UVM_HIGH);
       
      this.in_port[1].get(axi_in_tr);       // Get rm input transaction from port;
      
      `uvm_info(get_type_name(),$sformatf("print the RM INPORT NUM 1"), UVM_HIGH);
      
    	rm_out_tr = dummy_xaction::type_id::create();
    
      if(!$cast(axi_xaction_in, axi_in_tr)) begin
        `uvm_fatal(get_type_name(), "axi_xaction_1_process:rm received packet is not a axi_xaction type or its extension");
      end
      
      //Add process to handle rm input transaction(from monitor to rm). base on project requirement	
      //Coding begin
      //%%%%%%%%%%%%%%%%%%%%%
      //.....................
      `uvm_info(get_type_name(), $sformatf("this is an AXI TRANSACTION from slave"), UVM HIGH);	
      `uvm_info(get_type_name(), $sformatf("print transaction from slave at rm \n%s", axi_xaction_in.sprint()), UVM_DEBUG);	
      
      if (axi_xaction_in.m_enXactDir == axi_dec::DIR_WRITE) begin
        `uvm_info(get_type_name(), $sformatf("print the length = %0d & size = %0d from slave", axi_xaction_in.m_enXactLength, axi_xaction_in.m_enXferSize), UVM_HIGH);
         case (axi_xaction_in.m_enXactBurst)
            axi_dec::BURST_INCR:
                begin // INCR burst
                
                end
           axi_dec::BURST FIXED:
             begin // FIXED burst

             end
          axi_dec::BURST WRAP:	
             begin // WRAP burst
               `uvm_info(get_type_name(), $sformatf("print the length = %0d", axi_xaction_in.m_enXactLength), UVM_HIGH);
             end
          endcase
      end  //if
      else if (axi_xaction_in.m_enXactDir == axi_dec::DIR_READ) begin
        case (axi_xaction_in.m_enXactBurst)
               axi_dec::BURST_INCR:
                 begin              // INCR burst

                 end
               axi_dec::BURST_FIXED:
                 begin             // FIXED burst

                 end
               axi dec::BURST_WRAP:
                 begin // WRAP burst

                 end
               default : 
                 begin
                   `uvm_info(get_type_name(), $sformatf("this is a reserved burst type"), UVM_HIGH);
                end
          endcase
       end  //else if
      //Coding end
      `uvm_info(get_type_name(), $sformatf("send the rm transaction from AXI MASTER to CHECKER\n"), UVM_HIGH);
      //#20ns;
      this.out_port[1].put(rm_out_tr);	 // Put rm handled transaction to port
      //Coding end
    end //while (1)
join_none
  
endtask:axi_xaction_1_process

`endif








































  
