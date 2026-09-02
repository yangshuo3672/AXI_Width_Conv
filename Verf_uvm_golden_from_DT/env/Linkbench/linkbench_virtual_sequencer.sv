
class linkbench_virtual_sequencer #(type T = linkbench_env_dec) extends uvm_sequencer;

    typedef linkbench_virtual_sequencer #(T) this_type;

    `uvm_component_param_utils(this_type)

    uvm_sequencer#(uvm_sequence_item) ahb_mst_sqr[T::AHB_MST_NUM];  // User can modify the sequencer
    uvm_sequencer#(uvm_sequence_item) apb_mst_sqr[T::APB_MST_NUM];  // User can modify the sequencer
    uvm_sequencer#(uvm_sequence_item) axi_mst_sqr[T::AXI_MST_NUM];  // User can modify the sequencer

    extern function new(string name = "linkbench_virtual_sequencer", uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);

endclass

function linkbench_virtual_sequencer::new(string name = "linkbench_virtual_sequencer", uvm_component parent);

    super.new(name, parent);

endfunction: new

function void linkbench_virtual_sequencer::build_phase(uvm_phase phase);

    super.build_phase(phase);

endfunction: build_phase

