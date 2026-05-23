# ori_test: $v0 = 12 | 10 = 14 (zero-extended imm)
addi $t0, $zero, 12      # 0x2008 000c
ori  $v0, $t0, 10        # 0x3502 000a (op=0x0d rs=8 rt=2 imm=0x000a)
