# overflow_test: ADD positive overflow via MUL amplification
# loadi imm 16-bit signed: max = 32767 = 0x7FFF
# mul amplifies to 32767*32767 = 0x3FFF0001 = 1073676289
# add doubles -> 0x7FFE0002 = 2147352578 (still positive)
# add doubles again -> 0xFFFC0004 = -262140 (32-bit signed: overflow!)
loadi $t0, 32767
mul   $t1, $t0, $t0       # t1 = 0x3FFF0001
add   $t1, $t1, $t1       # t1 = 0x7FFE0002 (no overflow yet)
add   $v0, $t1, $t1       # v0 = 0xFFFC0004 = -262140 (signed overflow)
