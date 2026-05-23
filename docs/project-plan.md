# Genişletilmiş MIPS Multi-Cycle CPU — Proje Planı

Bu doküman, mevcut multicycle MIPS Verilog tasarımını **2026 mimari proje** gereksinimlerine göre genişletme planıdır. PDF: `2026-mimari_proje.pdf`. Son teslim: **8 Haziran 2026**.

---

## 1. Kapsam ve Mevcut Durum

### 1.1 ISA hedefi

**Standart MIPS (PDF zorunlu):** add, sub, and, or, xor, slt, addi, slti, andi, ori, xori, lw, sw, beq, bne, j  
**Repo'da mevcut (artılar):** jr, jal  
**Eklenecek yeni komutlar (PDF):** ADDI3, MUL, SWAP, LOADI, BGT, PUSH, POP

### 1.2 Eksik standartlar ve karşılığı

| Komut | Op/Funct | ALU op'u mevcut mu? | Eklenecek yer |
|---|---|---|---|
| and  rd,rs,rt | op=0, funct=0x24 | ✅ `ALU_AND` | decode + fsm |
| or   rd,rs,rt | op=0, funct=0x25 | ✅ `ALU_OR`  | decode + fsm |
| xor  rd,rs,rt | op=0, funct=0x26 | ✅ `ALU_XOR` | decode + fsm |
| andi rt,rs,im | op=0x0c          | ✅ `ALU_AND` | decode + fsm (sxi yerine **zero-ext** gerek; not §3.4) |
| ori  rt,rs,im | op=0x0d          | ✅ `ALU_OR`  | decode + fsm (zero-ext) |
| slti rt,rs,im | op=0x0a          | ✅ `ALU_SLT` | decode + fsm |

ALU'da gerekli oplar **zaten var** (`rtl/alu.v:25-33`). Donanım açısından "ucuz" eklemeler.

### 1.3 Mimari teyit (PDF Teknik Gereksinimler bölümü)

PDF: PC, IR, Memory (I+D), Register File, ALU, MDR, A, B, ALUOut + 5 faz (IF/ID/EX/MEM/WB).

Mevcut karşılık (`rtl/cpu.v`):
- ✅ PC: `pc` (cpu.v:59)
- ✅ IR: `ir` (cpu.v:16)
- ✅ Unified memory: `mem0` (cpu.v:106)
- ✅ Register file: `regfile0`
- ✅ ALU: `alu0`
- ✅ A, B: `a`, `b` (cpu.v:59) — `aWe`/`bWe` ile yüklenir
- ✅ ALUOut karşılığı: `ffResult` (cpu.v:95–96)
- ⚠️ **MDR yok** — `dOut` (memory çıkışı) doğrudan kullanılıyor; raporda "implicit MDR via combinational read" denebilir veya **gerçek bir MDR register'ı eklenebilir** (temizlik için tercih edilebilir, §3.5).

**Karar:** MDR register'ı eklenecek (rapor uyumu + temiz tasarım). Diğer registerlar hazır.

---

## 2. Komut Bazlı Plan

Her satır: **opcode/format · cycle · datapath etkisi**.

### 2.1 Standart eklemeler

| Komut | Format | Opcode/Funct | Cycle | Datapath değişikliği |
|---|---|---|---|---|
| AND  rd,rs,rt | R | op=0, funct=0x24 | 4 (IF→ID→EX→WB) | Yok — `EX_AND` state, `aluOp=AND` |
| OR   rd,rs,rt | R | op=0, funct=0x25 | 4 | Yok — `EX_OR` |
| XOR  rd,rs,rt | R | op=0, funct=0x26 | 4 | Yok — `EX_XOR_R` (mevcut `EX_XORI`'dan ayrı) |
| ANDI rt,rs,im | I | 0x0c | 4 | `aluB` = **zero-ext** imm; yeni `ALU_SRC_B_ZXI` (§3.4) |
| ORI  rt,rs,im | I | 0x0d | 4 | aynı zxi |
| SLTI rt,rs,im | I | 0x0a | 4 | `aluB`=sxi, `aluOp=SLT` (yeni state `EX_SLTI`) |

### 2.2 Yeni komutlar

#### (a) `LOADI rd, imm` — basit
- **Format:** I-type benzeri. Önerilen: `op=0x1d (custom), rt=rd, im16=imm`. (rs alanı = 0.)
- **Cycle:** 3 (IF → EX(no-op A/B) → WB).
- **Datapath:** ALU `0+sxi` ile imm'i geçir. `aluA = $zero (regfile read of $0)` veya yeni "0" kaynağı. Pratik yol: ID'de `a ← reg[rs]=reg[0]`, EX'te `aluA=A, aluB=SXI, aluOp=ADD`. Bu durumda **mevcut datapath yeterli**.
- **WB:** `dst=RT (=rd alanı), regIn=ALU_RES`.

#### (b) `BGT rs, rt, label`
- **Format:** I-type. `op=0x07` (boş slot).
- **Cycle:** 4 (IF → ID_B → EX_BGT → WB_BGT). BEQ/BNE ile aynı şablon.
- **Datapath:** ALU'da **`SLT` operandlarını ters çevir**: `aluA=B (rt)`, `aluB=A (rs)`, `aluOp=SLT`. Sonuç `result==1` ise `rs>rt`. Mevcut `result` bit0'ı branch koşulu olur — `eq` sinyali yeniden kullanılamaz (zero+overflow tabanlı); yeni `gt` sinyali türetelim: `assign gt = result[0]`. `WB_BGT.pcWe = gt`.
- **Branch hedefi:** README/BNE ile aynı: `PC+4 + (imm<<2)`. ID_B'de `aluA=PC, aluB=sxi<<2, op=ADD` → `ffResult`. WB'de bu `ffResult` PC'ye yazılır.

#### (c) `ADDI3 rd, rs, rt, imm`
- **Format:** Yeni format. R-type'a sığmıyor (shamt 5-bit, imm gerek). Önerilen: **I-type ama rd dahil**: `op=0x1e | rs5 | rt5 | rd5 | imm11` (toplam 32-bit). 11-bit imm ile sign-extend.
- **Cycle:** 5 (IF → ID_X → EX1 → EX2 → WB).
- **Datapath:** 2-aşamalı ALU:
  - **EX1:** `aluA=A (rs), aluB=B (rt), op=ADD` → `ffResult ← rs+rt`.
  - **EX2:** `aluA=ffResult, aluB=sxi11, op=ADD` → `ffResult ← (rs+rt)+imm`.
  - **WB:** `dst=ADDI3_RD (yeni — rd alanı 5-bit imm'in altı)`, `regIn=ALU_RES`.
- **Donanım etkisi:** `aluA`'ya **3. kaynak** gerek (`ffResult`). `aluAMux` 2-way → **4-way'e yükselt** (§3.3). `writeAddrMux`'a da yeni alan: instr[10:6] olarak rd yerleşimi tercih edilebilir (`mux4way` yap). Sxi yardımcı: **11-bit özel sign-extend** decode'ta üretilir.

#### (d) `SWAP rs, rt`
- **Format:** R-type alt-tip. `op=0, funct=0x30` (kullanılmayan funct).
- **Cycle:** 5 (IF → ID_X → WB_SWAP1 → WB_SWAP2 → IF).
- **Datapath:** Regfile **tek yazma portlu** → 2-cycle yazma.
  - ID_X: `a←reg[rs]`, `b←reg[rt]` (zaten varsayılan).
  - WB_SWAP1: `writeAddr=rs (yani rs alanı)`, `regDIn=B`. → regfile[rs] ← eski rt.
  - WB_SWAP2: `writeAddr=rt`, `regDIn=A`. → regfile[rt] ← eski rs.
- **Donanım etkisi:** `writeAddrMux` (şu an 2-way: rd/rt) → **4-way**: rd / rt / rs / $31 ($31 JAL için, hâlâ JAL'i `ffResult+pc-4` ile yapıyorsa). `regDInMux` 2-way → **4-way**: MDR / ALU_RES / **A** / **B**. (LOADI ek kaynağa ihtiyaç duymadığı için bu mux genişlemesi yalnızca SWAP için.)

#### (e) `MUL rd, rs, rt`
- **Format:** R-type. `op=0, funct=0x18` (gerçek MIPS `mult` da 0x18 ama HI/LO'ya yazar; biz tek 32-bit ürün döndürüp `rd`'ye yazıyoruz — basitleştirilmiş).
- **Cycle:** 2 yaklaşım var:
  - **(i) Tek-cycle `*`**: `result = a * b;` Verilog operatörü — sentez aracı çarpıcı çıkarır. EX_MUL → WB_MUL. 4-cycle toplam. **Önerilen başlangıç** (basit, hızlı).
  - **(ii) Iterative shift-add**: yeni `mul.v` modülü, `start/done` el sıkışması, ~32-cycle. FSM'de `EX_MUL_WAIT` state'i. **Daha "multi-cycle ALU extension"** ruhuna uyar (PDF'in dediği gibi).
- **Karar:** Önce (i) ile ilerle, vakit kalırsa (ii)'ye çevir. Rapor için (ii) tercih sebebi: "multi-cycle ALU extension" gereksinimini açıkça karşılar.
- **Donanım etkisi:** ALU'ya `MUL` opu eklenir (3-bit `command` zaten `0..7` dolu → `command`'i **4-bit'e** çıkar veya MUL'ü ALU dışına çıkar). Pratik: **mul.v ayrı modül**, paralel; ALU dokunulmaz. cpu.v'de yeni `mulResult` + mux entry.

#### (f) `PUSH rs` / `POP rd`
- **Format:** I-type benzeri, imm kullanılmaz.
  - `PUSH: op=0x1a, rs5, --, --` (rs=push edilecek register)
  - `POP : op=0x1b, --, rt5, --`  (rt=hedef register)
- **Konvansiyon:** SP = `$29`. Başlangıç SP değeri: bellek üst sınırı — örn. `0xFFFC` (memory `2**16` byte). Test programları başlangıçta `loadi $sp, 0xFFFC` ile kurmalı.
- **PUSH cycle akışı (6 cycle):**
  1. IF
  2. ID_X: `a←reg[29]=SP`, `b←reg[rs]`
  3. EX_PUSH: `ffResult ← a-4` (`aluOp=SUB, aluB=4`)
  4. MEM_PUSH: `mem[ffResult] ← b` (`memIn=ALU_RES, memWe=1`)
  5. WB_PUSH: `reg[29] ← ffResult` (`dst=29 sabit, regIn=ALU_RES`)
  6. → IF
- **POP cycle akışı (6 cycle):**
  1. IF
  2. ID_X: `a←reg[29]=SP`
  3. EX_POP: `ffResult ← a` (veya hiç) — adres SP'nin kendisi
  4. MEM_POP: `MDR ← mem[ffResult]`
  5. WB_POP_A: `reg[rt] ← MDR` (`dst=RT, regIn=MDR`)
  6. WB_POP_B: `reg[29] ← a+4` — burada **A hâlâ duruyor, aluA=A, aluB=4, op=ADD** → `ffResult`. Aynı cycle'da hem reg yazma hem ALU işlemi mümkün mü? Hayır — regfile tek-port. **Ayır:** önce SP+4'ü hesapla, sonra rt'ye yaz, sonra SP'ye yaz. Toplam 7 cycle.
- **Donanım etkisi:**
  - `writeAddrMux` 4-way (rd/rt/**rs**/**$29**) — SWAP ile birlikte.
  - `aluBMux`'a "4" zaten var — push/pop SP±4 için kullanılır.

---

## 3. Modül Bazlı Değişiklik Listesi

### 3.1 `cmd` genişliği — 4 → 5 bit

**Şu an:** 12 komut, 4-bit (0..15) sınırda.  
**Yeni:** 12 standart (+JR/JAL = 14) + 6 özel (+ ADDI3, MUL, SWAP, LOADI, BGT, PUSH, POP = 7) → ~21 komut. **5-bit gerek.**

Etkilenen yerler:
- `rtl/decode.v`: `cmd`, `memCmd` `reg [4:0]`.
- `rtl/fsm.v`: input portları, tüm `LW/SW/...` defines (8-bit'e çıkarmaya gerek yok, 5-bit yeterli).
- `rtl/cpu.v`: `wire [3:0] cmd, memCmd` → `[4:0]`.

### 3.2 FSM state genişliği

Şu an `[4:0] state` (`fsm.v:89-90`), 32 değer kapasitesi. Mevcut 20 state + yeni ~15 state ≈ 35. **`[5:0] state` (64 kapasite).**

Yeni state'ler (planlanan, fsm.v defines'e eklenecek):
```
EX_AND, EX_OR, EX_XOR_R, EX_ANDI, EX_ORI, EX_SLTI,
EX_LOADI, EX_BGT, WB_BGT,
EX_ADDI3_1, EX_ADDI3_2, WB_ADDI3,
WB_SWAP1, WB_SWAP2,
EX_MUL, WB_MUL,             // tek-cycle * için
EX_PUSH, MEM_PUSH, WB_PUSH,
EX_POP, MEM_POP, WB_POP_RT, WB_POP_SP
```

### 3.3 Mux genişletmeleri

| Mux | Şu an | Yeni | Neden |
|---|---|---|---|
| `aluAMux` (cpu.v:66) | 2-way (pc/a) | **4-way** (pc/a/ffResult/0) | ADDI3 EX2: ffResult; LOADI alternatifi: sabit 0 |
| `regDInMux` (cpu.v:126) | 2-way (MDR/ALU) | **4-way** (MDR/ALU/A/B) | SWAP iki yön |
| `writeAddrMux` (cpu.v:118) | 2-way (rd/rt) | **4-way** (rd/rt/rs/29) | SWAP, PUSH/POP, ADDI3 (rd alanı farklı bit'lerde) |
| `aluBMux` | 4-way (sxi<<2/sxi/b/4) | aynı kalır, **+1 girdi gerekirse** zxi (and/or-i) | ANDI/ORI için zero-ext |

ANDI/ORI için alternatif: `sxi`'yi olduğu gibi geçir ve **decode'ta opcode'a göre üst 16 biti maskele** — yani ayrı `zxi` çıkışı üret. Yatay büyüme yerine dikey: decode tarafında çöz, mux'u büyütme. **Tercih: decode'ta `zxi` üret, fsm bir `imm16Ext` seç sinyali ile sxi/zxi arasından seçer.** Bu, mux genişletmeden çözer; ayrı 2-way "imm-ext" mux gerekir.

### 3.4 Decode (`rtl/decode.v`)

Eklemeler:
- 5-bit `cmd`/`memCmd` çıkışı.
- Yeni opcodelar: ANDI(0xc), ORI(0xd), SLTI(0xa), LOADI(0x1d), BGT(0x07), ADDI3(0x1e), PUSH(0x1a), POP(0x1b).
- Yeni functlar: AND(0x24), OR(0x25), XOR(0x26), SWAP(0x30), MUL(0x18).
- `zxi = {16'b0, instr[15:0]}` çıkışı.
- ADDI3 için **11-bit sign-ext**: `sxi11 = {{21{instr[10]}}, instr[10:0]}`.
- ADDI3 için rd alanı: `instr[15:11]` zaten 5-bit, ama bu alan imm ile çakışıyorsa **yeniden tahsis** gerek. Format detayı §4'te.

### 3.5 MDR register'ı ekle

`rtl/cpu.v`:
```verilog
reg [31:0] mdr;
always @(posedge clk) if (mdrWe) mdr <= dOut;
```
- `mdrWe` FSM'den gelir, `MEM_LW`/`MEM_POP` state'inde 1.
- `regDInMux` girişi `dOut` yerine `mdr`. (LW WB'sinde MDR oku.)
- LW artık 6 cycle (IF/ID/EX/MEM/MDR_LATCH/WB) yerine **mevcut MEM_LW state'inde mdr de yazılır** → cycle sayısı aynı (5).

### 3.6 ALU

Hiç dokunulmaz (eğer MUL ayrı modülde olursa). Sadece `command` 3-bit kalır. AND/OR/XOR ekleme **şu an mevcut**; sadece FSM'den seçilmiyor.

### 3.7 Yeni modül: `rtl/mul.v` (opsiyonel, MUL iteratif yapılırsa)

```verilog
module mul(
  input clk, input start,
  input [31:0] a, b,
  output reg [31:0] product,
  output reg done
);
  // 32-cycle shift-and-add
endmodule
```

---

## 4. ISA Format Tablosu (son)

```
R-type (op=0):
 [31:26] op=0 | [25:21] rs | [20:16] rt | [15:11] rd | [10:6] shamt | [5:0] funct
   funct: ADD=0x20  SUB=0x22  AND=0x24  OR=0x25  XOR=0x26  SLT=0x2a
          JR=0x08   MUL=0x18  SWAP=0x30

I-type (mevcut + yeni):
 [31:26] op | [25:21] rs | [20:16] rt | [15:0] imm16
   op:   ADDI=0x08 SLTI=0x0a ANDI=0x0c ORI=0x0d XORI=0x0e
         LW=0x23   SW=0x2b   BEQ=0x04  BNE=0x05  BGT=0x07
         LOADI=0x1d  PUSH=0x1a  POP=0x1b

J-type:
 [31:26] op | [25:0] target
   op: J=0x02  JAL=0x03

ADDI3 (özel format):
 [31:26] op=0x1e | [25:21] rs | [20:16] rt | [15:11] rd | [10:0] imm11
```

**Konvansiyonlar:**
- $sp = $29.
- LOADI: `op | 00000 | rd | imm16`. (rs alanı kullanılmaz, rt alanı rd görevi görür — WB'de `dst=RT`.)
- PUSH: `op | rs | 00000 | 0x0000`. (rt/imm kullanılmaz.)
- POP : `op | 00000 | rt | 0x0000`.
- SWAP: R-type ama `rd=0, shamt=0`. `rs` ve `rt` swap edilir.

---

## 5. FSM Geçiş Şeması (genişletilmiş özet)

```
IF ── memCmd ──┬─ BEQ/BNE/BGT → ID_B
               ├─ J/JAL       → ID_J
               └─ diğer       → ID_X

ID_B → EX_BEQ | EX_BNE | EX_BGT → WB_BEQ | WB_BNE | WB_BGT → IF
ID_J → IF (J) | WB_JAL → IF
ID_X (cmd'ye göre dağılır):
  JR     → EX_JR → IF
  SUB    → EX_SUB → WB_SUBADDSLT → IF
  ADD    → EX_ADD → WB_SUBADDSLT → IF
  SLT    → EX_SLT → WB_SUBADDSLT → IF
  AND    → EX_AND → WB_R → IF             [yeni]
  OR     → EX_OR  → WB_R → IF             [yeni]
  XOR    → EX_XOR_R → WB_R → IF           [yeni]
  XORI   → EX_XORI → WB_I → IF
  ADDI   → EX_LWSWADDI → WB_I → IF
  ANDI   → EX_ANDI → WB_I → IF            [yeni]
  ORI    → EX_ORI  → WB_I → IF            [yeni]
  SLTI   → EX_SLTI → WB_I → IF            [yeni]
  LW     → EX_LWSWADDI → MEM_LW → WB_LW → IF
  SW     → EX_LWSWADDI → MEM_SW → IF
  LOADI  → EX_LOADI → WB_I → IF           [yeni]
  ADDI3  → EX_ADDI3_1 → EX_ADDI3_2 → WB_ADDI3 → IF  [yeni]
  SWAP   → WB_SWAP1 → WB_SWAP2 → IF       [yeni]
  MUL    → EX_MUL → WB_MUL → IF           [yeni; iteratifse EX_MUL_WAIT]
  PUSH   → EX_PUSH → MEM_PUSH → WB_PUSH → IF        [yeni]
  POP    → EX_POP  → MEM_POP  → WB_POP_RT → WB_POP_SP → IF  [yeni]
```

**`memCmd` ile branch tespiti:** mevcut tasarım BNE/BEQ'ı `memCmd`'den okuyor (`fsm.v:97`). **BGT'yi de oraya ekle**, yoksa ID_B'ye gitmez.

---

## 6. Assembler (Python)

`tools/asm.py`:
- Girdi: `.asm` (label'lı). Çıktı: `.dat` (byte başına bir hex satır, big-endian — mevcut format `testbench/unit_tests/add.dat`).
- Sözdizimi: standart MIPS + 6 yeni komut + register isimleri ($zero..$ra, $t0..$t9, $s0..$s7, $sp=$29).
- İki geçişli: 1. geçiş label tablosu, 2. geçiş encoding.
- PC göreli branch: `(label - (PC+4)) >> 2`.
- Direktif: `.org N` (PC'yi N byte'a kur), `.word V` (32-bit data).
- Kullanım: `python tools/asm.py prog.asm prog.dat`.

---

## 7. Test ve Doğrulama Planı

### 7.1 Birim testleri
- `testbench/alu/` Verilator testi Linux için var — Windows'ta atlanır. ModelSim için **`alu_tb.v`** Verilog testbenchi yazılacak (overflow/zero/negatif/sınır).
- `testbench/regfile/` aynı şekilde.

### 7.2 Komut testleri (her komut için ayrı `.dat`)
- Var: add, sub, slt, addi, xori, lw_sw, beq, bne, j, jal, jr, nsum2.
- **Yazılacak**: and, or, xor, andi, ori, slti, loadi, bgt, addi3, swap, mul, push, pop.
- Her test sonu: `$v0` ($2) içine beklenen sonuç yazılır, `cpu.t.v` mevcut `$display("Contents of v0: %d", ...)` ile teyit edilir.

### 7.3 Program testleri
- **nsum2** zaten var (1..15 toplamı).
- **factorial**: MUL kullanır (özyinelemeli değil iteratif).
- **stack-reverse**: PUSH/POP ile bir diziyi tersine çevir.
- **swap-sort**: SWAP + ADDI3 + BGT (bubble sort 5 eleman).

### 7.4 Coverage
- ModelSim'de `coverage save` ile state coverage. Tüm FSM state'leri girilmiş mi raporu.
- Sınır durumları: overflow (`add 0x7FFFFFFF + 1`), branch alanı sınırı, mem sınırı (`lw 0xFFFC`).

### 7.5 Otomasyon
- `tools/run_all_tests.do` ModelSim TCL: her `.dat` için restart+run+sonuç karşılaştırma.

---

## 8. Risk ve Sıralama

### 8.1 İş sırası (önerilen)
1. **Eksik standartlar** (and/or/xor/andi/ori/slti): warm-up, 1 günde biter.
2. **MDR ekle**, mux'ları genişlet, `cmd` 5-bit yap: altyapı refaktör. 1 gün.
3. **LOADI**, **BGT**: kolay yeni komutlar. 0.5 gün.
4. **ADDI3**: 2-aşamalı ALU + format. 1 gün.
5. **SWAP**: 2-cycle WB. 0.5 gün.
6. **MUL** (tek-cycle `*` ile başla). 0.5 gün.
7. **PUSH/POP**: en karmaşık, en sonda. 1 gün.
8. **Assembler** paralel yürür (Python tarafı). 1.5 gün.
9. **Test + coverage + rapor**. 2 gün.

Toplam: ~9 iş günü. Deadline'a ~17 gün var → tampon var.

### 8.2 Riskler
- **memCmd hilesi** (`fsm.v:97`): yeni branch (BGT) eklerken **memCmd path'i kırılırsa** ID_B'ye gitmez, FSM çöker. Birim testle erken yakala.
- **regfile tek-port**: SWAP/POP için kaçınılmaz olarak 2-cycle WB. Cycle bütçesini şişiriyor; rapor için "tasarım kararı" diye yazılmalı.
- **Custom opcode çakışması**: 0x1a/0x1b/0x1d/0x1e gerçek MIPS'te de kullanılmıyor — temiz.
- **PDF'in VHDL beklentisi**: Hocaya sorulup teyit edilecek; Verilog kabul edilmezse port işi günler alır.

---

## 9. Çıktı Klasör Yapısı

```
docs/
  project-plan.md         (bu doküman)
  technical-report.md     (final rapor — yazılacak)
  fsm-diagram.png         (yazılacak)
  datapath-diagram.png    (yazılacak)
rtl/
  cpu.v decode.v fsm.v alu.v regfile.v memory.v mux.v mux4way.v
  mul.v                   (opsiyonel — iteratif MUL için)
testbench/
  cpu.t.v                 (instruction parametresini değiştirerek tüm testler)
  alu_tb.v                (ModelSim için Verilog ALU testi — yazılacak)
  regfile_tb.v            (yazılacak)
  unit_tests/             (mevcut + 13 yeni .dat)
  programs/               (factorial.asm, stack-reverse.asm, swap-sort.asm)
tools/
  asm.py                  (assembler)
  run_all_tests.do        (ModelSim batch)
```

---

## 10. Açık Sorular (hocadan/ekipten teyit)

1. **Verilog kabul mü?** PDF "VHDL kodları" diyor; Verilog/VHDL dual kabulü beklentisi muhtemel ama yazılı teyit iyi olur.
2. **ADDI3 imm bit genişliği** PDF'te belirtilmemiş — biz 11-bit seçtik. Hoca daha geniş isterse format değişir.
3. **MUL HI/LO** mı yoksa **tek 32-bit rd**'ye mi? PDF "rd, rs, rt" formatı veriyor → biz tek rd seçtik. Gerçek MIPS `mult` HI/LO kullanır; rapor not düşülecek.
4. **PUSH/POP başlangıç SP'si** — uzlaşı: `0xFFFC`. Test programları başında `loadi $sp, 0xFFFC` çağırılacak.
