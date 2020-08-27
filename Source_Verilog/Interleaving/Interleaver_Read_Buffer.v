`timescale 1ns / 1ps

module Interleaver_Read_Buffer
#(
    parameter ROW_NUMBER = 10,
    parameter COL_NUMBER = 7
    )
    (
    input      CLK,
    input      RESET,
    // сигналы управления
    input      PING_PONG_FLAG_IN,
    output     PING_PONG_FLAG_OUT,
    input      READ_START,
    output reg READ_ACK,
    // сигналы для выходного FIFO
    output reg FIFO_DATA,
    output reg FIFO_WRITE,
    input      FIFO_FULL,
    // сигналы для буфера
    input      BUFF_DATA,
    output reg [$clog2(ROW_NUMBER*COL_NUMBER)-1:0] BUFF_ADDR 
    );

// -----------------------------------------------------------------------------------------------------------------------------
// задаем состояния конечного автомата управления блоком   
localparam INIT_STATE =       3'b000;
localparam WAIT_READ_START =  3'b001;
localparam SET_READ_ACK =     3'b010;
localparam SET_BUFF_ADDR =    3'b011;
localparam GET_BUFF_DATA =    3'b100;
localparam WAIT_OUT_FIFO =    3'b101;
localparam WRITE_TO_FIFO =    3'b110;

reg [2:0] FSM_State;

// счетчик битов данных
reg [ROW_NUMBER*COL_NUMBER-1:0] Bit_Counter;

// флаг выбора буфера для считывания
reg Ping_Pong_Flag_Value;    
    
// внутренний регистр для данных
reg Data_Internal;

// -----------------------------------------------------------------------------------------------------------------------------
// переходы между состояниями автомата
always @(posedge CLK)
    if (RESET) begin
        FSM_State <= INIT_STATE;
        Bit_Counter <= 0;
        Ping_Pong_Flag_Value <= 1'b0;
    end else begin
        case(FSM_State)
            // начальное состояние автомата
            INIT_STATE: begin
                Bit_Counter <= 0;
                FSM_State <= WAIT_READ_START;
            end
            
            // ожидание сигнала готовности от блока записи в буфер
            WAIT_READ_START: if (READ_START) FSM_State <= SET_READ_ACK;
            
            // подтверждение сигнала готовности данных от блока записи в буфер
            SET_READ_ACK: begin 
                Ping_Pong_Flag_Value <= PING_PONG_FLAG_IN;
                FSM_State <= SET_BUFF_ADDR;
            end
            
            // устанавливаем адрес бита в буфере
            SET_BUFF_ADDR: FSM_State <= GET_BUFF_DATA;
            
            // получаем бит из буфера
            GET_BUFF_DATA: begin
                Data_Internal <= BUFF_DATA;
                FSM_State <= WAIT_OUT_FIFO;
            end
            
            // ожидаем свободное место в выходном FIFO
            WAIT_OUT_FIFO: if (!FIFO_FULL) FSM_State <= WRITE_TO_FIFO;
            
            // записываем данные в выходное FIFO
            WRITE_TO_FIFO: begin
                Bit_Counter <= Bit_Counter + 1;
                if (Bit_Counter == ROW_NUMBER*COL_NUMBER-1)
                    FSM_State <= INIT_STATE;
                else 
                    FSM_State <= SET_BUFF_ADDR;    
            end
            
            // неожиданное состояние автомата
            default: FSM_State <= INIT_STATE;  
        endcase
    end

// -----------------------------------------------------------------------------------------------------------------------------
// выходные сигналы автомата
always @(*)
    case(FSM_State)
    
        // подтверждение сигнала готовности данных от блока записи в буфер
        SET_READ_ACK: begin
            READ_ACK = 1'b1;
            BUFF_ADDR = 0;
            FIFO_DATA = 1'b0; 
            FIFO_WRITE = 1'b0;
        end
        
        // устанавливаем адрес бита в буфере
        SET_BUFF_ADDR: begin
            READ_ACK = 1'b0;
            BUFF_ADDR = Bit_Counter;
            FIFO_DATA = 1'b0; 
            FIFO_WRITE = 1'b0;
            end
            
        // записываем данные в выходное FIFO
        WRITE_TO_FIFO: begin
            READ_ACK = 1'b0;
            BUFF_ADDR = 0;
            FIFO_DATA = Data_Internal; 
            FIFO_WRITE = 1'b1;
        end
            
        // любое другое состояние
        default: begin
            READ_ACK = 1'b0;
            BUFF_ADDR = 0;
            FIFO_DATA = 1'b0; 
            FIFO_WRITE = 1'b0;
            end      
    endcase
    
assign PING_PONG_FLAG_OUT = Ping_Pong_Flag_Value;    
        
endmodule
