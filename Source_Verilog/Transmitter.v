`timescale 1ns / 1ps

module transmitter(
    input      clk,
    input      ce,
    input      reset,
	input      bch_coder_on,
    input      interleaver_on,
    input      frame_former_on,
    input      data_in,
    input      data_in_we,
    output reg data_in_full,
    output reg data_out,
    output reg data_out_valid
    );

`include "Channel_Params.vh"

// сигналы для входного FIFO
wire infifo_outdata; 
wire infifo_empty; 
wire infifo_full; 
reg  infifo_re;
wire infifo_valid;

// сигналы для кодера
wire bch_coder_indata;
wire bch_coder_we;
wire bch_coder_full;
wire bch_coder_outdata;
wire bch_coder_re;
wire bch_coder_empty;

// сигналы для FIFO кодера
wire fifo_bch_coder_indata;
wire fifo_bch_coder_we;
wire fifo_bch_coder_full;
wire fifo_bch_coder_outdata;
reg  fifo_bch_coder_re;
wire fifo_bch_coder_empty;
wire fifo_bch_coder_valid;

// сигналы для перемежителя
reg  interleaver_indata;
wire interleaver_we;
wire interleaver_full;
wire interleaver_outdata;
wire interleaver_re;
reg  interleaver_empty;
wire interleaver_valid;

// сигналы для FIFO перемежителя
wire fifo_interleaver_indata;
wire fifo_interleaver_we;
wire fifo_interleaver_full;
wire fifo_interleaver_outdata;
reg  fifo_interleaver_re;
wire fifo_interleaver_empty;
wire fifo_interleaver_valid;

// сигналы для блока добавления преамбулы
reg  frame_former_indata;
wire frame_former_we;
wire frame_former_full;
wire frame_former_outdata;
wire frame_former_re;
reg  frame_former_empty;
wire frame_former_valid;

// сигналы для FIFO блока добавления преамбулы
wire fifo_frame_former_indata;
wire fifo_frame_former_we;
wire fifo_frame_former_full;
wire fifo_frame_former_outdata;
wire fifo_frame_former_re;
wire fifo_frame_former_empty;
wire fifo_frame_former_valid;


// -------------------------------------------------------------------------------------
// входное FIFO
xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    // String
    .ECC_MODE("no_ecc"),       // String
    .FIFO_MEMORY_TYPE("auto"), // String
    .FIFO_READ_LATENCY(1),     // DECIMAL
    .FIFO_WRITE_DEPTH(Transmitter_Fifo_Depth),     // DECIMAL
    .FULL_RESET_VALUE(0),      // DECIMAL
    .PROG_EMPTY_THRESH(10),    // DECIMAL
    .PROG_FULL_THRESH(10),     // DECIMAL
    .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
    .READ_DATA_WIDTH(1),       // DECIMAL
    .READ_MODE("std"),         // String
    .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES("1107"), // String
    .WAKEUP_TIME(0),           // DECIMAL
    .WRITE_DATA_WIDTH(1),      // DECIMAL
    .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
infifo (
    .wr_clk(clk),              
    .rst(reset),                     
    // сигналы записи
    .din(data_in),     
    .wr_en(data_in_we),  
    .full(infifo_full), 
    // сигналы чтения
    .dout(infifo_outdata),                  
    .rd_en(infifo_re),               
    .empty(infifo_empty),
    .data_valid(infifo_valid),                 
    // неиспользуемые входные сигналы
    .injectdbiterr(0), 
    .injectsbiterr(0), 
    .sleep(0)                
   );

always @(*)
    if (bch_coder_on) begin
        infifo_re = bch_coder_re;	
	end else if (interleaver_on) begin
        infifo_re = interleaver_re;
	end else begin
		infifo_re = frame_former_re;
    end       
   
// -------------------------------------------------------------------------------------    
// БЧХ кодер
BCH_Encoder
#(
    .BCH_POLYNOM(BCH_POLYNOM),
    .N(N),
    .K(K)
)
BCH_Encoder_Inst
(
    .CLK(clk),
    .RESET(reset),
    // сигналы для входного FIFO 
    .FIFO_IN_DATA(infifo_outdata),
    .FIFO_IN_RE(bch_coder_re),
    .FIFO_IN_EMPTY(infifo_empty),
    // сигналы для выходного FIFO 
    .FIFO_OUT_DATA(bch_coder_outdata),
    .FIFO_OUT_WE(bch_coder_we),
    .FIFO_OUT_FULL(bch_coder_full)
    );

assign fifo_bch_coder_indata = bch_coder_outdata;	
assign fifo_bch_coder_we = bch_coder_we;
assign bch_coder_full = fifo_bch_coder_full;
	
// FIFO после кодера
xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    // String
    .ECC_MODE("no_ecc"),       // String
    .FIFO_MEMORY_TYPE("auto"), // String
    .FIFO_READ_LATENCY(1),     // DECIMAL
    .FIFO_WRITE_DEPTH(Transmitter_Fifo_Depth),     // DECIMAL
    .FULL_RESET_VALUE(0),      // DECIMAL
    .PROG_EMPTY_THRESH(10),    // DECIMAL
    .PROG_FULL_THRESH(10),     // DECIMAL
    .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
    .READ_DATA_WIDTH(1),       // DECIMAL
    .READ_MODE("std"),         // String
    .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES("1107"), // String
    .WAKEUP_TIME(0),           // DECIMAL
    .WRITE_DATA_WIDTH(1),      // DECIMAL
    .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
bch_coder_fifo (
    .wr_clk(clk),              
    .rst(reset),                     
    // сигналы записи
    .din(fifo_bch_coder_indata),     
    .wr_en(fifo_bch_coder_we),  
    .full(fifo_bch_coder_full), 
    // сигналы чтения
    .dout(fifo_bch_coder_outdata),                  
    .rd_en(fifo_bch_coder_re),               
    .empty(fifo_bch_coder_empty),
    .data_valid(fifo_bch_coder_valid),                 
    // неиспользуемые входные сигналы
    .injectdbiterr(0), 
    .injectsbiterr(0), 
    .sleep(0)                
   );
 
always @(*)
    if (interleaver_on)
        fifo_bch_coder_re = interleaver_re;
	else if (frame_former_on)
        fifo_bch_coder_re = frame_former_re;
	else 
	    fifo_bch_coder_re = 1'b1;
     
// -------------------------------------------------------------------------------------
// мультиплексор входных данных для перемежителя
always @(*)
    if (bch_coder_on) begin
        interleaver_indata = fifo_bch_coder_outdata;
	    interleaver_empty = fifo_bch_coder_empty;
	end else begin
	    interleaver_indata = infifo_outdata;
	    interleaver_empty = infifo_empty;
    end  
	
// перемежитель
Interleaver 
#(
    .ROW_NUMBER(ROW_NUMBER),
    .COL_NUMBER(COL_NUMBER)
)
Interleaver_Inst(
    .CLK(clk),
    .RESET(reset),
    // сигналы для входного FIFO 
    .FIFO_IN_DATA(interleaver_indata),
    .FIFO_IN_RE(interleaver_re),
    .FIFO_IN_EMPTY(interleaver_empty),
    // сигналы для выходного FIFO 
    .FIFO_OUT_DATA(interleaver_outdata),
    .FIFO_OUT_WE(interleaver_we),
    .FIFO_OUT_FULL(interleaver_full)
    );

assign fifo_interleaver_indata = interleaver_outdata;	
assign fifo_interleaver_we = interleaver_we;
assign interleaver_full = fifo_interleaver_full;

// FIFO после перемежителя
xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    // String
    .ECC_MODE("no_ecc"),       // String
    .FIFO_MEMORY_TYPE("auto"), // String
    .FIFO_READ_LATENCY(1),     // DECIMAL
    .FIFO_WRITE_DEPTH(Transmitter_Fifo_Depth),     // DECIMAL
    .FULL_RESET_VALUE(0),      // DECIMAL
    .PROG_EMPTY_THRESH(10),    // DECIMAL
    .PROG_FULL_THRESH(10),     // DECIMAL
    .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
    .READ_DATA_WIDTH(1),       // DECIMAL
    .READ_MODE("std"),         // String
    .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES("1107"), // String
    .WAKEUP_TIME(0),           // DECIMAL
    .WRITE_DATA_WIDTH(1),      // DECIMAL
    .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
interleaver_fifo (
    .wr_clk(clk),              
    .rst(reset),                     
    // сигналы записи
    .din(fifo_interleaver_indata),     
    .wr_en(fifo_interleaver_we),  
    .full(fifo_interleaver_full), 
    // сигналы чтения
    .dout(fifo_interleaver_outdata),                  
    .rd_en(fifo_interleaver_re),               
    .empty(fifo_interleaver_empty),
    .data_valid(fifo_interleaver_valid),                 
    // неиспользуемые входные сигналы
    .injectdbiterr(0), 
    .injectsbiterr(0), 
    .sleep(0)                
   );   
   
always @(*)
    if (frame_former_on) begin
        fifo_interleaver_re = frame_former_re;	
	end else begin
		fifo_interleaver_re = 1'b1;
    end   
// -------------------------------------------------------------------------------------    
// мультиплексор входных данных для блока добавления преамбулы
always @(*)
    if (interleaver_on) begin
        frame_former_indata = fifo_interleaver_outdata;
	    frame_former_empty = fifo_interleaver_empty;	
	end else if (bch_coder_on) begin
        frame_former_indata = fifo_bch_coder_outdata;
	    frame_former_empty = fifo_bch_coder_empty;
	end else begin
	    frame_former_indata = infifo_outdata;
	    frame_former_empty = infifo_empty;
    end    
	
// блок добавления преамбулы
Frame_Former 
#(
    .PREAMBLE_LEN(PREAMBLE_LEN),
    .PREAMBLE_VAL(PREAMBLE_VAL),
    .PAYLOAD_LEN(PAYLOAD_LEN)
)
Frame_Former_Inst(
    .CLK(clk),
    .RESET(reset),
    // сигналы для входного FIFO 
    .FIFO_IN_DATA(frame_former_indata),
    .FIFO_IN_RE(frame_former_re),
    .FIFO_IN_EMPTY(frame_former_empty),
    // сигналы для выходного FIFO 
    .FIFO_OUT_DATA(frame_former_outdata),
    .FIFO_OUT_WE(frame_former_we),
    .FIFO_OUT_FULL(frame_former_full)
    );

assign fifo_frame_former_indata = frame_former_outdata;	
assign fifo_frame_former_we = frame_former_we;
assign frame_former_full = fifo_frame_former_full;
	
// FIFO после блока добавления преамбулы
xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    // String
    .ECC_MODE("no_ecc"),       // String
    .FIFO_MEMORY_TYPE("auto"), // String
    .FIFO_READ_LATENCY(1),     // DECIMAL
    .FIFO_WRITE_DEPTH(Transmitter_Fifo_Depth),     // DECIMAL
    .FULL_RESET_VALUE(0),      // DECIMAL
    .PROG_EMPTY_THRESH(10),    // DECIMAL
    .PROG_FULL_THRESH(10),     // DECIMAL
    .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
    .READ_DATA_WIDTH(1),       // DECIMAL
    .READ_MODE("std"),         // String
    .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES("1107"), // String
    .WAKEUP_TIME(0),           // DECIMAL
    .WRITE_DATA_WIDTH(1),      // DECIMAL
    .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
outfifo (
    .wr_clk(clk),              
    .rst(reset),                     
    // сигналы записи
    .din(fifo_frame_former_indata),     
    .wr_en(fifo_frame_former_we),  
    .full(fifo_frame_former_full), 
    // сигналы чтения
    .dout(fifo_frame_former_outdata),                  
    .rd_en(1'b1),               
    .empty(),
    .data_valid(fifo_frame_former_valid),                                 
    // неиспользуемые входные сигналы
    .injectdbiterr(0), 
    .injectsbiterr(0), 
    .sleep(0)                
   );   

// мультиплексор выходных данных   
always @(*)
    if (frame_former_on) begin
	    data_out = fifo_frame_former_outdata;
	    data_out_valid = fifo_frame_former_valid;
		data_in_full = infifo_full;
	end else if (interleaver_on) begin
        data_out = fifo_interleaver_outdata;
	    data_out_valid = fifo_interleaver_valid;
        data_in_full = infifo_full;		
	end else if (bch_coder_on) begin
        data_out = fifo_bch_coder_outdata;
	    data_out_valid = fifo_bch_coder_valid;
		data_in_full = infifo_full;
	end else begin
	    data_out = data_in;
	    data_out_valid = data_in_we;
		data_in_full = 1'b0;
    end    
	
endmodule
