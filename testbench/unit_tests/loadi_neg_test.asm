# loadi_neg_test: $v0 = -1 (sign-extended imm 0xFFFF -> 0xFFFFFFFF)
loadi $v0, -1            # op=0x1d rs=0 rt=2 imm=0xFFFF -> 0x7402 FFFF
