# gen_waveforms.ps1
# Generates report waveform figures (docs/img/wave_*.png) fully headless:
# for each test it patches cpu.t.v, compiles, runs ModelSim to produce cpu.vcd,
# then renders selected signals via vcd_to_wave.py. Restores cpu.t.v at the end.
#
# Run from the testbench/ directory:  .\gen_waveforms.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$tb = Join-Path $PSScriptRoot "cpu.t.v"
$orig = [System.IO.File]::ReadAllText($tb)

$tests = @(
  @{ dat = "nsum2.dat";             png = "wave_nsum2.png";   start = 0;  end = 56;
     title = "nsum2 - genel multi-cycle akis: IF/ID/EX/WB, PC ilerlemesi, kontrol sinyalleri" },
  @{ dat = "mul_test.dat";          png = "wave_mul.png";     start = 0;  end = 30;
     title = "MUL - EX_MUL state'i, ALU result = 12 x 5 = 0x3C (60)" },
  @{ dat = "addi3_test.dat";        png = "wave_addi3.png";   start = 0;  end = 32;
     title = "ADDI3 - iki asamali ALU: EX_ADDI3_1 (rs+rt) -> EX_ADDI3_2 (+imm11) = 35" },
  @{ dat = "pushpop_lifo_test.dat"; png = "wave_pushpop.png"; start = 26; end = 82;
     title = "PUSH/POP - LIFO yigin: MEM_PUSH / MEM_POP, memWe darbeleri, SP -/+ 4" }
)

if (-not (Test-Path work/_lib.qdb)) { vlib work | Out-Null }

try {
  foreach ($t in $tests) {
    $patched = $orig -replace 'unit_tests/[^"]+\.dat', "unit_tests/$($t.dat)"
    [System.IO.File]::WriteAllText($tb, $patched)
    vlog -quiet cpu.t.v | Out-Null
    vsim -c work.cputest -do "run -all; quit" | Out-Null
    python vcd_to_wave.py cpu.vcd "../docs/img/$($t.png)" --title $t.title --start $t.start --end $t.end
  }
}
finally {
  [System.IO.File]::WriteAllText($tb, $orig)
  Write-Host "cpu.t.v restored."
}
