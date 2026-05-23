addi $t0, $zero, 5
addi $t1, $zero, 0
addi $t2, $zero, 0
label:
addi $t1, $t1, 1
add $t2, $t1, $t2
bne $t0, $t1, label
add $v0, $t2, $zero