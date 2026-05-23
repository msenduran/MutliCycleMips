# swap_test: $t0=100, $t1=200, swap -> $t0=200, $t1=100, then $v0 = $t0 = 200
loadi $t0, 100
loadi $t1, 200
swap  $t0, $t1
add   $v0, $t0, $zero
