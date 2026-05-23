# andi_test: $v0 = 12 & 10 = 8 (zero-extended imm)
addi $t0, $zero, 12      # 0x2008 000c
andi $v0, $t0, 10        # 0x3102 000a (op=0x0c rs=8 rt=2 imm=0x000a)
