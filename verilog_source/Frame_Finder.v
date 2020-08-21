`timescale 1ns / 1ps

module Frame_Finder
    #(
    parameter DETECT_THRESH = 5,
    parameter PAYLOAD_LEN = 5,
    parameter LOCK_COUNT = 5,
    parameter UNLOCK_COUNT = 5,
    parameter PREAMBLE_LEN = 8,
    parameter [PREAMBLE_LEN-1:0] PREAMBLE_VAL = 8'b01110011
    )
    (
    input  CLK,
    input  RESET,
    input  DATA_IN,
    input  DATA_IN_VALID,
    output DATA_OUT,
    output DATA_OUT_VALID,
    output LOCK
    );
    
// внутренние константы блока
localparam PREAMBLE_SHIFT_REG_LEN = 2**($clog2(PREAMBLE_LEN));
localparam PREAMBLE_SUM_STAGES = $clog2(PREAMBLE_LEN);

// входной регистр сдвига    
reg [PREAMBLE_SUM_STAGES+4:0] Input_Shift_Reg;

// сигнал захвата синхронизации
reg Sync_State;

// счетчики числа обнаруженных и пропущенных преамбул
integer lock_counter, unlock_counter;

// счетчик полученных бит в кадре
integer frame_bit_counter;

// выходные сигналы детектора преамбулы
wire Detect_Out, Detect_Valid;
    
// флаг данных в кадре
reg Payload_Valid;

// входной регистр сдвига
always @(posedge CLK)
    if (RESET)
        Input_Shift_Reg <= 0;
    else if (DATA_IN_VALID)
        Input_Shift_Reg <= {Input_Shift_Reg[PREAMBLE_SUM_STAGES+3:0], DATA_IN};    
 
// блок управления переменными кадровой синхронизации
always @(posedge CLK)
    if (RESET) begin
        frame_bit_counter <= 0;
        lock_counter <= 0;
        unlock_counter <= 0;
        Sync_State <= 0;
        Payload_Valid <= 0;
    end else if (DATA_IN_VALID) begin
        Payload_Valid <= 0;
        frame_bit_counter <= frame_bit_counter + 1;
        // --------------------------------------------------------------
        // если нет захвата
        if (!Sync_State) begin
            unlock_counter <= 0;
            // если полученно заданное количество бит
            if (frame_bit_counter == PAYLOAD_LEN + PREAMBLE_LEN - 1)
                // если преамбула обнаружена, увеличиваем число обнаруженных преамбул 
                if (Detect_Out) begin
                    frame_bit_counter <= 0;
                    lock_counter <= lock_counter + 1;
                    if (lock_counter == LOCK_COUNT - 1)
                        Sync_State <= 1'b1;
                end else begin
                    frame_bit_counter <= 0;
                    lock_counter <= 0;
                end
            // если преамбула обнаружена в произвольном месте, то обнуляем счетчик
            else if (Detect_Out) begin
                frame_bit_counter <= 0;
                lock_counter <= 0;
            end    
        end                  
        // --------------------------------------------------------------
        // если захвата уже произведен
        if (Sync_State) begin
            lock_counter <= 0;
            // устанавливаем флаг данных в кадре после обнаружения преамбулы           
            if (frame_bit_counter < PAYLOAD_LEN) Payload_Valid <= 1'b1;
            // если получено заданное число бит
            if (frame_bit_counter == PAYLOAD_LEN + PREAMBLE_LEN - 1)
                // если преамбула не обнаружена, увеличиваем число необнаруженных преамбул
                if (!Detect_Out) begin
                    frame_bit_counter <= 0;
                    unlock_counter <= unlock_counter + 1;
                    if (unlock_counter == UNLOCK_COUNT - 1) Sync_State <= 1'b0;
                // иначе обнуляем счетчик необнаруженных преамбул
                end else begin
                    frame_bit_counter <= 0;
                    unlock_counter <= 0;
                end
        end
    end

// -------------------------------------------------------------------------------
Preamble_Finder
    #(
    .DETECT_THRESH(DETECT_THRESH),
    .PREAMBLE_LEN(PREAMBLE_LEN),
    .PREAMBLE_VAL(PREAMBLE_VAL)
    )
Preamble_Finder_Inst    
    (
    .CLK(CLK),
    .RESET(RESET),
    .DATA_IN(DATA_IN),
    .DATA_IN_VALID(DATA_IN_VALID),
    .DETECT_OUT(Detect_Out),
    .DETECT_OUT_VALID(Detect_Valid)
    );
 
// формирование выходных сигналов 
assign LOCK = Sync_State;
assign DATA_OUT = Input_Shift_Reg[PREAMBLE_SUM_STAGES + 4];
assign DATA_OUT_VALID = DATA_IN_VALID & Payload_Valid;

endmodule
