module mux4way
  #(parameter width=32)
   (
    output [width-1:0] out,
    input [1:0]        sel,
    input [width-1:0]  in0,
    input [width-1:0]  in1,
    input [width-1:0]  in2,
    input [width-1:0]  in3
    );

   assign out = sel[0] ? (sel[1] ? in3 : in1) : (sel[1] ? in2 : in0);
endmodule
