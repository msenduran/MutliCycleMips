# push_test: push 42 onto stack, verify via lw
# SP init = 0x1000 (4096)
loadi $sp, 4096
loadi $t0, 42
push  $t0                 # SP=0x0FFC; mem[0x0FFC] = 42
lw    $v0, 0($sp)         # $v0 = mem[0x0FFC] = 42
