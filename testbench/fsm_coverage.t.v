// FSM state coverage testi: t??m test programlar??n?? s??rayla ko??tur,
// her programda hangi state'lere girildi??ini logla.
`include "../rtl/cpu.v"
module cputest_cov();
   reg clk;
   initial clk = 0;
   cpu #(.instruction("unit_tests/nsum2.dat")) dut(clk);
   always #1 clk = ~clk;

   reg [63:0] visited;  // 64-bit bitmask, state 0..63
   integer i, s;
   initial begin
      visited = 0;
      for (i = 0; i < 2048; i = i + 1) begin
         #2;
         visited = visited | (64'b1 << dut.fsm0.state);
      end
      $display("Visited state bitmask: %h", visited);
      for (s = 0; s < 42; s = s + 1) begin
         if (visited[s])
           $display("  state %2d  VISITED", s);
         else
           $display("  state %2d  ---", s);
      end
      $finish;
   end
endmodule












