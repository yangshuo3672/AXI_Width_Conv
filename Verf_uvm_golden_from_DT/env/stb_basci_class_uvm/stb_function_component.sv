class stb_function_component #(int IN_PORT_NUM = 0, int OUT_PORT_NUM = 0) extends uvm_component;
    `uvm_component_param_utils(stb_function_component #(IN_PORT_NUM, OUT_PORT_NUM))

    uvm_reg_block reg_model;                    /// The Register Model
    uvm_blocking_peek_port #(uvm_sequence_item) in_port[IN_PORT_NUM - 1 : 0];   /// The input port of function
    uvm_blocking_put_port #(uvm_sequence_item) out_port[OUT_PORT_NUM - 1 : 0];  /// The output port of function

    /** \brief Constructor
        Call super.new();
    */
    extern function new(string name, uvm_component parent);

    /** \brief build_phase
        Calls super.build_phase(phase) to enable automatic get config and create object
    */
    extern virtual function void build_phase(uvm_phase phase);

endclass: stb_function_component

function stb_function_component::new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), "new(): stb_function_component has been constructed", UVM_HIGH);
endfunction: new

function void stb_function_component::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (IN_PORT_NUM > 0) begin
        foreach(this.in_port[i]) begin
            if (this.in_port[i] == null) begin
                this.in_port[i] = new($sformatf("in_port[%0d]", i), this);
                `uvm_info(get_type_name(), $sformatf("build_phase(): in_port[%0d] new instance is internally allocated", i), UVM_MEDIUM);
            end
        end
    end

    if (OUT_PORT_NUM > 0) begin
        foreach(this.out_port[i]) begin
            if (this.out_port[i] == null) begin
                this.out_port[i] = new($sformatf("out_port[%0d]", i), this);
                `uvm_info(get_type_name(), $sformatf("build_phase(): out_port[%0d] new instance is internally allocated", i), UVM_MEDIUM);
            end
        end
    end
    `uvm_info(get_type_name(), "build_phase(): stb_function_component build_phase is done", UVM_HIGH);
endfunction: build_phase
