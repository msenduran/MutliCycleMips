# and_test: $v0 = 12 & 10 = 8
addi $t0, $zero, 12      # 0x2008 000c
addi $t1, $zero, 10      # 0x2009 000a
and  $v0, $t0, $t1       # 0x0109 1024  (op=0 rs=8 rt=9 rd=2 funct=0x24)
