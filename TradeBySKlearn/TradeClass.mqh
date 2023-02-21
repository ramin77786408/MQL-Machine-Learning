//+------------------------------------------------------------------+
//|                                                   TradeClass.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
#include <Random.mqh>
CRandom random;

class Trade 
{
  protected:
    long       ticket;
    
  public:
    int        magic_number;
    int        State[9];
    int        TPf;
    int        order;
    long       Buy(double); 
    long       Sell(double);
    int        PositionTotal();
    bool       PositionClosed();
    long       Ticket();
    void       fillCSV(string, int);
    double     GetLastProfit();
    int        GetLastOrderType();      
    int        CalcuteSignal();
    void       PlaceOrders(int); 
    double     LotsOptimized();
    float      lot;
    string     address;
               Trade(int, int);
               //~Trade(void);

  private:
    
    int        Tsignal;
    long       last_time;
    
};

Trade::Trade(int magic, int takeprofit){
   order = 0;
   lot   = 0.01;
   TPf   = takeprofit;
   last_time = TimeCurrent()-100;
   magic_number = magic;
   CalcuteSignal();
   PlaceOrders(Tsignal);
}

//Trade::~Trade() {
  
//}

long Trade::Buy(double lot){
   MqlTradeRequest request={};
   request.action=TRADE_ACTION_DEAL;                                     // setting a pending order
   request.symbol=_Symbol;                                               // symbol
   request.magic=magic_number;                                           // ORDER_MAGIC
   request.volume=lot;                                                   // volume in 0.1 lots
   request.sl=SymbolInfoDouble(_Symbol,SYMBOL_ASK)-TPf*Point();          // Stop Loss is not specified
   request.tp=SymbolInfoDouble(_Symbol,SYMBOL_ASK)+TPf*Point();          // Take Profit is not specified     
   request.type=0;                                                       // order type
   request.price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);                   // open price
//--- send a trade request
   MqlTradeResult result={0};
   OrderSend(request,result);
   ticket = result.deal;
   //Print("result : Buy", result.deal);
   return result.deal;
}

long Trade::Sell(double lot){  
   MqlTradeRequest request={};
   request.action=TRADE_ACTION_DEAL;                                     // setting a pending order
   request.symbol=_Symbol;                                               // symbol
   request.magic=magic_number;                                           // ORDER_MAGIC
   request.volume=lot;                                                   // volume in 0.1 lots
   request.sl=SymbolInfoDouble(_Symbol,SYMBOL_BID)+TPf*Point();          // Stop Loss is not specified
   request.tp=SymbolInfoDouble(_Symbol,SYMBOL_BID)-TPf*Point();          // Take Profit is not specified     
   request.type=1;                                                       // order type
   request.price=SymbolInfoDouble(_Symbol,SYMBOL_BID);                   // open price
//--- send a trade request
   MqlTradeResult result={0};
   OrderSend(request,result);
   ticket = result.deal;
   //Print("result : Sell", result.deal);
   return result.deal;
}
//+------------------------------------------------------------------+
//  Ticket of last position
//+------------------------------------------------------------------+
/*
long Trade::Ticket(){
   long deal_ticket; 
   long ticket;
   long lasttime=last_time;
   double lasprofit=0;
   //--- set the start and end date to request the history of deals
   datetime from_date=lasttime;         // from the very beginning
   datetime to_date=TimeCurrent();// till the current moment
   HistorySelect(from_date,to_date);
   for(int i=HistoryDealsTotal();i>=0;i--){
      deal_ticket=HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(deal_ticket,DEAL_MAGIC)== magic_number){
         if(HistoryDealGetInteger(deal_ticket,DEAL_TIME)>lasttime) {
            ticket=HistoryDealGetInteger(deal_ticket,DEAL_TICKET);
            lasttime = HistoryDealGetInteger(deal_ticket,DEAL_TIME);
         }
      }
   }
   return ticket;
}*/
//+------------------------------------------------------------------+
//  Number of this agent Positions
//+------------------------------------------------------------------+
int Trade::PositionTotal(){
   int number=0; 
   long ticket;
   for(int i=PositionsTotal();i>=0;i--){
      ticket=PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      if(PositionGetInteger(POSITION_MAGIC)== magic_number)   number++;
         
   }
   return number;
}
//+------------------------------------------------------------------+
//  when closed the position
//+------------------------------------------------------------------+
bool Trade::PositionClosed(){
   Print("position closed");
   return(! PositionSelectByTicket(ticket));
}
//+------------------------------------------------------------------+
//  fill CSV for each trade
//+------------------------------------------------------------------+
void Trade::fillCSV(string address,int rightPosition){  
   Print("fill csv");
   int Handle =FileOpen(address,FILE_COMMON|FILE_CSV|FILE_WRITE,"\t", CP_UTF8);
   if(Handle!=INVALID_HANDLE)
     {
      //--- write array data to the end of the file
      FileSeek(Handle,0,SEEK_END);
      FileWrite(Handle,State[0],State[1],State[2],State[3],State[4],State[5],State[6],State[7],State[8],rightPosition);
      //FileWriteArray(Handle,State,0,WHOLE_ARRAY);
      //--- close the file
      FileClose(Handle);
      }
   order = 0;
}
//+------------------------------------------------------------------+
//  Get Last Profit
//+------------------------------------------------------------------+
double Trade::GetLastProfit() {
   Print("get last profit");
   long deal_ticket; 
   long lasttime=last_time;
   double lasprofit=0;
   //--- set the start and end date to request the history of deals
   datetime from_date=lasttime;         // from the very beginning
   datetime to_date=TimeCurrent();// till the current moment
//--- request the history of deals in the specified period
   HistorySelect(from_date,to_date);
   for(int i=HistoryDealsTotal();i>=0;i--){
      deal_ticket=HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(deal_ticket,DEAL_MAGIC)== magic_number){
         if(HistoryDealGetInteger(deal_ticket,DEAL_TIME)>lasttime) {
            lasprofit=HistoryDealGetDouble(deal_ticket,DEAL_PROFIT);
            lasttime = HistoryDealGetInteger(deal_ticket,DEAL_TIME);
         }
      }
   }
   return(lasprofit);
 }
//+------------------------------------------------------------------+
//  Get Last Order Type
//+------------------------------------------------------------------+  
int Trade::GetLastOrderType() {
   Print("Getlast order type");
   ulong deal_ticket; 
   long lasttime=last_time;
   int type=0;
   //--- set the start and end date to request the history of deals
   datetime from_date=lasttime;         // from the very beginning
   datetime to_date=TimeCurrent();// till the current moment
//--- request the history of deals in the specified period
   HistorySelect(from_date,to_date);
   for(int i=HistoryDealsTotal();i>=0;i--){
      deal_ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(deal_ticket,DEAL_MAGIC)== magic_number){
         if(HistoryDealGetInteger(deal_ticket,DEAL_TIME)>lasttime)  {
            type = HistoryDealGetInteger(deal_ticket,DEAL_TYPE);
            lasttime = HistoryDealGetInteger(deal_ticket,DEAL_TIME);
         }
      }
   }  
   return(type);
}
//+------------------------------------------------------------------+
//| Calculate Tsignal                                                 |
//+------------------------------------------------------------------+
int Trade::CalcuteSignal() {
   Print("calcute signal");
   Tsignal = random.RandomInteger(0,2);
   return Tsignal;
  }
//+------------------------------------------------------------------+
//| Place orders                                                     |
//+------------------------------------------------------------------+
void Trade::PlaceOrders(int signal){
   Print("PlaceOrders");
   order = 1;
   if(signal==0)      Buy(lot);
   if(signal==1)      Sell(lot);
   if(signal==2)      Print("nothing to do!! Because of invalid signal");
  }
//+------------------------------------------------------------------+
//| Optimize lots                                                    |
//+------------------------------------------------------------------+
/*
double Trade::LotsOptimized() {
   
   lot=MathRound(AccountInfoDouble(ACCOUNT_BALANCE)/100);
   lot=lot/100;
   return(lot);
  }
*/

