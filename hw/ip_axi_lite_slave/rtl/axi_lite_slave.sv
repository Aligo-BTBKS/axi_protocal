module axi_lite_slave #(
    // Users to add parameters here
    // parameter integer C_U_PERI_DATA_WIDTH       = 16,
    parameter integer C_U_PERI_NUMS             = 16,
    // User parameters ends
    // Do not modify the parameters beyond this line
    

    // 使用[OPT_MEM_ADDR_BITS+ADDR_LSB-1 : ADDR_LSB]来匹配可以操作的地址空间或寄存器
    
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH	= 6
) (
    // Users to add ports here


    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input   logic                                   S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input   logic                                   S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input   logic [C_S_AXI_ADDR_WIDTH-1 : 0]        S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
        // privilege and security level of the transaction, and whether
        // the transaction is a data access or an instruction access.
    input   logic [2 : 0]                           S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
        // valid write address and control information.
    input   logic                                   S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
        // to accept an address and associated control signals.
    output  logic                                   S_AXI_AWREADY,
    
    // Write data (issued by master, acceped by Slave) 
    input   logic [C_S_AXI_DATA_WIDTH-1 : 0]        S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
        // valid data. There is one write strobe bit for each eight
        // bits of the write data bus.    
    input   logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0]    S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
        // data and strobes are available.
    input   logic                                   S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
        // can accept the write data.
    output  logic                                   S_AXI_WREADY,
    // Write response. This signal indicates the status
        // of the write transaction.
    output  logic [1 : 0]                           S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
        // is signaling a valid write response.
    output  logic                                   S_AXI_BVALID,
    // Response ready. This signal indicates that the master
        // can accept a write response.
    input   logic                                   S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input   logic [C_S_AXI_ADDR_WIDTH-1 : 0]        S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
        // and security level of the transaction, and whether the
        // transaction is a data access or an instruction access.
    input   logic [2 : 0]                           S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
        // is signaling valid read address and control information.
    input   logic                                   S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
        // ready to accept an address and associated control signals.
    output  logic                                   S_AXI_ARREADY,
    // Read data (issued by slave)
    output  logic [C_S_AXI_DATA_WIDTH-1 : 0]        S_AXI_RDATA,
    // Read response. This signal indicates the status of the
        // read transfer.
    output  logic [1 : 0]                           S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
        // signaling the required read data.
    output  logic                                   S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
        // accept the read data and response information.
    input   logic                                   S_AXI_RREADY
);
	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam int  ADDR_LSB                 = $clog2(C_S_AXI_DATA_WIDTH/8);
    // OPT_MEM_ADDR_BITS is up to the nums of register in slave components
	localparam int  OPT_PERI_ADDR_BITS       = $clog2(C_U_PERI_NUMS);


    typedef enum logic[1:0] { IDLE_e = 2'b00, ADDR_e = 2'b01, DATA_e = 2'b11, RESP_e = 2'b10 } state_t;
    state_t stateW, stateW_n, stateR, stateR_n;



    // write inner register
    logic   [C_S_AXI_DATA_WIDTH/8-1 : 0]            wstrb_r;
    logic   [C_S_AXI_ADDR_WIDTH-1 : 0]              awaddr_r;
    logic   [C_S_AXI_DATA_WIDTH-1 : 0]              wdata_r;
    logic                                           write_finish;
    logic   [OPT_PERI_ADDR_BITS-1:0]                wreg_index;
    // read inner register
    logic   [C_S_AXI_ADDR_WIDTH-1 : 0]              araddr_r;
    logic   [OPT_PERI_ADDR_BITS-1:0]                rreg_index;
    // logic                                           read_finish;
    // write channel handshake signal
    logic                                           aw_hs;
    logic                                           w_hs;
    logic                                           b_hs;
    // read channel handshake signal
    logic                                           ar_hs;
    logic                                           r_hs;
    // addr check out
    logic                                           awaddr_ok;
    logic                                           araddr_ok;
    logic                                           awaddr_aligned;
    logic                                           araddr_aligned;
    

/********************************* register logic **********************************/
    // define user register
    logic   [C_S_AXI_DATA_WIDTH-1:0]   user_mem    [0:C_U_PERI_NUMS-1];


/********************************* wirte logic **********************************/
    // handshake
    assign aw_hs            = S_AXI_AWVALID && S_AXI_AWREADY;
    assign w_hs             = S_AXI_WVALID  && S_AXI_WREADY;
    assign b_hs             = S_AXI_BVALID  && S_AXI_BREADY;
    assign awaddr_aligned   = (awaddr_r[ADDR_LSB-1:0] == '0);
    assign araddr_aligned   = (araddr_r[ADDR_LSB-1:0] == '0);
    assign awaddr_ok        = (awaddr_r[C_S_AXI_ADDR_WIDTH-1 : ADDR_LSB] < C_U_PERI_NUMS) && awaddr_aligned;
    assign araddr_ok        = (araddr_r[C_S_AXI_ADDR_WIDTH-1 : ADDR_LSB] < C_U_PERI_NUMS) && araddr_aligned;
    assign wreg_index       = awaddr_r[ADDR_LSB +: OPT_PERI_ADDR_BITS];
    assign rreg_index       = araddr_r[ADDR_LSB +: OPT_PERI_ADDR_BITS];


    always_ff @( posedge S_AXI_ACLK ) begin
        if(S_AXI_ARESETN == 1'b0) begin
            stateW      <= IDLE_e;
        end
        else begin
            stateW      <= stateW_n;
        end
    end

    always_comb begin
        case (stateW)
            IDLE_e: begin
                if( aw_hs && w_hs ) begin  // data and addr arrive at the same clock
                    stateW_n     = RESP_e;
                end
                else if( aw_hs ) begin // addr arrive first
                    stateW_n     = DATA_e;
                end
                else if( w_hs ) begin   // data arrive first
                    stateW_n     = ADDR_e;
                end
                else begin
                    stateW_n     = IDLE_e;
                end
            end
            ADDR_e: begin
                if( aw_hs ) begin
                    stateW_n     = RESP_e;
                end
                else begin
                    stateW_n     = ADDR_e;
                end
            end
            DATA_e: begin
                if( w_hs ) begin
                    stateW_n     = RESP_e;
                end
                else begin
                    stateW_n     = DATA_e;
                end
            end
            RESP_e: begin
                // 检查地址和数据，返回响应
                if ( b_hs ) begin
                    stateW_n = IDLE_e;
                end
                else begin
                    stateW_n = RESP_e;                        
                end
            end
            default: stateW_n    = IDLE_e;
        endcase
    end

    // function logic
    // AWREADY and WREADY
    assign S_AXI_AWREADY = (stateW == IDLE_e) || (stateW == ADDR_e);
    assign S_AXI_WREADY  = (stateW == IDLE_e) || (stateW == DATA_e);

    // BVALIE, BRESP
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <= 1'b0;
            S_AXI_BRESP  <= 2'b00;
        end else begin
            if (stateW == RESP_e && !b_hs) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= awaddr_ok ? 2'b00 : 2'b10;
            end
            else if (b_hs) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end
    
    // wdata_r,awaddr_r,wstrb_r
    always_ff @( posedge S_AXI_ACLK ) begin
        if( S_AXI_ARESETN == 1'b0 ) begin
            awaddr_r                <= '0;
        end
        else if( aw_hs ) begin
            awaddr_r                <= S_AXI_AWADDR;
        end
    end
    always_ff @( posedge S_AXI_ACLK ) begin
        if( S_AXI_ARESETN == 1'b0 ) begin
            wdata_r                 <= '0;
            wstrb_r                 <= '0;
        end
        else if( w_hs ) begin
            wdata_r                 <= S_AXI_WDATA;
            wstrb_r                 <= S_AXI_WSTRB;
        end
    end

    // write data in user_mem
    localparam int BUS_BYTES = C_S_AXI_DATA_WIDTH/8;
    // localparam int REG_BYTES = C_U_PERI_DATA_WIDTH/8;
    // add user write logic
    // write data to register
    always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            write_finish <= 1'b0;
            user_mem <= '{default: '0};
        end else begin
            if (stateW == RESP_e && !write_finish) begin
                if (awaddr_ok) begin
                    for (int i = 0; i < BUS_BYTES; i++) begin
                        if (wstrb_r[i])
                            user_mem[wreg_index][8*i +: 8] <= wdata_r[8*i +: 8];
                    end
                end
                write_finish <= 1'b1;
            end else if (stateW == RESP_e && b_hs) begin
                write_finish <= 1'b0;
            end
        end
    end

/********************************* read logic **********************************/

// handshake
    assign ar_hs = S_AXI_ARVALID && S_AXI_ARREADY;
    assign r_hs  = S_AXI_RVALID  && S_AXI_RREADY;

    // 状态机
    always_ff @( posedge S_AXI_ACLK ) begin
        if (!S_AXI_ARESETN)
            stateR <= IDLE_e;
        else
            stateR <= stateR_n;
    end

    always_comb begin
        stateR_n = stateR;
        case (stateR)
            IDLE_e: begin
                if (ar_hs)
                    stateR_n = RESP_e;     // 收到地址就可以准备回数据了（AXI-Lite只有单拍）
            end
            RESP_e: begin
                if (r_hs)
                    stateR_n = IDLE_e;
            end
        endcase
    end

    // ARREADY assert in IDLE state
    assign S_AXI_ARREADY = (stateR == IDLE_e);

    // latch S_AXI_ARADDR
    always_ff @( posedge S_AXI_ACLK ) begin
        if (!S_AXI_ARESETN) begin
            araddr_r <= '0;
        end 
        else if (ar_hs) begin
            araddr_r <= S_AXI_ARADDR;
        end
    end
    // add user read logic
    // R channel
    // always_ff @( posedge S_AXI_ACLK ) begin
    //     if (!S_AXI_ARESETN) begin
    //         S_AXI_RDATA  <= '0;
    //         S_AXI_RRESP  <= 2'b00;
    //         S_AXI_RVALID <= 1'b0;
    //     end 
    //     else begin
    //         if (stateR == RESP_e && !S_AXI_RVALID) begin
                // 第一次进 RESP，填数据
    //             if (araddr_ok) begin
    //                 S_AXI_RDATA               <= '0;     // 高位清0
    //                 S_AXI_RDATA[C_U_PERI_DATA_WIDTH-1:0]    <= user_mem[rreg_index];
    //                 S_AXI_RRESP               <= 2'b00;  // OKAY
    //             end 
    //             else begin
    //                 S_AXI_RDATA               <= '0;
    //                 S_AXI_RRESP               <= 2'b10;  // SLVERR
    //             end
    //             S_AXI_RVALID                  <= 1'b1;
    //         end else if (r_hs) begin
                // master 收走了
    //             S_AXI_RVALID                  <= 1'b0;
    //         end
    //     end
    // end

    always_ff @( posedge S_AXI_ACLK ) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RDATA     <= '0;
            S_AXI_RRESP     <= 2'b00;
            S_AXI_RVALID    <= 1'b0;
        end 
        else if( stateR == RESP_e && !S_AXI_RVALID ) begin
            S_AXI_RDATA     <= araddr_ok ? user_mem[rreg_index] : '0;
            S_AXI_RRESP     <= araddr_ok ? 2'b00 : 2'b10;
            S_AXI_RVALID    <= 1'b1;
        end
        else if( r_hs ) begin
            S_AXI_RVALID    <= 1'b0;
        end
    end



endmodule