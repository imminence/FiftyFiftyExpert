//+------------------------------------------------------------------+
//|                                                 AreaFiftyOne.mq4 |
//|                                                           VBApps |
//|                                                 http://vbapps.co |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2017 VBApps::Valeri Balachnin"
#property link      "http://vbapps.co"
#property version   "1.1"
#property description "Trades on oversold or overbought market till the next signal."
#property strict

#resource "\\Indicators\\AreaFiftyOneIndicator.ex4"

//#include <mql4-http.mqh>

#define HEXCHAR_TO_DECCHAR(h)  (h<=57 ? (h-48) : (h-55))

//--- input parameters
extern double   LotSize=0.01;
extern bool     LotAutoSize=true;
extern int      RiskPercent=50;
extern int      TrailingStep=50;
extern int      DistanceStep=50;
extern int      MagicNumber=3537;
extern int      TakeProfit=750;
extern int      StopLoss=0;
//extern string   Licence="1F038D55F0BC3648B93112B3E26D4F23A5794A1C2EB0FC14";

int RSI_Period=13;         //8-25
int RSI_Price=5;           //0-6
int Volatility_Band=34;    //20-40
int RSI_Price_Line=0;
int RSI_Price_Type=MODE_SMA;      //0-3
int Trade_Signal_Line=7;
int Trade_Signal_Line2=18;
int Trade_Signal_Type=MODE_SMA;   //0-3
int Slippage=3,MaxOrders=6,BreakEven=0;
int TicketNrPendingSell=0,TicketNrPendingSell2=0,TicketNrSell=0;
int TicketNrPendingBuy=0,TicketNrPendingBuy2=0,TicketNrBuy=0;
bool AddPositions=false;
double TP=TakeProfit,SL=StopLoss;
double SLI=0,TPI=0;
string EAName="AreaFiftyOne";
string IndicatorName="AreaFiftyOneIndicator";
/*licence*/
bool trial_lic=false;
datetime expiryDate=D'2017.04.27 00:00';
/*licence_end*/
bool WrongDirectionBuy=false,WrongDirectionSell=false;
int WrongDirectionBuyTicketNr=0,WrongDirectionSellTicketNr=0;
int handle_ind;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(trial_lic)
     {
      if(TimeCurrent()>expiryDate)
        {
         Alert("Expired copy. Please contact vendor.");
         return(INIT_FAILED);
           } else {
         ObjectCreate("TrialVersion",OBJ_LABEL,0,0,0);
         ObjectSetText("TrialVersion","End of a trial period: "+TimeToStr(expiryDate),11,"Calibri",clrAqua);
         ObjectSet("TrialVersion",OBJPROP_CORNER,0);
         ObjectSet("TrialVersion",OBJPROP_XDISTANCE,5);
         ObjectSet("TrialVersion",OBJPROP_YDISTANCE,5);
        }
     }
//Print(getComputerName());
/* uchar src[56],dst[],key[];
   string keystr="OneFiftyArea";
   if(StringLen(Licence)>0)
     {
      HexToArray(Licence,src);
      StringToCharArray(keystr,key);
      int res=CryptDecode(CRYPT_DES,src,key,dst);
      if(res>0)
        {
         string result[];
         int k=StringSplit(CharArrayToString(dst),StringGetCharacter(";",0),result);
         for(int i=0;i<k;i++)
           {
            PrintFormat("result[%d]=%s",i,result[i]);
           }
        }
      else
         Print("Error in CryptDecode. Error code=",GetLastError());
        } else {
      Alert("Please add licence key to parameters!");
      return(INIT_FAILED);
     }*/
   handle_ind=iCustom(_Symbol,_Period,"::Indicators\\"+IndicatorName+".ex4",0,0);
   if(handle_ind==INVALID_HANDLE)
     {
      Print("Expert: iCustom call: Error code=",GetLastError());
      return(INIT_FAILED);
     }
/*else {PrintFormat("Indicator: iCustom value=%f",handle_ind);}*/
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int limit=1,err=0,BuyFlag=0,SellFlag=0;
   bool BUY=false,SELL=false;
   double TempTDIGreen=0,TempTDIRed=0;
   for(int i=1;i<=limit;i++)
     {
      //double TDIGreenPlusOne=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,4,i+1);
      double TDIGreen=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,4,i);
      double TDIYellow=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,2,i);
      //double TDIRedPlusOne=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,5,i+1);
      double TDIRed=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,5,i);
      // double TDIUp=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,1,i);
      // double TDIDown=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,3,i);
      // double TDIB3=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,6,i);

/* string TSRed=DoubleToStr(TDIRed);
      string TSGreen=DoubleToStr(TDIGreen);
      StringReplace(TSRed,".","");
      StringReplace(TSGreen,".","");
      int TRed=StrToInteger(TSRed);
      int TGreen=StrToInteger(TSGreen);*/
/*Print("*****************START");
      Print("TDIGreen="+NormalizeDouble(TDIGreen,3));
      Print("TDIRed="+NormalizeDouble(TDIRed,3));
      Print(TDIGreen>65.0);
      Print(TDIRed<35.0);
      Print(NormalizeDouble(TDIGreen,3)>NormalizeDouble(TDIRed,3));
      Print(NormalizeDouble(TDIGreen,3)<NormalizeDouble(TDIRed,3));
      Print(NormalizeDouble(NormalizeDouble(TDIRed,3)-NormalizeDouble(TDIGreen,3),1)>=3.5);
      Print(NormalizeDouble(NormalizeDouble(TDIGreen,3)-NormalizeDouble(TDIRed,3),1)>=3.5);
      Print("*****************END");*/
      if((TDIGreen>68) &&(NormalizeDouble(TDIGreen,3)>NormalizeDouble(TDIRed,3)) &&(NormalizeDouble(NormalizeDouble(TDIGreen,3)-NormalizeDouble(TDIRed,3),1)>=3.5)) SELL=true;
      if((TDIRed<32) && (NormalizeDouble(TDIGreen,3)<NormalizeDouble(TDIRed,3)) && (NormalizeDouble(NormalizeDouble(TDIRed,3)-NormalizeDouble(TDIGreen,3),1)>=3.5)) BUY=true;

      //if((SELL==false && BUY ==false) && (TDIRed>TDIGreen) && (TDIRedPlusOne<=TDIGreenPlusOne) && (TDIGreen-TDIRed)>=3.5)BUY=true;
      //if((SELL==false && BUY ==false) && (TDIRed<TDIGreen) && (TDIRedPlusOne>=TDIGreenPlusOne) && (TDIGreen-TDIRed)>=3.5)SELL=true;


/*if(TDIGreen-TDIRed<6){Print("NO Exit !");}*/
/*  if(TDIGreen-TDIRed>=6){Print("Change of Trend: If you have SELL Position(s),Check Exit Rules!");}
      if(TDIRed-TDIGreen>=6){Print("Change of Trend: If you have BUY Position(s),Check Exit Rules!");}*/
/*
TempTDIGreen=TDIGreen;
      TempTDIRed=TDIRed;*/
      //entry conditions
      if(BUY==true){BuyFlag=1;break;}
      if(SELL==true){SellFlag=1;break;}
     }
//risk management
   if(LotAutoSize)
     {
      int Faktor=100;
      if(RiskPercent<0.1 || RiskPercent>100){Comment("Invalid Risk Value.");}
      else
        {
         if(Digits<3){Faktor=10;}else{Faktor=100;}
         LotSize=MathFloor((AccountFreeMargin()*AccountLeverage()*RiskPercent*Point*Faktor)/(Ask*MarketInfo(Symbol(),MODE_LOTSIZE)*
                           MarketInfo(Symbol(),MODE_MINLOT)))*MarketInfo(Symbol(),MODE_MINLOT);
         if(LotSize<MarketInfo(Symbol(),MODE_MINLOT)) LotSize=MarketInfo(Symbol(),MODE_MINLOT);
        }
     }
   if(LotAutoSize==false){LotSize=LotSize;}

//positions initialization
   int cnt=0,OP=0,OS=0,OB=0,CloseSell=0,OSC=0,OBC=0,CloseBuy=0;OP=0;
   for(cnt=0;cnt<OrdersTotal();cnt++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if((OrderType()==OP_SELL || OrderType()==OP_BUY) && OrderSymbol()==Symbol() && ((OrderMagicNumber()==MagicNumber)))
           {
            OP=OP+1;
            if(OrderType()==OP_SELL)OSC=OSC+1;
            if(OrderType()==OP_BUY)OBC=OBC+1;
           }
        }
     }
   if(OP>=1){OS=0;OB=0;}OB=0;OS=0;CloseBuy=0;CloseSell=0;

//entry conditions verification
   if(SellFlag>0){OS=1;OB=0;}if(BuyFlag>0){OB=1;OS=0;}

//conditions to close positions
/* if(SellFlag>0){CloseBuy=1;}
   if(BuyFlag>0){CloseSell=1;}
*/
/*for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if((OrderType()==OP_BUY || OrderType()==OP_BUYLIMIT) && OrderSymbol()==Symbol() && ((OrderMagicNumber()==MagicNumber) || MagicNumber==0))
        {
         if(CloseBuy==1)
           {
            OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,Red);
            for(int t=0;t<OrdersTotal();t++)
              {
               if(OrderType()==OP_BUYLIMIT && OrderSymbol()==Symbol() && ((OrderMagicNumber()==MagicNumber) || MagicNumber==0))
                 {
                  if(StringCompare(OrderComment(),EAName+"P1B")==0 || StringCompare(OrderComment(),EAName+"P2B")==0) OrderDelete(OrderTicket(),clrNONE);
                 }
              }
            TicketNr=0;
            TicketNrPending=0;
            TicketNrPending2=0;
            CurrentProfit(0);
           }
        }
      if((OrderType()==OP_SELL || OrderType()==OP_SELLLIMIT) && OrderSymbol()==Symbol() && ((OrderMagicNumber()==MagicNumber) || MagicNumber==0))
        {
         if(CloseSell==1)
           {
            OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Red);
            for(int k=0;k<OrdersTotal();k++)
              {
               if(OrderType()==OP_SELLLIMIT && OrderSymbol()==Symbol() && ((OrderMagicNumber()==MagicNumber) || MagicNumber==0))
                 {
                  if(StringCompare(OrderComment(),EAName+"P1S") || StringCompare(OrderComment(),EAName+"P2S")) OrderDelete(OrderTicket(),clrNONE);
                 }
              }
            TicketNr=0;
            TicketNrPending=0;
            TicketNrPending2=0;
            CurrentProfit(0);
           }
        }
     }*/

   for(cnt=0;cnt<OrdersHistoryTotal();cnt++)
     {
      if(OrderSelect(cnt,SELECT_BY_POS,MODE_HISTORY) && OrderSymbol()==Symbol() && 
         (TicketNrPendingSell>0 || TicketNrPendingSell2>0 || TicketNrPendingBuy>0 || TicketNrPendingBuy2>0) && 
         (OrderMagicNumber()==MagicNumber) && (OrderTicket()==TicketNrBuy || OrderTicket()==TicketNrSell))
        {
         bool foundS1=false,foundS2=false,foundB1=false,foundB2=false;
         for(int cnt0=0;cnt0<OrdersHistoryTotal();cnt0++)
           {
            if(WrongDirectionSellTicketNr>0 && WrongDirectionSellTicketNr==OrderTicket()){WrongDirectionSell=false;WrongDirectionSellTicketNr=0;}
            if(WrongDirectionBuyTicketNr>0  &&  WrongDirectionBuyTicketNr==OrderTicket()){WrongDirectionBuy=false;WrongDirectionBuyTicketNr=0;}
            if(OrderTicket()==TicketNrPendingSell) {foundS1=true;}
            if(OrderTicket()==TicketNrPendingSell2) {foundS2=true;}
            if(OrderTicket()==TicketNrPendingBuy) {foundB1=true;}
            if(OrderTicket()==TicketNrPendingBuy2) {foundB2=true;}

            if(foundS1==false && OrderTicket()==TicketNrSell && TicketNrPendingSell>0
               && getTicketCurrentType(TicketNrPendingSell)>-1 && getTicketCurrentType(TicketNrPendingSell)==3)
              {if(OrderDelete(TicketNrPendingSell,clrNONE)){/*bool delS;delS=OrderDelete(TicketNrPendingSell,clrNONE);*/TicketNrPendingSell=0;}};

            if(foundS2==false && OrderTicket()==TicketNrSell && TicketNrPendingSell2>0
               && getTicketCurrentType(TicketNrPendingSell2)>-1 && getTicketCurrentType(TicketNrPendingSell2)==3)
              {if(OrderDelete(TicketNrPendingSell2,clrNONE)){/*bool delS2;delS2=OrderDelete(TicketNrPendingSell2,clrNONE);*/TicketNrPendingSell2=0;}}

            if(foundB1==false && OrderTicket()==TicketNrBuy && TicketNrPendingBuy>0
               && getTicketCurrentType(TicketNrPendingBuy)>-1 && getTicketCurrentType(TicketNrPendingBuy)==2)
              {if(OrderDelete(TicketNrPendingBuy,clrNONE)){/*bool delB;delB=OrderDelete(TicketNrPendingBuy,clrNONE);*/TicketNrPendingBuy=0;}}

            if(foundB2==false && OrderTicket()==TicketNrBuy && TicketNrPendingBuy2>0
               && getTicketCurrentType(TicketNrPendingBuy2)>-1 && getTicketCurrentType(TicketNrPendingBuy2)==2)
              {if(OrderDelete(TicketNrPendingBuy2,clrNONE)){/*bool delB2;delB2=OrderDelete(TicketNrPendingBuy2,clrNONE);*/TicketNrPendingBuy2=0;}}
           }
        }
     }

   for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES)==true && (OrderType()==OP_BUY || OrderType()==OP_SELL) && (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && 
         ((TicketNrPendingSell>0 || (TicketNrPendingSell>0 && TicketNrPendingSell2>0)) || 
         (TicketNrPendingBuy>0 || (TicketNrPendingBuy>0 && TicketNrPendingBuy2>0))) && (TicketNrBuy>0 || TicketNrSell>0))
        {
         for(int c=0;c<OrdersTotal();c++)
           {
            if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES)==true)
              {
               double TempTP=NormalizeDouble(OrderTakeProfit(),Digits);
               if((OrderTicket()==TicketNrPendingSell && OrderType()==OP_SELL) || (OrderTicket()==TicketNrPendingSell2 && OrderType()==OP_SELL))
                 {
                  if((TicketNrSell>0) && (OrderSelect(TicketNrSell,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm;fm=OrderModify(TicketNrSell,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}
                  if((TicketNrPendingSell>0) && (OrderSelect(TicketNrPendingSell,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm1;fm1=OrderModify(TicketNrPendingSell,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}
                  if((TicketNrPendingSell2>0) && (OrderSelect(TicketNrPendingSell2,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm2;fm2=OrderModify(TicketNrPendingSell2,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}
                  WrongDirectionSell=true;
                  WrongDirectionSellTicketNr=TicketNrSell;
                  break;
                 }
              }
           }
         for(int f=0;f<OrdersTotal();f++)
           {
            if(OrderSelect(f,SELECT_BY_POS,MODE_TRADES)==true)
              {
               double TempTP=NormalizeDouble(OrderTakeProfit(),Digits);
               if((OrderTicket()==TicketNrPendingBuy && OrderType()==OP_BUY) || (OrderTicket()==TicketNrPendingBuy2 && OrderType()==OP_BUY))
                 {
                  if((TicketNrBuy>0) && (OrderSelect(TicketNrBuy,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm;fm=OrderModify(TicketNrBuy,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}
                  if((TicketNrPendingBuy>0) && (OrderSelect(TicketNrPendingBuy,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm1;fm1=OrderModify(TicketNrPendingBuy,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}
                  if((TicketNrPendingBuy2>0) && (OrderSelect(TicketNrPendingBuy2,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm2;fm2=OrderModify(TicketNrPendingBuy2,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}
                  WrongDirectionBuy=true;
                  WrongDirectionBuyTicketNr=TicketNrBuy;
                  break;
                 }
              }
           }
        }

     }

/*for(cnt=0;cnt<OrdersTotal();cnt++)
     {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
       if((OrderType()==OP_BUY || OrderType()==OP_SELL) && (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) && 
         ((TicketNrPendingSell>0 || (TicketNrPendingSell>0 && TicketNrPendingSell2>0)) || 
         (TicketNrPendingBuy>0 || (TicketNrPendingBuy>0 && TicketNrPendingBuy2>0))) && (TicketNrBuy>0 || TicketNrSell>0)) {
         
         }
      }*/

//open position
   if((AddP() && AddPositions && OP<=MaxOrders) || (OP<=MaxOrders && !AddPositions))
     {
      // && TempTDIGreen>RSI_Top_Value && (TempTDIGreen-TempTDIRed)>=3.5
      if(OS==1 && OSC==0 && (!(AccountFreeMarginCheck(Symbol(),OP_SELL,LotSize*3)<=0 || GetLastError()==134)))
        {
         if(TP==0)TPI=0;else TPI=Bid-TP*Point;if(SL==0)SLI=0;else SLI=Bid+SL*Point;
         TicketNrSell=OrderSend(Symbol(),OP_SELL,LotSize,Bid,Slippage,SLI,TPI,EAName,MagicNumber,0,Red);OS=0;
         //if(TicketNr==-1)OrderSend(Symbol(),OP_SELL,LotSize,Bid,Slippage,SLI,TPI,EAName,MagicNumber,0,Red);
         double TempPendingLotSize=NormalizeDouble(LotSize*0.625,Digits);
         if(TempPendingLotSize<MarketInfo(Symbol(),MODE_MINLOT))TempPendingLotSize=MarketInfo(Symbol(),MODE_MINLOT);
         if(TicketNrPendingSell==0)TicketNrPendingSell=OrderSend(Symbol(),OP_SELLLIMIT,TempPendingLotSize,Bid+TP/2*Point,Slippage,0,Bid,EAName+"P1S",MagicNumber,0,Red);
         //if(TicketNrPending==-1)OrderSend(Symbol(),OP_SELLLIMIT,TempPendingLotSize,Bid+TP/2*Point,Slippage,SLI,Bid,EAName+"P1S",MagicNumber,0,Red);

         double TempPendingLotSize2=NormalizeDouble(LotSize*0.5,Digits);
         if(TempPendingLotSize2<MarketInfo(Symbol(),MODE_MINLOT))TempPendingLotSize2=MarketInfo(Symbol(),MODE_MINLOT);
         if(TicketNrPendingSell2==0)TicketNrPendingSell2=OrderSend(Symbol(),OP_SELLLIMIT,TempPendingLotSize2,Bid+TP/1*Point,Slippage,0,Bid,EAName+"P2S",MagicNumber,0,Red);
         // if(TicketNrPending2==-1)OrderSend(Symbol(),OP_SELLLIMIT,TempPendingLotSize2,Bid+TP*Point,Slippage,SLI,Bid,EAName+"P2S",MagicNumber,0,Red);
        }
      // && TempTDIGreen<RSI_Down_Value && (TempTDIGreen-TempTDIRed)>=3.5
      if(OB==1 && OBC==0 && (!(AccountFreeMarginCheck(Symbol(),OP_BUY,LotSize*3)<=0 || GetLastError()==134)))
        {
         if(TP==0)TPI=0;else TPI=Ask+TP*Point;if(SL==0)SLI=0;else SLI=Ask-SL*Point;
         TicketNrBuy=OrderSend(Symbol(),OP_BUY,LotSize,Ask,Slippage,SLI,TPI,EAName,MagicNumber,0,Lime);OB=0;
         //if(TicketNr==-1)OrderSend(Symbol(),OP_BUY,LotSize,Ask,Slippage,SLI,TPI,EAName,MagicNumber,0,Lime);

         double TempPendingLotSize=NormalizeDouble(LotSize*0.625,Digits);
         if(TempPendingLotSize<MarketInfo(Symbol(),MODE_MINLOT))TempPendingLotSize=MarketInfo(Symbol(),MODE_MINLOT);
         if(TicketNrPendingBuy==0)TicketNrPendingBuy=OrderSend(Symbol(),OP_BUYLIMIT,TempPendingLotSize,Ask-TP/2*Point,Slippage,0,Ask,EAName+"P1B",MagicNumber,0,Red);
         //if(TicketNrPending==-1)OrderSend(Symbol(),OP_BUYLIMIT,TempPendingLotSize,Bid-TP/2*Point,Slippage,SLI,Bid,EAName+"P1B",MagicNumber,0,Red);

         double TempPendingLotSize2=NormalizeDouble(LotSize*0.5,Digits);
         if(TempPendingLotSize2<MarketInfo(Symbol(),MODE_MINLOT))TempPendingLotSize2=MarketInfo(Symbol(),MODE_MINLOT);
         if(TicketNrPendingBuy2==0)TicketNrPendingBuy2=OrderSend(Symbol(),OP_BUYLIMIT,TempPendingLotSize2,Ask-TP/1*Point,Slippage,0,Ask,EAName+"P2B",MagicNumber,0,Red);
         //if(TicketNrPending2==-1)OrderSend(Symbol(),OP_BUYLIMIT,TempPendingLotSize2,Bid-TP*Point,Slippage,SLI,Bid,EAName+"P2B",MagicNumber,0,Red);
        }
     }
   double TempProfit=0;
   for(int j=0;j<OrdersTotal();j++)
     {
      if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==MagicNumber))
           {
            if(WrongDirectionBuy==true && OrderType()==OP_SELL){TrP();}
            else if(WrongDirectionSell==true && OrderType()==OP_BUY){TrP();}
            else if(WrongDirectionBuy==false && WrongDirectionSell==false){TrP();}
            TempProfit=TempProfit+OrderProfit();
           }
        }
     }
   CurrentProfit(TempProfit);

//not enough money message to continue the martingale
   if((TicketNrBuy<0 || TicketNrSell) && GetLastError()==134){err=1;Print("NOT ENOGUGHT MONEY!!");}
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
//add positions function
bool AddP()
  {
   int _num=0; int _ot=0;
   for(int j=0;j<OrdersTotal();j++)
     {
      if(OrderSelect(j,SELECT_BY_POS)==true && OrderSymbol()==Symbol() && OrderType()<3 && (OrderMagicNumber()==MagicNumber))
        {
         _num++;if(OrderOpenTime()>_ot) _ot=OrderOpenTime();
        }
     }
   if(_num==0) return(true);if(_num>0 && ((Time[0]-_ot))>0) return(true);else return(false);
  }
//trailing stop and breakeven
void TrP()
  {
   int BE=BreakEven;int TS=DistanceStep;double pb,pa,pp;pp=MarketInfo(OrderSymbol(),MODE_POINT);
   if(OrderType()==OP_BUY)
     {
      pb=MarketInfo(OrderSymbol(),MODE_BID);
      if(BE>0)
        {
         if((pb-OrderOpenPrice())>BE*pp)
           {
            if((OrderStopLoss()-OrderOpenPrice())<0)
              {
               ModSL(OrderOpenPrice()+0*pp);
              }
           }
        }
      if(TS>0)
        {
         if((pb-OrderOpenPrice())>TS*pp)
           {
            if(OrderStopLoss()<pb-(TS+TrailingStep-1)*pp)
              {
               ModSL(pb-TS*pp);return;
              }
           }
        }
     }
   if(OrderType()==OP_SELL)
     {
      pa=MarketInfo(OrderSymbol(),MODE_ASK);
      if(BE>0)
        {
         if((OrderOpenPrice()-pa)>BE*pp)
           {
            if((OrderOpenPrice()-OrderStopLoss())<0)
              {
               ModSL(OrderOpenPrice()-0*pp);
              }
           }
        }
      if(TS>0)
        {
         if(OrderOpenPrice()-pa>TS*pp)
           {
            if(OrderStopLoss()>pa+(TS+TrailingStep-1)*pp || OrderStopLoss()==0)
              {
               ModSL(pa+TS*pp);
               return;
              }
           }
        }
     }
  }
//stop loss modification function
void ModSL(double ldSL)
  {
   bool fm;fm=OrderModify(OrderTicket(),OrderOpenPrice(),ldSL,OrderTakeProfit(),0,CLR_NONE);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CurrentProfit(double CurProfit)
  {
   ObjectCreate("CurProfit",OBJ_LABEL,0,0,0);
   if(CurProfit>=0.0)
     {
      ObjectSetText("CurProfit","Current Profit: "+DoubleToString(CurProfit,2)+" "+AccountCurrency(),11,"Calibri",clrLime);
        }else{ObjectSetText("CurProfit","Current Profit: "+DoubleToString(CurProfit,2)+" "+AccountCurrency(),11,"Calibri",clrOrangeRed);
     }
   ObjectSet("CurProfit",OBJPROP_CORNER,0);
   ObjectSet("CurProfit",OBJPROP_XDISTANCE,5);
   ObjectSet("CurProfit",OBJPROP_YDISTANCE,30);

   ObjectCreate("MagicNumber",OBJ_LABEL,0,0,0);
   ObjectSetText("MagicNumber","MagicNumber: "+IntegerToString(MagicNumber),11,"Calibri",clrMediumVioletRed);
   ObjectSet("MagicNumber",OBJPROP_CORNER,0);
   ObjectSet("MagicNumber",OBJPROP_XDISTANCE,5);
   ObjectSet("MagicNumber",OBJPROP_YDISTANCE,45);
   if(trial_lic && TimeCurrent()>expiryDate) {ExpertRemove();}
  }
//+------------------------------------------------------------------+
int getTicketCurrentType(int TicketNr)
  {
   int res=-1;

   if(OrderSelect(TicketNr,SELECT_BY_TICKET,MODE_TRADES))
     {
      res=OrderType();
     }
   return res;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*bool HexToArray(string str,uchar &arr[])
  {
   int strcount = StringLen(str);
   int arrcount = ArraySize(arr);
   if(arrcount < strcount / 2) return false;

   uchar tc[];
   StringToCharArray(str,tc);

   int i=0, j=0;
   for(i=0; i<strcount; i+=2)
     {
      uchar tmpchr=(HEXCHAR_TO_DECCHAR(tc[i])<<4)+HEXCHAR_TO_DECCHAR(tc[i+1]);
      arr[j]=tmpchr;
      j++;
     }

   return true;
  }*/
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*uchar HexToDecimal(string hex)
  {
// assumes hex is 1 character
   if(!StringCompare(hex,"0"))
      return 0;
   if(!StringCompare(hex,"1"))
      return 1;
   if(!StringCompare(hex,"2"))
      return 2;
   if(!StringCompare(hex,"3"))
      return 3;
   if(!StringCompare(hex,"4"))
      return 4;
   if(!StringCompare(hex,"5"))
      return 5;
   if(!StringCompare(hex,"6"))
      return 6;
   if(!StringCompare(hex,"7"))
      return 7;
   if(!StringCompare(hex,"8"))
      return 8;
   if(!StringCompare(hex,"9"))
      return 9;
   if(!StringCompare(hex,"A"))
      return 10;
   if(!StringCompare(hex,"B"))
      return 11;
   if(!StringCompare(hex,"C"))
      return 12;
   if(!StringCompare(hex,"D"))
      return 13;
   if(!StringCompare(hex,"E"))
      return 14;
   if(!StringCompare(hex,"F"))
      return 15;
   return 0;
  }*/
//+------------------------------------------------------------------+
