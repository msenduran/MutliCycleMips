# pushpop_lifo_test: push 10, push 20, push 30. pop into $v0 -> 30 (LIFO)
loadi $sp, 4096
loadi $t0, 10
loadi $t1, 20
loadi $t2, 30
push  $t0                 # mem[0x0FFC]=10
push  $t1                 # mem[0x0FF8]=20
push  $t2                 # mem[0x0FF4]=30
pop   $v0                 # $v0=30
