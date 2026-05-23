# mem_boundary_test: write to and read from high memory address
# Memory is 65536 bytes (16-bit addr). Use address 0x2000 (well within range).
loadi $t0, 0xDEAD         # 16-bit signed imm: 0xDEAD = -8531 signed, sxi -> 0xFFFFDEAD
# To get clean value, mul small numbers:
loadi $t0, 100
loadi $t1, 8192           # 0x2000
sw    $t0, 0($t1)         # mem[0x2000] = 100
lw    $v0, 0($t1)         # $v0 = mem[0x2000] = 100
