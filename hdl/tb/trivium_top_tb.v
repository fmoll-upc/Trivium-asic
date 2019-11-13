//////////////////////////////////////////////////////////////////////////////////
// Developer:         F. Moll
// 
// Create Date:      22 October 2019 
// Module Name:      trivium_top_tb
// Project Name:     Trivium-asic
// Description:      The module trivium_top is tested using reference I/O files. Each
//                test incorporates the pre-loading with a new key and IV, as well
//                as providing input words and checking the correctness of the
//                encrypted output words.
//
// Dependencies:     /
//
// Revision: 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
module trivium_top_tb;

////////////////////////////////////////////////////////////////////////////////
// Helper function definitions
////////////////////////////////////////////////////////////////////////////////
/* Get the number of tests contained in a specified file */
function [31:0] get_num_tests;
    input [8*20:1] i_file_name;
    reg [8*20:1] cur_line;
    integer cur_num;
    integer fd;
    integer scan_ret;
begin
    cur_num = 0;
    fd = $fopen(i_file_name, "r");
    if (!fd) begin
        $display("ERROR: Could not open '%s'", i_file_name);
        get_num_tests = 0;
    end
    else begin
        /* Iterate over lines */
        scan_ret = $fscanf(fd, "%s", cur_line);
        while (scan_ret) begin
            if (cur_line == "-")
                cur_num = cur_num + 1;
            
            scan_ret = $fscanf(fd, "%s", cur_line);
        end
      
        $fclose(fd);
        get_num_tests = cur_num;
    end
end
endfunction

/* Returns the key or IV of a particular test */
function [79:0] get_key_iv;
    input [8*20:1] i_file_name;
    input [8*3:1] key_or_iv;
    input [31:0] test_num;
    reg [8*20:1] cur_line;
    reg [79:0] ret_val;
    integer cur_num;
    integer fd;
    integer scan_ret;
    integer fpos;
begin
    cur_num = 0;
    fd = $fopen(i_file_name, "r");
    if (!fd) begin
        $display("ERROR: Could not open '%s'", i_file_name);
        $finish;
    end
    else begin
        /* Iterate until specified test is found */
        fpos = $ftell(fd);
        scan_ret = $fscanf(fd, "%s", cur_line);
        while (cur_num < test_num && scan_ret) begin
            if (cur_line == "-")
                cur_num = cur_num + 1;
            
            fpos = $ftell(fd);
            scan_ret = $fscanf(fd, "%s", cur_line);
        end
      
        if (cur_line == ".") begin
            $display("ERROR: Incorrect test number specified: %d", test_num);
            $fclose(fd);
            $finish;
        end
      
        /* Get key or IV and return, get back previous line to interpret as hex */   	
        $fseek(fd, fpos, 0);
        if (key_or_iv == "key")
            scan_ret = $fscanf(fd, "%h", ret_val);
        else if (key_or_iv == "iv") begin
            scan_ret = $fscanf(fd, "%h", ret_val);
            scan_ret = $fscanf(fd, "%h", ret_val);
        end
        else begin
            $display("ERROR: Could not read requested value!");
            $fclose(fd);
            $finish;
        end
      
        $fclose(fd);
        get_key_iv = ret_val;
    end
end 
endfunction

/* Return the number of 32-bit words in specified test */
function [31:0] get_num_words;
    input [8*20:1] i_file_name;
    input integer line_num;
    input integer test_num;
    reg [8*20:1] cur_line;
    integer cur_num;
    integer fd;
    integer fpos;
    integer scan_ret;
begin
    cur_num = 0;
    fd = $fopen(i_file_name, "r");
    if (!fd) begin
        $display("ERROR: Could not open '%s'", i_file_name);
        $finish;
    end
    else begin
        /* Iterate until specified test is found */
        fpos = $ftell(fd);
        scan_ret = $fscanf(fd, "%s", cur_line);
        while (cur_num < test_num && scan_ret) begin
            if (cur_line == "-")
                cur_num = cur_num + 1;
            
            fpos = $ftell(fd);
            scan_ret = $fscanf(fd, "%s", cur_line);
        end
      
        if (cur_line == ".") begin
            $display("ERROR: Incorrect test number specified: %d", test_num);
            $fclose(fd);
            $finish;
        end
      
        /* Skip the key and IV in case we are reading from input reference */
        $fseek(fd, fpos, 0);
        if (i_file_name == "trivium_ref_in.txt") begin
            scan_ret = $fscanf(fd, "%s", cur_line);
            scan_ret = $fscanf(fd, "%s", cur_line);
        end
      
        /* Counter number of words in current test */
        cur_num = 0;
        cur_line = "";
        scan_ret = $fscanf(fd, "%s", cur_line);
        while (cur_line != "-") begin
            cur_num = cur_num + 1;
            scan_ret = $fscanf(fd, "%s", cur_line);
        end
      
        $fclose(fd);
        get_num_words = cur_num;
    end
end 
endfunction

/* Return 32-bit word from specified file */
function [31:0] get_word;
    input [8*20:1] i_file_name;
    input integer line_num;
    input integer test_num;
    reg [8*20:1] cur_line;
    reg [79:0] cur_word;
    integer cur_num;
    integer fd;
    integer fpos;
    integer scan_ret;
begin
    cur_num = 0;
    fd = $fopen(i_file_name, "r");
    if (!fd) begin
        $display("ERROR: Could not open '%s'", i_file_name);
        $finish;
    end
    else begin
        /* Iterate until specified test is found */
        fpos = $ftell(fd);
        scan_ret = $fscanf(fd, "%s", cur_line);
        while (cur_num < test_num && scan_ret) begin
            if (cur_line == "-")
                cur_num = cur_num + 1;
           
            fpos = $ftell(fd); 
            scan_ret = $fscanf(fd, "%s", cur_line);
        end
      
        if (cur_line == ".") begin
            $display("ERROR: Incorrect test number specified: %d", test_num);
            $fclose(fd);
            $finish;
        end
      
        /* Skip the key and IV in case we are reading from input reference */
        $fseek(fd, fpos, 0);
        if (i_file_name == "trivium_ref_in.txt") begin
            scan_ret = $fscanf(fd, "%h", cur_word);
            scan_ret = $fscanf(fd, "%h", cur_word);
        end
      
        /* Skip to specified word */
        cur_num = 0;
        scan_ret = $fscanf(fd, "%h", cur_word);
        while (cur_num < line_num && scan_ret) begin
            cur_num = cur_num + 1;
            scan_ret = $fscanf(fd, "%h", cur_word);
        end
      
        $fclose(fd);
        get_word = cur_word[31:0];
    end
end 
endfunction

////////////////////////////////////////////////////////////////////////////////
// Signal definitions
////////////////////////////////////////////////////////////////////////////////

/* Module inputs */
reg             clk_i;
reg             n_rst_i;
reg     	    dat_i;
reg             init_i;
reg             end_i;

/* Module outputs */
wire     		dat_o;
wire			busy_o;

/* Other signals */
reg start_tests_s;      /* Flag indicating the start of the tests */
reg     [95:0]  key_r;  /* Key used for encryption */
reg     [95:0]  iv_r;   /* IV used for encryption */
reg     [31:0]  dat_in_s; // Input 32-bit data stream
reg    [31:0]  dat_out_s; // Output 32-bit data stream
reg    [31:0]  dat_outref_s; // Output 32-bit reference data
integer instr_v;        /* Current stimulus instruction index */
integer dat_cntr_v;     /* Data counter variable */
integer bitcntr_v;     /* Bit counter inside input data variable */
integer keyiv_cntr_v;     /* Key/IV counter variable */
integer cur_test_v;     /* Index of current test */

////////////////////////////////////////////////////////////////////////////////
// UUT Instantiation
////////////////////////////////////////////////////////////////////////////////
trivium_top uut(
    .clk_i(clk_i),
    .n_rst_i(n_rst_i),
    .dat_i(dat_i),
    .init_i(init_i),    
    .end_i(end_i),    
    .dat_o(dat_o),
    .busy_init_o(busy_o)
);

////////////////////////////////////////////////////////////////////////////////
// UUT Initialization
////////////////////////////////////////////////////////////////////////////////
initial begin
    /* Initialize Inputs */
    clk_i = 0;
    n_rst_i = 0;
    
    /* Initialize other signals/variables */
    start_tests_s = 0;
    cur_test_v = 0;
    
    /* Wait 100 ns for global reset to finish */
    #100;
    n_rst_i = 1'b1;
    start_tests_s = 1'b1;
end

////////////////////////////////////////////////////////////////////////////////
// Clock generation
////////////////////////////////////////////////////////////////////////////////
always begin
    #10 clk_i = ~clk_i;
end

////////////////////////////////////////////////////////////////////////////////
// Stimulus process
////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_i or negedge n_rst_i) begin
    if (!n_rst_i) begin
        /* Reset registers driven here */
        dat_in_s <= 0;
        dat_out_s <= 0;
        init_i <= 0;
        end_i <= 0;   
        instr_v <= 0;
        dat_cntr_v <= 0;
        keyiv_cntr <= 0;
        key_r <= 0;
        iv_r <= 0;
    end
    else if (start_tests_s) begin
        case (instr_v)
            0: begin    /* Instruction 0: Obtain key & iv */

                /* Get the current key and IV */
                key_r[79:0] <= get_key_iv("trivium_ref_in.txt", "key", cur_test_v);
                iv_r[79:0] <= get_key_iv("trivium_ref_in.txt", "iv", cur_test_v);

                instr_v <= instr_v + 1;
            end
         
            1: begin    /* Instruction 1: Send key to core */
            	dat_i <= key_r[0];
                init_i <= 1;
                
                if (keyiv_cntr_v!=79) begin
                	key_r <= {0,key_r[79:1]};
                    keyiv_cntr_v <= keyiv_cntr_v + 1;
                end
                else begin
                   keyiv_cntr_v = 0;
                   instr_v <= instr_v + 1;
                end
             end
         
            2: begin    /* Instruction 2: Send IV to core */
            	dat_i <= iv_r[0];
               // init_i <= 1;
                
                if (keyiv_cntr_v!=79) begin
                	iv_r <= {0,iv_r[79:1]};
                    keyiv_cntr_v <= keyiv_cntr_v + 1;
                end
                else begin
                   keyiv_cntr_v = 0;
                   instr_v <= instr_v + 1;
                   init_i <= 1'b1; // Start initilization
                end
            end
         
            3: begin    /* Instruction 3: Initialize the cipher */
                init_i <= 1'b0; // release init signal
                if (!busy_o) begin// check busy signal in cipher
                    instr_v <= instr_v + 1;
                    dat_in_s <= get_word("trivium_ref_in.txt", dat_cntr_v, cur_test_v);
                    dat_outref_s <= get_word("trivium_ref_out.txt", dat_cntr_v, cur_test_v);
                    dat_i <= dat_in_s[0];
                    bitcntr_v <= 0;
                end
            end
         
            4: begin    /* Instruction 4: Present a 32-bit value to encrypt */
                if (bitcntr_v != 31) begin // count 32 bits
                    dat_in_s <= {0, dat_in_s[31:1]};
                	dat_out_s <= {dat_out_s[31:1], dat_o};
                    bitcontr_v <= bitcontr_v + 1;
                end
                else begin
                	bitcontr_v <= 0;
                    if (dat_out_s != dat_outref_s)
                		instr_v <= 6; // Finish error state
                	else begin
	                	if (dat_cntr_v < get_num_words("trivium_ref_in.txt", dat_cntr_v, cur_test_v) - 1) begin
    	                    dat_cntr_v <= dat_cntr_v + 1;
		                    dat_in_s <= get_word("trivium_ref_in.txt", dat_cntr_v, cur_test_v);
        		            dat_outref_s <= get_word("trivium_ref_out.txt", dat_cntr_v, cur_test_v);
        	            end
        	            else begin
        	            	instr_v <= 7; //Check completion state
        	            end
                	end
                end
            end
            
            6: begin    /* Display error and finish */
         		$display("ERROR: Incorrect output in test %d, word %d!", cur_test_v, dat_cntr_v);
                $display("%04x != %04x, input = %04x", dat_out_s, dat_outref_s, get_word("trivium_ref_in.txt", dat_cntr_v, cur_test_v));
                $finish;
			end
         
            7: begin    /* Instruction 7: Check if all tests completed and decide what to do */
                if (cur_test_v < get_num_tests("trivium_ref_in.txt") - 1) begin
                    cur_test_v <= cur_test_v + 1;
                    instr_v <= 0; // Obtain new key and iv and start over
                end
                else begin
                    cur_test_v <= 0;
                    instr_v <= instr_v + 1; // Finish successfully state
                end
            end
         
            default: begin
                $display("Tests successfully completed!");
                $finish;
            end
        endcase
    end
end
      
endmodule
