# bgt_eq_test: 5>5 (equal) -> branch NOT taken (strict greater) -> $v0=11
# PC=0  loadi $t0, 5
# PC=4  loadi $t1, 5
# PC=8  bgt $t0, $t1, label (offset=+3)
# PC=12 loadi $v0, 11
# PC=16 j end
# PC=20 loadi $v0, 99
# PC=24 label: loadi $v0, 22
# PC=28 end: j end
