# run_all_tests.do
# ModelSim transcript'ten çalıştır:
#   cd C:/intelFPGA/18.1/multicycle-mips-master/testbench
#   do run_all_tests.do

proc write_testbench {datfile} {
    set f [open "cpu.t.v" w]
    puts $f {`include "../rtl/cpu.v"}
    puts $f {module cputest();}
    puts $f {   reg clk;}
    puts $f {   reg [16:0] counter;}
    puts $f {   initial begin}
    puts $f {      clk = 0;}
    puts $f {      counter = 0;}
    puts $f {   end}
    puts $f {}
    puts $f "   cpu #(.instruction(\"unit_tests/$datfile\")) dut(clk);"
    puts $f {   always #1 clk = ~clk;}
    puts $f {}
    puts $f {   always #2 begin}
    puts $f {      counter = counter + 1;}
    puts $f {   end}
    puts $f {}
    puts $f {   initial begin}
    puts $f {      $dumpfile("cpu.vcd");}
    puts $f {      $dumpvars();}
    puts $f {      $display("Contents: %d", dut.mem0.mem[3]);}
    puts $f {      #4096$display("Contents of T0 and T1: %d and %d", dut.regfile0.registers[8], dut.regfile0.registers[9]);}
    puts $f {      $display("Contents of v0: %d", dut.regfile0.registers[2]);}
    puts $f {      $finish;}
    puts $f {   end}
    puts $f {endmodule}
    close $f
}

if {[file exists work/_lib.qdb] == 0} {
    vlib work
}

set tests {
    {ADD    add.dat    {v0 = 1234}}
    {ADDI   addi.dat   {v0 = 123}}
    {SUB    sub.dat    {v0 = 12}}
    {SLT    slt.dat    {v0 = 1}}
    {XORI   xori.dat   {v0 = 2}}
    {LW_SW  lw_sw.dat  {v0 = 4096}}
    {BEQ    beq.dat    {v0 = 2}}
    {BNE    bne.dat    {v0 = 15}}
    {NSUM2  nsum2.dat  {v0 = 120}}
}

set passed 0
set failed 0

foreach t $tests {
    set label    [lindex $t 0]
    set datfile  [lindex $t 1]
    set expected [lindex $t 2]

    echo "===================="
    echo "TEST: $label  (beklenen: $expected)"
    echo "===================="

    write_testbench $datfile
    vlog -quiet cpu.t.v
    vsim -quiet work.cputest
    run -all
    quit -sim

    incr passed
    echo ""
}

echo "=============================="
echo "Toplam $passed test tamamlandi"
echo "=============================="

# cpu.t.v'yi nsum2 ile geri yukle
write_testbench nsum2.dat
