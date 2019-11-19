//////////////////////////////////////////////////////////////////////////////////
// Developer:         F. Moll
// 
// Create Date:      21 October 2019 
// Module Name:      cipher_engine
// Project Name:     Trivium-asic
// Description:      The top module of the Trivium core. It realizes
//                   a state machine that controls the cipher_engine component.
//					 Serial input for Key and IV in sequence, Key first, LSB first.
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none

module trivium_top(
    /* Module inputs */
    input   wire            clk_i,      /* System clock */
    input   wire            n_rst_i,    /* Asynchronous active low reset */
    input   wire    	    dat_i,      /* Serial input data (iv, key, cipher)*/
    input   wire            get_dat_i,     /* present new bit (key/iv/dat) cipher */
    input   wire            ld_keys_i,     /* Load key/iv registers */
    input   wire            end_i,     /* End of data stream */

    /* Module outputs */
//    output  wire            busy_o,      /* Busy flag */     
    output  wire   		    dat_o,      /* Serial cipher output */
    output reg 				ready_o  // Cipher initialized
);

//////////////////////////////////////////////////////////////////////////////////
// Signal definitions
//////////////////////////////////////////////////////////////////////////////////
reg     [2:0]   next_state_s;   /* Next state of the FSM */
reg     [2:0]   cur_state_r;    /* Current state of the FSM */
reg     [10:0]  cntr_r;         /* Counter for warm-up and input processing */
reg             cphr_en_r;      /* Cipher enable  */
reg             ce_keyiv_r;      /* Input SR enable  */
reg             ld_init_r;      /* Load cipher with key and iv */
wire    [159:0]  initreg_s;          /* key & iv register */
wire		[79:0]	key_dat_s;		/* key value */
wire		[79:0]	iv_dat_s;		/* iv value */

//////////////////////////////////////////////////////////////////////////////////
// Local parameter definitions
//////////////////////////////////////////////////////////////////////////////////
parameter   IDLE_e = 0, 
            RECV_INI_e = 1, 
            LOAD_KEYIV_e = 2, 
            WARMUP_e = 3, 
            WAIT_e = 4, 
            PROC_e = 5;

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

// Key received first, so Key in LSB side of init_reg
assign key_dat_s = initreg_s[79:0];
assign iv_dat_s = initreg_s[159:80];

input_sr #(
        .REG_SZ(160)
    ) 
    key_iv(
        .clk_i(clk_i),
        .n_rst_i(n_rst_i),
        .ce_i(ce_keyiv_r),
        .reg_in_i(dat_i),
        .dat_o(initreg_s)
    );


//////////////////////////////////////////////////////////////////////////////////
// Next state logic of the FSM
//////////////////////////////////////////////////////////////////////////////////
always @(*) begin
    case (cur_state_r)
        IDLE_e: /* Wait until the user initializes the module */
            if (get_dat_i)
                next_state_s = RECV_INI_e;
            else
                next_state_s = IDLE_e;
        
        RECV_INI_e: /* key and iv received in input SR key_iv */
        	if(ld_keys_i)
        		next_state_s = LOAD_KEYIV_e;
        	else
				if(!get_dat_i)
					next_state_s = IDLE_e;
				else
        			next_state_s = RECV_INI_e;
        		
		LOAD_KEYIV_e: /* load key and iv in cipher registers */
			next_state_s = WARMUP_e;
	            
        WARMUP_e: /* Warm up the cipher */
            if (cntr_r == 1151)
                next_state_s = WAIT_e;
            else
                next_state_s = WARMUP_e;

        WAIT_e: /* stop cipher shift */
            if (get_dat_i)
                next_state_s = PROC_e;
            else
				if (ld_keys_i)
					next_state_s = LOAD_KEYIV_e;
				else 
                	next_state_s = WAIT_e;
                        
        PROC_e: /* Generate cipher stream */
            if (!get_dat_i)
                next_state_s = WAIT_e;
			else
				next_state_s = PROC_e;
            
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
    end
    else begin
        /* State save logic */
        cur_state_r <= next_state_s;
		if(cur_state_r == WARMUP_e) begin
			cntr_r <= cntr_r + 1;
		end
		else begin
			cntr_r <= 0;
		end
    end
end

      
        /* Output logic combinational*/
    always@(*) begin
        case (cur_state_r)
            IDLE_e: begin
				cphr_en_r <= 1'b0;
				ce_keyiv_r <= 1'b0;
				ld_init_r <= 1'b0;
        		ready_o <= 1'b0;
            end
         
            RECV_INI_e: begin
				cphr_en_r <= 1'b0;
				ce_keyiv_r <= 1'b1;
				ld_init_r <= 1'b0;
				ready_o <= 1'b0;
            end
         
            LOAD_KEYIV_e: begin
				cphr_en_r <= 1'b0;
				ce_keyiv_r <= 1'b0;
				ld_init_r <= 1'b1;
				ready_o <= 1'b0;
            end
         
            WARMUP_e: begin
				cphr_en_r <= 1'b1;
				ce_keyiv_r <= 1'b0;
				ld_init_r <= 1'b0;
				ready_o <= 1'b0;
            end
                  
            WAIT_e: begin
				cphr_en_r <= 1'b0;
				ce_keyiv_r <= 1'b0;
				ld_init_r <= 1'b0;
				ready_o <= 1'b1;
            end
                  
            PROC_e: begin
				cphr_en_r <= 1'b1;
				ce_keyiv_r <= 1'b0;
				ld_init_r <= 1'b0;
				ready_o <= 1'b1;
            end
         
        endcase
    end

endmodule
