# bgt_nottaken_test: 5>10 -> branch NOT taken -> $v0=11
# PC=0  loadi $t0, 5                           # 0x7408 0005
# PC=4  loadi $t1, 10                          # 0x7409 000a
# PC=8  bgt   $t0, $t1, label   (offset=+3)    # 0x1d09 0003
# PC=12 loadi $v0, 11           (taken path)   # 0x7402 000b
# PC=16 j end                   (target=7)     # 0x0800 0007
# PC=20 loadi $v0, 99                          # 0x7402 0063
# PC=24 label: loadi $v0, 22                   # 0x7402 0016
# PC=28 end: j end                             # 0x0800 0007
