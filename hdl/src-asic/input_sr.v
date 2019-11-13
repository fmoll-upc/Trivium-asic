//////////////////////////////////////////////////////////////////////////////////
// Developer:         F. Moll
// 
// Create Date:      21 October 2019 
// Module Name:      cipher_engine
// Project Name:     Trivium-asic
// Description:      A simple shift register that stores the key and IV (80+80 bits).
// 					 Serial input, IV first, LSB first.
//
// Dependencies:     /
//
// Revision: 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none

module input_sr #(
    parameter REG_SZ = 93
) 
(
    /* Standard control signals */
    input   wire            clk_i,      /* System clock */
    input   wire            n_rst_i,    /* Asynchronous active low reset */
    input   wire            ce_i,       /* Chip enable */

	input  wire             reg_in_i,   /* Serial input */
	output reg       		[(REG_SZ - 1):0]    dat_o;      /* Shift register output */
);

reg       		[(REG_SZ - 1):0]    dat_r;      /* Shift register output */

//////////////////////////////////////////////////////////////////////////////////
// Shift register process
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_i or negedge n_rst_i) begin
    if (!n_rst_i)
        dat_r <= 0;
    else begin
        if (ce_i) begin
            /* Shift contents of register */
            dat_r <= {dat_r[(REG_SZ - 2):0], reg_in_i};
        end
    end
end

assign dat_o <= dat_r;

endmodule
