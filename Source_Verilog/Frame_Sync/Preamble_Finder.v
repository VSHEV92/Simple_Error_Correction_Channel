`timescale 1ns / 1ps

module Preamble_Finder
    #(
    parameter DETECT_THRESH = 5,
    parameter PREAMBLE_LEN = 8,
    parameter [PREAMBLE_LEN-1:0] PREAMBLE_VAL = 8'b01110011
    )
    (
    input      CLK,
    input      RESET,
    input      DATA_IN,
    input      DATA_IN_VALID,
    output reg DETECT_OUT,
    output reg DETECT_OUT_VALID
    );

// внутренние константы блока
localparam PREAMBLE_SHIFT_REG_LEN = 2**($clog2(PREAMBLE_LEN));
localparam PREAMBLE_SUM_STAGES = $clog2(PREAMBLE_LEN);

// входной сдвиговый регистр
reg [PREAMBLE_LEN-1:0] Preamble_Shift_Reg;
// регистр побитового сравнения
reg [PREAMBLE_SHIFT_REG_LEN-1:0] Preamble_Xor_Reg;
// массив вычисления количества совпавших бит
integer Sum_Val_Array [0:PREAMBLE_SUM_STAGES-1][0:PREAMBLE_SHIFT_REG_LEN/2-1];
// результат суммирования
integer Sum_Result;
// переменные для циклов
integer idx, sum_stage;

// регистр сдвига для поиска преамбулы
always @(posedge CLK)
    if (RESET)
        Preamble_Shift_Reg <= 0;
    else if (DATA_IN_VALID)
        Preamble_Shift_Reg <= {DATA_IN, Preamble_Shift_Reg[PREAMBLE_LEN-1:1]};    

// сравнение входного регистра с преамбулой
always @(posedge CLK)
    if (RESET)
        Preamble_Xor_Reg <= 0;
    else if (DATA_IN_VALID) begin
        Preamble_Xor_Reg <= 'b0;
        Preamble_Xor_Reg[PREAMBLE_LEN-1:0] <= ~(Preamble_Shift_Reg ^ PREAMBLE_VAL[PREAMBLE_LEN-1:0]);
    end
    
// процесс суммирования удиниц в регистре сравнения
always @(posedge CLK)
    if (RESET) begin
        Sum_Result <= 0;
        for (sum_stage = 0; sum_stage<PREAMBLE_SUM_STAGES; sum_stage = sum_stage + 1)
            for (idx = 0; idx<PREAMBLE_SHIFT_REG_LEN/2; idx = idx + 1)
                Sum_Val_Array[sum_stage][idx] <= 0;
    end else if (DATA_IN_VALID) begin
        // суммирование единиц в регистре сравнения
        for (idx = 0; idx<PREAMBLE_SHIFT_REG_LEN/2; idx = idx + 1)
            Sum_Val_Array[0][idx] <= Preamble_Xor_Reg[idx] + Preamble_Xor_Reg[idx + PREAMBLE_SHIFT_REG_LEN/2];
        // остальные стадии суммирования
        for (sum_stage = 1; sum_stage<PREAMBLE_SUM_STAGES; sum_stage = sum_stage + 1)
            for (idx = 0; idx<PREAMBLE_SHIFT_REG_LEN/(2**(sum_stage+1)); idx = idx + 1)
                Sum_Val_Array[sum_stage][idx] <= Sum_Val_Array[sum_stage-1][idx] + Sum_Val_Array[sum_stage-1][idx+PREAMBLE_SHIFT_REG_LEN/(2**(sum_stage+1))];    
        // сохранение результата суммирования
        Sum_Result <= Sum_Val_Array[PREAMBLE_SUM_STAGES-1][0];
    end

// результата сравнения с порогом
always @(posedge CLK) begin
    DETECT_OUT_VALID <= 0;
    if (RESET) 
        {DETECT_OUT, DETECT_OUT_VALID} <= {1'b0,1'b0};
    else if (DATA_IN_VALID) begin
        if (Sum_Result >= DETECT_THRESH)
            DETECT_OUT <= 1;
        else
            DETECT_OUT <= 0;
        DETECT_OUT_VALID <= 1;
    end       
end

endmodule

