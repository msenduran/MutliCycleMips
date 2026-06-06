# show_wave.do
# Kullanim: vsim -do show_wave.do
# Veya ModelSim transcript'ten: do show_wave.do
#
# Test secimi (argumanla veya varsayilan):
#   do show_wave.do              -> nsum2 (varsayilan)
#   do show_wave.do mul_test     -> unit_tests/mul_test.dat
#   do show_wave.do push_test    -> unit_tests/push_test.dat
# Komut satirindan acmak icin:  vsim -do "do show_wave.do mul_test"
if {$argc > 0} {
   set TESTNAME $1
} else {
   set TESTNAME "nsum2"
}
set TESTDAT "unit_tests/$TESTNAME.dat"
echo "Waveform testi: $TESTDAT"

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
add wave -radix decimal  sim:/cputest/dut/result
add wave                 sim:/cputest/dut/zero
add wave                 sim:/cputest/dut/overflow
add wave                 sim:/cputest/dut/gt

add wave -divider {Registers (decimal)}
add wave -radix decimal  sim:/cputest/dut/a
add wave -radix decimal  sim:/cputest/dut/b
add wave -radix decimal  sim:/cputest/dut/ffResult

# Gercek register dosyasi (programin sonuclari) - decimal
add wave -divider {Register File (decimal)}
add wave -radix decimal -label {v0 (r2)}  {sim:/cputest/dut/regfile0/registers[2]}
add wave -radix decimal -label {t0 (r8)}  {sim:/cputest/dut/regfile0/registers[8]}
add wave -radix decimal -label {t1 (r9)}  {sim:/cputest/dut/regfile0/registers[9]}
add wave -radix decimal -label {t2 (r10)} {sim:/cputest/dut/regfile0/registers[10]}
add wave -radix decimal -label {sp (r29)} {sim:/cputest/dut/regfile0/registers[29]}

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
# Tüm simülasyon yerine ilk ~6 komutu okunabilir göster (screenshot için).
# Tüm akışı görmek istersen: wave zoom full
wave zoom range 0 56
