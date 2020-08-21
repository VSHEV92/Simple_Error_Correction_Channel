`timescale 1ns / 1ps

module Data_Generator
    #(parameter BITS_NUMB = 10 )
    (
    input CLK,
    input RESET,
    input START,
    // сигналы для выходного FIFO 
    output reg FIFO_OUT_DATA,
    output reg FIFO_OUT_WE,
    input      FIFO_OUT_FULL
    );
    
// -----------------------------------------------------------------------------------------------------------------------------
// задаем состояния конечного автомата управления блоком
parameter INIT_STATE =          3'b000;
parameter CHECK_FIFO_OUT_DATA = 3'b001;
parameter SEND_DATA =           3'b010;
parameter GENERATION_REPORT =   3'b011;
parameter IDLE =                3'b100;

reg [2:0] FSM_State;
 
 // счетсчик числа бит данных
reg [$clog2(BITS_NUMB)-1:0] Bits_Counter; 

// -----------------------------------------------------------------------------------------------------------------------------
// переходы между состояниями автомата
always @(posedge CLK)
begin
    if (RESET) begin
       FSM_State <= INIT_STATE;
       Bits_Counter <= 0;
    end else begin
        case(FSM_State)      
            // Начальное состояние автомата, попадаем при включении
            INIT_STATE: if(START) FSM_State <= CHECK_FIFO_OUT_DATA;
            
            // Проверка выходного FIFO перед выдачей данных
            CHECK_FIFO_OUT_DATA: if (~FIFO_OUT_FULL) FSM_State <= SEND_DATA;
            
            // Выдача битов данных
            SEND_DATA: begin
                Bits_Counter <= Bits_Counter + 1;
                if (Bits_Counter == BITS_NUMB-1) begin
                    FSM_State <= GENERATION_REPORT;
                    Bits_Counter <= 0;
                end
                else FSM_State <= CHECK_FIFO_OUT_DATA;
            end
            
            // вывод сообщения об окончании генерации данных
            GENERATION_REPORT: begin
                FSM_State <= IDLE;
                $display("Data generation done at time %0t ps", $realtime);
            end
            
            // конечное соостояние после выдачи всех данных
            IDLE: FSM_State <= IDLE;
            
            // непредусмотренное состояние
            default: begin
                FSM_State <= INIT_STATE;
                $error("Unexpected FSM State");
            end
        endcase
    end
end
   
// -----------------------------------------------------------------------------------------------------------------------------
// выходные сигналы автомата
always @(*)
begin
    case(FSM_State)
    SEND_DATA: begin
    // Выдача битов данных
        FIFO_OUT_WE = 1'b1;
        FIFO_OUT_DATA = $random;
    end
    // Другие состояния
    default: begin
        FIFO_OUT_WE = 1'b0;
        FIFO_OUT_DATA = 1'b0;
    end
    endcase
end
    
    
endmodule
