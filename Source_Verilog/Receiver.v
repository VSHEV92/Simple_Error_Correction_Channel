`timescale 1ns / 1ps

module receiver(
    input      clk,
    input      ce,
    input      reset,
	input      bch_decoder_on,
    input      deinterleaver_on,
    input      frame_finder_on,
    input      data_in,
    input      data_in_valid,
    output reg data_out,
    output reg data_out_valid,
    output     frame_sync_lock
    );

`include "Channel_Params.vh"
 
reg internal_reset;
wire lock;

wire frame_finder_out;
wire frame_finder_valid;   

reg deinterleaver_in;
reg deinterleaver_in_valid;   

wire deinterleaver_out;
wire deinterleaver_valid;    

reg decoder_in;
reg decoder_in_valid; 

wire decoder_out;
wire decoder_valid; 
 
// -------------------------------------------------------------------------------------------------------------------------
// блок кадровой синхронизации			
Frame_Finder
    #(
    .DETECT_THRESH(DETECT_THRESH),
    .PAYLOAD_LEN(PAYLOAD_LEN),
    .LOCK_COUNT(LOCK_COUNT),
    .UNLOCK_COUNT(UNLOCK_COUNT),
    .PREAMBLE_LEN(PREAMBLE_LEN),
    .PREAMBLE_VAL(PREAMBLE_VAL)
    )
Frame_Finder_Inst    
    (
    .CLK(clk),
    .RESET(reset),
    .DATA_IN(data_in),
    .DATA_IN_VALID(data_in_valid),
    .DATA_OUT(frame_finder_out),
    .DATA_OUT_VALID(frame_finder_valid),
    .LOCK(lock)
    );    

assign frame_sync_lock = lock;

always @(*)
    if (frame_finder_on)
        internal_reset = reset | ~lock;
    else
	    internal_reset = reset;
// -------------------------------------------------------------------------------------------------------------------------
// деперемежитель
always @(*)
    if (frame_finder_on) begin
        deinterleaver_in = frame_finder_out;
		deinterleaver_in_valid = frame_finder_valid;
	end else begin
	    deinterleaver_in = data_in;
		deinterleaver_in_valid = data_in_valid;
	end
		
Deinterleaver
    #(
    .ROW_NUMBER(ROW_NUMBER),
    .COL_NUMBER(COL_NUMBER)
    )
Deinterleaver_Inst    
    (
    .CLK(clk),
    .RESET(internal_reset),
    .DATA_IN(deinterleaver_in),
    .DATA_IN_VALID(deinterleaver_in_valid),
    .DATA_OUT(deinterleaver_out),
    .DATA_OUT_VALID(deinterleaver_valid)
    );

// -------------------------------------------------------------------------------------------------------------------------
// БЧХ декодер
always @(*)
    if (deinterleaver_on) begin
        decoder_in = deinterleaver_out;
		decoder_in_valid = deinterleaver_valid;
	end else if (frame_finder_on) begin
        decoder_in = frame_finder_out;
		decoder_in_valid = frame_finder_valid;
	end else begin
	    decoder_in = data_in;
		decoder_in_valid = data_in_valid;
	end

BCH_Decoder
#(
    .DEC_BCH_POLYNOM(BCH_POLYNOM),
    .DEC_N(N),
    .DEC_K(K)
)
BCH_Decoder_Inst    
    (
    .CLK(clk),
    .RESET(internal_reset),
    .DATA_IN(decoder_in),
    .DATA_IN_VALID(decoder_in_valid),
    .DATA_OUT(decoder_out),
    .DATA_OUT_VALID(decoder_valid)
    );	
 
// мультиплексор выходных данных   
always @(*)
    if (bch_decoder_on) begin
	    data_out = decoder_out;
	    data_out_valid = decoder_valid;
	end else if (deinterleaver_on) begin
        data_out = deinterleaver_out;
	    data_out_valid = deinterleaver_valid;	
	end else if (frame_finder_on) begin
        data_out = frame_finder_out;
	    data_out_valid = frame_finder_valid;
	end else begin
	    data_out = data_in;
	    data_out_valid = data_in_valid;
    end   
	
endmodule
