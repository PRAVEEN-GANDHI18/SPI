module spi_full_duplex(
  input wire sys_clock,
  input wire reset_n,
  input wire [1:0]spi_mode,
  input wire cs,
  input wire tx_enable,
  input wire [17:0]data_in,
  input wire [1:0]clock_speed,
  
  //input wire [17:0]ram_data_in,
  //input wire tx_valid,
  
  output reg [17:0] master_out,	
  output reg mrx_data_valid //output of master
 // output reg [17:0] slave_out,			//output of slave 1 to RAM
 // output reg rx_valid
  
);
  
  wire miso;
  wire mosi;
  wire ss_n;
  wire ss_n1;
  wire ss_n2;
  wire sclk;
  wire [17:0]slave_out_to_ram1;
  wire rx_valid_slave_to_ram1;
  wire [17:0]data_from_ram_to_slave1;
  wire tx_valid_ram_to_slave1;
  wire [17:0]slave_out_to_ram2;
  wire rx_valid_slave_to_ram2;
  wire [17:0]data_from_ram_to_slave2;
  wire tx_valid_ram_to_slave2;

 spi_master master(
   .sys_clock(sys_clock),
   .reset_n(reset_n),
   .tx_enable(tx_enable),
   .data_in(data_in),
   .clock_speed(clock_speed),
   .spi_mode(spi_mode),
   .miso(miso),//serial
   .ss_n(ss_n),
   .mosi(mosi),//serial
   .sclk(sclk), //serial clock
   .master_out(master_out),
   .mrx_data_valid(mrx_data_valid)
);
  
  demux dmux(
    .a(ss_n),
    .select(cs),
    .x(ss_n1),
    .y(ss_n2)
  );
    
  multiplex mux(
    .miso1(miso1),
    .miso2(miso2),
    .cs(cs),
    .miso(miso)
  );
  
 spi_slave slave1(
  .sys_clock(sys_clock),
  .reset_n(reset_n),
  .spi_mode(spi_mode),
  .mosi(mosi),//serial
   .ram_data_in(data_from_ram_to_slave1),//from ram
   .ss_n(ss_n1), 
  .sclk(sclk), //serial clock
   .tx_valid(tx_valid_ram_to_slave1),
   .miso(miso1),//serial
   .slave_out(slave_out_to_ram1),
   .rx_valid(rx_valid_slave_to_ram1)
);
  
  
  ram_1kB ram1(
    .sys_clock(sys_clock),
    .reset_n(reset_n),
    .rx_valid(rx_valid_slave_to_ram1),
    .data_in(slave_out_to_ram1),
    .data_out(data_from_ram_to_slave1),
    .tx_valid(tx_valid_ram_to_slave1)
  );
  
  spi_slave slave2(
  .sys_clock(sys_clock),
  .reset_n(reset_n),
  .spi_mode(spi_mode),
  .mosi(mosi),//serial
    .ram_data_in(data_from_ram_to_slave2),//from ram
    .ss_n(ss_n2), 
  .sclk(sclk), //serial clock
    .tx_valid(tx_valid_ram_to_slave2),
    .miso(miso2),//serial
    .slave_out(slave_out_to_ram2),
    .rx_valid(rx_valid_slave_to_ram2)
);
 
  ram_1kB ram2(
    .sys_clock(sys_clock),
    .reset_n(reset_n),
    .rx_valid(rx_valid_slave_to_ram2),
    .data_in(slave_out_to_ram2),
    .data_out(data_from_ram_to_slave2),
    .tx_valid(tx_valid_ram_to_slave2)
  );
  
  
endmodule
  
