#ifndef AXI2AXI_RM__SV
#define AXI2AXI_RM__SV
#define FULL_ADDR 64'hffff_ffff_ffff_ffff

//***********************************************************class axi2axi_rm*****************************************//
class axi2axi_rm extends stb_function_component #(2, 2);

`uvm_component_utils begin(axi2axi_rm)
`uvm_component_utils_end

extern function new(string	name,
                    uvm component	parent
                   );

extern virtual function void build_phase(uvm_phase phase);

extern virtual task run_phase(uvm_phase phase);

extern virtual task axi_xaction_0_process();
extern virtual task axi_xaction_1 process();

extern function strb_change(input [127:0] wstrb, input [31:0] size, output [127:0] strb);

endclass: axi2axi_rm
//**********************************************************************************************************************//

//****************************************************function new******************************************************//
  
function axi2axi_rm::new(string	name,
                         uvm_component parent
                        );
  super.new(name, parent);
endfunction: new

//************************************************function build_phase****************************************************//
  
function void axi2axi_rm::build phase(uvm phase phase);
    super.build phase(phase);
endfunction: build phase

//****************************************************task run_phase******************************************************//
  
task axi2axi_rm::run phase(uvm_phase phase);
   super.run_phase(phase);
   `uvm_info(get_type_name(), $sformatf("begin the RM"), UVM HIGH);
   fork
       axi_xaction_0_process();
       axi_xaction_1_process();
   join none
endtask: run phase

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
      `uvm_info(get_type_name(), $sformatf("this is an AXI TRANSACTION from master"), UVM HIGH);	
      `uvm_info(get_type_name(), $sformatf("print transaction from master at rm \n%s", axi_xaction_in.sprint()), UVM DEBUG);	
      
      if (axi_xaction_in.m_enXactDir == axi_dec::DIR_WRITE) begin
         `uvm_info(get_type_name(), $sformatf("print the length = %0d & size = %0d from master", axi_xaction_in.m_enXactLength, axi_xaction_in.m_enXferSize), UVM HIGH);
         case (axi_xaction_in.m_enXactBurst)
            axi_dec::BURST_INCR:
                begin // INCR burst
                
                end
           axi_dec::BURST FIXED:
             begin // FIXED burst

             end
          axi_dec::BURST WRAP:	
             begin // WRAP burst
               `uvm_info(get_type_name(), $sformatf("print the length = %0d", axi_xaction_in.m_enXactLength), UVM HIGH);
             end
          endcase
      end  //if
      else if (axi_xaction_in.m_enXactDir == axi_dec::DIR_READ) begin
        case (axi_xaction_in.m_enXactBurst)
               axi_dec::BURST INCR:
                 begin              // INCR burst

                 end
               axi_dec::BURST FIXED:
                 begin             // FIXED burst

                 end
               axi dec::BURST WRAP:
                 begin // WRAP burst

                 end
               default : 
                 begin
                   `uvm_info(get_type_name(), $sformatf("this is a reserved burst type"), UVM_HIGH);
                end
          endcase
       end  //else if

      `uvm_info(get_type_name(), $sformatf("send the rm transaction from AXI MASTER to CHECKER\n"), UVM HIGH);
      #20ns;
      this.out_port[0].put(rm_out_tr);	 // Put rm handled transaction to port

    end //while (1)
join_none
  
endtask::axi_xaction_0_process



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
      `uvm_info(get_type_name(), $sformatf("this is an AXI TRANSACTION from slave"), UVM HIGH);	
      `uvm_info(get_type_name(), $sformatf("print transaction from slave at rm \n%s", axi_xaction_in.sprint()), UVM DEBUG);	
      
      if (axi_xaction_in.m_enXactDir == axi_dec::DIR_WRITE) begin
        `uvm_info(get_type_name(), $sformatf("print the length = %0d & size = %0d from slave", axi_xaction_in.m_enXactLength, axi_xaction_in.m_enXferSize), UVM HIGH);
         case (axi_xaction_in.m_enXactBurst)
            axi_dec::BURST_INCR:
                begin // INCR burst
                
                end
           axi_dec::BURST FIXED:
             begin // FIXED burst

             end
          axi_dec::BURST WRAP:	
             begin // WRAP burst
               `uvm_info(get_type_name(), $sformatf("print the length = %0d", axi_xaction_in.m_enXactLength), UVM HIGH);
             end
          endcase
      end  //if
      else if (axi_xaction_in.m_enXactDir == axi_dec::DIR_READ) begin
        case (axi_xaction_in.m_enXactBurst)
               axi_dec::BURST INCR:
                 begin              // INCR burst

                 end
               axi_dec::BURST FIXED:
                 begin             // FIXED burst

                 end
               axi dec::BURST WRAP:
                 begin // WRAP burst

                 end
               default : 
                 begin
                   `uvm_info(get_type_name(), $sformatf("this is a reserved burst type"), UVM_HIGH);
                end
          endcase
       end  //else if

      `uvm_info(get_type_name(), $sformatf("send the rm transaction from AXI MASTER to CHECKER\n"), UVM HIGH);
      //#20ns;
      this.out_port[0].put(rm_out_tr);	 // Put rm handled transaction to port

    end //while (1)
join_none
  
endtask::axi_xaction_1_process

`endif








































  
