`timescale 1ns/1ps
//bypass: when downstream ready=1
//skid :  when downstream ready=0,upstream data store in skid_buffer data.

module ktp_skid_buffer #(
  parameter WIDTH = 8
)(
    input   logic            clk,
    input   logic            resetn,
//input
    input   logic            valid_i,
    output  logic            ready_o,
    input   logic   [WIDTH-1:0] data_i,
//output
    output  logic            valid_o,
    input   logic            ready_i,
    output  logic   [WIDTH-1:0] data_o
);

//two stage register:

//bypass(entry 0):
    logic             out_valid;  //direct wire port valid_o
    logic [WIDTH-1:0]  out_data;  //port data_o
//skid buffer(entry 1):
    logic             skid_valid; //buffer valid
    logic [WIDTH-1:0]  skid_data; //buffer data

    wire   input_fire    = valid_i && ready_o;  //upstream  handshake
    wire   output_fire  = valid_o && ready_i;  //downstream handshake

    //wire  output_empty = !out_valid;
    //wire  output_load  = output_empty || output_fire;

//*** ready_o depends only on this module's state ,not on ready_i
    assign ready_o = !skid_valid;  //only when skid buffer is empty, can accept the upstream's  data;if the skid buffer is full,backpressure upstream

//upstream is driven by bypass register(entry 0) ,so decoupe the up and down.
    assign valid_o = out_valid;
    assign data_o  = out_data;

//when need to pop data,if skid buffer has data,output skid's data.if skid buffer is empty,so look upstream whether has new data(input_fire).
//
    always_ff@ (posedge clk or negedge resetn)begin
        if(!resetn)begin
            out_valid  <= 1'b0;
            out_data   <= 'd0;
        end
        else begin
            if(output_fire)begin
                if(skid_valid)begin
                    out_data  <= skid_data;
                    out_valid <= 1'b1;
