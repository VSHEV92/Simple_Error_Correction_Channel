// ---------------------------------------------------------------------------------------------
// выбор варианта тракта
parameter CHANNEL_PATTERN = 6;

generate 
if (CHANNEL_PATTERN == 1) begin
    `define BCH_POLYNOM_VAL 4'b1011
    `define N_VAL 7
    `define K_VAL 4
    `define ROW_NUMBER_VAL 142	
end	
if (CHANNEL_PATTERN == 2) begin
    `define BCH_POLYNOM_VAL 5'b10011
    `define N_VAL 15
    `define K_VAL 11
    `define ROW_NUMBER_VAL 67	
end	
if (CHANNEL_PATTERN == 3) begin
    `define BCH_POLYNOM_VAL 9'b111010001
    `define N_VAL 15
    `define K_VAL 7
    `define ROW_NUMBER_VAL 67	
end
if (CHANNEL_PATTERN == 4) begin
    `define BCH_POLYNOM_VAL 6'b100101
    `define N_VAL 31
    `define K_VAL 26
    `define ROW_NUMBER_VAL 34	
end	
if (CHANNEL_PATTERN == 5) begin
    `define BCH_POLYNOM_VAL 11'b11101101001
    `define N_VAL 31
    `define K_VAL 21
    `define ROW_NUMBER_VAL 34	
end	
if (CHANNEL_PATTERN == 6) begin
    `define BCH_POLYNOM_VAL 16'b1000111110101111
    `define N_VAL 31
    `define K_VAL 16
    `define ROW_NUMBER_VAL 34	
end		
endgenerate

// ---------------------------------------------------------------------------------------------
// параметры БЧХ кодера
parameter BCH_POLYNOM = `BCH_POLYNOM_VAL;
parameter N = `N_VAL;
parameter K = `K_VAL;

// параметры перемежителя
parameter ROW_NUMBER = `ROW_NUMBER_VAL;
parameter COL_NUMBER = `N_VAL;

// ---------------------------------------------------------------------------------------------
// параметры преамбулы
parameter PREAMBLE_LEN = 64;
parameter [PREAMBLE_LEN-1:0] PREAMBLE_VAL = 'b0010011101001010000000001100111100110001101110000011100101110110;

// параметры блоков добавления преамбулы и кадровой синхронизации
parameter DETECT_THRESH = 50;
parameter LOCK_COUNT = 3;
parameter UNLOCK_COUNT = 10;

parameter PAYLOAD_LEN = COL_NUMBER*ROW_NUMBER;

// ---------------------------------------------------------------------------------------------
parameter Transmitter_Fifo_Depth = 64;



	
