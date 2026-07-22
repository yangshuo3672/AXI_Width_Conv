`idndef AXI2AXI_ENV_DEC__SV
`define AXI2AXI_ENV_DEC__SV

class axi2axi_env_dec extends linkbench_env_dec;
  
  parameter AXI_MST_NUM =1;
  parameter AXI_SLV_NUM =1;
  parameter APB_MST_NUM =1;
  
endclass:axi2axi_env_dec

`endif
