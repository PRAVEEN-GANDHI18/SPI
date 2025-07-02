//master inputs
//clock  neg_reset  transc_en  input_data  clock_speed  mode  

module spi_slave(
  input wire sys_clock,
  input wire reset_n,
  input wire [1:0]spi_mode,
  input wire mosi,//serial
  input wire [17:0]ram_data_in,//from ram
  input wire ss_n, 
  input wire sclk, //serial clock
  input wire tx_valid,
  output reg miso,//serial
  output reg [17:0] slave_out,
  output reg rx_valid
);
  
  
  localparam IDLE=1'b0;
  localparam ACTIVE =1'b1;
  
  localparam MODE0=2'b00;
  localparam MODE1=2'b01;
  localparam MODE2=2'b10;
  localparam MODE3=2'b11;
  
  reg nextstate;
  
  // ----buffer----
  reg [17:0]stx_buffer;
  reg [17:0]srx_buffer;
  
  reg [4:0]stx_counter; //18 maxvalue
  reg [4:0]srx_counter;
  
  reg modified_sclk;
  reg first_edge;
  
  //reg prev_clk, cur_clk;
  
  always @(sclk) begin
    
    if(~|spi_mode) begin			//mode00
      modified_sclk = ~sclk;
    end else if(spi_mode[1] && ~spi_mode[0]) begin
      modified_sclk = sclk;
    end else if(~spi_mode[1] && spi_mode[0]) begin
      if(~first_edge) begin
        first_edge = 1'b1;
      end else begin
        modified_sclk = sclk;
      end
    end else begin
      if(~first_edge) begin
        first_edge = 1'b1;
      end else begin
        modified_sclk = ~sclk;
      end
    end
    
  end
      
  always@(posedge sys_clock,negedge reset_n)begin
    
    if (~reset_n)begin
      modified_sclk<=1'b1;
      first_edge<=0;
    end
    else if(~nextstate)begin
      modified_sclk<=1'b1;
    end
    
  end
  
 
  always@( posedge tx_valid,negedge reset_n)begin
    
    if (~reset_n)begin
      stx_buffer<=18'h3ffff;
    end
    else if(tx_valid)begin
      stx_buffer<=ram_data_in;
    end
    else begin
      stx_buffer<=18'h3ffff;
    end
    
  end
  
//RECEIVING DATA (SAMPLING IN)----------------=
  always @(posedge modified_sclk) begin
    
    if(nextstate) begin
      srx_buffer[17]= mosi;					
      if (srx_counter!=17)
        srx_buffer=srx_buffer>>1;
      srx_counter = srx_counter+1'b1;
    end
    
  end
    
  //-----------SENDING DATA (SHIFTING OUT)----------------=
  always @(modified_sclk) begin
    
    case(nextstate)
      IDLE: begin
        miso=stx_buffer[0];
        srx_buffer= 18'h3ffff;
        first_edge=0;
      end
      ACTIVE: begin
        if(~modified_sclk) begin
          miso = stx_buffer[0];			//lsb first
          stx_buffer ={1'b1,stx_buffer[17:1]};//mtx_buffer = mtx_buffer>>1
          if(stx_counter!=18)stx_counter = stx_counter +1;
        end
      end
    endcase
    
  end


              
  always@(posedge sys_clock ,negedge ss_n, negedge reset_n)begin
    
    if (~reset_n)begin
      nextstate<=IDLE;
      stx_buffer<=18'h3ffff;
      srx_buffer<=18'h3ffff;
      stx_counter<=0;
      srx_counter<=0;
      miso<=1;
      slave_out<=18'h3ffff;
    end
    else begin
      case(nextstate)
        IDLE:begin
          rx_valid<=0;
          if(~ss_n) begin
            nextstate<=ACTIVE;
          end else nextstate<=IDLE;
        end
        ACTIVE:begin
          if ((stx_counter==18 && srx_counter==18) || ss_n)begin    
            slave_out <=srx_buffer;	
             rx_valid<=1;
            nextstate<=IDLE;
            stx_counter<=0;
            srx_counter<=0;
           
          end else begin
            nextstate<=ACTIVE;
          end
        end
      endcase
    end
    
  end
endmodule
            
          
          
    
      
