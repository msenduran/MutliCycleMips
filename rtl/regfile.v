/*
 Module regfile
 
 Inputs: dIn, readAddr0, readAddr1, writeAddr, we
 Outputs: dOut0, dOut1

 Function:
 dOut0 = mem[readAddr0]
 dOut1 = mem[readAddr1]
 if we then mem[addr] = din.
 mem[0] = 0

 Comments: This is made to the MIPS spec, so the width is a byte and
 aword is 4 bytes i.e data in and data out are 32 bits, which span 4
 bytes.
 */

module regfile
  #(
    parameter
    width = 32,
    addrWidth = 5,
    depth = 2**addrWidth
    )
   (
    output [width-1:0]    dOut0,
                          dOut1,
    input [width-1:0]     dIn,
    input [addrWidth-1:0] readAddr0,
                          readAddr1,
                          writeAddr,
    input                 we,
    clk
    );

   reg [width-1:0]        registers [depth-1:0];
   initial registers[0] = 0;

   always @(posedge clk) begin
      if (we && writeAddr != 0) begin
         registers[writeAddr] <= dIn;
      end
   end

   assign dOut0 = registers[readAddr0];
   assign dOut1 = registers[readAddr1];
endmodule
