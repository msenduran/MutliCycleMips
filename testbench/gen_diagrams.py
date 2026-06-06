#!/usr/bin/env python3
"""
gen_diagrams.py — Generate the report's FSM state-transition diagram and the
multi-cycle datapath block diagram as PNGs (docs/img/), using matplotlib
(+ networkx for FSM layering). No external tools (Graphviz) required.

Run from testbench/:  python gen_diagrams.py
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import networkx as nx

OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "img")

# ---- FSM: states grouped by multi-cycle stage (layer) --------------------
LAYER = {  # state -> stage column
    "IF": 0,
    "ID_X": 1, "ID_B": 1, "ID_J": 1,
    "EX_ADD": 2, "EX_SUB": 2, "EX_SLT": 2, "EX_AND": 2, "EX_OR": 2,
    "EX_XOR_R": 2, "EX_MUL": 2, "EX_XORI": 2, "EX_ANDI": 2, "EX_ORI": 2,
    "EX_SLTI": 2, "EX_LWSWADDI": 2, "EX_JR": 2, "EX_BEQ": 2, "EX_BNE": 2,
    "EX_BGT": 2, "EX_ADDI3_1": 2, "EX_ADDI3_2": 2, "EX_PUSH": 2,
    "MEM_LW": 3, "MEM_SW": 3, "MEM_PUSH": 3, "MEM_POP": 3,
    "WB_SUBADDSLT": 4, "WB_R_LOGIC": 4, "WB_ADDIXORI": 4, "WB_I_LOGIC": 4,
    "WB_LW": 4, "WB_BEQ": 4, "WB_BNE": 4, "WB_BGT": 4, "WB_ADDI3": 4,
    "WB_SWAP1": 4, "WB_SWAP2": 4, "WB_PUSH_SP": 4, "WB_POP_RT": 4,
    "WB_POP_SP": 4, "WB_JAL": 4,
}

# Forward transitions (derived from report section 5.1 / fsm.v flows)
EDGES = [
    ("IF", "ID_X"), ("IF", "ID_B"), ("IF", "ID_J"),
    ("ID_B", "EX_BEQ"), ("ID_B", "EX_BNE"), ("ID_B", "EX_BGT"),
    # ID_X fan-out
    ("ID_X", "EX_ADD"), ("ID_X", "EX_SUB"), ("ID_X", "EX_SLT"),
    ("ID_X", "EX_AND"), ("ID_X", "EX_OR"), ("ID_X", "EX_XOR_R"),
    ("ID_X", "EX_MUL"), ("ID_X", "EX_XORI"), ("ID_X", "EX_ANDI"),
    ("ID_X", "EX_ORI"), ("ID_X", "EX_SLTI"), ("ID_X", "EX_LWSWADDI"),
    ("ID_X", "EX_JR"), ("ID_X", "EX_ADDI3_1"), ("ID_X", "EX_PUSH"),
    ("ID_X", "WB_SWAP1"), ("ID_X", "MEM_POP"),
    # EX -> next
    ("EX_LWSWADDI", "WB_ADDIXORI"), ("EX_LWSWADDI", "MEM_LW"),
    ("EX_LWSWADDI", "MEM_SW"),
    ("EX_ADD", "WB_SUBADDSLT"), ("EX_SUB", "WB_SUBADDSLT"),
    ("EX_SLT", "WB_SUBADDSLT"), ("EX_MUL", "WB_SUBADDSLT"),
    ("EX_AND", "WB_R_LOGIC"), ("EX_OR", "WB_R_LOGIC"),
    ("EX_XOR_R", "WB_R_LOGIC"),
    ("EX_XORI", "WB_ADDIXORI"),
    ("EX_ANDI", "WB_I_LOGIC"), ("EX_ORI", "WB_I_LOGIC"),
    ("EX_SLTI", "WB_I_LOGIC"),
    ("EX_BEQ", "WB_BEQ"), ("EX_BNE", "WB_BNE"), ("EX_BGT", "WB_BGT"),
    ("EX_ADDI3_1", "EX_ADDI3_2"), ("EX_ADDI3_2", "WB_ADDI3"),
    ("EX_PUSH", "MEM_PUSH"), ("MEM_PUSH", "WB_PUSH_SP"),
    ("MEM_LW", "WB_LW"),
    ("MEM_POP", "WB_POP_RT"), ("WB_POP_RT", "WB_POP_SP"),
    ("WB_SWAP1", "WB_SWAP2"),
]
# Transitions that return to IF (drawn faintly)
RETURN = ["ID_J", "EX_JR", "MEM_SW", "WB_SUBADDSLT", "WB_R_LOGIC",
          "WB_ADDIXORI", "WB_I_LOGIC", "WB_LW", "WB_BEQ", "WB_BNE",
          "WB_BGT", "WB_ADDI3", "WB_SWAP2", "WB_PUSH_SP", "WB_POP_SP"]

LAYER_COLOR = {0: "#cfe2f3", 1: "#d9ead3", 2: "#fce5cd",
               3: "#e6d4ec", 4: "#fff2cc"}
LAYER_NAME = {0: "IF (Fetch)", 1: "ID (Decode)", 2: "EX (Execute)",
              3: "MEM (Memory)", 4: "WB (Write-Back)"}


def fsm_diagram():
    G = nx.DiGraph()
    for s, l in LAYER.items():
        G.add_node(s, layer=l)
    G.add_edges_from(EDGES)
    pos = nx.multipartite_layout(G, subset_key="layer", align="vertical")
    # spread columns wider, scale y
    xs = sorted(set(round(p[0], 4) for p in pos.values()))
    xmap = {x: i * 4.0 for i, x in enumerate(xs)}
    pos = {n: (xmap[round(p[0], 4)], p[1] * 26) for n, p in pos.items()}

    fig, ax = plt.subplots(figsize=(17, 13))
    # column headers
    for l, x in zip(sorted(LAYER_NAME), sorted(set(p[0] for p in pos.values()))):
        ax.text(x, max(p[1] for p in pos.values()) + 1.4, LAYER_NAME[l],
                ha="center", va="bottom", fontsize=13, fontweight="bold",
                color="#333")

    w, h = 1.7, 0.62
    def draw_node(n):
        x, y = pos[n]
        unreachable = (n == "WB_JAL")
        fc = "#dddddd" if unreachable else LAYER_COLOR[LAYER[n]]
        ec = "#999999" if unreachable else "#555555"
        box = FancyBboxPatch((x - w / 2, y - h / 2), w, h,
                             boxstyle="round,pad=0.02,rounding_size=0.12",
                             linewidth=1.0, edgecolor=ec, facecolor=fc,
                             linestyle="--" if unreachable else "-", zorder=3)
        ax.add_patch(box)
        label = n + "\n(ulaşılmıyor)" if unreachable else n
        ax.text(x, y, label, ha="center", va="center", fontsize=7.2,
                fontfamily="monospace", zorder=4)

    for n in G.nodes:
        draw_node(n)

    def arrow(a, b, color, rad, lw, ls="-", z=2, alpha=1.0):
        xa, ya = pos[a]; xb, yb = pos[b]
        ar = FancyArrowPatch((xa, ya), (xb, yb),
                             connectionstyle=f"arc3,rad={rad}",
                             arrowstyle="-|>", mutation_scale=10,
                             linewidth=lw, color=color, linestyle=ls,
                             alpha=alpha, zorder=z,
                             shrinkA=w * 17, shrinkB=w * 17)
        ax.add_patch(ar)

    for a, b in EDGES:
        same = LAYER[a] == LAYER[b]
        arrow(a, b, "#3a6ea5", 0.12 if same else 0.04, 1.0)
    # return-to-IF edges, faint and curved over the top
    for a in RETURN:
        arrow(a, "IF", "#bbbbbb", -0.32, 0.7, ls=(0, (4, 3)), z=1, alpha=0.8)

    ax.text(pos["IF"][0], min(p[1] for p in pos.values()) - 1.6,
            "Gri kesikli oklar: komut tamamlandıktan sonra IF'e dönüş",
            ha="left", va="top", fontsize=9, color="#777", style="italic")

    ax.set_title("Multi-Cycle MIPS — 42-State FSM Durum Geçiş Diyagramı",
                 fontsize=15, fontweight="bold")
    ax.set_xlim(-2.5, max(p[0] for p in pos.values()) + 2.5)
    ax.set_ylim(min(p[1] for p in pos.values()) - 2.5,
                max(p[1] for p in pos.values()) + 2.5)
    ax.axis("off")
    plt.tight_layout()
    out = os.path.join(OUT, "fsm_diagram.png")
    plt.savefig(out, dpi=150, bbox_inches="tight")
    print("wrote", out)
    plt.close(fig)


# ---- Datapath block diagram ---------------------------------------------
def datapath_diagram():
    fig, ax = plt.subplots(figsize=(18, 9))

    def box(x, y, w, h, text, fc="#eef3fb", ec="#3a6ea5", fs=9, bold=False):
        ax.add_patch(FancyBboxPatch((x - w / 2, y - h / 2), w, h,
                     boxstyle="round,pad=0.02,rounding_size=0.08",
                     linewidth=1.3, edgecolor=ec, facecolor=fc, zorder=3))
        ax.text(x, y, text, ha="center", va="center", fontsize=fs,
                fontweight="bold" if bold else "normal", zorder=4)
        return (x, y, w, h)

    def mux(x, y, h, text, fc="#fff2cc"):
        # trapezoid (narrow output on the right)
        w = 0.7
        pts = [(x - w / 2, y + h / 2), (x + w / 2, y + h / 2 - 0.18),
               (x + w / 2, y - h / 2 + 0.18), (x - w / 2, y - h / 2)]
        ax.add_patch(plt.Polygon(pts, closed=True, facecolor=fc,
                     edgecolor="#bf9000", linewidth=1.2, zorder=3))
        ax.text(x, y, text, ha="center", va="center", fontsize=7.2, zorder=4)
        return (x, y, w, h)

    def ar(p, q, color="#3a6ea5", lw=1.4, rad=0.0, ls="-", label=None,
           lx=0, ly=0.25):
        ax.add_patch(FancyArrowPatch(p, q, connectionstyle=f"arc3,rad={rad}",
                     arrowstyle="-|>", mutation_scale=13, linewidth=lw,
                     color=color, linestyle=ls, zorder=2))
        if label:
            mx, my = (p[0] + q[0]) / 2 + lx, (p[1] + q[1]) / 2 + ly
            ax.text(mx, my, label, fontsize=7, color=color, ha="center",
                    style="italic", zorder=5)

    # --- main row (y=0) ---
    PC   = box(1.0, 0.0, 1.1, 0.9, "PC", "#cfe2f3", "#2e6da4", 11, True)
    MAM  = mux(3.0, 0.0, 1.7, "memAddr\nMux 4w")
    MEM  = box(5.2, 0.0, 1.5, 2.4, "Memory\n(Unified\nI + D)\n64 KiB",
               "#e6d4ec", "#7e57c2", 9, True)
    IR   = box(7.6, 0.9, 1.2, 0.8, "IR", "#cfe2f3", "#2e6da4", 10, True)
    MDR  = box(7.6, -1.0, 1.2, 0.8, "MDR", "#cfe2f3", "#2e6da4", 10, True)
    DEC  = box(9.9, 0.9, 1.4, 1.6, "Decode\nrs rt rd\nsxi/zxi\nsxi11 jAddr",
               "#d9ead3", "#6aa84f", 8)
    RF   = box(12.3, 0.0, 1.5, 2.2, "Register\nFile\n32x32\n($zero=0)",
               "#d9ead3", "#6aa84f", 9, True)
    A    = box(14.4, 0.8, 1.0, 0.7, "A", "#cfe2f3", "#2e6da4", 10, True)
    B    = box(14.4, -0.8, 1.0, 0.7, "B", "#cfe2f3", "#2e6da4", 10, True)
    AAM  = mux(16.1, 0.8, 1.3, "aluA\nMux")
    ABM  = mux(16.1, -0.8, 1.3, "aluB\nMux")
    ALU  = box(18.0, 0.0, 1.4, 2.0, "ALU\n9 op\n(4-bit cmd)",
               "#fce5cd", "#e69138", 9, True)
    FF   = box(20.3, 0.0, 1.3, 0.9, "ALUOut\n(ffResult)", "#cfe2f3", "#2e6da4", 9, True)

    # feedback muxes
    PCM  = mux(3.0, 2.6, 1.7, "pc Mux 4w")
    RDM  = mux(12.3, -2.7, 1.7, "regDIn Mux 4w")
    IMM  = box(13.0, -1.7, 1.5, 0.6, "immMux: sxi/zxi/sxi11/0", "#fff2cc", "#bf9000", 7)

    # --- main dataflow arrows ---
    def right(a): return (a[0] + a[2] / 2, a[1])
    def left(a):  return (a[0] - a[2] / 2, a[1])
    def top(a):   return (a[0], a[1] + a[3] / 2)
    def bot(a):   return (a[0], a[1] - a[3] / 2)

    ar(right(PC), left(MAM), label="PC")
    ar(right(MAM), left(MEM), label="addr")
    ar(right(MEM), left(IR), label="dOut", ly=0.3)
    ar(right(MEM), left(MDR), rad=-0.0, color="#7e57c2", label="dOut")
    ar(right(IR), left(DEC))
    ar(right(DEC), (RF[0], RF[1] + 0.5), label="rs/rt/rd")
    ar(bot(DEC), (IMM[0], IMM[1] + 0.3), color="#bf9000", rad=-0.2)
    ar(right(RF), left(A), label="dOut0", ly=0.28)
    ar(right(RF), left(B), label="dOut1", ly=-0.3)
    ar(right(A), left(AAM))
    ar(right(B), left(ABM))
    ar(right(IMM), bot(ABM), color="#bf9000", rad=0.2, label="imm")
    ar(right(AAM), (ALU[0] - ALU[2] / 2, ALU[1] + 0.5))
    ar(right(ABM), (ALU[0] - ALU[2] / 2, ALU[1] - 0.5))
    ar(right(ALU), left(FF), label="result")

    # feedback paths (distinct color)
    fb = "#cc4125"
    ar(top(FF), (PCM[0] + 0.7, PCM[1]), color=fb, rad=-0.3)  # ALUOut->pcMux
    ar(top(ALU), (PCM[0] + 0.7, PCM[1] - 0.05), color=fb, rad=-0.25)  # result->pcMux (branch)
    ar(right(PCM), top(PC), color=fb, rad=0.0, label="PC+4 / dal / atla / JR", lx=-1.0, ly=0.35)
    ar(bot(FF), (MAM[0], MAM[1] - 0.9), color=fb, rad=0.3, label="ffResult", ly=-0.4)  # ALUOut->memAddrMux
    # regDIn feedback
    ar(bot(MDR), (RDM[0] + 0.6, RDM[1]), color=fb, rad=-0.2, label="MDR")
    ar(bot(FF), (RDM[0] - 0.4, RDM[1] - 0.4), color=fb, rad=0.35)
    ar(top(RDM), bot(RF), color=fb, rad=0.0, label="dIn", lx=0.5)

    ax.text(3.0, 2.6 + 1.1, "geri besleme (feedback)", color=fb, fontsize=8,
            ha="center", style="italic")

    ax.set_title("Multi-Cycle MIPS — Datapath Blok Diyagramı (MUX / register / veri yolları)",
                 fontsize=14, fontweight="bold")
    ax.set_xlim(-0.5, 21.5)
    ax.set_ylim(-4.0, 4.2)
    ax.set_aspect("equal")
    ax.axis("off")
    plt.tight_layout()
    out = os.path.join(OUT, "datapath_diagram.png")
    plt.savefig(out, dpi=150, bbox_inches="tight")
    print("wrote", out)
    plt.close(fig)


if __name__ == "__main__":
    fsm_diagram()
    datapath_diagram()
