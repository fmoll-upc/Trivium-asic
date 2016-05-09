# Trivium
A Verilog implementation of the Trivium stream cipher

# 0. Overview
    0. Overview
    1. General Information
    2. Current Status
    3. Synthesizing and Testing The Core
    4. TODOs
    5. License
    6. References
	

# 1. General Information
    + This Verilog implementation of the Trivium stream cipher consists of:
        - The core components
        - A testbench that tests the top level functionality
        - A Python reference implementation for the generation of test vectors and possibly other scenarios
    + The interface of the core is designed such that it is compatible with PLB-based processor systems,
      such as the Xilinx MicroBlaze
    + The hdl/src directory contains the source code of the core, whereas the testbench can be found in hdl/tb
    + Test vectors and the python reference implementation can be found in the reference_implementation/ directory
    + The specification of Trivium can be found in [1]
	
# 2. Current Status
    The core has successfully been synthesized, placed and routed in a design. In addition, the test coverage of
    the behavioral simulation is complete, with the core passing all tests.
    A next step is verify the functionality of the core in silicon as part of a larger FPGA design.
    
# 3. Synthesizing and Testing The Core
    + Synthesis
        - The core requires no special constraints to function
        - All necessary code can be found in the hdl/src directory
        - Make sure that the file hdl/src/trivium_globals.v is included in any design that uses this core
    + Testing
        - The testbench for the behavioral simulation can be found in hdl/tb
        - Running the test requires two files that contain the test vectors
        - The test vector files can be generated by executing the script reference_implementation/trivium_py.py
        - The test vectors consist of randomly generated input (trivium_ref_in.txt) and corresponding encrypted
          outputs (trivisum_ref_out.txt)
        - Be sure to copy these test vector files to the directory of the project that runs the testbench if you
          are using Xilinx tools (Xilinx ISE in particular)
        - The testbench is self checking and will abort with a success message if all tests pass
		
# 4. TODOs
    + Add interrupt functionality

# 5. License
    This project is licensed under the Lesser General Public License (LGPL). See the lincense.txt file in the top
    level project directory for more info.

# 6. References
    + [1] http://www.ecrypt.eu.org/stream/p3ciphers/trivium/trivium_p3.pdf
