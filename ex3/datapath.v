/*
 * Based on D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
module adder(
    input  [31:0] a, b,
    output [31:0] y);

   assign y = a + b;
endmodule

module immext (
    input  i_op,
    input  s_op,
    input  b_op,
    input  u_op,
    input  j_op,
    input [31:0] instr,
    output reg [31:0] y);

   wire [4:0] immtype;

   assign immtype = { i_op, s_op, b_op, u_op, j_op };
   
   always @ (*)
     case (immtype)
       5'b10000: y <= { {20{instr[31]}}, instr[31:20] };
       5'b01000: y <= { {20{instr[31]}}, instr[31:25], instr[11:7] };
       5'b00100: y <= { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };
       5'b00010: y <= { instr[31:12], 12'b0 };
       5'b00001: y <= { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };
       default: y <= 'hx;
     endcase // case (immtpe)
   
endmodule

module flopr # (parameter WIDTH = 8)
   (input	clk, reset,
    input	[WIDTH-1:0] d,
    output reg [WIDTH-1:0]  q);
					
   always @ (posedge clk, posedge reset)
     if (reset) q <= 0;
     else	q <= d;
endmodule

module mux2 # (parameter WIDTH = 8)
   (input  [WIDTH-1:0] d0, d1,
    input  s,
    output [WIDTH-1:0] y);
				
   assign y = s ? d1 : d0;
endmodule

module regfile(
    input clk,
    input we3,
    input [4:0] ra1,
    input [4:0] ra2,
    input [4:0] wa3,
    input [31:0] wd3,
    output [31:0] rd1,
    output [31:0] rd2
    );

   reg [31:0] 	  rf[31:0];
	
   // 3-port register file
   always @ (posedge clk)
     if (we3) rf[wa3] <= wd3;
		
   assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
   assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule

module datapath(
    input  clk,
    input  reset,
    input  memtoreg,
    input  pcsrc,
    input  alusrc,
    input  regwrite,
    input  i_op,
    input  s_op,
    input  b_op,
    input  u_op,
    input  j_op,
    input  [3:0] alucontrol,
    output btaken,
    output [31:0] pc,
    input  [31:0] instr,
    output [31:0] aluout,
    output [31:0] writedata,
    input  [31:0] readdata
    );

   wire [31:0] 	 pcnext, pcplus4, pcbranch;
   wire [31:0] 	 immextv;
   wire [31:0] 	 rsrca, srca, srcb;
   wire [31:0] 	 result0, result;
	
   // exploit immediate
   immext	ie(i_op, s_op, b_op, u_op, j_op, instr, immextv);

   // for next PC
   flopr #(32)	pcreg(clk, reset, pcnext, pc);
   adder	pcadd1 (pc, 32'b100, pcplus4);
   adder	pcadd2(pc, immextv, pcbranch);
   mux2 #(32)   pcmux(pcplus4, pcbranch, (pcsrc|j_op), pcnext);
							
   // reg-file logic
   regfile	rf(clk, regwrite, instr[19:15], instr[24:20], instr[11:7],
		   result, rsrca, writedata);
   mux2 #(32)	resmux1(aluout, readdata, memtoreg, result0);
   mux2 #(32)	resmux2(result0, pcplus4, j_op, result);
	
   // ALU logic
   mux2 #(32) srcamux(rsrca, 32'h0, u_op, srca);
   mux2 #(32) srcbmux(writedata, immextv, alusrc, srcb);
   alu alu(srca, srcb, alucontrol, aluout, btaken);
endmodule

module testdp;
   reg clk;
   reg reset;
   reg memtoreg, pcsrc, alusrc, regwrite;
   reg i_op, s_op, b_op, u_op, j_op;
   reg [3:0] alucontrol;
   reg [31:0] instr;
   reg [31:0] readdata;
   wire btaken;
   wire [31:0] pc;
   wire [31:0] aluout;
   wire [31:0] writedata;

   datapath dp(clk, reset, memtoreg, pcsrc, alusrc, regwrite,
	       i_op, s_op, b_op, u_op, j_op, alucontrol, btaken, pc,
	       instr, aluout, writedata, readdata);

   initial begin
      $dumpfile("testdp.vcd");
      $dumpvars(0, testdp);
      clk = 1; reset = 1; memtoreg = 0; pcsrc = 0; alusrc = 0; regwrite = 1;
      instr = 32'hdeadbeaf;
      i_op = 0; s_op = 0; b_op = 0; u_op = 0; j_op = 0;
      alucontrol = 0;
      readdata = 0; #1
      reset = 0; clk = 0; #1
      clk = 1; #1
      clk = 0; #1
      clk = 1; i_op = 1; #1
      clk = 0; #1
      clk = 1; i_op = 0; s_op = 1; #1
      clk = 0; #1
      clk = 1; s_op = 0; b_op = 1; #1
      clk = 0; #1
      clk = 1; b_op = 0; u_op = 1; #1
      clk = 0; #1
      clk = 1; u_op = 0; j_op = 1; #1
      clk = 0; #1
      clk = 1; instr = 32'h5eadbeaf; j_op = 0; i_op = 1; #1
      clk = 0; #1
      clk = 1; i_op = 0; s_op = 1; #1
      clk = 0; #1
      clk = 1; s_op = 0; b_op = 1; #1
      clk = 0; #1
      clk = 1; b_op = 0; u_op = 1; #1
      clk = 0; #1
      clk = 1; u_op = 0; j_op = 1; #1
      clk = 0; #1
      clk = 1; readdata = 32'hf; memtoreg = 1; regwrite = 1; j_op = 0; i_op = 1; instr = 32'hde108080; #1
      clk = 0; #1
      clk = 1; #1
      clk = 0; #1
      clk = 1; regwrite = 0; alusrc = 0; #1
      clk = 0; #1
      clk = 1; alusrc = 1; #1
      clk = 0; #1
      clk = 1; pcsrc = 1; #1
      clk = 0; #1
      clk = 1; #1
      clk = 0; #1
      $finish;
   end
endmodule // testdp
