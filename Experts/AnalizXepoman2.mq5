//+------------------------------------------------------------------+
//|                                    XAU_Analyzer_Trader.mq5       |
//|              Полный анализ + авто-торговля с подтверждением      |
//+------------------------------------------------------------------+
#property strict

struct IndicatorVotes
{
   int votes[10];
   int totalSum;
   string signal;
   int candlesForecast;
   double currentPrice;
   double targetPrice;
   double atrValue;
};

IndicatorVotes resultH1, resultH4, resultD1;

//--- Хендлы индикаторов (H1, H4, D1)
int hEMA50_H1, hEMA200_H1, hMACD_H1, hADX_H1, hRSI_H1;
int hStoch_H1, hCCI_H1, hVol_H1, hOBV_H1, hBB_H1, hATR_H1;
int hEMA50_H4, hEMA200_H4, hMACD_H4, hADX_H4, hRSI_H4;
int hStoch_H4, hCCI_H4, hVol_H4, hOBV_H4, hBB_H4, hATR_H4;
int hEMA50_D1, hEMA200_D1, hMACD_D1, hADX_D1, hRSI_D1;
int hStoch_D1, hCCI_D1, hVol_D1, hOBV_D1, hBB_D1, hATR_D1;

//--- Информация о паре
string currentSymbol = "";
string symbolType = "";
int symbolDigits = 0;
double symbolPoint = 0;
long symbolSpread = 0;
long symbolStopLevel = 0;
string currentSession = "";

//--- Параметры панели
string panelName = "AnalysisPanel";
string buttonName = "CollapseButton";
int panelX = 20, panelY = 30;
int panelWidth = 480;
int panelHeightExpanded = 620;
int panelHeightCollapsed = 35;
bool isCollapsed = false;

//--- Торговые параметры
input bool   AutoTrading      = true;       // Автоматическая торговля
input int    MagicNumber      = 20261008;   // Магический номер
input double RiskPercent      = 1.0;        // Риск на сделку (% от депозита)
input double ATR_SL_Mult      = 1.5;        // Множитель ATR для стоп-лосса
input int    MaxOrders        = 1;          // Макс. кол-во ордеров
input bool   UseSoundAlert    = true;       // Звуковой сигнал
input bool   UsePushNotify    = false;      // Push-уведомление

//--- Состояние торговли
string lastSignal = "";
datetime lastSignalTime = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   currentSymbol = _Symbol;
   symbolDigits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   symbolPoint = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   symbolSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   symbolStopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   symbolType = DetectSymbolType(_Symbol);
   
   //=== ИНИЦИАЛИЗАЦИЯ ИНДИКАТОРОВ H1 ===
   hEMA50_H1 = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   hEMA200_H1 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
   hMACD_H1 = iMACD(_Symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE);
   hADX_H1 = iADX(_Symbol, PERIOD_H1, 14);
   hRSI_H1 = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);
   hStoch_H1 = iStochastic(_Symbol, PERIOD_H1, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
   hCCI_H1 = iCCI(_Symbol, PERIOD_H1, 20, PRICE_CLOSE);
   hVol_H1 = iVolumes(_Symbol, PERIOD_H1, VOLUME_TICK);
   hOBV_H1 = iOBV(_Symbol, PERIOD_H1, VOLUME_TICK);
   hBB_H1 = iBands(_Symbol, PERIOD_H1, 20, 0, 2.0, PRICE_CLOSE);
   hATR_H1 = iATR(_Symbol, PERIOD_H1, 14);
   
   //=== ИНИЦИАЛИЗАЦИЯ ИНДИКАТОРОВ H4 ===
   hEMA50_H4 = iMA(_Symbol, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE);
   hEMA200_H4 = iMA(_Symbol, PERIOD_H4, 200, 0, MODE_EMA, PRICE_CLOSE);
   hMACD_H4 = iMACD(_Symbol, PERIOD_H4, 12, 26, 9, PRICE_CLOSE);
   hADX_H4 = iADX(_Symbol, PERIOD_H4, 14);
   hRSI_H4 = iRSI(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);
   hStoch_H4 = iStochastic(_Symbol, PERIOD_H4, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
   hCCI_H4 = iCCI(_Symbol, PERIOD_H4, 20, PRICE_CLOSE);
   hVol_H4 = iVolumes(_Symbol, PERIOD_H4, VOLUME_TICK);
   hOBV_H4 = iOBV(_Symbol, PERIOD_H4, VOLUME_TICK);
   hBB_H4 = iBands(_Symbol, PERIOD_H4, 20, 0, 2.0, PRICE_CLOSE);
   hATR_H4 = iATR(_Symbol, PERIOD_H4, 14);
   
   //=== ИНИЦИАЛИЗАЦИЯ ИНДИКАТОРОВ D1 ===
   hEMA50_D1 = iMA(_Symbol, PERIOD_D1, 50, 0, MODE_EMA, PRICE_CLOSE);
   hEMA200_D1 = iMA(_Symbol, PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE);
   hMACD_D1 = iMACD(_Symbol, PERIOD_D1, 12, 26, 9, PRICE_CLOSE);
   hADX_D1 = iADX(_Symbol, PERIOD_D1, 14);
   hRSI_D1 = iRSI(_Symbol, PERIOD_D1, 14, PRICE_CLOSE);
   hStoch_D1 = iStochastic(_Symbol, PERIOD_D1, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
   hCCI_D1 = iCCI(_Symbol, PERIOD_D1, 20, PRICE_CLOSE);
   hVol_D1 = iVolumes(_Symbol, PERIOD_D1, VOLUME_TICK);
   hOBV_D1 = iOBV(_Symbol, PERIOD_D1, VOLUME_TICK);
   hBB_D1 = iBands(_Symbol, PERIOD_D1, 20, 0, 2.0, PRICE_CLOSE);
   hATR_D1 = iATR(_Symbol, PERIOD_D1, 14);
   
   // Проверка хендлов (убрали несуществующий hClose_H1)
   if(hEMA50_H1==INVALID_HANDLE || hRSI_H1==INVALID_HANDLE || hATR_H1==INVALID_HANDLE)
   {
      Print("❌ Ошибка создания индикаторов!");
      return(INIT_FAILED);
   }
   
   CreatePanel();
   CreateCollapseButton();
   EventSetTimer(60);
   
   Print("✅ ", currentSymbol, " (", symbolType, ") Торговый бот запущен");
   Print("StopLevel: ", symbolStopLevel, " пунктов");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeletePanel();
   EventKillTimer();
}

//+------------------------------------------------------------------+
void OnTimer() { Analyze(); }
void OnTick()  { Analyze(); }

//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == buttonName)
   {
      isCollapsed = !isCollapsed;
      ObjectSetInteger(0, buttonName, OBJPROP_STATE, false);
      UpdateCollapseButton();
      UpdatePanel();
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
string DetectSymbolType(string symbol)
{
   string sym = symbol;
   StringToUpper(sym);
   if(StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0) return "ЗОЛОТО 🥇";
   if(StringFind(sym, "XAG") >= 0 || StringFind(sym, "SILVER") >= 0) return "СЕРЕБРО 🥈";
   if(StringFind(sym, "BTC") >= 0) return "КРИПТО ₿";
   if(StringFind(sym, "ETH") >= 0) return "КРИПТО Ξ";
   if(StringFind(sym, "US30") >= 0 || StringFind(sym, "SPX") >= 0 || StringFind(sym, "NAS") >= 0) return "ИНДЕКС 📊";
   if(StringFind(sym, "OIL") >= 0 || StringFind(sym, "WTI") >= 0 || StringFind(sym, "BRENT") >= 0) return "НЕФТЬ 🛢";
   string currencies[] = {"USD", "EUR", "GBP", "JPY", "CHF", "AUD", "CAD", "NZD"};
   for(int i = 0; i < 8; i++)
      if(StringFind(sym, currencies[i]) >= 0) return "ФОРЕКС 💱";
   return "ДРУГОЕ";
}

//+------------------------------------------------------------------+
string DetectSession()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.hour >= 0 && dt.hour < 8)   return "АЗИЯ 🌏";
   if(dt.hour >= 8 && dt.hour < 13)  return "ЕВРОПА 🇪🇺";
   if(dt.hour >= 13 && dt.hour < 21) return "АМЕРИКА 🇺🇸";
   return "ТИХИЙ ОКЕАН 🌊";
}

//+------------------------------------------------------------------+
string DetectDayOfWeek()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   string days[] = {"ВС", "ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ"};
   return days[dt.day_of_week];
}

//+------------------------------------------------------------------+
void Analyze()
{
   currentSession = DetectSession();
   symbolSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   
   AnalyzeTimeframe(PERIOD_H1, hEMA50_H1, hEMA200_H1, hMACD_H1, hADX_H1, hRSI_H1,
                    hStoch_H1, hCCI_H1, hVol_H1, hOBV_H1, hBB_H1, hATR_H1, resultH1);
   AnalyzeTimeframe(PERIOD_H4, hEMA50_H4, hEMA200_H4, hMACD_H4, hADX_H4, hRSI_H4,
                    hStoch_H4, hCCI_H4, hVol_H4, hOBV_H4, hBB_H4, hATR_H4, resultH4);
   AnalyzeTimeframe(PERIOD_D1, hEMA50_D1, hEMA200_D1, hMACD_D1, hADX_D1, hRSI_D1,
                    hStoch_D1, hCCI_D1, hVol_D1, hOBV_D1, hBB_D1, hATR_D1, resultD1);
   
   UpdatePanel();
   
   if(AutoTrading && !IsTradeAllowed()) return;
   
   string entrySignal = CheckEntryConfirmation();
   
   if(entrySignal != lastSignal && entrySignal != "")
   {
      lastSignal = entrySignal;
      lastSignalTime = TimeCurrent();
      
      DeletePendingOrders();
      PlaceSmartOrder(entrySignal);
      
      if(UseSoundAlert)
      {
         if(StringFind(entrySignal, "BUY") >= 0) PlaySound("alert.wav");
         else PlaySound("alert2.wav");
      }
      
      if(UsePushNotify)
         SendNotification(currentSymbol + ": " + entrySignal);
      
      Print("🔔 СИГНАЛ ВХОДА: ", entrySignal);
   }
   
   ManageOpenPositions();
   ChartRedraw();
}

//+------------------------------------------------------------------+
string CheckEntryConfirmation()
{
   if(MathAbs(resultH1.totalSum) < 5) return ""; 
   
   if(resultH1.totalSum > 0 && resultH4.totalSum < 1) return "";
   if(resultH1.totalSum < 0 && resultH4.totalSum > -1) return "";
   
   if(resultH1.totalSum > 0 && resultD1.totalSum < -2) return "";
   if(resultH1.totalSum < 0 && resultD1.totalSum > 2) return "";
   
   //=== ПРАВИЛО 4: Свечное подтверждение на H1 (исправлено, используем CopyClose напрямую) ===
   double closeH1[], openH1[];
   ArraySetAsSeries(closeH1, true);
   ArraySetAsSeries(openH1, true);
   if(CopyClose(_Symbol, PERIOD_H1, 0, 3, closeH1) < 3) return "";
   if(CopyOpen(_Symbol, PERIOD_H1, 0, 3, openH1) < 3) return "";
   
   bool bullishCandle = (closeH1[1] > openH1[1]);
   bool bearishCandle = (closeH1[1] < openH1[1]);
   
   if(resultH1.totalSum > 0 && !bullishCandle) return "";
   if(resultH1.totalSum < 0 && !bearishCandle) return "";
   
   //=== ПРАВИЛО 5: RSI не в экстремуме ===
   double rsi[];
   ArraySetAsSeries(rsi, true);
   if(CopyBuffer(hRSI_H1, 0, 0, 3, rsi) < 3) return "";
   
   if(resultH1.totalSum > 0 && rsi[1] > 75) return ""; 
   if(resultH1.totalSum < 0 && rsi[1] < 25) return ""; 
   
   if(resultH1.totalSum > 0)
      return "CONFIRMED BUY 🟢";
   else
      return "CONFIRMED SELL 🔴";
}

//+------------------------------------------------------------------+
void PlaceSmartOrder(string signal)
{
   if(CountPendingOrders() >= MaxOrders) return;
   if(CountOpenPositions() >= MaxOrders) return;
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   double ema50[], bbMiddle[];
   ArraySetAsSeries(ema50, true);
   ArraySetAsSeries(bbMiddle, true);
   
   if(CopyBuffer(hEMA50_H1, 0, 0, 3, ema50) < 3) return;
   if(CopyBuffer(hBB_H1, 0, 0, 3, bbMiddle) < 3) return;
   
   double rsi[];
   ArraySetAsSeries(rsi, true);
   if(CopyBuffer(hRSI_H1, 0, 0, 3, rsi) < 3) return;
   
   double lot = CalculateLotSize(resultH1.atrValue * ATR_SL_Mult);
   if(lot <= 0) return;
   
   double slDistance = resultH1.atrValue * ATR_SL_Mult;
   double tpPrice = resultH1.targetPrice; 
   
   double minDistance = symbolStopLevel * point;
   if(slDistance < minDistance) slDistance = minDistance * 1.5;
   
   string orderType = "";
   double orderPrice = 0, sl = 0, tp = 0;
   
   if(StringFind(signal, "BUY") >= 0)
   {
      if(rsi[1] < 45)
      {
         orderType = "BUY LIMIT";
         orderPrice = MathMax(ema50[1], bbMiddle[1]);
         if(orderPrice >= bid) orderPrice = bid - resultH1.atrValue * 0.5;
         sl = orderPrice - slDistance;
         tp = tpPrice;
         if(tp <= orderPrice) tp = orderPrice + slDistance * 2;
      }
      else
      {
         double high[];
         ArraySetAsSeries(high, true);
         if(CopyHigh(_Symbol, PERIOD_H1, 0, 5, high) < 5) return;
         orderType = "BUY STOP";
         orderPrice = high[1] + resultH1.atrValue * 0.2;
         sl = orderPrice - slDistance;
         tp = tpPrice;
         if(tp <= orderPrice) tp = orderPrice + slDistance * 2;
      }
      
      orderPrice = NormalizeDouble(orderPrice, symbolDigits);
      sl = NormalizeDouble(sl, symbolDigits);
      tp = NormalizeDouble(tp, symbolDigits);
      
      if(MathAbs(orderPrice - bid) < minDistance)
         orderPrice = bid + minDistance + point;
      
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      request.action = TRADE_ACTION_PENDING;
      request.symbol = _Symbol;
      request.volume = lot;
      request.price = orderPrice;
      request.sl = sl;
      request.tp = tp;
      request.type = ORDER_TYPE_BUY_LIMIT;
      if(orderType == "BUY STOP") request.type = ORDER_TYPE_BUY_STOP;
      request.magic = MagicNumber;
      request.comment = signal;
      
      if(OrderSend(request, result))
         Print("✅ ", orderType, " выставлен: ", orderPrice, " SL:", sl, " TP:", tp, " Lot:", lot);
      else
         Print("❌ Ошибка ордера: ", result.retcode, " ", result.comment);
   }
   else // SELL
   {
      if(rsi[1] > 55)
      {
         orderType = "SELL LIMIT";
         orderPrice = MathMin(ema50[1], bbMiddle[1]);
         if(orderPrice <= ask) orderPrice = ask + resultH1.atrValue * 0.5;
         sl = orderPrice + slDistance;
         tp = tpPrice;
         if(tp >= orderPrice) tp = orderPrice - slDistance * 2;
      }
      else
      {
         double low[];
         ArraySetAsSeries(low, true);
         if(CopyLow(_Symbol, PERIOD_H1, 0, 5, low) < 5) return;
         orderType = "SELL STOP";
         orderPrice = low[1] - resultH1.atrValue * 0.2;
         sl = orderPrice + slDistance;
         tp = tpPrice;
         if(tp >= orderPrice) tp = orderPrice - slDistance * 2;
      }
      
      orderPrice = NormalizeDouble(orderPrice, symbolDigits);
      sl = NormalizeDouble(sl, symbolDigits);
      tp = NormalizeDouble(tp, symbolDigits);
      
      if(MathAbs(orderPrice - ask) < minDistance)
         orderPrice = ask - minDistance - point;
      
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      request.action = TRADE_ACTION_PENDING;
      request.symbol = _Symbol;
      request.volume = lot;
      request.price = orderPrice;
      request.sl = sl;
      request.tp = tp;
      request.type = ORDER_TYPE_SELL_LIMIT;
      if(orderType == "SELL STOP") request.type = ORDER_TYPE_SELL_STOP;
      request.magic = MagicNumber;
      request.comment = signal;
      
      if(OrderSend(request, result))
         Print("✅ ", orderType, " выставлен: ", orderPrice, " SL:", sl, " TP:", tp, " Lot:", lot);
      else
         Print("❌ Ошибка ордера: ", result.retcode, " ", result.comment);
   }
}

//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
   if(slDistance <= 0) return 0.01;
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * RiskPercent / 100.0;
   
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(tickValue <= 0 || tickSize <= 0) return 0.01;
   
   double lot = riskMoney / ((slDistance / tickSize) * tickValue);
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lot = MathFloor(lot / lotStep) * lotStep;
   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;
   
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      
      string posType = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
      
      if(posType == "BUY" && resultH1.totalSum <= -5)
      {
         ClosePosition(ticket);
         Print("🔄 Позиция BUY закрыта — сигнал сменился");
      }
      else if(posType == "SELL" && resultH1.totalSum >= 5)
      {
         ClosePosition(ticket);
         Print("🔄 Позиция SELL закрыта — сигнал сменился");
      }
   }
}

//+------------------------------------------------------------------+
void ClosePosition(ulong ticket)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = _Symbol;
   request.volume = PositionGetDouble(POSITION_VOLUME);
   request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price = (request.type == ORDER_TYPE_SELL) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.deviation = 10;
   request.magic = MagicNumber;
   
   OrderSend(request, result);
}

//+------------------------------------------------------------------+
void DeletePendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;
      
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      request.action = TRADE_ACTION_REMOVE;
      request.order = ticket;
      OrderSend(request, result);
   }
}

//+------------------------------------------------------------------+
int CountPendingOrders()
{
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if(OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;
      count++;
   }
   return count;
}

//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      count++;
   }
   return count;
}

//+------------------------------------------------------------------+
bool IsTradeAllowed()
{
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return false;
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) return false;
   return true;
}

//+------------------------------------------------------------------+
void AnalyzeTimeframe(ENUM_TIMEFRAMES tf, int hEMA50, int hEMA200, int hMACD, int hADX, int hRSI,
                      int hStoch, int hCCI, int hVol, int hOBV, int hBB, int hATR, IndicatorVotes &result)
{
   double bufEMA50[], bufEMA200[], bufClose[];
   double bufMACDMain[], bufMACDSig[];
   double bufADX[], bufPlusDI[], bufMinusDI[];
   double bufRSI[], bufStochK[], bufStochD[], bufCCI[];
   double bufVol[], bufOBV[];
   double bufBBUpper[], bufBBMiddle[], bufBBLower[];
   double bufATR[];
   
   ArraySetAsSeries(bufEMA50, true);   ArraySetAsSeries(bufEMA200, true);
   ArraySetAsSeries(bufMACDMain, true); ArraySetAsSeries(bufMACDSig, true);
   ArraySetAsSeries(bufADX, true);     ArraySetAsSeries(bufPlusDI, true); ArraySetAsSeries(bufMinusDI, true);
   ArraySetAsSeries(bufRSI, true);
   ArraySetAsSeries(bufStochK, true);  ArraySetAsSeries(bufStochD, true);
   ArraySetAsSeries(bufCCI, true);
   ArraySetAsSeries(bufVol, true);
   ArraySetAsSeries(bufOBV, true);
   ArraySetAsSeries(bufBBUpper, true); ArraySetAsSeries(bufBBMiddle, true); ArraySetAsSeries(bufBBLower, true);
   ArraySetAsSeries(bufClose, true);
   ArraySetAsSeries(bufATR, true);
   
   if(CopyBuffer(hEMA50, 0, 0, 3, bufEMA50) < 3) return;
   if(CopyBuffer(hEMA200, 0, 0, 3, bufEMA200) < 3) return;
   if(CopyBuffer(hMACD, 0, 0, 3, bufMACDMain) < 3) return;
   if(CopyBuffer(hMACD, 1, 0, 3, bufMACDSig) < 3) return;
   if(CopyBuffer(hADX, 0, 0, 3, bufADX) < 3) return;
   if(CopyBuffer(hADX, 1, 0, 3, bufPlusDI) < 3) return;
   if(CopyBuffer(hADX, 2, 0, 3, bufMinusDI) < 3) return;
   if(CopyBuffer(hRSI, 0, 0, 3, bufRSI) < 3) return;
   if(CopyBuffer(hStoch, 0, 0, 3, bufStochK) < 3) return;
   if(CopyBuffer(hStoch, 1, 0, 3, bufStochD) < 3) return;
   if(CopyBuffer(hCCI, 0, 0, 3, bufCCI) < 3) return;
   if(CopyBuffer(hVol, 0, 0, 3, bufVol) < 3) return;
   if(CopyBuffer(hOBV, 0, 0, 3, bufOBV) < 3) return;
   if(CopyBuffer(hBB, 0, 0, 3, bufBBMiddle) < 3) return;
   if(CopyBuffer(hBB, 1, 0, 3, bufBBUpper) < 3) return;
   if(CopyBuffer(hBB, 2, 0, 3, bufBBLower) < 3) return;
   if(CopyBuffer(hATR, 0, 0, 3, bufATR) < 3) return;
   if(CopyClose(_Symbol, tf, 0, 3, bufClose) < 3) return;
   
   result.votes[0] = (bufClose[1] > bufEMA50[1]) ? 1 : -1;
   result.votes[1] = (bufClose[1] > bufEMA200[1]) ? 1 : -1;
   
   if(bufMACDMain[2] < bufMACDSig[2] && bufMACDMain[1] > bufMACDSig[1]) result.votes[2] = 1;
   else if(bufMACDMain[2] > bufMACDSig[2] && bufMACDMain[1] < bufMACDSig[1]) result.votes[2] = -1;
   else result.votes[2] = (bufMACDMain[1] > bufMACDSig[1]) ? 1 : -1;
   
   if(bufADX[1] > 25)
      result.votes[3] = (bufPlusDI[1] > bufMinusDI[1]) ? 1 : -1;
   else
      result.votes[3] = 0;
   
   if(bufRSI[1] > 70) result.votes[4] = -1;
   else if(bufRSI[1] < 30) result.votes[4] = 1;
   else result.votes[4] = (bufRSI[1] > 50) ? 1 : -1;
   
   if(bufStochK[2] < bufStochD[2] && bufStochK[1] > bufStochD[1] && bufStochK[1] < 30) result.votes[5] = 1;
   else if(bufStochK[2] > bufStochD[2] && bufStochK[1] < bufStochD[1] && bufStochK[1] > 70) result.votes[5] = -1;
   else result.votes[5] = 0;
   
   if(bufCCI[1] > 100) result.votes[6] = 1;
   else if(bufCCI[1] < -100) result.votes[6] = -1;
   else result.votes[6] = 0;
   
   if(bufVol[1] > bufVol[2] * 1.2)
      result.votes[7] = (bufClose[1] > bufClose[2]) ? 1 : -1;
   else
      result.votes[7] = 0;
   
   result.votes[8] = (bufOBV[1] > bufOBV[2]) ? 1 : -1;
   
   if(bufClose[1] <= bufBBLower[1]) result.votes[9] = 1;
   else if(bufClose[1] >= bufBBUpper[1]) result.votes[9] = -1;
   else result.votes[9] = 0;
   
   result.totalSum = 0;
   for(int i = 0; i < 10; i++) result.totalSum += result.votes[i];
   
   if(result.totalSum >= 5)       result.signal = "STRONG BUY";
   else if(result.totalSum >= 3)  result.signal = "BUY";
   else if(result.totalSum <= -5) result.signal = "STRONG SELL";
   else if(result.totalSum <= -3) result.signal = "SELL";
   else                           result.signal = "HOLD";
   
   double atrValue = bufATR[1];
   result.atrValue = atrValue;
   double priceRange = bufBBUpper[1] - bufBBLower[1];
   
   int baseCandles = MathAbs(result.totalSum);
   double volatilityFactor = (priceRange > 0) ? atrValue / (priceRange * 0.1) : 1.0;
   
   if(volatilityFactor > 1.5) result.candlesForecast = (int)(baseCandles * 0.7);
   else if(volatilityFactor < 0.5) result.candlesForecast = (int)(baseCandles * 1.5);
   else result.candlesForecast = baseCandles;
   
   if(result.candlesForecast < 1) result.candlesForecast = 1;
   if(result.candlesForecast > 10) result.candlesForecast = 10;
   
   result.currentPrice = bufClose[1];
   
   double multiplier = 0;
   if(result.totalSum >= 5) multiplier = 2.5;
   else if(result.totalSum >= 3) multiplier = 1.8;
   else if(result.totalSum <= -5) multiplier = 2.5;
   else if(result.totalSum <= -3) multiplier = 1.8;
   
   multiplier *= (result.candlesForecast / 5.0);
   
   if(result.totalSum > 0)
   {
      result.targetPrice = result.currentPrice + (atrValue * multiplier);
      if(result.targetPrice > bufBBUpper[1] * 1.02) result.targetPrice = bufBBUpper[1] * 1.02;
   }
   else if(result.totalSum < 0)
   {
      result.targetPrice = result.currentPrice - (atrValue * multiplier);
      if(result.targetPrice < bufBBLower[1] * 0.98) result.targetPrice = bufBBLower[1] * 0.98;
   }
   else
   {
      result.targetPrice = result.currentPrice;
   }
}

//+------------------------------------------------------------------+
void CreatePanel()
{
   ObjectCreate(0, panelName+"_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_XDISTANCE, panelX);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YDISTANCE, panelY);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YSIZE, panelHeightExpanded);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_BGCOLOR, C'20,20,30');
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_COLOR, C'60,60,80');
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_BACK, false);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_SELECTABLE, false);
}

void CreateCollapseButton()
{
   ObjectCreate(0, buttonName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, buttonName, OBJPROP_XDISTANCE, panelX + panelWidth - 35);
   ObjectSetInteger(0, buttonName, OBJPROP_YDISTANCE, panelY + 3);
   ObjectSetInteger(0, buttonName, OBJPROP_XSIZE, 30);
   ObjectSetInteger(0, buttonName, OBJPROP_YSIZE, 28);
   ObjectSetString(0, buttonName, OBJPROP_TEXT, "▼");
   ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, buttonName, OBJPROP_BGCOLOR, C'40,40,60');
   ObjectSetInteger(0, buttonName, OBJPROP_BORDER_COLOR, C'80,80,100');
   ObjectSetString(0, buttonName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, buttonName, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(0, buttonName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, buttonName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, buttonName, OBJPROP_STATE, false);
}

void UpdateCollapseButton()
{
   if(isCollapsed)
   {
      ObjectSetString(0, buttonName, OBJPROP_TEXT, "▲");
      ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrOrange);
   }
   else
   {
      ObjectSetString(0, buttonName, OBJPROP_TEXT, "▼");
      ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrYellow);
   }
   int newHeight = isCollapsed ? panelHeightCollapsed : panelHeightExpanded;
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YSIZE, newHeight);
}

void UpdatePanel()
{
   int currentHeight = isCollapsed ? panelHeightCollapsed : panelHeightExpanded;
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YSIZE, currentHeight);
   
   int y = panelY + 10;
   int lineHeight = 20;
   string priceFormat = "%." + IntegerToString(symbolDigits) + "f";
   
   string title = "═══ " + currentSymbol + " (" + symbolType + ") ═══";
   CreateLabel(panelName+"_Title", title, panelX + 10, y, clrYellow, 11);
   
   if(isCollapsed)
   {
      string shortInfo = "";
      color shortColor = clrGray;
      if(resultH1.totalSum >= 5)       { shortInfo = "▲ STRONG BUY"; shortColor = clrLime; }
      else if(resultH1.totalSum >= 3)  { shortInfo = "▲ BUY";        shortColor = clrGreen; }
      else if(resultH1.totalSum <= -5) { shortInfo = "▼ STRONG SELL"; shortColor = clrRed; }
      else if(resultH1.totalSum <= -3) { shortInfo = "▼ SELL";       shortColor = clrDarkRed; }
      else                             { shortInfo = "● HOLD";       shortColor = clrGray; }
      CreateLabel(panelName+"_ShortInfo", shortInfo, panelX + 250, y, shortColor, 10);
      HideAllDetails();
   }
   else
   {
      ShowAllDetails(y, lineHeight, priceFormat);
   }
   ChartRedraw();
}

void HideAllDetails()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, panelName) == 0 && 
         StringFind(name, "_BG") < 0 && 
         StringFind(name, "_Title") < 0 && 
         StringFind(name, "_ShortInfo") < 0)
         ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   }
}

void ShowAllDetails(int startY, int lineHeight, string priceFormat)
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, panelName) == 0)
         ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   ObjectSetInteger(0, panelName+"_ShortInfo", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   
   int y = startY + lineHeight + 3;
   
   CreateLabel(panelName+"_Type", "Тип: " + symbolType, panelX + 10, y, clrLightSkyBlue, 9);
   CreateLabel(panelName+"_Session", currentSession + " | " + DetectDayOfWeek(), 
               panelX + 250, y, clrWheat, 9);
   y += lineHeight;
   
   CreateLabel(panelName+"_Spread", "Спред: " + IntegerToString(symbolSpread) + " pts", 
               panelX + 10, y, clrLightGray, 9);
   CreateLabel(panelName+"_Point", "Point: " + DoubleToString(symbolPoint, symbolDigits), 
               panelX + 250, y, clrLightGray, 9);
   y += lineHeight;
   
   CreateLabel(panelName+"_Time", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS), 
               panelX + 10, y, clrGray, 9);
   y += lineHeight + 3;
   
   CreateLabel(panelName+"_Sep0", "═══════════════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   CreateLabel(panelName+"_Col1", "ТФ", panelX + 20, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col2", "СИГНАЛЫ", panelX + 80, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col3", "Σ", panelX + 270, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col4", "ПРОГНОЗ", panelX + 310, y, clrDodgerBlue, 10);
   y += lineHeight + 3;
   
   CreateLabel(panelName+"_Sep1", "─────────────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   DrawTFRow("H1", resultH1, "H1", y, priceFormat, lineHeight);
   y += lineHeight * 3 + 3;
   
   CreateLabel(panelName+"_Sep2", "─────────────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   DrawTFRow("H4", resultH4, "H4", y, priceFormat, lineHeight);
   y += lineHeight * 3 + 3;
   
   CreateLabel(panelName+"_Sep3", "─────────────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   DrawTFRow("D1", resultD1, "D1", y, priceFormat, lineHeight);
   y += lineHeight * 3 + 3;
   
   CreateLabel(panelName+"_Sep4", "═══════════════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   string confirmStatus = "";
   color confirmColor = clrGray;
   
   bool rule1 = MathAbs(resultH1.totalSum) >= 5;
   bool rule2 = (resultH1.totalSum > 0 && resultH4.totalSum >= 1) || 
                (resultH1.totalSum < 0 && resultH4.totalSum <= -1);
   bool rule3 = (resultH1.totalSum > 0 && resultD1.totalSum >= -2) || 
                (resultH1.totalSum < 0 && resultD1.totalSum <= 2);
   
   CreateLabel(panelName+"_TradeTitle", "🎯 ТОРГОВЛЯ:", panelX + 10, y, clrYellow, 10);
   y += lineHeight;
   
   string r1 = rule1 ? "✅" : "❌";
   color c1 = rule1 ? clrLime : clrRed;
   CreateLabel(panelName+"_Rule1", r1 + " H1: STRONG сигнал", panelX + 20, y, c1, 9);
   y += lineHeight - 3;
   
   string r2 = rule2 ? "✅" : "❌";
   color c2 = rule2 ? clrLime : clrRed;
   CreateLabel(panelName+"_Rule2", r2 + " H4: подтверждение", panelX + 20, y, c2, 9);
   y += lineHeight - 3;
   
   string r3 = rule3 ? "✅" : "❌";
   color c3 = rule3 ? clrLime : clrRed;
   CreateLabel(panelName+"_Rule3", r3 + " D1: тренд совпадает", panelX + 20, y, c3, 9);
   y += lineHeight;
   
   if(rule1 && rule2 && rule3)
   {
      double closeH1[], openH1[], rsi[];
      ArraySetAsSeries(closeH1, true);
      ArraySetAsSeries(openH1, true);
      ArraySetAsSeries(rsi, true);
      CopyClose(_Symbol, PERIOD_H1, 0, 2, closeH1);
      CopyOpen(_Symbol, PERIOD_H1, 0, 2, openH1);
      CopyBuffer(hRSI_H1, 0, 0, 2, rsi);
      
      bool candleOk = (resultH1.totalSum > 0 && closeH1[1] > openH1[1]) ||
                      (resultH1.totalSum < 0 && closeH1[1] < openH1[1]);
      bool rsiOk = (resultH1.totalSum > 0 && rsi[1] < 75) ||
                   (resultH1.totalSum < 0 && rsi[1] > 25);
      
      if(candleOk && rsiOk)
      {
         confirmStatus = (resultH1.totalSum > 0) ? "🟢 CONFIRMED BUY — ЖДЕМ ОРДЕР" : "🔴 CONFIRMED SELL — ЖДЕМ ОРДЕР";
         confirmColor = (resultH1.totalSum > 0) ? clrLime : clrRed;
      }
      else
      {
         confirmStatus = "⏳ Ожидание свечи/RSI...";
         confirmColor = clrOrange;
      }
   }
   else
   {
      confirmStatus = "⏸ Нет подтверждения — ждем";
      confirmColor = clrGray;
   }
   
   CreateLabel(panelName+"_Confirm", confirmStatus, panelX + 20, y, confirmColor, 10);
   y += lineHeight;
   
   int pendingCount = CountPendingOrders();
   int posCount = CountOpenPositions();
   
   string orderInfo = StringFormat("📋 Ордеров: %d | Позиций: %d", pendingCount, posCount);
   CreateLabel(panelName+"_OrderInfo", orderInfo, panelX + 20, y, clrLightSkyBlue, 9);
}

void DrawTFRow(string tfLabel, IndicatorVotes &result, string prefix, int y, string priceFormat, int lineHeight)
{
   CreateLabel(panelName+"_TF_"+prefix, tfLabel, panelX + 25, y, clrWhite, 11);
   
   int xSignals = panelX + 80;
   for(int i = 0; i < 10; i++)
   {
      color c = (result.votes[i] > 0) ? clrLime : (result.votes[i] < 0) ? clrRed : clrGray;
      string s = (result.votes[i] > 0) ? "▲" : (result.votes[i] < 0) ? "▼" : "●";
      CreateLabel(panelName+"_"+prefix+"_"+IntegerToString(i), s, xSignals + i*16, y, c, 10);
   }
   
   color sumColor = (result.totalSum > 0) ? clrLime : (result.totalSum < 0) ? clrRed : clrGray;
   CreateLabel(panelName+"_Sum"+prefix, StringFormat("%+d", result.totalSum), panelX + 275, y, sumColor, 11);
   
   color sigColor = GetSignalColor(result.signal);
   CreateLabel(panelName+"_Signal"+prefix, result.signal, panelX + 310, y, sigColor, 10);
   y += lineHeight;
   
   CreateLabel(panelName+"_Forecast"+prefix, StringFormat("%d свечей", result.candlesForecast), 
               panelX + 310, y, clrOrange, 9);
   y += lineHeight;
   
   string priceStr = StringFormat(priceFormat + " → " + priceFormat, result.currentPrice, result.targetPrice);
   color priceColor = (result.targetPrice > result.currentPrice) ? clrLime : 
                      (result.targetPrice < result.currentPrice) ? clrRed : clrGray;
   CreateLabel(panelName+"_Price"+prefix, priceStr, panelX + 80, y, priceColor, 9);
}

color GetSignalColor(string signal)
{
   if(signal == "STRONG BUY") return clrLime;
   if(signal == "BUY") return clrGreen;
   if(signal == "STRONG SELL") return clrRed;
   if(signal == "SELL") return clrDarkRed;
   return clrGray;
}

void CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
}

void DeletePanel()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, panelName) == 0 || name == buttonName)
         ObjectDelete(0, name);
   }
}
//+------------------------------------------------------------------+