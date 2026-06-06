# Mevcut testler hâlâ geçiyor mu kontrol
$tests = @(
    "nsum2","add","sub","slt","xori","addi","beq","bne","j","jal","jr","lw_sw","add123"
)
$tests = $tests | ForEach-Object { @{Name=$_} }

$tbPath = "cpu.t.v"
$original = Get-Content $tbPath -Raw

foreach ($t in $tests) {
    $name = $t.Name
    $patched = $original -replace 'unit_tests/[a-zA-Z0-9_]+\.dat', "unit_tests/$name.dat"
    Set-Content -Path $tbPath -Value $patched -Encoding ASCII
    $null = vlog $tbPath 2>&1
    $out  = vsim -c work.cputest -do "run -all; quit" 2>&1 | Out-String
    $m = [regex]::Match($out, 'Contents of v0:\s+(-?\d+)')
    if ($m.Success) {
        "{0,-14} v0={1}" -f $name, $m.Groups[1].Value
    } else {
        "{0,-14} NO v0 output" -f $name
    }
}

Set-Content -Path $tbPath -Value $original -Encoding ASCII
