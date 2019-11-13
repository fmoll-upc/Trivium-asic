//////////////////////////////////////////////////////////////////////////////////
// Developer:         F. Moll
// 
// Create Date:      21 October 2019 
// Module Name:      cipher_engine
// Project Name:     Trivium-asic
// Description:      The top module of the Trivium core. It realizes
//                   a state machine that controls the cipher_engine component.
//					 Serial input for Key and IV in sequence, LSB first.
//
// Dependencies:     /
//
// Revision: 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none

module trivium_top(
    /* Module inputs */
    input   wire            clk_i,      /* System clock */
    input   wire            n_rst_i,    /* Asynchronous active low reset */
    input   wire    	    dat_i,      /* Serial input data (iv, key, cipher)*/
    input   wire            init_i,     /* Initialize the cipher */
    input   wire            end_i,     /* End of data stream */

    /* Module outputs */
//    output  wire            busy_o,      /* Busy flag */     
    output  reg    		    dat_o,      /* Serial cipher output */
    output reg				busy_init_o //busy flag while initializing
);

//////////////////////////////////////////////////////////////////////////////////
// Signal definitions
//////////////////////////////////////////////////////////////////////////////////
reg     [2:0]   next_state_s;   /* Next state of the FSM */
reg     [2:0]   cur_state_r;    /* Current state of the FSM */
reg     [10:0]  cntr_r;         /* Counter for warm-up and input processing */
reg     [7:0]  cntr_key_r;         /* Counter for input key and iv store */
reg             cphr_en_r;      /* Cipher enable  */
reg             ce_keyiv_r;      /* Input SR enable  */
reg             ld_init_r;      /* Load cipher with key and iv */
reg     [159:0]  initreg_r;          /* key & iv register */
wire		[79:0]	key_dat_s;		/* key value */
wire		[79:0]	iv_dat_s;		/* iv value */
integer i;

//////////////////////////////////////////////////////////////////////////////////
// Local parameter definitions
//////////////////////////////////////////////////////////////////////////////////
parameter   IDLE_e = 0, 
            RECV_INI_e = 1, 
            LOAD_KEYIV_e = 2, 
            WARMUP_e = 3, 
            PROC_e = 4;

//////////////////////////////////////////////////////////////////////////////////
// Module instantiations
//////////////////////////////////////////////////////////////////////////////////
cipher_engine cphr(
    .clk_i(clk_i),
    .n_rst_i(n_rst_i),
    .ce_i(cphr_en_r),
    .key_dat_i(key_dat_s),
    .iv_dat_i(iv_dat_s),
    .ld_init_i(ld_init_r),
    .dat_i(dat_i),
    .dat_o(dat_o)
);

key_dat_s <= initreg_r[159:80];
iv_dat_s <= initreg_r[79:0];

input_sr #(
        .REG_SZ(160)
    ) 
    key_iv(
        .clk_i(clk_i),
        .n_rst_i(n_rst_i),
        .ce_i(ce_keyiv_r),
        .reg_in_i(dat_i),
        .dat_o(initreg_r)
    );


//////////////////////////////////////////////////////////////////////////////////
// Next state logic of the FSM
//////////////////////////////////////////////////////////////////////////////////
always @(*) begin
    case (cur_state_r)
        IDLE_e:
            /* Wait until the user initializes the module */
            if (init_i)
                next_state_s = RECV_INI_e;
            else
                next_state_s = IDLE_e;
        
        RECV_INI_s:
        	/* key and iv received in input SR key_iv */
        	if(cntr_key_r == 159)
        		next_state_s = LOAD_KEYIV_s;
        	else
        		next_state_s = RECV_INI_s;
        		
		LOAD_KEYIV_e:
			/* load key and iv in cipher registers */
			next_state_s = WARMUP_e;
	            
        WARMUP_e:
            /* Warm up the cipher */
            if (cntr_r == 1151)
                next_state_s = PROC_e;
            else
                next_state_s = WARMUP_e;
                        
        PROC_e:
            /* Generate cipher stream */
            if (end_i)
                next_state_s = IDLE_e;
            
        default:
            next_state_s = cur_state_r;
    endcase
end

//////////////////////////////////////////////////////////////////////////////////
// State save and output logic of the FSM
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_i or negedge n_rst_i) begin
    if (!n_rst_i) begin
        /* Reset registers driven here */
        cur_state_r <= IDLE_e;
        cntr_r <= 0;
        cntr_key_r <= 0;
        cphr_en_r <= 1'b0;
        ce_keyiv_r <= 1'b0;
        ld_init_r <= 1'b0;
        busy_init_o <= 1'b0;
    end
    else begin
        /* State save logic */
        cur_state_r <= next_state_s;
      
        /* Output logic */
        case (cur_state_r)
            IDLE_e: begin
				cntr_r <= 0;
				cntr_key_r <= 0;
				cphr_en_r <= 1'b0;
				ce_keyiv_r <= 1'b0;
				ld_init_r <= 1'b0;
            end
         
            RECV_INI_e: begin
				cntr_r <= 0;
				cntr_key_r <= cntr_key_r + 1;
				cphr_en_r <= 1'b0;
				ce_keyiv_r <= 1'b1;
				ld_init_r <= 1'b0;
            end
         
            LOAD_KEYIV_e: begin
				cntr_r <= 0;
				cntr_key_r <= 0;
				cphr_en_r <= 1'b0;
				ce_keyiv_r <= 1'b0;
				ld_init_r <= 1'b1;
            end
         
            WARMUP_e: begin
				cntr_r <= cntr_r + 1;
				cntr_key_r <= 0;
				cphr_en_r <= 1'b1;
				ce_keyiv_r <= 1'b0;
				ld_init_r <= 1'b0;
				busy_init_o <= 1'b1;
            end
                  
            PROC_e: begin
				cntr_r <= 0;
				cntr_key_r <= 0;
				cphr_en_r <= 1'b1;
				ce_keyiv_r <= 1'b0;
				ld_init_r <= 1'b0;
				busy_init_o <= 1'b0;
            end
         
        endcase
    end
end

endmodule
