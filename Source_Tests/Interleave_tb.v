`timescale 1ns / 1ps

module Interleave_tb();

`include "Channel_Params.vh"

// -------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------
parameter CLK_PERIOD = 10;
parameter GEN_BITS_NUMB = 200;

// -------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------

// управляющие сигналы
reg clk = 0;
reg reset = 1;
reg data_gen_start = 0;
reg check_test_start = 0;
reg error_flag = 0;
integer loop_idx;

// сигналы для входного FIFO
wire infifo_indata;
wire infifo_we;
wire infifo_full;
wire infifo_outdata;
wire infifo_re;
wire infifo_empty;
wire infifo_valid;

// сигналы для выходного FIFO
wire outfifo_indata;
wire outfifo_we;
wire outfifo_full;
wire outfifo_outdata;
wire outfifo_re;
wire outfifo_empty;
wire outfifo_valid;

// сигналы для деперемежителя
wire deinterleaver_out;
wire deinterleaver_valid;

// сигналы для проверки теста
integer TX_Bit_Count = 0;
integer RX_Bit_Count = 0;
reg [GEN_BITS_NUMB-1:0] TX_Bit_Vector;
reg [GEN_BITS_NUMB-1:0] RX_Bit_Vector;

// -------------------------------------------------------------------------------------
always #CLK_PERIOD clk = ~clk;

initial begin
    #50 reset = 0;
    #50 data_gen_start = 1; 
    #50000 check_test_start = 1;
end

// -------------------------------------------------------------------------------------
// генератор входных данных
Data_Generator #(.BITS_NUMB(GEN_BITS_NUMB))
Data_Generator_Inst
    (
    .CLK(clk),
    .RESET(reset),
    .START(data_gen_start),
    .FIFO_OUT_DATA(infifo_indata),
    .FIFO_OUT_WE(infifo_we),
    .FIFO_OUT_FULL(infifo_full)
    );

// -------------------------------------------------------------------------------------
// входное FIFO
xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    // String
    .ECC_MODE("no_ecc"),       // String
    .FIFO_MEMORY_TYPE("auto"), // String
    .FIFO_READ_LATENCY(1),     // DECIMAL
    .FIFO_WRITE_DEPTH(16),     // DECIMAL
    .FULL_RESET_VALUE(0),      // DECIMAL
    .PROG_EMPTY_THRESH(10),    // DECIMAL
    .PROG_FULL_THRESH(10),     // DECIMAL
    .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
    .READ_DATA_WIDTH(1),       // DECIMAL
    .READ_MODE("std"),         // String
    .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES("11C7"), // String
    .WAKEUP_TIME(0),           // DECIMAL
    .WRITE_DATA_WIDTH(1),      // DECIMAL
    .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
infifo (
 
    .wr_clk(clk),              
    .rst(reset),                     
    // сигналы записи
    .din(infifo_indata),     
    .wr_en(infifo_we),  
    .full(infifo_full), 
    // сигналы чтения
    .dout(infifo_outdata),                  
    .rd_en(infifo_re),               
    .empty(infifo_empty),                
    // неиспользуемые входные сигналы
    .injectdbiterr(0), 
    .injectsbiterr(0), 
    .sleep(0)                
   );

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
    .FIFO_IN_DATA(infifo_outdata),
    .FIFO_IN_RE(infifo_re),
    .FIFO_IN_EMPTY(infifo_empty),
    // сигналы для выходного FIFO 
    .FIFO_OUT_DATA(outfifo_indata),
    .FIFO_OUT_WE(outfifo_we),
    .FIFO_OUT_FULL(outfifo_full)
    );


// выходное FIFO
xpm_fifo_sync #(
    .DOUT_RESET_VALUE("0"),    // String
    .ECC_MODE("no_ecc"),       // String
    .FIFO_MEMORY_TYPE("auto"), // String
    .FIFO_READ_LATENCY(1),     // DECIMAL
    .FIFO_WRITE_DEPTH(16),     // DECIMAL
    .FULL_RESET_VALUE(0),      // DECIMAL
    .PROG_EMPTY_THRESH(10),    // DECIMAL
    .PROG_FULL_THRESH(10),     // DECIMAL
    .RD_DATA_COUNT_WIDTH(1),   // DECIMAL
    .READ_DATA_WIDTH(1),       // DECIMAL
    .READ_MODE("std"),         // String
    .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES("11C7"), // String
    .WAKEUP_TIME(0),           // DECIMAL
    .WRITE_DATA_WIDTH(1),      // DECIMAL
    .WR_DATA_COUNT_WIDTH(1)    // DECIMAL
   )
outfifo (
 
    .wr_clk(clk),              
    .rst(reset),                     
    // сигналы записи
    .din(outfifo_indata),     
    .wr_en(outfifo_we),  
    .full(outfifo_full), 
    // сигналы чтения
    .dout(outfifo_outdata),                  
    .rd_en(1),               
    .empty(outfifo_empty),
    .data_valid(outfifo_valid),                  
    // неиспользуемые входные сигналы
    .injectdbiterr(0), 
    .injectsbiterr(0), 
    .sleep(0)                
   );
				
// -------------------------------------------------------------------------------------------------------------------------			
Deinterleaver
    #(
    .ROW_NUMBER(ROW_NUMBER),
    .COL_NUMBER(COL_NUMBER)
    )
Deinterleaver_Inst    
    (
    .CLK(clk),
    .RESET(reset),
    .DATA_IN(outfifo_outdata),
    .DATA_IN_VALID(outfifo_valid),
    .DATA_OUT(deinterleaver_out),
    .DATA_OUT_VALID(deinterleaver_valid)
    );

// -------------------------------------------------------------------------------------------------------------------------			
always @(posedge clk)
begin
    // подсчитываем и сохраняем данные от генератора
    if (infifo_we) begin
        TX_Bit_Vector[TX_Bit_Count] = infifo_indata;
        TX_Bit_Count = TX_Bit_Count + 1;
    end
    
    // подсчитываем и сохраняем данные от деперемежителя
    if (deinterleaver_valid) begin
        RX_Bit_Vector[RX_Bit_Count] = deinterleaver_out;
        RX_Bit_Count = RX_Bit_Count + 1;
    end
    
    // запускаем проверку теста
    if (check_test_start) begin
        $display("Number of transmitted bits: %0d", TX_Bit_Count);
        $display("Number of received bits: %0d", RX_Bit_Count);
        
        for (loop_idx = 0; loop_idx<RX_Bit_Count; loop_idx = loop_idx+1) 
            if (RX_Bit_Vector[loop_idx] != TX_Bit_Vector[loop_idx])
                error_flag = 1;
        
        $display("---------------------------------------");        
        if (error_flag) $display("TEST FAIL!");
        else $display("TEST PASS!");
        $display("---------------------------------------");
        
        $finish;
    end
end

endmodule
