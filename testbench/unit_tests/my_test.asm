# Test: 10 * 3 = 30 hesapla (carpma yok, tekrarlı toplama ile)
# $t0 = sayac (3'e kadar sayar)
# $t1 = 10 (her adim bu kadar eklenir)
# $v0 = toplam sonuc

addi $t0, $zero, 0      # sayac = 0
addi $t1, $zero, 10     # t1 = 10
addi $t2, $zero, 3      # limit = 3
addi $v0, $zero, 0      # toplam = 0

loop:
    add  $v0, $v0, $t1  # toplam += 10
    addi $t0, $t0, 1    # sayac++
    bne  $t0, $t2, loop # sayac != 3 ise dongu

# $v0 = 30 olmali
