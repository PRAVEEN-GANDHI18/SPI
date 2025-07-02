module ram_1kB(
  input wire sys_clock,
  input wire reset_n,
  input wire rx_valid,
  input wire [17:0] data_in,
 
  output reg [17:0] data_out, // back to slave
  output reg tx_valid
);
  // 1kB = 1x1024x8 bits || word length = 16 bits | total words = 512
  reg [15:0] mem [0:511];//1KB RAM MEMORY -> mem
  wire [1:0] opcode;

 
  // Internal Registers
  reg [15:0] wptr;
  reg [15:0] rptr;
  reg [17:0] data_buf;
  reg valid_buf;
 
  localparam ADDR_STORE = 2'b00,  // Address in which the data going to be stored  (Move write pointer)
  DATA_WRITE = 2'b01,  // Data that is going to be written in the write pointrer
  READ_ADDR  = 2'b10,  // Read address in which read pointer will be pointed to
  READ_DATA  = 2'b11;  // This indicates the data which is stored in READ ADDR ""data_out""
 
  assign opcode = data_in[17:16];
  //assign data_out = data_buf;
  assign tx_valid = valid_buf;
 
  always@(posedge sys_clock or negedge reset_n) begin
    if(~reset_n) begin
      for(int i=0;i<512;i++)begin
        for(int j=0;j<16;j++)begin
          mem[i][j]=0;
        end
      end
     // mem<=0;
      //data_buf <= 18'b0;
      wptr <= 16'b0;
      rptr <= 16'b0;
      valid_buf <= 1'b0;
    end
    else if(rx_valid) begin
      case(opcode)
        ADDR_STORE:
          begin
            wptr<= data_in[15:0];//stores write address in write pointer
            valid_buf <= 1'b0;
          end
       
        DATA_WRITE:
          begin
            mem[wptr] <= data_in[15:0];//stores data in the write pointer address
            valid_buf <= 1'b0;
          end
       
        READ_ADDR:
          begin
            rptr <= data_in[15:0];//stores read address in read pointer
            valid_buf <= 1'b0;
          end
       
        READ_DATA:
          begin
            //data_buf <= {2'b00,mem[rptr]};
            data_out <= {2'b00,mem[rptr]};
            valid_buf <= 1'b1;
          end
         
        default:
          begin
            //data_buf <= 18'b0;
            data_out<=18'b0;
            valid_buf <= 1'b0;
          end
         
      endcase
    end else begin
      //data_buf <= 18'b0;
      data_out<=18'b0;
    end
  end
endmodule


