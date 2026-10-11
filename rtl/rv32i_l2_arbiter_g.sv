`timescale 1ns/1ps

module rv32i_l2_arbiter_g (
    input wire clk,
    input wire rst,

    
    input wire ic_req,
    input wire ic_write,
    input wire [31:0] ic_addr,
    input wire [127:0] ic_wdata,
    output reg [127:0] ic_rdata,
    output reg ic_ready,

    input wire dc_req,
    input wire dc_write,
    input wire [31:0] dc_addr,
    input wire [127:0] dc_wdata,
    output reg [127:0] dc_rdata,
    output reg dc_ready,

    output reg l2_req,
    output reg l2_write,
    output reg [31:0] l2_addr,
    output reg [127:0] l2_wdata,
    input wire [127:0] l2_rdata,
    input wire l2_ready
);

    localparam A_IDLE = 3'd0;
    localparam A_SEND = 3'd1;
    localparam A_WAIT_RESPONSE    = 3'd2;
    localparam A_WAIT_READY_LOW   = 3'd3;

    reg [2:0] state;

    
    reg owner;
    reg prefer_dcache;

    reg saved_write;
    reg [31:0] saved_addr;
    reg [127:0] saved_wdata;

    always @(posedge clk or posedge rst) begin
        if (rst) begin

            state <= A_IDLE;

            owner <= 1'b0;
            prefer_dcache <= 1'b0;

            saved_write <= 1'b0;
            saved_addr <= 32'b0;
            saved_wdata <= 128'b0;

            l2_req <= 1'b0;
            l2_write <= 1'b0;
            l2_addr <= 32'b0;
            l2_wdata <= 128'b0;

            ic_rdata <= 128'b0;
            ic_ready <= 1'b0;

            dc_rdata <= 128'b0;
            dc_ready <= 1'b0;

        end else begin

            
            ic_ready <= 1'b0;
            dc_ready <= 1'b0;

            case (state)

                A_IDLE: begin
                    l2_req <= 1'b0;

                    if (ic_req && dc_req) begin

                        if (prefer_dcache) begin
                            owner <= 1'b1;

                            saved_write <= dc_write;
                            saved_addr <= dc_addr;
                            saved_wdata <= dc_wdata;

                            l2_req <= 1'b1;
                            l2_write <= dc_write;
                            l2_addr <= dc_addr;
                            l2_wdata <= dc_wdata;

                        end else begin
                            owner <= 1'b0;

                            saved_write <= ic_write;
                            saved_addr <= ic_addr;
                            saved_wdata <= ic_wdata;

                            l2_req <= 1'b1;
                            l2_write <= ic_write;
                            l2_addr <= ic_addr;
                            l2_wdata <= ic_wdata;
                        end

                        prefer_dcache <= ~prefer_dcache;
                        state <= A_WAIT_RESPONSE;

                    end else if (dc_req) begin

                        owner <= 1'b1;

                        saved_write <= dc_write;
                        saved_addr <= dc_addr;
                        saved_wdata <= dc_wdata;

                        l2_req <= 1'b1;
                        l2_write <= dc_write;
                        l2_addr <= dc_addr;
                        l2_wdata <= dc_wdata;

                        prefer_dcache <= 1'b0;
                        state <= A_WAIT_RESPONSE;

                    end else if (ic_req) begin

                        owner <= 1'b0;

                        saved_write <= ic_write;
                        saved_addr <= ic_addr;
                        saved_wdata <= ic_wdata;

                        l2_req <= 1'b1;
                        l2_write <= ic_write;
                        l2_addr <= ic_addr;
                        l2_wdata <= ic_wdata;

                        prefer_dcache <= 1'b1;
                        state <= A_WAIT_RESPONSE;

                    end
                end

                
                A_SEND: begin

                    l2_req <= 1'b1;
                    l2_write <= saved_write;
                    l2_addr <= saved_addr;
                    l2_wdata <= saved_wdata;

                    state <= A_WAIT_RESPONSE;
                end

                A_WAIT_RESPONSE: begin

                    if (l2_ready) begin

                        l2_req <= 1'b0;

                        if (owner == 1'b0) begin
                            ic_rdata <= l2_rdata;
                            ic_ready <= 1'b1;
                        end else begin
                            dc_rdata <= l2_rdata;
                            dc_ready <= 1'b1;
                        end

                        state <= A_WAIT_READY_LOW;
                    end
                end

                A_WAIT_READY_LOW: begin

                    l2_req <= 1'b0;

                    if (!l2_ready) begin
                        state <= A_IDLE;
                    end
                end

                default: begin
                    state <= A_IDLE;
                    l2_req <= 1'b0;
                end

            endcase
        end
    end

endmodule