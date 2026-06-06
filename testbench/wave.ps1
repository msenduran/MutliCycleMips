# wave.ps1 — ModelSim GUI'de bir testin waveform'unu acar (decimal register'larla).
# Kullanim:
#   .\wave.ps1               -> nsum2
#   .\wave.ps1 mul_test      -> unit_tests/mul_test.dat
#   .\wave.ps1 pushpop_lifo_test
param([string]$test = "nsum2")
Set-Location $PSScriptRoot
vsim -do "do show_wave.do $test"
