#!/usr/bin/env python3
"""
vcd_to_wave.py — Render selected signals from a ModelSim VCD as a digital
timing-diagram PNG (headless, no GUI needed).

Usage:
    python vcd_to_wave.py <cpu.vcd> <out.png> --title "..." [--end PS]

Handles both whole-vector regs (e.g. `pc [31:0]`) and bit-blasted wires
(e.g. `result [31]`, `result [30]`, ...). FSM `state` values are annotated
with their symbolic names so the control flow is readable.

Tailored to the multicycle-MIPS testbench hierarchy (cputest.dut.fsm0).
"""
import sys, re, argparse
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon

# FSM state number -> name (from rtl/fsm.v / report section 5)
STATE_NAMES = {
    0: "IF", 1: "ID_B", 2: "ID_J", 3: "ID_X", 4: "EX_BEQ", 5: "EX_BNE",
    6: "EX_JR", 7: "EX_SUB", 8: "EX_ADD", 9: "EX_SLT", 10: "EX_XORI",
    11: "EX_LWSWADDI", 12: "MEM_LW", 13: "MEM_SW", 14: "WB_JAL",
    15: "WB_SUBADDSLT", 16: "WB_ADDIXORI", 17: "WB_LW", 18: "WB_BEQ",
    19: "WB_BNE", 20: "EX_AND", 21: "EX_OR", 22: "EX_XOR_R", 23: "EX_ANDI",
    24: "EX_ORI", 25: "EX_SLTI", 26: "WB_R_LOGIC", 27: "WB_I_LOGIC",
    28: "EX_BGT", 29: "WB_BGT", 30: "EX_ADDI3_1", 31: "EX_ADDI3_2",
    32: "WB_ADDI3", 33: "WB_SWAP1", 34: "WB_SWAP2", 35: "EX_MUL",
    36: "EX_PUSH", 37: "MEM_PUSH", 38: "WB_PUSH_SP", 39: "MEM_POP",
    40: "WB_POP_RT", 41: "WB_POP_SP",
}

# Signals to display, in order: (vcd-path-suffix, label, kind)
#   kind: "clk" | "bit" | "bus" | "state"
SIGNALS = [
    ("cputest.clk",            "clk",       "clk"),
    ("dut.fsm0.state",         "state",     "state"),
    ("dut.pc",                 "pc",        "bus"),
    ("dut.ir",                 "ir",        "bus"),
    ("dut.a",                  "A",         "bus"),
    ("dut.b",                  "B",         "bus"),
    ("dut.ffResult",           "ALUOut",    "bus"),
    ("dut.result",             "result",    "bus"),
    ("dut.fsm0.pcWe",          "pcWe",      "bit"),
    ("dut.fsm0.irWe",          "irWe",      "bit"),
    ("dut.fsm0.regWe",         "regWe",     "bit"),
    ("dut.fsm0.memWe",         "memWe",     "bit"),
    ("dut.fsm0.aluResWe",      "aluResWe",  "bit"),
]


def parse_vcd(path):
    """Return (changes, end_time). changes[id] = list of (time, value_str)."""
    scope = []
    vectors = {}     # fullpath -> id
    scalars = {}     # fullpath -> id
    bitblast = {}    # fullpath -> {bit_index: id}
    with open(path, "r", errors="replace") as f:
        text = f.read()

    # --- header: parse $var declarations with scope tracking ---
    header, _, body = text.partition("$enddefinitions")
    for line in header.splitlines():
        line = line.strip()
        if line.startswith("$scope"):
            scope.append(line.split()[2])
        elif line.startswith("$upscope"):
            if scope:
                scope.pop()
        elif line.startswith("$var"):
            toks = line.split()
            # $var <type> <size> <id> <name> [bitrange] $end
            size = int(toks[2]); vid = toks[3]; name = toks[4]
            bitrange = toks[5] if toks[5] != "$end" else None
            full = ".".join(scope + [name])
            if bitrange and re.match(r"^\[\d+\]$", bitrange):
                idx = int(bitrange[1:-1])
                bitblast.setdefault(full, {})[idx] = vid
            elif size > 1:
                vectors[full] = vid
            else:
                scalars[full] = vid

    # --- body: collect value changes per id ---
    changes = {}       # id -> [(t, val)]
    t = 0
    end_time = 0
    for line in body.splitlines():
        line = line.strip()
        if not line:
            continue
        if line[0] == "#":
            t = int(line[1:]); end_time = max(end_time, t)
        elif line[0] in "01xz":
            vid = line[1:]
            changes.setdefault(vid, []).append((t, line[0]))
        elif line[0] in "bB":
            val, _, vid = line[1:].partition(" ")
            changes.setdefault(vid, []).append((t, val))
    return changes, end_time, vectors, scalars, bitblast


def find_path(suffix, *maps):
    for m in maps:
        if suffix in m:
            return ("exact", m[suffix])
        for full in m:
            if full.endswith("." + suffix) or full == suffix:
                return (full, m[full])
    return (None, None)


def bus_value_series(changes, vid):
    """Whole-vector: list of (t, intval)."""
    out = []
    for t, v in changes.get(vid, []):
        if any(c in "xz" for c in v):
            out.append((t, None))
        else:
            out.append((t, int(v, 2)))
    return out


def bitblast_series(changes, bits, width):
    """Reconstruct bus value over time from individual bit changes."""
    cur = {i: 0 for i in range(width)}
    events = []
    for idx, vid in bits.items():
        for t, v in changes.get(vid, []):
            events.append((t, idx, v))
    events.sort()
    out = []
    last_t = None
    for t, idx, v in events:
        cur[idx] = 0 if v in "xz" else int(v)
        if last_t is not None and t != last_t:
            val = sum(cur[i] << i for i in range(width))
            out.append((last_t, val))
        last_t = t
    if last_t is not None:
        out.append((last_t, sum(cur[i] << i for i in range(width))))
    # dedup consecutive equal values
    dd = []
    for t, val in out:
        if not dd or dd[-1][1] != val:
            dd.append((t, val))
    return dd


def step_changes(series, start, end):
    """series [(t,val)] -> segment list [(t0, t1, val)] clipped to [start, end]."""
    segs = []
    for i, (t, val) in enumerate(series):
        t1 = series[i + 1][0] if i + 1 < len(series) else end
        if t1 <= start or t >= end:
            continue
        segs.append((max(t, start), min(t1, end), val))
    return segs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vcd")
    ap.add_argument("out")
    ap.add_argument("--title", default="")
    ap.add_argument("--start", type=int, default=0, help="start time (ps)")
    ap.add_argument("--end", type=int, default=None, help="end time (ps)")
    args = ap.parse_args()

    changes, end_time, vectors, scalars, bitblast = parse_vcd(args.vcd)
    end = args.end if args.end else end_time
    start = args.start

    rows = []
    for suffix, label, kind in SIGNALS:
        if kind in ("bus", "state"):
            _, vid = find_path(suffix, vectors)
            if vid:
                series = bus_value_series(changes, vid)
            else:
                # try bit-blasted
                fp, bits = find_path(suffix, bitblast)
                if not bits:
                    continue
                width = max(bits) + 1
                series = bitblast_series(changes, bits, width)
            rows.append((label, kind, series))
        else:
            _, vid = find_path(suffix, scalars)
            if not vid:
                continue
            series = [(t, int(v) if v in "01" else 0) for t, v in changes.get(vid, [])]
            rows.append((label, kind, series))

    n = len(rows)
    span = end - start
    fig, ax = plt.subplots(figsize=(14, 0.55 * n + 1.2))
    ax.set_xlim(start, end)
    ax.set_ylim(-0.5, n - 0.5)
    ax.set_yticks(range(n))
    ax.set_yticklabels([r[0] for r in reversed(rows)], fontfamily="monospace", fontsize=9)
    ax.set_xlabel("simülasyon zamanı (ps)")
    if args.title:
        ax.set_title(args.title, fontsize=11, fontweight="bold")
    ax.grid(True, axis="x", linestyle=":", alpha=0.35)

    H = 0.34  # half-height of a signal band
    for ri, (label, kind, series) in enumerate(rows):
        y = n - 1 - ri
        segs = step_changes(series, start, end)
        if kind == "clk":
            # draw clock as square wave from transitions
            xs, ys = [], []
            for (t0, t1, val) in segs:
                xs += [t0, t1]
                lvl = y - H if val == 0 else y + H
                ys += [lvl, lvl]
            ax.plot(xs, ys, color="#1f77b4", linewidth=0.8, drawstyle="steps-post")
        elif kind == "bit":
            xs, ys = [], []
            for (t0, t1, val) in segs:
                lvl = y - H if val == 0 else y + H
                xs += [t0, t1]; ys += [lvl, lvl]
            ax.plot(xs, ys, color="#2ca02c", linewidth=1.1, drawstyle="steps-post")
            for (t0, t1, val) in segs:
                if val:
                    ax.axvspan(t0, t1, ymin=(y - H + 0.5) / n, ymax=(y + H + 0.5) / n,
                               color="#2ca02c", alpha=0.08)
        else:  # bus / state
            for (t0, t1, val) in segs:
                if t1 <= t0:
                    continue
                color = "#fff2cc" if kind == "state" else "#eef3fb"
                edge = "#d6b656" if kind == "state" else "#9bb7d4"
                bevel = min((t1 - t0) * 0.15, span * 0.004)
                poly = Polygon([(t0 + bevel, y + H), (t1 - bevel, y + H),
                                (t1, y), (t1 - bevel, y - H),
                                (t0 + bevel, y - H), (t0, y)],
                               closed=True, facecolor=color, edgecolor=edge, linewidth=0.7)
                ax.add_patch(poly)
                if val is None:
                    txt = "x"
                elif kind == "state":
                    txt = STATE_NAMES.get(val, str(val))
                else:
                    txt = f"{val:X}"
                if (t1 - t0) > span * 0.012:
                    ax.text((t0 + t1) / 2, y, txt, ha="center", va="center",
                            fontsize=6.5, fontfamily="monospace")

    ax.set_xlim(start, end)
    plt.tight_layout()
    plt.savefig(args.out, dpi=140, bbox_inches="tight")
    print(f"wrote {args.out}  ({n} signals, end={end} ps)")


if __name__ == "__main__":
    main()
