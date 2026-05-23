# bgt_taken_test: 10>5 -> branch taken -> $v0=22
# PC=0  loadi $t0, 10                          # 0x7408 000a
# PC=4  loadi $t1, 5                           # 0x7409 0005
# PC=8  bgt   $t0, $t1, label   (offset=+3)    # 0x1d09 0003  target=12+3*4=24
# PC=12 loadi $v0, 11           (fall-through) # 0x7402 000b
# PC=16 j end                   (target=7=28>>2) # 0x0800 0007
# PC=20 loadi $v0, 99           (filler)       # 0x7402 0063
# PC=24 label: loadi $v0, 22                   # 0x7402 0016
# PC=28 end: j end              (self-loop)    # 0x0800 0007
