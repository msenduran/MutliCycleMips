/**
 * Module FSM
 * Inputs: clock (clk), equality boolean (eq), command (cmd).
 * Outputs: Control signals for the multicycle CPU.
 * Function: Output the control signals for the multicycle CPU.
 */
`define MEM_PC 0
`define MEM_ALU_RES 1
`define MEM_A 2
`define DST_RD 0
`define DST_RT 1
`define DST_RS 2
`define DST_SP 3
`define PC_SRC_ALU_RES 0
`define PC_SRC_ALU 1
`define PC_SRC_J 2
`define PC_SRC_A 3
`define ALU_SRC_A_PC 0
`define ALU_SRC_A_A 1
`define ALU_SRC_A_FFRES 2
`define ALU_SRC_B_SXIS 0
`define ALU_SRC_B_IMM 1
`define ALU_SRC_B_B 2
`define ALU_SRC_B_4 3
`define REG_IN_MDR 0
`define REG_IN_ALU_RES 1
`define REG_IN_B 2
`define REG_IN_A 3
`define IMM_SXI 0
`define IMM_ZXI 1
`define IMM_SXI11 2

`define IF 0
`define ID_B 1
`define ID_J 2
`define ID_X 3
`define EX_BEQ 4
`define EX_BNE 5
`define EX_JR 6
`define EX_SUB 7
`define EX_ADD 8
`define EX_SLT 9
`define EX_XORI 10
`define EX_LWSWADDI 11
`define MEM_LW 12
`define MEM_SW 13
`define WB_JAL 14
`define WB_SUBADDSLT 15
`define WB_ADDIXORI 16
`define WB_LW 17
`define WB_BEQ 18
`define WB_BNE 19
`define EX_AND 20
`define EX_OR 21
`define EX_XOR_R 22
`define EX_ANDI 23
`define EX_ORI 24
`define EX_SLTI 25
`define WB_R_LOGIC 26
`define WB_I_LOGIC 27
`define EX_BGT 28
`define WB_BGT 29
`define EX_ADDI3_1 30
`define EX_ADDI3_2 31
`define WB_ADDI3 32
`define WB_SWAP1 33
`define WB_SWAP2 34
`define EX_MUL 35
`define EX_PUSH 36
`define MEM_PUSH 37
`define WB_PUSH_SP 38
`define MEM_POP 39
`define WB_POP_RT 40
`define WB_POP_SP 41

`define ALU_ADD 0
`define ALU_SUB 1
`define ALU_XOR 2
`define ALU_SLT 3
`define ALU_AND 4
`define ALU_NAND 5
`define ALU_NOR 6
`define ALU_OR 7
`define ALU_MUL 8

`define LW 0
`define SW 1
`define J 2
`define JR 3
`define JAL 4
`define BEQ 5
`define BNE 6
`define XORI 7
`define ADDI 8
`define ADD 9
`define SUB 10
`define SLT 11
`define AND 12
`define OR 13
`define XOR_R 14
`define ANDI 15
`define ORI 16
`define SLTI 17
`define LOADI 18
`define BGT 19
`define ADDI3 20
`define SWAP 21
`define MUL 22
`define PUSH 23
`define POP 24

module fsm
  (
   input            clk,
                    eq,
                    gt,
   input [4:0]      cmd,
                    memCmd,
   output reg [3:0] aluOp,
   output reg [1:0] pcSrc,
                    aluSrcB,
                    aluSrcA,
                    immExt,
                    regIn,
                    dst,
                    memIn,
   output reg       pcWe,
   memWe,
   irWe,
   aWe,
   bWe,
   regWe,
   aluResWe
   );

   reg [5:0]        prevState;
   reg [5:0]        state;

   // Compute the current state
   initial state = 0;
   always @(prevState, cmd, memCmd) begin
      case (prevState)
        `IF :
          if (memCmd == `BNE || memCmd == `BEQ || memCmd == `BGT) state = `ID_B;
          else if (memCmd == `J || memCmd == `JAL) state = `ID_J;
          else state = `ID_X;
        `ID_B :
          case (cmd)
            `BEQ : state = `EX_BEQ;
            `BNE : state = `EX_BNE;
            `BGT : state = `EX_BGT;
            default: state = `EX_BNE;
          endcase
        `ID_J : state = (cmd == `J) ? `IF : `EX_BNE;
        `ID_X :
          case (cmd)
            `JR    : state = `EX_JR;
            `SUB   : state = `EX_SUB;
            `ADD   : state = `EX_ADD;
            `SLT   : state = `EX_SLT;
            `AND   : state = `EX_AND;
            `OR    : state = `EX_OR;
            `XOR_R : state = `EX_XOR_R;
            `XORI  : state = `EX_XORI;
            `ANDI  : state = `EX_ANDI;
            `ORI   : state = `EX_ORI;
            `SLTI  : state = `EX_SLTI;
            `LOADI : state = `EX_LWSWADDI;
            `ADDI3 : state = `EX_ADDI3_1;
            `SWAP  : state = `WB_SWAP1;
            `MUL   : state = `EX_MUL;
            `PUSH  : state = `EX_PUSH;
            `POP   : state = `MEM_POP;
            default : state = `EX_LWSWADDI;
          endcase

        `EX_BEQ : state = `WB_BEQ;
        `EX_BNE : state = `WB_BNE;
        `EX_BGT : state = `WB_BGT;
        `EX_JR : state = `IF;
        `EX_SUB : state = `WB_SUBADDSLT;
        `EX_ADD : state = `WB_SUBADDSLT;
        `EX_SLT : state = `WB_SUBADDSLT;
        `EX_AND : state = `WB_R_LOGIC;
        `EX_OR  : state = `WB_R_LOGIC;
        `EX_XOR_R : state = `WB_R_LOGIC;
        `EX_XORI : state = `WB_ADDIXORI;
        `EX_ANDI : state = `WB_I_LOGIC;
        `EX_ORI  : state = `WB_I_LOGIC;
        `EX_SLTI : state = `WB_I_LOGIC;
        `EX_ADDI3_1 : state = `EX_ADDI3_2;
        `EX_ADDI3_2 : state = `WB_ADDI3;
        `WB_SWAP1 : state = `WB_SWAP2;
        `WB_SWAP2 : state = `IF;
        `EX_MUL : state = `WB_SUBADDSLT;
        `EX_PUSH : state = `MEM_PUSH;
        `MEM_PUSH : state = `WB_PUSH_SP;
        `WB_PUSH_SP : state = `IF;
        `MEM_POP : state = `WB_POP_RT;
        `WB_POP_RT : state = `WB_POP_SP;
        `WB_POP_SP : state = `IF;
        `EX_LWSWADDI :
          if (cmd == `ADDI || cmd == `LOADI) state = `WB_ADDIXORI;
          else if (cmd == `SW) state = `MEM_SW;
          else state = `MEM_LW;
        `MEM_LW : state = `WB_LW;
        `MEM_SW : state = `IF;
        default : state = `IF;
      endcase
   end

   // Set control signals
   always @(posedge clk) begin
      case (state)
        `IF : begin
           pcSrc <= `PC_SRC_ALU;
           aluSrcA <= `ALU_SRC_A_PC;
           aluSrcB <= `ALU_SRC_B_4;
           aluOp <= `ALU_ADD;
           memIn <= `MEM_PC;
           immExt <= `IMM_SXI;

           aWe <= 0;
           bWe <= 0;
           irWe <= 1;
           memWe <= 0;
           pcWe <= 1;
           regWe <= 0;
           aluResWe <= 1;
        end

        `ID_B : begin
           aluSrcA <= `ALU_SRC_A_PC;
           aluSrcB <= `ALU_SRC_B_SXIS;
           aluOp <= `ALU_ADD;
           immExt <= `IMM_SXI;

           aWe <= 1;
           bWe <= 1;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 0;
           aluResWe <= 1;
        end

        `ID_J : begin
           pcSrc <= `PC_SRC_J;
           aluSrcA <= `ALU_SRC_A_PC;
           aluSrcB <= `ALU_SRC_B_4;
           aluOp <= `ALU_ADD;
           immExt <= `IMM_SXI;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 1;
           regWe <=0;
           aluResWe <= 1;
        end

        `ID_X : begin
           aWe <= 1;
           bWe <= 1;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_BEQ : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_SUB;
           pcSrc <= `PC_SRC_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 0;
        end

        `EX_BNE : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_SUB;
           pcSrc <= `PC_SRC_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 0;
        end

        `EX_BGT : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_SUB;
           pcSrc <= `PC_SRC_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 0;
        end

        `EX_JR : begin
           pcSrc <= `PC_SRC_A;
           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 1;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_SUB : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_SUB;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_ADD : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_ADD;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_SLT : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_SLT;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_AND : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_AND;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_OR : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_OR;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_XOR_R : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_XOR;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_XORI : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_IMM;
           aluOp <= `ALU_XOR;
           immExt <= `IMM_ZXI;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_ANDI : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_IMM;
           aluOp <= `ALU_AND;
           immExt <= `IMM_ZXI;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_ORI : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_IMM;
           aluOp <= `ALU_OR;
           immExt <= `IMM_ZXI;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_SLTI : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_IMM;
           aluOp <= `ALU_SLT;
           immExt <= `IMM_SXI;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_LWSWADDI : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_IMM;
           aluOp <= `ALU_ADD;
           immExt <= `IMM_SXI;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `MEM_LW : begin
           memIn <= `MEM_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `MEM_SW : begin
           memIn <= `MEM_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 1;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `WB_JAL : begin
           dst <= `DST_RD;
           regIn <= `REG_IN_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `WB_SUBADDSLT : begin
           dst <= `DST_RD;
           regIn <= `REG_IN_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `WB_R_LOGIC : begin
           dst <= `DST_RD;
           regIn <= `REG_IN_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `WB_ADDIXORI : begin
           dst <= `DST_RT;
           regIn <= `REG_IN_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `WB_I_LOGIC : begin
           dst <= `DST_RT;
           regIn <= `REG_IN_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `WB_LW : begin
           dst <= `DST_RT;
           regIn <= `REG_IN_MDR;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `WB_BEQ : begin
           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= eq;
           regWe <=0;
           aluResWe <= 1;
        end

        `WB_BNE : begin
           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= !eq;
           regWe <=0;
           aluResWe <= 1;
        end

        `WB_BGT : begin
           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= gt;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_ADDI3_1 : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_ADD;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_ADDI3_2 : begin
           aluSrcA <= `ALU_SRC_A_FFRES;
           aluSrcB <= `ALU_SRC_B_IMM;
           aluOp <= `ALU_ADD;
           immExt <= `IMM_SXI11;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `WB_ADDI3 : begin
           dst <= `DST_RD;
           regIn <= `REG_IN_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `WB_SWAP1 : begin
           dst <= `DST_RS;
           regIn <= `REG_IN_B;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `WB_SWAP2 : begin
           dst <= `DST_RT;
           regIn <= `REG_IN_A;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `EX_MUL : begin
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_B;
           aluOp <= `ALU_MUL;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <=0;
           aluResWe <= 1;
        end

        `EX_PUSH : begin
           // ffResult <- SP - 4
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_4;
           aluOp <= `ALU_SUB;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 0;
           aluResWe <= 1;
        end

        `MEM_PUSH : begin
           // mem[ffResult] <- b ; keep ffResult unchanged (SP-4 stays for WB)
           memIn <= `MEM_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 1;
           pcWe <= 0;
           regWe <= 0;
           aluResWe <= 0;
        end

        `WB_PUSH_SP : begin
           // reg[$29] <- ffResult (= SP-4)
           dst <= `DST_SP;
           regIn <= `REG_IN_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `MEM_POP : begin
           // memAddr <- A (SP) ; in parallel, ALU computes SP+4 into ffResult
           memIn <= `MEM_A;
           aluSrcA <= `ALU_SRC_A_A;
           aluSrcB <= `ALU_SRC_B_4;
           aluOp <= `ALU_ADD;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 0;
           aluResWe <= 1;
        end

        `WB_POP_RT : begin
           // reg[rt_field=rd] <- mem[A] (read combinationally via dOut)
           // keep memIn=MEM_A so dOut still reflects mem[SP]
           dst <= `DST_RT;
           regIn <= `REG_IN_MDR;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end

        `WB_POP_SP : begin
           // reg[$29] <- ffResult (= SP+4)
           dst <= `DST_SP;
           regIn <= `REG_IN_ALU_RES;

           aWe <= 0;
           bWe <= 0;
           irWe <= 0;
           memWe <= 0;
           pcWe <= 0;
           regWe <= 1;
        end
      endcase
      prevState <= state;
   end
endmodule
