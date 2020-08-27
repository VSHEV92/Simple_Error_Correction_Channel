`timescale 1ns / 1ps

module Interleaver_Write_Buffer
#(
    parameter ROW_NUMBER = 10,
    parameter COL_NUMBER = 7
    )
    (
    input CLK,
    input RESET,
    // сигналы управления 
    input      READ_ACK,
    output reg READ_START,
    output     PING_PONG_FLAG,
    // сигналы для входного FIFO 
    input      FIFO_IN_DATA,
    output reg FIFO_IN_RE,
    input      FIFO_IN_EMPTY,
    // сигналы для выходного FIFO 
    output reg BUFF_DATA,
    output reg [$clog2(ROW_NUMBER*COL_NUMBER)-1:0] BUFF_ADDR,
    output reg BUFF_WE
    );

// -----------------------------------------------------------------------------------------------------------------------------
// задаем состояния конечного автомата управления блоком   
localparam INIT_STATE =       3'b000;
localparam WAIT_FIFO_DATA =   3'b001;
localparam READ_FROM_FIFO =   3'b010;
localparam GET_FROM_FIFO =    3'b011;
localparam WRITE_TO_BUFF =    3'b100;
localparam WAIT_READ_ACK =    3'b101;

reg [2:0] FSM_State;

// счетчик рядов матрициы перемежения
reg [$clog2(ROW_NUMBER)-1:0] Row_Counter;
 
// счетчик столбцов матрицы перемежения
reg [$clog2(COL_NUMBER)-1:0] Col_Counter;

// флаг выбора буфера для записи
reg Ping_Pong_Flag_value;

// внутренний регистр входных данных
reg Data_Internal;
 
// -----------------------------------------------------------------------------------------------------------------------------
// переходы между состояниями автомата
always @(posedge CLK)
    if (RESET) begin
       FSM_State <= INIT_STATE;
       Row_Counter <= 0;
       Col_Counter <= 0;
       Ping_Pong_Flag_value <= 1'b0;
       READ_START <= 1'b0;
   end else begin
       case(FSM_State)
           // начальное состояние автомата
           INIT_STATE: begin
               Row_Counter <= 0;
               Col_Counter <= 0;
               FSM_State <= WAIT_FIFO_DATA;
           end
           
           // ожидаем данных во входном FIFO
           WAIT_FIFO_DATA: if (!FIFO_IN_EMPTY) FSM_State <= READ_FROM_FIFO;
           
           // запрашиваем данные из входного FIFO
           READ_FROM_FIFO: FSM_State <= GET_FROM_FIFO;
           
           // защелкиваем данные из входного FIFO
           GET_FROM_FIFO: begin
               Data_Internal <= FIFO_IN_DATA;
               FSM_State <= WRITE_TO_BUFF;
           end
           
           // записываем данные в буфер
           WRITE_TO_BUFF: begin
               Col_Counter <= Col_Counter + 1;
               FSM_State <= WAIT_FIFO_DATA;
               if (Col_Counter == COL_NUMBER-1) begin
                   Col_Counter <= 0;
                   Row_Counter <= Row_Counter + 1;
                   if (Row_Counter == ROW_NUMBER-1) begin
                       READ_START <= 1'b1;        // если это последняя строка, инвертируем флаг буфера и выставляем флаг готовности данных
                       FSM_State <= WAIT_READ_ACK;
                   end
               end
           end
           
           // ожидаем окончения считывания данных из буфера
           WAIT_READ_ACK: if (READ_ACK) begin
               READ_START <= 1'b0; 
               Ping_Pong_Flag_value <= ~Ping_Pong_Flag_value;
               FSM_State <= INIT_STATE;    
           end
           
           // неожиданное состояние
           default: begin
               FSM_State <= INIT_STATE;
               READ_START <= 1'b0;
           end
       endcase
   end

// -----------------------------------------------------------------------------------------------------------------------------
// выходные сигналы автомата
always @(*)
    case(FSM_State)
        // состояние считывания данных из FIFO
        READ_FROM_FIFO: begin
            FIFO_IN_RE = 1'b1;
            BUFF_DATA = 1'b0;
            BUFF_ADDR = 0;
            BUFF_WE = 1'b0;
        end
        
        // состояние записи данных в буфер
        WRITE_TO_BUFF: begin
            FIFO_IN_RE = 1'b0;
            BUFF_DATA = Data_Internal;
            BUFF_ADDR = Col_Counter*ROW_NUMBER + Row_Counter;
            BUFF_WE = 1'b1;
        end
    
        // любое другое состояние
        default: begin
            FIFO_IN_RE = 1'b0;
            BUFF_DATA = 1'b0;
            BUFF_ADDR = 0;
            BUFF_WE = 1'b0;
        end
    endcase   
 
 // выдача флага выбора буфера  
 assign PING_PONG_FLAG = Ping_Pong_Flag_value;
   
endmodule
