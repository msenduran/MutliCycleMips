# branch_range_test: negative branch (loop) — backward branch with sign-extended imm
# Sum 1..10 using bne loop (verifies branch with negative offset)
loadi $t0, 0              # accumulator
loadi $t1, 1              # counter
loadi $t2, 11             # limit
loop:                     # PC=12
  add   $t0, $t0, $t1     # acc += i
  addi  $t1, $t1, 1       # i++
  bne   $t1, $t2, loop    # if i != 11, branch back
add   $v0, $t0, $zero     # v0 = 1+2+...+10 = 55
