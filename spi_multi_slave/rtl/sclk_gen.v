//generates serial clock
module sclk_gen(
  input wire sys_clock,
  input wire reset_n,
  input tx_enable,
  input nextstate,
  input wire [1:0]clock_speed,
  input wire [1:0]clock_mode,
  output reg sclk
);
  localparam MODE0=2'b00;
  localparam MODE1=2'b01;
  localparam MODE2=2'b10;
  localparam MODE3=2'b11;
  localparam CLOCK2=2'b00;
  localparam CLOCK4=2'b01;
  localparam CLOCK8=2'b10;
  localparam CLOCK16=2'b11;
  reg [7:0]final_value;
  reg [7:0]clock_ticks;
  
  
  always@(negedge nextstate,negedge reset_n)begin
    if (~reset_n)begin
      sclk<=(clock_mode[1])?1'b1:1'b0;
    end
    else begin
      if(~nextstate)begin
        case(clock_mode)
          MODE0,MODE1:begin
            sclk<=0;
          end
          
          MODE2,MODE3:begin
            sclk<=1;
          end
        endcase
      end
    end
  end
  
  always@(clock_speed)begin
    case(clock_speed)
      CLOCK16:final_value=8'd8;
      CLOCK8:final_value=8'd4;
      CLOCK4:final_value=8'd2;
      CLOCK2:final_value=8'd1;
      default:final_value=8'd1;
    endcase
  end
      
  
  always @(posedge sys_clock, negedge reset_n)begin
    if(~reset_n || ~nextstate)begin
      clock_ticks<=1;
    end
    else begin
      if (nextstate)begin
      if(clock_ticks==final_value)begin
        clock_ticks<=1;
        sclk<=~sclk;
      end
      else begin
        clock_ticks<=clock_ticks+1;
        sclk<=sclk;
      end
    end
    end
  end
  
endmodule
          
          
        
