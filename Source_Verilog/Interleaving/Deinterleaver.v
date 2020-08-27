`timescale 1ns / 1ps

module Deinterleaver
#(
    parameter ROW_NUMBER = 10,
    parameter COL_NUMBER = 7
    )
    (
    input      CLK,
    input      RESET,
    input      DATA_IN,
    input      DATA_IN_VALID,
    output reg DATA_OUT,
    output reg DATA_OUT_VALID
    );
    
// счетчик рядов матрициы перемежения
reg [$clog2(ROW_NUMBER)-1:0] Row_Counter;
 
// счетчик столбцов матрицы перемежения
reg [$clog2(COL_NUMBER)-1:0] Col_Counter;

// счетчик битов данных
reg [$clog2(ROW_NUMBER*COL_NUMBER)-1:0] Bit_Counter;

// задержка строба входных данных
reg DATA_IN_VALID_delay_1, DATA_IN_VALID_delay_2;    

//сигналы начала выдачи данных
reg Output_Start, Output_Start_delay_1, Output_Start_delay_2;

//флаги выбора буфера для записи и чтения
reg Ping_Pong_Flag, Ping_Pong_Flag_delay_1, Ping_Pong_Flag_delay_2;
 
//адреса и сигналы для чтения и записи в буферы
reg [$clog2(ROW_NUMBER*COL_NUMBER)-1:0] Buff_Rd_Addr;
reg [$clog2(ROW_NUMBER*COL_NUMBER)-1:0] Buff_Wr_Addr;
reg Wr_Data_Internal;

wire Data_Buff_1;
wire Data_Buff_2;
reg Buff_1_Wr;
reg Buff_2_Wr;

// -------------------------------------------------------------------------------------------------------
// формирование сигналов для записи в буфер
always @(posedge CLK)
    if (RESET) begin
        Wr_Data_Internal <= 1'b0;
        Buff_1_Wr <= 1'b0;
        Buff_2_Wr <= 1'b0;
    end
    else begin
        Wr_Data_Internal <= DATA_IN;
        Buff_1_Wr <= DATA_IN_VALID & ~Ping_Pong_Flag;
        Buff_2_Wr <= DATA_IN_VALID & Ping_Pong_Flag;
    end 
        
// счетчик и формирователь адреса данных для записи        
always @(posedge CLK)
    if (RESET) begin
        Buff_Wr_Addr <= 0;
        Col_Counter <= 0;
        Row_Counter <= 0;
        Ping_Pong_Flag <= 1'b0;
        Output_Start <= 1'b0; 
    end else if (DATA_IN_VALID) begin
        Buff_Wr_Addr <= Row_Counter*COL_NUMBER + Col_Counter;
        Row_Counter <= Row_Counter + 1;
        if (Row_Counter == ROW_NUMBER-1) begin
            Row_Counter <= 0;
            Col_Counter <= Col_Counter + 1;
            if (Col_Counter == COL_NUMBER-1) begin
                Col_Counter <= 0;
                Output_Start <= 1'b1; // устанавливаем флаг после первого заполнения буфера
                Ping_Pong_Flag <= ~Ping_Pong_Flag;  
            end
        end
    end        
 
// -------------------------------------------------------------------------------------------------------
// формирование выходных данных
always @(posedge CLK)
    if (RESET) begin
        DATA_OUT <= 1'b0;
        DATA_OUT_VALID <= 1'b0;
        Ping_Pong_Flag_delay_1 <= 1'b0;
        Ping_Pong_Flag_delay_2 <= 1'b0;
        Output_Start_delay_1 <= 1'b0;
        Output_Start_delay_2 <= 1'b0;
        DATA_IN_VALID_delay_1 <= 1'b0;
        DATA_IN_VALID_delay_2 <= 1'b0;    
    end 
    else begin
        // DATA_OUT
        Ping_Pong_Flag_delay_1 <= Ping_Pong_Flag;
        Ping_Pong_Flag_delay_2 <= Ping_Pong_Flag_delay_1;
        if (Ping_Pong_Flag_delay_2)
            DATA_OUT <= Data_Buff_1;
        else 
            DATA_OUT <= Data_Buff_2;
        
        // DATA_OUT_VALID
        DATA_IN_VALID_delay_1 <= DATA_IN_VALID;
        DATA_IN_VALID_delay_2 <= DATA_IN_VALID_delay_1;
        Output_Start_delay_1 <= Output_Start;
        Output_Start_delay_2 <= Output_Start_delay_1;
        DATA_OUT_VALID <= Output_Start_delay_2 & DATA_IN_VALID_delay_2;   
    end
    
// счетчик и формирователь адреса данных для чтения        
always @(posedge CLK)
    if (RESET) begin
        Buff_Rd_Addr <= 0;
        Bit_Counter <= 0; 
    end else if (DATA_IN_VALID) begin
        Buff_Rd_Addr <= Bit_Counter;
        Bit_Counter <= Bit_Counter + 1;
        if (Bit_Counter == COL_NUMBER*ROW_NUMBER-1)
            Bit_Counter <= 0;
    end
    
// -------------------------------------------------------------------------------------------------------
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
