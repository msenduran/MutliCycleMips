`include "decode.v"
`include "alu.v"
`include "regfile.v"
`include "memory.v"
`include "mux4way.v"
`include "mux.v"

module cpu
  #(parameter instruction="mem/data.dat")
   (input clk);

   wire [31:0] sxi, zxi, sxi11, dOut;
   wire [4:0]  rd, rt, rs;
   wire [27:0] jAddr28;
   wire [4:0]  cmd, memCmd;
   reg [31:0]  ir;

   initial ir =  {mem0.mem[0], mem0.mem[1], mem0.mem[2], mem0.mem[3]};

   decode decode0
     (
      .instr(ir),
      .memInstr(dOut),
      .rd(rd),
      .rt(rt),
      .rs(rs),
      .sxi(sxi),
      .zxi(zxi),
      .sxi11(sxi11),
      .jAddr(jAddr28),
      .cmd(cmd),
      .memCmd(memCmd)
      );

   wire        eq, gt, pcWe, memWe, irWe, aWe, bWe, regWe, aluResWe;
   wire [3:0]  aluOp;
   wire [1:0]  pcSrc, aluSrcB, aluSrcA, immExt, regIn, dst, memIn;

   fsm fsm0
     (
      .clk(clk),
      .eq(eq),
      .gt(gt),
      .cmd(cmd),
      .memCmd(memCmd),
      .aluOp(aluOp),
      .pcSrc(pcSrc),
      .aluSrcB(aluSrcB),
      .pcWe(pcWe),
      .memWe(memWe),
      .irWe(irWe),
      .aWe(aWe),
      .bWe(bWe),
      .regWe(regWe),
      .regIn(regIn),
      .aluSrcA(aluSrcA),
      .memIn(memIn),
      .dst(dst),
      .aluResWe(aluResWe),
      .immExt(immExt)
      );

   wire [31:0] imm;
   mux4way immMux
     (
      .out(imm),
      .sel(immExt),
      .in0(sxi),
      .in1(zxi),
      .in2(sxi11),
      .in3(32'b0)
      );

   reg [31:0]  pc, a, b, ffResult;
   initial pc = 0;
   wire [31:0] aluA, aluB, result;
   wire        zero, overflow;

   and eqAnd(eq, zero, !overflow);
   // Signed greater-than for BGT: !Z AND (N == V), where N=result[31], V=overflow
   assign gt = !zero && (result[31] == overflow);

   mux4way aluAMux
     (
      .out(aluA),
      .sel(aluSrcA),
      .in0(pc),
      .in1(a),
      .in2(ffResult),
      .in3(32'b0)
      );

   mux4way aluBMux
     (
      .out(aluB),
      .sel(aluSrcB),
      .in0(sxi<<2),
      .in1(imm),
      .in2(b),
      .in3(4)
      );

   alu alu0
     (
      .result(result),
      .zero(zero),
      .overflow(overflow),
      .operandA(aluA),
      .operandB(aluB),
      .command(aluOp)
      );

   wire [31:0] memAddr;
   always @(posedge clk) if (aluResWe) ffResult <= result;

   mux4way memAddrMux
     (
      .out(memAddr),
      .sel(memIn),
      .in0(pc),
      .in1(ffResult),
      .in2(a),
      .in3(32'b0)
      );

   memory #(.data(instruction)) mem0
     (
      .dOut(dOut),
      .clk(clk),
      .addr(memAddr),
      .we(memWe),
      .dIn(b)
      );

   wire [31:0] dOut0, dOut1, regDIn;
   wire [4:0]  writeAddr;

   mux4way #(.width(5)) writeAddrMux
     (
      .out(writeAddr),
      .sel(dst),
      .in0(rd),
      .in1(rt),
      .in2(rs),
      .in3(5'd29)
      );

   mux4way regDInMux
     (
      .out(regDIn),
      .sel(regIn),
      .in0(dOut),
      .in1(ffResult),
      .in2(b),
      .in3(a)
      );

   regfile regfile0
     (
      .dOut0(dOut0),
      .dOut1(dOut1),
      .dIn(regDIn),
      .readAddr0(rs),
      .readAddr1(rt),
      .writeAddr(writeAddr),
      .we(regWe),
      .clk(clk)
      );

   wire [31:0] pcIn;

   // assign pcIn = pcSrc[1] ? pcSrc[0] ? a : {pc[31:28], jAddr28} : pcSrc[0] ? result : ffResult;
   mux4way pcMux
     (
      .out(pcIn),
      .sel(pcSrc),
      .in0(ffResult),
      .in1(result),
      .in2({pc[31:28], jAddr28}),
      .in3(a)
      );

   always @(posedge clk) begin
      if (aWe) a <= dOut0;
      if (bWe) b <= dOut1;
      if (irWe) ir <= dOut;
      if (pcWe) pc <= pcIn;
   end

endmodule
