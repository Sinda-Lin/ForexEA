#property  copyright "FortuneCode2.0.1 only for Testing"
//FortuneCode2.0.1 is doing on XAUUSD M5

enum ENUM_Trading_Mode  {PendingLimitOrderFollowTrend = 0, PendingLimitOrderReversalTrend = 1, PendingStopOrderFollowTrend = 2, PendingStopOrderReversalTrend = 3};
enum ENUM_Candlestick_Mode {ToAvoidNews = 0, ToTriggerOrder = 1};

//------------------
extern  ENUM_Trading_Mode  TradingMode=3  ;   
extern  ENUM_Candlestick_Mode  CandlestickMode=0  ;   
extern int   CandlestickHighLow=800  ;   //how many points to controll if avoid news

//--------------------------------------------------core factors-----------------------------------------------
extern bool UseMM=false ;   //if useMM is false, fixedLots will be used
extern double Risk=0.1  ;   // riskrate = risk/100
extern double FixedLots=0.01  ;   
//lot management
extern double LotsExponent=1.20  ;   //
extern int   Pipstep=200  ;             //how many pips between two order
extern double PipstepExponent=1  ;     // when it is 1, pips between two order never change by the order amount
//fund management
extern bool AutoTargetMoney=false  ;   //targetMoneySell = lots * TargetMoneyFactor * CountTradesSell() * LotsExponent
extern double TargetMoneyFactor=100  ;   
extern double TargetMoney=1000  ;        // if AutoTargetMoney = False, set up an fix amount
extern bool AutoStopLossMoney=false ;   //slMoneySell = lots * StoplossFactor * CountTradesSell ( ) * LotsExponent ;
extern double StoplossFactor=100  ;   
extern double StoplossMoney=1000  ;        //slMoneyBuy = StoplossMoney ;
//order open strategy
extern double HighFibo=76.4  ;    // order trigger level - high
extern double LowFibo=23.6  ;    // order trigger level - low
extern int   PendingDistance=50  ;  
//--------------------------------------------------core factors-----------------------------------------------

extern bool UseTakeProfit=true ;   // when it is false, do not set take profit for single order
extern bool AutoTakeProfit=true ; 
extern int   TakeProfit=500  ;   //it works when UserTakeProfit=Ture
extern bool UseStopLoss=false ; 
extern bool AutoStopLoss=false ;  
extern int   StopLoss=500  ;   

extern bool UseTrailing=false ;   
extern int   TrailingStop=20  ;   // if the price run back TrailingStop point, then stoploss
extern int   TrailingStart=0  ;   // Add a gap to controll more space to start trailing stoploss

extern int   MaxOrderBuy=26 ;   
extern int   MaxOrderSell=26  ;   
 

extern double MaxSpreadPlusCommission=50  ;   //the cost limit in point
extern bool HighToLow=true  ;   //Chart object is high to low

extern int   StartBar=1  ;     //which bars start to calculate fibo level
extern int   BarsBack=50  ;    //how many bars to calculate fibo level
extern bool ShowFibo=true  ; 

extern int   Slippage=10  ; 
  
extern int   MagicNumber=666888;  // identify number for this EA, if MagicNumber=0, only one EA at one time
extern string TradeComment="FortuneCode2.0.1"  ;  
extern bool TradeMonday=true  ;   
extern bool TradeTuesday=true  ;   
extern bool TradeWednesday=true  ;   
extern bool TradeThursday=true  ;   
extern bool TradeFriday=true  ;   
extern int   StartHour=1  ;   
extern int   StartMinute=10  ;   
extern int   EndHour=23  ;   
extern int   EndMinute=59  ;   

double    maxVolume = 10000.0;  // set an internal maximum volume
// set fibo line
double    fiboLevel_1 = 0.0;
double    fiboLevel_2 = 0.236;
double    fiboLevel_3 = 0.382;
double    fiboLevel_4 = 0.5;
double    fiboLevel_5 = 0.618;
double    fiboLevel_6 = 0.764;
double    fiboLevel_7 = 1.0;

uint      vlColor = Blue; // vertical line color
uint      fiboColor = DarkGray; //fibo line color
// 
double    fiboLevel_1_price[];
double    fiboLevel_2_price[];
double    fiboLevel_3_price[];
double    fiboLevel_4_price[];
double    fiboLevel_5_price[];
double    fiboLevel_6_price[];
double    fiboLevel_7_price[];

bool      buyOrderClose = false;
bool      sellOrderClose = false;
int       specifyOrder = 0;  // if specifyOrder = 0, we count every open order; if specifyOrder > 0, we only search order MagicNumber = specifyOrder ; if specifyOrder<0, do not count.
int       pos_global = 0;
int       sellSwitchByMax = 0;
int       buySwitchByMax = 0;
double    priceArray[30];
int       digits = 0;
double    pointSize = 0.0;
int       lotDigits = 0;
double    minFixedLots = 0.0;
double    maxLots = 0.0;
double    riskRate = 0.0;
double    cost = 0.0;
double    normPendingDistance = 0.0;
double    newsPriceRange = 0.0;
bool      commissionCaled = false;
double    commissionPerCont = 0.0;
int       spreadPos = 0;
double    initComission = 0.0; // initail commission per contract 
bool      calNextPeriod = true;
double    nextPeriod = 240.0; // 240 means chart time frame is H1
double    pipSize = 0.0; //never use
double    priceRange = 0.0;
double    targetMoneyBuy = 0.0; // target money buy
double    targetMoneySell = 0.0; // target money sell
double    slMoneyBuy = 0.0; // stoploss money buy
double    slMoneySell = 0.0; // stoploss money sell
double    totalProfitBuy = 0.0;  //check main process with this factor
double    totalProfitSell = 0.0;

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
   cost = NormalizeDouble(MaxSpreadPlusCommission *  pointSize, digits + 1) ; //normalize the max cost per contract
   normPendingDistance = NormalizeDouble(PendingDistance * pointSize, digits) ; 
   newsPriceRange = NormalizeDouble(pointSize * CandlestickHighLow, digits) ;
   commissionCaled = false ;
   commissionPerCont = NormalizeDouble(initComission *  pointSize,digits + 1) ;
   if ( !(IsTesting()) )
   {
      if ( calNextPeriod )
      {
         periodInSec = Period();
         switch(periodInSec)
         {
            case 1 :
            nextPeriod = 5.0 ;
               break;
            case 5 :
            nextPeriod = 15.0 ;
               break;
            case 15 :
            nextPeriod = 30.0 ;
               break;
            case 30 :
            nextPeriod = 60.0 ;
               break;
            case 60 :
            nextPeriod = 240.0 ;
               break;
            case 240 :
            nextPeriod = 1440.0 ;
               break;
            case 1440 :
            nextPeriod = 10080.0 ;
               break;
            case 10080 :
            nextPeriod = 43200.0 ;
               break;
            case 43200 :
            nextPeriod = 43200.0 ;
         }
      }
      pipSize = 0.0001 ;
   }
   DeleteAllObjects(); 
   SetIndexBuffer(0,fiboLevel_1_price); 
   SetIndexBuffer(1,fiboLevel_2_price); 
   SetIndexBuffer(2,fiboLevel_3_price); 
   SetIndexBuffer(3,fiboLevel_4_price); 
   SetIndexBuffer(4,fiboLevel_5_price); 
   SetIndexBuffer(5,fiboLevel_6_price); 
   SetIndexBuffer(6,fiboLevel_7_price); 
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
   bool      isDemo;
   string    expiredDateString;
   datetime  expiredDate;
   double    pipStepCurrSell;
   double    pipStepCurrBuy;
   double    lastestSellPrice;
   double    lastestbuyPrice;
   int       errorCode;
   string    errorMessage;
   int       orderSendResult;
   double    orderSendingPrice;
   double    contractAmount;
   int       breakFibo;
   int       subOrderType;
   bool      orderModifyResult;
   double    pendingOpenPrice;
   double    lots;
   double    orderSendingLotsBuy;
   double    orderSendingLotsSell;
   double    volumeStep0;
   double    volumeStep1;
   double    volumeStep2;
   double    volumeStep3;
   double    volumeStep4;
   double    volumeStep5;
   double    volumeStep6;
   double    volumeStep7;
   double    lowLowest;
   double    highHighest;
   int       lowestData;
   int       highestData;
   double    lowFiboPrice;
   double    priceFiboLevel2;
   double    priceFiboLevel3;
   double    priceFiboLevel4;
   double    priceFiboLevel5;
   double    priceFiboLevel6;
   double    highFiboPrice;
   int       pos;
   double    spread;
   double    spreadTotal;
   int       subCounter;
   double    spreadAvg;
   double    askAfterComm;
   double    bidAfterComm;
   double    costPerCont;
   double    priceRangeCur;
   double    priceRangeLast;
   int       pendingOrderAmount;
   string    tradeComm;
   //----- -----

   //Demo Account Control
   isDemo = IsDemo() ;
   if ( !(isDemo) )
   {
      //Alert("You can not use the program with a real account!"); 
      //return(0); 
   }

   //Program expired date control
   expiredDateString = "2023.12.31" ;
   expiredDate = StringToTime(expiredDateString) ;
   if ( TimeCurrent() >= expiredDate )
   {
      //Alert("The trial version has been expired!"); 
      //return(0); 
   }

   if ( ShowFibo == 1 )
   {
      CalcFibo(); 
   }

   pipStepCurrSell = NormalizeDouble(Pipstep * MathPow(PipstepExponent,CountTradesSell()),0); //pip between two order changing with exponent and orderamount, it never changes if PipsterExpoent=1 
   pipStepCurrBuy = NormalizeDouble(Pipstep * MathPow(PipstepExponent,CountTradesBuy()),0); //

   lastestSellPrice = FindLastSellPrice_Hilo() ;
   lastestbuyPrice = FindLastBuyPrice_Hilo() ;
   errorCode = 0 ;
   orderSendResult = 0 ;
   orderSendingPrice = 0.0 ;
   contractAmount = 0.0 ;
   breakFibo = 0 ; // default is 0 when price did not break fibo price, -1 is break the highest level, 1 is break the lowest level.
   subOrderType = 0 ;
   orderModifyResult = false ;
   pendingOpenPrice = 0.0 ;
   lots = 0.0 ;
   orderSendingLotsBuy = 0.0 ;
   orderSendingLotsSell = 0.0 ;
   volumeStep0 = 0.0 ;
   volumeStep1 = 0.0 ;
   volumeStep2 = 0.0 ;  //take profit of pending order
   volumeStep3 = 0.0 ; //stoploss of pending order
   volumeStep4 = iHigh(NULL,0,0) ; //the highest price of the current bar of the current timeframe 
   volumeStep5 = iLow(NULL,0,0) ; //the lowest price of the current bar of the current timeframe 
   volumeStep6 = iHigh(NULL,0,1) ; //the highest price of the -1 bar of the current timeframe 
   volumeStep7 = iLow(NULL,0,1) ; //the lowest price of the -1 bar of the current timeframe 

   //calculate prices of all fibo level
   lowLowest = 0.0 ;
   highHighest = 0.0 ;
   lowestData = iLowest(NULL,0,MODE_LOW,BarsBack,StartBar) ;
   highestData = iHighest(NULL,0,MODE_HIGH,BarsBack,StartBar) ;
   highHighest = High[highestData]; //high price of highest data
   lowLowest = Low[lowestData] ;  //low price of lowest data
   priceRange = highHighest - lowLowest ;

   priceFiboLevel2 = priceRange * fiboLevel_2 + lowLowest ;
   priceFiboLevel3 = priceRange * fiboLevel_3 + lowLowest ; //0.382
   priceFiboLevel4 = priceRange * fiboLevel_4 + lowLowest ;
   priceFiboLevel5 = priceRange * fiboLevel_5 + lowLowest ; //0.618
   priceFiboLevel6 = priceRange * fiboLevel_6 + lowLowest ;

   lowFiboPrice = LowFibo / 100.0 * priceRange + lowLowest;
   highFiboPrice = HighFibo / 100.0 * priceRange + lowLowest ;

   //-------------------------------------------------------
   //it is calculating commission for single contract
   if ( !(commissionCaled) )
   {
      for (pos = OrdersHistoryTotal() - 1 ; pos >= 0 ; pos = pos - 1)
      {
         if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_HISTORY)) || !(OrderProfit()!=0.0) || !(OrderClosePrice()!=OrderOpenPrice()) || OrderSymbol() != Symbol() )   continue;
         commissionCaled = true ;
         contractAmount = MathAbs(OrderProfit() / (OrderClosePrice() - OrderOpenPrice()));
         commissionPerCont = ( -(OrderCommission())) / contractAmount ;
         break;
      }
   }
   //-----------------------------------------------------------
   //trading lots calculated by risk rate or set by fiexed lots.
   lots = NormalizeDouble(AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15),lotDigits) ; //15 is lot size in the base currency
   if ( !(UseMM) )
   {
      lots = FixedLots ;
   }
   //target money & stop loss money
   targetMoneySell = lots * TargetMoneyFactor * CountTradesSell() * LotsExponent ;
   if ( !(AutoTargetMoney) )
   {
      targetMoneySell = TargetMoney ;
   }
   targetMoneyBuy = lots * TargetMoneyFactor * CountTradesBuy ( ) * LotsExponent ;
   if ( !(AutoTargetMoney) )
   {
      targetMoneyBuy = TargetMoney ;
   }
   slMoneySell = lots * StoplossFactor * CountTradesSell ( ) * LotsExponent ;
   if ( !(AutoStopLossMoney) )
   {
      slMoneySell = StoplossMoney ;
   }
   slMoneyBuy = lots * StoplossFactor * CountTradesBuy ( ) * LotsExponent ;
   if ( !(AutoStopLossMoney) )
   {
      slMoneyBuy = StoplossMoney ;
   }

   // Calculate the average spread of last 30 bar to calculate the cost per contract
   spread = Ask - Bid ; // make lack of ask and bid setting up above
   ArrayCopy(priceArray,priceArray,0,1,29); 
   priceArray[29] = spread;
   if ( spreadPos <  30 )
   {
      spreadPos=spreadPos + 1;
   }
   spreadTotal = 0.0 ;
   pos = 29 ;
   for (subCounter = 0 ; subCounter < spreadPos ; subCounter = subCounter + 1)
   {
      spreadTotal = spreadTotal + priceArray[pos] ;
      pos = pos - 1;
   }
   spreadAvg = spreadTotal / spreadPos ;
   askAfterComm = NormalizeDouble(Ask + commissionPerCont,digits) ;
   bidAfterComm = NormalizeDouble(Bid - commissionPerCont,digits) ;
   costPerCont = NormalizeDouble(spreadAvg + commissionPerCont,digits + 1) ;

   priceRangeCur = volumeStep4 - volumeStep5 ;
   priceRangeLast = volumeStep6 - volumeStep7 ;
   //max order amount of buy and sell order setting
   if ( Bid - lastestSellPrice >= pipStepCurrSell * Point() ) // if bid - the bid price of the last open sell order >= pip step in current , switch on the ordersending by set up the max order amount
   {
      sellSwitchByMax = MaxOrderSell ;  //contoll the max order amount of sell order and to be a switch of send order
   }
   else
   {
      sellSwitchByMax = 1 ;
   }
   if ( lastestbuyPrice - Ask >= pipStepCurrBuy * Point() )
   {
      buySwitchByMax = MaxOrderBuy ;
   }
   else
   {
      buySwitchByMax = 1 ;
   }
   // To see if the bid price go break the fibo high trigger level or low trigger level
   if ( CandlestickMode != 0 ) //if candlestickMode == 1, do not avoid news
   {
      if ( CandlestickMode == 1 && priceRangeCur>newsPriceRange )
      {
         if ( Bid>highFiboPrice )
         {
            breakFibo = -1 ;  
         }
         else
         {
            if ( Bid<lowFiboPrice )
            {
               breakFibo = 1 ;
            }
         }
      }
   }
   else //if candlestickMode == 0, avoid news
   {
      if ( priceRangeCur<=newsPriceRange && priceRangeLast<=newsPriceRange )
      {
         if ( Bid>highFiboPrice )
         {
            breakFibo = -1 ;
         }
         else
         {
            if ( Bid<lowFiboPrice )
            {
               breakFibo = 1 ;
            }
         }
      }
   }
   //--------------------------------------------------------------------------------------
   pendingOrderAmount = 0 ;
   for(pos = 0 ; pos < OrdersTotal() ; pos = pos + 1)
   //modify pending order
   {
      if ( !(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) || OrderMagicNumber() != MagicNumber )   continue;
      subOrderType = OrderType() ;
      if ( subOrderType == 0 || subOrderType == 1 || OrderSymbol() != Symbol() )   continue; 
      pendingOrderAmount = pendingOrderAmount + 1;
      switch(subOrderType)
      {
         case 4 : //Buy Stop
            pendingOpenPrice = NormalizeDouble(OrderOpenPrice(),digits) ;
            orderSendingPrice = NormalizeDouble(Ask + normPendingDistance,digits) ;
            if ( !(orderSendingPrice<pendingOpenPrice) )   break;
            if (AutoStopLoss){
               volumeStep0 = 0.0; //just wait to fill
            }
            else{
               volumeStep0 = NormalizeDouble(orderSendingPrice - StopLoss * Point(),digits) ;
            }
            if (AutoTakeProfit)
            {
               volumeStep1 = NormalizeDouble(priceFiboLevel3,digits) ;
               MoveTakeProfitBuy(volumeStep1);
            }
            else
            {
               volumeStep1 = NormalizeDouble(TakeProfit * Point() + orderSendingPrice,digits) ;
            }
            volumeStep3 = volumeStep0 ; //stop loss price 
            if ( !(UseStopLoss) )
            {
               volumeStep3 = 0.0 ;
            }
            volumeStep2 = volumeStep1 ; //take profit price
            if ( !(UseTakeProfit) )
            {
               volumeStep2 = 0.0 ;
            }
            if ( OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() )
            {
               orderModifyResult = OrderModify(OrderTicket(),orderSendingPrice,volumeStep3,volumeStep2,0,Blue) ;
            }
            if ( orderModifyResult )   break;
            errorCode = GetLastError() ;
            errorMessage = ErrorDescription(errorCode) ;
            Print("BUYSTOP Modify Error Code: " + string(errorCode) + " Message: " + errorMessage + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
            break;
         case 5 : // Sell Stop
            pendingOpenPrice = NormalizeDouble(OrderOpenPrice(),digits) ;
            orderSendingPrice = NormalizeDouble(Bid - normPendingDistance,digits) ;
            if ( !(orderSendingPrice>pendingOpenPrice) )   break;
            if (AutoStopLoss){
               volumeStep0 = 0.0; //just wait to fill
            }
            else{
               volumeStep0 = NormalizeDouble(StopLoss * Point() + orderSendingPrice,digits) ;
            }
            if (AutoTakeProfit)
            {
               volumeStep1 = NormalizeDouble(priceFiboLevel5,digits) ;
               MoveTakeProfitSell(volumeStep1);
            }
            else
            {
               volumeStep1 = NormalizeDouble(orderSendingPrice - TakeProfit * Point(),digits) ;
            }
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
               orderModifyResult = OrderModify(OrderTicket(),orderSendingPrice,volumeStep3,volumeStep2,0,Red) ;
            }
            if ( orderModifyResult )   break;
            errorCode = GetLastError() ;
            errorMessage = ErrorDescription(errorCode) ;
            Print("SELLSTOP Modify Error Code: " + string(errorCode) + " Message: " + errorMessage + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
            break;
         case 3 : // Sell Limit
            pendingOpenPrice = NormalizeDouble(OrderOpenPrice(),digits) ;
            orderSendingPrice = NormalizeDouble(Bid + normPendingDistance,digits) ;
            if ( !(orderSendingPrice<pendingOpenPrice) )   break;
            if (AutoStopLoss){
               volumeStep0 = 0.0; //just wait to fill
            }
            else{
               volumeStep0 = NormalizeDouble(StopLoss * Point() + orderSendingPrice,digits) ;
            }
            if (AutoTakeProfit)
            {
               volumeStep1 = NormalizeDouble(priceFiboLevel5,digits) ;
               MoveTakeProfitSell(volumeStep1);
            }
            else
            {
               volumeStep1 = NormalizeDouble(orderSendingPrice - TakeProfit * Point(),digits) ;
            }
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
               orderModifyResult = OrderModify(OrderTicket(),orderSendingPrice,volumeStep3,volumeStep2,0,Red) ;
            }
            if ( orderModifyResult )   break;
            errorCode = GetLastError() ;
            errorMessage = ErrorDescription(errorCode) ;
            Print("BUYLIMIT Modify Error Code: " + string(errorCode) + " Message: " + errorMessage + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
               break;
         case 2 : //Buy Limit
            pendingOpenPrice = NormalizeDouble(OrderOpenPrice(),digits) ;
            orderSendingPrice = NormalizeDouble(Ask - normPendingDistance,digits) ;
            if ( !(orderSendingPrice>pendingOpenPrice) )   break;
            if (AutoStopLoss){
               volumeStep0 = 0.0; //just wait to fill
            }
            else{
               volumeStep0 = NormalizeDouble(orderSendingPrice - StopLoss * Point(),digits) ;
            }
            if (AutoTakeProfit)
            {
               volumeStep1 = NormalizeDouble(priceFiboLevel3,digits) ;
               MoveTakeProfitBuy(volumeStep1);
            }
            else
            {
               volumeStep1 = NormalizeDouble(TakeProfit * Point() + orderSendingPrice,digits) ;
            }      
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
               orderModifyResult = OrderModify(OrderTicket(),orderSendingPrice,volumeStep3,volumeStep2,0,Blue) ;
            }
            if ( orderModifyResult )   break;
            errorCode = GetLastError() ;
            errorMessage = ErrorDescription(errorCode) ;
            Print("SELLLIMIT Modify Error Code: " + string(errorCode) + " Message: " + errorMessage + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
      }
   }
   // to see if the profit meet take profit or stop loss to close them
   if( CountTradesBuy() == 0 )
   {
      buyOrderClose = false ;
   }
   if( CountTradesSell() == 0 )
   {
      sellOrderClose = false ;
   }
   TotalProfitbuy();  // calculate the totalProfitBuy in global
   TotalProfitsell(); // calculate the totalProfitSell in global
   ChartComment(); 
   if ( ( ( targetMoneyBuy>0.0 && totalProfitBuy>=targetMoneyBuy ) || ( -(slMoneyBuy)<0.0 && totalProfitBuy<= -(slMoneyBuy)) ) )
   {
      buyOrderClose = true ;
   }
   if ( buyOrderClose )
   {
      OpenOrdClose();  //close opening buy order and buy pending order
   }
   if ( ( ( targetMoneySell>0.0 && totalProfitSell>=targetMoneySell ) || ( -(slMoneySell)<0.0 && totalProfitSell<= -(slMoneySell)) ) )
   {
      sellOrderClose = true ;
   }
   if ( sellOrderClose )
   {
      OpenOrdClose2();  //close opening sell order and sell pending order
   }
   // --------------------------------------------------------------------------------------
   //trading day controll : Monday to Friday
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
   // ------------------------------------------------------------------------------------------
   switch(TradingMode)
   {
      case 0 ://PendingLimitOrderFollowTrend  
         if ( Bid<lowFiboPrice && CountTradesSell ( ) >= sellSwitchByMax )
         {
            return(0); 
         }
         if ( !(Bid>highFiboPrice) || CountTradesBuy ( ) < buySwitchByMax )   break; //if bid <= highFiboPrice or Buy order amount < max, then go.
         return(0); 
      case 2 : //PendingStopOrderFollowTrend
         if ( Bid<lowFiboPrice && CountTradesSell ( ) >= sellSwitchByMax ) 
         {
            return(0); 
         }
         if ( !(Bid>highFiboPrice) || CountTradesBuy ( ) < buySwitchByMax )   break;
         return(0); 
      case 1 : //PendingLimitOrderReversalTrend
         if ( Bid>highFiboPrice && CountTradesSell ( ) >= sellSwitchByMax )
         {
            return(0); 
         }
         if ( !(Bid<lowFiboPrice) || CountTradesBuy ( ) < buySwitchByMax )   break;
         return(0); 
      case 3 : //PendingStopOrderReversalTrend
         if ( Bid>highFiboPrice && CountTradesSell ( ) >= sellSwitchByMax )
         {
            return(0); 
         }
         if ( !(Bid<lowFiboPrice) || CountTradesBuy ( ) < buySwitchByMax )   break; // if bid >= lowFiboPrice or Buy order amount < max, then go.
         return(0); 
   }

   switch(TradingMode)
   //to make the pending order
   {
      case 0 : //PendingLimitOrderFollowTrend  
         if ( pendingOrderAmount != 0 || breakFibo == 0 || !(costPerCont<=cost) || !(f0_4()) )   break; //if there is no pdddending order; price go over the fibo range; costPerCont < cost set; function in running time
         lots = AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15) ; //15 is the lotsize
         if ( !(UseMM) )
         {
            lots = FixedLots ;
         }
         orderSendingLotsBuy = NormalizeDouble(lots * MathPow(LotsExponent,CountTradesBuy()),digits) ;
         orderSendingLotsBuy = MathMax(minFixedLots,orderSendingLotsBuy) ;
         orderSendingLotsBuy = MathMin(maxLots,orderSendingLotsBuy) ;
         orderSendingLotsSell = NormalizeDouble(lots * MathPow(LotsExponent,CountTradesSell()),digits) ;
         orderSendingLotsSell = MathMax(minFixedLots,orderSendingLotsSell) ;
         orderSendingLotsSell = MathMin(maxLots,orderSendingLotsSell) ;
         if ( breakFibo <  0 ) //bid go break the high fibo level, make buy limit order to follow the trend
         {
            orderSendingPrice = NormalizeDouble(Ask - normPendingDistance,digits) ;
            if (AutoStopLoss){
               volumeStep0 = 0.0; //just wait to fill
            }
            else{
               volumeStep0 = NormalizeDouble(orderSendingPrice - StopLoss * Point(),digits) ;
            }
            if (AutoTakeProfit)
            {
               volumeStep1 = NormalizeDouble(priceFiboLevel3,digits) ;
            }
            else
            {
               volumeStep1 = NormalizeDouble(TakeProfit * Point() + orderSendingPrice,digits) ;
            }
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
            orderSendResult = OrderSend(Symbol(),OP_BUYLIMIT,orderSendingLotsBuy,orderSendingPrice,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Blue) ;
            if ( orderSendResult > 0 )   break;
            errorCode = GetLastError() ;
            errorMessage = ErrorDescription(errorCode) ;
            Print("BUYLIMIT Send Error Code: " + string(errorCode) + " Message: " + errorMessage + " LT: " + DoubleToString(orderSendingLotsBuy,digits) + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
            break;
         }
         // bid go break the low fibo level, make sell limit order to follow the trend
         orderSendingPrice = NormalizeDouble(Bid + normPendingDistance,digits) ;
         if (AutoStopLoss){
            volumeStep0 = 0.0; //just wait to fill
         }
         else{
            volumeStep0 = NormalizeDouble(StopLoss * Point() + orderSendingPrice,digits) ;
         }
         if (AutoTakeProfit)
         {
            volumeStep1 = NormalizeDouble(priceFiboLevel3,digits) ;
         }
         else
         {
            volumeStep1 = NormalizeDouble(orderSendingPrice - TakeProfit * Point(),digits) ;
         }
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
         orderSendResult = OrderSend(Symbol(),OP_SELLLIMIT,orderSendingLotsSell,orderSendingPrice,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Red) ;
         if ( orderSendResult > 0 )   break;
         errorCode = GetLastError() ;
         errorMessage = ErrorDescription(errorCode) ;
         Print("SELLLIMIT Send Error Code: " + string(errorCode) + " Message: " + errorMessage + " LT: " + DoubleToString(orderSendingLotsSell,digits) + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
      case 1 : //PendingLimitOrderReversalTrend
         if ( pendingOrderAmount != 0 || breakFibo == 0 || !(costPerCont<=cost) || !(f0_4()) )   break;
         lots = AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15) ;
         if ( !(UseMM) )
         {
            lots = FixedLots ;
         }
         orderSendingLotsBuy = NormalizeDouble(lots * MathPow(LotsExponent,CountTradesBuy()),digits) ;
         orderSendingLotsBuy = MathMax(minFixedLots,orderSendingLotsBuy) ;
         orderSendingLotsBuy = MathMin(maxLots,orderSendingLotsBuy) ;
         orderSendingLotsSell = NormalizeDouble(lots * MathPow(LotsExponent,CountTradesSell()),digits) ;
         orderSendingLotsSell = MathMax(minFixedLots,orderSendingLotsSell) ;
         orderSendingLotsSell = MathMin(maxLots,orderSendingLotsSell) ;
         if ( breakFibo <  0 ) //bid go break the high fibo level, make sell limit order to reverse the trend
         {
            orderSendingPrice = NormalizeDouble(Bid + normPendingDistance,digits) ;
            if (AutoStopLoss){
               volumeStep0 = 0.0; //just wait to fill
            }
            else{
               volumeStep0 = NormalizeDouble(StopLoss * Point() + orderSendingPrice,digits) ;
            }
            if (AutoTakeProfit)
            {
               volumeStep1 = NormalizeDouble(priceFiboLevel5,digits) ;
            }
            else
            {
               volumeStep1 = NormalizeDouble(orderSendingPrice - TakeProfit * Point(),digits) ;
            }
            
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
            orderSendResult = OrderSend(Symbol(),OP_SELLLIMIT,orderSendingLotsSell,orderSendingPrice,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Red) ;
            if ( orderSendResult > 0 )   break;
            errorCode = GetLastError() ;
            errorMessage = ErrorDescription(errorCode) ;
            Print("SELLLIMIT Send Error Code: " + string(errorCode) + " Message: " + errorMessage + " LT: " + DoubleToString(orderSendingLotsSell,digits) + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
            break;
         }
         //bid go break the low fibo level, make buy limit order to reverse the trend
         orderSendingPrice = NormalizeDouble(Ask - normPendingDistance,digits) ;
         if (AutoStopLoss){
            volumeStep0 = 0.0; //just wait to fill
         }
         else{
            volumeStep0 = NormalizeDouble(orderSendingPrice - StopLoss * Point(),digits) ;
         }
         if (AutoTakeProfit)
         {
            volumeStep1 = NormalizeDouble(priceFiboLevel3,digits) ;
         }
         else
         {
            volumeStep1 = NormalizeDouble(TakeProfit * Point() + orderSendingPrice,digits) ;
         }
         
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
         orderSendResult = OrderSend(Symbol(),OP_BUYLIMIT,orderSendingLotsBuy,orderSendingPrice,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Blue) ;
         if ( orderSendResult > 0 )   break;
         errorCode = GetLastError() ;
         errorMessage = ErrorDescription(errorCode) ;
         Print("BUYLIMIT Send Error Code: " + string(errorCode) + " Message: " + errorMessage + " LT: " + DoubleToString(orderSendingLotsBuy,digits) + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
      case 2 : //PendingStopOrderFollowTrend
         if ( pendingOrderAmount != 0 || breakFibo == 0 || !(costPerCont<=cost) || !(f0_4 ( )) )   break;
         lots = AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15) ;
         if ( !(UseMM) )
         {
            lots = FixedLots ;
         }
         orderSendingLotsBuy = NormalizeDouble(lots * MathPow(LotsExponent,CountTradesBuy ( )),digits) ;
         orderSendingLotsBuy = MathMax(minFixedLots,orderSendingLotsBuy) ;
         orderSendingLotsBuy = MathMin(maxLots,orderSendingLotsBuy) ;
         orderSendingLotsSell = NormalizeDouble(lots * MathPow(LotsExponent,CountTradesSell ( )),digits) ;
         orderSendingLotsSell = MathMax(minFixedLots,orderSendingLotsSell) ;
         orderSendingLotsSell = MathMin(maxLots,orderSendingLotsSell) ;
         if ( breakFibo <  0 ) //bid go break the high fibo level, make buy stop order to follow the trend
            {
            orderSendingPrice = NormalizeDouble(Ask + normPendingDistance,digits) ;
            if (AutoStopLoss){
               volumeStep0 = 0.0; //just wait to fill
            }
            else{
               volumeStep0 = NormalizeDouble(orderSendingPrice - StopLoss * Point(),digits) ;
            }
            if (AutoTakeProfit)
            {
               volumeStep1 = NormalizeDouble(priceFiboLevel3,digits) ;
            }
            else
            {
               volumeStep1 = NormalizeDouble(TakeProfit * Point() + orderSendingPrice,digits) ;
            }
            
            
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
            orderSendResult = OrderSend(Symbol(),OP_BUYSTOP,orderSendingLotsBuy,orderSendingPrice,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Blue) ;
            if ( orderSendResult > 0 )   break;
            errorCode = GetLastError() ;
            errorMessage = ErrorDescription(errorCode) ;
            Print("BUYSTOP Send Error Code: " + string(errorCode) + " Message: " + errorMessage + " LT: " + DoubleToString(orderSendingLotsBuy,digits) + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
            break;
         }
         //bid go break the low fibo level, make sell stop order to follow the trend
         orderSendingPrice = NormalizeDouble(Bid - normPendingDistance,digits) ;
         if (AutoStopLoss){
            volumeStep0 = 0.0; //just wait to fill
         }
         else{
            volumeStep0 = NormalizeDouble(StopLoss * Point() + orderSendingPrice,digits) ;
         }
         if (AutoTakeProfit)
         {
            volumeStep1 = NormalizeDouble(priceFiboLevel3,digits) ;
         }
         else
         {
            volumeStep1 = NormalizeDouble(orderSendingPrice - TakeProfit * Point(),digits) ;
         }   
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
         orderSendResult = OrderSend(Symbol(),OP_SELLSTOP,orderSendingLotsSell,orderSendingPrice,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Red) ;
         if ( orderSendResult > 0 )   break;
         errorCode = GetLastError() ;
         errorMessage = ErrorDescription(errorCode) ;
         Print("SELLSTOP Send Error Code: " + string(errorCode) + " Message: " + errorMessage + " LT: " + DoubleToString(orderSendingLotsSell,digits) + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
         break;
      case 3 : //PendingStopOrderReversalTrend
         if ( pendingOrderAmount != 0 || breakFibo == 0 || !(costPerCont<=cost) || !(f0_4 ( )) )   break;
         lots = AccountBalance() * AccountLeverage() * riskRate / MarketInfo(Symbol(),15) ;
         if ( !(UseMM) )
         {
            lots = FixedLots ;
         }
         orderSendingLotsBuy = NormalizeDouble(lots * MathPow(LotsExponent,CountTradesBuy ( )),digits) ;
         orderSendingLotsBuy = MathMax(minFixedLots,orderSendingLotsBuy) ;
         orderSendingLotsBuy = MathMin(maxLots,orderSendingLotsBuy) ;
         orderSendingLotsSell = NormalizeDouble(lots * MathPow(LotsExponent,CountTradesSell ( )),digits) ;
         orderSendingLotsSell = MathMax(minFixedLots,orderSendingLotsSell) ;
         orderSendingLotsSell = MathMin(maxLots,orderSendingLotsSell) ;
         if ( breakFibo <  0 ) //bid go break the high fibo level, make sell stop order to follow the trend
         {
            orderSendingPrice = NormalizeDouble(Bid - normPendingDistance,digits) ;
            if (AutoStopLoss){
               volumeStep0 = 0.0; //just wait to fill
            }
            else{
               volumeStep0 = NormalizeDouble(StopLoss * Point() + orderSendingPrice,digits) ;
            }
            if (AutoTakeProfit)
            {
               volumeStep1 = NormalizeDouble(priceFiboLevel5,digits) ;
            }
            else
            {
               volumeStep1 = NormalizeDouble(orderSendingPrice - TakeProfit * Point(),digits) ;
            }
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
            orderSendResult = OrderSend(Symbol(),OP_SELLSTOP,orderSendingLotsSell,orderSendingPrice,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Red) ;
            if ( orderSendResult > 0 )   break;
            errorCode = GetLastError() ;
            errorMessage = ErrorDescription(errorCode) ;
            Print("SELLSTOP Send Error Code: " + string(errorCode) + " Message: " + errorMessage + " LT: " + DoubleToString(orderSendingLotsSell,digits) + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
            break;
            }
         //bid go break the low fibo level, make buy stop order to follow the trend
         orderSendingPrice = NormalizeDouble(Ask + normPendingDistance,digits) ;
         if (AutoStopLoss){
            volumeStep0 = 0.0; //just wait to fill
         }
         else{
            volumeStep0 = NormalizeDouble(orderSendingPrice - StopLoss * Point(),digits) ;
         }
         if (AutoTakeProfit)
         {
            volumeStep1 = NormalizeDouble(priceFiboLevel3,digits) ;
         }
         else
         {
            volumeStep1 = NormalizeDouble(TakeProfit * Point() + orderSendingPrice,digits) ;
         }      
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
         orderSendResult = OrderSend(Symbol(),OP_BUYSTOP,orderSendingLotsBuy,orderSendingPrice,Slippage,volumeStep3,volumeStep2,TradeComment,MagicNumber,0,Blue) ;
         if ( orderSendResult > 0 )   break;
         errorCode = GetLastError() ;
         errorMessage = ErrorDescription(errorCode) ;
         Print("BUYSTOP Send Error Code: " + string(errorCode) + " Message: " + errorMessage + " LT: " + DoubleToString(orderSendingLotsBuy,digits) + " OP: " + DoubleToString(orderSendingPrice,digits) + " SL: " + DoubleToString(volumeStep3,digits) + " TP: " + DoubleToString(volumeStep2,digits) + " Bid: " + DoubleToString(Bid,digits) + " Ask: " + DoubleToString(Ask,digits)); 
   }
   tradeComm = "AvgSpread:" + DoubleToString(spreadAvg,digits) + "  Commission rate:" + DoubleToString(commissionPerCont,digits + 1) + "  Real avg. spread:" + DoubleToString(costPerCont,digits + 1) ;
   if ( costPerCont>cost )
   {
      tradeComm = tradeComm + "\n" + "The EA can not run with this spread ( " + DoubleToString(costPerCont,digits + 1) + " > " + DoubleToString(cost,digits + 1) + " )" ;
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
         // if Ask - TrilingStart > openPrice + TrailingStop, then Move TrailingStop
         if ( ( !(NormalizeDouble(OrderStopLoss(),Digits())<NormalizeDouble(Bid - TrailingStop * Point(),Digits())) && !(OrderStopLoss()==0.0) ) || !(OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid - TrailingStop * Point(),Digits()),OrderTakeProfit(),0,Blue)) || GetLastError() != 0 )   continue;
         
         Print(Symbol() + ": Trailing Buy OrderModify ok "); 
            continue;
      }

      // sell order
      if ( TrailingStop <= 0 || !(NormalizeDouble(TrailingStart * Point() + Bid,Digits())<NormalizeDouble(OrderOpenPrice() - TrailingStop * Point(),Digits())) )   continue;
      if ( ( !(NormalizeDouble(OrderStopLoss(),Digits())>NormalizeDouble(TrailingStop * Point() + Ask,Digits())) && !(OrderStopLoss()==0.0) ) || !(OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(TrailingStop * Point() + Ask,Digits()),OrderTakeProfit(),0,Red)) || GetLastError() != 0 )   continue;
      Print(Symbol() + ": Trailing Sell OrderModify ok "); 
   }
}
//MoveTrailingStop <<==
//---------- ----------  ---------- ----------

void MoveTakeProfitBuy(double takeProfitPrice)
// move take profit for all buy orders
{
   int pos;
   int errorCode;
   string errorMessage;
   bool  orderModifyResult;
   for(pos = 0; pos < OrdersTotal(); pos++)
   {
      if(!(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber )   continue;
      if (OrderType() == 0 || OrderType() == 2 || OrderType() == 4)
      {
         orderModifyResult = OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(takeProfitPrice,Digits()),0,Blue);
         if ( orderModifyResult )   break;
         errorCode = GetLastError() ;
         errorMessage = ErrorDescription(errorCode) ;
         Print("BUY Order Modify Error Code: " + string(errorCode) + " Message: " + errorMessage + " OP: " + " TP: " + DoubleToString(takeProfitPrice,Digits())); 
         break;
      }
   }
   Print(Symbol() + ": Total TakeProfit Buy OrderModify ok "); 
}

void MoveTakeProfitSell(double takeProfitPrice)
// move take profit for all sell orders
{
   int pos;
   int errorCode;
   string errorMessage;
   bool  orderModifyResult;
   for(pos = 0; pos < OrdersTotal(); pos++)
   {
      if(!(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)) || OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber )   continue;
      if (OrderType() == 1 || OrderType() == 3 || OrderType() == 5)
      {
         orderModifyResult = OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),NormalizeDouble(takeProfitPrice,Digits()),0,Blue);
         if ( orderModifyResult )   break;
         errorCode = GetLastError() ;
         errorMessage = ErrorDescription(errorCode) ;
         Print("Sell Order Modify Error Code: " + string(errorCode) + " Message: " + errorMessage + " OP: " + " TP: " + DoubleToString(takeProfitPrice,Digits())); 
         break;
      }
   }
   Print(Symbol() + ": Total TakeProfit Sell OrderModify ok "); 
}



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
            orderclosed = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),9),Slippage,Blue) ; // market info 9: bid price
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
   // mainComment = "----------------------------------------\n" ;
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
   mainComment = mainComment + "Target Money Buy = " + DoubleToString(targetMoneyBuy,2) + br ;
   mainComment = mainComment + "Stoploss Money Buy = " + DoubleToString(-(slMoneyBuy),2) + br ;
   mainComment = mainComment + separation;
   mainComment = mainComment + "Target Money Sell = " + DoubleToString(targetMoneySell,2) + br ;
   mainComment = mainComment + "Stoploss Money Sell = " + DoubleToString( -(slMoneySell),2) + br ;
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
//fiboLevel_price will be calculated at this function
{
   double lowestPrice;
   double highestPrice;
   int lowestData;
   int highestData;
   int pos;
   //----- -----
   lowestData = iLowest(NULL,0,MODE_LOW,BarsBack,StartBar) ;
   highestData = iHighest(NULL,0,MODE_HIGH,BarsBack,StartBar) ;
   highestPrice = High[highestData] ;
   lowestPrice = Low[lowestData] ;
   if ( HighToLow )
   {
      DrawVerticalLine ( "v_u_hl",highestData,vlColor); 
      DrawVerticalLine ( "v_l_hl",lowestData,vlColor); 
      if ( ObjectFind("trend_hl") == -1 )
      {
         ObjectCreate("trend_hl",OBJ_TREND,0,Time[highestData],highestPrice,Time[lowestData],lowestPrice,0,0.0); 
      }
      ObjectSet("trend_hl",OBJPROP_TIME1,Time[highestData]); 
      ObjectSet("trend_hl",OBJPROP_TIME2,Time[lowestData]); 
      ObjectSet("trend_hl",OBJPROP_PRICE1,highestPrice); 
      ObjectSet("trend_hl",OBJPROP_PRICE2,lowestPrice); 
      ObjectSet("trend_hl",OBJPROP_STYLE,2.0); 
      ObjectSet("trend_hl",OBJPROP_RAY,0.0); 
      if ( ObjectFind("Fibo_hl") == -1 )
      {
         ObjectCreate("Fibo_hl",OBJ_FIBO,0,0,highestPrice,0,lowestPrice,0,0.0); 
      }
      ObjectSet("Fibo_hl",OBJPROP_PRICE1,highestPrice); 
      ObjectSet("Fibo_hl",OBJPROP_PRICE2,lowestPrice); 
      ObjectSet("Fibo_hl",OBJPROP_LEVELCOLOR,fiboColor); 
      ObjectSet("Fibo_hl",OBJPROP_FIBOLEVELS,7.0); 
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
      for (pos = 0 ; pos < 100 ; pos = pos + 1)
      {
         fiboLevel_7_price[pos] = NormalizeDouble((highestPrice - lowestPrice) * fiboLevel_7 + lowestPrice,Digits());
         fiboLevel_6_price[pos] = NormalizeDouble((highestPrice - lowestPrice) * fiboLevel_6 + lowestPrice,Digits());
         fiboLevel_5_price[pos] = NormalizeDouble((highestPrice - lowestPrice) * fiboLevel_5 + lowestPrice,Digits());
         fiboLevel_4_price[pos] = NormalizeDouble((highestPrice - lowestPrice) * fiboLevel_4 + lowestPrice,Digits());
         fiboLevel_3_price[pos] = NormalizeDouble((highestPrice - lowestPrice) * fiboLevel_3 + lowestPrice,Digits());
         fiboLevel_2_price[pos] = NormalizeDouble((highestPrice - lowestPrice) * fiboLevel_2 + lowestPrice,Digits());
         fiboLevel_1_price[pos] = NormalizeDouble((highestPrice - lowestPrice) * fiboLevel_1 + lowestPrice,Digits());
      }
      return;
   }

   DrawVerticalLine ( "v_u_lh",highestData,vlColor); 
   DrawVerticalLine ( "v_l_lh",lowestData,vlColor); 
   if ( ObjectFind("trend_hl") == -1 )
   {
      ObjectCreate("trend_lh",OBJ_TREND,0,Time[lowestData],lowestPrice,Time[highestData],highestPrice,0,0.0); 
   }
   ObjectSet("trend_lh",OBJPROP_TIME1,Time[lowestData]); 
   ObjectSet("trend_lh",OBJPROP_TIME2,Time[highestData]); 
   ObjectSet("trend_lh",OBJPROP_PRICE1,lowestPrice); 
   ObjectSet("trend_lh",OBJPROP_PRICE2,highestPrice); 
   ObjectSet("trend_lh",OBJPROP_STYLE,2.0); 
   ObjectSet("trend_lh",OBJPROP_RAY,0.0); 
   if ( ObjectFind("Fibo_lh") == -1 )
   {
      ObjectCreate("Fibo_lh",OBJ_FIBO,0,0,lowestPrice,0,highestPrice,0,0.0); 
   }
   ObjectSet("Fibo_lh",OBJPROP_PRICE1,lowestPrice); 
   ObjectSet("Fibo_lh",OBJPROP_PRICE2,highestPrice); 
   ObjectSet("Fibo_lh",OBJPROP_LEVELCOLOR,fiboColor); 
   ObjectSet("Fibo_lh",OBJPROP_FIBOLEVELS,7.0); 
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
   for (pos = 0 ; pos < 100 ; pos = pos + 1)
   {
      fiboLevel_1_price[pos] = NormalizeDouble(highestPrice,4);
      fiboLevel_2_price[pos] = NormalizeDouble(highestPrice - (highestPrice - lowestPrice) * fiboLevel_2,Digits());
      fiboLevel_3_price[pos] = NormalizeDouble(highestPrice - (highestPrice - lowestPrice) * fiboLevel_3,Digits());
      fiboLevel_4_price[pos] = NormalizeDouble(highestPrice - (highestPrice - lowestPrice) * fiboLevel_4,Digits());
      fiboLevel_5_price[pos] = NormalizeDouble(highestPrice - (highestPrice - lowestPrice) * fiboLevel_5,Digits());
      fiboLevel_6_price[pos] = NormalizeDouble(highestPrice - (highestPrice - lowestPrice) * fiboLevel_6,Digits());
      fiboLevel_7_price[pos] = NormalizeDouble(lowestPrice,4);
   }
}
//CalcFibo <<==
//---------- ----------  ---------- ----------

void DrawVerticalLine(string objectName,int priceData,color objectColor)
//draw vertical line at specific price data
{
   if ( ObjectFind(objectName) == -1 )
      {
         ObjectCreate(objectName,OBJ_VLINE,0,Time[priceData],0.0,0,0.0,0,0.0); 
         ObjectSet(objectName,OBJPROP_COLOR,objectColor); 
         ObjectSet(objectName,OBJPROP_STYLE,1.0); 
         ObjectSet(objectName,OBJPROP_WIDTH,1.0); 
         WindowRedraw(); 
         return;
      }
   ObjectDelete(objectName); 
   ObjectCreate(objectName,OBJ_VLINE,0,Time[priceData],0.0,0,0.0,0,0.0); 
   ObjectSet(objectName,OBJPROP_COLOR,objectColor); 
   ObjectSet(objectName,OBJPROP_STYLE,1.0); 
   ObjectSet(objectName,OBJPROP_WIDTH,1.0); 
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
