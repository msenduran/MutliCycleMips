/*
 Module memory
 
 Inputs: clk, addr, instrAddr, we, dIn
 Outputs: dOut, instrOut

 Function:
 dOut = mem[addr]
 instrOut = mem[instrAddr]
 if we then mem[addr] = din.

 Comments: This is made to the MIPS spec, so the width is a byte and
 aword is 4 bytes i.e data in and data out are 32 bits, which span 4
 bytes.
 */

module memory
  #(
    parameter width = 8,
    wordSz = 4,
    addrWidth = 16,
    depth = 2**addrWidth,
    data = "mem/instructions.dat"
    )
   (
    output [width*wordSz-1:0] dOut,
    input                     clk,
    input [31:0]              addr,
    input                     we,
    input [width*wordSz-1:0]  dIn
    );

   reg [width-1:0]            mem [depth-1:0];

   initial $readmemh(data, mem);

   genvar                     i;

   generate
      for (i = 0; i < wordSz; i = i+1) begin
         always @(posedge clk)
           if (we)
             mem[addr+wordSz-1-i] <= dIn[i*width+:width];

         assign dOut[(wordSz - i - 1) * width+:width] = mem[addr+i];
      end
   endgenerate
endmodule
