`timescale 1ns / 1ps

module BCH_Decod_tb();

`include "Channel_Params.vh"

// -------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------
parameter CLK_PERIOD = 10;
parameter GEN_BITS_NUMB = 200;
parameter ERROR_PROB = 0.01;

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

// сигналы для декодера
wire decoder_out;
wire decoder_valid;

// сигналы для канала с ошибками
wire channel_out;
wire channel_valid;
wire error_valid;

// сигналы для проверки теста
integer Error_Bits_Count = 0;
integer TX_Bit_Count = 0;
integer RX_Bit_Count = 0;
integer Err_Count = 0;
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
// канала с ошибками
Channel
#(
    .ERROR_PROB(ERROR_PROB)
    )
Channel_Inst    
    (
    .CLK(clk),
    .DATA_IN(outfifo_outdata),
    .DATA_IN_VALID(outfifo_valid),
    .DATA_OUT(channel_out),
    .DATA_OUT_VALID(channel_valid),
    .ERROR_VALID(error_valid)
    );
				
// -------------------------------------------------------------------------------------------------------------------------			
// БЧХ декодер
BCH_Decoder
#(
    .DEC_BCH_POLYNOM(BCH_POLYNOM),
    .DEC_N(N),
    .DEC_K(K)
)
BCH_Decoder_Inst    
    (
    .CLK(clk),
    .RESET(reset),
    .DATA_IN(channel_out),
    .DATA_IN_VALID(channel_valid),
    .DATA_OUT(decoder_out),
    .DATA_OUT_VALID(decoder_valid)
    );

// -------------------------------------------------------------------------------------------------------------------------			
always @(posedge clk)
begin
    // подсчитываем и сохраняем данные от генератора
    if (infifo_we) begin
        TX_Bit_Vector[TX_Bit_Count] = infifo_indata;
        TX_Bit_Count = TX_Bit_Count + 1;
    end
    
    // подсчитываем и сохраняем данные от декодера
    if (decoder_valid) begin
        RX_Bit_Vector[RX_Bit_Count] = decoder_out;
        RX_Bit_Count = RX_Bit_Count + 1;
    end
    
    // подсчитываем и сохраняем число сгенерированных ошибок в канале
    if (error_valid) begin
        Err_Count = Err_Count + 1;
    end
    
    
    // запускаем проверку теста
    if (check_test_start) begin
        $display("Number of transmitted bits: %0d", TX_Bit_Count);
        $display("Number of received bits: %0d", RX_Bit_Count);
        $display("Number of channel errors: %0d", Err_Count);
        
        for (loop_idx = 0; loop_idx<RX_Bit_Count; loop_idx = loop_idx+1) 
            if (RX_Bit_Vector[loop_idx] != TX_Bit_Vector[loop_idx])
                Error_Bits_Count = Error_Bits_Count + 1;
            
        $display("Number of errors after decoding: %0d", Error_Bits_Count);
        
        $display("---------------------------------------");        
        if (Error_Bits_Count > ERROR_PROB*GEN_BITS_NUMB) $display("TEST FAIL!");
        else $display("TEST PASS!");
        $display("---------------------------------------");
        
        $finish;
    end
end

endmodule
