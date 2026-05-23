`include "../rtl/cpu.v"
module cputest();
   reg clk;
   reg [16:0] counter;
   initial begin
      clk = 0;
      counter = 0;
   end

   cpu #(.instruction("C:\\intelFPGA\\18.1\\multicycle-mips-master\\testbench\\unit_tests\\branch_range_test.dat")) dut(clk);
   always #1 clk = ~clk;

   always #2 begin
      counter = counter + 1;
   end

   initial begin
      $dumpfile("cpu.vcd");
      $dumpvars();
      $display("Contents: %d", dut.mem0.mem[3]);
      #4096$display("Contents of T0 and T1: %d and %d", dut.regfile0.registers[8], dut.regfile0.registers[9]);
      $display("Contents of v0: %d", dut.regfile0.registers[2]);
      $finish;
   end
endmodule

























