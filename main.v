
module testbench;
  
  reg CLK,A,B,R,AT,BT;
  wire LA,LB;
  wire[3:0]AL,AH;
  
  FSM main(CLK,A,B,R,AT,BT,AL,AH,LA,LB);
  
  initial 
    begin
      
      $monitor("CLK=%1b OUT = %2d %2d  LIGHT A(%1b) B(%1b)  \n",CLK,AH,AL,LA,LB);
      
      AT = 0;
      BT = 0;
      A = 0;
      B = 0;
      R = 0;
      CLK = 0;
      //Simulate Clock
      repeat(30)
        #5 CLK = ~CLK;
        
      #5 AT = 1;
      
      repeat(1000)
        #5 CLK = ~CLK;
    end
endmodule


module counter10(CLK,cnt,reset,out,ack);
  input CLK,cnt,reset;
  output [3:0]out;
  output ack;
  reg [3:0]out;
  reg ack;
  
initial
  begin
    out[3:0] = 0;
    ack = 0;
  end
  
always @ (reset) // Asyncronous Reset
  if(reset)
    out[3:0] = 0;
  
always @ (negedge CLK)
    ack = 0;
  
always @ (posedge CLK)
  if(cnt) 
    begin
      out[3:0] = out[3:0] + 1;
      if(out[3:0] == 10)
        begin
          out[3:0] = 0;
          ack = 1;
        end
    end
  
endmodule


module counter5(CLK,cnt,reset,out,ack);
  input CLK,cnt,reset;
  output [3:0]out;
  output ack;
  reg [3:0]out;
  reg ack;
  
initial
  begin
    out[3:0] = 0;
    ack = 0;
  end
  
always @ (reset) // Asyncronous Reset
  if(reset)
    out[3:0] = 0;
  
always @ (negedge CLK)
    ack = 0;
  
always @ (posedge CLK)
  if(cnt) 
    begin
      out[3:0] = out[3:0] + 1;
      if(out[3:0] == 5)
        begin
          out[3:0] = 0;
          ack = 1;
        end
    end
  
endmodule


module FSM(CLK,A,B,R,ATrf,BTrf,AL,AH,ALight,BLight);
  input CLK,A,B,R,ATrf,BTrf;
  output [3:0]AL,AH;
  output ALight,BLight;
  
  wire dummy; // Not Connected Wire
  parameter S0 = 0 , S1 = 1 , S2 = 2 , S3 = 3 , P0 = 4 , P1 = 5;  //Labels for States
  reg [0:3]curState , nextState;
  
  wire [3:0]AL,AH,D,T;
  reg ALight , BLight;
  reg CEnable, DEnable, TEnable;
  reg CReset, DReset, TReset;
  
  //Main Counter
  wire C2Enable;
  counter10 LC(CLK,CEnable,CReset,AL,C2Enable);
  counter10 HC(CLK,C2Enable,CReset,AH,dummy);
  
  //Yellow Light 
  wire DFinish;
  counter5 DC(CLK,DEnable,DReset,D,DFinish);
  
  //Traffic Control
  wire TOverride;
  counter5 TO(CLK,TEnable,TReset,T,TOverride);
  
initial
  begin
    CEnable = 1;
    DEnable = 0;
    TEnable = 1;
    
    curState = S0;
    nextState = S0;
    
    ALight = 1;
    BLight = 0;  
  end
  
always @ (negedge CLK)
  begin
    CReset = 0;
    DReset = 0;
    TReset = 0;
  end
     
always @ (posedge CLK)
  begin
    curState = nextState;
    
    //Check Traffic Condition
    if(!((curState == S0 && !ATrf && BTrf) || (curState == S2 && ATrf && !BTrf)))
      TReset = 1;
      
  end
  
always @ (AH or DFinish or A or B or R or TOverride)
  case(curState)
    S0 :
      begin
        if(A)
          begin
            CEnable = 0;
            CReset = 1;
            ALight = 1;
            BLight = 0;
            
            nextState = P0;
          end
        else if(B)
          begin
            CEnable = 0;
            CReset = 1;
            ALight = 0;
            BLight = 1;
            
            nextState = P1;
          end
        else if(R)
          begin
            CEnable = 1;
            DEnable = 0;  
            ALight = 1;
            BLight = 0;  
            nextState = S0;
          end
        else if((AH == 9 && AL == 0) || TOverride)
          begin
            CEnable = 0;
            CReset = 1;
            DEnable = 1;
            ALight = 0;
            BLight = 0;
            
            nextState = S1;
          end
      end
    S1 :
      begin
        if(A)
          begin
            DEnable = 0;
            DReset = 1;
            ALight = 1;
            BLight = 0;
            
            nextState = P0;
          end
        else if(B)
          begin
            DEnable = 0;
            DReset = 1;
            ALight = 0;
            BLight = 1;
            
            nextState = P1;
          end
        else if(R)
          begin
            CEnable = 1;
            DEnable = 0;  
            ALight = 1;
            BLight = 0;  
            nextState = S0;
          end
        else if(DFinish)
          begin
            CEnable = 1;
            DEnable = 0;
            ALight = 0;
            BLight = 1;
            
            nextState = S2;
          end
      end
    S2 :
      begin
        if(A)
          begin
            CEnable = 0;
            CReset = 1;
            ALight = 1;
            BLight = 0;
            
            nextState = P0;
          end
        else if(B)
          begin
            CEnable = 0;
            CReset = 1;
            ALight = 0;
            BLight = 1;
            
            nextState = P1;
          end
        else if(R)
          begin
            CEnable = 1;
            DEnable = 0;  
            ALight = 1;
            BLight = 0;  
            nextState = S0;
          end
        else if((AH == 3 && AL == 0) || TOverride)
          begin
            CEnable = 0;
            CReset = 1;
            DEnable = 1;
            ALight = 0;
            BLight = 0;
            
            nextState = S3;
          end
      end
    S3 :
      begin
        if(A)
          begin
            DEnable = 0;
            DReset = 1;
            ALight = 1;
            BLight = 0;
            
            nextState = P0;
          end
        else if(B)
          begin
            DEnable = 0;
            DReset = 1;
            ALight = 0;
            BLight = 1;
            
            nextState = P1;
          end
        else if(R)
          begin
            CEnable = 1;
            DEnable = 0;  
            ALight = 1;
            BLight = 0;  
            nextState = S0;
          end
        else if(DFinish)
          begin
            CEnable = 1;
            DEnable = 0;
            ALight = 1;
            BLight = 0;
            
            nextState = S0;
          end
      end
    P0:
      begin
        if(B)
          begin
            ALight = 0;
            BLight = 1;
            
            nextState = P1;
          end
        else if(R)
          begin
            CEnable = 1;
            DEnable = 0;  
            ALight = 1;
            BLight = 0;  
            nextState = S0;
          end
      end
    P1:
      begin
        if(A)
          begin
            ALight = 1;
            BLight = 0;
            
            nextState = P0;
          end
        else if(R)
          begin
            CEnable = 1;
            DEnable = 0;  
            ALight = 1;
            BLight = 0;  
            nextState = S0;
          end
      end
      
  endcase
  
endmodule  




