//master inputs
//clock  neg_reset  transc_en  input_data  clock_speed  mode  

module spi_master(
  input wire sys_clock,
  input wire reset_n,
  input wire tx_enable,
  input wire [17:0]data_in,
  input wire [1:0]clock_speed,
  input wire [1:0]spi_mode,
  input wire miso,//serial
  output reg ss_n, 
  output reg mosi,//serial
  output reg sclk, //serial clock
  output reg [17:0] master_out,
  output reg mrx_data_valid
);
  reg nextstate;
  
  sclk_gen sclk_gen_master(
    .sys_clock(sys_clock),
    .reset_n(reset_n),
    .tx_enable(tx_enable),
    .nextstate(nextstate),
    .clock_speed(clock_speed),
    .clock_mode(spi_mode),
    .sclk(sclk)
);
  
  
  localparam IDLE=1'b0;
  localparam ACTIVE =1'b1;
  
  localparam MODE0=2'b00;
  localparam MODE1=2'b01;
  localparam MODE2=2'b10;
  localparam MODE3=2'b11;
  
  
  
  // ----buffer----
  reg [17:0]mtx_buffer;
  reg [17:0]mrx_buffer;
  
  reg [4:0]mtx_counter; //18 maxvalue
  reg [4:0]mrx_counter;
  
  reg modified_sclk;
  reg first_edge;
  reg capture_flag;
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
      
  always@(posedge tx_enable,negedge reset_n)begin
    
    if (~reset_n)begin
      modified_sclk<=1'b1;
      first_edge<=0;
    end
    else if(~nextstate) begin
      modified_sclk<=1'b1;
    end
    
  end
  
  always @(posedge tx_enable) capture_flag<=1;
  
  
  
  always@(posedge tx_enable, negedge reset_n)begin
    
    if (~reset_n)begin
      mtx_buffer<=18'h3ffff;
    end
    else begin
      mtx_buffer<=data_in;
    end
    
  end
  
 
  //-----------RECEIVING DATA (SAMPLING IN)----------------=
  always @(posedge modified_sclk) begin
    
    if(nextstate) begin
      mrx_buffer[17]= miso;					
      if (mrx_counter!=17)
        mrx_buffer=mrx_buffer>>1;
      mrx_counter = mrx_counter+1'b1;
    end
    
  end
    
  //-----------SENDING DATA (SHIFTING OUT)----------------=
  always @(modified_sclk) begin
    
    case(nextstate)
      IDLE: begin
        ss_n=1;
        mtx_counter=0;
        mrx_counter=0;
        mosi=mtx_buffer[0];
        mrx_buffer= 18'h3ffff;//sending default one
        first_edge = 0;
      end
      ACTIVE: begin
        if(~modified_sclk) begin
            mosi = mtx_buffer[0];				//lsb first
            mtx_buffer ={1'b1,mtx_buffer[17:1]};//mtx_buffer = mtx_buffer>>1
          if(mtx_counter!=18)mtx_counter = mtx_counter +1;
        end
      end
    endcase
    
  end
              
  always@(posedge sys_clock , negedge reset_n)begin
    
    if (~reset_n)begin
      nextstate<=IDLE;
      mtx_buffer<=18'h3ffff;
      mrx_buffer<=18'h3ffff;
      ss_n<=1;
      mtx_counter<=0;
      mrx_counter<=0;
      mosi<=1;
      mrx_data_valid<=1;
      master_out<=18'h3ffff;
    end
    else begin
      case(nextstate)
        IDLE:begin
          if(capture_flag) begin
            nextstate<=ACTIVE;
            capture_flag<=0;
            ss_n<=0;
            mrx_data_valid<=0;
          end else nextstate<=IDLE;
        end
        ACTIVE:begin
          
          if (mtx_counter==18 && mrx_counter==18)begin     				//change it with gates
            nextstate<=IDLE;
            master_out <=mrx_buffer;				 //----changed
             mtx_counter<=0;
             mrx_counter<=0;
            mrx_data_valid<=1;
          end else begin
            nextstate<=ACTIVE;
          end
        end
      endcase
    end
    
  end
endmodule
            
          
          
    
      
