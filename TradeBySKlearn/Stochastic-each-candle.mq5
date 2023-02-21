//+------------------------------------------------------------------+
//|                                       Stochastic-Each-Candle.mq5 |
//|                                     Copyright 2023, Ramin Nadani |
//|                        https://www.mql5.com/ru/users/raminmadani |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Ramin Madani"
#property link      "https://www.mql5.com/ru/users/raminmadani"
#property version   "10.00"

#include <Trade\AccountInfo.mqh>
#include <TradeClass.mqh>
#include <Arrays\ArrayInt.mqh>


long magic = 0;
static datetime last_time=0;
int handle,handle1,handle2,handle3,handle4,handle5,handle6,handle7,handle8;
double iBuffer[5],iBuffer1[5],iBuffer2[5],iBuffer3[5],iBuffer4[5],iBuffer5[5],iBuffer6[5],iBuffer7[5],iBuffer8[5];
float lot=0.01;
int Tsignal;
input int      TPf=500;
input int      period = 14;
string adr2 = Symbol()+_Period+"min"+TPf+"TP.csv";
int state[9];

struct Agents{
   
   Trade             *ag;
};
Agents         agent[];
     


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
int OnInit() {
   setHandle();
   FileDelete(adr2,FILE_COMMON);
   return(INIT_SUCCEEDED);
  }
  

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   for(int i=0;i<magic; i++){
      delete agent[i].ag;}
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   for(int i=0;i<magic; i++){
      if(agent[i].ag.PositionTotal()==0 && agent[i].ag.order == 1){
         if(agent[i].ag.GetLastProfit() > 0){
               agent[i].ag.order = 0;
               fillCSV(agent[i].ag.State,  (1-agent[i].ag.GetLastOrderType()) ); 
         }else{fillCSV(agent[i].ag.State,    (agent[i].ag.GetLastOrderType()) ); 
              agent[i].ag.order = 0;
        }
     }
  }
   
   if (isNewBar(0)){
       ArrayResize(agent,magic+1);
       agent[magic].ag = new Trade(magic, TPf);
       GetState(agent[magic].ag.State);
       magic ++;
   }
}

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
  
void fillCSV(int &s[],int rightPosition){
   
   int Handle =FileOpen(adr2,FILE_COMMON|FILE_CSV|FILE_READ|FILE_WRITE,"\t", CP_UTF8);
   if(Handle!=INVALID_HANDLE)
     {
      //--- write array data to the end of the file
      FileSeek(Handle,0,SEEK_END);
      FileWrite(Handle,s[0],s[1],s[2],s[3],s[4],s[5],s[6],s[7],s[8],rightPosition);
      //--- close the file
      FileClose(Handle);
      }
   
}