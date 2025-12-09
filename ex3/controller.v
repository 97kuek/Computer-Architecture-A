/*
 * Based on D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
module maindec(
    input [6:0] op,
    output memtoreg,
    output memwrite,
    output alusrc,
    output regwrite,
    output r_op,
    output i_op,
    output s_op,
    output b_op,
    output u_op,
    output j_op,

    output [2:0] aluop
    );

   reg [12:0] 	 controls;
	
   assign { regwrite, alusrc, memwrite, memtoreg,
            r_op, i_op, s_op, b_op, u_op, j_op, aluop } = controls;
				
   always @ (*)
     case (op)
       7'b0110011: controls <= 13'b1000100000100; //Rtype
       7'b0010011: controls <= 13'b1100010000101; //Itype
       7'b1100011: controls <= 13'b0000000100110; //Btype
       7'b0000011: controls <= 13'b1101010000111; //LW
       7'b0100011: controls <= 13'b0110001000111; //SW
       7'b0110111: controls <= 13'b1100000010011; //LUI
       7'b1101111: controls <= 13'b1000000001000; //JAL
       default:    controls <= 13'bxxxxxxxxxxxxx; //???
     endcase

endmodule

module aludec(
    input [2:0]      funct3,
    input [6:0]      funct7,
    input            r_op,
    input [2:0]      aluop,
    output reg [3:0] alucontrol
    );

   wire exf7;
   assign exf7 = (r_op & ((funct7 == 7'b0100000 ) ? 1'b1 : ((funct7 == 7'b0000000 ) ? 1'b0 : 1'bx)));
   
   always @ (*)
     case (aluop)
       3'b000: alucontrol <= 4'b0000; // addition
       3'b011: alucontrol <= 4'b0110; // or
       3'b100: alucontrol <= {exf7, funct3}; // R-type
       3'b101: alucontrol <= {1'b0, funct3}; // I-type
       3'b110: alucontrol <= {1'b0, funct3}; // B-type
       3'b111: case (funct3) // L-type or S-type
                 3'b010: alucontrol <= 4'b0000; // LW or SW
                 default: alucontrol <= 4'bxxxx;
               endcase
      default: alucontrol <= 4'bxxxx; //???
     endcase
endmodule

module controller(
    input [6:0] op,
    input [2:0] funct3,
    input [6:0] funct7,
    input btaken,
    output memtoreg,
    output memwrite,
    output pcsrc,
    output alusrc,
    output regwrite,
    output r_op,
    output i_op,
    output s_op,
    output b_op,
    output u_op,
    output j_op,
    output [3:0] alucontrol
    );

   wire [2:0] 	 aluop;
	
   maindec md (op, memtoreg, memwrite, alusrc, regwrite,
               r_op, i_op, s_op, b_op, u_op, j_op, aluop);
   aludec ad (funct3, funct7, r_op, aluop, alucontrol);
	
   assign pcsrc = b_op & btaken;
endmodule

module testcont;
   reg [6:0] op;
   reg [2:0] funct3;
   reg [6:0] funct7;
   reg 	     btaken;
   wire      memtoreg, memwrite, pcsrc, alusrc, regwrite;
   wire      r_op, i_op, s_op, b_op, u_op, j_op;
   wire [3:0] alucontrol;

   controller ctl(op, funct3, funct7, btaken, memtoreg, memwrite, pcsrc,
		  alusrc, regwrite, r_op, i_op, s_op, b_op, u_op, j_op,
                  alucontrol);

   initial begin
      $dumpfile("testcont.vcd");
      $dumpvars(0, testcont);
      btaken = 0; op = 'h33; funct3 = 'h0; funct7 = 'h0; #1
      funct3 = 'h0; funct7 = 'h20; #1
      funct3 = 'h7; funct7 = 'h0; #1
      funct3 = 'h6; funct7 = 'h0; #1
      funct3 = 'h2; funct7 = 'h0; #1
      op = 'h3; funct3 = 2; #1
      op = 'h23; funct3 = 2; #1
      op = 'h13; funct3 = 0; #1
      op = 'h13; funct3 = 6; #1
      op = 'h37; #1
      op = 'h6f; #1
      $finish;
   end
endmodule // testcont
