//////////////////////////////////////////////////////////////////////////////////
// Developer:         F. Moll
// 
// Create Date:      21 October 2019 
// Module Name:      cipher_engine
// Project Name:     Trivium-asic
// Description:      A simple shift register that may be pre-loaded. The shift register
//                   incorporates a specified feedback and feedforward path.
//                   This component is designed in such a way that the logic required for
//                   Trivium can be obtained by combining three such register, each with
//                   a specific set of parameters. Modification of the original Trivium project.
//
// Dependencies:     /
//
// Revision: 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none

module trivium_sr #(
    parameter REG_SZ = 93,
    parameter FEED_FWD_IDX = 66, /* index according to specs (1:REG_SZ) */
    parameter FEED_BKWD_IDX = 69 /* index according to specs (1:REG_SZ) */
) 
// Note:
// indexes assume register goes from 1 to REG_SZ, 
// so the bit of the register is IDX-1
// 
(
    /* Standard control signals */
    input   wire            clk_i,      /* System clock */
    input   wire            n_rst_i,    /* Asynchronous active low reset */
    input   wire            ce_i,       /* Chip enable */
      
   /* Input and output data related signals */
    input   wire   		    ld_i,       /* Load external value */
    input   wire    [(REG_SZ-1):0]  ld_dat_i,   /* External input data to load */
    input   wire            dat_i,      /* Input bit from other register */
    input   wire            z_i,      /* Input key bit from other register */
    output  wire            dat_o,      /* Output bit  to other register */
    output  wire            z_o         /* Output for the key stream */
);

//////////////////////////////////////////////////////////////////////////////////
// Signal definitions
//////////////////////////////////////////////////////////////////////////////////
reg     [(REG_SZ - 1):0]    dat_r;      /* Shift register contents */
wire                        reg_in_s;   /* Shift register input (feedback value) */

//////////////////////////////////////////////////////////////////////////////////
// Feedback calculation
//////////////////////////////////////////////////////////////////////////////////
assign reg_in_s = dat_i ^ dat_r[(FEED_BKWD_IDX-1)] ^ z_i; /* Added z_i, missing in original project */
//assign reg_in_s = dat_i ^ dat_r[(FEED_BKWD_IDX-1)] ; 

//////////////////////////////////////////////////////////////////////////////////
// Shift register process
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_i or negedge n_rst_i) begin
    if (!n_rst_i)
        dat_r <= {REG_SZ{1'b0}};
    else begin
        if (ce_i) begin
            /* Shift contents of register */
            dat_r <= {dat_r[(REG_SZ - 2):0], reg_in_s};
        end
        else if (ld_i != 0) begin /* Load external values into register */
            dat_r[(REG_SZ - 1):0] <= ld_dat_i;
        end
    end
end

//////////////////////////////////////////////////////////////////////////////////
// Output calculations
//////////////////////////////////////////////////////////////////////////////////
assign z_o = (dat_r[REG_SZ - 1] ^ dat_r[FEED_FWD_IDX-1]);
assign dat_o = (dat_r[REG_SZ - 2] & dat_r[REG_SZ - 3]) ; /* Modified from original */
//assign dat_o = z_o ^ (dat_r[REG_SZ - 2] & dat_r[REG_SZ - 3]) ; 

endmodule
