#!/usr/bin/env python3
"""
MIPS Assembler - multicycle-mips projesi icin
Kullanim:
    python assembler.py input.asm          -> input.dat olusturur
    python assembler.py input.asm out.dat  -> belirtilen dosyaya yazar
"""

import sys
import re

# ── Register tablosu ─────────────────────────────────────────────────────────
REGS = {
    '$zero': 0, '$0': 0,
    '$at': 1,
    '$v0': 2,  '$v1': 3,
    '$a0': 4,  '$a1': 5,  '$a2': 6,  '$a3': 7,
    '$t0': 8,  '$t1': 9,  '$t2': 10, '$t3': 11,
    '$t4': 12, '$t5': 13, '$t6': 14, '$t7': 15,
    '$s0': 16, '$s1': 17, '$s2': 18, '$s3': 19,
    '$s4': 20, '$s5': 21, '$s6': 22, '$s7': 23,
    '$t8': 24, '$t9': 25,
    '$k0': 26, '$k1': 27,
    '$gp': 28, '$sp': 29, '$fp': 30, '$ra': 31,
}

# ── Yardimci fonksiyonlar ─────────────────────────────────────────────────────
def reg(name):
    name = name.strip().strip(',')
    if name in REGS:
        return REGS[name]
    raise ValueError(f"Bilinmeyen register: '{name}'")

def parse_imm(val, bits=16):
    val = val.strip().strip(',')
    n = int(val, 0)          # 0x... veya decimal destekler
    if n < 0:
        n = n & ((1 << bits) - 1)   # two's complement
    return n & ((1 << bits) - 1)

def r_type(rs, rt, rd, shamt=0, funct=0):
    return (0 << 26) | (rs << 21) | (rt << 16) | (rd << 11) | (shamt << 6) | funct

def i_type(opcode, rs, rt, imm16):
    return (opcode << 26) | (rs << 21) | (rt << 16) | (imm16 & 0xFFFF)

def j_type(opcode, target26):
    return (opcode << 26) | (target26 & 0x3FFFFFF)

def word_to_bytes(word):
    return [(word >> 24) & 0xFF,
            (word >> 16) & 0xFF,
            (word >>  8) & 0xFF,
             word        & 0xFF]

# ── 1. Gecis: label adresleri topla ──────────────────────────────────────────
def first_pass(lines):
    labels = {}
    instructions = []
    pc = 0

    for lineno, line in enumerate(lines, 1):
        line = line.split('#')[0].strip()   # yorumlari kaldir
        if not line:
            continue

        if ':' in line:
            label, rest = line.split(':', 1)
            labels[label.strip()] = pc
            line = rest.strip()
            if not line:
                continue

        tokens = [t for t in re.split(r'[\s,()]+', line) if t]
        instructions.append((lineno, pc, tokens))
        pc += 4

    return labels, instructions

# ── 2. Gecis: makine kodu uret ────────────────────────────────────────────────
def encode(op, args, pc, labels, lineno):
    def branch_off(target):
        if target in labels:
            return ((labels[target] - (pc + 4)) // 4) & 0xFFFF
        return parse_imm(target)

    def jump_tgt(target):
        if target in labels:
            return labels[target] >> 2
        return int(target, 0) >> 2

    def lw_sw_args(args):
        """lw/sw icin: 'rt, imm(rs)' veya 'rt, imm' formatlarini isle"""
        rt_r = reg(args[0])
        if len(args) == 3:
            return rt_r, parse_imm(args[1]), reg(args[2])
        return rt_r, parse_imm(args[1]), 0   # rs = $zero

    try:
        op = op.lower()

        # ── R-type ──────────────────────────────────────────────────────────
        if   op == 'add':  rd,rs,rt = reg(args[0]),reg(args[1]),reg(args[2]); return r_type(rs,rt,rd,funct=0x20)
        elif op == 'sub':  rd,rs,rt = reg(args[0]),reg(args[1]),reg(args[2]); return r_type(rs,rt,rd,funct=0x22)
        elif op == 'and':  rd,rs,rt = reg(args[0]),reg(args[1]),reg(args[2]); return r_type(rs,rt,rd,funct=0x24)
        elif op == 'or':   rd,rs,rt = reg(args[0]),reg(args[1]),reg(args[2]); return r_type(rs,rt,rd,funct=0x25)
        elif op == 'xor':  rd,rs,rt = reg(args[0]),reg(args[1]),reg(args[2]); return r_type(rs,rt,rd,funct=0x26)
        elif op == 'slt':  rd,rs,rt = reg(args[0]),reg(args[1]),reg(args[2]); return r_type(rs,rt,rd,funct=0x2a)
        elif op == 'jr':   return r_type(reg(args[0]),0,0,funct=0x08)

        # ── I-type ──────────────────────────────────────────────────────────
        elif op == 'addi': return i_type(0x08, reg(args[1]), reg(args[0]), parse_imm(args[2]))
        elif op == 'slti': return i_type(0x0a, reg(args[1]), reg(args[0]), parse_imm(args[2]))
        elif op == 'andi': return i_type(0x0c, reg(args[1]), reg(args[0]), parse_imm(args[2]))
        elif op == 'ori':  return i_type(0x0d, reg(args[1]), reg(args[0]), parse_imm(args[2]))
        elif op == 'xori': return i_type(0x0e, reg(args[1]), reg(args[0]), parse_imm(args[2]))
        elif op == 'lw':   rt_r,off,rs_r = lw_sw_args(args); return i_type(0x23, rs_r, rt_r, off)
        elif op == 'sw':   rt_r,off,rs_r = lw_sw_args(args); return i_type(0x2b, rs_r, rt_r, off)
        elif op == 'beq':  return i_type(0x04, reg(args[0]), reg(args[1]), branch_off(args[2]))
        elif op == 'bne':  return i_type(0x05, reg(args[0]), reg(args[1]), branch_off(args[2]))

        # ── J-type ──────────────────────────────────────────────────────────
        elif op == 'j':    return j_type(0x02, jump_tgt(args[0]))
        elif op == 'jal':  return j_type(0x03, jump_tgt(args[0]))

        # ── Genisletilmis komut seti ─────────────────────────────────────────
        elif op == 'loadi':
            # loadi rd, imm  -> op=0x1d, rs=0, rt=rd, imm16
            return i_type(0x1d, 0, reg(args[0]), parse_imm(args[1]))

        elif op == 'bgt':
            # bgt rs, rt, label  -> op=0x07, rs, rt, branch_off
            return i_type(0x07, reg(args[0]), reg(args[1]), branch_off(args[2]))

        elif op == 'addi3':
            # addi3 rd, rs, rt, imm11  -> op=0x1e | rs5 | rt5 | rd5 | imm11
            rd_r = reg(args[0]); rs_r = reg(args[1]); rt_r = reg(args[2])
            imm = parse_imm(args[3], bits=11)
            return (0x1e << 26) | (rs_r << 21) | (rt_r << 16) | (rd_r << 11) | (imm & 0x7FF)

        elif op == 'swap':
            # swap rs, rt  -> R-type funct=0x30, rd=0
            return r_type(reg(args[0]), reg(args[1]), 0, funct=0x30)

        elif op == 'mul':
            # mul rd, rs, rt  -> R-type funct=0x18
            rd_r,rs_r,rt_r = reg(args[0]), reg(args[1]), reg(args[2])
            return r_type(rs_r, rt_r, rd_r, funct=0x18)

        elif op == 'push':
            # push rs  -> op=0x1a, rs_field=$sp (29), rt_field=pushed reg, imm=0
            # ID_X: a<-reg[29]=SP, b<-reg[rs]
            return i_type(0x1a, 29, reg(args[0]), 0)

        elif op == 'pop':
            # pop rd   -> op=0x1b, rs_field=$sp (29), rt_field=dest reg, imm=0
            # ID_X: a<-reg[29]=SP; WB writes reg[rt_field]
            return i_type(0x1b, 29, reg(args[0]), 0)

        else:
            raise ValueError(f"Bilinmeyen komut: '{op}'")

    except ValueError:
        raise
    except Exception as e:
        raise ValueError(f"Satir {lineno}: {e}")

def assemble(lines):
    labels, instructions = first_pass(lines)
    machine_code = []
    for lineno, pc, tokens in instructions:
        word = encode(tokens[0], tokens[1:], pc, labels, lineno)
        machine_code.append(word)
    return machine_code

# ── Cikti ──────────────────────────────────────────────────────────────────
def write_dat(machine_code, output_file):
    with open(output_file, 'w') as f:
        for word in machine_code:
            for byte in word_to_bytes(word):
                f.write(f'{byte:02x}\n')

def main():
    if len(sys.argv) < 2:
        print("Kullanim: python assembler.py <input.asm> [output.dat]")
        sys.exit(1)

    input_file  = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file.replace('.asm', '.dat')

    with open(input_file, 'r') as f:
        lines = f.readlines()

    try:
        machine_code = assemble(lines)
    except ValueError as e:
        print(f"HATA: {e}")
        sys.exit(1)

    write_dat(machine_code, output_file)

    print(f"Derlendi: {len(machine_code)} komut  ->  {output_file}")
    print("\nMakine kodu (hex):")
    for i, word in enumerate(machine_code):
        bs = word_to_bytes(word)
        print(f"  [{i*4:04x}]  {bs[0]:02x} {bs[1]:02x} {bs[2]:02x} {bs[3]:02x}  =  0x{word:08x}")

if __name__ == '__main__':
    main()
