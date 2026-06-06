# show_wave.do
# Kullanim: vsim -do show_wave.do
# Veya ModelSim transcript'ten: do show_wave.do
#
# Hangi testi gormek istiyorsan asagidaki satiri degistir:
set TESTDAT "unit_tests/nsum2.dat"

if {[file exists work/_lib.qdb] == 0} { vlib work }

# cpu.t.v icindeki dat dosyasini gecici olarak degistir
set f [open "cpu.t.v" r]
set src [read $f]
close $f
set patched [regsub {unit_tests/[a-zA-Z0-9_]+\.dat} $src $TESTDAT]
set f [open "cpu.t.v.tmp" w]
puts -nonewline $f $patched
close $f

vlog -quiet cpu.t.v.tmp
file delete cpu.t.v.tmp

vsim -quiet work.cputest

# Temel datapath sinyalleri
add wave -divider {Clock}
add wave                 sim:/cputest/clk

add wave -divider {PC and IR}
add wave -radix hex      sim:/cputest/dut/pc
add wave -radix hex      sim:/cputest/dut/ir

add wave -divider {FSM}
add wave -radix unsigned sim:/cputest/dut/fsm0/state
add wave -radix unsigned sim:/cputest/dut/fsm0/prevState

add wave -divider {ALU}
add wave -radix hex      sim:/cputest/dut/result
add wave                 sim:/cputest/dut/zero
add wave                 sim:/cputest/dut/overflow
add wave                 sim:/cputest/dut/gt

add wave -divider {Registers}
add wave -radix hex      sim:/cputest/dut/a
add wave -radix hex      sim:/cputest/dut/b
add wave -radix hex      sim:/cputest/dut/ffResult

add wave -divider {Memory}
add wave                 sim:/cputest/dut/mem0/we
add wave -radix hex      sim:/cputest/dut/mem0/addr
add wave -radix hex      sim:/cputest/dut/mem0/dOut

add wave -divider {Control}
add wave                 sim:/cputest/dut/fsm0/pcWe
add wave                 sim:/cputest/dut/fsm0/irWe
add wave                 sim:/cputest/dut/fsm0/regWe
add wave                 sim:/cputest/dut/fsm0/memWe
add wave                 sim:/cputest/dut/fsm0/aluResWe

run 4096 ns
wave zoom full
