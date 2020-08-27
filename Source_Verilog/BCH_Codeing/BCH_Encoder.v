`timescale 1ns / 1ps

module BCH_Encoder
#(
    parameter BCH_POLYNOM = 4'b1011,
    parameter N = 7,
    parameter K = 4
)
(
    input CLK,
    input RESET,
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
localparam READ_FROM_FIFO_IN =       3'b001;
localparam GET_FROM_FIFO_IN =        3'b010;
localparam CHECK_FIFO_OUT_DATA =     3'b011;
localparam SEND_DATA =               3'b100;
localparam CHECK_FIFO_OUT_PARITY =   3'b101;
localparam SEND_PARITY =             3'b110;

reg [2:0] FSM_State;
    
// счетчик битов четности
reg [$clog2(N-K)-1:0] Parity_Counter;

// счетчик битов данных
reg [$clog2(K)-1:0] Data_Counter;

// сдвиговый регистр
reg [N-K-1:0] Data_Shift_Reg;

// внутренний регистр данных
reg Data_Internal;

// вспомогательные сигналы
reg Xor_Result;
integer loop_idx;
   
// -----------------------------------------------------------------------------------------------------------------------------
// переходы между состояниями автомата
always @(posedge CLK)
    if (RESET) begin
       FSM_State <= INIT_STATE;
       Data_Counter <= 0;
       Parity_Counter <= 0;
       Data_Shift_Reg <= 0;  
    end else begin
        case(FSM_State)
            // Начальное состояние автомата, попадаем при включении
            INIT_STATE: if (!FIFO_IN_EMPTY) FSM_State <= READ_FROM_FIFO_IN;
        
            // Запрос данных из входного FIFO
            READ_FROM_FIFO_IN: FSM_State <= GET_FROM_FIFO_IN;
            
            // Защелкиваем данные из входного FIFO
            GET_FROM_FIFO_IN: begin
                Xor_Result = FIFO_IN_DATA ^ Data_Shift_Reg[N-K-1];
                Data_Shift_Reg[0] <= Xor_Result;
                
               for(loop_idx = 1; loop_idx < N-K; loop_idx = loop_idx + 1)
                   Data_Shift_Reg[loop_idx] <= Data_Shift_Reg[loop_idx-1] ^ (Xor_Result & BCH_POLYNOM[loop_idx]);
               
               Data_Internal <= FIFO_IN_DATA;
               FSM_State <= CHECK_FIFO_OUT_DATA;
            end
            
            // Проверка на заполнение выходного FIFO
            CHECK_FIFO_OUT_DATA: if (!FIFO_OUT_FULL) FSM_State <= SEND_DATA;
        
            // Выдача битов данных
            SEND_DATA: begin
                Data_Counter <= Data_Counter + 1;
                if (Data_Counter == K-1) begin
                    FSM_State <= CHECK_FIFO_OUT_PARITY;
                    Data_Counter <= 0;
                end else
                    FSM_State <= INIT_STATE;
            end
            
            // Проверка на заполнение выходного FIFO перед выдачей бит четности
            CHECK_FIFO_OUT_PARITY: if (!FIFO_OUT_FULL) FSM_State <= SEND_PARITY;
            
            // Выдача битов четности
            SEND_PARITY: begin
                Parity_Counter <= Parity_Counter + 1;
                Data_Shift_Reg[0] <= 1'b0;
                 
               for(loop_idx = 1; loop_idx < N-K; loop_idx = loop_idx + 1)
                   Data_Shift_Reg[loop_idx] <= Data_Shift_Reg[loop_idx-1];
               
               if (Parity_Counter == N - K-1) begin
                    FSM_State <= INIT_STATE;
                    Parity_Counter <= 0;
                end else
                    FSM_State <= CHECK_FIFO_OUT_PARITY; 
            end
            
            // непредусмотренное состояние
            default: begin
                FSM_State <= INIT_STATE;
                Data_Counter <= 0;
                Parity_Counter <= 0;
                Data_Shift_Reg <= 0;  
            end 
        endcase     
    end   

// -----------------------------------------------------------------------------------------------------------------------------
// выходные сигналы автомата
always @(*)
    case(FSM_State)
        // выдача бытов данных
        SEND_DATA: begin 
            FIFO_IN_RE = 1'b0; 
            FIFO_OUT_WE = 1'b1; 
            FIFO_OUT_DATA = Data_Internal;
        end
        // запрос данных из входного FIFO
        READ_FROM_FIFO_IN: begin
            FIFO_IN_RE = 1'b1; 
            FIFO_OUT_WE = 1'b0; 
            FIFO_OUT_DATA = 1'b0;
        end
        // выдача бытов четности
        SEND_PARITY: begin
            FIFO_IN_RE = 1'b0; 
            FIFO_OUT_WE = 1'b1; 
            FIFO_OUT_DATA = Data_Shift_Reg[N-K-1];
        end
        // любое другое состояние
        default: begin
            FIFO_IN_RE = 1'b0; 
            FIFO_OUT_WE = 1'b0; 
            FIFO_OUT_DATA = 1'b0;
        end
    endcase
   
endmodule
