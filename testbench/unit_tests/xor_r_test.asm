# xor_r_test (R-type xor): $v0 = 12 ^ 10 = 6
addi $t0, $zero, 12      # 0x2008 000c
addi $t1, $zero, 10      # 0x2009 000a
xor  $v0, $t0, $t1       # 0x0109 1026  (funct=0x26)
