//Test Case1: mode=00 clock_speed=00 spi_multi_slave configuration under full write and full read in two slaves alternatively (write - ram1, write - ram2, read - ram1, read - ram2)


class write_address;			//odd addresses
  rand bit [15:0] waddr;
  constraint c1{
    waddr inside {[0:500]};
    waddr %2==1;}
endclass

class write_data;				//even data, under 500
  rand bit [15:0] wdata;
  constraint c1{
    wdata inside {[0:500]};
    wdata %2==0;}
endclass

module spi_full_duplex_tb();
 
  logic sys_clock;
  logic reset_n;
  logic [1:0]spi_mode;
  logic tx_enable;
  logic [17:0]data_in;
  logic [1:0]clock_speed;
 
  integer j,k,rd_addr_ptr,rd_data_ptr;
  integer counter=0;
  
  reg [15:0] waddr_checker_array [0:1][0:9];
  reg [15:0] wdata_checker_array [0:1][0:9];
  reg [15:0] rdata_checker_array [0:1][0:9];
  reg init;
 
  logic [17:0] master_out; //output of master
  logic cs;
  logic mrx_data_valid;
  
  //-----------creating objects-----------
  write_address obj1 = new();
  write_data obj2=new();
  
  //----------port mapping----------------
  spi_full_duplex dut(
    .sys_clock(sys_clock),
    .reset_n(reset_n),
    .spi_mode(spi_mode),
    .cs(cs),
    .tx_enable(tx_enable),
    .data_in(data_in),
    .clock_speed(clock_speed),   
    .master_out(master_out),
    .mrx_data_valid(mrx_data_valid)
  );
  
  //----------port mapping----------------
  always #10 sys_clock = ~sys_clock;
  
  //----------initialization----------------
  initial begin
   sys_clock = 0;
   reset_n = 0;
   tx_enable = 0;
   data_in = 18'b0;
   clock_speed = 2'b00;
   spi_mode = 2'b00; 
   init=0;
   #2;
   reset_n = 1;
   init =1;
  end
  
  initial begin
    #2;
    j=0;
    k=0;
    rd_addr_ptr=0;
    cs=0;
    counter=0;
    write_ram();							//write to ram1
    
    
    #2000;
    init =1; 
    j=0;
    k=0;
    rd_addr_ptr=0;
    cs=1;
    write_ram();							//write to ram2
    
    #2000;
    init =1; 
    j=0;
    k=0;
    rd_addr_ptr=0;
    cs=0;
    read_ram();								//read from ram1
    
    #2000;
    init =1; 
    j=0;
    k=0;
    rd_addr_ptr=0;
    cs=1;
    read_ram();								//read from ram2
    
   end

  task write_ram();
    $display("writing in ram ->%0d",cs+1);
    repeat(20)begin							//write 10 time(10 address + 10 data)
      if(init) begin						//first cycle is triggered by init signal
        init=0;
        if (counter==0)begin
          obj1.randomize();
          data_in={2'b00,obj1.waddr};
          waddr_checker_array[cs][j]=obj1.waddr;
          j++;
          counter++;
          #5;
          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
      
        end else if (counter==1) begin
          obj2.randomize();
          data_in={2'b01,obj2.wdata};
          wdata_checker_array[cs][k]=obj2.wdata;
          k++;
          counter=0;
          #5;
          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
        end
        
      end else begin
        @(posedge mrx_data_valid);			//write based on mrx_data_valid generated from the init trigger
        if (counter==0)begin
          obj1.randomize();
          data_in={2'b00,obj1.waddr};
          waddr_checker_array[cs][j]=obj1.waddr;
          j++;
          counter++;
          #5;
          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
      
        end else if (counter==1) begin
          obj2.randomize();
          data_in={2'b01,obj2.wdata};
          wdata_checker_array[cs][k]=obj2.wdata;
          k++;
          counter=0;
          #5;
          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
        end
      end
      
    end
  endtask
     
  
  task read_ram();
    $display("reading from ram ->%0d",cs+1);
    repeat(22)begin							//read 10 time(10 address + 10 data+2 extra cycles for the )last data
      if(init) begin						//first cycle is triggered by init signal
        init=0;
        if (counter==0)begin				
          data_in={2'b10,waddr_checker_array[cs][rd_addr_ptr]};
          rd_addr_ptr++;
          counter++;
          #5;
          init=0;
          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
        end else if (counter==1)begin
          if(rd_addr_ptr>1)
            rdata_checker_array[cs][rd_addr_ptr-2]=master_out;
          data_in={2'b11,16'b0};
          counter=0;
          #5;
          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
        end
        
      end else begin
        @(posedge mrx_data_valid)				//write based on mrx_data_valid generated from the init trigger
        if (counter==0)begin	
          if(rd_addr_ptr>=10)					//send dummy read signal for last 2 cycles
            data_in={2'b10,16'b0};
          else
            data_in={2'b10,waddr_checker_array[cs][rd_addr_ptr]};
          rd_addr_ptr++;
          counter++;
          #5;
          init=0;
          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
        end else if (counter==1)begin
          if(rd_addr_ptr>1)
            rdata_checker_array[cs][rd_addr_ptr-2]=master_out;
          if(rd_addr_ptr>10)					//send dummy read signal for last 2 cycles
            data_in={2'b10,16'b0};
          else
            data_in={2'b11,16'b0};
          counter=0;
          #5;
          tx_enable =1; //master( fromcontroller)
          #15;
          tx_enable=0;
          
          
        end
      end
      
    end
  endtask
  
  //-------------------------------------------------------------------
  initial begin
    $dumpfile("madan.vcd");
    $dumpvars;
     #70000 ;
    

    //----------------------------write data check--------------------------------
    $display("\n-----------------WRITE DATA TEST--------------------");
    for (int i=0;i<$size(waddr_checker_array[0]);i++)begin
      if (dut.ram1.mem[waddr_checker_array[0][i]]==wdata_checker_array[0][i])begin
        $display( " RAM1 [ IDX ADDR - %0h ] = %0h , EXPECTED DATA @ SAME ADDRESS =%0h WRITE TEST PASS !",waddr_checker_array[0][i],dut.ram1.mem[waddr_checker_array[0][i]],wdata_checker_array[0][i]);
      end
      else begin
        $display(" RAM1 [ IDX ADDR - %0h ] = %0h , EXPECTED DATA @ SAME ADDRESS =%0h WRITE TEST FAIL !",waddr_checker_array[0][i],dut.ram1.mem[waddr_checker_array[0][i]],wdata_checker_array[0][i]);
      end
    end
    
    for (int i=0;i<$size(waddr_checker_array[1]);i++)begin
      if (dut.ram2.mem[waddr_checker_array[1][i]]==wdata_checker_array[1][i])begin
        $display( " RAM2 [ IDX ADDR - %0h ] = %0h , EXPECTED DATA @ SAME ADDRESS =%0h WRITE TEST PASS !",waddr_checker_array[1][i],dut.ram2.mem[waddr_checker_array[1][i]],wdata_checker_array[1][i]);
      end
      else begin
        $display(" RAM2 [ IDX ADDR - %0h ] = %0h , EXPECTED DATA @ SAME ADDRESS =%0h WRITE TEST FAIL !",waddr_checker_array[1][i],dut.ram2.mem[waddr_checker_array[1][i]],wdata_checker_array[1][i]);
      end
    end
    
    //----------------------------read data check--------------------------------
    $display("\n-----------------READ DATA TEST--------------------");
    for (int i=0;i<$size(rdata_checker_array[0]);i++)begin
      if (rdata_checker_array[0][i]==wdata_checker_array[0][i])begin
        $display( " RAM1 DATA IN MEM = %0h , DATA OBTAINED WHILE READING = %0h READ TEST PASS !",wdata_checker_array[0][i],rdata_checker_array[0][i]);
      end
      else begin
        $display( " RAM1 DATA IN MEM = %0h , DATA OBTAINED WHILE READING = %0h READ TEST FAIL !",wdata_checker_array[0][i],rdata_checker_array[0][i]);
      end
    end
    
    for (int i=0;i<$size(rdata_checker_array[1]);i++)begin
      if (rdata_checker_array[1][i]==wdata_checker_array[1][i])begin
        $display( " RAM2 DATA IN MEM = %0h , DATA OBTAINED WHILE READING = %0h READ TEST PASS !",wdata_checker_array[1][i],rdata_checker_array[1][i]);
      end
      else begin
        $display( " RAM2 DATA IN MEM = %0h , DATA OBTAINED WHILE READING = %0h READ TEST FAIL !",wdata_checker_array[1][i],rdata_checker_array[1][i]);
      end
    end
    
    $display("ram 1 ->%p",dut.ram1.mem);
    $display("ram 2 ->%p",dut.ram2.mem);
      $finish;  
  end
 
  
endmodule
  
