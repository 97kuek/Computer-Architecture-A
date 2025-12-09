/*
 * From D. M. Harris and S. L. Harris, "Digital Design and Computer Architecture"
 */
`timescale 1ns / 1ps
module alu(
    input [31:0] srca,
    input [31:0] srcb,
    input [3:0] alucontrol,
    output reg [31:0] aluout,
    output reg btaken
    );

   always @ (*)
     begin
      case (alucontrol)
         4'b0000: aluout <= srca + srcb;
         4'b1000: aluout <= srca - srcb;
         4'b0010: aluout <= $signed(srca) < $signed(srcb);
         4'b0100: aluout <= srca ^ srcb;
         4'b0110: aluout <= srca | srcb;
         4'b0111: aluout <= srca & srcb;
      endcase
      case (alucontrol) // for conditonal branch
         4'b0000: btaken <= (srca == srcb) ? 1 : 0;                   // BEQ
         4'b0001: btaken <= (srca != srcb) ? 1 : 0;                   // BNE
         4'b0100: btaken <= ($signed(srca) < $signed(srcb)) ? 1 : 0;  // BLT
         4'b0101: btaken <= ($signed(srca) >= $signed(srcb)) ? 1 : 0; // BGE
         4'b0110: btaken <= (srca < srcb) ? 1 : 0;                    // BLTU
         4'b0111: btaken <= (srca >= srcb) ? 1 : 0;                   // BGEU
         default: btaken <= 0;
        endcase
     end
	
endmodule

module alutest;

   reg [31:0] opa, opb;
   reg [3:0]  aluc;
   wire [31:0] res;
   wire        btaken;
   
   alu alu1(opa, opb, aluc, res, btaken);

   initial begin
      $dumpfile("alutest.vcd");
      $dumpvars(0, alutest);
      aluc = 0; #1
      opa = 3; opb = 1;   #1
      aluc = 0; opa = 4; opb = -2; #1

      aluc = 8; #1
      opa = 3; opb = 1;   #1
      aluc = 8; opa = 4; opb = -2; #1
      aluc = 7; #1
      aluc = 6; #1
      aluc = 2; #1
      opa = 3; opb = 3; #1
      opa = 1; opb = 3; #1
      opa = -1; opb = 3; #1
      opa = -1; opb = -2; #1
      opa = -3; opb = -2; #1
      $finish;
   end
   

endmodule // alutest
