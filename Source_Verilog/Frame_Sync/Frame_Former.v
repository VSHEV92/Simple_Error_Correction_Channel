`timescale 1ns / 1ps
//`include "Error_Correction_Channel_Header.vh"

module Frame_Former
#(
  parameter PREAMBLE_LEN = 30,
  parameter [PREAMBLE_LEN-1:0] PREAMBLE_VAL = 'h0123425,
  parameter PAYLOAD_LEN = 48
)
(
    input      CLK,
    input      RESET,
    // сигналы для входного FIFO 
    input      FIFO_IN_DATA,
    output reg FIFO_IN_RE,
    input      FIFO_IN_EMPTY,
    // сигналы для выходного FIFO 
    output reg FIFO_OUT_DATA,
    output reg FIFO_OUT_WE,
    input      FIFO_OUT_FULL
    );

// -----------------------------------------------------------------------------------------------------------------------------
// задаем состояния конечного автомата управления блоком
localparam INIT_STATE =              3'b000;
localparam CHECK_FIFO_OUT_PREAMBLE = 3'b001;
localparam SEND_PREAMBLE =           3'b010;
localparam WAIT_FIFO_IN =            3'b011;
localparam READ_FROM_FIFO_IN =       3'b100;
localparam GET_FROM_FIFO_IN =        3'b101;
localparam CHECK_FIFO_OUT_DATA =     3'b110;
localparam SEND_DATA =               3'b111;

reg [2:0] FSM_State;

// счетсчики числа бит преамбулы и данных
reg [$clog2(PREAMBLE_LEN)-1:0] Preamble_Counter; 
reg [$clog2(PAYLOAD_LEN)-1:0] Payload_Counter; 

// внутренний регистр для данных
reg Data_Internal; 

// -----------------------------------------------------------------------------------------------------------------------------
// переходы между состояниями автомата
always @(posedge CLK)
begin
    if (RESET) begin
       FSM_State <= INIT_STATE;
       Preamble_Counter <= 0;
       Payload_Counter <= 0;  
    end else begin
        case(FSM_State)      
            // Начальное состояние автомата, попадаем при включении
            INIT_STATE: begin
                FSM_State <= CHECK_FIFO_OUT_PREAMBLE;
                Preamble_Counter <= 0;
                Payload_Counter <= 0; 
            end
            
            // Проверка выходного FIFO перед выдачей преамбулы
            CHECK_FIFO_OUT_PREAMBLE: if (~FIFO_OUT_FULL) FSM_State <= SEND_PREAMBLE;
            
            // Выдача битов преамбулы    
            SEND_PREAMBLE: begin
                Preamble_Counter <= Preamble_Counter + 1;
                if (Preamble_Counter == PREAMBLE_LEN-1) begin
                    FSM_State <= WAIT_FIFO_IN;
                    Preamble_Counter <= 0;
                end
                else FSM_State <= CHECK_FIFO_OUT_PREAMBLE;
            end
            
            // Ожидание данных во входном FIFO
            WAIT_FIFO_IN: if (~FIFO_IN_EMPTY) FSM_State <= READ_FROM_FIFO_IN;
                
            // Запрос на чтение данных из входного FIFO    
            READ_FROM_FIFO_IN: FSM_State <= GET_FROM_FIFO_IN;
            
            // Получение данных из входного FIFO
            GET_FROM_FIFO_IN: begin
                FSM_State <= CHECK_FIFO_OUT_DATA;
                Data_Internal <= FIFO_IN_DATA;
            end
            
            // Проверка выходного FIFO перед выдачей данных
            CHECK_FIFO_OUT_DATA: if (~FIFO_OUT_FULL) FSM_State <= SEND_DATA;
            
            // Выдача битов данных
            SEND_DATA: begin
                Payload_Counter <= Payload_Counter + 1;
                if (Payload_Counter == PAYLOAD_LEN-1) begin
                    FSM_State <= CHECK_FIFO_OUT_PREAMBLE;
                    Payload_Counter <= 0;
                end
                else FSM_State <= WAIT_FIFO_IN;
            end
            
            // непредусмотренное состояние
            default: FSM_State <= INIT_STATE;
            
        endcase
    end
end

// -----------------------------------------------------------------------------------------------------------------------------
// выходные сигналы автомата
always @(*)
begin
    case(FSM_State)
    // Выдача преамбулы
    SEND_PREAMBLE: begin
        FIFO_IN_RE = 1'b0;
        FIFO_OUT_WE = 1'b1;
        FIFO_OUT_DATA = PREAMBLE_VAL[Preamble_Counter];
    end
    // Запрос на чтение данных из входного FIFO
    READ_FROM_FIFO_IN: begin
        FIFO_IN_RE = 1'b1;
        FIFO_OUT_WE = 1'b0;
        FIFO_OUT_DATA = 1'b0;
    end
    SEND_DATA: begin
    // Выдача битов данных
        FIFO_IN_RE = 1'b0;
        FIFO_OUT_WE = 1'b1;
        FIFO_OUT_DATA = Data_Internal;
    end
    // Другие состояния
    default: begin
        FIFO_IN_RE = 1'b0;
        FIFO_OUT_WE = 1'b0;
        FIFO_OUT_DATA = 1'b0;
    end
    endcase
end

endmodule
