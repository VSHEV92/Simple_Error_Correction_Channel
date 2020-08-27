`timescale 1ns / 1ps

module Interleaver
#(
    parameter ROW_NUMBER = 10,
    parameter COL_NUMBER = 7
)
(
    input  CLK,
    input  RESET,
    // сигналы для входного FIFO 
    input  FIFO_IN_DATA,
    output FIFO_IN_RE,
    input  FIFO_IN_EMPTY,
    // сигналы для выходного FIFO 
    output FIFO_OUT_DATA,
    output FIFO_OUT_WE,
    input  FIFO_OUT_FULL
);

// сигналы для чтения  
wire Data_Buff_1;
wire Data_Buff_2;
wire [$clog2(ROW_NUMBER*COL_NUMBER)-1:0] Buff_Rd_Addr;
wire Rd_Data_Internal;

// сигналы для записи
wire Wr_Data_Internal;
wire [$clog2(ROW_NUMBER*COL_NUMBER)-1:0] Buff_Wr_Addr;
wire Buff_1_Wr;
wire Buff_2_Wr;
wire Buff_Wr;

// вспомогательные сигналы
wire Read_Ack;
wire Read_Start;
wire Wr_Ping_Pong_Flag;
wire Rd_Ping_Pong_Flag;

// вспомогательные присваивания
assign Buff_1_Wr = Buff_Wr & ~Wr_Ping_Pong_Flag;
assign Buff_2_Wr = Buff_Wr & Wr_Ping_Pong_Flag;
assign Rd_Data_Internal = !Rd_Ping_Pong_Flag ? Data_Buff_1 : Data_Buff_2;
 
// блок записи в буфер
Interleaver_Write_Buffer
#(
    .ROW_NUMBER(ROW_NUMBER),
    .COL_NUMBER(COL_NUMBER)
    )
Interleaver_Write_Buffer_Inst    
    (
    .CLK(CLK),
    .RESET(RESET),
    // сигналы управления 
    .READ_ACK(Read_Ack),
    .READ_START(Read_Start),
    .PING_PONG_FLAG(Wr_Ping_Pong_Flag),
    // сигналы для входного FIFO 
    .FIFO_IN_DATA(FIFO_IN_DATA),
    .FIFO_IN_RE(FIFO_IN_RE),
    .FIFO_IN_EMPTY(FIFO_IN_EMPTY),
    // сигналы для выходного FIFO 
    .BUFF_DATA(Wr_Data_Internal),
    .BUFF_ADDR(Buff_Wr_Addr),
    .BUFF_WE(Buff_Wr)
    );
    
// блок чтения из буфера
Interleaver_Read_Buffer
#(
    .ROW_NUMBER(ROW_NUMBER),
    .COL_NUMBER(COL_NUMBER)
    )
Interleaver_Read_Buffer_Inst
    (
    .CLK(CLK),
    .RESET(RESET),
    // сигналы управления
    .PING_PONG_FLAG_IN(Wr_Ping_Pong_Flag),
    .PING_PONG_FLAG_OUT(Rd_Ping_Pong_Flag),
    .READ_START(Read_Start),
    .READ_ACK(Read_Ack),
    // сигналы для выходного FIFO
    .FIFO_DATA(FIFO_OUT_DATA),
    .FIFO_WRITE(FIFO_OUT_WE),
    .FIFO_FULL(FIFO_OUT_FULL),
    // сигналы для буфера
    .BUFF_DATA(Rd_Data_Internal),
    .BUFF_ADDR(Buff_Rd_Addr) 
    );
      
// BUFFER 1    
xpm_memory_sdpram #(
      .ADDR_WIDTH_A($clog2(ROW_NUMBER*COL_NUMBER)),   
      .ADDR_WIDTH_B($clog2(ROW_NUMBER*COL_NUMBER)),
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(1),         // DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String
      .MEMORY_SIZE(ROW_NUMBER*COL_NUMBER),       
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B(1),          // DECIMAL
      .READ_LATENCY_B(1),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(1),         // DECIMAL
      .WRITE_MODE_B("no_change")      // String
   )
   BUFFER_1_inst (
      .clka(CLK),  
      .clkb(CLK),                  
      .rstb(RESET),                     
      // ------------------------------------
      .doutb(Data_Buff_1),                          
      .addrb(Buff_Rd_Addr),                  
      .enb(1'b1),                      
      // ------------------------------------
      .dina(Wr_Data_Internal),
      .addra(Buff_Wr_Addr),
      .wea(Buff_1_Wr),                      
      .ena(1'b1),
      // ------------------------------------                      
      .regceb(1'b1),
      .injectdbiterra(1'b0), 
      .injectsbiterra(1'b0),    
      .sleep(1'b0)                                           
   );    
    
// BUFFER 2    
xpm_memory_sdpram #(
      .ADDR_WIDTH_A($clog2(ROW_NUMBER*COL_NUMBER)),   
      .ADDR_WIDTH_B($clog2(ROW_NUMBER*COL_NUMBER)),
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(1),         // DECIMAL
      .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String
      .MEMORY_SIZE(ROW_NUMBER*COL_NUMBER),       
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_B(1),          // DECIMAL
      .READ_LATENCY_B(1),             // DECIMAL
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(1),         // DECIMAL
      .WRITE_MODE_B("no_change")      // String
   )
   BUFFER_2_inst (
      .clka(CLK),  
      .clkb(CLK),                  
      .rstb(RESET),                     
      // ------------------------------------
      .doutb(Data_Buff_2),                          
      .addrb(Buff_Rd_Addr),                  
      .enb(1'b1),                      
      // ------------------------------------
      .dina(Wr_Data_Internal),
      .addra(Buff_Wr_Addr),
      .wea(Buff_2_Wr),                      
      .ena(1'b1),
      // ------------------------------------                      
      .regceb(1'b1),
      .injectdbiterra(1'b0), 
      .injectsbiterra(1'b0),    
      .sleep(1'b0)                                           
   );    
    
endmodule
