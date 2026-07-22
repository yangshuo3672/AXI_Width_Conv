#ifndef AXI2AXI_RM__SV
#define AXI2AXI_RM__SV
#define FULL_ADDR 64'hffff_ffff_ffff_ffff

22 class axi2axi rm extends stb function component #(2, 2);
23
24
25	26	// Define the member variables base on project requirement	三=
27	//	-Coding begin-
28	// rand int pkt len; // Define the packet length
29	//	--Coding end.	//-
30	uvm component utils begin(axi2axi_rm)
31
32	// Add variables into field-automation base on project requirement
33
34	//	-Coding begin-
35
36	-Coding end
37	uvm component utils end
38
39	/** \brief new
40	Constructor
41	*/
42	extern function new(string	name,
43	uvm component	parent
44
45
46	/** \brief build phase
47	Calls super.build phase(phase) to enable automatic get config and create object
48	/*
49	extern virtual function void build phase(uvm phase phase);
50
51	\brief run phase
52	Components implement behavior that is exhibited for the entire run-time, across the various run-time phases
53	/*
54	extern virtual task run phase(uvm phase phase);
55
56	\brief The axi xaction processing thread
57
58	extern virtual task axi xaction O process();
59	extern virtual task axi_xaction_1 process();
09
[9	extern function strb change(input [127:0] wstrb, input [31:0] size, output [127:0] strb);
62
63	//-
64	// Define the functions or task base on project requirement	//
65	// -
99	-Coding begin-	//-
67
68	Coding end-
69
70 endclass: axi2axi_rm
71
72 function axi2axi_rm::new(string	name,
总过	uvm component parent
