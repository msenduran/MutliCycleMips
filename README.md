# mips-subset

This is a multicycle CPU meant to be an improvement over our initial mips single cycle CPU.
By varying the amount of cycles used per instruction, every operation is no longer necessarily as slow as the slowest operation.
We also get to re-use components in different cycles, allowing us to decrease area cost.
The supported commands are LW, SW, J, JR, JAL, BEQ, BNE, XORI, ADDI, ADD, SUB, and SLT.

# Implementation

We used the above circuitry for the CPU.
We chose this as it uses only the necessities, such as an ALU.
We then added DFFs where necessary via an FSM
The additional wire over the instruction register (IR) exists because the FSM must know the current instruction to move onto the ID phase.
However, due to the instruction needing to go through both the memory unit and the instruction memory, the instruction is not actually loaded until after ID when it is too late.
Luckily, we are guaranteed given this subset of instructions and our FSM that in the clock cycle before IR is updated the output of the memory unit is the instruction of concern.

![alt text](https://github.com/concavegit/multicycle-mips/blob/master/New%20Doc%202018-11-13%2012.13.11.jpg)

# FSM

This is based off our CPU structure, we have merged as many states as possible without effecting the clock cycle or decoder instructions.

![alt text](https://github.com/concavegit/multicycle-mips/blob/master/Untitled%20Diagram.png)

The appropriate control signals are set given the current state, and state transitions are calculated given the previous state and the current instruction.

For an example insturction `addi $t0, $t0 2`

The relevant state progression would be this:

1. We start off at common for all `IF`
2. And then move to the `ID` which is common for ADD,SUB,ADDI and other similar instructions.
3. We then go to the add `EX` state which is the only unique state for this instruction.
4. Finally end at a `WB` which is common for all executional instructions which write back to the register.







# Description of our test plan and result
This is a waveform with all decoder and regfile ports exposed. This helped us catch many errors such as BNE needing to jump to PC+4+IMM<<2, rather than PC + IMM<<2. This also helped us see that our mux inputs for BNE were swapped.

![](res/gtkwave.png)

For the testing we had a 3 pronged approach. 

- Number 1 was to test all the components individually using Verilog test benches, especially the ALU.
  However, since we re-use components which have been proven to work in past experience and make no changes, they are not included.

- Number 2 was to write unit tests for all the functions our CPU was capable of doing. This helped us debug control signals and the integration. All the unit tests worked fine.
  This is tested by changing the instruction parameter set in `testbench/cpu.t.v` to the appropriate memory file, running, and checking the output of `$v0`.

- Number 3 was to write more complex assembly code.
  We ran program which calculated the sum of N natural numbers, which used immediate and branch functions.
  The testbench prints contents of $v0 for the correct return value (120 for the sum of the first 15 natural numbers) as well as a waveform.
  This is tested by running `testbench/cpu.t.v` with iverilog as-is.
  
Some performance/area analysis of your design. This can be for the full processor, or a case study of choices made designing a single unit.It can be based on calculation, simulation, Vivado synthesis results, or a mix of all three.

# Test Benches

- CPU Operations: We created a test for each of the 12 assembly operations we implemented.
- Regfile: We write values to all registers with both write enable possibilities, checking for changes and consistencies with asserts. We also make sure that $zero is always zero in these processes. We also made sure that both read and write ports were decoupled via asserts.
- ALU: We used a testbench which checks 49 cases for each of the 8 operations. The 49 cases tested all possible pairs of the following 7 inputs, (2^31)-1, (2^31)-2, -2^31, (-2^31) + 1, 0, 1, and -1. This is a verilator testbench.
- CPU and FSM: We used a summation testbench, knowing that the final value of $v0 should be 120, the sum of natural numbers to 15.
  When there was an error, we checked the control signals and made proper adjustments.
  Where there were timing issues, we changed the hardware.

# Challenges
The first order of business was testing the decoder, which was a day of work.
The hardest challenges was the issue of the FSM requiring the flip-floped instruction from the PC, and that path has the PC, the memory unit, and the IR.
This caused the FSM to proceed to the default state because the instruction had not reached the IR.
We fixed one timing issues by not committing to the next state from the current state
Instead, we calculate the current state based off the previous state and the current command.
The second timing issue was solved by creating a wire which bypasses the IR to the FSM and decoder, as the memory output the cycle before the IR is updated is the instruction of concern.

# Performance
Our design is optimized for area.
We have only a single ALU for arithmetic operations, in contrast to our single-cycle CPU requiring an additional PC incrementer due to structural constraints.
Our memory unit also has a single read address and data output, as we no longer need to access an instruction and data at the same time.
This eliminates an entire 2^10-way mux.

Our design also has better timing than the single cycle CPU.
For example, the MEM phase of the multicycle CPU is the slowest.
However, not every instruction needs it, whereas the single cycle CPU must have a clock speed which can execute the slowest instruction in a single cycle.

# Further Work
We currently use sequential logic for the setting of control signals as part of the FSM.
This has caused us to have to wait for a flip-flop value such as an equals flag to properly set a control signal.
Our solution for BNE and BEQ was to add an additional WB phase which uses the EQ flag found in the EX phase before returning to IF.
If we were to design this again, we would have state transitions be the only sequential logic, and use combinatorial logic for control signals and everything else.
