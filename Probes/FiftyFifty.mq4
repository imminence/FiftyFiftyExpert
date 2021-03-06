//+------------------------------------------------------------------+
//|                                                   FiftyFifty.mq4 |
//|                                           Copyright 2017, VBApps |
//|                                     https://dax-trading-group.de |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, VBApps"
#property link      "https://dax-trading-group.de"
#property version   "1.00"
#property strict

extern bool SoundON=true;
extern bool EmailON=false;
//---- input parameters
extern int KPeriod=5;
extern int DPeriod=3;
extern int Slowing=3;
extern int MA_Method=2; // SMA 0, EMA 1, SMMA 2, LWMA 3
extern int PriceField=1; // Low/High 0, Close/Close 1
extern double LotSize=0.01;
extern bool AutomaticMode=false;
extern int AutoModeRiskPercent=5;
extern int MagicNumber=903;
extern int LevelForSell=85;
extern int LevelForBuy=15;
extern int IndicatorDiff=1;

int OrdersPerSymbol=0;
int ticketvbbuyplus3=0;
int ticketvbsellminus3=0;
int ticketvbsell85=0;
int ticketvbbuy15=0;
int flagval1 = 0;
int flagval2 = 0;
double minstoplevel=0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---  
   int cnt=0;
   double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
   for(cnt=OrdersTotal();cnt>=0;cnt--)
     {
      bool b=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && b)
        {
         OrdersPerSymbol++;
        }
     }
   double currAccFreeInProcent=100 -(AccountBalance()-AccountEquity())/100;
   double currAccMargin=AccountMargin();
   if(currAccMargin==0)
     {
      currAccMargin=1;
     }
   double MarginLevel=AccountFreeMargin()/currAccMargin*100;
   Print("MarginLevel: "+MarginLevel);
   Print("currAccFreeInProcent: "+currAccFreeInProcent);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ObjectsDeleteAll();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int limit,i,counter;
   double tmp=0;
   double fastMAnow,slowMAnow,fastMAprevious,slowMAprevious;
   double stoplossBuy=NormalizeDouble(Bid-250.0*Point-minstoplevel*Point,Digits);
   double takeprofitBuy=NormalizeDouble(Bid+500.0*Point+minstoplevel*Point,Digits);
   double stoplossSell=NormalizeDouble(Ask-250.0*Point-minstoplevel*Point,Digits);
   double takeprofitSell=NormalizeDouble(Ask+500.0*Point+minstoplevel*Point,Digits);

   limit=iBars(Symbol(),Period());

   for(i=1; i<=limit; i++) 
     {

      counter=i;

      fastMAnow=iStochastic(Symbol(),0,KPeriod,DPeriod,Slowing,MA_Method,PriceField,MODE_MAIN,i);
      fastMAprevious=iStochastic(Symbol(),0,KPeriod,DPeriod,Slowing,MA_Method,PriceField,MODE_MAIN,i+1);

      slowMAnow=iStochastic(Symbol(),0,KPeriod,DPeriod,Slowing,MA_Method,PriceField,MODE_SIGNAL,i);
      slowMAprevious=iStochastic(Symbol(),0,KPeriod,DPeriod,Slowing,MA_Method,PriceField,MODE_SIGNAL,i+1);

      if((fastMAnow>slowMAnow) && (fastMAprevious<slowMAprevious))
        {
         if(i==1 && flagval1==0)
           {
            flagval1=1;
            flagval2=0;
            if(SoundON) Print("BUY signal at Ask=",Ask,"\n Bid=",Bid,"\n Time=",TimeToStr(CurTime(),TIME_DATE)," ",TimeHour(CurTime()),":",TimeMinute(CurTime()),"\n Symbol=",Symbol()," Period=",Period());
            if(ticketvbsellminus3>0) 
              {
               OrderClose(ticketvbsellminus3,LotSize,Ask,3,Red);
              }
            ticketvbbuyplus3=OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,"vbbuyplus3",0,0,Blue);
            if(ticketvbbuyplus3<0)
              {
               Print("OrderSendBuy failed with error #",GetLastError());
              }
            else { Print("OrderSendBuyIndicator placed successfully");};
            if(EmailON) SendMail("BUY signal alert","BUY signal at Ask="+DoubleToStr(Ask,4)+", Bid="+DoubleToStr(Bid,4)+", Date="+TimeToStr(CurTime(),TIME_DATE)+" "+TimeHour(CurTime())+":"+TimeMinute(CurTime())+" Symbol="+Symbol()+" Period="+Period());
           }
        }
      else if((fastMAnow<slowMAnow) && (fastMAprevious>slowMAprevious))
        {
         if(i==1 && flagval2==0)
           {
            flagval2=1;
            flagval1=0;
            if(ticketvbbuyplus3>0) 
              {
               OrderClose(ticketvbbuyplus3,LotSize,Bid,3,Red);
              }
            ticketvbsellminus3=OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,"vbsellminus3",0,0,Blue);
            if(ticketvbsellminus3<0)
              {
               Print("OrderSendSell failed with error #",GetLastError());
                 }else {Print("OrderSendSellIndicator placed successfully");
              }
            if(SoundON) Print("SELL signal at Ask=",Ask,"\n Bid=",Bid,"\n Date=",TimeToStr(CurTime(),TIME_DATE)," ",TimeHour(CurTime()),":",TimeMinute(CurTime()),"\n Symbol=",Symbol()," Period=",Period());
            if(EmailON) SendMail("SELL signal alert","SELL signal at Ask="+DoubleToStr(Ask,4)+", Bid="+DoubleToStr(Bid,4)+", Date="+TimeToStr(CurTime(),TIME_DATE)+" "+TimeHour(CurTime())+":"+TimeMinute(CurTime())+" Symbol="+Symbol()+" Period="+Period());
           }
        }
     }

//Print(iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0));
//Print(iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0));
//Print(iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0)-iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0));

   double currAccFreeInProcent=100-(AccountBalance()-AccountEquity())/100;
   double currAccMargin=AccountMargin();
   if(currAccMargin==0)
     {
      currAccMargin=1;
     }
   double MarginLevel=AccountFreeMargin()/currAccMargin*100;
   int currStochMain=MathRound(NormalizeDouble(iStochastic(Symbol(),0,5,3,3,MODE_SMA,1,MODE_MAIN,0),0));
   int currStochSignal=MathRound(NormalizeDouble(iStochastic(Symbol(),0,5,3,3,MODE_SMA,1,MODE_SIGNAL,0),0));
//Print("StochMain: "+IntegerToString(currStochMain));
//Print("StochSignal: "+IntegerToString(currStochSignal));
//Print("MarginLevel:"+MarginLevel);
   int currentStochDiff=currStochMain-currStochSignal;
   if(currAccFreeInProcent>50 && (MarginLevel>200 || OrdersTotal()==0))
     {
      if(currentStochDiff>IndicatorDiff)
        {
         //Print("OpenBuyPlusDiff");
         if(CheckIfOrderExists("vbbuyplus3",ticketvbbuyplus3)==0)
           {
/*ticketvbbuyplus3=OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,"vbbuyplus3",0,0,Blue);
            if(ticketvbbuyplus3<0)
              {
               Print("OrderSendBuy failed with error #",GetLastError());
              }
            else { Print("OrderSendBuyIndicator placed successfully");};*/
           }
        }
      else if(currentStochDiff<-IndicatorDiff)
        {
         //Print("OpenSellMinusDiff");
/*if(CheckIfOrderExists("vbsellminus3",ticketvbsellminus3)==0)
           {
            ticketvbsellminus3=OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,"vbsellminus3",0,0,Blue);
            if(ticketvbsellminus3<0)
              {
               Print("OrderSendSell failed with error #",GetLastError());
                 }else {Print("OrderSendSellIndicator placed successfully");
              }
           }*/
        }

      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(MathRound(NormalizeDouble(iStochastic(Symbol(),0,5,3,3,MODE_SMA,1,MODE_MAIN,0),0))>LevelForSell)
        {
         //Print("OpenSell=> Stoch>"+IntegerToString(LevelForSell));
         if(CheckIfOrderExists("vbsell85",ticketvbsell85)==0)
           {
/*ticketvbsell85=OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,"vbsell85",0,0,Blue);
            if(ticketvbsell85<0)
              {
               Print("OrderSendSell failed with error #",GetLastError());
                 } else {Print("OrderSendSell placed successfully");
              }*/
           }
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      else if(MathRound(NormalizeDouble(iStochastic(Symbol(),0,5,3,3,MODE_SMA,1,MODE_MAIN,0),0))<LevelForBuy)
        {
         //Print("OpenBuy=> Stoch<"+IntegerToString(LevelForBuy));
         if(CheckIfOrderExists("vbbuy15",ticketvbbuy15)==0)
           {
/*ticketvbbuy15=OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,"vbbuy15",0,0,Blue);
            if(ticketvbbuy15<0)
              {
               Print("OrderSendBuy failed with error #",GetLastError());
              }
            else Print("OrderSendBuy placed successfully");*/
           }
        }

      int cnt=0;
      for(cnt=OrdersTotal();cnt>0;cnt--)
         //+------------------------------------------------------------------+
         //|                                                                  |
         //+------------------------------------------------------------------+
        {
         bool b=OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         //+------------------------------------------------------------------+
         //|                                                                  |
         //+------------------------------------------------------------------+
         if(b)
           {
            if(OrderSymbol()==Symbol())
              {
               if(OrderType()==OP_BUY)
                 {
                  //Print("OrderTicketBuy: "+OrderTicket()+"; OrderComment: "+OrderComment());
                  //if(SignalToClose()=="vbbuy15" && OrderComment()=="vbbuy15")
                  if(SignalToClose()=="vbbuy15")
                    {
                     OrderClose(OrderTicket(),LotSize,Bid,3,Red);
                    }
                  //if(SignalToClose()=="vbbuyplus3" && OrderComment()=="vbbuyplus3")
                  if(SignalToClose()=="vbbuyplus3")
                    {
                     OrderClose(OrderTicket(),LotSize,Bid,3,Red);
                    }
                 }
               if(OrderType()==OP_SELL)
                 {
                  //Print("OrderTicketSell: "+OrderTicket()+"; OrderComment: "+OrderComment());
                  if(SignalToClose()=="vbsell85")
                     //if(SignalToClose()=="vbsell85" && OrderComment()=="vbsell85")
                    {
                     OrderClose(OrderTicket(),LotSize,Ask,3,Red);
                    }
                  if(SignalToClose()=="vbsellminus3")
                     //if(SignalToClose()=="vbsellminus3" && OrderComment()=="vbsellminus3")
                    {
                     OrderClose(OrderTicket(),LotSize,Ask,3,Red);
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+

string SignalToClose()
  {
   string TypeToClose="";
   int currStochMain=MathRound(NormalizeDouble(iStochastic(Symbol(),0,5,3,3,MODE_SMA,1,MODE_MAIN,0),0));
   int currStochSignal=MathRound(NormalizeDouble(iStochastic(Symbol(),0,5,3,3,MODE_SMA,1,MODE_SIGNAL,0),0));
   int currentStochDiff=currStochMain-currStochSignal;
//Print("currentStochDiff: "+currentStochDiff);
//Print("currStochMain: "+currStochMain);
//Print("currStochSignal: "+currStochSignal);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(currStochMain>80)
     {
      TypeToClose="vbbuy15";
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(currStochMain<20)
     {
      TypeToClose="vbsell85";
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(currentStochDiff==0)
     {
      TypeToClose="vbsellminus3";
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(currentStochDiff==0)
     {
      TypeToClose="vbbuyplus3";
     }
   return TypeToClose;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CheckIfOrderExists(string MyOrderType,int TicketNumber)
  {

// schau die anzahl der orders
// wenn der order in der liste ist, dann gib eine 1 zurück,
// sinst gib eine 0 zurück
// sonderffall: wenn keine orders offen sind, gib auch eine 0 zurück

   int total=OrdersTotal();
   int res=1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(total==0)
     {
      res=0;
      //Print("Total Orders = 0");
        } else {
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      for(int pos=0;pos<total;pos++)
         //+------------------------------------------------------------------+
         //|                                                                  |
         //+------------------------------------------------------------------+
        {
         bool b=OrderSelect(pos,SELECT_BY_POS,MODE_TRADES);
         if(b)
           {
            if(OrderTicket()==TicketNumber)
              {
               res=1;
/*Print("OrderComment: "+OrderComment());
               Print("MyOrderType: "+MyOrderType);
               if(OrderComment()==MyOrderType)
                 {
                  res=1;*/
              }
            else
              {
               res=0;
              }
           }
         else
           {
            res=0;
           }

        }
     }
//}
   return res;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|   expert TotalOrdersCount function                               |
//+------------------------------------------------------------------+
int TotalOrdersCount()
  {
   int result=0;

   for(int i=0; i<OrdersTotal(); i++)
     {
      int MyOrderSelect=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderMagicNumber()==MagicNumber) result++;
     }

//---
   return (result);
  }
//-------------------------------------------------------------------+
