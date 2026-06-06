# Yeni eklenen standart komutlar için batch test
$tests = @(
    @{Name="and_test";    Expected=8},
    @{Name="or_test";     Expected=14},
    @{Name="xor_r_test";  Expected=6},
    @{Name="andi_test";   Expected=8},
    @{Name="ori_test";    Expected=14},
    @{Name="slti_test";   Expected=1},
    @{Name="loadi_test";  Expected=42},
    @{Name="bgt_taken_test";    Expected=22},
    @{Name="bgt_nottaken_test"; Expected=11},
    @{Name="bgt_eq_test";       Expected=11},
    @{Name="addi3_test";        Expected=35},
    @{Name="addi3_neg_test";    Expected=27},
    @{Name="swap_test";         Expected=200},
    @{Name="swap_test2";        Expected=100},
    @{Name="mul_test";          Expected=60},
    @{Name="mul_zero_test";     Expected=0},
    @{Name="mul_neg_test";      Expected=-42},
    @{Name="push_test";         Expected=42},
    @{Name="pop_test";          Expected=99},
    @{Name="pushpop_lifo_test"; Expected=30},
    @{Name="overflow_test";     Expected=-262140},
    @{Name="mem_boundary_test"; Expected=100},
    @{Name="branch_range_test"; Expected=55}
)

$tbPath = "cpu.t.v"
$original = Get-Content $tbPath -Raw

foreach ($t in $tests) {
    $name = $t.Name
    $exp  = $t.Expected
    $patched = $original -replace 'unit_tests/[a-zA-Z0-9_]+\.dat', "unit_tests/$name.dat"
    Set-Content -Path $tbPath -Value $patched -Encoding ASCII

    $null = vlog $tbPath 2>&1
    $out  = vsim -c work.cputest -do "run -all; quit" 2>&1 | Out-String
    $m = [regex]::Match($out, 'Contents of v0:\s+(-?\d+)')
    if ($m.Success) {
        $raw = [int64]$m.Groups[1].Value
        # Convert 32-bit unsigned to signed if needed
        $got = if ($raw -ge 2147483648) { $raw - 4294967296 } else { $raw }
        $ok = if ($got -eq $exp) { "PASS" } else { "FAIL" }
        "{0,-14} expected={1,-4} got={2,-4} {3}" -f $name, $exp, $got, $ok
    } else {
        "{0,-14} NO v0 output" -f $name
    }
}

# Restore original testbench
Set-Content -Path $tbPath -Value $original -Encoding ASCII
