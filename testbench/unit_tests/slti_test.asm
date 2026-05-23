# slti_test: $v0 = (5 < 10) ? 1 : 0 = 1
addi $t0, $zero, 5       # 0x2008 0005
slti $v0, $t0, 10        # 0x2902 000a (op=0x0a rs=8 rt=2 imm=0x000a)
