addi $t0, $zero, 0
addi $t1, $zero, 1
label:
addi	$t0, $t0, 1
beq $t0, $t1, label
add $v0, $t0, $zero