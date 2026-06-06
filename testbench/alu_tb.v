// alu_tb.v — ModelSim birim testi: ALU'nun 9 işlemi + zero/overflow bayrakları.
//   vlog alu_tb.v ; vsim -c work.alu_tb -do "run -all; quit"
`include "../rtl/alu.v"

module alu_tb;
   reg  signed [31:0] a, b;
   reg         [3:0]  cmd;
   wire signed [31:0] result;
   wire               zero, overflow, carryout;
   integer            pass = 0, fail = 0;

   // ALU komut kodları (alu.v localparam ile aynı)
   localparam ADD=4'b0000, SUB=4'b0001, XOR=4'b0010, SLT=4'b0011,
              AND=4'b0100, NAND=4'b0101, NOR=4'b0110, OR=4'b0111, MUL=4'b1000;

   alu dut(.result(result), .zero(zero), .overflow(overflow),
           .carryout(carryout), .operandA(a), .operandB(b), .command(cmd));

   task chk(input [255:0] name, input signed [31:0] exp);
      begin
         #1;
         if (result === exp) begin
            $display("PASS %0s: result=%0d (0x%h)", name, result, result);
            pass = pass + 1;
         end else begin
            $display("FAIL %0s: got=%0d exp=%0d", name, result, exp);
            fail = fail + 1;
         end
      end
   endtask

   task chkflag(input [255:0] name, input got, input exp);
      begin
         if (got === exp) begin
            $display("PASS %0s (flag=%b)", name, got); pass = pass + 1;
         end else begin
            $display("FAIL %0s: flag got=%b exp=%b", name, got, exp); fail = fail + 1;
         end
      end
   endtask

   initial begin
      a=5;  b=3;  cmd=ADD; chk("ADD 5+3", 8);
      a=0;  b=0;  cmd=ADD; #1; chkflag("ADD zero flag", zero, 1'b1);
      a=32'h7FFFFFFF; b=1; cmd=ADD; #1; chkflag("ADD overflow (MAX+1)", overflow, 1'b1);
      a=10; b=4;  cmd=SUB; chk("SUB 10-4", 6);
      a=5;  b=5;  cmd=SUB; #1; chkflag("SUB zero flag", zero, 1'b1);
      a=32'h0F0F0F0F; b=32'h00FF00FF; cmd=XOR; chk("XOR", 32'h0FF00FF0);
      a=-1; b=0;  cmd=SLT; chk("SLT signed -1<0", 1);
      a=5;  b=3;  cmd=SLT; chk("SLT 5<3", 0);
      a=32'hFF00FF00; b=32'h0F0F0F0F; cmd=AND;  chk("AND", 32'h0F000F00);
      a=32'hFFFFFFFF; b=32'hFFFFFFFF; cmd=NAND; chk("NAND", 32'h00000000);
      a=32'h00000000; b=32'h00000000; cmd=NOR;  chk("NOR", 32'hFFFFFFFF);
      a=32'hF0F0F0F0; b=32'h0F0F0F0F; cmd=OR;   chk("OR", 32'hFFFFFFFF);
      a=12; b=5;  cmd=MUL; chk("MUL 12*5", 60);
      a=-7; b=6;  cmd=MUL; chk("MUL signed -7*6", -42);

      $display("=== ALU birim testi: %0d PASS, %0d FAIL ===", pass, fail);
      $finish;
   end
endmodule
