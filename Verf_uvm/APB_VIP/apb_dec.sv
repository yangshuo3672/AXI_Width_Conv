
`ifndef APB_ADDR_WIDTH
`define APB_ADDR_WIDTH 32
`endif

`ifndef APB_DATA_WIDTH
`define APB_DATA_WIDTH 32
`endif

`ifndef APB_WSTRB_WIDTH
`define APB_WSTRB_WIDTH 4
`endif

`ifndef APB_AUSER_WIDTH
`define APB_AUSER_WIDTH 64
`endif

`ifndef APB_RUSER_WIDTH
`define APB_RUSER_WIDTH 64
`endif

`ifndef APB_WUSER_WIDTH
`define APB_WUSER_WIDTH 64
`endif

`ifndef APB_SETUP_TIME
`define APB_SETUP_TIME 0.1ns
`endif

`ifndef APB_HOLD_TIME
`define APB_HOLD_TIME 0.1ns
`endif

`define APB_MEM_WIDTH `APB_ADDR_WIDTH

`define APB_X_CHECK(signal_value,signal_name)
if((signal_value !== 'z)&&(^signal_value === 1'bx))
  `uvm_error(get_type_name(),$sformatf("%0s is X state when valid is asserted",signal_name));

package apb_dec
  typedef enum {READ,WRITE} apb_dir_enum;
endpackage:apb_dec
