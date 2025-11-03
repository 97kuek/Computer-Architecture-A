/*
 * From D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
module testbench();

   reg	clk;
   reg	reset;
	
   wire [31:0] writedata, dataaddr;
   wire        memwrite;
	
   // instantiate device to be tested
   top dut (clk, reset, writedata, dataaddr, memwrite);
	
   // initialize test
   initial begin
      $dumpfile("testb.vcd");
      $dumpvars(0, testbench);
      reset <= 1; # 22; reset <= 0;
   end
		
   // generate clock to sequence tests
   always
     begin
	clk <= 1; #5; clk <= 0; #5;
     end
		
   // check results
   always @ (negedge clk)
     begin
	if (memwrite & dataaddr === 84) begin
           if (writedata === 33054) begin
	      $display ("Simulation succeeded");
	      $finish;
           end else begin
	      $display ("Simulation partially succeeded");
	      $finish;
           end
	end
     end

endmodule
