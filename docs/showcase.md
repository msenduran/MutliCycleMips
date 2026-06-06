# Demo Video Çekim Senaryosu (Showcase)

Bu doküman, projenin demo videosunu çekerken adım adım izlenecek **komut + anlatım** senaryosudur. Her segment bir ekip rolüne bağlıdır (PDF: her üye kendi alanını anlatır). Tahmini toplam süre: **8–11 dk**.

> **Ön hazırlık (kayıttan önce, ekranda gösterme):**
> - ModelSim ve Python'un PATH'de olduğunu doğrula: `vsim -version`, `python --version`
> - Terminali `testbench/` dizininde aç:
>   ```powershell
>   cd C:\intelFPGA\18.1\multicycle-mips-master\testbench
>   ```
> - İlk derleme için bir kez: `vlib work` (zaten varsa atla)
> - Terminal yazı tipini büyüt (okunabilirlik), pencereyi geniş yap.

---

## 0. Açılış (≈30 sn) — *Proje Yöneticisi: Meriç Şenduran*

**Anlatım:** "Bu projede multicycle MIPS işlemcisini Verilog ile tasarladık ve standart komut setine 6 yeni özel komut ekledik: LOADI, BGT, ADDI3, SWAP, MUL, PUSH/POP. Toplam 23 komut, 42 state'li FSM. ModelSim'de doğruladık, Quartus'ta sentezledik, Python ile bir assembler yazdık."

**Göster:** `docs/proje-raporu.md` (veya docx) başlığı ve §0 görev dağılımı tablosu — kim ne yaptı.

---

## 1. Proje Yapısı (≈30 sn) — *Entegrasyon & Dok.: Mehmet Kağan Kocadağ*

**Anlatım:** "Tasarım `rtl/` altında modüler: cpu (top), decode, fsm, alu, regfile, memory, mux'lar. Testler `testbench/`, dokümanlar `docs/`."

**Komut (klasör ağacı):**
```powershell
tree /F ..\rtl
```
**Göster:** `rtl/cpu.v` dosyasını kısaca aç — modül instance'ları (alu0, fsm0, regfile0, mem0, mux'lar).

---

## 2. Birim Testleri (≈60 sn) — *Verification & Test: Alperen Çiftcibaşı*

**Anlatım:** "Önce ALU ve register file'ı CPU'dan bağımsız test ettik."

**Komut:**
```powershell
.\run_unit_tests.ps1
```
**Beklenen:** `=== ALU birim testi: 14 PASS, 0 FAIL ===` ve `=== Regfile birim testi: 5 PASS, 0 FAIL ===`

**Vurgula:** ALU'nun 9 işlemi (ADD/SUB/XOR/SLT/AND/NAND/NOR/OR/MUL), zero/overflow bayrakları; register file'da `$zero` hardwired ve çift okuma portu.

---

## 3. Komut Testleri + Regresyon (≈90 sn) — *Verification & Test: Alperen*

**Anlatım:** "23 komutun her biri için ayrı test senaryosu yazdık; hepsi beklenen sonucu veriyor."

**Komut 1 (yeni komutlar, PASS/FAIL):**
```powershell
.\run_new_tests.ps1
```
**Beklenen:** 23 satır, hepsi `PASS` (ör. `mul_test expected=60 got=60 PASS`, `pushpop_lifo_test expected=30 got=30 PASS`).

**Komut 2 (regresyon — golden test):**
```powershell
.\run_regression.ps1
```
**Vurgula:** `nsum2 v0=120` — 1+2+…+15 toplamı; tüm değişikliklerden sonra korundu (regresyon yok).

---

## 4. FSM State Coverage (≈60 sn) — *Control Unit: Hakan Babur*

**Anlatım:** "Kontrol birimi 42 state'li bir FSM. Tüm testleri koşturup hangi state'lerin ziyaret edildiğini ölçtük."

**Komut:**
```powershell
.\run_coverage.ps1
```
**Beklenen:** Her testin girdiği state listesi + `State coverage: 41/42 (97.6%)`, eksik tek state `WB_JAL`.

**Vurgula:** `pushpop_lifo_test` satırında `EX_PUSH, MEM_PUSH, WB_PUSH_SP, MEM_POP, WB_POP_RT, WB_POP_SP` — stack komutlarının tüm state'leri. `WB_JAL` scope-dışı pre-existing durum.

---

## 5. Waveform — Komut Davranışı (≈3 dk) — *Control Unit: Hakan + Datapath: Meriç*

> **En etkili bölüm.** ModelSim GUI'de birkaç komutun dalga formunu canlı gösterin. Her testte `state` (FSM), `pc`, `ir`, `a`/`b`/`ALUOut`, kontrol sinyallerini işaret edin.
>
> **State sayı→isim eşlemesi** rapor §5'te. Hızlı referans:
> `0=IF, 3=ID_X, 8=EX_ADD, 11=EX_LWSWADDI, 35=EX_MUL, 30/31=EX_ADDI3_1/2, 28=EX_BGT, 36=EX_PUSH, 37=MEM_PUSH, 39=MEM_POP, 15=WB_SUBADDSLT, 16=WB_ADDIXORI`
>
> **Decimal görünüm:** `show_wave.do` artık `a/b/ALUOut/result`'ı ve **Register File** grubunu (`v0/t0/t1/t2/sp`) **decimal** gösterir — sonucun register'a düştüğünü doğrudan okuyabilirsin (ör. mul_test'te `t0=12, t1=5, v0=60`). Anlık değiştirmek için Wave'de sinyale sağ tık → **Radix ▸ Decimal/Unsigned**.

**GUI'yi aç (terminalden):**
```powershell
vsim -do "do show_wave.do nsum2"
```
*(veya ModelSim konsolundan `do show_wave.do nsum2`)*

### 5a. Genel akış — `nsum2`
**Göster:** `pc` 0→4→8→C… ilerliyor; her komut `IF → ID_X → EX → WB`. `irWe`/`pcWe` fetch'te, `regWe` write-back'te darbeleniyor.

### 5b. MUL — `do show_wave.do mul_test`
**Anlatım:** "MUL tek ALU işleminde çarpıyor." **Göster:** state `IF→ID_X→EX_MUL(35)→WB_SUBADDSLT(15)`; `a=C` (12), `b=5`, `ALUOut=3C` (60).

### 5c. ADDI3 — `do show_wave.do addi3_test`
**Anlatım:** "ADDI3 üç operandlı — ALU iki cycle kullanıyor." **Göster:** `EX_ADDI3_1(30)`'da `ALUOut=1E` (30), `EX_ADDI3_2(31)`'de `ALUOut=23` (35).

### 5d. PUSH/POP — `do show_wave.do pushpop_lifo_test`
**Anlatım:** "Yığın aşağı büyüyor, LIFO." **Göster:** Wave'de **Zoom Full** yapıp push bölgesine bak: `a` (SP) `1000→FFC→FF8→FF4`, `memWe` darbeleri, sonra POP en son değeri (30) geri okuyor.

### 5e. BGT — `do show_wave.do bgt_taken_test`
**Anlatım:** "Yeni signed büyüktür dallanması." **Göster:** `EX_BGT(28)` → `gt` bayrağı → `WB_BGT(29)`'da `pcWe`, dal alınıyor.

---

## 6. Quartus RTL — Sentezlenebilirlik (≈60 sn) — *Datapath: Meriç Şenduran*

**Anlatım:** "Tasarım sadece simüle edilebilir değil; Quartus Prime'da Cyclone IV E hedefine 0 hatayla sentezlenebiliyor."

**Komut (zaten elaborate edildiyse atla):**
```powershell
cd ..\quartus
& "C:\intelFPGA_lite\18.1\quartus\bin64\quartus_map.exe" MultiCycleMips --analysis_and_elaboration
```
**Göster (GUI):** Quartus'ta projeyi aç → **Tools ▸ Netlist Viewers ▸ RTL Viewer** → cpu'nun tüm blokları: decode/fsm, alu, regfile, memory, 7 mux, pc/ir/**mdr**/a/b/ffResult register'ları. (Bu şema raporda §4.3'te de var.)

---

## 7. Assembler (≈60 sn) — *ISA & Assembler: Ömer Yasin Akis*

**Anlatım:** "Assembly kodunu makine koduna çeviren 2-geçişli bir Python assembler yazdık; label ve 23 komutu destekliyor."

**Komut:**
```powershell
cd C:\intelFPGA\18.1\multicycle-mips-master
python assembler.py testbench\unit_tests\mul_test.asm
```
**Göster:** `mul_test.asm` kaynağı (loadi/loadi/mul) → üretilen `.dat` (hex makine kodu). İstersen encoding örneği: `mul $v0,$t0,$t1 → 0x01091018`.

**Bağla:** "Bu .dat dosyasını az önce ModelSim'de koşturduk — uçtan uca akış: assembly → makine kodu → simülasyon."

---

## 8. Kapanış (≈30 sn) — *Proje Yöneticisi: Meriç*

**Özet (ekranda rapor §1 / §10):**
- 23 komut, 42-state FSM
- Birim (ALU 14/14, regfile 5/5) + komut (23/23) testleri PASS, nsum2=120 golden korundu
- FSM coverage %97.6
- Quartus'ta 0-hata sentez
- Python assembler

**Kapanış cümlesi:** "Teknik rapor, kaynak kod, testbench'ler, assembler ve bu demo Drive'da; linkler raporun ilk sayfasında."

---

## Demo Waveform Komutları — 10 test (kopyala-yapıştır)

Her satır ModelSim GUI'yi açıp ilgili testin dalga formunu (decimal register'larla) gösterir. Prompt'a `!` ile yapıştır:

```powershell
# 1) Genel akış — döngü + branch (1+...+15 = 120)
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do nsum2"

# 2) MUL — EX_MUL, v0=60
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do mul_test"

# 3) MUL signed — v0=-42 (decimal signed)
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do mul_neg_test"

# 4) ADDI3 — iki aşamalı ALU, v0=35
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do addi3_test"

# 5) SWAP — register takası, v0=200
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do swap_test"

# 6) PUSH/POP — LIFO yığın, sp düşer, v0=30
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do pushpop_lifo_test"

# 7) BGT — signed büyüktür dallanması, gt flag, v0=22
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do bgt_taken_test"

# 8) LOADI — immediate yükleme, v0=42
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do loadi_test"

# 9) LW/SW — bellek load/store, v0=4096
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do lw_sw"

# 10) BEQ — eşitlik dallanması, v0=2
Set-Location C:\intelFPGA\18.1\multicycle-mips-master\testbench; vsim -do "do show_wave.do beq"
```

> Kısayolla aynısı: `testbench/` dizininde `.\wave.ps1 <test>` (ör. `.\wave.ps1 pushpop_lifo_test`).

## Hızlı Komut Kartı (tek bakışta)

```powershell
# testbench/ dizininden:
.\run_unit_tests.ps1        # ALU 14/14 + regfile 5/5
.\run_new_tests.ps1         # 23 komut testi (PASS/FAIL)
.\run_regression.ps1        # nsum2=120 golden + 13 test
.\run_coverage.ps1          # FSM 41/42 (%97.6)

.\wave.ps1 mul_test         # kisayol: GUI'de o testin waveform'unu acar
vsim -do "do show_wave.do mul_test"     # ayni sey, acik komut

# repo kökünden:
python assembler.py testbench\unit_tests\mul_test.asm   # asm -> dat

# quartus/ dizininden (RTL Viewer için elaborate):
& "C:\intelFPGA_lite\18.1\quartus\bin64\quartus_map.exe" MultiCycleMips --analysis_and_elaboration
```

> **Çekim ipuçları:** terminal yazısını büyüt; her komuttan önce ne yapacağını bir cümleyle söyle; waveform'da fareyle ilgili sinyali işaret et; uzun testlerde çıktıyı hızlandırmadan PASS satırlarını göster.
