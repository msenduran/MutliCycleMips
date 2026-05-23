module mux
  #(parameter width=32)
   (
    output [width-1:0] out,
    input              sel,
    input [width-1:0]  in0,
    input [width-1:0]  in1
    );

   assign out = sel ? in1 : in0;
endmodule
