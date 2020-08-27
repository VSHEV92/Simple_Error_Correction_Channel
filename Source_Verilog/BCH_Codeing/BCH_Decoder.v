`timescale 1ns / 1ps

module BCH_Decoder
#(
    parameter DEC_BCH_POLYNOM = 4'b1011,
    parameter DEC_N = 7,
    parameter DEC_K = 4
    )
    (
    input      CLK,
    input      RESET,
    input      DATA_IN,
    input      DATA_IN_VALID,
    output reg DATA_OUT,
    output reg DATA_OUT_VALID
    );

`include "Syndrome_Table.vh"
    
// счетчик битов закодированных данных    
reg [$clog2(DEC_N):0] Coded_Data_Counter;    

// счетчик битов данных    
reg [$clog2(DEC_K)-1:0] Data_Counter;    

// значение синдрома
reg [DEC_N-DEC_K-1:0] Syndrome_Value;
reg Syndrome_Valid;

// входной сдвиговый регистр
reg [DEC_N-1:0] Error_Value;
reg [DEC_N:0] Data_Shift_Reg;

// сдвиговый регистр декодера
reg [DEC_N-DEC_K-1:0] Decoder_Shift_Reg;

// выходной сдвиговый регистр
reg [DEC_K-1:0] Output_Shift_Reg;
reg Output_Shift_Start;

integer loop_idx;

// входной сдвиговый регистр
always @(posedge CLK)
    if (RESET) 
        Data_Shift_Reg <= 0;
    else if (DATA_IN_VALID) begin
        Data_Shift_Reg[DEC_N:1] <= Data_Shift_Reg[DEC_N-1:0];
        Data_Shift_Reg[0] <= DATA_IN; 
    end
// вычисление синдрома
always @(posedge CLK) begin
    Syndrome_Valid <= 1'b0;
    if (RESET) begin
        Decoder_Shift_Reg <= 0;
        Coded_Data_Counter <= 0;
    end else if (DATA_IN_VALID) begin
        Decoder_Shift_Reg[0] <= DATA_IN ^(Decoder_Shift_Reg[DEC_N-DEC_K-1] & DEC_BCH_POLYNOM[0]);
        
        for (loop_idx = 1; loop_idx < DEC_N-DEC_K; loop_idx = loop_idx + 1)
            Decoder_Shift_Reg[loop_idx] <= Decoder_Shift_Reg[loop_idx-1] ^ (Decoder_Shift_Reg[DEC_N-DEC_K-1] & DEC_BCH_POLYNOM[loop_idx]);
        
        Coded_Data_Counter <= Coded_Data_Counter + 1;
        
        if (Coded_Data_Counter == DEC_N) begin
            Syndrome_Value <= Decoder_Shift_Reg;
            Decoder_Shift_Reg[DEC_N-DEC_K-1:1] <= 0;
            Decoder_Shift_Reg[0] <= DATA_IN;
            Coded_Data_Counter <= 1;
            Syndrome_Valid <= 1'b1;        
        end
    end
end

// устранение ошибок и последовательная выдача данных    
always @(posedge CLK) begin
    DATA_OUT_VALID <= 1'b0;
    if (RESET) begin
        DATA_OUT_VALID <= 1'b0;
        DATA_OUT <= 1'b0;
        Output_Shift_Reg <= 0;
        Data_Counter <= 0;
        Output_Shift_Start <= 1'b0; 
    end else begin
        if (Syndrome_Valid && !Output_Shift_Start) begin
            Output_Shift_Start <= 1'b1;
            Data_Counter <= 0;
        
            Error_Value = SYNDROME_TABLE[DEC_N*Syndrome_Value +:DEC_N];
            Output_Shift_Reg <= Data_Shift_Reg[DEC_N:DEC_N-DEC_K+1] ^ Error_Value[DEC_K-1:0];
        end   
        else if (Output_Shift_Start) begin
            DATA_OUT_VALID <= 1'b1;
            DATA_OUT <= Output_Shift_Reg[DEC_K-1];
            
            Output_Shift_Reg[DEC_K-1:1] <= Output_Shift_Reg[DEC_K-2:0];
            Data_Counter <= Data_Counter + 1;
            
            if (Data_Counter == DEC_K-1) begin
               Output_Shift_Start <= 1'b0;
               Data_Counter <= 0;
            end
        end    
    end
end
endmodule
