`timescale 1ns / 1ps

module Error_Channel_tb();

`include "Channel_Params.vh"

// -------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------
parameter CLK_PERIOD = 10;
parameter GEN_BITS_NUMB = 200;
parameter ERROR_PROB = 0.00;

// -------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------

// управляющие сигналы
reg clk = 0;
reg reset = 1;
reg data_gen_start = 0;
reg check_test_start = 0;
reg error_flag = 0;
integer loop_idx;

// входные сигналы передатчика
wire infifo_indata;
wire infifo_we;
wire infifo_full;

// выходные сигналы передатчика
wire transmitter_out;
wire transmitter_valid;

// сигналы для канала с ошибками
wire channel_out;
wire channel_valid;
wire error_valid;

// выходные сигналы приемника
wire receiver_out;
wire receiver_valid;
wire receiver_lock;

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
// передатчик
transmitter Transmitter_Inst(
    .clk(clk),
    .ce(1'b1),
    .reset(reset),
	.bch_coder_on(1'b1),
    .interleaver_on(1'b1),
    .frame_former_on(1'b1),
    .data_in(infifo_indata),
    .data_in_we(infifo_we),
    .data_in_full(infifo_full),
    .data_out(transmitter_out),
    .data_out_valid(transmitter_valid)
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
    .DATA_IN(transmitter_out),
    .DATA_IN_VALID(transmitter_valid),
    .DATA_OUT(channel_out),
    .DATA_OUT_VALID(channel_valid),
    .ERROR_VALID(error_valid)
    );
				
// -------------------------------------------------------------------------------------------------------------------------			
// приемник
receiver Receiver_Inst(
    .clk(clk),
    .ce(1'b1),
    .reset(reset),
	.bch_decoder_on(1'b1),
    .deinterleaver_on(1'b1),
    .frame_finder_on(1'b1),
    .data_in(channel_out),
    .data_in_valid(channel_valid),
    .data_out(receiver_out),
    .data_out_valid(receiver_valid),
    .frame_sync_lock(receiver_lock)
    );

// -------------------------------------------------------------------------------------------------------------------------			
always @(posedge clk)
begin
    // подсчитываем и сохраняем данные от генератора
    if (infifo_we) begin
        TX_Bit_Vector[TX_Bit_Count] = infifo_indata;
        TX_Bit_Count = TX_Bit_Count + 1;
    end
    
    // подсчитываем и сохраняем данные от приемника
    if (receiver_valid) begin
        RX_Bit_Vector[RX_Bit_Count] = receiver_out;
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
            if (RX_Bit_Vector[loop_idx] != TX_Bit_Vector[loop_idx + PAYLOAD_LEN/N*K*(LOCK_COUNT+1)])
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
