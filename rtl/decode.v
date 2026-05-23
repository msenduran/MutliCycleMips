/**
 * Module Decode
 * Inputs: instruction (instr)
 * Outputs: rd, rs, sign extend immediate (sxi), zero-extended immediate (zxi),
 * jump address (jAddr), command (cmd).
 * Function: Output the addresses and command for use in the CPU and FSM.
 */
`include "fsm.v"

module decode
  (
   input [31:0]     instr,
   input [31:0]     memInstr,
   output [4:0]     rd,
                    rt,
                    rs,
   output [31:0]    sxi,
                    zxi,
                    sxi11,
   output [27:0]    jAddr,
   output reg [4:0] cmd,
   output reg [4:0] memCmd
   );

   wire [5:0]       opcode, funct, memOpcode, memFunct;

   localparam
     LW = 6'h23,
     SW = 6'h2b,
     J = 6'h2,
     JAL = 6'h3,
     BEQ = 6'h4,
     BNE = 6'h5,
     BGT = 6'h7,
     XORI = 6'he,
     ANDI = 6'hc,
     ORI  = 6'hd,
     SLTI = 6'ha,
     ADDI = 6'h8,
     LOADI = 6'h1d,
     ADDI3 = 6'h1e,
     PUSH  = 6'h1a,
     POP   = 6'h1b,

     R_JR  = 6'h8,
     R_ADD = 6'h20,
     R_SUB = 6'h22,
     R_AND = 6'h24,
     R_OR  = 6'h25,
     R_XOR = 6'h26,
     R_SLT = 6'h2a,
     R_SWAP = 6'h30,
     R_MUL  = 6'h18;

   assign
     rd = instr[15:11],
     rt = instr[20:16],
     rs = instr[25:21],
     sxi = {{16{instr[15]}}, instr[15:0]},
     zxi = {16'b0, instr[15:0]},
     sxi11 = {{21{instr[10]}}, instr[10:0]},
     opcode = instr[31:26],
     funct = instr[5:0],
     jAddr = {instr[25:0], 2'b0},
     memOpcode = memInstr[31:26],
     memFunct = memInstr[5:0];

   always @(memOpcode, memFunct) begin
      case (memOpcode)
        LW   : memCmd = `LW;
        SW   : memCmd = `SW;
        J    : memCmd = `J;
        JAL  : memCmd = `JAL;
        BEQ  : memCmd = `BEQ;
        BNE  : memCmd = `BNE;
        BGT  : memCmd = `BGT;
        XORI : memCmd = `XORI;
        ANDI : memCmd = `ANDI;
        ORI  : memCmd = `ORI;
        SLTI : memCmd = `SLTI;
        ADDI : memCmd = `ADDI;
        LOADI: memCmd = `LOADI;
        ADDI3: memCmd = `ADDI3;
        PUSH : memCmd = `PUSH;
        POP  : memCmd = `POP;
        default :
          case (memFunct)
            R_JR  : memCmd = `JR;
            R_ADD : memCmd = `ADD;
            R_SUB : memCmd = `SUB;
            R_AND : memCmd = `AND;
            R_OR  : memCmd = `OR;
            R_XOR : memCmd = `XOR_R;
            R_SLT : memCmd = `SLT;
            R_SWAP: memCmd = `SWAP;
            R_MUL : memCmd = `MUL;
            default: memCmd = `LW;
          endcase
      endcase
   end

   always @(opcode, funct) begin
      case (opcode)
        LW   : cmd = `LW;
        SW   : cmd = `SW;
        J    : cmd = `J;
        JAL  : cmd = `JAL;
        BEQ  : cmd = `BEQ;
        BNE  : cmd = `BNE;
        BGT  : cmd = `BGT;
        XORI : cmd = `XORI;
        ANDI : cmd = `ANDI;
        ORI  : cmd = `ORI;
        SLTI : cmd = `SLTI;
        ADDI : cmd = `ADDI;
        LOADI: cmd = `LOADI;
        ADDI3: cmd = `ADDI3;
        PUSH : cmd = `PUSH;
        POP  : cmd = `POP;
        default :
          case (funct)
            R_JR  : cmd = `JR;
            R_ADD : cmd = `ADD;
            R_SUB : cmd = `SUB;
            R_AND : cmd = `AND;
            R_OR  : cmd = `OR;
            R_XOR : cmd = `XOR_R;
            R_SLT : cmd = `SLT;
            R_SWAP: cmd = `SWAP;
            R_MUL : cmd = `MUL;
            default: cmd = `LW;
          endcase
      endcase
   end
endmodule
