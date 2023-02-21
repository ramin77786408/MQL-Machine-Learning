//+------------------------------------------------------------------+
//|                                               SocketToPython.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

static datetime last_time=0;
int handle,handle1,handle2,handle3,handle4,handle5,handle6,handle7,handle8;
double iBuffer[5],iBuffer1[5],iBuffer2[5],iBuffer3[5],iBuffer4[5],iBuffer5[5],iBuffer6[5],iBuffer7[5],iBuffer8[5];

input int      period = 14;
int socket;
int State[9];
double lot  = 0.01;
int TPf     = 300;



void GetState(int &p[])
{
   double i[9];
 
   
   if(CopyBuffer(handle,0,0,5,iBuffer)!=5)return;
   i[0]=iBuffer[4];
   if(CopyBuffer(handle1,0,0,5,iBuffer1)!=5)return;
   i[1]=iBuffer1[4];
   if(CopyBuffer(handle2,0,0,5,iBuffer2)!=5)return;
   i[2]=iBuffer2[4];
   if(CopyBuffer(handle3,0,0,5,iBuffer3)!=5)return;
   i[3]=iBuffer3[4];
   if(CopyBuffer(handle4,0,0,5,iBuffer4)!=5)return;
   i[4]=iBuffer4[4];
   if(CopyBuffer(handle5,0,0,5,iBuffer5)!=5)return;
   i[5]=iBuffer5[4];
   if(CopyBuffer(handle6,0,0,5,iBuffer6)!=5)return;
   i[6]=iBuffer6[4];
   if(CopyBuffer(handle7,0,0,5,iBuffer7)!=5)return;
   i[7]=iBuffer7[4];
   if(CopyBuffer(handle8,0,0,5,iBuffer8)!=5)return;
   i[8]=iBuffer8[4];
  
   for(int g=0;g<9;g++){
      p[g] = int(i[g]);
      } 
     
}

void setHandle(){
    handle=iStochastic(Symbol(),PERIOD_M1,period,3,3,MODE_SMA,STO_CLOSECLOSE);
    ArraySetAsSeries(iBuffer,true);
    handle1=iStochastic(Symbol(),PERIOD_M5,period,3,3,MODE_SMA,STO_CLOSECLOSE);
    ArraySetAsSeries(iBuffer1,true);
    handle2=iStochastic(Symbol(),PERIOD_M10,period,3,3,MODE_SMA,STO_CLOSECLOSE);
    ArraySetAsSeries(iBuffer2,true);
    handle3=iStochastic(Symbol(),PERIOD_M15,period,3,3,MODE_SMA,STO_CLOSECLOSE);
    ArraySetAsSeries(iBuffer3,true);
    handle4=iStochastic(Symbol(),PERIOD_M30,period,3,3,MODE_SMA,STO_CLOSECLOSE);
    ArraySetAsSeries(iBuffer4,true);
    handle5=iStochastic(Symbol(),PERIOD_H1,period,3,3,MODE_SMA,STO_CLOSECLOSE);
    ArraySetAsSeries(iBuffer5,true);
    handle6=iStochastic(Symbol(),PERIOD_H4,period,3,3,MODE_SMA,STO_CLOSECLOSE);
    ArraySetAsSeries(iBuffer6,true);
    handle7=iStochastic(Symbol(),PERIOD_H8,period,3,3,MODE_SMA,STO_CLOSECLOSE);
    ArraySetAsSeries(iBuffer7,true);     
    handle8=iStochastic(Symbol(),PERIOD_D1,period,3,3,MODE_SMA,STO_CLOSECLOSE);
    ArraySetAsSeries(iBuffer8,true);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   setHandle();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      if(!isNewBar(0)) return;
      
      GetState(State);
      socket=SocketCreate();
      if(socket!=INVALID_HANDLE) {
        if(SocketConnect(socket,"localhost",9090,1000)) {
         Print("Connected to "," localhost",":",9090);
         string tosend;
         for(int i=0;i<ArraySize(State);i++) tosend+=(string)State[i]+" ";       
         string received = socksend(socket, tosend) ? socketreceive(socket, 10) : "100";  
         Print(received);
         if(received == '0') Buy();
         if(received == '1') Sell();
         
        }
         
        else Print("Connection ","localhost",":",9090," error ",GetLastError());
        SocketClose(socket); }
       else Print("Socket creation error ",GetLastError());
  }
//+------------------------------------------------------------------+

bool socksend(int sock,string request) 
  {
   char req[];
   int  len=StringToCharArray(request,req)-1;
   if(len<0) return(false);
   return(SocketSend(sock,req,len)==len); 
  }
  
//+------------------------------------------------------------------+ 
string socketreceive(int sock,int timeout)
  {
   char rsp[];
   string result="";
   uint len;
   uint timeout_check=GetTickCount()+timeout;
   do
     {
      len=SocketIsReadable(sock);
      if(len)
        {
         int rsp_len;
         rsp_len=SocketRead(sock,rsp,len,timeout);
         if(rsp_len>0) 
           {
            result+=CharArrayToString(rsp,0,rsp_len); 
           }
        }
     }
   while((GetTickCount()<timeout_check) && !IsStopped());
   return result;
  }
//+------------------------------------------------------------------+

bool isNewBar(int w) {
   datetime lastbar_time=datetime(SeriesInfoInteger(Symbol(),_Period,SERIES_LASTBAR_DATE) - w*60);
   if(last_time==0) {
      last_time=lastbar_time;
      return(false);
     }
   if(last_time<lastbar_time) {
      last_time=datetime(SeriesInfoInteger(Symbol(),_Period,SERIES_LASTBAR_DATE));
      return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------+

void Buy(){
   
   MqlTradeRequest request={};
   request.action=TRADE_ACTION_DEAL;            // setting a pending order
   request.magic=123000;                        // ORDER_MAGIC
   request.symbol=_Symbol;                      // symbol
   request.volume=lot;                          // volume in 0.1 lots
   request.sl=SymbolInfoDouble(_Symbol,SYMBOL_ASK)-TPf*Point();                                // Stop Loss is not specified
   request.tp=SymbolInfoDouble(_Symbol,SYMBOL_ASK)+TPf*Point();                                // Take Profit is not specified     
   request.type=0;                              // order type
   request.price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);                 // open price
//--- send a trade request
   MqlTradeResult result={0};
   OrderSend(request,result); 
   Print(result.deal);
   //Reward[number_of_sample] = reward;
}
//+------------------------------------------------------------------+
void Sell(){
   
   MqlTradeRequest request={};
   request.action=TRADE_ACTION_DEAL;            // setting a pending order
   request.magic=654000;                        // ORDER_MAGIC
   request.symbol=_Symbol;                      // symbol
   request.volume=lot;                          // volume in 0.1 lots
   request.sl=SymbolInfoDouble(_Symbol,SYMBOL_BID)+TPf*Point();                                // Stop Loss is not specified
   request.tp=SymbolInfoDouble(_Symbol,SYMBOL_BID)-TPf*Point();                                // Take Profit is not specified     
   request.type=1;                              // order type
   request.price=SymbolInfoDouble(_Symbol,SYMBOL_BID);                 // open price
//--- send a trade request
   MqlTradeResult result={0};
   OrderSend(request,result); 
   
   //Reward[number_of_sample] = reward;
}




//+------------------------------------------------------------------+