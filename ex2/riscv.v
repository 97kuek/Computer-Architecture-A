/*
 * Based on D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
module riscv(
    input  clk,
    input  reset,
    output [31:0] pc,
    input  [31:0] instr,
    output memwrite,
    output [31:0] aluout,
    output [31:0] writedata,
    input  [31:0] readdata
    );

   wire 	  memtoreg, branch, alusrc, regdst, regwrite, jump, btaken;
   wire [1:0] 	  immtype;
 	  
   wire [3:0] 	  alucontrol;
	
   controller ctl(instr[6:0], instr[14:12], instr[31:25], btaken,
                  memtoreg, memwrite, pcsrc, alusrc, regwrite,
                  r_op, i_op, s_op, b_op, u_op, j_op, alucontrol);
   datapath dp(clk, reset, memtoreg, pcsrc, alusrc, regwrite,
               i_op, s_op, b_op, u_op, j_op, alucontrol,
               btaken, pc, instr, aluout, writedata, readdata);
					
endmodule
