# pop_test: push 99, pop into $v0 -> $v0 = 99
loadi $sp, 4096
loadi $t0, 99
push  $t0                 # SP=0x0FFC; mem[0x0FFC] = 99
pop   $v0                 # $v0 = 99 ; SP=0x1000
