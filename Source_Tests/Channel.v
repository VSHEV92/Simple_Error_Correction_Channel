`timescale 1ns / 1ps

module Channel
#(
    parameter ERROR_PROB = 0.01
    )
    (
    input CLK,
    input RESET,
    input  DATA_IN,
    input  DATA_IN_VALID,
    output ERROR_VALID,
    output DATA_OUT,
    output DATA_OUT_VALID
    );

integer rand_val;
real rand_val_real;
reg error;

// генератор ошибок    
always @(posedge CLK) begin
    rand_val = $urandom % 1_000_000;
    rand_val_real = $itor(rand_val)/1_000_000;
    if (rand_val_real < ERROR_PROB)
        error = 1'b1;
    else
        error = 1'b0;
end

assign DATA_OUT = DATA_IN ^ error;
assign DATA_OUT_VALID = DATA_IN_VALID;
assign ERROR_VALID = DATA_IN_VALID & error;
    
endmodule
