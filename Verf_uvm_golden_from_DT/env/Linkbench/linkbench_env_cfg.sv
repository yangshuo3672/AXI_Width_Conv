class linkbench_env_cfg #(type T = linkbench_env_dec) extends uvm_object;

   typedef linkbench_env_cfg #(T) this_type;

   bit                            ahb_mst_if_agent_sw[];           ///!< Switch of ahb_if_agent
   bit                            apb_mst_if_agent_sw[];           ///!< Switch of apb_if_agent
   bit                            axi_mst_if_agent_sw[];           ///!< Switch of axi_if_agent
   stb_dec::interface_agent_work_mode_e  ahb_mst_if_agent_work_mode[]; ///!< The ahb_if_agent work mode
   stb_dec::interface_agent_work_mode_e  apb_mst_if_agent_work_mode[]; ///!< The apb_if_agent work mode
   stb_dec::interface_agent_work_mode_e  axi_mst_if_agent_work_mode[]; ///!< The axi_if_agent work mode
   rand ahb_interface_agent_cfg     ahb_mst_if_agent_cfg[];         ///!< The ahb_if_agent driver configure
   rand apb_interface_agent_cfg     apb_mst_if_agent_cfg[];         ///!< The apb_if_agent driver configure
   rand axi_interface_agent_cfg     axi_mst_if_agent_cfg[];         ///!< The axi_if_agent driver configure

   bit                            ahb_slv_if_agent_sw[];           ///!< Switch of ahb_if_agent
   bit                            apb_slv_if_agent_sw[];           ///!< Switch of apb_if_agent
   bit                            axi_slv_if_agent_sw[];           ///!< Switch of axi_if_agent
   stb_dec::interface_agent_work_mode_e  ahb_slv_if_agent_work_mode[]; ///!< The ahb_if_agent work mode
   stb_dec::interface_agent_work_mode_e  apb_slv_if_agent_work_mode[]; ///!< The apb_if_agent work mode
   stb_dec::interface_agent_work_mode_e  axi_slv_if_agent_work_mode[]; ///!< The axi_if_agent work mode
   rand ahb_interface_agent_cfg     ahb_slv_if_agent_cfg[];         ///!< The ahb_if_agent driver configure
   rand apb_interface_agent_cfg     apb_slv_if_agent_cfg[];         ///!< The apb_if_agent driver configure
   rand axi_interface_agent_cfg     axi_slv_if_agent_cfg[];         ///!< The axi_if_agent driver configure

   stb_dec::verf_env_scene_e        env_scene = stb_dec::FOR_BT;    ///!< Define for manage verification environment code
                                                                   ///!< This variable can be changed in gen_cfg phase in env

   //-------------------------------------------------------------------------------//
   // Declare the variables base on project requirement.                         //
   //-------------------------------------------------------------------------------//
   //-------------------------------------------------------------------------------//Coding begin-----------------------------------------//
   // rand int post_consent;
   // rand int sim_timeout;
   //-------------------------------------------------------------------------------//Coding end-----------------------------------------//

   //-------------------------------------------------------------------------------//
   // Declare variables constraints base on project requirement                  //
   //-------------------------------------------------------------------------------//
   //-------------------------------------------------------------------------------//Coding begin-----------------------------------------//
   // constraint post_consent_cons;
   // constraint sim_timeout_cons;
   //-------------------------------------------------------------------------------//Coding end-----------------------------------------//

   `uvm_object_param_utils_begin(this_type)
   //###########################################################################
// Add variables into field-automation base on project requirement 
//###########################################################################
//----------------------------Coding begin-------------------------------//

`uvm_field_array_object(ahb_mst_if_agent_cfg, UVM_ALL_ON)
`uvm_field_array_int(ahb_mst_if_agent_sw, UVM_ALL_ON)
`uvm_field_array_enum(stb_dec::interface_agent_work_mode_e, ahb_mst_if_agent_work_mode, UVM_ALL_ON)
`uvm_field_array_object(apb_mst_if_agent_cfg, UVM_ALL_ON)
`uvm_field_array_int(apb_mst_if_agent_sw, UVM_ALL_ON)
`uvm_field_array_enum(stb_dec::interface_agent_work_mode_e, apb_mst_if_agent_work_mode, UVM_ALL_ON)
`uvm_field_array_object(axi_mst_if_agent_cfg, UVM_ALL_ON)
`uvm_field_array_int(axi_mst_if_agent_sw, UVM_ALL_ON)
`uvm_field_array_enum(stb_dec::interface_agent_work_mode_e, axi_mst_if_agent_work_mode, UVM_ALL_ON)

`uvm_field_array_object(ahb_slv_if_agent_cfg, UVM_ALL_ON)
`uvm_field_array_int(ahb_slv_if_agent_sw, UVM_ALL_ON)
`uvm_field_array_enum(stb_dec::interface_agent_work_mode_e, ahb_slv_if_agent_work_mode, UVM_ALL_ON)
`uvm_field_array_object(apb_slv_if_agent_cfg, UVM_ALL_ON)
`uvm_field_array_int(apb_slv_if_agent_sw, UVM_ALL_ON)
`uvm_field_array_enum(stb_dec::interface_agent_work_mode_e, apb_slv_if_agent_work_mode, UVM_ALL_ON)
`uvm_field_array_object(axi_slv_if_agent_cfg, UVM_ALL_ON)
`uvm_field_array_int(axi_slv_if_agent_sw, UVM_ALL_ON)
`uvm_field_array_enum(stb_dec::interface_agent_work_mode_e, axi_slv_if_agent_work_mode, UVM_ALL_ON)

`uvm_field_enum(stb_dec::verf_env_scene_e, env_scene, UVM_ALL_ON)

//----------------------------Coding end-------------------------------//
`uvm_object_utils_end

/** \brief new()
Constructor
*/
extern function new(string name = "linkbench_env_cfg");

/** \brief pre_randomize()
Handle random data information before randomize
*/
extern function void pre_randomize();

/** \brief post_randomize()
Handle random data information after randomize
*/
extern function void post_randomize();
  
endclass：linkbench_env_cfg

function linkbench_env_cfg::new(string name = "linkbench_env_cfg");

    super.new(name);

    ahb_mst_if_agent_sw              = new[T::AHB_MST_NUM];
    apb_mst_if_agent_sw              = new[T::APB_MST_NUM];
    axi_mst_if_agent_sw              = new[T::AXI_MST_NUM];
    ahb_mst_if_agent_work_mode       = new[T::AHB_MST_NUM];
    apb_mst_if_agent_work_mode       = new[T::APB_MST_NUM];
    axi_mst_if_agent_work_mode       = new[T::AXI_MST_NUM];
    ahb_mst_if_agent_cfg             = new[T::AHB_MST_NUM];
    apb_mst_if_agent_cfg             = new[T::APB_MST_NUM];
    axi_mst_if_agent_cfg             = new[T::AXI_MST_NUM];

    ahb_slv_if_agent_sw              = new[T::AHB_SLV_NUM];
    apb_slv_if_agent_sw              = new[T::APB_SLV_NUM];
    axi_slv_if_agent_sw              = new[T::AXI_SLV_NUM];
    ahb_slv_if_agent_work_mode       = new[T::AHB_SLV_NUM];
    apb_slv_if_agent_work_mode       = new[T::APB_SLV_NUM];
    axi_slv_if_agent_work_mode       = new[T::AXI_SLV_NUM];
    ahb_slv_if_agent_cfg             = new[T::AHB_SLV_NUM];
    apb_slv_if_agent_cfg             = new[T::APB_SLV_NUM];
    axi_slv_if_agent_cfg             = new[T::AXI_SLV_NUM];

    foreach (axi_mst_if_agent_work_mode[i])
        this.axi_mst_if_agent_work_mode[i] = stb_dec::MASTER;
    foreach (axi_slv_if_agent_work_mode[i])
        this.axi_slv_if_agent_work_mode[i] = stb_dec::SLAVE;

    foreach (ahb_mst_if_agent_work_mode[i])                      //AHB mst/SLV
        this.ahb_mst_if_agent_work_mode[i] = stb_dec::MASTER;
    foreach(ahb_slv_if_agent_work_mode[i])
        this.ahb_slv_if_agent_work_mode[i] = stb_dec::SLAVE;

    foreach (apb_mst_if_agent_work_mode[i])                      //APB mst/SLV
        this.apb_mst_if_agent_work_mode[i] = stb_dec::MASTER;
    foreach (apb_slv_if_agent_work_mode[i])                      //APB mst/SLV
        this.apb_slv_if_agent_work_mode[i] = stb_dec::SLAVE;

    foreach (apb_mst_if_agent_sw[i])                             //APB mst/SLV
        this.apb_mst_if_agent_sw[i] = stb_dec::OFF;
    foreach (ahb_mst_if_agent_sw[i])                             //APB mst/SLV
        this.ahb_mst_if_agent_sw[i] = stb_dec::OFF;
    foreach (axi_mst_if_agent_sw[i])                             //APB mst/SLV
        this.axi_mst_if_agent_sw[i] = stb_dec::ON;
    foreach (apb_slv_if_agent_sw[i])
    this.apb_slv_if_agent_sw[i] = stb_dec::OFF; //APB slv/SLV
foreach (ahb_slv_if_agent_sw[i])
    this.ahb_slv_if_agent_sw[i] = stb_dec::OFF; //APB slv/SLV
foreach (axi_slv_if_agent_sw[i])
    this.axi_slv_if_agent_sw[i] = stb_dec::ON; //APB slv/SLV

foreach (this.ahb_mst_if_agent_cfg[i]) begin
    this.ahb_mst_if_agent_cfg[i] = ahb_interface_agent_cfg::type_id::create($sformatf("ahb_mst_if_agent_cfg[%0d]", i));
end

foreach (this.apb_mst_if_agent_cfg[i]) begin
    this.apb_mst_if_agent_cfg[i] = apb_interface_agent_cfg::type_id::create($sformatf("apb_mst_if_agent_cfg[%0d]", i));
end

foreach (this.axi_mst_if_agent_cfg[i]) begin
    this.axi_mst_if_agent_cfg[i] = axi_interface_agent_cfg::type_id::create($sformatf("axi_mst_if_agent_cfg[%0d]", i));
end

foreach (this.ahb_slv_if_agent_cfg[i]) begin
    this.ahb_slv_if_agent_cfg[i] = ahb_interface_agent_cfg::type_id::create($sformatf("ahb_slv_if_agent_cfg[%0d]", i));
end

foreach (this.apb_slv_if_agent_cfg[i]) begin
    this.apb_slv_if_agent_cfg[i] = apb_interface_agent_cfg::type_id::create($sformatf("apb_slv_if_agent_cfg[%0d]", i));
end

foreach (this.axi_slv_if_agent_cfg[i]) begin
    this.axi_slv_if_agent_cfg[i] = axi_interface_agent_cfg::type_id::create($sformatf("axi_slv_if_agent_cfg[%0d]", i));
end
  
endfunction：new

  function void linkbench_env_cfg::pre_randomize();
    super.pre_randomize();
  endfunction:pre_randomize

    function void linkbench_env_cfg::post_randomize();
    super.post_randomize();
  endfunction:post_randomize
