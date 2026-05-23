# swap_test2: swap sonrası $t1=100 doğrulaması -> v0 = $t1 = 100
# PC=0  loadi $t0, 100
# PC=4  loadi $t1, 200
# PC=8  swap  $t0, $t1
# PC=12 add   $v0, $t1, $zero   # rs=9 rt=0 rd=2 -> 0x0120 0020
