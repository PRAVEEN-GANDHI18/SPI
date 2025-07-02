module multiplex(
  input miso1,
  input miso2,
  input cs,
  output reg miso);
  
  always @(*) begin
    case(cs)
      1'b0: miso=miso1;
      1'b1: miso=miso2;
    endcase
  end
  
endmodule
