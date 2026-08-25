package stb_dec

  parameter ON=1'b1;
  parameter OFF=1'b0;

  typedef enum bit[3:0]{MASTER                = 4'b0000,
                        SLAVE                 = 4'b0001,
                        MASTER_NO_MONITOR     = 4'b0010,
                        ONLY_MONITOR          = 4'b0011,
                        REG_MASTER            = 4'b0100,
                        REG_MASTER_NO_MONITOR = 4'b0101
                       }interface_agent_work_mode_e;

  typedef enum bit[2:0]{FOR_UT     = 3'b000, //Unit 单元测试
                        FOR_BT     = 3'b001, //Block 模块测试
                        FOR_IT     = 3'b010, //Integration 继承测试
                        FOR_ST     = 3'b011  //System 系统测试 
                       }verf_env_scene_e;

  typedef enum int {
      DRV_RND = 0, // when valid=0, drive all other signals with random value.
      DRV_0 = 1,   // when valid=0, always drive the other signals='0'.
      DRV_1 = 2,   // when valid=0, always drive the other signals='1'.
      DRV_X = 3,   // when valid=0, always drive the other signals='X'.
      DRV_LST = 4  // when valid=0, never drive the other signals, so they retain their last values.
  } drv_mode_e;



  
endpackage:stb_dec
