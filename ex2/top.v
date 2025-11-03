/*
 * Based on D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
 // rename for your .dat-file
`define DATFILE "memfile.dat"

module dmem(
    input  clk, we,
    input  [31:0] a, wd,
    output [31:0] rd);

   reg [31:0] RAM[63:0];
   assign rd = RAM[a[31:2]];
	
   always @ (posedge clk)
     if (we)
       RAM[a[31:2]] <= wd;

   initial
     begin
	$readmemh (`DATFILE, RAM);
     end

endmodule

module imem (
    input  [5:0]  a,
    output [31:0] rd);
				
   reg [31:0]  RAM[63:0];
	
   initial
     begin
	$readmemh (`DATFILE, RAM);
     end
		
   assign rd = RAM[a];
endmodule

module top(
    input clk,
    input reset,
    output [31:0] writedata,
    output [31:0] dataaddr,
    output memwrite
    );

   wire [31:0] pc, instr, readdata;
   // instantiate a processor and memories
   riscv riscv (clk, reset, pc, instr, memwrite, dataaddr, writedata, readdata);
   imem imem (pc[7:2], instr);
   dmem dmem (clk, memwrite, dataaddr, writedata, readdata);
	
endmodule
