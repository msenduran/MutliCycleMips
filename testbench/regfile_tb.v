// regfile_tb.v — ModelSim birim testi: register file yaz/oku, $zero hardwired,
// çift okuma portu, we=0 davranışı.
//   vlog regfile_tb.v ; vsim -c work.regfile_tb -do "run -all; quit"
`include "../rtl/regfile.v"

module regfile_tb;
   reg         clk = 0;
   reg  [31:0] dIn;
   reg  [4:0]  ra0, ra1, wa;
   reg         we;
   wire [31:0] dOut0, dOut1;
   integer     pass = 0, fail = 0;

   regfile dut(.dOut0(dOut0), .dOut1(dOut1), .dIn(dIn),
               .readAddr0(ra0), .readAddr1(ra1), .writeAddr(wa),
               .we(we), .clk(clk));

   always #1 clk = ~clk;

   task chk(input [255:0] name, input [31:0] got, input [31:0] exp);
      begin
         if (got === exp) begin
            $display("PASS %0s: 0x%h", name, got); pass = pass + 1;
         end else begin
            $display("FAIL %0s: got=0x%h exp=0x%h", name, got, exp); fail = fail + 1;
         end
      end
   endtask

   initial begin
      we = 0; dIn = 0; ra0 = 0; ra1 = 0; wa = 0;

      // 1) reg[5] = 0xDEADBEEF, sonra oku
      @(negedge clk); wa = 5; dIn = 32'hDEADBEEF; we = 1;
      @(negedge clk); we = 0; ra0 = 5; #0;
      chk("yaz/oku reg5", dOut0, 32'hDEADBEEF);

      // 2) $zero hardwired: reg[0]'a yazmayı dene -> 0 kalmalı
      @(negedge clk); wa = 0; dIn = 32'h12345678; we = 1;
      @(negedge clk); we = 0; ra0 = 0; #0;
      chk("$zero hardwired", dOut0, 32'h00000000);

      // 3) reg[10] = 0xAAAA5555, iki portu paralel oku
      @(negedge clk); wa = 10; dIn = 32'hAAAA5555; we = 1;
      @(negedge clk); we = 0; ra0 = 5; ra1 = 10; #0;
      chk("cift okuma port0", dOut0, 32'hDEADBEEF);
      chk("cift okuma port1", dOut1, 32'hAAAA5555);

      // 4) we=0 iken yazma olmamalı
      @(negedge clk); wa = 5; dIn = 32'h00000000; we = 0;
      @(negedge clk); ra0 = 5; #0;
      chk("we=0 yazma yok", dOut0, 32'hDEADBEEF);

      $display("=== Regfile birim testi: %0d PASS, %0d FAIL ===", pass, fail);
      $finish;
   end
endmodule
