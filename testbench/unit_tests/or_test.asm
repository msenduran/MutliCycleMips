# or_test: $v0 = 12 | 10 = 14
addi $t0, $zero, 12      # 0x2008 000c
addi $t1, $zero, 10      # 0x2009 000a
or   $v0, $t0, $t1       # 0x0109 1025  (funct=0x25)
