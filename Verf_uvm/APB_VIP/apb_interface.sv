interface apb_interface(input bit PClk,
                        input bit rst_n); //modify by DTS2019032808854

    logic [`APB_ADDR_WIDTH-1:0]   PAddr;
    logic                         PSel;
    logic [`APB_DATA_WIDTH-1:0]   PWData;
    logic [`APB_DATA_WIDTH-1:0]   PRData;
    logic                         PEnable;
    logic                         PWrite;
    logic                         PReady;
    logic                         PSlvErr;
    logic [2:0]                   PProt;
    logic [`APB_WSTRB_WIDTH-1:0]  PStrb;

    //add for DTS2018030809844
    logic [`APB_AUSER_WIDTH-1:0]  PAuser;
    logic [`APB_RUSER_WIDTH-1:0]  PRuser;
    logic [`APB_WUSER_WIDTH-1:0]  PWuser;
    //add for DTS2018110108555
    logic [`HISI_VIP_APB_QOS_PORT_WIDTH -1:0] PQos    ;
    logic [`HISI_VIP_APB_GRPID_PORT_WIDTH -1:0] PGrpid ;
    logic [`HISI_VIP_APB_VMID_PORT_WIDTH -1:0] PVmid  ;
    logic [`HISI_VIP_APB_MPUBYPASS_PORT_WIDTH -1:0] PMpubypass;
    logic [`HISI_VIP_APB_SNOOP_PORT_WIDTH -1:0] PSnoop ;
    logic [`HISI_VIP_APB_DOMAIN_PORT_WIDTH -1:0] PDomain ;

    clocking master_cb @(posedge PClk);
        default input #(`APB_SETUP_TIME) output #(`APB_HOLD_TIME);

    `ifndef ASYN_RESET_FUNC
        input rst_n;
    `endif

        output PAddr;
        output PSel;
        output PWData;
        input  PRData;
        output PEnable;
        output PWrite;
        input  PReady;
        input  PSlvErr;
        output PProt;
        output PStrb;
        output PAuser;
        output PWuser;
        input  PRuser;
        output PQos    ;
        output PGrpid  ;
        output PVmid   ;
        output PMpubypass;
        output PSnoop  ;
        output PDomain ;
    endclocking


    clocking slave_cb @(posedge PClk);
        default input #(`APB_SETUP_TIME) output #(`APB_HOLD_TIME);

        `ifndef ASYN_RESET_FUNC
           input rst_n;
        `endif

        input PAddr;
        input PSel;
        input PEnable;
        input PPrt;
        input PWrite;
        input PWDData;
        input PStrb;
        input PAuser;
        input PWuser;
        input PQos;
        input PGrpid ;
        input PVmid ;
        input PMpubypass;
        input PSnoop ;
        input PDomain ;
        output PRData;
        output PSlvErr;
        output PReady;
    output PRuser;
    endclocking

    clocking monitor_cb @(posedge PClk);
        default input #(`APB_SETUP_TIME) output #(`APB_HOLD_TIME);

    `ifndef ASYN_RESET_FUNC
       input rst_n;
    `endif

    input PAddr;
    input PSel;
    input PWDData;
    input PRData;
    input PEnable;
    input PWrite;
    input PReady;
    input PSlvErr;
    input PPrt;
    input PStrb;
    input PAuser;
    input PWuser;
    input PRuser;
    input PQos ;
    input PGrpid ;
    input PVmid ;
    input PMpubypass;
    input PSnoop ;
    input PDomain ;
  endclocking

    modport Master(clocking master_cb, input rst_n);
    modport Slave(clocking slave_cb, input rst_n);
    modport Monitor(clocking monitor_cb, input rst_n);

endinterface
