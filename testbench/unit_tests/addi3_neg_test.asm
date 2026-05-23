# addi3_neg_test: $v0 = 10 + 20 + (-3) = 27 (sign-extend 11-bit)
loadi $t0, 10            # 0x7408 000a
loadi $t1, 20            # 0x7409 0014
# addi3 $v0, $t0, $t1, -3
#   op=0x1e rs=8 rt=9 rd=2 imm11=0x7FD (-3 in 11-bit two's complement)
#   011110 01000 01001 00010 11111111101
#   = 0x7909 17FD
addi3 $v0, $t0, $t1, -3  # 0x7909 17FD
