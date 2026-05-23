/*
 Module alu
 
 Inputs: operandA, operandB, command
 Outputs: result, carryout, zero, overflow
 Function: result = the result of the corresponding command.
 carryout = the carry output of either addition or subtraction, 0
 otherwise.
 zero = 1 if the command is addition or subtraction and the result
 is 0, 0 otherwise.
 */

module alu
  #(parameter width = 32)
   (
    output reg signed [width-1:0] result,
    output                        zero,
    output reg                    overflow,
                                  carryout,
    input signed [width-1:0]      operandA,
                                  operandB,
    input [3:0]                   command
    );

   localparam
     ADD = 4'b0000,
     SUB = 4'b0001,
     XOR = 4'b0010,
     SLT = 4'b0011,
     AND = 4'b0100,
     NAND = 4'b0101,
     NOR = 4'b0110,
     OR = 4'b0111,
     MUL = 4'b1000;

   always @(command, operandA, operandB) begin
      case (command)
        ADD: begin
           {carryout, result} = {1'b0, operandA} + {1'b0, operandB};
           overflow = (operandA[width-1] ~^ operandB[width-1]) && (operandA[width-1] ^ result[width-1]) ? 1 : 0;
        end

        SUB: begin
           {carryout, result} = {1'b0, operandA} + {1'b0, ~operandB} + 1;
           overflow = (operandA[width-1] ^ operandB[width-1]) && (operandA[width-1] ^ result[width-1]) ? 1 : 0;
        end

        XOR: begin
           result = operandA ^ operandB;
           carryout = 0;
           overflow = 0;
        end

        SLT: begin
           result = {{(width-1){1'b0}}, operandA < operandB};
           carryout = 0;
           overflow = 0;
        end

        AND: begin
           result = operandA & operandB;
           carryout = 0;
           overflow = 0;
        end

        NAND: begin
           result = ~(operandA & operandB);
           carryout = 0;
           overflow = 0;
        end

        NOR: begin
           result = ~(operandA | operandB);
           carryout = 0;
           overflow = 0;
        end

        OR: begin
           result = operandA | operandB;
           carryout = 0;
           overflow = 0;
        end

        MUL: begin
           result = operandA * operandB;  // signed multiply, lower 32 bits
           carryout = 0;
           overflow = 0;
        end

        default: begin
           result = 0;
           carryout = 0;
           overflow = 0;
        end
      endcase
   end

   assign zero = (command == ADD || command == SUB) ? result == 0 : 0;
endmodule
