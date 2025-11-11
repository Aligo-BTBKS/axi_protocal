module tb_axi_lite_slave;
    timeunit 1ns;
    timeprecision 1ns;
    // 参数
    localparam int C_S_AXI_DATA_WIDTH = 32;
    localparam int C_S_AXI_ADDR_WIDTH = 32;

    // 信号
    logic                                   clk;
    logic                                   rstn;
    logic [C_S_AXI_ADDR_WIDTH-1:0]          S_AXI_AWADDR;
    logic [2:0]                             S_AXI_AWPROT;
    logic                                   S_AXI_AWVALID;
    logic                                   S_AXI_AWREADY;
    logic [C_S_AXI_DATA_WIDTH-1:0]          S_AXI_WDATA;
    logic [(C_S_AXI_DATA_WIDTH/8)-1:0]      S_AXI_WSTRB;
    logic                                   S_AXI_WVALID;
    logic                                   S_AXI_WREADY;
    logic [1:0]                             S_AXI_BRESP;
    logic                                   S_AXI_BVALID;
    logic                                   S_AXI_BREADY;
    logic [C_S_AXI_ADDR_WIDTH-1:0]          S_AXI_ARADDR;
    logic [2:0]                             S_AXI_ARPROT;
    logic                                   S_AXI_ARVALID;
    logic                                   S_AXI_ARREADY;
    logic [C_S_AXI_DATA_WIDTH-1:0]          S_AXI_RDATA;
    logic [1:0]                             S_AXI_RRESP;
    logic                                   S_AXI_RVALID;
    logic                                   S_AXI_RREADY;

    // 时钟
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // 复位
    initial begin
        rstn = 0;
        S_AXI_AWVALID = 0;
        S_AXI_AWADDR  = 0;
        S_AXI_AWPROT  = 0;
        S_AXI_WVALID  = 0;
        S_AXI_WDATA   = 0;
        S_AXI_WSTRB   = 0;
        S_AXI_BREADY  = 0;
        S_AXI_ARVALID = 0;
        S_AXI_ARADDR  = 0;
        S_AXI_ARPROT  = 0;
        S_AXI_RREADY  = 0;
        #50;
        rstn = 1;
    end

    // DUT
    axi_lite_slave #(
        // .C_U_PERI_DATA_WIDTH (16),
        .C_U_PERI_NUMS       (16),
        .C_S_AXI_DATA_WIDTH  (32),
        .C_S_AXI_ADDR_WIDTH  (32)
    ) dut (
        .S_AXI_ACLK   (clk),
        .S_AXI_ARESETN(rstn),
        .S_AXI_AWADDR (S_AXI_AWADDR),
        .S_AXI_AWPROT (S_AXI_AWPROT),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA  (S_AXI_WDATA),
        .S_AXI_WSTRB  (S_AXI_WSTRB),
        .S_AXI_WVALID (S_AXI_WVALID),
        .S_AXI_WREADY (S_AXI_WREADY),
        .S_AXI_BRESP  (S_AXI_BRESP),
        .S_AXI_BVALID (S_AXI_BVALID),
        .S_AXI_BREADY (S_AXI_BREADY),
        .S_AXI_ARADDR (S_AXI_ARADDR),
        .S_AXI_ARPROT (S_AXI_ARPROT),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA  (S_AXI_RDATA),
        .S_AXI_RRESP  (S_AXI_RRESP),
        .S_AXI_RVALID (S_AXI_RVALID),
        .S_AXI_RREADY (S_AXI_RREADY)
    );
    // write task
    task automatic axi_write(input logic [31:0] addr,
                             input logic [31:0] data,
                             input logic [3:0]  strb = 4'hF,
                             input logic addr_first = 0,
                             input logic data_first = 0);
        begin
            S_AXI_AWADDR  <= addr;
            S_AXI_WDATA   <= data;
            S_AXI_WSTRB   <= strb;
            if(addr_first && !data_first) begin
                @(posedge clk);
                S_AXI_AWVALID   <= 1;
                wait(S_AXI_AWREADY);
                @(posedge clk);
                S_AXI_AWVALID   <= 0;
                S_AXI_WVALID    <= 1;
                wait(S_AXI_WREADY);
                @(posedge clk);
                S_AXI_WVALID <= 0;
            end
            else if(!addr_first && data_first) begin
                @(posedge clk);
                S_AXI_WVALID    <= 1;
                wait(S_AXI_WREADY);
                @(posedge clk);
                S_AXI_WVALID    <= 0;
                S_AXI_AWVALID   <= 1;
                wait(S_AXI_AWREADY);
                @(posedge clk);
                S_AXI_AWVALID   <= 0;
            end
            else begin
                @(posedge clk);
                S_AXI_AWVALID   <= 1;
                S_AXI_WVALID    <= 1;
                wait(S_AXI_AWREADY && S_AXI_WREADY);
                @(posedge clk);
                S_AXI_AWVALID   <= 0;
                S_AXI_WVALID    <= 0;
            end
            // wait Bresp
            S_AXI_BREADY <= 1;
            wait (S_AXI_BVALID);
            @(posedge clk);
            $display("[%0t] WRITE @%h data=%h resp=%0b", $time, addr, data, S_AXI_BRESP);
            S_AXI_BREADY <= 0;
        end
    endtask



    // 读任务
    task automatic axi_read(input  logic [31:0] addr,
                            output logic [31:0] data);
        begin
            @(posedge clk);
            S_AXI_ARADDR  <= addr;
            S_AXI_ARVALID <= 1;
            wait (S_AXI_ARREADY);
            @(posedge clk);
            S_AXI_ARVALID <= 0;
            S_AXI_RREADY  <= 1;
            wait (S_AXI_RVALID);
            data = S_AXI_RDATA;
            $display("[%0t] READ  @%h data=%h resp=%0b", $time, addr, data, S_AXI_RRESP);
            @(posedge clk);
            S_AXI_RREADY <= 0;
        end
    endtask


    // 测试流程
    initial begin : main_test
        logic [31:0] rd;
        wait(rstn); // wait reset finish
        repeat(5)@(posedge clk);
        // case 1 ：test write action
        // awvalid arrive first
        axi_write(32'h0000_0008, 32'haa00_0055, 4'b1001, 1, 0); //write reg_2
        // wvalid arrive first
        axi_write(32'h0000_0020, 32'h0000_1155, 4'b0011, 0, 1); //write reg_8
        // awvalid and wvalid arrive together
        axi_write(32'h0000_000c, 32'h0000_1001, 4'b0011, 0, 0); //write reg_3
        // the error address test
        axi_write(32'h0100_0000, 32'h1234_5678, 4'b0011);
        // test unligned address
        axi_write(32'h0000_0001, 32'h0000_00AA, 4'b0011);
        
        // case 2: test read action
        axi_read (32'h0000_0008, rd);
        assert (rd == 32'haa00_0055) else $fatal("byte write fail");
        axi_read (32'h0000_0020, rd);
        assert (rd == 32'h0000_1155) else $fatal("byte write fail");
        axi_read (32'h0000_000c, rd);
        assert (rd == 32'h0000_1001) else $fatal("byte write fail");


        # 100;
        $display("ALL TEST DONE");
        $finish;
    end

endmodule