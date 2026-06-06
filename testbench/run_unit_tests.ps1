# run_unit_tests.ps1 — ALU ve Register File birim testlerini ModelSim'de koşar.
#   .\run_unit_tests.ps1
Set-Location $PSScriptRoot
if (-not (Test-Path work/_lib.qdb)) { vlib work | Out-Null }

foreach ($tb in @("alu_tb", "regfile_tb")) {
    vlog -quiet "$tb.v" | Out-Null
    $out = vsim -c "work.$tb" -do "run -all; quit"
    $out | Select-String -Pattern "PASS|FAIL|==="
}
