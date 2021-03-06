//+------------------------------------------------------------------+
//|                                                 AreaFiftyOne.mq4 |
//|                                                           VBApps |
//|                                                 http://vbapps.co |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2017 VBApps::Valeri Balachnin"
#property version   "3.48"
#property description "Trades on trend change with different indicators."
#property strict

#resource "\\Indicators\\AreaFiftyOneIndicator.ex4"
#resource "\\Indicators\\AreaFiftyOne_Trend.ex4"

#define SLIPPAGE              5
#define NO_ERROR              1
#define AT_LEAST_ONE_FAILED   2

#define ORDER_TYPE_BUY        OP_BUY
#define ORDER_TYPE_SELL       OP_SELL
#define ORDER_TYPE_BUY_LIMIT  OP_BUYLIMIT
#define ORDER_TYPE_SELL_LIMIT OP_SELLLIMIT
#define ORDER_TYPE_BUY_STOP   OP_BUYSTOP
#define ORDER_TYPE_SELL_STOP  OP_SELLSTOP

//--- input parameters
extern static string Trading="Base trading params";
extern double LotSize=0.01; // Lot size can be <0.10 in the free version
extern static string LotAutoSize_Comment="Available in the full version!";
extern static string LotRiskPercent_Comment="Available in the full version!";
extern static string MoneyRiskInPercent_Comment="Available in the full version!";
extern static string MaxDynamicLotSize_Comment="Available in the full version!";
extern static string MaxMoneyValueToLose_Comment="Available in the full version!";
bool     LotAutoSize=false;
int      LotRiskPercent=25;
int      MoneyRiskInPercent=0;
double   MaxDynamicLotSize=0.0;
int      MaxMoneyValueToLose=0;
extern static string TrailingStep_Comment="Available in the full version!";
extern static string DistanceStep_Comment="Available in the full version!";
extern static string Positions="Handle positions params";
int      TrailingStep=15;
int      DistanceStep=15;
extern int      TakeProfit=750;
extern int      StopLoss=0;
extern static string Indicators="Choose strategies";
extern static string TrendIndicatorStrategy="-------------------";
extern bool     UseTrendIndicator=false;
extern bool     UseSMAOnTrendIndicator=true;
extern int      UseOneOrTwoSMAOnTrendIndicator=1;
extern bool     UseSMAsCrossingOnTrendIndicatorData=false;
extern static string RSIBasedStrategy="-------------------";
extern bool     UseRSIBasedIndicator=false;
extern static string MACD_ADX_MA_Strategy="-------------------";
extern bool     UseSimpleTrendStrategy=false;
extern static string SimpleStochasticCrossingStrategy="-------------------";
extern bool     UseStochasticBasedStrategy=false;
extern static string ADX_RSI_MA_Strategy="-------------------";
extern bool     Use5050Strategy=false;
extern static string StochastiCroosingRSIStrategy="-------------------";
extern bool     UseStochRSICroosingStrategy=true;
bool     AllowPendings=false;
extern static string TimeSettings="Trading time";
extern static string StartHour_Comment="Available in the full versioin!";
extern static string EndHour_Comment="Available in the full versioin!";
int StartHour=0;
int EndHour=23;
extern static string OnlyBuyOrSellMarket="-------------------";
extern bool OnlyBuy=true;
extern bool OnlySell=true;
extern static string UserPositions="Handle user opened positions as a EA own";
extern static string HandleUserPositions_Comment="Available in the full version!";
bool     HandleUserPositions=false;
int  CountCharsInCommentToEscape=0;
extern static string SignalHandling="Create signals only on new candle or on every tick";
extern bool     HandleOnCandleOpenOnly=true;
//extern static string MaxOpenedPositionsOnCandle_Comment="Available in the full versioin!";
//int      MaxOpenedPositionsOnCandle=2;
extern static string MaxOrdersSettings="Creates position independently of opened positions";
extern bool     AddPositionsIndependently=false;
extern static string MaxConcurrentOpenedOrders_Comment="Available in the full versioin!";
int      MaxConcurrentOpenedOrders=4;
extern static string UsingEAOnDifferentTimeframes="-------------------";
extern int      MagicNumber=3537;

bool Debug=false;
bool DebugTrace=false;

/*licence*/
bool trial_lic=false;
datetime expiryDate=D'2017.06.17 00:00';
bool rent_lic=false;
datetime rentExpiryDate=D'2018.05.12 00:00';
int rentAccountNumber=0;
string rentCustomerName="";
/*licence_end*/

int RSI_Period=13;         //8-25
int RSI_Price=0;           //0-6
int Volatility_Band=34;    //20-40
int RSI_Price_Line=6;
int RSI_Price_Type=MODE_SMA;      //0-3
int Trade_Signal_Line=7;
int Trade_Signal_Line2=18;
int Trade_Signal_Type=MODE_SMA;   //0-3
int MAFastPeriod = 7;
int MASlowPeriod = 21;
int KPeriod1=21;
int DPeriod1=7;
int Slowing1=7;
int MAMethod1=0;
int PriceField1=0;
int ma_method=MODE_SMA;
int price_field=0;
int Slippage=3,BreakEven=0;
int TicketNrPendingSell=0,TicketNrPendingSell2=0,TicketNrSell=0;
int TicketNrPendingBuy=0,TicketNrPendingBuy2=0,TicketNrBuy=0;
double LotSizeP1,LotSizeP2;
int StopLevel=0;
double StopLevelDouble=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point();
double CurrentLoss=0;
double TP=TakeProfit,SL=StopLoss;
double SLI=0,TPI=0;
string EAName="AreaFiftyOne_Free";
string IndicatorName="AreaFiftyOneIndicator";
string IndicatorName2="AreaFiftyOne_Trend";
bool WrongDirectionBuy=false,WrongDirectionSell=false;
int WrongDirectionBuyTicketNr=0,WrongDirectionSellTicketNr=0;
int TicketNrBuyWD=0,TicketNrSellWD=0;
int TicketNrBuyStoch=0,TicketNrSellStoch=0;
int handle_ind;
bool OrderDueStoch=false;
int countStochOrders=0;
int countedDecimals=2;
double CurrentTotalLotSize=0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(LotSize<MarketInfo(Symbol(),MODE_MINLOT))
     {
      LotSize=MarketInfo(Symbol(),MODE_MINLOT);
     }
   if(LotSize>=MarketInfo(Symbol(),MODE_MAXLOT))
     {
      LotSize=MarketInfo(Symbol(),MODE_MAXLOT);
     }
//if(HandleUserPositions) bool h=OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0);
   double lotstep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   countedDecimals=(int)-MathLog10(lotstep);
   if(Debug)
     {
      Print("AccountNumber="+IntegerToString(AccountNumber()));
      Print("AccountCompany="+AccountCompany());
      Print("AccountName=",AccountName());
      Print("AccountServer=",AccountServer());
      Print("MODE_LOTSIZE=",MarketInfo(Symbol(),MODE_LOTSIZE),", Symbol=",Symbol());
      Print("MODE_MINLOT=",MarketInfo(Symbol(),MODE_MINLOT),", Symbol=",Symbol());
      Print("MODE_LOTSTEP=",MarketInfo(Symbol(),MODE_LOTSTEP),", Symbol=",Symbol());
      Print("MODE_MAXLOT=",MarketInfo(Symbol(),MODE_MAXLOT),", Symbol=",Symbol());
      Print("countedDecimals="+IntegerToString(countedDecimals));
     }
   if(trial_lic)
     {
      if(!IsTesting() && TimeCurrent()>expiryDate)
        {
         Alert("Expired copy. Please contact vendor.");
         return(INIT_FAILED);
           } else {
         ObjectCreate("TrialVersion",OBJ_LABEL,0,0,0);
         ObjectSetText("TrialVersion","End of a trial period: "+TimeToStr(expiryDate),11,"Calibri",clrAqua);
         ObjectSet("TrialVersion",OBJPROP_CORNER,1);
         ObjectSet("TrialVersion",OBJPROP_XDISTANCE,5);
         ObjectSet("TrialVersion",OBJPROP_YDISTANCE,15);
        }
     }

   if(rent_lic)
     {
      if(!IsTesting() && AccountName()==rentCustomerName && AccountNumber()==rentAccountNumber)
        {
         if(TimeCurrent()>rentExpiryDate)
           {
            Alert("Your license is expired. Please contact us.");
              } else {
            ObjectCreate("RentVersion",OBJ_LABEL,0,0,0);
            ObjectSetText("RentVersion","Your version is valid till: "+TimeToStr(rentExpiryDate),11,"Calibri",clrAqua);
            ObjectSet("RentVersion",OBJPROP_CORNER,1);
            ObjectSet("RentVersion",OBJPROP_XDISTANCE,5);
            ObjectSet("RentVersion",OBJPROP_YDISTANCE,15);

           }
           } else {
         if(!IsTesting())
           {
            Alert("You can use the expert advisor only on accountNumber="+IntegerToString(rentAccountNumber)+" and accountName="+rentCustomerName);
            Alert("Current accountNumber="+IntegerToString(AccountNumber())+" && accountName="+AccountName());
            return(INIT_FAILED);
           }
        }
     }
   if(UseRSIBasedIndicator)
     {
      handle_ind=(int)iCustom(_Symbol,_Period,"::Indicators\\"+IndicatorName+".ex4",0,0);
      if(handle_ind==INVALID_HANDLE)
        {
         Print("Expert: iCustom call: Error code=",GetLastError());
         return(INIT_FAILED);
        }
     }
   if(UseTrendIndicator)
     {
      handle_ind=0;
      handle_ind=(int)iCustom(_Symbol,_Period,"::Indicators\\"+IndicatorName2+".ex4",0,0);
      if(handle_ind==INVALID_HANDLE)
        {
         Print("Expert: iCustom call2: Error code=",GetLastError());
         return(INIT_FAILED);
        }
     }
   bool compareContractSizes=false;
   if(CompareDoubles(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_CONTRACT_SIZE),100000.0)) {compareContractSizes=true;}
   else {compareContractSizes=false;}
   StopLevel=(int)(MarketInfo(Symbol(),MODE_STOPLEVEL)*1.3);
   int MarginMode=(int)MarketInfo(Symbol(),MODE_MARGINCALCMODE);
   if(StopLevel>0)
     {
      TrailingStep=TrailingStep+StopLevel;
      DistanceStep=DistanceStep+StopLevel;
      if(Debug){Print("TrailingStep="+IntegerToString(TrailingStep)+";DistanceStep="+IntegerToString(DistanceStep)+";StopLevel="+IntegerToString(StopLevel));}
     }
   if((getContractProfitCalcMode()==1 || getContractProfitCalcMode()==2 || MarginMode==4)
      && (AllowPendings) && (compareContractSizes==false))
     {AllowPendings=false;Print("Pendings are disabled due CFD or Futures.");}
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(Debug)
     {
      if(UseStochasticBasedStrategy){Print("countStochOrders="+IntegerToString(countStochOrders));}
      Print("StopLevelDouble="+DoubleToStr(StopLevelDouble));
      Print("StopLevel="+IntegerToString(StopLevel));
     }
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
   bool TradingAllowed=false;
/*if(Debug){Print("StartHour>-1="+(StartHour>-1)+"&&EndHour<24="+(EndHour<24)+"&&Hour>StartHour="+(Hour()>StartHour)
   +"||Hour==StartHour="+(Hour()==StartHour)+"&&Hour<EndHour="+(Hour()<EndHour)+"||Hour==EndHour"+(Hour()==EndHour));}*/
   if((StartHour>-1 && EndHour<24) && (((Hour()>StartHour) || (Hour()==StartHour)) && (Hour()<EndHour || Hour()==EndHour)))
     {
      TradingAllowed=true;
     }
   bool CheckForSignal;
   if(HandleOnCandleOpenOnly && Volume[0]==1) {CheckForSignal=true;} else {CheckForSignal=false;}
   if(HandleOnCandleOpenOnly==false && CurrentCandleHasNoOpenedTrades()) {CheckForSignal=true;}

//double TempTDIGreen=0,TempTDIRed=0;
   if(TradingAllowed && CheckForSignal)
     {
      if(UseRSIBasedIndicator)
        {
         int i=0;
         double TDIGreen=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,4,i);
         double TDIGreenPrevious=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,4,i+1);
         double TDIYellow=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,2,i);
         double TDIYellowPrevous=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,2,i+1);
         //double TDIRedPlusOne=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,5,i+1);
         double TDIRed=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,5,i);
         // double TDIUp=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,1,i);
         // double TDIDown=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,3,i);
         double TSL2=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,6,i);
         double TSL2Previous=iCustom(Symbol(),0,"::Indicators\\"+IndicatorName+".ex4",RSI_Period,RSI_Price,Volatility_Band,RSI_Price_Line,RSI_Price_Type,Trade_Signal_Line,Trade_Signal_Line2,Trade_Signal_Type,6,i+1);

         if((TSL2<TDIYellow) && (TDIGreen>TSL2 && (TDIGreenPrevious<TSL2Previous || TDIGreenPrevious==TSL2Previous))) {BuyFlag=true;}
         if((TSL2>TDIYellow) && (TDIGreen<TSL2 && (TDIGreenPrevious>TSL2Previous || TDIGreenPrevious==TSL2Previous))) {SellFlag=true;}

         if((TDIYellow<50) &&(TSL2<TDIYellow)  && (TDIGreen>TDIYellow && (TDIGreenPrevious<TDIYellowPrevous || TDIGreenPrevious==TDIYellowPrevous))) {BuyFlag=true;}
         if((TDIYellow>50) && (TSL2>TDIYellow) && (TDIGreen<TDIYellow && (TDIGreenPrevious>TDIYellowPrevous || TDIGreenPrevious==TDIYellowPrevous))) {SellFlag=true;}

         if(SellFlag && Debug) { Print("Got sell signal from RSI-based indicator!");}
         if(BuyFlag && Debug) { Print("Got buy signal from RSI-based indicator!");}
        }

      if(UseTrendIndicator)
        {
         if(true)//(Volume[0]==1)
           {
            double Trend=NormalizeDouble(iCustom(Symbol(),0,"::Indicators\\"+IndicatorName2+".ex4",0,0),1);
            double TrendBack=NormalizeDouble(iCustom(Symbol(),0,"::Indicators\\"+IndicatorName2+".ex4",0,1),1);
            double TrendBack2=NormalizeDouble(iCustom(Symbol(),0,"::Indicators\\"+IndicatorName2+".ex4",0,2),1);
            double MA=NormalizeDouble(iCustom(Symbol(),0,"::Indicators\\"+IndicatorName2+".ex4",1,0),1);
            double MABack=NormalizeDouble(iCustom(Symbol(),0,"::Indicators\\"+IndicatorName2+".ex4",1,1),1);
            double MABack2=NormalizeDouble(iCustom(Symbol(),0,"::Indicators\\"+IndicatorName2+".ex4",1,2),1);
            double MA_Second=NormalizeDouble(iCustom(Symbol(),0,"::Indicators\\"+IndicatorName2+".ex4",2,0),1);
            double MABack_Second=NormalizeDouble(iCustom(Symbol(),0,"::Indicators\\"+IndicatorName2+".ex4",2,1),1);
            double MABack2_Second=NormalizeDouble(iCustom(Symbol(),0,"::Indicators\\"+IndicatorName2+".ex4",2,2),1);

            if(Debug)
              {
               Print("Trend="+DoubleToStr(Trend));
               Print("TrendBack="+DoubleToStr(TrendBack));
               Print("TrendBack2="+DoubleToStr(TrendBack2));
               Print("MA="+DoubleToStr(MA));
               Print("MABack="+DoubleToStr(MABack));
               Print("MABack2="+DoubleToStr(MABack2));
               Print("MA_Second="+DoubleToStr(MA_Second));
               Print("MABack_Second="+DoubleToStr(MABack_Second));
               Print("MABack2_Second="+DoubleToStr(MABack2_Second));
              }

            if(!UseSMAOnTrendIndicator)
              {
               if(((Trend<TrendBack || CompareDoubles(Trend,TrendBack)) && ((Trend<26) && (TrendBack>=23)) && (TrendBack2>=26)))
                 {
                  if(Debug)
                    {
                     Print("SellSignal!");
                     Print("Trend="+DoubleToStr(Trend));
                     Print("TrendBack="+DoubleToStr(TrendBack));
                    }
                  SellFlag=1;

                 }

               if(((Trend>TrendBack || CompareDoubles(Trend,TrendBack)) && (Trend>4) && (TrendBack<=8) && (TrendBack2<=5)))
                 {
                  if(Debug)
                    {
                     Print("BuySignal!");
                     Print("Trend="+DoubleToStr(Trend));
                     Print("TrendBack="+DoubleToStr(TrendBack));
                    }
                  BuyFlag=1;
                 }
              }
            if(UseSMAOnTrendIndicator && (UseOneOrTwoSMAOnTrendIndicator==1 || UseOneOrTwoSMAOnTrendIndicator==2))
              {
               if(((MathRound(MA)>MathRound(Trend)) || ((MA-0.5)==Trend))
                  && (((MA-Trend)>1) || ((MA-Trend)==1)) && (Trend<14.5 || Trend>16.5)
                  && ((MathRound(MABack)<MathRound(TrendBack)) || (MathRound(MABack)==MathRound(TrendBack)))
                  && (MathRound(MABack2)<MathRound(TrendBack2)))
                 {
                  if(Debug)
                    {
                     Print("SELL=>MA="+DoubleToStr(MathRound(MA))+">Trend="+DoubleToStr(MathRound(Trend))
                           +"&&MABack="+DoubleToStr(MathRound(MABack))+"<=TrendBack="+DoubleToStr(MathRound(TrendBack))
                           +"&&MaBack2="+DoubleToStr(MathRound(MABack2))+"<=TrendBack2="+DoubleToStr(MathRound(TrendBack2)));
                    }
                  SellFlag=1;
                 }
               if(((MathRound(MA)<MathRound(Trend)) || ((MA+0.5)==Trend))
                  && (((Trend-MA)>1) || ((Trend-MA)==1)) && (Trend<14.5 || Trend>16.5) && (Trend>4)
                  && ((MathRound(MABack)>MathRound(TrendBack)) || (MathRound(MABack)==MathRound(TrendBack)))
                  && (MathRound(MABack2)>MathRound(TrendBack2)))
                 {
                  if(Debug)
                    {
                     Print("BUY=>MA="+DoubleToStr(MathRound(MA))+"<Trend="+DoubleToStr(MathRound(Trend))
                           +"&&MABack="+DoubleToStr(MathRound(MABack))+"=>TrendBack="+DoubleToStr(MathRound(TrendBack))
                           +"&&MaBack2="+DoubleToStr(MathRound(MABack2))+"=>TrendBack2="+DoubleToStr(MathRound(TrendBack2)));
                    }
                  BuyFlag=1;
                 }
              }

            if(UseSMAOnTrendIndicator && (UseOneOrTwoSMAOnTrendIndicator==2 || UseOneOrTwoSMAOnTrendIndicator==3))
              {
               //using ma50
               if(((MathRound(MA_Second)>MathRound(Trend)) || (MathRound(MA_Second-0.5)==Trend))
                  && (((MA_Second-Trend)>0.5) || ((MA_Second-Trend)==1)) && (Trend<14.5 || Trend>16.5)
                  && ((MathRound(MABack_Second)<MathRound(TrendBack)) || (MathRound(MABack_Second)==MathRound(TrendBack)))
                  && (MathRound(MABack2_Second)<MathRound(TrendBack2)))
                 {
                  if(Debug)
                    {
                     Print("SELL=>MA_Second="+DoubleToStr(MathRound(MA_Second))+">Trend="+DoubleToStr(MathRound(Trend))
                           +"&&MABack_Second="+DoubleToStr(MathRound(MABack_Second))+"<=TrendBack="+DoubleToStr(MathRound(TrendBack))
                           +"&&MaBack2_Second="+DoubleToStr(MathRound(MABack2_Second))+"<=TrendBack2="+DoubleToStr(MathRound(TrendBack2)));
                    }
                  SellFlag=1;
                 }
               if(((MathRound(MA_Second)<MathRound(Trend)) || (MathRound(MA_Second+0.5)==Trend))
                  && (((Trend-MA_Second)>0.5) || ((Trend-MA_Second)==1)) && (Trend<14.5 || Trend>16.5)
                  && ((MathRound(MABack_Second)>MathRound(TrendBack)) || (MathRound(MABack_Second)==MathRound(TrendBack)))
                  && (MathRound(MABack2_Second)>MathRound(TrendBack2)))
                 {
                  if(Debug)
                    {
                     Print("BUY=>MA_Second="+DoubleToStr(MathRound(MA_Second))+"<Trend="+DoubleToStr(MathRound(Trend))
                           +"&&MABack_Second="+DoubleToStr(MathRound(MABack_Second))+"=>TrendBack="+DoubleToStr(MathRound(TrendBack))
                           +"&&MaBack2_Second="+DoubleToStr(MathRound(MABack2_Second))+"=>TrendBack2="+DoubleToStr(MathRound(TrendBack2)));
                    }
                  BuyFlag=1;
                 }
              }
            if(UseSMAOnTrendIndicator && UseSMAsCrossingOnTrendIndicatorData)
              {
               //using emas
               if(((MathRound(MA_Second)>MathRound(MA)) || (MathRound(MA_Second-0.5)==MA))
                  && (((MA_Second-MA)>0.5) || ((MA_Second-MA)==1))
                  && ((MathRound(MABack_Second)<MathRound(MABack)) || (MathRound(MABack_Second)==MathRound(MABack2)))
                  && (MathRound(MABack2_Second)<MathRound(MABack2)))
                 {
                  if(Debug)
                    {
                     Print("SELL=>MA_Second="+DoubleToStr(MathRound(MA_Second))+">MATrend="+DoubleToStr(MathRound(MA))
                           +"&&MABack_Second="+DoubleToStr(MathRound(MABack_Second))+"<=MABack="+DoubleToStr(MathRound(MABack))
                           +"&&MaBack2_Second="+DoubleToStr(MathRound(MABack2_Second))+"<=MABack2="+DoubleToStr(MathRound(MABack2)));
                    }
                  SellFlag=1;
                 }
               if(((MathRound(MA_Second)<MathRound(MA)) || (MathRound(MA_Second+0.5)==MA))
                  && (((MA-MA_Second)>0.5) || ((MA-MA_Second)==1))
                  && ((MathRound(MABack_Second)>MathRound(MABack)) || (MathRound(MABack_Second)==MathRound(MABack)))
                  && (MathRound(MABack2_Second)>MathRound(MABack2)))
                 {
                  if(Debug)
                    {
                     Print("BUY=>MA_Second="+DoubleToStr(MathRound(MA_Second))+"<MA="+DoubleToStr(MathRound(MA))
                           +"&&MABack_Second="+DoubleToStr(MathRound(MABack_Second))+"=>MABack="+DoubleToStr(MathRound(MABack))
                           +"&&MaBack2_Second="+DoubleToStr(MathRound(MABack2_Second))+"=>MABack2="+DoubleToStr(MathRound(MABack2)));
                    }
                  BuyFlag=1;
                 }
              }
            if((SellFlag || BuyFlag) && Debug) {Print("Got signal from trend-based indicator!");}
           }
        }
      if(UseSimpleTrendStrategy)
        {
         if(true)//(Volume[0]==1)
           {
            double MAFastPrevious1,MAFastPrevious2;
            double MASlowPrevious1,MASlowPrevious2;

            MAFastPrevious1=iMA(NULL,0,MAFastPeriod,0,MODE_EMA,PRICE_CLOSE,1);
            MAFastPrevious2=iMA(NULL,0,MAFastPeriod,0,MODE_EMA,PRICE_CLOSE,2);
            MASlowPrevious1=iMA(NULL,0,MASlowPeriod,0,MODE_EMA,PRICE_CLOSE,1);
            MASlowPrevious2=iMA(NULL,0,MASlowPeriod,0,MODE_EMA,PRICE_CLOSE,2);

            //fast MA > slow MA.
            if(MAFastPrevious1>MASlowPrevious1)
              {
               //BuyFlag = true;
               //fast MA crosses over slow MA.
               if(MAFastPrevious2<MASlowPrevious2)
                 {
                  if(iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1)>0 && 
                     iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,1)>20 && iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,1)<33)
                    {
                     BuyFlag=true;
                    }
                 }
              }
            //fast MA < slow MA.
            else if(MAFastPrevious1<MASlowPrevious1)
              {
               //SellFlag = true;
               //fast MA crosses below slow MA.
               if(MAFastPrevious2>MASlowPrevious2)
                 {
                  if(iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1)<0 && 
                     iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,1)>20 && iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,1)<33)
                    {
                     SellFlag=true;
                    }
                 }
              }
           }
        }
      if(UseStochasticBasedStrategy)
        {
         for(int i=0; i<=2; i++)
           {
            double stochastic1now,stochastic2now,stochastic1previous,stochastic2previous,stochastic1after,stochastic2after;
            stochastic1now=iStochastic(NULL,0,KPeriod1,DPeriod1,Slowing1,MAMethod1,PriceField1,0,i);
            stochastic1previous=iStochastic(NULL,0,KPeriod1,DPeriod1,Slowing1,MAMethod1,PriceField1,0,i+1);
            stochastic1after=iStochastic(NULL,0,KPeriod1,DPeriod1,Slowing1,MAMethod1,PriceField1,0,i-1);
            stochastic2now=iStochastic(NULL,0,KPeriod1,DPeriod1,Slowing1,MAMethod1,PriceField1,1,i);
            stochastic2previous=iStochastic(NULL,0,KPeriod1,DPeriod1,Slowing1,MAMethod1,PriceField1,1,i+1);
            stochastic2after=iStochastic(NULL,0,KPeriod1,DPeriod1,Slowing1,MAMethod1,PriceField1,1,i-1);

            if((stochastic1now>stochastic2now) && (stochastic1previous<stochastic2previous) && (stochastic1after>stochastic2after)
               && ((stochastic1now-stochastic2now)>0.5) && (stochastic1now<70.0))
              {
               if(NewBar())
                 {
                  BuyFlag=true;
                 }
              }
            if((stochastic1now<stochastic2now) && (stochastic1previous>stochastic2previous) && (stochastic1after<stochastic2after)
               && ((stochastic2now-stochastic1now)>0.5) && (stochastic1now>30.0))
              {
               if(NewBar())
                 {
                  SellFlag=true;
                 }
              }
           }
        }
      if(Use5050Strategy)
        {
         if(true)//(Volume[0]==1)
           {
            int i=0;
            if((MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i))>50) && (MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i))<52)
               && ((MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i+1))==50) || (MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i+1))==49))
               && (iMA(NULL,0,34,8,MODE_SMA,PRICE_CLOSE,0)<Ask))
              {
               BuyFlag=true;
              }
            if((MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i))<50) && (MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i))>48)
               && ((MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i+1))==50) || (MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i+1))==49))
               && (iMA(NULL,0,34,8,MODE_SMA,PRICE_CLOSE,0)>Bid))
              {
               SellFlag=true;
              }
           }
        }
      if(UseStochRSICroosingStrategy)
        {
         if(true)//(CheckForSignal)
           {
            int i=0,KPeriod2=21,DPeriod2=7,Slowing2=7,MAMethod2=MODE_SMA,PriceField2=0;
            double stochastic1now,stochastic1previous;
            stochastic1now=iStochastic(NULL,0,KPeriod2,DPeriod2,Slowing1,MAMethod2,PriceField2,0,i);
            stochastic1previous=iStochastic(NULL,0,KPeriod2,DPeriod2,Slowing1,MAMethod2,PriceField2,0,i+1);

            if((MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i))<MathRound(stochastic1now))
               && (MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i))>MathRound(stochastic1previous)))
              {
               BuyFlag=true;
              }
            if((MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i))>MathRound(stochastic1now))
               && (MathRound(iRSI(NULL,0,45,PRICE_CLOSE,i))<MathRound(stochastic1previous)))
              {
               SellFlag=true;
              }
           }
        }
     }

//risk management
   double SymbolStep=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   int MarginMode=(int)MarketInfo(Symbol(),MODE_MARGINCALCMODE);
   bool compareContractSizes=false;
   if(CompareDoubles(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_CONTRACT_SIZE),100000.0)) {compareContractSizes=true;}
   else {compareContractSizes=false;}
   double RemainingLotSize=0.0;
   int countRemainingMaxLots=0;
   bool LotSizeIsBiggerThenMaxLot=false;
   double MaxLot=MarketInfo(Symbol(),MODE_MAXLOT);
   if(SymbolStep>0.0)
     {
      MaxLot=NormalizeDouble(MaxLot-MathMod(MaxLot,SymbolStep),countedDecimals);
     }

   if(LotAutoSize)
     {
      int Faktor=100;
      if(LotRiskPercent<0.1 || LotRiskPercent>1000){Comment("Invalid Risk Value.");}
      else
        {
         if(getContractProfitCalcMode()==0 || (MarginMode==0 && compareContractSizes))
           {
            //Print("Fall1:"+(MarginMode==0 && compareContractSizes));
            LotSize=NormalizeDouble(MathFloor((AccountFreeMargin()*AccountLeverage()*LotRiskPercent*Point*Faktor)/
                                    (Ask*MarketInfo(Symbol(),MODE_LOTSIZE)*MarketInfo(Symbol(),MODE_MINLOT)))*MarketInfo(Symbol(),MODE_MINLOT),countedDecimals);
            //Print("LotSize="+LotSize);
            LotSizeP1 = NormalizeDouble(LotSize*0.625,countedDecimals);
            LotSizeP2 = NormalizeDouble(LotSize*0.5,countedDecimals);
           }
         else if((getContractProfitCalcMode()==1 || getContractProfitCalcMode()==2 || MarginMode==4) && (compareContractSizes==false))
           {
            //Print("Fall2:"+((getContractProfitCalcMode()==1 || getContractProfitCalcMode()==2 || MarginMode==4) && (compareContractSizes==false)));
            if(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_CONTRACT_SIZE)==1.0){countedDecimals=0;}
            int Splitter=1000;
            if(getContractProfitCalcMode()==1){Splitter=100000;}
            if(MarginMode==4 && MarketInfo(Symbol(),MODE_TICKSIZE)==0.001){Splitter=1000000;}
            if(Digits==3){Faktor=1;}
            if(Digits==2){Faktor=10;}
            LotSize=NormalizeDouble(MathFloor((AccountFreeMargin()*AccountLeverage()*LotRiskPercent*Faktor*Point)/
                                    (Ask*MarketInfo(Symbol(),MODE_TICKSIZE)*MarketInfo(Symbol(),MODE_MINLOT)))*MarketInfo(Symbol(),MODE_MINLOT)/Splitter,countedDecimals);
            LotSizeP1 = MathFloor(NormalizeDouble(LotSize*0.625,countedDecimals));
            LotSizeP2 = MathFloor(NormalizeDouble(LotSize*0.5,countedDecimals));
            //Print("LotSize2="+LotSize);
            if(SymbolStep>0.0)
              {
               LotSize=LotSize-MathMod(LotSize,SymbolStep);
               LotSizeP1=LotSizeP1-MathMod(LotSizeP1,SymbolStep);
               LotSizeP2=LotSizeP2-MathMod(LotSizeP2,SymbolStep);
              }
              } else {
            Print("Cannot calculate the right auto lot size!");
            LotSize=MarketInfo(Symbol(),MODE_MINLOT);
            LotSizeP1=MarketInfo(Symbol(),MODE_MINLOT);
            LotSizeP2=MarketInfo(Symbol(),MODE_MINLOT);
           }
        }

      if(MaxDynamicLotSize>0 && LotSize>MaxDynamicLotSize)
        {
         LotSize=MaxDynamicLotSize;
        }
     }
   if(LotAutoSize==false){LotSize=LotSize;}
   if(LotSize<MarketInfo(Symbol(),MODE_MINLOT))
     {
      LotSize=MarketInfo(Symbol(),MODE_MINLOT);
      LotSizeP1 = NormalizeDouble(LotSize*0.625,countedDecimals);
      LotSizeP2 = NormalizeDouble(LotSize*0.5,countedDecimals);
      if(SymbolStep>0.0)
        {
         LotSize=NormalizeDouble(LotSize-MathMod(LotSize,SymbolStep),countedDecimals);
         LotSizeP1=NormalizeDouble(LotSizeP1-MathMod(LotSizeP1,SymbolStep), countedDecimals);
         LotSizeP2=NormalizeDouble(LotSizeP2-MathMod(LotSizeP2,SymbolStep), countedDecimals);
        }
     }
   if(LotSize>MaxLot)
     {
      countRemainingMaxLots=(int)(LotSize/MaxLot);
      RemainingLotSize=MathMod(LotSize,MaxLot);
      LotSizeIsBiggerThenMaxLot=true;
      CurrentTotalLotSize=LotSize;
      LotSize=MarketInfo(Symbol(),MODE_MAXLOT);
      LotSizeP1=NormalizeDouble(LotSizeP1*0.625,countedDecimals);
      LotSizeP2=NormalizeDouble(LotSizeP2*0.5,countedDecimals);
      if(SymbolStep>0.0)
        {
         LotSize=NormalizeDouble(LotSize-MathMod(LotSize,SymbolStep),countedDecimals);
         LotSizeP1=NormalizeDouble(LotSizeP1-MathMod(LotSizeP1,SymbolStep), countedDecimals);
         LotSizeP2=NormalizeDouble(LotSizeP2-MathMod(LotSizeP2,SymbolStep), countedDecimals);
        }
     }
//in the free version LotSize can be less then 0.10!
   if(LotSize>0.10) {LotSize=0.10;}
   if(Debug)
     {
      Print("LotSize="+DoubleToStr(LotSize,countedDecimals));
      Print("LotSize*0,625="+DoubleToStr(LotSizeP1,countedDecimals));
      Print("LotSize*0,5="+DoubleToStr(LotSizeP2,countedDecimals));
     }

//Money Management
   double TempLoss=0;
   for(int j=0;j<OrdersTotal();j++)
     {
      if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber()==MagicNumber))
           {
            TempLoss=TempLoss+OrderProfit();
           }
        }
     }
   if(AccountBalance()>0)
     {
      CurrentLoss=NormalizeDouble((TempLoss/AccountBalance())*100,2);
     }
   if((MoneyRiskInPercent>0 && StrToInteger(DoubleToStr(MathAbs(CurrentLoss),0))>MoneyRiskInPercent)
      || (MaxMoneyValueToLose>0 && StrToInteger(DoubleToStr(MathAbs(TempLoss),0))>MaxMoneyValueToLose))
     {
      while(CloseAll()==AT_LEAST_ONE_FAILED)
        {
         Sleep(1000);
         Print("Order close failed - retrying error: #"+IntegerToString(GetLastError()));
        }
     }

//positions initialization
   int cnt=0,OP=0,OS=0,OB=0,CloseSell=0,OSC=0,OBC=0,CloseBuy=0;OP=0;
   for(cnt=0;cnt<OrdersTotal();cnt++)
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
   if(HandleUserPositions){HandleUserPositionsFun();}
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
         (TicketNrPendingSell>0 || TicketNrPendingSell2>0 || TicketNrPendingBuy>0 || TicketNrPendingBuy2>0 || TicketNrSellStoch>0 || TicketNrBuyStoch>0) && 
         (OrderMagicNumber()==MagicNumber) && 
         (OrderTicket()==TicketNrBuy || OrderTicket()==TicketNrSell || OrderTicket()==TicketNrBuyWD || OrderTicket()==TicketNrSellWD
         || OrderTicket()==TicketNrSellStoch || OrderTicket()==TicketNrBuyStoch))
        {
         bool foundS1=false,foundS2=false,foundB1=false,foundB2=false,foundSWD=false,foundBWD=false,foundSST=false,foundBST=false;
         for(int cnt0=0;cnt0<OrdersHistoryTotal();cnt0++)
           {
            if(WrongDirectionSellTicketNr>0 && WrongDirectionSellTicketNr==OrderTicket()){WrongDirectionSell=false;WrongDirectionSellTicketNr=0;}
            if(WrongDirectionBuyTicketNr>0  &&  WrongDirectionBuyTicketNr==OrderTicket()){WrongDirectionBuy=false;WrongDirectionBuyTicketNr=0;}
            if(OrderTicket()==TicketNrPendingSell) {foundS1=true;}
            if(OrderTicket()==TicketNrPendingSell2) {foundS2=true;}
            if(OrderTicket()==TicketNrPendingBuy) {foundB1=true;}
            if(OrderTicket()==TicketNrPendingBuy2) {foundB2=true;}
            if(OrderTicket()==TicketNrSellWD) {foundSWD=true;}
            if(OrderTicket()==TicketNrBuyWD) {foundBWD=true;}
            if(OrderTicket()==TicketNrSellStoch) {foundSST=true;}
            if(OrderTicket()==TicketNrBuyStoch) {foundBST=true;}

            if(foundSST){TicketNrSellStoch=0;}
            if(foundBST){TicketNrBuyStoch=0;}
            if(OrderTicket()==TicketNrSell)
              {
               if(foundS1==false && TicketNrPendingSell>0
                  && getTicketCurrentType(TicketNrPendingSell)>-1 && getTicketCurrentType(TicketNrPendingSell)==3)
                 {
                  bool delS1; delS1=OrderDelete(TicketNrPendingSell);
                  if(delS1==false){bool delS11;delS11=OrderDelete(TicketNrPendingSell);TicketNrPendingSell=0;}else{TicketNrPendingSell=0;}
                 }
               if(foundS2==false && TicketNrPendingSell2>0
                  && getTicketCurrentType(TicketNrPendingSell2)>-1 && getTicketCurrentType(TicketNrPendingSell2)==3)
                 {
                  bool delS2; delS2=OrderDelete(TicketNrPendingSell2);
                  if(delS2==false){bool delS21;delS21=OrderDelete(TicketNrPendingSell2);TicketNrPendingSell2=0;}else{TicketNrPendingSell2=0;}
                 }
               if(foundBWD==false && getTicketCurrentType(TicketNrBuyWD)>-1 && getTicketCurrentType(TicketNrBuyWD)==3)
                 {
                  bool delB; delB=OrderDelete(TicketNrPendingSell2);
                  if(delB==false){bool delB1;delB1=OrderDelete(TicketNrBuyWD);TicketNrBuyWD=0;}else{TicketNrBuyWD=0;}
                 }
              }
            if(OrderTicket()==TicketNrBuy)
              {
               if(foundB1==false && TicketNrPendingBuy>0
                  && getTicketCurrentType(TicketNrPendingBuy)>-1 && getTicketCurrentType(TicketNrPendingBuy)==2)
                 {
                  bool delB1; delB1=OrderDelete(TicketNrPendingBuy);
                  if(delB1==false){bool delB11;delB11=OrderDelete(TicketNrPendingBuy);TicketNrPendingBuy=0;}else{TicketNrPendingBuy=0;}
                 }

               if(foundB2==false && TicketNrPendingBuy2>0
                  && getTicketCurrentType(TicketNrPendingBuy2)>-1 && getTicketCurrentType(TicketNrPendingBuy2)==2)
                 {
                  bool delB2; delB2=OrderDelete(TicketNrPendingBuy2);
                  if(delB2==false){bool delB21;delB21=OrderDelete(TicketNrPendingBuy2);TicketNrPendingBuy2=0;}else{TicketNrPendingBuy2=0;}
                 }
               if(foundSWD==false && getTicketCurrentType(TicketNrSellWD)>-1 && getTicketCurrentType(TicketNrSellWD)==3)
                 {
                  bool delS; delS=OrderDelete(TicketNrPendingSell2);
                  if(delS==false){bool delS1;delS1=OrderDelete(TicketNrSellWD);TicketNrSellWD=0;}else{TicketNrSellWD=0;}
                 }
              }
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
                    {
                     if(OrderModifyCheck(OrderTicket(),OrderOpenPrice(),0,TempTP))
                       {
                        bool fm;fm=OrderModify(TicketNrSell,OrderOpenPrice(),0,TempTP,0,CLR_NONE);
                       }
                    }
/*if((TicketNrPendingSell>0) && (OrderSelect(TicketNrPendingSell,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm1;fm1=OrderModify(TicketNrPendingSell,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}
                  if((TicketNrPendingSell2>0) && (OrderSelect(TicketNrPendingSell2,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm2;fm2=OrderModify(TicketNrPendingSell2,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}*/
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
                    {
                     if(OrderModifyCheck(OrderTicket(),OrderOpenPrice(),0,TempTP))
                       {
                        bool fm;fm=OrderModify(TicketNrBuy,OrderOpenPrice(),0,TempTP,0,CLR_NONE);
                       }
                    }
/* if((TicketNrPendingBuy>0) && (OrderSelect(TicketNrPendingBuy,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm1;fm1=OrderModify(TicketNrPendingBuy,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}
                  if((TicketNrPendingBuy2>0) && (OrderSelect(TicketNrPendingBuy2,SELECT_BY_TICKET,MODE_TRADES)==true) && TempTP!=OrderTakeProfit())
                    {bool fm2;fm2=OrderModify(TicketNrPendingBuy2,OrderOpenPrice(),0,TempTP,0,CLR_NONE);}*/
                  WrongDirectionBuy=true;
                  WrongDirectionBuyTicketNr=TicketNrBuy;
                  break;
                 }
              }
           }
        }
     }
//open position
// 
   if((AddP() && AddPositionsIndependently && OP<=MaxConcurrentOpenedOrders) || (OP==0 && !AddPositionsIndependently))
     {
      // && TempTDIGreen>RSI_Top_Value && (TempTDIGreen-TempTDIRed)>=3.5
      //&& MarketInfo(Symbol(),MODE_TRADEALLOWED)
      if(OnlySell==true && !(AccountFreeMarginCheck(Symbol(),OP_SELL,LotSize*3)<=0 || GetLastError()==134))
        {
         if(OrderDueStoch && UseStochasticBasedStrategy && TicketNrSellStoch==0)
           {
            if(OrderDueStoch){Print("Sell due Stoch!");countStochOrders=countStochOrders+1;}
            if(TP==0)TPI=0;else TPI=Bid-TP*Point;if(SL==0)SLI=Bid+10000*Point;else SLI=Bid+SL*Point;
            if(CheckMoneyForTrade(Symbol(),LotSize,OP_SELL))
              {
               if(CheckStopLoss_Takeprofit(ORDER_TYPE_SELL,SLI,TPI) && CheckVolumeValue(LotSize))
                 {
                  TicketNrSellStoch=OrderSend(Symbol(),OP_SELL,LotSize,Bid,Slippage,SLI,TPI,EAName,MagicNumber,0,Red);OS=0;
                  if(TicketNrSellStoch<0)
                    {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                  //else{Print("Order Sent Successfully, Ticket # is: "+string(TicketNrSell));}
                  if(LotSizeIsBiggerThenMaxLot)
                    {
                     for(int c=0;c<countRemainingMaxLots-1;c++)
                       {
                        if(OrderSend(Symbol(),OP_SELL,MaxLot,Bid,Slippage,SLI,TPI,EAName,MagicNumber,0,Red)<0)
                          {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                       }
                     if(OrderSend(Symbol(),OP_SELL,RemainingLotSize,Bid,Slippage,SLI,TPI,EAName,MagicNumber,0,Red)<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                    }
                 }
              }
           }
         if(OS==1 /*&& OSC==0*/ && !OrderDueStoch)
           {
            if(TP==0)TPI=0;else TPI=Bid-TP*Point;if(SL==0)SLI=Bid+10000*Point;else SLI=Bid+SL*Point;
            if(CheckMoneyForTrade(Symbol(),LotSize,OP_SELL))
              {
               if(CheckStopLoss_Takeprofit(ORDER_TYPE_SELL,SLI,TPI) && CheckVolumeValue(LotSize))
                 {
                  TicketNrSell=OrderSend(Symbol(),OP_SELL,LotSize,Bid,Slippage,SLI,TPI,EAName,MagicNumber,0,Red);OS=0;
                  if(TicketNrSell<0)
                    {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                  //else{Print("Order Sent Successfully, Ticket # is: "+string(TicketNrSell));}
                  if(LotSizeIsBiggerThenMaxLot)
                    {
                     for(int c=0;c<countRemainingMaxLots-1;c++)
                       {
                        if(OrderSend(Symbol(),OP_SELL,MaxLot,Bid,Slippage,SLI,TPI,EAName,MagicNumber,0,Red)<0)
                          {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                       }
                     if(OrderSend(Symbol(),OP_SELL,RemainingLotSize,Bid,Slippage,SLI,TPI,EAName,MagicNumber,0,Red)<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                    }
                 }
              }

            if(AllowPendings && !OrderDueStoch)
              {
               double TempPendingLotSize=LotSizeP1;
               if(TempPendingLotSize<MarketInfo(Symbol(),MODE_MINLOT))TempPendingLotSize=MarketInfo(Symbol(),MODE_MINLOT);
               if(TicketNrPendingSell>0 && OrderSelect(TicketNrPendingSell,SELECT_BY_POS))
                 {if(OrderType()==3){bool delS=OrderDelete(TicketNrPendingSell);}TicketNrPendingSell=0;}
               else if(!OrderSelect(TicketNrPendingSell,SELECT_BY_POS) && TicketNrPendingSell>0)
                 {TicketNrPendingSell=0;}
               if(TicketNrPendingSell==0 && IsNewOrderAllowed() && (CheckMoneyForTrade(Symbol(),TempPendingLotSize,OP_SELL)))
                 {
                  if(CheckStopLoss_Takeprofit(ORDER_TYPE_SELL,SLI,TPI) && CheckVolumeValue(TempPendingLotSize))
                    {
                     TicketNrPendingSell=OrderSend(Symbol(),OP_SELLLIMIT,TempPendingLotSize,Bid+TP/2*Point,Slippage,0,Bid,EAName+"P1S",MagicNumber,0,Red);
                     if(TicketNrPendingSell<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                     // else{Print("Order Sent Successfully, Ticket # is: "+strin#g(TicketNrPendingSell));}
                    }
                 }

               double TempPendingLotSize2=LotSizeP1;
               if(TempPendingLotSize2<MarketInfo(Symbol(),MODE_MINLOT))TempPendingLotSize2=MarketInfo(Symbol(),MODE_MINLOT);
               if(TicketNrPendingSell2>0 && OrderSelect(TicketNrPendingSell2,SELECT_BY_POS))
                 {if(OrderType()==3){bool delS2=OrderDelete(TicketNrPendingSell2);}TicketNrPendingSell2=0;}
               else if(!OrderSelect(TicketNrPendingSell2,SELECT_BY_POS) && TicketNrPendingSell2>0)
                 {TicketNrPendingSell2=0;}
               if(TicketNrPendingSell2==0 && IsNewOrderAllowed() && (CheckMoneyForTrade(Symbol(),TempPendingLotSize2,OP_SELL)))
                 {
                  if(CheckStopLoss_Takeprofit(ORDER_TYPE_SELL,SLI,TPI) && CheckVolumeValue(TempPendingLotSize2))
                    {
                     TicketNrPendingSell2=OrderSend(Symbol(),OP_SELLLIMIT,TempPendingLotSize2,Bid+TP/1*Point,Slippage,0,Bid,EAName+"P2S",MagicNumber,0,Red);
                     if(TicketNrPendingSell2<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                     else{Print("Order Sent Successfully, Ticket # is: "+string(TicketNrPendingSell2));}
                    }
                 }

               if(TP==0)TPI=0;else TPI=Ask+(TP*2)*Point;if(SL==0)SLI=10000*Point;else SLI=Ask-(SL*2)*Point;
               if(CheckMoneyForTrade(Symbol(),LotSize,OP_BUY) && IsNewOrderAllowed())
                 {
                  if(CheckStopLoss_Takeprofit(ORDER_TYPE_BUY,SLI,TPI) && CheckVolumeValue(LotSize))
                    {
                     int expiryTime=(int)TimeCurrent()+(1209600);
                     TicketNrBuyWD=OrderSend(Symbol(),OP_BUYSTOP,LotSize,Ask+TP*Point,Slippage,SLI,TPI,EAName+"WD_BUY",MagicNumber,expiryTime,Lime);
                     if(TicketNrBuyWD<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                     //else{Print("Order Sent Successfully, Ticket # is: "+string(TicketNrBuy));}
                    }
                 }
              }
            OrderDueStoch=false;
           }
        }
      // && TempTDIGreen<RSI_Down_Value && (TempTDIGreen-TempTDIRed)>=3.5
      // && MarketInfo(Symbol(),MODE_TRADEALLOWED)
      if(OnlyBuy==true && !(AccountFreeMarginCheck(Symbol(),OP_BUY,LotSize*3)<=0 || GetLastError()==134))
        {
         if(OrderDueStoch && UseStochasticBasedStrategy && TicketNrBuyStoch==0)
           {
            if(OrderDueStoch){Print("Buy due Stoch!");countStochOrders=countStochOrders+1;}
            if(TP==0)TPI=0;else TPI=Ask+TP*Point;if(SL==0)SLI=Ask-10000*Point;else SLI=Ask-SL*Point;
            if(CheckMoneyForTrade(Symbol(),LotSize,OP_BUY))
              {
               if(CheckStopLoss_Takeprofit(ORDER_TYPE_BUY,SLI,TPI) && CheckVolumeValue(LotSize))
                 {
                  TicketNrBuyStoch=OrderSend(Symbol(),OP_BUY,LotSize,Ask,Slippage,SLI,TPI,EAName,MagicNumber,0,Lime);OB=0;
                  if(TicketNrBuyStoch<0)
                    {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                  //else{Print("Order Sent Successfully, Ticket # is: "+string(TicketNrBuy));}
                  if(LotSizeIsBiggerThenMaxLot)
                    {
                     for(int c=0;c<countRemainingMaxLots-1;c++)
                       {
                        if(OrderSend(Symbol(),OP_BUY,MaxLot,Ask,Slippage,SLI,TPI,EAName,MagicNumber,0,Lime)<0)
                          {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                       }
                     if(OrderSend(Symbol(),OP_BUY,RemainingLotSize,Ask,Slippage,SLI,TPI,EAName,MagicNumber,0,Lime)<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                    }
                 }
              }
           }
         if(OB==1 /*&& OBC==0 */ && !OrderDueStoch)
           {
            if(TP==0)TPI=0;else TPI=Ask+TP*Point;if(SL==0)SLI=Ask-10000*Point;else SLI=Ask-SL*Point;
            if(CheckMoneyForTrade(Symbol(),LotSize,OP_BUY))
              {
               if(CheckStopLoss_Takeprofit(ORDER_TYPE_BUY,SLI,TPI) && CheckVolumeValue(LotSize))
                 {
                  TicketNrBuy=OrderSend(Symbol(),OP_BUY,LotSize,Ask,Slippage,SLI,TPI,EAName,MagicNumber,0,Lime);OB=0;
                  if(TicketNrBuy<0)
                    {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                  //else{Print("Order Sent Successfully, Ticket # is: "+string(TicketNrBuy));}
                  if(LotSizeIsBiggerThenMaxLot)
                    {
                     for(int c=0;c<countRemainingMaxLots-1;c++)
                       {
                        if(OrderSend(Symbol(),OP_BUY,MaxLot,Ask,Slippage,SLI,TPI,EAName,MagicNumber,0,Lime)<0)
                          {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                       }
                     if(OrderSend(Symbol(),OP_BUY,RemainingLotSize,Ask,Slippage,SLI,TPI,EAName,MagicNumber,0,Lime)<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                    }
                 }
              }
            if(AllowPendings && !OrderDueStoch)
              {
               double TempPendingLotSize=LotSizeP1;
               if(TempPendingLotSize<MarketInfo(Symbol(),MODE_MINLOT))TempPendingLotSize=MarketInfo(Symbol(),MODE_MINLOT);
               if(TicketNrPendingBuy>0 && OrderSelect(TicketNrPendingBuy,SELECT_BY_POS))
                 {if(OrderType()==2){bool delB=OrderDelete(TicketNrPendingBuy);}TicketNrPendingBuy=0;}
               else if(!OrderSelect(TicketNrPendingBuy,SELECT_BY_POS) && TicketNrPendingBuy>0)
                 {TicketNrPendingBuy=0;}
               if(TicketNrPendingBuy==0 && IsNewOrderAllowed() && (CheckMoneyForTrade(Symbol(),TempPendingLotSize,OP_BUY)))
                 {
                  if(CheckStopLoss_Takeprofit(ORDER_TYPE_BUY,SLI,TPI) && CheckVolumeValue(TempPendingLotSize))
                    {
                     TicketNrPendingBuy=OrderSend(Symbol(),OP_BUYLIMIT,TempPendingLotSize,Ask-TP/2*Point,Slippage,0,Ask,EAName+"P1B",MagicNumber,0,Red);
                     if(TicketNrPendingBuy<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                     //else{Print("Order Sent Successfully, Ticket # is: "+string(TicketNrPendingBuy));}
                    }
                 }

               double TempPendingLotSize2=LotSizeP2;
               if(TempPendingLotSize2<MarketInfo(Symbol(),MODE_MINLOT))TempPendingLotSize2=MarketInfo(Symbol(),MODE_MINLOT);
               if(TicketNrPendingBuy2>0 && OrderSelect(TicketNrPendingBuy2,SELECT_BY_POS) && OrderType()==2)
                 {if(OrderType()==2){bool delB2=OrderDelete(TicketNrPendingBuy2);}TicketNrPendingBuy2=0;}
               else if(!OrderSelect(TicketNrPendingBuy2,SELECT_BY_POS) && TicketNrPendingBuy2>0)
                 {TicketNrPendingBuy2=0;}
               if(TicketNrPendingBuy2==0 && IsNewOrderAllowed() && (CheckMoneyForTrade(Symbol(),TempPendingLotSize2,OP_BUY)))
                 {
                  if(CheckStopLoss_Takeprofit(ORDER_TYPE_BUY,SLI,TPI) && CheckVolumeValue(TempPendingLotSize2))
                    {
                     TicketNrPendingBuy2=OrderSend(Symbol(),OP_BUYLIMIT,TempPendingLotSize2,Ask-TP/1*Point,Slippage,0,Ask,EAName+"P2B",MagicNumber,0,Red);
                     if(TicketNrPendingBuy2<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                     //else{Print("Order Sent Successfully, Ticket # is: "+string(TicketNrPendingBuy2));}
                    }
                 }

               if(TP==0)TPI=0;else TPI=Bid-(TP*2)*Point;if(SL==0)SLI=Bid+10000*Point;else SLI=Bid+(SL*2)*Point;
               if(CheckMoneyForTrade(Symbol(),LotSize,OP_SELL) && IsNewOrderAllowed())
                 {
                  if(CheckStopLoss_Takeprofit(ORDER_TYPE_SELL,SLI,TPI) && CheckVolumeValue(LotSize))
                    {
                     int expiryTime=(int)TimeCurrent()+(1209600);
                     TicketNrSellWD=OrderSend(Symbol(),OP_SELLSTOP,LotSize,Bid-TP*Point,Slippage,SLI,TPI,EAName+"WD_SELL",MagicNumber,expiryTime,Red);
                     if(TicketNrSellWD<0)
                       {Print(EAName+" => OrderSend Error: "+IntegerToString(GetLastError()));}
                     // else{Print("Order Sent Successfully, Ticket # is: "+string(TicketNrSellWD));}
                    }
                 }
              }
            OrderDueStoch=false;
           }
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
            TempProfit=TempProfit+OrderProfit()+OrderCommission()+OrderSwap();
            if(Debug){Print("TempProfit="+DoubleToStr(TempProfit));}
           }
        }
     }

   double TempProfitUserPosis=0.0;
   if(HandleUserPositions)
     {
      for(int ff=0;ff<OrdersTotal();ff++)
        {
         if(OrderSelect(ff,SELECT_BY_POS,MODE_TRADES))
           {
            string OrderCom=OrderComment();
            if((StringLen(OrderCom)-CountCharsInCommentToEscape)>0 || (StringLen(OrderCom)-CountCharsInCommentToEscape==0))
              {
               OrderCom=StringSubstr(OrderCom,StringLen(OrderCom)-CountCharsInCommentToEscape,StringLen(OrderCom));
                 } else if((StringLen(OrderCom)-CountCharsInCommentToEscape)<0) {
               OrderCom="";
              }
            if(OrderSymbol()==Symbol() && (OrderComment()=="" || OrderCom=="") && OrderMagicNumber()==0)
              {
               TrP();
              }
           }
        }
      for(int f=0;f<OrdersTotal();f++)
        {
         if(OrderSelect(f,SELECT_BY_POS,MODE_TRADES))
           {
            string OrderCom=OrderComment();
            if((StringLen(OrderCom)-CountCharsInCommentToEscape)>0 || (StringLen(OrderCom)-CountCharsInCommentToEscape==0))
              {
               OrderCom=StringSubstr(OrderCom,StringLen(OrderCom)-CountCharsInCommentToEscape,StringLen(OrderCom));
                 } else if((StringLen(OrderCom)-CountCharsInCommentToEscape)<0) {
               OrderCom="";
              }
            if(OrderSymbol()==Symbol() && (OrderComment()=="" || OrderCom=="") && OrderMagicNumber()==0)
              {
               TempProfitUserPosis=TempProfitUserPosis+OrderProfit()+OrderCommission()+OrderSwap();
              }
           }
        }
     }
   CurrentProfit(TempProfit,TempProfitUserPosis);

//not enough money message to continue the martingale
   if((TicketNrBuy<0 || TicketNrSell<0) && GetLastError()==134){err=1;Print("NOT ENOGUGHT MONEY!!");}
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=AccountBalance();
   return(ret);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void HandleUserPositionsFun()
  {
   for(int j=0;j<OrdersTotal();j++)
     {
      if(OrderSelect(j,SELECT_BY_POS)==true && OrderSymbol()==Symbol())
        {
         if(Debug){Print("OrderComment='"+OrderComment()+"'");}
         if(Debug){Print("OrderMagicNumber='"+IntegerToString(OrderMagicNumber())+"'");}
         string OrderCom=OrderComment();
         if((StringLen(OrderCom)-CountCharsInCommentToEscape)>0 || (StringLen(OrderCom)-CountCharsInCommentToEscape==0))
           {
            OrderCom=StringSubstr(OrderCom,StringLen(OrderCom)-CountCharsInCommentToEscape,StringLen(OrderCom));
              } else if((StringLen(OrderCom)-CountCharsInCommentToEscape)<0) {
            OrderCom="";
           }
         if(OrderMagicNumber()==0 && (OrderComment()=="" || OrderCom==""))
           {
            if((OrderType()==OP_SELL) && (((OrderOpenPrice()-OrderTakeProfit())!=TakeProfit*Point)
               || ((OrderStopLoss()>OrderOpenPrice()) || OrderStopLoss()==0)))
              {
               if(TP==0)TPI=0;else TPI=OrderOpenPrice()-TP*Point;if(SL==0)SLI=OrderOpenPrice()+10000*Point;else SLI=OrderOpenPrice()+SL*Point;
               if(OrderModifyCheck(OrderTicket(),OrderOpenPrice(),SLI,TPI) && CheckStopLoss_Takeprofit(ORDER_TYPE_SELL,SLI,TPI))
                 {
                  if(OrderTakeProfit()!=TPI && ((OrderStopLoss()<SLI && OrderOpenPrice()<OrderStopLoss()) || OrderStopLoss()==0))
                    {
                     bool Res=OrderModify(OrderTicket(),OrderOpenPrice(),SLI,TPI,0,clrGoldenrod);
                    }
                 }
              }
            else
               if((OrderType()==OP_BUY) && (((OrderTakeProfit()-OrderOpenPrice())!=TakeProfit*Point)
                  || ((OrderStopLoss()<OrderOpenPrice()) || OrderStopLoss()==0)))
                 {
                  if(TP==0)TPI=0;else TPI=OrderOpenPrice()+TP*Point;if(SL==0)SLI=OrderOpenPrice()-10000*Point;else SLI=OrderOpenPrice()-SL*Point;

                  if(OrderModifyCheck(OrderTicket(),OrderOpenPrice(),SLI,TPI) && CheckStopLoss_Takeprofit(ORDER_TYPE_BUY,SLI,TPI))
                    {
                     if(OrderTakeProfit()!=TPI && ((OrderStopLoss()>SLI && OrderOpenPrice()>OrderStopLoss()) || OrderStopLoss()==0))
                       {
                        bool Res=OrderModify(OrderTicket(),OrderOpenPrice(),SLI,TPI,0,clrGoldenrod);
                       }
                    }
                 }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|add positions function                                            |
//+------------------------------------------------------------------+
bool AddP()
  {
   int _num=0,_ot=0;
   for(int j=0;j<OrdersTotal();j++)
     {
      if(OrderSelect(j,SELECT_BY_POS)==true && OrderSymbol()==Symbol() && OrderType()<3 && (OrderMagicNumber()==MagicNumber))
        {
         _num++;if(OrderOpenTime()>_ot) _ot=(int)OrderOpenTime();
        }
     }
   if(_num==0) return(true);if(_num>0 && ((Time[0]-_ot))>0) return(true);else return(false);
  }
//trailing stop and breakeven
void TrP()
  {
   int BE=0;int TS=DistanceStep;double pbid,pask,ppoint;ppoint=MarketInfo(OrderSymbol(),MODE_POINT);
   double commissions=OrderCommission()+OrderSwap();
   double commissionsInPips;
   double tickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   if(Debug) {Print("tickValue="+DoubleToStr(tickValue,5));}
   if(tickValue==0) {tickValue=0.9;}
   double spread=Ask-Bid;
   double tickSize=MarketInfo(Symbol(),MODE_TICKSIZE);
   if(Debug) {Print("commissions="+DoubleToStr(commissions,8));}
   commissionsInPips=((commissions/OrderLots()/tickValue)*tickSize)+(spread*2);
   if(commissionsInPips<0){commissionsInPips=commissionsInPips-(commissionsInPips*2);}
   if(Debug)
     {
      Print("commissionsInPips(Ticket="+IntegerToString(OrderTicket())+")="+DoubleToStr(commissionsInPips,5)
            +";DistanceStep="+IntegerToString(TS)+";TrailingStep="+IntegerToString(TrailingStep));
     }
   if(OrderType()==OP_BUY)
     {
      pbid=MarketInfo(OrderSymbol(),MODE_BID);
      if(BE>0)
        {
         if((pbid-OrderOpenPrice())>BE*ppoint)
           {
            if((OrderStopLoss()-OrderOpenPrice())<0)
              {
               if(Debug){Print("Fall1");}
               ModSL(OrderOpenPrice()+0*ppoint+commissionsInPips);
              }
           }
        }
      if(TS>0)
        {
         if((pbid-OrderOpenPrice())>TS*ppoint)
           {
            if(OrderStopLoss()<(pbid-((TS+TrailingStep-1)*ppoint+commissionsInPips+StopLevelDouble*1.3)))
              {
               if((pbid-((TS+TrailingStep-1)*ppoint+commissionsInPips+StopLevelDouble*1.3))>OrderOpenPrice())
                 {
                  if(Debug){Print("Fall2: "+"Ask="+DoubleToStr(pbid,5)+";TS="+IntegerToString(TS)+";commissionInPips="+DoubleToStr(commissionsInPips,5));}
                  if(pbid>pbid-(TS*ppoint+commissionsInPips+StopLevelDouble*1.3))
                    {
                     ModSL(pbid-(TS*ppoint+commissionsInPips+StopLevelDouble*1.3));
                    }
                 }
               return;
              }
           }
        }
     }
   if(OrderType()==OP_SELL)
     {
      pask=MarketInfo(OrderSymbol(),MODE_ASK);
      if(BE>0)
        {
         if((OrderOpenPrice()-pask)>BE*ppoint)
           {
            if((OrderOpenPrice()-OrderStopLoss())<0)
              {
               if(Debug){Print("Fall3");}
               ModSL(OrderOpenPrice()-0*ppoint-commissionsInPips);
              }
           }
        }
      if(TS>0)
        {
         if(OrderOpenPrice()-pask>TS*ppoint)
           {
            if(OrderStopLoss()>(pask+((TS+TrailingStep-1)*ppoint+commissionsInPips+StopLevelDouble*1.3)) || OrderStopLoss()==0)
              {
               if((pask+((TS+TrailingStep-1)*ppoint+commissionsInPips+StopLevelDouble*1.3))<OrderOpenPrice())
                 {
                  if(Debug){Print("Fall4: "+"Ask="+DoubleToStr(pask,5)+";TS="+IntegerToString(TS)+";commissionInPips="+DoubleToStr(commissionsInPips,5));}
                  if(pask<pask+(TS*ppoint+commissionsInPips+StopLevelDouble*1.3))
                    {
                     ModSL(pask+(TS*ppoint+commissionsInPips+StopLevelDouble*1.3));
                    }
                 }
               return;
              }
           }
        }
     }
  }
//stop loss modification function
void ModSL(double ldSL)
  {
   if(Debug){Print("ldSL="+DoubleToStr(ldSL,5));}
   if(OrderModifyCheck(OrderTicket(),OrderOpenPrice(),ldSL,OrderTakeProfit()))
     {
      if(OrderType()==OP_BUY)
        {
         if(CheckStopLoss_Takeprofit(ORDER_TYPE_BUY,ldSL,OrderTakeProfit()))
           {
            bool fm;fm=OrderModify(OrderTicket(),OrderOpenPrice(),ldSL,OrderTakeProfit(),0,Red);
           }
        }
      if(OrderType()==OP_SELL)
        {
         if(CheckStopLoss_Takeprofit(ORDER_TYPE_SELL,ldSL,OrderTakeProfit()))
           {
            bool fm;fm=OrderModify(OrderTicket(),OrderOpenPrice(),ldSL,OrderTakeProfit(),0,Red);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CurrentCandleHasNoOpenedTrades()
  {
   bool positionCanBeOpened=false;
   int currentAlreadyOpenedPositions=0;
   if(OrdersTotal()>0)
     {
      for(int cnt=0;cnt<OrdersTotal();cnt++)
        {
         if(OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES)==true)
           {
            if((OrderType()==OP_SELL || OrderType()==OP_BUY) && OrderSymbol()==Symbol() && ((OrderMagicNumber()==MagicNumber)))
              {
               if(Period()==PERIOD_M1 || Period()==PERIOD_M5 || Period()==PERIOD_M15 || Period()==PERIOD_M30)
                 {
                  if(TimeMinute(Time[0])==TimeMinute(OrderOpenTime()))
                    {
                     positionCanBeOpened=false;
                       }else{
                     positionCanBeOpened=true;
                    }
                 }
               if(Period()==PERIOD_H1 || Period()==PERIOD_H4)
                 {
                  if(TimeHour(Time[0])==TimeHour(OrderOpenTime()))
                    {
                     positionCanBeOpened=false;
                       }else{
                     positionCanBeOpened=true;
                    }
                 }

               if(Period()==PERIOD_D1 || Period()==PERIOD_W1)
                 {
                  if(TimeDay(Time[0])==TimeDay(OrderOpenTime()))
                    {
                     positionCanBeOpened=false;
                       }else{
                     positionCanBeOpened=true;
                    }
                 }

               if(Period()==PERIOD_MN1)
                 {
                  if(TimeMinute(Time[0])==TimeMinute(OrderOpenTime()))
                    {
                     positionCanBeOpened=false;
                       }else{
                     positionCanBeOpened=true;
                    }
                 }
              }
           }
        }
        } else {
      positionCanBeOpened=true;
     }
   return positionCanBeOpened;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CurrentProfit(double CurProfit,double CurProfitOfUserPosis)
  {
   ObjectCreate("CurProfit",OBJ_LABEL,0,0,0);
   if(CurProfit>=0.0)
     {
      ObjectSetText("CurProfit","EA Profit: "+DoubleToString(CurProfit,2)+" "+AccountCurrency(),11,"Calibri",clrLime);
        }else{ObjectSetText("CurProfit","EA Profit: "+DoubleToString(CurProfit,2)+" "+AccountCurrency(),11,"Calibri",clrOrangeRed);
     }
   ObjectSet("CurProfit",OBJPROP_CORNER,1);
   ObjectSet("CurProfit",OBJPROP_XDISTANCE,5);
   ObjectSet("CurProfit",OBJPROP_YDISTANCE,40);

   if(HandleUserPositions)
     {
      ObjectCreate("CurProfitOfManualPlacedUserPositions",OBJ_LABEL,0,0,0);
      if(CurProfitOfUserPosis>=0.0)
        {
         ObjectSetText("CurProfitOfManualPlacedUserPositions",
                       "Profit(user positions): "+DoubleToString(CurProfitOfUserPosis,2)+" "+AccountCurrency(),11,"Calibri",clrLime);
           }else{ObjectSetText("CurProfitOfManualPlacedUserPositions",
                                 "Profit(user positions): "+DoubleToString(CurProfitOfUserPosis,2)+" "+AccountCurrency(),11,"Calibri",clrOrangeRed);
        }
      ObjectSet("CurProfitOfManualPlacedUserPositions",OBJPROP_CORNER,1);
      ObjectSet("CurProfitOfManualPlacedUserPositions",OBJPROP_XDISTANCE,5);
      ObjectSet("CurProfitOfManualPlacedUserPositions",OBJPROP_YDISTANCE,120);
     }

   ObjectCreate("MagicNumber",OBJ_LABEL,0,0,0);
   ObjectSetText("MagicNumber","MagicNumber: "+IntegerToString(MagicNumber),11,"Calibri",clrMediumVioletRed);
   ObjectSet("MagicNumber",OBJPROP_CORNER,1);
   ObjectSet("MagicNumber",OBJPROP_XDISTANCE,5);
   ObjectSet("MagicNumber",OBJPROP_YDISTANCE,60);

   ObjectCreate("NextLotSize",OBJ_LABEL,0,0,0);
   if(CurrentTotalLotSize>0.0)
     {ObjectSetText("NextLotSize","NextLotSize: "+DoubleToString(CurrentTotalLotSize,2),11,"Calibri",clrLightYellow);}
   else {ObjectSetText("NextLotSize","NextLotSize: "+DoubleToString(LotSize,2),11,"Calibri",clrLightYellow);}
   ObjectSet("NextLotSize",OBJPROP_CORNER,1);
   ObjectSet("NextLotSize",OBJPROP_XDISTANCE,5);
   ObjectSet("NextLotSize",OBJPROP_YDISTANCE,80);
/*ObjectCreate("EAName",OBJ_LABEL,0,0,0);
   ObjectSetText("EAName","EAName: "+EAName,11,"Calibri",clrGold);
   ObjectSet("EAName",OBJPROP_CORNER,1);
   ObjectSet("EAName",OBJPROP_XDISTANCE,5);
   ObjectSet("EAName",OBJPROP_YDISTANCE,75);*/

   if(CurrentLoss<0.0)
     {
      ObjectCreate("CurrentLoss",OBJ_LABEL,0,0,0);
      ObjectSetText("CurrentLoss","Current loss in %: "+DoubleToString(CurrentLoss,2),11,"Calibri",clrDeepPink);
      ObjectSet("CurrentLoss",OBJPROP_CORNER,1);
      ObjectSet("CurrentLoss",OBJPROP_XDISTANCE,5);
      ObjectSet("CurrentLoss",OBJPROP_YDISTANCE,100);
        } else {ObjectDelete("CurrentLoss");
     }

   if(!IsTesting() && trial_lic && TimeCurrent()>expiryDate) {ExpertRemove();}
   if(!IsTesting() && rent_lic && TimeCurrent()>rentExpiryDate) {ExpertRemove();}
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
int CloseAll()
  {
   bool rv=NO_ERROR;
   int numOfOrders=OrdersTotal();
   int FirstOrderType=0;

   for(int index=0; index<OrdersTotal(); index++)
     {
      bool oS=OrderSelect(index,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
        {
         FirstOrderType=OrderType();
         break;
        }
     }

   for(int index=numOfOrders-1; index>=0; index--)
     {
      bool oS=OrderSelect(index,SELECT_BY_POS,MODE_TRADES);

      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
         switch(OrderType())
           {
            case OP_BUY:
               if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),SLIPPAGE,Red))
               rv=AT_LEAST_ONE_FAILED;
               break;

            case OP_SELL:
               if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),SLIPPAGE,Red))
               rv=AT_LEAST_ONE_FAILED;
               break;

            case OP_BUYLIMIT:
            case OP_SELLLIMIT:
            case OP_BUYSTOP:
            case OP_SELLSTOP:
               if(!OrderDelete(OrderTicket()))
               rv=AT_LEAST_ONE_FAILED;
               break;
           }
     }

   return(rv);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Überprüft - ob noch eine Order gesetzt werden kann               |
//+------------------------------------------------------------------+
bool IsNewOrderAllowed()
  {
//--- Bekommen die Anzahl der erlaubten Pending Orders am Konto
   int max_allowed_orders=(int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);

//---  wenn es keine Beschränkungen gibt - geben true zurück, man kann auch Order absenden
   if(max_allowed_orders==0) return(true);

//--- wenn es bis zu dieser Stelle angekommen ist, bedeutet dies, dass eine Beschränkung gibt, wie viel Order schon gelten
   int orders=OrdersTotal();

//--- geben wir das Ergebnis des Vergleiches zurück
   return(orders<max_allowed_orders);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getContractProfitCalcMode()
  {
   int profitCalcMode=(int)MarketInfo(Symbol(),MODE_PROFITCALCMODE);
   return profitCalcMode;
  }
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb,double lots,int type)
  {
   double free_margin=AccountFreeMarginCheck(symb,type,lots);
//-- wenn es Geldmittel nicht ausreichend sind
   if(free_margin<0)
     {
      string oper=(type==OP_BUY)? "Buy":"Sell";
      Print("Not enough money for ",oper," ",lots," ",symb," Error code=",GetLastError());
      return(false);
     }
//-- die Überprüfung ist erfolgreich gelaufen
   return(true);
  }
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2)
  {
   if(NormalizeDouble(number1-number2,5)==0) return(true);
   else return(false);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| die Überprüfung der neuen Ebene-Werte vor der Modifikation der Order         |
//+------------------------------------------------------------------+
bool OrderModifyCheck(int ticket,double price,double sl,double tp)
  {
//--- Wählen wir die Order nach dem Ticket
   if(OrderSelect(ticket,SELECT_BY_TICKET))
     {
      //--- Die Größe des Punktes und des Symbol-Namens, nach dem die Pending Order gesetzt wurde
      string symbol=OrderSymbol();
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      //--- Überprüfen wir - ob es Änderungen im Eröffnungspreis gibt 
      bool PriceOpenChanged=true;
      int type=OrderType();
      if(!(type==OP_BUY || type==OP_SELL))
        {
         PriceOpenChanged=(MathAbs(OrderOpenPrice()-price)>point);
        }
      //--- Überprüfen wir - ob es Änderungen in der Ebene StopLoss gibt
      bool StopLossChanged=(MathAbs(OrderStopLoss()-sl)>point);
      //--- Überprüfen wir - ob es Änderungen in der Ebene Takeprofit gibt
      bool TakeProfitChanged=(MathAbs(OrderTakeProfit()-sl)>tp);
      //--- wenn es Änderungen in den Ebenen  gibt
      if(PriceOpenChanged || StopLossChanged || TakeProfitChanged)
         return(true);  // kann man diese Order modifizieren      
      //--- Änderungen gibt es nicht in den Eröffnungsebenen,StopLoss und Takeprofit 
      else
      //--- Berichten wir über den Fehler
         PrintFormat("Order #%d hat schon Ebene Open=%.5f SL=.5f TP=%.5f",
                     ticket,OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
     }
//--- kommen bis zu Ende, Änderungen für die Order nicht gibt
   return(false);       // es gibt keinen Sinn, zu modifizieren 
  }
//+------------------------------------------------------------------+
bool CheckStopLoss_Takeprofit(ENUM_ORDER_TYPE type,double SLT,double TPT)
  {
   int stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   if(stops_level!=0)
     {
      PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must be"+
                  " less %d points from close price",stops_level,stops_level);
     }
   bool SLT_check=false,TPT_check=false;
   switch(type)
     {
      case  ORDER_TYPE_BUY:
        {
         SLT_check=(Bid-SLT>stops_level*_Point);
         if(!SLT_check)
            PrintFormat("For order %s StopLoss=%.5f must be less than %.5f"+
                        " (Bid=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SLT,Bid-stops_level*_Point,Bid,stops_level);
         TPT_check=(TPT-Bid>stops_level*_Point);
         if(!TPT_check)
            PrintFormat("For order %s TakeProfit=%.5f must be greater than %.5f"+
                        " (Bid=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TPT,Bid+stops_level*_Point,Bid,stops_level);
         return(SLT_check&&TPT_check);
        }
      case  ORDER_TYPE_SELL:
        {
         SLT_check=(SLT-Ask>stops_level*_Point);
         if(!SLT_check)
            PrintFormat("For order %s StopLoss=%.5f must be greater than %.5f "+
                        " (Ask=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SLT,Ask+stops_level*_Point,Ask,stops_level);
         TPT_check=(Ask-TPT>stops_level*_Point);
         if(!TPT_check)
            PrintFormat("For order %s TakeProfit=%.5f must be less than %.5f "+
                        " (Ask=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TPT,Ask-stops_level*_Point,Ask,stops_level);
         return(TPT_check&&SLT_check);
        }
      break;
     }
   return false;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume)
  {
//--- minimal allowed volume for trade operations
   string description="";
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      PrintFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      PrintFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      Print(StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
            volume_step,ratio*volume_step));
      return(false);
     }
//if(description=="") {description="Correct volume value";}
//Print(description);
   return(true);
  }
//+-----------------------------------------------------------------+

bool NewBar()
  {
   static datetime lastbar;
   datetime curbar=Time[0];
   if(lastbar!=curbar)
     {
      lastbar=curbar;
      return(true);
     }
   else
     {
      return(false);
     }
  }
//+------------------------------------------------------------------+
