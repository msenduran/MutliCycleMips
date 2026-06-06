# FSM state coverage: tüm yeni komut testlerini koştur, birleşik state setini topla
$tests = @(
    "and_test","or_test","xor_r_test","andi_test","ori_test","slti_test",
    "loadi_test","loadi_neg_test",
    "bgt_taken_test","bgt_nottaken_test","bgt_eq_test",
    "addi3_test","addi3_neg_test",
    "swap_test","swap_test2",
    "mul_test","mul_zero_test","mul_neg_test",
    "push_test","pop_test","pushpop_lifo_test",
    "overflow_test","mem_boundary_test","branch_range_test",
    "nsum2","add","sub","slt","xori","addi","beq","bne","j","jal","jr","lw_sw"
)

$tbPath = "fsm_coverage.t.v"
$original = Get-Content $tbPath -Raw
$unionMask = [uint64]0

$stateNames = @(
    "IF","ID_B","ID_J","ID_X","EX_BEQ","EX_BNE","EX_JR","EX_SUB","EX_ADD","EX_SLT",
    "EX_XORI","EX_LWSWADDI","MEM_LW","MEM_SW","WB_JAL","WB_SUBADDSLT","WB_ADDIXORI","WB_LW","WB_BEQ","WB_BNE",
    "EX_AND","EX_OR","EX_XOR_R","EX_ANDI","EX_ORI","EX_SLTI","WB_R_LOGIC","WB_I_LOGIC","EX_BGT","WB_BGT",
    "EX_ADDI3_1","EX_ADDI3_2","WB_ADDI3","WB_SWAP1","WB_SWAP2","EX_MUL",
    "EX_PUSH","MEM_PUSH","WB_PUSH_SP","MEM_POP","WB_POP_RT","WB_POP_SP"
)

foreach ($name in $tests) {
    $patched = $original -replace 'unit_tests/[a-zA-Z0-9_]+\.dat', "unit_tests/$name.dat"
    Set-Content -Path $tbPath -Value $patched -Encoding ASCII
    $null = vlog $tbPath 2>&1
    $out = vsim -c work.cputest_cov -do "run -all; quit" 2>&1 | Out-String
    $m = [regex]::Match($out, 'Visited state bitmask:\s+([0-9a-fA-F]+)')
    if ($m.Success) {
        $mask = [Convert]::ToUInt64($m.Groups[1].Value, 16)
        $unionMask = $unionMask -bor $mask

        # Per-test log
        $testStates = @()
        for ($i = 0; $i -lt $stateNames.Length; $i++) {
            if ($mask -band ([uint64]1 -shl $i)) { $testStates += $stateNames[$i] }
        }
        "{0,-22} [{1}]" -f $name, ($testStates -join ", ")
    } else {
        "{0,-22} NO OUTPUT" -f $name
    }
}
Set-Content -Path $tbPath -Value $original -Encoding ASCII

# Decode union mask
$visited = 0
$missing = @()
for ($i = 0; $i -lt $stateNames.Length; $i++) {
    if ($unionMask -band ([uint64]1 -shl $i)) {
        $visited++
    } else {
        $missing += "{0,2}={1}" -f $i, $stateNames[$i]
    }
}

"State coverage: {0}/{1} ({2:N1}%)" -f $visited, $stateNames.Length, ($visited / $stateNames.Length * 100)
if ($missing.Count -gt 0) {
    "Eksik state'ler:"
    $missing | ForEach-Object { "  $_" }
} else {
    "Tüm state'ler en az bir test tarafından ziyaret edildi."
}
