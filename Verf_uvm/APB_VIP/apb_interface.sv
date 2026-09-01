//分为三个clocking block/modport
//Master：驱动addr、write、wdata（作为output），采样prdata、pready、pslverr（作为input）
//Slave：驱动prdata、pready、pslverr（作为output）、采样master传来的信号（作为input）
//monitor: 作monitor使用，只采样总线，不进行驱动，因此都是输出

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

//clock blocking
    clocking slave_cb @(posedge PClk);
        default input #(`APB_SETUP_TIME) output #(`APB_HOLD_TIME);

        `ifndef ASYN_RESET_FUNC
           input rst_n;
        `endif

        input PAddr;
        input PSel;
        input PEnable;
        input PProt;
        input PWrite;
        input PWData;
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
//modport用来规定不同模块、类访问这个接口是，能看到哪些信号，以及方向是什么
//使用的时候 apb_interface.Master my_mst_if  ,代表从Master角度使用接口，只能按master_cb的方向访问想关信号
      
endinterface
