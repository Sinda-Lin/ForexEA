#property  copyright "baotu EA3.2 only for EURUSD M5"

//test

enum ENUM_Trading_Mode  {PendingLimitOrderFollowTrend = 0, PendingLimitOrderReversalTrend = 1, PendingStopOrderFollowTrend = 2, PendingStopOrderReversalTrend = 3};
enum ENUM_Candlestick_Mode {ToAvoidNews = 0, ToTriggerOrder = 1};

//------------------
extern  ENUM_Trading_Mode  TradingMode=3  ;   
extern bool UseMM=false ;   
extern double Risk=0.1  ;   // risk rate in %
extern double FixedLots=0.01  ;   
extern double LotsExponent=1.15  ;   
extern bool UseTakeProfit=false ;   
extern int   TakeProfit=200  ;   
extern bool UseStopLoss=false ;   
extern int   StopLoss=500  ;   
extern bool AutoTargetMoney=true  ;   
extern double TargetMoneyFactor=20  ;   
extern double TargetMoney=0  ;   
extern bool AutoStopLossMoney=false ;   
extern double StoplossFactor=0  ;   
extern double StoplossMoney=0  ;   
extern bool UseTrailing=false ;   
extern int   TrailingStop=20  ;   
extern int   TrailingStart=0  ;   
extern  ENUM_Candlestick_Mode  CandlestickMode=0  ;   
extern int   CandlestickHighLow=500  ;   
extern int   MaxOrderBuy=51  ;   
extern int   MaxOrderSell=51  ;   
extern int   PendingDistance=25  ;   
extern int   Pipstep=15  ;   
extern double PipstepExponent=1  ;   
extern double MaxSpreadPlusCommission=50  ;   //the cost of trading per lot
extern bool HighToLow=true  ;   //Chart object is high to low
extern double HighFibo=76.4  ;   
extern double LowFibo=23.6  ;   
extern int   StartBar=1  ;   
extern int   BarsBack=20  ;   
extern bool ShowFibo=true  ;   
extern int   Slippage=3  ;   
extern int   MagicNumber=6;  // identify number setting
extern string TradeComment="22版51"  ;  
extern bool TradeMonday=true  ;   
extern bool TradeTuesday=true  ;   
extern bool TradeWednesday=true  ;   
extern bool TradeThursday=true  ;   
extern bool TradeFriday=true  ;   
extern int   StartHour=0  ;   
extern int   StartMinute=0  ;   
extern int   EndHour=23  ;   
extern int   EndMinute=59  ;   
  
double    maxVolume = 10000.0;  // set an internal maximum volume
// set fibo line
double    fiboLevel_2 = 0.236;
double    fiboLevel_3 = 0.382;
double    fiboLevel_4 = 0.5;
double    fiboLevel_5 = 0.618;
double    fiboLevel_6 = 0.764;
double    fiboLevel_1 = 0.0;
double    fiboLevel_7 = 1.0;

uint      总_ui_9 = Blue;
uint      总_ui_10 = DarkGray;
// 
double    总_do11ko[];
double    总_do12ko[];
double    总_do13ko[];
double    总_do14ko[];
double    总_do15ko[];
double    总_do16ko[];
double    总_do17ko[];
double    总_do18ko[];

double    totalProfitBuy = 0.0; 
double    totalProfitSell = 0.0;
bool      总_bo_21 = false;
bool      总_bo_22 = false;
int       specifyOrder = 0;  // if specifyOrder > 0 && specifyOrder = MagicNumber, we only search specify order
int       pos_global = 0;
int       总_in_25 = 0;
int       总_in_26 = 0;
int       总_in_27 = 0;
int       总_in_28 = 0;
double    priceArray[30];
int       digits = 0;
double    pointSize = 0.0;
int       lotDigits = 0;
double    minFixedLots = 0.0;
double    maxLots = 0.0;
double    riskRate = 0.0;
double    cost = 0.0;
double    normPendingDistance = 0.0;
double    总_do_38 = 0.0;
double    总_do_39 = 0.0;
double    总_do_40 = 0.0;
double    总_do_41 = 0.0;
double    总_do_42 = 0.0;
double    总_do_43 = 0.0;
bool      总_bo_44 = false;
double    总_do_45 = 0.0;
int       总_in_46 = 0;
double    总_do_47 = 0.0;
bool      总_bo_48 = true;
double    总_do_49 = 240.0;
double    总_do_50 = 0.0;
int       总_in_51 = 0;
double    总_do_52 = 0.0;
double    总_do_53 = 0.0;
double    总_do_54 = 0.0;
double    总_do_55 = 0.0;
double    总_do_56 = 0.0; // target money buy
double    总_do_57 = 0.0; // target money sell
double    总_do_58 = 0.0; // stoploss money buy
double    总_do_59 = 0.0; // stoploss money sell

#import   "stdlib.ex4"
string ErrorDescription( int error_code);

int init()
{
   int       periodInSec;
   double    volumeStep;
   //----- -----

   ArrayInitialize(priceArray,0.0); 
   digits = MarketInfo(NULL,12) ; // MarketInfo-12: count of digits after decimal point in the symbol prices.
   pointSize = MarketInfo(NULL,11) ;  // MarketInfo-11: point size in the quote currency.
   Print("Digits: " + string(digits) + " Point: " + DoubleToString(pointSize,digits)); 
   volumeStep = MarketInfo(Symbol(),24); // step of changing lots.
   lotDigits = MathLog(volumeStep) / (-2.302585092994); // 0 or 1; number of digits after decimal point of lots.
   minFixedLots = MathMax(FixedLots,MarketInfo(Symbol(),23)); //MarketInfo-23: Minimum permitted amount of a lot.
   maxLots = MathMin(maxVolume,MarketInfo(Symbol(),25));  //MarketInfo-25: Maximum permitted amount of a lot
   riskRate = Risk / 100.0 ; 
   cost = NormalizeDouble(MaxSpreadPlusCommission *  pointSize, digits + 1) ; //normalize the cost per contract
   normPendingDistance = NormalizeDouble(PendingDistance * pointSize, digits) ; 
   总_do_43 = NormalizeDouble(pointSize * CandlestickHighLow, digits) ;
   总_bo_44 = false ;
   总_do_45 = NormalizeDouble(总_do_47 *  pointSize,digits + 1) ;
   if ( !(IsTesting()) )
   {
      if ( 总_bo_48 )
      {
         periodInSec = Period() ;
         switch(periodInSec)
         {
            case 1 :
            总_do_49 = 5.0 ;
               break;
            case 5 :
            总_do_49 = 15.0 ;
               break;
            case 15 :
            总_do_49 = 30.0 ;
               break;
            case 30 :
            总_do_49 = 60.0 ;
               break;
            case 60 :
            总_do_49 = 240.0 ;
               break;
            case 240 :
            总_do_49 = 1440.0 ;
               break;
            case 1440 :
            总_do_49 = 10080.0 ;
               break;
            case 10080 :
            总_do_49 = 43200.0 ;
               break;
            case 43200 :
            总_do_49 = 43200.0 ;
         }
      }
      总_do_50 = 0.0001 ;
   }
   DeleteAllObjects(); 
   SetIndexBuffer(0,总_do11ko); 
   SetIndexBuffer(1,总_do12ko); 
   SetIndexBuffer(2,总_do13ko); 
   SetIndexBuffer(3,总_do14ko); 
   SetIndexBuffer(4,总_do15ko); 
   SetIndexBuffer(5,总_do16ko); 
   SetIndexBuffer(6,总_do17ko); 
   SetIndexBuffer(7,总_do18ko); 
   SetIndexLabel(0,"Fibo_" + DoubleToString(fiboLevel_1,4)); 
   SetIndexLabel(1,"Fibo_" + DoubleToString(fiboLevel_2,4)); 
   SetIndexLabel(2,"Fibo_" + DoubleToString(fiboLevel_3,4)); 
   SetIndexLabel(3,"Fibo_" + DoubleToString(fiboLevel_4,4)); 
   SetIndexLabel(4,"Fibo_" + DoubleToString(fiboLevel_5,4)); 
   SetIndexLabel(5,"Fibo_" + DoubleToString(fiboLevel_6,4)); 
   SetIndexLabel(7,"Fibo_" + DoubleToString(fiboLevel_7,4)); 
   return(0); 
}
//init <<==
//---------- ----------  ---------- ----------

int start()
{
   bool      子_bo_1;
   string    子_st_2;
   datetime  子_da_3;
   double    子_do_4;
   double    子_do_5;
   double    子_do_6;
   double    子_do_7;
   int       子_in_8;
   string    子_st_9;
   int       子_in_10;
   double    子_do_11;
   double    子_do_12;
   int       子_in_13;
   int       子_in_14;
   bool      子_bo_15;
   double    子_do_16;
   double    子_do_17;
   double    子_do_18;
   double    子_do_19;
   double    volumeStep0;
   double    volumeStep1;
   double    volumeStep2;
   double    volumeStep3;
   double    volumeStep4;
   double    volumeStep5;
   double    volumeStep6;
   double    volumeStep7;
   int       子_in_28;
   int       子_in_29;
   double    子_do_30;
   double    子_do_31;
   int       子_in_32;
   int       子_in_33;
   double    子_do_34;
   double    子_do_35;
   double    子_do_36;
   double    子_do_37;
   double    子_do_38;
   double    子_do_39;
   double    子_do_40;
   double    子_do_41;
   double    子_do_42;
   int       子_in_43;
   double    子_do_44;
   double    子_do_45;
   int       子_in_46;
   double    子_do_47;
   double    子_do_48;
   double    子_do_49;
   double    子_do_50;
   double    子_do_51;
   double    子_do_52;
   int       子_in_53;
   string    子_st_54;
   //----- -----




   子_bo_1 = IsDemo() ;
   if ( !(子_bo_1) )
   {
   //Alert("You can not use the program with a real account!"); 
   //return(0); 
   }
   子_st_2 = "2016.8.25" ;
   子_da_3 = StringToTime(子_st_2) ;
   if ( TimeCurrent() >= 子_da_3 )
   {
   //Alert("The trial version has been expired!"); 
   //return(0); 
   }
   if ( ShowFibo == 1 )
   {
   CalcFibo(); 
   }
   子_do_4 = NormalizeDouble(Pipstep * MathPow(PipstepExponent,CountTradesSell ( )),0) ;
   子_do_5 = NormalizeDouble(Pipstep * MathPow(PipstepExponent,CountTradesBuy ( )),0) ;
   子_do_6 = FindLastSellPrice_Hilo ( ) ;
   子_do_7 = FindLastBuyPrice_Hilo ( ) ;
   子_in_8 = 0 ;
   子_in_10 = 0 ;
   子_do_11 = 0.0 ;
   子_do_12 = 0.0 ;
   子_in_13 = 0 ;
   子_in_14 = 0 ;
   子_bo_15 = false ;
   子_do_16 = 0.0 ;
   子_do_17 = 0.0 ;
   子_do_18 = 0.0 ;
   子_do_19 = 0.0 ;
   volumeStep0 = 0.0 ;
   volumeStep1 = 0.0 ;
   volumeStep2 = 0.0 ;
   volumeStep3 = 0.0 ;
   volumeStep4 = iHigh(NULL,0,0) ;
   volumeStep5 = iLow(NULL,0,0) ;
   volumeStep6 = iHigh(NULL,0,1) ;
   volumeStep7 = iLow(NULL,0,1) ;
   子_in_28 = 0 ;
   子_in_29 = 0 ;
   子_do_30 = 0.0 ;
   子_do_31 = 0.0 ;
   子_in_32 = iLowest(NULL,0,MODE_LOW,BarsBack,StartBar) ;
   子_in_33 = iHighest(NULL,0,MODE_HIGH,BarsBack,StartBar) ;
   子_do_34 = 0.0 ;
   子_do_35 = 0.0 ;
   子_do_31 = High[子_in_33] ;
   子_do_30 = Low[子_in_32] ;
   总_do_52 = 子_do_31 - 子_do_30 ;
   子_do_36 = LowFibo / 100.0 * 总_do_52 + 子_do_30 ;
   子_do_37 = 总_do_52 * 0.236 + 子_do_30 ;
   子_do_38 = 总_do_52 * 0.382 + 子_do_30 ;
   子_do_39 = 总_do_52 * 0.5 + 子_do_30 ;
   子_do_40 = 总_do_52 * 0.618 + 子_do_30 ;
   子_do_41 = 总_do_52 * 0.764 + 子_do_30 ;
   子_do_42 = HighFibo / 100.0 * 总_do_52 + 子_do_30 ;
   if ( !(总_bo_44) )
   {
   for (子_in_43 = OrdersHistoryTotal() - 1 ; 子_in_43 >= 0 ; 子_in_43 = 子_in_43 - 1)
   {
   if ( !(OrderSelect(子_in_43,SELECT_BY_POS,MODE_HISTORY)) || !(OrderProfit()!=0.0) || !(OrderClosePrice()!=OrderOpenPrice()) || OrderSymbol() != Symbol() )   continue;
   总_bo_44 = true ;
   子_do_12=MathAbs(OrderProfit() / (OrderClosePrice() - OrderOpenPrice()));
   总_do_45 = ( -(OrderCommission())) / 子_do_12 ;
   break;

   }
   }
   子_do_17 = NormalizeDouble(AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15),lotDigits) ;
   if ( !(UseMM) )
   {
   子_do_17 = FixedLots ;
   }
   总_do_57 = 子_do_17 * TargetMoneyFactor * CountTradesSell ( ) * LotsExponent ;
   if ( !(AutoTargetMoney) )
   {
   总_do_57 = TargetMoney ;
   }
   总_do_56 = 子_do_17 * TargetMoneyFactor * CountTradesBuy ( ) * LotsExponent ;
   if ( !(AutoTargetMoney) )
   {
   总_do_56 = TargetMoney ;
   }
   总_do_59 = 子_do_17 * StoplossFactor * CountTradesSell ( ) * LotsExponent ;
   if ( !(AutoStopLossMoney) )
   {
   总_do_59 = StoplossMoney ;
   }
   总_do_58 = 子_do_17 * StoplossFactor * CountTradesBuy ( ) * LotsExponent ;
   if ( !(AutoStopLossMoney) )
   {
   总_do_58 = StoplossMoney ;
   }
   子_do_44 = Ask - Bid ;
   ArrayCopy(priceArray,priceArray,0,1,29); 
   priceArray[29] = 子_do_44;
   if ( 总_in_46 <  30 )
   {
   总_in_46=总_in_46 + 1;
   }
   子_do_45 = 0.0 ;
   子_in_43 = 29 ;
   for (子_in_46 = 0 ; 子_in_46 < 总_in_46 ; 子_in_46 = 子_in_46 + 1)
   {
   子_do_45 = 子_do_45 + priceArray[子_in_43] ;
   子_in_43 = 子_in_43 - 1;
   }
   子_do_47 = 子_do_45 / 总_in_46 ;
   子_do_48 = NormalizeDouble(Ask + 总_do_45,digits) ;
   子_do_49 = NormalizeDouble(Bid - 总_do_45,digits) ;
   子_do_50 = NormalizeDouble(子_do_47 + 总_do_45,digits + 1) ;
   子_do_51 = volumeStep4 - volumeStep5 ;
   子_do_52 = volumeStep6 - volumeStep7 ;
   if ( Bid - 子_do_6>=子_do_4 * Point() )
   {
   总_in_25 = MaxOrderSell ;
   }
   else
   {
   总_in_25 = 1 ;
   }
   if ( 子_do_7 - Ask>=子_do_5 * Point() )
   {
   总_in_26 = MaxOrderBuy ;
   }
   else
   {
   总_in_26 = 1 ;
   }
   if ( CandlestickMode != 0 )
   {
   if ( CandlestickMode == 1 && 子_do_51>总_do_43 )
   {
   if ( Bid>子_do_42 )
      {
      子_in_13 = -1 ;
      }
   else
      {
      if ( Bid<子_do_36 )
      {
      子_in_13 = 1 ;
   }}}}
   else
   {
   if ( 子_do_51<=总_do_43 && 子_do_52<=总_do_43 )
   {
   if ( Bid>子_do_42 )
      {
      子_in_13 = -1 ;
      }
   else
      {
      if ( Bid<子_do_36 )
      {
      子_in_13 = 1 ;
   }}}}
   子_in_53 = 0 ;
   for (子_in_43 = 0 ; 子_in_43 < OrdersTotal() ; 子_in_43 = 子_in_43 + 1)
   {
   if ( !(OrderSelect(子_in_43,SELECT_BY_POS,MODE_TRADES)) || OrderMagicNumber() != MagicNumber )   continue;
   子_in_14 = OrderType() ;
   if ( 子_in_14 == 0 || 子_in_14 == 1 || OrderSymbol() != Symbol() )   continue;
   子_in_53 = 子_in_53 + 1;
   switch(子_in_14)
   {
   case 4 :
      子_do_16 = NormalizeDouble(OrderOpenPrice(),digits) ;
      子_do_11 = NormalizeDouble(Ask + normPendingDistance,digits) ;
      if ( !(子_do_11<子_do_16) )   break;
      volumeStep0 = NormalizeDouble(子_do_11 - StopLoss * Point(),digits) ;
      volumeStep1 = NormalizeDouble(TakeProfit * Point() + 子_do_11,digits) ;
      volumeStep3 = volumeStep0 ;
      if ( !(UseStopLoss) )
      {
      volumeStep3 = 0.0 ;
      }
      volumeStep2 = volumeStep1 ;
      if ( !(UseTakeProfit) )
      {
      volumeStep2 = 0.0 ;
      }
      if ( OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() )
      {
      子_bo_15 = OrderModify(OrderTicket(),子_do_11,volumeStep3,volumeStep2,0,Blue) ;
      }
      if ( 子_bo_15 )   break;
      子_in_8 = GetLastError() ;
      子_st_9 = ErrorDescription(子_in_8) ;
      Print("BUYSTOP Modify Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
   case 5 :
      子_do_16 = NormalizeDouble(OrderOpenPrice(),digits) ;
      子_do_11 = NormalizeDouble(Bid - normPendingDistance,digits) ;
      if ( !(子_do_11>子_do_16) )   break;
      volumeStep0 = NormalizeDouble(StopLoss * Point() + 子_do_11,digits) ;
      volumeStep1 = NormalizeDouble(子_do_11 - TakeProfit * Point(),digits) ;
      volumeStep3 = volumeStep0 ;
      if ( !(UseStopLoss) )
      {
      volumeStep3 = 0.0 ;
      }
      volumeStep2 = volumeStep1 ;
      if ( !(UseTakeProfit) )
      {
      volumeStep2 = 0.0 ;
      }
      if ( OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() )
      {
      子_bo_15 = OrderModify(OrderTicket(),子_do_11,volumeStep3,volumeStep2,0,Red) ;
      }
      if ( 子_bo_15 )   break;
      子_in_8 = GetLastError() ;
      子_st_9 = ErrorDescription(子_in_8) ;
      Print("SELLSTOP Modify Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
   case 3 :
      子_do_16 = NormalizeDouble(OrderOpenPrice(),digits) ;
      子_do_11 = NormalizeDouble(Bid + normPendingDistance,digits) ;
      if ( !(子_do_11<子_do_16) )   break;
      volumeStep0 = NormalizeDouble(StopLoss * Point() + 子_do_11,digits) ;
      volumeStep1 = NormalizeDouble(子_do_11 - TakeProfit * Point(),digits) ;
      volumeStep3 = volumeStep0 ;
      if ( !(UseStopLoss) )
      {
      volumeStep3 = 0.0 ;
      }
      volumeStep2 = volumeStep1 ;
      if ( !(UseTakeProfit) )
      {
      volumeStep2 = 0.0 ;
      }
      if ( OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() )
      {
      子_bo_15 = OrderModify(OrderTicket(),子_do_11,volumeStep3,volumeStep2,0,Red) ;
      }
      if ( 子_bo_15 )   break;
      子_in_8 = GetLastError() ;
      子_st_9 = ErrorDescription(子_in_8) ;
      Print("BUYLIMIT Modify Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
   case 2 :
      子_do_16 = NormalizeDouble(OrderOpenPrice(),digits) ;
      子_do_11 = NormalizeDouble(Ask - normPendingDistance,digits) ;
      if ( !(子_do_11>子_do_16) )   break;
      volumeStep0 = NormalizeDouble(子_do_11 - StopLoss * Point(),digits) ;
      volumeStep1 = NormalizeDouble(TakeProfit * Point() + 子_do_11,digits) ;
      volumeStep3 = volumeStep0 ;
      if ( !(UseStopLoss) )
      {
      volumeStep3 = 0.0 ;
      }
      volumeStep2 = volumeStep1 ;
      if ( !(UseTakeProfit) )
      {
      volumeStep2 = 0.0 ;
      }
      if ( OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() )
      {
      子_bo_15 = OrderModify(OrderTicket(),子_do_11,volumeStep3,volumeStep2,0,Blue) ;
      }
      if ( 子_bo_15 )   break;
      子_in_8 = GetLastError() ;
      子_st_9 = ErrorDescription(子_in_8) ;
      Print("SELLLIMIT Modify Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
   }
   }
   if ( CountTradesBuy ( ) == 0 )
   {
   总_bo_21 = false ;
   }
   if ( CountTradesSell ( ) == 0 )
   {
   总_bo_22 = false ;
   }
   TotalProfitbuy ( ); 
   TotalProfitsell ( ); 
   ChartComment(); 
   if ( ( ( 总_do_56>0.0 && totalProfitBuy>=总_do_56 ) || ( -(总_do_58)<0.0 && totalProfitBuy<= -(总_do_58)) ) )
   {
   总_bo_21 = true ;
   }
   if ( 总_bo_21 )
   {
   OpenOrdClose ( ); 
   }
   if ( ( ( 总_do_57>0.0 && totalProfitSell>=总_do_57 ) || ( -(总_do_59)<0.0 && totalProfitSell<= -(总_do_59)) ) )
   {
   总_bo_22 = true ;
   }
   if ( 总_bo_22 )
   {
   OpenOrdClose2 ( ); 
   }
   if ( UseTrailing )
   {
   MoveTrailingStop(); 
   }
   if ( !(TradeMonday) && DayOfWeek() == 1 )
   {
   return(0); 
   }
   if ( !(TradeTuesday) && DayOfWeek() == 2 )
   {
   return(0); 
   }
   if ( !(TradeWednesday) && DayOfWeek() == 3 )
   {
   return(0); 
   }
   if ( !(TradeThursday) && DayOfWeek() == 4 )
   {
   return(0); 
   }
   if ( !(TradeFriday) && DayOfWeek() == 5 )
   {
   return(0); 
   }
   switch(TradingMode)
   {
   case 0 :
   if ( Bid<子_do_36 && CountTradesSell ( ) >= 总_in_25 )
      {
      return(0); 
      }
   if ( !(Bid>子_do_42) || CountTradesBuy ( ) < 总_in_26 )   break;
   return(0); 
   case 2 :
   if ( Bid<子_do_36 && CountTradesSell ( ) >= 总_in_25 )
      {
      return(0); 
      }
   if ( !(Bid>子_do_42) || CountTradesBuy ( ) < 总_in_26 )   break;
   return(0); 
   case 1 :
   if ( Bid>子_do_42 && CountTradesSell ( ) >= 总_in_25 )
      {
      return(0); 
      }
   if ( !(Bid<子_do_36) || CountTradesBuy ( ) < 总_in_26 )   break;
   return(0); 
   case 3 :
   if ( Bid>子_do_42 && CountTradesSell ( ) >= 总_in_25 )
      {
      return(0); 
      }
   if ( !(Bid<子_do_36) || CountTradesBuy ( ) < 总_in_26 )   break;
   return(0); 
   }
   switch(TradingMode)
   {
   case 0 :
   if ( 子_in_53 != 0 || 子_in_13 == 0 || !(子_do_50<=cost) || !(f0_4 ( )) )   break;
   子_do_17 = AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15) ;
   if ( !(UseMM) )
      {
      子_do_17 = FixedLots ;
      }
   子_do_18 = NormalizeDouble(子_do_17 * MathPow(LotsExponent,CountTradesBuy ( )),digits) ;
   子_do_18 = MathMax(minFixedLots,子_do_18) ;
   子_do_18 = MathMin(maxLots,子_do_18) ;
   子_do_19 = NormalizeDouble(子_do_17 * MathPow(LotsExponent,CountTradesSell ( )),digits) ;
   子_do_19 = MathMax(minFixedLots,子_do_19) ;
   子_do_19 = MathMin(maxLots,子_do_19) ;
   if ( 子_in_13 <  0 )
      {
      子_do_11 = NormalizeDouble(Ask - normPendingDistance,digits) ;
      volumeStep0 = NormalizeDouble(子_do_11 - StopLoss * Point(),digits) ;
      volumeStep1 = NormalizeDouble(TakeProfit * Point() + 子_do_11,digits) ;
      volumeStep3 = volumeStep0 ;
      if ( !(UseStopLoss) )
      {
      volumeStep3 = 0.0 ;
      }
      volumeStep2 = volumeStep1 ;
      if ( !(UseTakeProfit) )
      {
      volumeStep2 = 0.0 ;
      }
      子_in_10 = OrderSend(Symbol(),OP_BUYLIMIT,子_do_18,子_do_11,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Blue) ;
      if ( 子_in_10 > 0 )   break;
      子_in_8 = GetLastError() ;
      子_st_9 = ErrorDescription(子_in_8) ;
      Print("BUYLIMIT Send Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " LT: " + DoubleToString(子_do_18,digits) + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
   }
   子_do_11 = NormalizeDouble(Bid + normPendingDistance,digits) ;
   volumeStep0 = NormalizeDouble(StopLoss * Point() + 子_do_11,digits) ;
   volumeStep1 = NormalizeDouble(子_do_11 - TakeProfit * Point(),digits) ;
   volumeStep3 = volumeStep0 ;
   if ( !(UseStopLoss) )
   {
   volumeStep3 = 0.0 ;
   }
   volumeStep2 = volumeStep1 ;
   if ( !(UseTakeProfit) )
   {
   volumeStep2 = 0.0 ;
   }
   子_in_10 = OrderSend(Symbol(),OP_SELLLIMIT,子_do_19,子_do_11,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Red) ;
   if ( 子_in_10 > 0 )   break;
   子_in_8 = GetLastError() ;
   子_st_9 = ErrorDescription(子_in_8) ;
   Print("SELLLIMIT Send Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " LT: " + DoubleToString(子_do_19,digits) + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
      break;
   case 1 :
   if ( 子_in_53 != 0 || 子_in_13 == 0 || !(子_do_50<=cost) || !(f0_4 ( )) )   break;
   子_do_17 = AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15) ;
   if ( !(UseMM) )
      {
      子_do_17 = FixedLots ;
      }
   子_do_18 = NormalizeDouble(子_do_17 * MathPow(LotsExponent,CountTradesBuy ( )),digits) ;
   子_do_18 = MathMax(minFixedLots,子_do_18) ;
   子_do_18 = MathMin(maxLots,子_do_18) ;
   子_do_19 = NormalizeDouble(子_do_17 * MathPow(LotsExponent,CountTradesSell ( )),digits) ;
   子_do_19 = MathMax(minFixedLots,子_do_19) ;
   子_do_19 = MathMin(maxLots,子_do_19) ;
   if ( 子_in_13 <  0 )
      {
      子_do_11 = NormalizeDouble(Bid + normPendingDistance,digits) ;
      volumeStep0 = NormalizeDouble(StopLoss * Point() + 子_do_11,digits) ;
      volumeStep1 = NormalizeDouble(子_do_11 - TakeProfit * Point(),digits) ;
      volumeStep3 = volumeStep0 ;
      if ( !(UseStopLoss) )
      {
      volumeStep3 = 0.0 ;
      }
      volumeStep2 = volumeStep1 ;
      if ( !(UseTakeProfit) )
      {
      volumeStep2 = 0.0 ;
      }
      子_in_10 = OrderSend(Symbol(),OP_SELLLIMIT,子_do_19,子_do_11,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Red) ;
      if ( 子_in_10 > 0 )   break;
      子_in_8 = GetLastError() ;
      子_st_9 = ErrorDescription(子_in_8) ;
      Print("SELLLIMIT Send Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " LT: " + DoubleToString(子_do_19,digits) + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
   }
   子_do_11 = NormalizeDouble(Ask - normPendingDistance,digits) ;
   volumeStep0 = NormalizeDouble(子_do_11 - StopLoss * Point(),digits) ;
   volumeStep1 = NormalizeDouble(TakeProfit * Point() + 子_do_11,digits) ;
   volumeStep3 = volumeStep0 ;
   if ( !(UseStopLoss) )
   {
   volumeStep3 = 0.0 ;
   }
   volumeStep2 = volumeStep1 ;
   if ( !(UseTakeProfit) )
   {
   volumeStep2 = 0.0 ;
   }
   子_in_10 = OrderSend(Symbol(),OP_BUYLIMIT,子_do_18,子_do_11,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Blue) ;
   if ( 子_in_10 > 0 )   break;
   子_in_8 = GetLastError() ;
   子_st_9 = ErrorDescription(子_in_8) ;
   Print("BUYLIMIT Send Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " LT: " + DoubleToString(子_do_18,digits) + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
      break;
   case 2 :
   if ( 子_in_53 != 0 || 子_in_13 == 0 || !(子_do_50<=cost) || !(f0_4 ( )) )   break;
   子_do_17 = AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15) ;
   if ( !(UseMM) )
      {
      子_do_17 = FixedLots ;
      }
   子_do_18 = NormalizeDouble(子_do_17 * MathPow(LotsExponent,CountTradesBuy ( )),digits) ;
   子_do_18 = MathMax(minFixedLots,子_do_18) ;
   子_do_18 = MathMin(maxLots,子_do_18) ;
   子_do_19 = NormalizeDouble(子_do_17 * MathPow(LotsExponent,CountTradesSell ( )),digits) ;
   子_do_19 = MathMax(minFixedLots,子_do_19) ;
   子_do_19 = MathMin(maxLots,子_do_19) ;
   if ( 子_in_13 <  0 )
      {
      子_do_11 = NormalizeDouble(Ask + normPendingDistance,digits) ;
      volumeStep0 = NormalizeDouble(子_do_11 - StopLoss * Point(),digits) ;
      volumeStep1 = NormalizeDouble(TakeProfit * Point() + 子_do_11,digits) ;
      volumeStep3 = volumeStep0 ;
      if ( !(UseStopLoss) )
      {
      volumeStep3 = 0.0 ;
      }
      volumeStep2 = volumeStep1 ;
      if ( !(UseTakeProfit) )
      {
      volumeStep2 = 0.0 ;
      }
      子_in_10 = OrderSend(Symbol(),OP_BUYSTOP,子_do_18,子_do_11,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Blue) ;
      if ( 子_in_10 > 0 )   break;
      子_in_8 = GetLastError() ;
      子_st_9 = ErrorDescription(子_in_8) ;
      Print("BUYSTOP Send Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " LT: " + DoubleToString(子_do_18,digits) + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
   }
   子_do_11 = NormalizeDouble(Bid - normPendingDistance,digits) ;
   volumeStep0 = NormalizeDouble(StopLoss * Point() + 子_do_11,digits) ;
   volumeStep1 = NormalizeDouble(子_do_11 - TakeProfit * Point(),digits) ;
   volumeStep3 = volumeStep0 ;
   if ( !(UseStopLoss) )
   {
   volumeStep3 = 0.0 ;
   }
   volumeStep2 = volumeStep1 ;
   if ( !(UseTakeProfit) )
   {
   volumeStep2 = 0.0 ;
   }
   子_in_10 = OrderSend(Symbol(),OP_SELLSTOP,子_do_19,子_do_11,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Red) ;
   if ( 子_in_10 > 0 )   break;
   子_in_8 = GetLastError() ;
   子_st_9 = ErrorDescription(子_in_8) ;
   Print("SELLSTOP Send Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " LT: " + DoubleToString(子_do_19,digits) + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
      break;
   case 3 :
   if ( 子_in_53 != 0 || 子_in_13 == 0 || !(子_do_50<=cost) || !(f0_4 ( )) )   break;
   子_do_17 = AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15) ;
   if ( !(UseMM) )
      {
      子_do_17 = FixedLots ;
      }
   子_do_18 = NormalizeDouble(子_do_17 * MathPow(LotsExponent,CountTradesBuy ( )),digits) ;
   子_do_18 = MathMax(minFixedLots,子_do_18) ;
   子_do_18 = MathMin(maxLots,子_do_18) ;
   子_do_19 = NormalizeDouble(子_do_17 * MathPow(LotsExponent,CountTradesSell ( )),digits) ;
   子_do_19 = MathMax(minFixedLots,子_do_19) ;
   子_do_19 = MathMin(maxLots,子_do_19) ;
   if ( 子_in_13 <  0 )
      {
      子_do_11 = NormalizeDouble(Bid - normPendingDistance,digits) ;
      volumeStep0 = NormalizeDouble(StopLoss * Point() + 子_do_11,digits) ;
      volumeStep1 = NormalizeDouble(子_do_11 - TakeProfit * Point(),digits) ;
      volumeStep3 = volumeStep0 ;
      if ( !(UseStopLoss) )
      {
      volumeStep3 = 0.0 ;
      }
      volumeStep2 = volumeStep1 ;
      if ( !(UseTakeProfit) )
      {
      volumeStep2 = 0.0 ;
      }
      子_in_10 = OrderSend(Symbol(),OP_SELLSTOP,子_do_19,子_do_11,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Red) ;
      if ( 子_in_10 > 0 )   break;
      子_in_8 = GetLastError() ;
      子_st_9 = ErrorDescription(子_in_8) ;
      Print("SELLSTOP Send Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " LT: " + DoubleToString(子_do_19,digits) + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
   }
   子_do_11 = NormalizeDouble(Ask + normPendingDistance,digits) ;
   volumeStep0 = NormalizeDouble(子_do_11 - StopLoss * Point(),digits) ;
   volumeStep1 = NormalizeDouble(TakeProfit * Point() + 子_do_11,digits) ;
   volumeStep3 = volumeStep0 ;
   if ( !(UseStopLoss) )
   {
   volumeStep3 = 0.0 ;
   }
   volumeStep2 = volumeStep1 ;
   if ( !(UseTakeProfit) )
   {
   volumeStep2 = 0.0 ;
   }
   子_in_10 = OrderSend(Symbol(),OP_BUYSTOP,子_do_18,子_do_11,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Blue) ;
   if ( 子_in_10 > 0 )   break;
   子_in_8 = GetLastError() ;
   子_st_9 = ErrorDescription(子_in_8) ;
   Print("BUYSTOP Send Error Code: " + string(子_in_8) + " Message: " + 子_st_9 + " LT: " + DoubleToString(子_do_18,digits) + " OP: " + DoubleToString(子_do_11,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
   }
   子_st_54 = "AvgSpread:" + DoubleToString(子_do_47,digits) + "  Commission rate:" + DoubleToString(总_do_45,digits + 1) + "  Real avg. spread:" + DoubleToString(子_do_50,digits + 1) ;
   if ( 子_do_50>cost )
   {
   子_st_54 = 子_st_54 + "\n" + "The EA can not run with this spread ( " + DoubleToString(子_do_50,digits + 1) + " > " + DoubleToString(cost,digits + 1) + " )" ;
   }
   return(0); 
}
//start <<==
//---------- ----------  ---------- ----------

int deinit()
{
   Comment(""); 
   DeleteAllObjects ( ); 
   return(0); 
}
//deinit <<==
//---------- ----------  ---------- ----------

int f0_4()
// function to control the running time, return 1 to run, return 0 to stop
{
   if ( ( ( Hour() > StartHour && Hour() < EndHour ) || ( Hour() == StartHour && Minute() >= StartMinute ) || (Hour() == EndHour && Minute() <  EndMinute) ) )
   {
      return(1); 
   }
   return(0); 
}
//f0_4 <<==
//---------- ----------  ---------- ----------

void MoveTrailingStop()
// move trailing stop loss price
{
   int pos;
   //----- -----
   for(pos = 0; pos < OrdersTotal(); pos++)
   {
      if(!(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) || OrderType() > 1 || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber )   continue;
      //check the specified order is openning 
      if ( OrderType() == 0 ) // buy order
      {
         if ( TrailingStop <= 0 || !(NormalizeDouble(Ask - TrailingStart * Point(),Digits()) > NormalizeDouble(TrailingStop * Point() + OrderOpenPrice(),Digits())) )   continue;

         if ( ( !(NormalizeDouble(OrderStopLoss(),Digits())<NormalizeDouble(Bid - TrailingStop * Point(),Digits())) && !(OrderStopLoss()==0.0) ) || !(OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid - TrailingStop * Point(),Digits()),OrderTakeProfit(),0,Blue)) || GetLastError() != 0 )   continue;
         Print(Symbol() + ": Trailing Buy OrderModify ok "); 
            continue;
      }
      if ( TrailingStop <= 0 || !(NormalizeDouble(TrailingStart * Point() + Bid,Digits())<NormalizeDouble(OrderOpenPrice() - TrailingStop * Point(),Digits())) )   continue;

      if ( ( !(NormalizeDouble(OrderStopLoss(),Digits())>NormalizeDouble(TrailingStop * Point() + Ask,Digits())) && !(OrderStopLoss()==0.0) ) || !(OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(TrailingStop * Point() + Ask,Digits()),OrderTakeProfit(),0,Red)) || GetLastError() != 0 )   continue;
      Print(Symbol() + ": Trailing Sell OrderModify ok "); 
   }
}
//MoveTrailingStop <<==
//---------- ----------  ---------- ----------

int ScanOpenTrades()
{
   int orderAmount;
   int openTrades;
   int pos;
   //----- -----
   orderAmount = OrdersTotal() ;
   openTrades = 0 ;
   for(pos = 0; pos <= orderAmount - 1 ; pos = pos + 1)
   {
      if(!(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) || OrderType() > 1)   continue;

      if(specifyOrder > 0 && OrderMagicNumber() == specifyOrder )
      {
         openTrades = openTrades + 1;
      }
      if ( specifyOrder != 0 )   continue;
      openTrades = openTrades + 1;
   }
   return(openTrades); 
}
//ScanOpenTrades <<==
//---------- ----------  ---------- ----------

int ScanOpenTradessymbol()
//Scan opening trades with specify symbol
{
   int       orderAmount;
   int       openTrades;
   int       pos;
   //----- -----
   orderAmount = OrdersTotal() ;
   openTrades = 0 ;
   for (pos = 0 ; pos <= orderAmount - 1 ; pos = pos + 1)
   {
      if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) || OrderType() > 1 )   continue;

      if ( OrderSymbol() == Symbol() && specifyOrder > 0 && OrderMagicNumber() == specifyOrder )
      {
      openTrades = openTrades + 1;
      }
      if ( OrderSymbol() != Symbol() || specifyOrder != 0 )   continue;
      openTrades = openTrades + 1;
   }
   return(openTrades); 
}
//ScanOpenTradessymbol <<==
//---------- ----------  ---------- ----------

void OpenOrdClose()
//close opening buy order and buy pending order
{
   int       orderAmount;
   int       pos;
   int       orderType;
   bool      orderclosed; //if the order closed successfully
   bool      orderClosing; // order closing switch
   //----- -----
   orderClosing = false ;
   orderAmount = OrdersTotal() ;
   for (pos = 0 ; pos < orderAmount ; pos = pos + 1)
   {
      if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) )   continue;
      orderType = OrderType() ;
      orderclosed = false ;
      orderClosing = false ;
      if ( OrderSymbol() == Symbol() && MagicNumber > 0 && OrderMagicNumber() == MagicNumber )
      {
         orderClosing = true ;
      }
      else
      {
         if ( OrderSymbol() == Symbol() && MagicNumber == 0 )
         {
            orderClosing = true ;
         }
      }
      if ( !(orderClosing) )   continue;
      switch(orderType)
      {
         case 0 :
            orderclosed = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),9),Slippage,Blue) ;
            break;
         case 2 :
            if ( !(OrderDelete(OrderTicket(),0xFFFFFFFF)) )   break;
         case 4 :
            if ( !(OrderDelete(OrderTicket(),0xFFFFFFFF)) )   break;
         default :
            if ( orderclosed )   break;
            Print(" OrderClose failed with error #",GetLastError()); 
            Sleep(3000); 
      }
   }
}
//OpenOrdClose <<==
//---------- ----------  ---------- ----------

void OpenOrdClose2()
//close opening sell order and sell pending order
{
   int       orderAmount;
   int       pos;
   int       orderType;
   bool      orderclosed;
   bool      orderClosing;
   //----- -----
   orderClosing = false ;
   orderAmount = OrdersTotal() ;
   for (pos = 0 ; pos < orderAmount ; pos = pos + 1)
   {
      if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) )   continue;
      orderType = OrderType() ;
      orderclosed = false ;
      orderClosing = false ;
      if ( OrderSymbol() == Symbol() && MagicNumber > 0 && OrderMagicNumber() == MagicNumber )
      {
         orderClosing = true ;
      }
      else
      {
         if ( OrderSymbol() == Symbol() && MagicNumber == 0 )
         {
            orderClosing = true ;
         }
      }
      if ( !(orderClosing) )   continue;
      switch(orderType)
      {
         case 1 :
            orderclosed = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),10),Slippage,Red) ;
         break;
         case 3 :
            if ( !(OrderDelete(OrderTicket(),0xFFFFFFFF)) )   break;
         case 5 :
            if ( !(OrderDelete(OrderTicket(),0xFFFFFFFF)) )   break;
            default :
            if ( orderclosed )   break;
            Print(" OrderClose failed with error #",GetLastError()); 
            Sleep(3000); 
      }
   }
}
//OpenOrdClose2 <<==
//---------- ----------  ---------- ----------

void TotalProfitbuy()
//calculate the total profit of opening buy orders
{
   int       orderAmount;
   int       pos;
   int       orderType;
   bool      isThatOrder;
   //----- -----
   orderAmount = OrdersTotal() ;
   totalProfitBuy = 0.0 ;
   for (pos = 0 ; pos < orderAmount ; pos = pos + 1)
   {
      if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) )   continue;
      orderType = OrderType() ;
      isThatOrder = false ;
      if ( OrderSymbol() == Symbol() && MagicNumber > 0 && OrderMagicNumber() == MagicNumber )
      {
         isThatOrder = true ;
      }
      else
      {
         if ( OrderSymbol() == Symbol() && MagicNumber == 0 )
         {
            isThatOrder = true ;
         }
      }
      if ( !(isThatOrder) || orderType != 0 )   continue;
      totalProfitBuy = OrderProfit() + OrderCommission() + OrderSwap() + totalProfitBuy ;
   }
}
//TotalProfitbuy <<==
//---------- ----------  ---------- ----------

void TotalProfitsell()
//calculate the total profit of opening sell orders
{
   int       orderAmount;
   int       pos;
   int       orderType;
   bool      isThatOrder;
   //----- -----
   orderAmount = OrdersTotal() ;
   totalProfitSell = 0.0 ;
   for (pos = 0 ; pos < orderAmount ; pos = pos + 1)
   {
      if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) )   continue;
      orderType = OrderType() ;
      isThatOrder = false ;
      if ( OrderSymbol() == Symbol() && MagicNumber > 0 && OrderMagicNumber() == MagicNumber )
      {
         isThatOrder = true ;
      }
      else
      {
         if ( OrderSymbol() == Symbol() && MagicNumber == 0 )
         {
            isThatOrder = true ;
         }
      }
      if ( !(isThatOrder) || orderType != 1 )   continue;
      totalProfitSell = OrderProfit() + OrderCommission() + OrderSwap() + totalProfitSell ;
   }
}
//TotalProfitsell <<==
//---------- ----------  ---------- ----------

void ChartComment()
//show account infomation and trading information on the current chart
{
   string    mainComment;
   string    separation;
   string    br;
   //----- -----
   mainComment = "" ;
   separation = "----------------------------------------\n" ;
   br = "\n" ;
   mainComment = "----------------------------------------\n" ;
   mainComment = "----------------------------------------\nName = " + AccountName() + "\n" ;
   mainComment = mainComment + "Broker" + " " + "=" + " " + AccountCompany() + "\n" ;
   mainComment = mainComment + "Account Leverage" + " " + "=" + " " + "1:" + DoubleToString(AccountLeverage(),0) + "\n" ;
   mainComment = mainComment + "Account Balance" + " " + "=" + " " + DoubleToString(AccountBalance(),2) + "\n" ;
   mainComment = mainComment + "Account Equity" + " " + "=" + " " + DoubleToString(AccountEquity(),2) + "\n" ;
   mainComment = mainComment + "Day Profit" + " " + "=" + " " + DoubleToString(AccountBalance() - startBalanceD1(),2) + br ;
   mainComment = mainComment + separation;
   mainComment = mainComment + "Open ALL Positions = " + string(ScanOpenTrades()) + br ;
   mainComment = mainComment + Symbol() + " ALL Order = " + string(ScanOpenTradessymbol()) + br ;
   mainComment = mainComment + "Open Buy  = " + string(CountTradesBuy()) + br ;
   mainComment = mainComment + "Open Sell = " + string(CountTradesSell()) + br ;
   mainComment = mainComment + separation;
   mainComment = mainComment + "Target Money Buy = " + DoubleToString(总_do_56,2) + br ;
   mainComment = mainComment + "Stoploss Money Buy = " + DoubleToString(-(总_do_58),2) + br ;
   mainComment = mainComment + separation;
   mainComment = mainComment + "Target Money Sell = " + DoubleToString(总_do_57,2) + br ;
   mainComment = mainComment + "Stoploss Money Sell = " + DoubleToString( -(总_do_59),2) + br ;
   mainComment = mainComment + separation;
   mainComment = mainComment + "Buy Profit(USD) = " + DoubleToString(totalProfitBuy,2) + br ;
   mainComment = mainComment + "Sell Profit(USD) = " + DoubleToString(totalProfitSell,2) + br ;
   mainComment = mainComment + separation;
   Comment(mainComment); 
}
//ChartComment <<==
//---------- ----------  ---------- ----------

void DeleteAllObjects()
//delete all objects on the current chart
{
   int       objectAmount;
   string    objectName;
   int       pos;
   //----- -----
   pos = 0 ;
   objectAmount = ObjectsTotal(-1) ;
   for (pos = objectAmount - 1 ; pos >= 0 ; pos = pos - 1)
   {
      if ( HighToLow )
      {
         objectName = ObjectName(pos) ;
         if ( StringFind(objectName,"v_u_hl",0) > -1 )
         {
            ObjectDelete(objectName); 
         }
         if ( StringFind(objectName,"v_l_hl",0) > -1 )
         {
            ObjectDelete(objectName); 
         }
         if ( StringFind(objectName,"Fibo_hl",0) > -1 )
         {
            ObjectDelete(objectName); 
         }
         if ( StringFind(objectName,"trend_hl",0) > -1 )
         {
            ObjectDelete(objectName); 
         }
         WindowRedraw(); 
         continue;
      }
      objectName = ObjectName(pos) ;
      if ( StringFind(objectName,"v_u_lh",0) > -1 )
      {
         ObjectDelete(objectName); 
      }
      if ( StringFind(objectName,"v_l_lh",0) > -1 )
      {
         ObjectDelete(objectName); 
      }
      if ( StringFind(objectName,"Fibo_lh",0) > -1 )
      {
         ObjectDelete(objectName); 
      }
      if ( StringFind(objectName,"trend_lh",0) > -1 )
      {
         ObjectDelete(objectName); 
      }
      WindowRedraw(); 
   }
}
//DeleteAllObjects <<==
//---------- ----------  ---------- ----------

void CalcFibo()
{
   int       子_in_1;
   int       子_in_2;
   double    子_do_3;
   double    子_do_4;
   int       子_in_5;
   int       子_in_6;
   double    子_do_7;
   double    子_do_8;
   int       子_in_9;
   //----- -----
   子_in_5 = iLowest(NULL,0,MODE_LOW,BarsBack,StartBar) ;
   子_in_6 = iHighest(NULL,0,MODE_HIGH,BarsBack,StartBar) ;
   子_do_7 = 0.0 ;
   子_do_8 = 0.0 ;
   子_do_4 = High[子_in_6] ;
   子_do_3 = Low[子_in_5] ;
   if ( HighToLow )
   {
      DrawVerticalLine ( "v_u_hl",子_in_6,总_ui_9); 
      DrawVerticalLine ( "v_l_hl",子_in_5,总_ui_9); 
      if ( ObjectFind("trend_hl") == -1 )
      {
         ObjectCreate("trend_hl",OBJ_TREND,0,Time[子_in_6],子_do_4,Time[子_in_5],子_do_3,0,0.0); 
      }
      ObjectSet("trend_hl",OBJPROP_TIME1,Time[子_in_6]); 
      ObjectSet("trend_hl",OBJPROP_TIME2,Time[子_in_5]); 
      ObjectSet("trend_hl",OBJPROP_PRICE1,子_do_4); 
      ObjectSet("trend_hl",OBJPROP_PRICE2,子_do_3); 
      ObjectSet("trend_hl",OBJPROP_STYLE,2.0); 
      ObjectSet("trend_hl",OBJPROP_RAY,0.0); 
      if ( ObjectFind("Fibo_hl") == -1 )
      {
         ObjectCreate("Fibo_hl",OBJ_FIBO,0,0,子_do_4,0,子_do_3,0,0.0); 
      }
      ObjectSet("Fibo_hl",OBJPROP_PRICE1,子_do_4); 
      ObjectSet("Fibo_hl",OBJPROP_PRICE2,子_do_3); 
      ObjectSet("Fibo_hl",OBJPROP_LEVELCOLOR,总_ui_10); 
      ObjectSet("Fibo_hl",OBJPROP_FIBOLEVELS,8.0); 
      ObjectSet("Fibo_hl",210,fiboLevel_1); 
      ObjectSetFiboDescription("Fibo_hl",0,"SWING LOW (0.0) - %$"); 
      ObjectSet("Fibo_hl",211,fiboLevel_2); 
      ObjectSetFiboDescription("Fibo_hl",1,"BREAKOUT AREA (23.6) -  %$"); 
      ObjectSet("Fibo_hl",212,fiboLevel_3); 
      ObjectSetFiboDescription("Fibo_hl",2,"CRITICAL AREA (38.2) -  %$"); 
      ObjectSet("Fibo_hl",213,fiboLevel_4); 
      ObjectSetFiboDescription("Fibo_hl",3,"CRITICAL AREA (50.0) -  %$"); 
      ObjectSet("Fibo_hl",214,fiboLevel_5); 
      ObjectSetFiboDescription("Fibo_hl",4,"CRITICAL AREA (61.8) -  %$"); 
      ObjectSet("Fibo_hl",215,fiboLevel_6); 
      ObjectSetFiboDescription("Fibo_hl",5,"BREAKOUT AREA (76.4) -  %$"); 
      ObjectSet("Fibo_hl",217,fiboLevel_7); 
      ObjectSetFiboDescription("Fibo_hl",7,"SWING HIGH (100.0) - %$"); 
      ObjectSet("Fibo_hl",OBJPROP_RAY,1.0); 
      WindowRedraw(); 
      for (子_in_9 = 0 ; 子_in_9 < 100 ; 子_in_9 = 子_in_9 + 1)
      {
         总_do17ko[子_in_9] = NormalizeDouble((子_do_4 - 子_do_3) * fiboLevel_7 + 子_do_3,Digits());
         总_do16ko[子_in_9] = NormalizeDouble((子_do_4 - 子_do_3) * fiboLevel_6 + 子_do_3,Digits());
         总_do15ko[子_in_9] = NormalizeDouble((子_do_4 - 子_do_3) * fiboLevel_5 + 子_do_3,Digits());
         总_do14ko[子_in_9] = NormalizeDouble((子_do_4 - 子_do_3) * fiboLevel_4 + 子_do_3,Digits());
         总_do13ko[子_in_9] = NormalizeDouble((子_do_4 - 子_do_3) * fiboLevel_3 + 子_do_3,Digits());
         总_do12ko[子_in_9] = NormalizeDouble((子_do_4 - 子_do_3) * fiboLevel_2 + 子_do_3,Digits());
         总_do11ko[子_in_9] = NormalizeDouble((子_do_4 - 子_do_3) * fiboLevel_1 + 子_do_3,Digits());
      }
      return;
   }
   DrawVerticalLine ( "v_u_lh",子_in_6,总_ui_9); 
   DrawVerticalLine ( "v_l_lh",子_in_5,总_ui_9); 
   if ( ObjectFind("trend_hl") == -1 )
   {
      ObjectCreate("trend_lh",OBJ_TREND,0,Time[子_in_5],子_do_3,Time[子_in_6],子_do_4,0,0.0); 
   }
   ObjectSet("trend_lh",OBJPROP_TIME1,Time[子_in_5]); 
   ObjectSet("trend_lh",OBJPROP_TIME2,Time[子_in_6]); 
   ObjectSet("trend_lh",OBJPROP_PRICE1,子_do_3); 
   ObjectSet("trend_lh",OBJPROP_PRICE2,子_do_4); 
   ObjectSet("trend_lh",OBJPROP_STYLE,2.0); 
   ObjectSet("trend_lh",OBJPROP_RAY,0.0); 
   if ( ObjectFind("Fibo_lh") == -1 )
   {
      ObjectCreate("Fibo_lh",OBJ_FIBO,0,0,子_do_3,0,子_do_4,0,0.0); 
   }
   ObjectSet("Fibo_lh",OBJPROP_PRICE1,子_do_3); 
   ObjectSet("Fibo_lh",OBJPROP_PRICE2,子_do_4); 
   ObjectSet("Fibo_lh",OBJPROP_LEVELCOLOR,总_ui_10); 
   ObjectSet("Fibo_lh",OBJPROP_FIBOLEVELS,8.0); 
   ObjectSet("Fibo_lh",210,fiboLevel_1); 
   ObjectSetFiboDescription("Fibo_lh",0,"SWING LOW (0.0) - %$"); 
   ObjectSet("Fibo_lh",211,fiboLevel_2); 
   ObjectSetFiboDescription("Fibo_lh",1,"BREAKOUT AREA (23.6) -  %$"); 
   ObjectSet("Fibo_lh",212,fiboLevel_3); 
   ObjectSetFiboDescription("Fibo_lh",2,"CRITICAL AREA (38.2) -  %$"); 
   ObjectSet("Fibo_lh",213,fiboLevel_4); 
   ObjectSetFiboDescription("Fibo_lh",3,"CRITICAL AREA (50.0) -  %$"); 
   ObjectSet("Fibo_lh",214,fiboLevel_5); 
   ObjectSetFiboDescription("Fibo_lh",4,"CRITICAL AREA (61.8) -  %$"); 
   ObjectSet("Fibo_lh",215,fiboLevel_6); 
   ObjectSetFiboDescription("Fibo_lh",5,"BREAKOUT AREA (76.4) -  %$"); 
   ObjectSet("Fibo_lh",217,fiboLevel_7); 
   ObjectSetFiboDescription("Fibo_lh",7,"SWING HIGH (100.0) - %$"); 
   ObjectSet("Fibo_lh",OBJPROP_RAY,1.0); 
   WindowRedraw(); 
   for (子_in_9 = 0 ; 子_in_9 < 100 ; 子_in_9 = 子_in_9 + 1)
   {
      总_do11ko[子_in_9] = NormalizeDouble(子_do_4,4);
      总_do12ko[子_in_9] = NormalizeDouble(子_do_4 - (子_do_4 - 子_do_3) * fiboLevel_2,Digits());
      总_do13ko[子_in_9] = NormalizeDouble(子_do_4 - (子_do_4 - 子_do_3) * fiboLevel_3,Digits());
      总_do14ko[子_in_9] = NormalizeDouble(子_do_4 - (子_do_4 - 子_do_3) * fiboLevel_4,Digits());
      总_do15ko[子_in_9] = NormalizeDouble(子_do_4 - (子_do_4 - 子_do_3) * fiboLevel_5,Digits());
      总_do16ko[子_in_9] = NormalizeDouble(子_do_4 - (子_do_4 - 子_do_3) * fiboLevel_6,Digits());
      总_do17ko[子_in_9] = NormalizeDouble(子_do_3,4);
   }
}
//CalcFibo <<==
//---------- ----------  ---------- ----------

void DrawVerticalLine(string 木_0,int 木_1,color 木_2)
{
   if ( ObjectFind(木_0) == -1 )
      {
         ObjectCreate(木_0,OBJ_VLINE,0,Time[木_1],0.0,0,0.0,0,0.0); 
         ObjectSet(木_0,OBJPROP_COLOR,木_2); 
         ObjectSet(木_0,OBJPROP_STYLE,1.0); 
         ObjectSet(木_0,OBJPROP_WIDTH,1.0); 
         WindowRedraw(); 
         return;
      }
   ObjectDelete(木_0); 
   ObjectCreate(木_0,OBJ_VLINE,0,Time[木_1],0.0,0,0.0,0,0.0); 
   ObjectSet(木_0,OBJPROP_COLOR,木_2); 
   ObjectSet(木_0,OBJPROP_STYLE,1.0); 
   ObjectSet(木_0,OBJPROP_WIDTH,1.0); 
   WindowRedraw(); 
}
//DrawVerticalLine <<==
//---------- ----------  ---------- ----------

double FindLastBuyPrice_Hilo()
//find the open price of the lastest buy order 
{
   double    openPrice;
   int       orderTicketNumber;
   double    lastOpenPrice;
   int       lastOrder;
   //----- -----
   orderTicketNumber = 0 ;
   lastOpenPrice = 0.0 ;
   lastOrder = 0 ;
   for (pos_global=OrdersTotal() - 1 ; pos_global >= 0 ; pos_global=pos_global - 1)
   {
      if ( !(OrderSelect(pos_global,SELECT_BY_POS,MODE_TRADES)) || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderType() != 0 )   continue;
      orderTicketNumber = OrderTicket() ;
      if ( orderTicketNumber <= lastOrder )   continue;
      openPrice = OrderOpenPrice() ;
      lastOpenPrice = openPrice ;
      lastOrder = orderTicketNumber ;
   }
   return(lastOpenPrice); 
}
//FindLastBuyPrice_Hilo <<==
//---------- ----------  ---------- ----------

double FindLastSellPrice_Hilo()
//find the open price of the lastest sell order 
{
   double    openPrice;
   int       orderTicketNumber;
   double    lastOpenPrice;
   int       lastOrder;
   //----- -----
   orderTicketNumber = 0 ;
   lastOpenPrice = 0.0 ;
   lastOrder = 0 ;
   for (pos_global=OrdersTotal() - 1 ; pos_global >= 0 ; pos_global=pos_global - 1)
   {
      if ( !(OrderSelect(pos_global,SELECT_BY_POS,MODE_TRADES)) || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderType() != 1 )   continue;
      orderTicketNumber = OrderTicket() ;
      if ( orderTicketNumber <= lastOrder )   continue;
      openPrice = OrderOpenPrice() ;
      lastOpenPrice = openPrice ;
      lastOrder = orderTicketNumber ;
   }
   return(lastOpenPrice); 
}
//FindLastSellPrice_Hilo <<==
//---------- ----------  ---------- ----------

int CountTradesSell()
//count the opening sell order
{
   int sellTotal;
   int pos;
   //----- -----
   pos = 0 ;
   sellTotal = 0 ;
   for (pos = OrdersTotal() - 1 ; pos >= 0 ; pos = pos - 1)
   {
      if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderType() != 1 )   continue;
      sellTotal = sellTotal + 1;
   }
   return(sellTotal); 
}
//CountTradesSell <<==
//---------- ----------  ---------- ----------

int CountTradesBuy()
//count the opening buy order
{
   int buyTotal;
   int pos;
   //----- -----
   pos = 0 ;
   buyTotal = 0 ;
   for (pos = OrdersTotal() - 1 ; pos >= 0 ; pos = pos - 1)
   {
      if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber || OrderType() != 0 )   continue;
      buyTotal = buyTotal + 1;
   }
   return(buyTotal); 
}
//CountTradesBuy <<==
//---------- ----------  ---------- ----------
double startBalanceD1()
//calculate the start balance today
{
   double    profitTotal;
   int       historyAmount;
   datetime  todayDate;
   int       pos;
   double    startBalance;
   //----- -----
   historyAmount = OrdersHistoryTotal() ;
   todayDate = iTime(NULL,1440,0) ;
   for (pos = historyAmount ; pos >= 0 ; pos = pos - 1)
   {
      if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_HISTORY)) || OrderCloseTime() < todayDate )   continue;
      profitTotal = OrderProfit() + OrderCommission() + OrderSwap() + profitTotal ;
   }
   startBalance = NormalizeDouble(AccountBalance() - profitTotal,2) ;
   return(startBalance); 
}
//startBalanceD1 <<==
//---------- ----------  ---------- ----------
