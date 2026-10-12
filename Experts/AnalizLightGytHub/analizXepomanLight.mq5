//+------------------------------------------------------------------+
//|                                    XAU_Analyzer_PRO.mq5          |
//|           PRO-аналитик с вкладками (модульная архитектура)       |
//+------------------------------------------------------------------+
#property strict

//=== ПОДКЛЮЧЕНИЕ МОДУЛЕЙ ===
#include <Config.mqh>
#include <DataStructures.mqh>
#include <Analyzer.mqh>
#include <SignalManager.mqh>
#include <Storage.mqh>
#include <UI/Panel.mqh>

//--- Глобальные параметры (оптимизируемые из input)
IndicatorParams optParams;

//--- Файлы (уникальные для каждой пары)
string historyFileName = "signal_history.dat";
string statsFileName = "";
string logFileName = "";
string resultFileName = "";
datetime logMonthStart = 0;
datetime statsStartDate = 0;
string statsSymbol = "";

//--- Бэктест
bool isBacktestRunning = false;

//--- Результаты анализа по ТФ
IndicatorVotes resultH1, resultH4, resultD1;

//--- Хендлы индикаторов
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
string currentSession = "";

//--- Параметры панели
string panelName = PANEL_NAME;
string buttonName = BUTTON_NAME;
int panelX = PANEL_X;
int panelY = PANEL_Y;
int panelWidth = PANEL_WIDTH;
int panelHeightExpanded = PANEL_HEIGHT_EXPANDED;
int panelHeightCollapsed = PANEL_HEIGHT_COLLAPSED;



//--- Настройки
input bool   UseSoundAlert     = true;
input double ATR_SL_Mult       = 1.5;
input bool   DrawLevels        = true;
input color  EntryColor        = clrDodgerBlue;
input color  SLColor           = clrRed;
input color  TPColor           = clrLime;
input int    NewsMinutesBefore = 30;
input int    NewsMinutesAfter  = 30;
input bool   UsePushNotify     = true;
input int    ResultCheckDelay  = 60;

//=== ОТКЛЮЧАЕМЫЕ ФИЛЬТРЫ ===
input group "══════ ФИЛЬТРЫ (включайте/выключайте) ══════"
input bool   FilterLag         = true;
input bool   FilterStructure   = true;
input bool   FilterRSI         = true;
input bool   FilterCandle      = true;
input bool   FilterSession     = true;
input bool   FilterVolatility  = true;
input bool   FilterNews        = true;

//=== РЕЖИМЫ СИГНАЛОВ ===
input bool   UseSignalH1       = true;
input bool   UseSignalH4       = true;
input bool   UseSignalD1       = true;

//=== ОПТИМИЗИРУЕМЫЕ ПАРАМЕТРЫ ===
input group "══════ ПАРАМЕТРЫ ИНДИКАТОРОВ ══════"
input int    InpEmaFastPeriod  = 30;
input int    InpEmaSlowPeriod  = 200;
input int    InpRsiPeriod      = 10;
input double InpRsiOverbought  = 70.0;
input double InpRsiOversold    = 30.0;
input int    InpMacdFast       = 12;
input int    InpMacdSlow       = 26;
input int    InpMacdSignal     = 9;
input int    InpAdxPeriod      = 14;
input double InpAdxThreshold   = 25.0;
input int    InpStochK         = 14;
input int    InpStochD         = 3;
input int    InpStochSlowing   = 3;
input int    InpCciPeriod      = 20;
input double InpCciLevel       = 100.0;
input int    InpBbPeriod       = 20;
input double InpBbDeviation    = 2.0;
input int    InpAtrPeriod      = 14;
input double InpAtrSlMult      = 2.5;
input double InpSignalThreshold= 8.0;

//=== НАСТРОЙКИ БЭКТЕСТА ===
input group "══════ НАСТРОЙКИ БЭКТЕСТА ══════"
input int    backtestBars      = 1000;
input bool   OptimizeParams    = true;

//+------------------------------------------------------------------+
int OnInit()
{
   currentSymbol = _Symbol;
   
   //=== ИНИЦИАЛИЗАЦИЯ МЕНЕДЖЕРА ===
   SignalManager_Init();
   
   //=== ИНИЦИАЛИЗАЦИЯ ПАРАМЕТРОВ ===
   optParams.emaFastPeriod = InpEmaFastPeriod;
   optParams.emaSlowPeriod = InpEmaSlowPeriod;
   optParams.rsiPeriod = InpRsiPeriod;
   optParams.rsiOverbought = InpRsiOverbought;
   optParams.rsiOversold = InpRsiOversold;
   optParams.macdFast = InpMacdFast;
   optParams.macdSlow = InpMacdSlow;
   optParams.macdSignal = InpMacdSignal;
   optParams.adxPeriod = InpAdxPeriod;
   optParams.adxThreshold = InpAdxThreshold;
   optParams.stochK = InpStochK;
   optParams.stochD = InpStochD;
   optParams.stochSlowing = InpStochSlowing;
   optParams.cciPeriod = InpCciPeriod;
   optParams.cciLevel = InpCciLevel;
   optParams.bbPeriod = InpBbPeriod;
   optParams.bbDeviation = InpBbDeviation;
   optParams.atrPeriod = InpAtrPeriod;
   optParams.atrSLMult = InpAtrSlMult;
   optParams.signalThreshold = InpSignalThreshold;
   
   //=== ИНИЦИАЛИЗАЦИЯ ФАЙЛОВ ===
   Storage_InitFiles(currentSymbol);
   statsFileName = FILE_STATS_PREFIX + currentSymbol + FILE_STATS_EXT;
   logFileName = FILE_SIGNALS_PREFIX + currentSymbol + FILE_CSV_EXT;
   resultFileName = FILE_RESULTS_PREFIX + currentSymbol + FILE_CSV_EXT;
   historyFileName = FILE_HISTORY_PREFIX + currentSymbol + FILE_HISTORY_EXT;
   
   symbolDigits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   symbolPoint = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   symbolSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   symbolType = DetectSymbolType(_Symbol);
   
   // H1
   hEMA50_H1 = iMA(_Symbol, PERIOD_H1, optParams.emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hEMA200_H1 = iMA(_Symbol, PERIOD_H1, optParams.emaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hMACD_H1 = iMACD(_Symbol, PERIOD_H1, optParams.macdFast, optParams.macdSlow, optParams.macdSignal, PRICE_CLOSE);
   hADX_H1 = iADX(_Symbol, PERIOD_H1, optParams.adxPeriod);
   hRSI_H1 = iRSI(_Symbol, PERIOD_H1, optParams.rsiPeriod, PRICE_CLOSE);
   hStoch_H1 = iStochastic(_Symbol, PERIOD_H1, optParams.stochK, optParams.stochD, optParams.stochSlowing, MODE_SMA, STO_LOWHIGH);
   hCCI_H1 = iCCI(_Symbol, PERIOD_H1, optParams.cciPeriod, PRICE_CLOSE);
   hVol_H1 = iVolumes(_Symbol, PERIOD_H1, VOLUME_TICK);
   hOBV_H1 = iOBV(_Symbol, PERIOD_H1, VOLUME_TICK);
   hBB_H1 = iBands(_Symbol, PERIOD_H1, optParams.bbPeriod, 0, optParams.bbDeviation, PRICE_CLOSE);
   hATR_H1 = iATR(_Symbol, PERIOD_H1, optParams.atrPeriod);
   
   // H4
   hEMA50_H4 = iMA(_Symbol, PERIOD_H4, optParams.emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hEMA200_H4 = iMA(_Symbol, PERIOD_H4, optParams.emaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hMACD_H4 = iMACD(_Symbol, PERIOD_H4, optParams.macdFast, optParams.macdSlow, optParams.macdSignal, PRICE_CLOSE);
   hADX_H4 = iADX(_Symbol, PERIOD_H4, optParams.adxPeriod);
   hRSI_H4 = iRSI(_Symbol, PERIOD_H4, optParams.rsiPeriod, PRICE_CLOSE);
   hStoch_H4 = iStochastic(_Symbol, PERIOD_H4, optParams.stochK, optParams.stochD, optParams.stochSlowing, MODE_SMA, STO_LOWHIGH);
   hCCI_H4 = iCCI(_Symbol, PERIOD_H4, optParams.cciPeriod, PRICE_CLOSE);
   hVol_H4 = iVolumes(_Symbol, PERIOD_H4, VOLUME_TICK);
   hOBV_H4 = iOBV(_Symbol, PERIOD_H4, VOLUME_TICK);
   hBB_H4 = iBands(_Symbol, PERIOD_H4, optParams.bbPeriod, 0, optParams.bbDeviation, PRICE_CLOSE);
   hATR_H4 = iATR(_Symbol, PERIOD_H4, optParams.atrPeriod);
   
   // D1
   hEMA50_D1 = iMA(_Symbol, PERIOD_D1, optParams.emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hEMA200_D1 = iMA(_Symbol, PERIOD_D1, optParams.emaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hMACD_D1 = iMACD(_Symbol, PERIOD_D1, optParams.macdFast, optParams.macdSlow, optParams.macdSignal, PRICE_CLOSE);
   hADX_D1 = iADX(_Symbol, PERIOD_D1, optParams.adxPeriod);
   hRSI_D1 = iRSI(_Symbol, PERIOD_D1, optParams.rsiPeriod, PRICE_CLOSE);
   hStoch_D1 = iStochastic(_Symbol, PERIOD_D1, optParams.stochK, optParams.stochD, optParams.stochSlowing, MODE_SMA, STO_LOWHIGH);
   hCCI_D1 = iCCI(_Symbol, PERIOD_D1, optParams.cciPeriod, PRICE_CLOSE);
   hVol_D1 = iVolumes(_Symbol, PERIOD_D1, VOLUME_TICK);
   hOBV_D1 = iOBV(_Symbol, PERIOD_D1, VOLUME_TICK);
   hBB_D1 = iBands(_Symbol, PERIOD_D1, optParams.bbPeriod, 0, optParams.bbDeviation, PRICE_CLOSE);
   hATR_D1 = iATR(_Symbol, PERIOD_D1, optParams.atrPeriod);
   
   if(hEMA50_H1==INVALID_HANDLE || hRSI_H1==INVALID_HANDLE || hATR_H1==INVALID_HANDLE)
   {
      Print("❌ Ошибка создания индикаторов!");
      return(INIT_FAILED);
   }
   
   
   EventSetTimer(60);
   
   //=== ЗАГРУЗКА ДАННЫХ ИЗ ФАЙЛОВ ===
   Storage_LoadStats();
   Storage_InitLogs();
   Storage_LoadHistory();
   Storage_LoadActiveSignal();
   
   Print("✅ ", currentSymbol, " (", symbolType, ") PRO-аналитик запущен");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   isBacktestRunning = false;
   
   DeleteLevels();
   EventKillTimer();
}

void OnTimer() { Analyze(); }
void OnTick()
{
   Analyze();
   CheckSignalResult();
}

//+------------------------------------------------------------------+
//| Обработчик кликов                                                |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(UI_OnChartEvent(id, lparam, dparam, sparam)) return;
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == buttonName)
      {
         isCollapsed = !isCollapsed;
         ObjectSetInteger(0, buttonName, OBJPROP_STATE, false);
         UpdateCollapseButton();
         UpdatePanel();
         ChartRedraw();
      }
      else if(StringFind(sparam, panelName+"_Tab_") == 0)
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         string tabNumStr = StringSubstr(sparam, StringLen(panelName+"_Tab_"));
         int tabNum = (int)StringToInteger(tabNumStr);
         if(tabNum >= 0 && tabNum < TAB_COUNT)
         {
            currentTab = tabNum;
            UpdateTabs();
            UpdatePanel();
            ChartRedraw();
         }
      }
      else if(sparam == panelName+"_Prev")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         currentTab--;
         if(currentTab < 0) currentTab = TAB_COUNT - 1;
         UpdateTabs();
         UpdatePanel();
         ChartRedraw();
      }
      else if(sparam == panelName+"_Next")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         currentTab++;
         if(currentTab >= TAB_COUNT) currentTab = 0;
         UpdateTabs();
         UpdatePanel();
         ChartRedraw();
      }
      else if(sparam == panelName+"_Reset")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         if(MessageBox("Обнулить всю статистику?\n\nЭто действие нельзя отменить.", 
                       "Подтверждение сброса", MB_YESNO|MB_ICONQUESTION) == IDYES)
         {
            Storage_ResetStats();
            UpdatePanel();
            ChartRedraw();
         }
      }
      else if(StringFind(sparam, "_Backtest") >= 0)
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         if(isBacktestRunning)
         {
            Print("⏳ Бэктест уже запущен, подождите...");
            return;
         }
         isBacktestRunning = true;
         UpdatePanel();
         ChartRedraw();
         Sleep(100);
         RunBacktest();
         isBacktestRunning = false;
         UpdatePanel();
         ChartRedraw();
      }
   }
}

//+------------------------------------------------------------------+
//| Вспомогательные функции                                          |
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

string DetectSession()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.hour >= 0 && dt.hour < 8)   return "АЗИЯ 🌏";
   if(dt.hour >= 8 && dt.hour < 13)  return "ЕВРОПА 🇪🇺";
   if(dt.hour >= 13 && dt.hour < 21) return "АМЕРИКА 🇺🇸";
   return "ТИХИЙ ОКЕАН 🌊";
}

string DetectDayOfWeek()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   string days[] = {"ВС", "ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ"};
   return days[dt.day_of_week];
}

//+------------------------------------------------------------------+
//| ФИЛЬТРЫ                                                          |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   datetime from = TimeCurrent() - NewsMinutesBefore * 60;
   datetime to   = TimeCurrent() + NewsMinutesAfter * 60;
   MqlCalendarValue values[];
   if(CalendarValueHistory(values, from, to, "US") > 0)
   {
      for(int i = 0; i < ArraySize(values); i++)
      {
         MqlCalendarEvent event;
         if(CalendarEventById(values[i].event_id, event))
            if(event.importance == CALENDAR_IMPORTANCE_HIGH) return true;
      }
   }
   if(CalendarValueHistory(values, from, to, "EU") > 0)
   {
      for(int i = 0; i < ArraySize(values); i++)
      {
         MqlCalendarEvent event;
         if(CalendarEventById(values[i].event_id, event))
            if(event.importance == CALENDAR_IMPORTANCE_HIGH) return true;
      }
   }
   return false;
}

bool IsVolatilityOk()
{
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hATR_H1, 0, 0, 50, atr) < 50) return true;
   double avgATR = 0;
   for(int i = 0; i < 50; i++) avgATR += atr[i];
   avgATR /= 50;
   if(avgATR == 0) return true;
   double ratio = atr[0] / avgATR;
   if(ratio < VOLATILITY_RATIO_MIN || ratio > VOLATILITY_RATIO_MAX) return false;
   return true;
}

bool IsGoodSession()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.day_of_week == 0 || dt.day_of_week == 6) return false;
   if(dt.day_of_week == 5 && dt.hour >= SESSION_FRIDAY_CLOSE_HOUR) return false;
   if(dt.hour >= SESSION_DEAD_HOUR_START && dt.hour < SESSION_DEAD_HOUR_END) return false;
   return true;
}

void FindStructureLevels()
{
   nearestResistance = 0;
   nearestSupport = 0;
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   if(CopyHigh(_Symbol, PERIOD_H4, 0, STRUCTURE_LOOKBACK, high) < STRUCTURE_LOOKBACK) return;
   if(CopyLow(_Symbol, PERIOD_H4, 0, STRUCTURE_LOOKBACK, low) < STRUCTURE_LOOKBACK) return;
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minResDist = 999999, minSupDist = 999999;
   for(int i = STRUCTURE_PEAK_OFFSET; i < STRUCTURE_LOOKBACK - STRUCTURE_PEAK_OFFSET; i++)
   {
      if(high[i] > high[i-1] && high[i] > high[i-2] && high[i] > high[i+1] && high[i] > high[i+2])
      {
         if(high[i] > currentPrice)
         {
            double dist = high[i] - currentPrice;
            if(dist < minResDist) { minResDist = dist; nearestResistance = high[i]; }
         }
      }
      if(low[i] < low[i-1] && low[i] < low[i-2] && low[i] < low[i+1] && low[i] < low[i+2])
      {
         if(low[i] < currentPrice)
         {
            double dist = currentPrice - low[i];
            if(dist < minSupDist) { minSupDist = dist; nearestSupport = low[i]; }
         }
      }
   }
}

void SendPushNotification(string signal, double entry, double sl, double tp)
{
   string pushMsg = currentSymbol + " " + signal + "\n" +
                    "📍 Вход: " + DoubleToString(entry, symbolDigits) + "\n" +
                    "🛑 SL: " + DoubleToString(sl, symbolDigits) + "\n" +
                    "🎯 TP: " + DoubleToString(tp, symbolDigits) + "\n" +
                    "📊 Точность: " + DoubleToString(GetAccuracy(), 1) + "%";
   SendNotification(pushMsg);
}

double GetAccuracy()
{
   int totalDecided = winningSignals + losingSignals;
   if(totalDecided == 0) return 0;
   return winningSignals * 100.0 / totalDecided;
}

//+------------------------------------------------------------------+
//| ПРОВЕРКА ВХОДА С ФИЛЬТРАМИ                                       |
//+------------------------------------------------------------------+
string CheckEntryForTF(ENUM_TIMEFRAMES tf, IndicatorVotes &resultMain, int hRSI, string modeName)
{
   if(resultMain.weightedSum < SIGNAL_THRESHOLD_MIN && resultMain.weightedSum > -SIGNAL_THRESHOLD_MIN) return "";
   
   if(FilterRSI)
   {
      double rsi[];
      ArraySetAsSeries(rsi, true);
      if(CopyBuffer(hRSI, 0, 0, 3, rsi) < 3) return "";
      if(resultMain.weightedSum > 0 && rsi[1] > RSI_FILTER_BUY_MAX) return "";
      if(resultMain.weightedSum < 0 && rsi[1] < RSI_FILTER_SELL_MIN) return "";
   }
   
   if(FilterCandle)
   {
      double open[], close[];
      ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
      if(CopyOpen(_Symbol, tf, 0, 3, open) < 3) return "";
      if(CopyClose(_Symbol, tf, 0, 3, close) < 3) return "";
      bool candleOk = false;
      if(resultMain.weightedSum > 0 && close[1] > open[1]) candleOk = true;
      if(resultMain.weightedSum < 0 && close[1] < open[1]) candleOk = true;
      if(!candleOk) return "";
   }
   
   if(FilterLag)
   {
      double ema50[];
      ArraySetAsSeries(ema50, true);
      int hEMA50 = 0;
      if(tf == PERIOD_H1) hEMA50 = hEMA50_H1;
      else if(tf == PERIOD_H4) hEMA50 = hEMA50_H4;
      else if(tf == PERIOD_D1) hEMA50 = hEMA50_D1;
      if(hEMA50 != 0 && CopyBuffer(hEMA50, 0, 0, 2, ema50) >= 2)
      {
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double atr = resultMain.atrValue;
         if(resultMain.weightedSum > 0 && (currentPrice - ema50[0]) > atr * LAG_FILTER_ATR_MULTIPLIER) return "";
         if(resultMain.weightedSum < 0 && (ema50[0] - currentPrice) > atr * LAG_FILTER_ATR_MULTIPLIER) return "";
      }
   }
   
   if(FilterStructure)
   {
      if(nearestResistance > 0 && nearestSupport > 0)
      {
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double roomUp = nearestResistance - currentPrice;
         double roomDown = currentPrice - nearestSupport;
         if(resultMain.weightedSum > 0 && roomUp < resultMain.atrValue * STRUCTURE_ROOM_ATR) return "";
         if(resultMain.weightedSum < 0 && roomDown < resultMain.atrValue * STRUCTURE_ROOM_ATR) return "";
      }
   }
   
   if(resultMain.weightedSum > 0) return "CONFIRMED BUY 🟢 [" + modeName + "]";
   else return "CONFIRMED SELL 🔴 [" + modeName + "]";
}

string CheckEntryConfirmation()
{
   if(FilterNews) { if(IsNewsTime()) { filterNews = false; return ""; } filterNews = true; }
   else filterNews = true;
   
   if(FilterVolatility) { if(!IsVolatilityOk()) { filterVolatility = false; return ""; } filterVolatility = true; }
   else filterVolatility = true;
   
   if(FilterSession) { if(!IsGoodSession()) { filterSession = false; return ""; } filterSession = true; }
   else filterSession = true;
   
   filterCandle = FilterCandle;
   filterRSI = FilterRSI;
   filterStructure = FilterStructure;
   
   string signal = "";
   if(UseSignalH1) { signal = CheckEntryForTF(PERIOD_H1, resultH1, hRSI_H1, "H1"); if(signal != "") return signal; }
   if(UseSignalH4) { signal = CheckEntryForTF(PERIOD_H4, resultH4, hRSI_H4, "H4"); if(signal != "") return signal; }
   if(UseSignalD1) { signal = CheckEntryForTF(PERIOD_D1, resultD1, hRSI_D1, "D1"); if(signal != "") return signal; }
   return "";
}

//+------------------------------------------------------------------+
//| РАСЧЕТ УРОВНЕЙ                                                   |
//+------------------------------------------------------------------+
void CalculateLevelsForMode(string mode, IndicatorVotes &result, 
                            int hEMA50, int hBB, int hRSI,
                            double &outEntry, double &outSL, double &outTP, string &outType)
{
   outEntry = 0; outSL = 0; outTP = 0; outType = "";
   if(result.atrValue <= 0) return;
   
   ENUM_TIMEFRAMES tf = PERIOD_H1;
   if(mode == "H4") tf = PERIOD_H4;
   if(mode == "D1") tf = PERIOD_D1;
   
   string signal = CheckEntryForTF(tf, result, hRSI, mode);
   if(signal == "") return;
   
   double ema50[], bbMiddle[];
   ArraySetAsSeries(ema50, true); ArraySetAsSeries(bbMiddle, true);
   if(CopyBuffer(hEMA50, 0, 0, 3, ema50) < 3) return;
   if(CopyBuffer(hBB, 0, 0, 3, bbMiddle) < 3) return;
   
   double rsi[];
   ArraySetAsSeries(rsi, true);
   if(CopyBuffer(hRSI, 0, 0, 3, rsi) < 3) return;
   
   double slDistance = result.atrValue * ATR_SL_Mult;
   
   if(StringFind(signal, "BUY") >= 0)
   {
      if(rsi[1] < RSI_CORRECTION_BUY_MAX)
      {
         outType = "BUY LIMIT";
         outEntry = MathMax(ema50[1], bbMiddle[1]);
      }
      else
      {
         outType = "BUY STOP";
         double high[];
         ArraySetAsSeries(high, true);
         if(CopyHigh(_Symbol, tf, 0, 3, high) < 3) return;
         outEntry = high[1] + result.atrValue * 0.1;
      }
      outSL = outEntry - slDistance;
      double tpMult = (tf == PERIOD_H1) ? TP_MULT_H1_BASE + (result.candlesForecast * TP_MULT_H1_STEP) :
                      (tf == PERIOD_H4) ? TP_MULT_H4_BASE + (result.candlesForecast * TP_MULT_H4_STEP) :
                                          TP_MULT_D1_BASE + (result.candlesForecast * TP_MULT_D1_STEP);
      outTP = outEntry + (slDistance * tpMult);
      if(MathAbs(outTP - outEntry) / slDistance < RR_RATIO_MIN) { outEntry = 0; return; }
   }
   else
   {
      if(rsi[1] > RSI_CORRECTION_SELL_MIN)
      {
         outType = "SELL LIMIT";
         outEntry = MathMin(ema50[1], bbMiddle[1]);
      }
      else
      {
         outType = "SELL STOP";
         double low[];
         ArraySetAsSeries(low, true);
         if(CopyLow(_Symbol, tf, 0, 3, low) < 3) return;
         outEntry = low[1] - result.atrValue * 0.1;
      }
      outSL = outEntry + slDistance;
      double tpMult = (tf == PERIOD_H1) ? TP_MULT_H1_BASE + (result.candlesForecast * TP_MULT_H1_STEP) :
                      (tf == PERIOD_H4) ? TP_MULT_H4_BASE + (result.candlesForecast * TP_MULT_H4_STEP) :
                                          TP_MULT_D1_BASE + (result.candlesForecast * TP_MULT_D1_STEP);
      outTP = outEntry - (slDistance * tpMult);
      if(MathAbs(outEntry - outTP) / slDistance < RR_RATIO_MIN) { outEntry = 0; return; }
   }
   
   bool levelsOk = (StringFind(signal, "BUY") >= 0) ? (outSL < outEntry && outTP > outEntry) : (outSL > outEntry && outTP < outEntry);
   if(!levelsOk) { outEntry = 0; outSL = 0; outTP = 0; outType = ""; return; }
   
   outEntry = NormalizeDouble(outEntry, symbolDigits);
   outSL = NormalizeDouble(outSL, symbolDigits);
   outTP = NormalizeDouble(outTP, symbolDigits);
}

void CalculateRecommendedLevels()
{
   recEntryH1 = 0; recSLH1 = 0; recTPH1 = 0; recOrderTypeH1 = "";
   recEntryH4 = 0; recSLH4 = 0; recTPH4 = 0; recOrderTypeH4 = "";
   recEntryD1 = 0; recSLD1 = 0; recTPD1 = 0; recOrderTypeD1 = "";
   
   if(UseSignalH1) CalculateLevelsForMode("H1", resultH1, hEMA50_H1, hBB_H1, hRSI_H1, recEntryH1, recSLH1, recTPH1, recOrderTypeH1);
   if(UseSignalH4) CalculateLevelsForMode("H4", resultH4, hEMA50_H4, hBB_H4, hRSI_H4, recEntryH4, recSLH4, recTPH4, recOrderTypeH4);
   if(UseSignalD1) CalculateLevelsForMode("D1", resultD1, hEMA50_D1, hBB_D1, hRSI_D1, recEntryD1, recSLD1, recTPD1, recOrderTypeD1);
   
   activeMode = "";
   recEntry = 0; recSL = 0; recTP = 0; recOrderType = "";
   if(recEntryD1 > 0) { activeMode = "D1"; recEntry = recEntryD1; recSL = recSLD1; recTP = recTPD1; recOrderType = recOrderTypeD1; }
   else if(recEntryH4 > 0) { activeMode = "H4"; recEntry = recEntryH4; recSL = recSLH4; recTP = recTPH4; recOrderType = recOrderTypeH4; }
   else if(recEntryH1 > 0) { activeMode = "H1"; recEntry = recEntryH1; recSL = recSLH1; recTP = recTPH1; recOrderType = recOrderTypeH1; }
}

//+------------------------------------------------------------------+
//| ОСНОВНОЙ АНАЛИЗ                                                  |
//+------------------------------------------------------------------+
void Analyze()
{
   currentSession = DetectSession();
   symbolSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   
   //=== ПРОВЕРКА НОВЫХ СВЕЧЕЙ ===
   datetime currentBarTimeH1 = iTime(_Symbol, PERIOD_H1, 0);
   datetime currentBarTimeH4 = iTime(_Symbol, PERIOD_H4, 0);
   datetime currentBarTimeD1 = iTime(_Symbol, PERIOD_D1, 0);
   bool newBarH1 = (currentBarTimeH1 != lastBarTimeH1);
   bool newBarH4 = (currentBarTimeH4 != lastBarTimeH4);
   bool newBarD1 = (currentBarTimeD1 != lastBarTimeD1);
   if(newBarH1) lastBarTimeH1 = currentBarTimeH1;
   if(newBarH4) lastBarTimeH4 = currentBarTimeH4;
   if(newBarD1) lastBarTimeD1 = currentBarTimeD1;
   
   //=== АНАЛИЗ ТАЙМФРЕЙМОВ через ЕДИНУЮ функцию AnalyzeSignal ===
   resultH1 = AnalyzeSignal(PERIOD_H1, 0, hEMA50_H1, hEMA200_H1, hMACD_H1, hADX_H1, hRSI_H1,
                            hStoch_H1, hCCI_H1, hVol_H1, hOBV_H1, hBB_H1, hATR_H1, optParams);
   resultH4 = AnalyzeSignal(PERIOD_H4, 0, hEMA50_H4, hEMA200_H4, hMACD_H4, hADX_H4, hRSI_H4,
                            hStoch_H4, hCCI_H4, hVol_H4, hOBV_H4, hBB_H4, hATR_H4, optParams);
   resultD1 = AnalyzeSignal(PERIOD_D1, 0, hEMA50_D1, hEMA200_D1, hMACD_D1, hADX_D1, hRSI_D1,
                            hStoch_D1, hCCI_D1, hVol_D1, hOBV_D1, hBB_D1, hATR_D1, optParams);
   
   FindStructureLevels();
   
   //=== РАСЧЁТ УРОВНЕЙ ТОЛЬКО ПРИ НОВОЙ СВЕЧЕ ===
   if(newBarH1 && UseSignalH1)
   {
      signalFixedH1 = false;
      CalculateLevelsForMode("H1", resultH1, hEMA50_H1, hBB_H1, hRSI_H1, recEntryH1, recSLH1, recTPH1, recOrderTypeH1);
      if(recEntryH1 > 0) signalFixedH1 = true;
   }
   if(newBarH4 && UseSignalH4)
   {
      signalFixedH4 = false;
      CalculateLevelsForMode("H4", resultH4, hEMA50_H4, hBB_H4, hRSI_H4, recEntryH4, recSLH4, recTPH4, recOrderTypeH4);
      if(recEntryH4 > 0) signalFixedH4 = true;
   }
   if(newBarD1 && UseSignalD1)
   {
      signalFixedD1 = false;
      CalculateLevelsForMode("D1", resultD1, hEMA50_D1, hBB_D1, hRSI_D1, recEntryD1, recSLD1, recTPD1, recOrderTypeD1);
      if(recEntryD1 > 0) signalFixedD1 = true;
   }
   
   CalculateRecommendedLevels();
   UpdatePanel();
   
   //=== ПРОВЕРКА ИСПОЛНЕНИЯ АКТИВНОГО СИГНАЛА ===
   if(lastEntryPrice > 0 && !signalWasExecuted && !signalChecked)
   {
      double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(lastDirection == "BUY" && currentAsk >= lastEntryPrice)
      {
         signalWasExecuted = true;
         Print("✅ Сигнал ", activeMode, " ИСПОЛНЕН по цене ", DoubleToString(currentAsk, symbolDigits));
      }
      else if(lastDirection == "SELL" && currentBid <= lastEntryPrice)
      {
         signalWasExecuted = true;
         Print("✅ Сигнал ", activeMode, " ИСПОЛНЕН по цене ", DoubleToString(currentBid, symbolDigits));
      }
   }
   
   //=== СОЗДАНИЕ НОВЫХ СИГНАЛОВ ТОЛЬКО ПРИ НОВОЙ СВЕЧЕ ===
   if(UseSignalH1 && newBarH1 && (lastEntryPrice == 0 || signalChecked))
   {
      string sigH1 = CheckEntryForTF(PERIOD_H1, resultH1, hRSI_H1, "H1");
      if(sigH1 != "" && sigH1 != lastSignalH1)
      {
         lastSignalH1 = sigH1;
         lastSignalStrengthH1 = resultH1.weightedSum;
         totalSignals++;
         lastEntryPrice = recEntryH1;
         lastDirection = (StringFind(sigH1, "BUY") >= 0) ? "BUY" : "SELL";
         lastSignalCheckTime = TimeCurrent();
         signalChecked = false;
         signalWasExecuted = false;
         activeMode = "H1";
         int lifetimeH1 = CalculateSignalLifetime("H1", resultH1.weightedSum, resultH1.candlesForecast);
         signalExpirationTime = TimeCurrent() + lifetimeH1 * 60;
         if(UseSoundAlert) PlaySound("alert.wav");
         if(UsePushNotify) SendPushNotification(sigH1, recEntryH1, recSLH1, recTPH1);
         Print("🔔 СИГНАЛ H1: ", sigH1);
         Storage_AddToHistory("H1", lastDirection, recEntryH1, recSLH1, recTPH1, resultH1.weightedSum);
         Storage_LogSignal("H1", lastDirection, recEntryH1, recSLH1, recTPH1, resultH1.weightedSum, resultH1.atrValue);
      }
   }
   
   if(UseSignalH4 && newBarH4 && (lastEntryPrice == 0 || signalChecked))
   {
      string sigH4 = CheckEntryForTF(PERIOD_H4, resultH4, hRSI_H4, "H4");
      if(sigH4 != "" && sigH4 != lastSignalH4)
      {
         lastSignalH4 = sigH4;
         lastSignalStrengthH4 = resultH4.weightedSum;
         totalSignals++;
         lastEntryPrice = recEntryH4;
         lastDirection = (StringFind(sigH4, "BUY") >= 0) ? "BUY" : "SELL";
         lastSignalCheckTime = TimeCurrent();
         signalChecked = false;
         signalWasExecuted = false;
         activeMode = "H4";
         int lifetimeH4 = CalculateSignalLifetime("H4", resultH4.weightedSum, resultH4.candlesForecast);
         signalExpirationTime = TimeCurrent() + lifetimeH4 * 60;
         if(UseSoundAlert) PlaySound("alert2.wav");
         if(UsePushNotify) SendPushNotification(sigH4, recEntryH4, recSLH4, recTPH4);
         Print("🔔 СИГНАЛ H4: ", sigH4);
         Storage_AddToHistory("H4", lastDirection, recEntryH4, recSLH4, recTPH4, resultH4.weightedSum);
         Storage_LogSignal("H4", lastDirection, recEntryH4, recSLH4, recTPH4, resultH4.weightedSum, resultH4.atrValue);
      }
   }
   
   if(UseSignalD1 && newBarD1 && (lastEntryPrice == 0 || signalChecked))
   {
      string sigD1 = CheckEntryForTF(PERIOD_D1, resultD1, hRSI_D1, "D1");
      if(sigD1 != "" && sigD1 != lastSignalD1)
      {
         lastSignalD1 = sigD1;
         lastSignalStrengthD1 = resultD1.weightedSum;
         totalSignals++;
         lastEntryPrice = recEntryD1;
         lastDirection = (StringFind(sigD1, "BUY") >= 0) ? "BUY" : "SELL";
         lastSignalCheckTime = TimeCurrent();
         signalChecked = false;
         signalWasExecuted = false;
         activeMode = "D1";
         int lifetimeD1 = CalculateSignalLifetime("D1", resultD1.weightedSum, resultD1.candlesForecast);
         signalExpirationTime = TimeCurrent() + lifetimeD1 * 60;
         if(UseSoundAlert) PlaySound("ok.wav");
         if(UsePushNotify) SendPushNotification(sigD1, recEntryD1, recSLD1, recTPD1);
         Print("🔔 СИГНАЛ D1: ", sigD1);
         Storage_AddToHistory("D1", lastDirection, recEntryD1, recSLD1, recTPD1, resultD1.weightedSum);
         Storage_LogSignal("D1", lastDirection, recEntryD1, recSLD1, recTPD1, resultD1.weightedSum, resultD1.atrValue);
      }
   }
   
   if(DrawLevels) DrawLevelsOnChart();
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Проверка результата сигнала                                      |
//+------------------------------------------------------------------+
void CheckSignalResult()
{
   if(lastEntryPrice == 0 || signalChecked) return;
   if(recSL == 0 || recTP == 0) return;
   
   if(TimeCurrent() > signalExpirationTime && !signalWasExecuted)
   {
      canceledSignals++;
      totalSignals--;
      Print("⏰ Сигнал ИСТЁК. Аннулирован.");
      lastEntryPrice = 0;
      signalChecked = false;
      signalWasExecuted = false;
      if(activeMode == "H1") { lastSignalH1 = ""; signalFixedH1 = false; }
      else if(activeMode == "H4") { lastSignalH4 = ""; signalFixedH4 = false; }
      else if(activeMode == "D1") { lastSignalD1 = ""; signalFixedD1 = false; }
      Storage_RemoveSignalFromLog(lastSignalCheckTime, activeMode, lastDirection);
      activeMode = "";
      return;
   }
   
   if(!signalWasExecuted) return;
   
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   if(CopyHigh(_Symbol, PERIOD_H1, 0, EXECUTION_CHECK_CANDLES, high) < EXECUTION_CHECK_CANDLES) return;
   if(CopyLow(_Symbol, PERIOD_H1, 0, EXECUTION_CHECK_CANDLES, low) < EXECUTION_CHECK_CANDLES) return;
   
   double maxHigh = high[0], minLow = low[0];
   for(int i = 1; i < EXECUTION_CHECK_CANDLES; i++)
   {
      if(high[i] > maxHigh) maxHigh = high[i];
      if(low[i] < minLow) minLow = low[i];
   }
   
   string result = "";
   double movement = 0, exitPrice = 0;
   
   if(lastDirection == "BUY")
   {
      if(minLow <= recSL) { result = "LOSS"; exitPrice = recSL; movement = recSL - lastEntryPrice; }
      else if(maxHigh >= recTP) { result = "WIN"; exitPrice = recTP; movement = recTP - lastEntryPrice; }
   }
   else
   {
      if(maxHigh >= recSL) { result = "LOSS"; exitPrice = recSL; movement = lastEntryPrice - recSL; }
      else if(minLow <= recTP) { result = "WIN"; exitPrice = recTP; movement = lastEntryPrice - recTP; }
   }
   
   if(result != "")
   {
      if(result == "WIN") { winningSignals++; Print("✅ СИГНАЛ ВЕРНЫЙ!"); }
      else { losingSignals++; Print("❌ СИГНАЛ НЕВЕРНЫЙ!"); }
      
      signalChecked = true;
      Storage_LogResult(activeMode, lastDirection, lastEntryPrice, exitPrice, result, movement);
      Storage_UpdateHistoryResult(result, movement);
      Storage_SaveStats();
      Storage_RemoveSignalFromLog(lastSignalCheckTime, activeMode, lastDirection);
      
      lastEntryPrice = 0;
      signalWasExecuted = false;
      if(activeMode == "H1") { lastSignalH1 = ""; signalFixedH1 = false; }
      else if(activeMode == "H4") { lastSignalH4 = ""; signalFixedH4 = false; }
      else if(activeMode == "D1") { lastSignalD1 = ""; signalFixedD1 = false; }
      activeMode = "";
   }
}

//+------------------------------------------------------------------+
//| РАСЧЁТ СРОКА ЖИЗНИЯ                                              |
//+------------------------------------------------------------------+
int CalculateSignalLifetime(string mode, double weightedSum, int candlesForecast)
{
   int baseMinutes = (mode == "H1") ? LIFETIME_BASE_H1 : (mode == "H4") ? LIFETIME_BASE_H4 : LIFETIME_BASE_D1;
   double absSum = MathAbs(weightedSum);
   double multiplier = (absSum >= SIGNAL_VERY_STRONG) ? LIFETIME_MULT_VERY_STRONG :
                       (absSum >= SIGNAL_STRONG) ? LIFETIME_MULT_STRONG :
                       (absSum >= SIGNAL_ABOVE_AVG) ? LIFETIME_MULT_ABOVE_AVG :
                       (absSum >= SIGNAL_AVG) ? LIFETIME_MULT_AVG : LIFETIME_MULT_WEAK;
   double forecastMult = MathMax(FORECAST_MULT_MIN, MathMin(FORECAST_MULT_MAX, FORECAST_MULT_BASE + candlesForecast * FORECAST_MULT_STEP));
   int lifetime = (int)(baseMinutes * multiplier * forecastMult);
   
   int minL = (mode == "H1") ? LIFETIME_MIN_H1 : (mode == "H4") ? LIFETIME_MIN_H4 : LIFETIME_MIN_D1;
   int maxL = (mode == "H1") ? LIFETIME_MAX_H1 : (mode == "H4") ? LIFETIME_MAX_H4 : LIFETIME_MAX_D1;
   return MathMax(minL, MathMin(maxL, lifetime));
}

int CalculateSignalLifetimeForBacktest(ENUM_TIMEFRAMES tf, double weightedSum, int candlesForecast)
{
   string mode = (tf == PERIOD_H1) ? "H1" : (tf == PERIOD_H4) ? "H4" : "D1";
   return CalculateSignalLifetime(mode, weightedSum, candlesForecast);
}

//+------------------------------------------------------------------+
//| Отрисовка уровней                                                |
//+------------------------------------------------------------------+
void DrawLevelsOnChart()
{
   DeleteLevels();
   if(UseSignalH1 && recEntryH1 > 0)
   {
      DrawHLine("EntryLine_H1", recEntryH1, COLOR_H1_ENTRY, LINE_WIDTH_ENTRY, STYLE_SOLID, "🟢 H1 ВХОД: " + recOrderTypeH1);
      DrawHLine("SLLine_H1", recSLH1, COLOR_H1_LEVELS, LINE_WIDTH_SL_TP, STYLE_DASH, "🟢 H1 SL");
      DrawHLine("TPLine_H1", recTPH1, COLOR_H1_LEVELS, LINE_WIDTH_SL_TP, STYLE_DASH, "🟢 H1 TP");
   }
   if(UseSignalH4 && recEntryH4 > 0)
   {
      DrawHLine("EntryLine_H4", recEntryH4, COLOR_H4_ENTRY, LINE_WIDTH_ENTRY, STYLE_SOLID, "🟡 H4 ВХОД: " + recOrderTypeH4);
      DrawHLine("SLLine_H4", recSLH4, COLOR_H4_LEVELS, LINE_WIDTH_SL_TP, STYLE_DASH, "🟡 H4 SL");
      DrawHLine("TPLine_H4", recTPH4, COLOR_H4_LEVELS, LINE_WIDTH_SL_TP, STYLE_DASH, "🟡 H4 TP");
   }
   if(UseSignalD1 && recEntryD1 > 0)
   {
      DrawHLine("EntryLine_D1", recEntryD1, COLOR_D1_ENTRY, LINE_WIDTH_ENTRY, STYLE_SOLID, "🔴 D1 ВХОД: " + recOrderTypeD1);
      DrawHLine("SLLine_D1", recSLD1, COLOR_D1_LEVELS, LINE_WIDTH_SL_TP, STYLE_DASH, "🔴 D1 SL");
      DrawHLine("TPLine_D1", recTPD1, COLOR_D1_LEVELS, LINE_WIDTH_SL_TP, STYLE_DASH, "🔴 D1 TP");
   }
   if(nearestResistance > 0) DrawHLine("ResistLine", nearestResistance, COLOR_STRUCTURE, LINE_WIDTH_STRUCTURE, STYLE_DOT, "🧱 Сопротивление");
   if(nearestSupport > 0) DrawHLine("SupportLine", nearestSupport, COLOR_STRUCTURE, LINE_WIDTH_STRUCTURE, STYLE_DOT, "🧱 Поддержка");
}

void DrawHLine(string name, double price, color clr, int width, ENUM_LINE_STYLE style, string tip)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
   }
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tip + " @ " + DoubleToString(price, symbolDigits));
}

void DeleteLevels()
{
   ObjectDelete(0, "EntryLine_H1"); ObjectDelete(0, "SLLine_H1"); ObjectDelete(0, "TPLine_H1");
   ObjectDelete(0, "EntryLine_H4"); ObjectDelete(0, "SLLine_H4"); ObjectDelete(0, "TPLine_H4");
   ObjectDelete(0, "EntryLine_D1"); ObjectDelete(0, "SLLine_D1"); ObjectDelete(0, "TPLine_D1");
   ObjectDelete(0, "ResistLine"); ObjectDelete(0, "SupportLine");
}

//+------------------------------------------------------------------+
//| БЭКТЕСТ (использует ту же функцию AnalyzeSignal)                 |
//+------------------------------------------------------------------+
void RunBacktest()
{
   Print("🚀 ФУНКЦИЯ RunBacktest ЗАПУЩЕНА!");
   Print("🧪 ЗАПУСК УМНОГО МУЛЬТИ-ТФ БЭКТЕСТА С ОПТИМИЗАЦИЕЙ");
   
   int availableBars = iBars(_Symbol, PERIOD_H1);
   if(availableBars < BACKTEST_BARS_MIN)
   {
      Print("❌ Недостаточно истории!");
      isBacktestRunning = false;
      return;
   }
   
   int actualBars = MathMin(backtestBars, availableBars - 20);
   Print("📊 Будет проверено баров H1: ", actualBars);
   
   double testThresholds[] = {
      MathMax(1.0, optParams.signalThreshold - 2.0),
      MathMax(1.0, optParams.signalThreshold - 1.0),
      optParams.signalThreshold,
      optParams.signalThreshold + 1.0,
      optParams.signalThreshold + 2.0
   };
   double testATRMultipliers[] = {
      MathMax(0.5, optParams.atrSLMult - 0.5),
      optParams.atrSLMult,
      optParams.atrSLMult + 0.5,
      optParams.atrSLMult + 1.0
   };
   int testEMAPeriods[] = {
      (int)MathMax(10, optParams.emaFastPeriod - 20),
      optParams.emaFastPeriod,
      optParams.emaFastPeriod + 20,
      optParams.emaFastPeriod + 40
   };
   int testRSIPeriods[] = {
      (int)MathMax(5, optParams.rsiPeriod - 4),
      optParams.rsiPeriod,
      optParams.rsiPeriod + 4,
      optParams.rsiPeriod + 8
   };
   
   double bestAccuracy = 0.0;
   IndicatorParams bestParams;
   int bestTotalTrades = 0, bestWins = 0;
   int bestTotalH1 = 0, bestWinsH1 = 0, bestLossesH1 = 0;
   int bestTotalH4 = 0, bestWinsH4 = 0, bestLossesH4 = 0;
   int bestTotalD1 = 0, bestWinsD1 = 0, bestLossesD1 = 0;
   
   int totalCombinations = ArraySize(testThresholds) * ArraySize(testATRMultipliers) * 
                           ArraySize(testEMAPeriods) * ArraySize(testRSIPeriods);
   int currentCombination = 0;
   Print("🔄 Начало оптимизации: ", totalCombinations, " комбинаций...");
   
   for(int t = 0; t < ArraySize(testThresholds); t++)
   for(int a = 0; a < ArraySize(testATRMultipliers); a++)
   for(int e = 0; e < ArraySize(testEMAPeriods); e++)
   for(int r = 0; r < ArraySize(testRSIPeriods); r++)
   {
      currentCombination++;
      if(currentCombination % 10 == 0) Print("⏳ Оптимизация: ", currentCombination, " из ", totalCombinations);
      
      IndicatorParams testParams = optParams;
      testParams.signalThreshold = testThresholds[t];
      testParams.atrSLMult = testATRMultipliers[a];
      testParams.emaFastPeriod = testEMAPeriods[e];
      testParams.rsiPeriod = testRSIPeriods[r];
      
      int totalH1 = 0, winsH1 = 0, lossesH1 = 0, canceledH1 = 0;
      int totalH4 = 0, winsH4 = 0, lossesH4 = 0, canceledH4 = 0;
      int totalD1 = 0, winsD1 = 0, lossesD1 = 0, canceledD1 = 0;
      int lastCheckedH4 = -1, lastCheckedD1 = -1;
      
      for(int shift = actualBars; shift >= 5; shift--)
      {
         if(shift % BACKTEST_STEP_DEFAULT != 0) continue;
         datetime barTime = iTime(_Symbol, PERIOD_H1, shift);
         MqlDateTime dt;
         TimeToStruct(barTime, dt);
         if(dt.hour >= SESSION_DEAD_HOUR_START && dt.hour < SESSION_DEAD_HOUR_END) continue;
         if(dt.day_of_week == 0 || dt.day_of_week == 6) continue;
         if(dt.day_of_week == 5 && dt.hour >= SESSION_FRIDAY_CLOSE_HOUR) continue;
         
         if(UseSignalH1)
         {
            IndicatorVotes sig = AnalyzeSignal(PERIOD_H1, shift, hEMA50_H1, hEMA200_H1, hMACD_H1, hADX_H1, hRSI_H1,
                                               hStoch_H1, hCCI_H1, hVol_H1, hOBV_H1, hBB_H1, hATR_H1, testParams);
            if(MathAbs(sig.weightedSum) >= testParams.signalThreshold && CheckCandleAndRSI(shift, PERIOD_H1, sig.weightedSum, testParams))
               SimulateTradeWithFile(shift, PERIOD_H1, sig.weightedSum, testParams.atrSLMult, totalH1, winsH1, lossesH1, canceledH1, testParams, barTime, sig.candlesForecast);
         }
         if(UseSignalH4)
         {
            int currentH4 = iBarShift(_Symbol, PERIOD_H4, barTime);
            if(currentH4 != lastCheckedH4 && currentH4 >= 2 && currentH4 < iBars(_Symbol, PERIOD_H4) - 3)
            {
               IndicatorVotes sig = AnalyzeSignal(PERIOD_H4, currentH4, hEMA50_H4, hEMA200_H4, hMACD_H4, hADX_H4, hRSI_H4,
                                                  hStoch_H4, hCCI_H4, hVol_H4, hOBV_H4, hBB_H4, hATR_H4, testParams);
               if(MathAbs(sig.weightedSum) >= testParams.signalThreshold && CheckCandleAndRSI(currentH4, PERIOD_H4, sig.weightedSum, testParams))
                  SimulateTradeWithFile(currentH4, PERIOD_H4, sig.weightedSum, testParams.atrSLMult, totalH4, winsH4, lossesH4, canceledH4, testParams, barTime, sig.candlesForecast);
               lastCheckedH4 = currentH4;
            }
         }
         if(UseSignalD1)
         {
            int currentD1 = iBarShift(_Symbol, PERIOD_D1, barTime);
            if(currentD1 != lastCheckedD1 && currentD1 >= 2 && currentD1 < iBars(_Symbol, PERIOD_D1) - 3)
            {
               IndicatorVotes sig = AnalyzeSignal(PERIOD_D1, currentD1, hEMA50_D1, hEMA200_D1, hMACD_D1, hADX_D1, hRSI_D1,
                                                  hStoch_D1, hCCI_D1, hVol_D1, hOBV_D1, hBB_D1, hATR_D1, testParams);
               if(MathAbs(sig.weightedSum) >= testParams.signalThreshold && CheckCandleAndRSI(currentD1, PERIOD_D1, sig.weightedSum, testParams))
                  SimulateTradeWithFile(currentD1, PERIOD_D1, sig.weightedSum, testParams.atrSLMult, totalD1, winsD1, lossesD1, canceledD1, testParams, barTime, sig.candlesForecast);
               lastCheckedD1 = currentD1;
            }
         }
      }
      
      int realTotal = winsH1 + lossesH1 + winsH4 + lossesH4 + winsD1 + lossesD1;
      int wins = winsH1 + winsH4 + winsD1;
      int totalTests = totalH1 + totalH4 + totalD1;
      
      if(realTotal >= BACKTEST_MIN_REAL_SIGNALS)
      {
         double accuracy = wins * 100.0 / realTotal;
         if(accuracy > bestAccuracy || (accuracy == bestAccuracy && totalTests > bestTotalTrades))
         {
            bestAccuracy = accuracy;
            bestParams = testParams;
            bestTotalTrades = totalTests;
            bestWins = wins;
            bestTotalH1 = totalH1; bestWinsH1 = winsH1; bestLossesH1 = lossesH1;
            bestTotalH4 = totalH4; bestWinsH4 = winsH4; bestLossesH4 = lossesH4;
            bestTotalD1 = totalD1; bestWinsD1 = winsD1; bestLossesD1 = lossesD1;
         }
      }
   }
   
   Print("🏁 АВТО-ОПТИМИЗАЦИЯ ЗАВЕРШЕНА");
   Print("🏆 ЛУЧШАЯ КОНФИГУРАЦИЯ:");
   Print("   ▶ Порог: ", DoubleToString(bestParams.signalThreshold, 1));
   Print("   ▶ ATR SL: ", DoubleToString(bestParams.atrSLMult, 1));
   Print("   ▶ EMA: ", bestParams.emaFastPeriod);
   Print("   ▶ RSI: ", bestParams.rsiPeriod);
   Print("   ▶ Точность: ", DoubleToString(bestAccuracy, 1), "%");
   Print("   ▶ Сигналов: ", bestTotalTrades, " (WIN: ", bestWins, " | LOSS: ", bestTotalTrades - bestWins, ")");
   
   if(bestTotalH1 > 0) { int r = bestWinsH1 + bestLossesH1; Print("   H1: ", DoubleToString(bestWinsH1 * 100.0 / r, 1), "%"); }
   if(bestTotalH4 > 0) { int r = bestWinsH4 + bestLossesH4; Print("   H4: ", DoubleToString(bestWinsH4 * 100.0 / r, 1), "%"); }
   if(bestTotalD1 > 0) { int r = bestWinsD1 + bestLossesD1; Print("   D1: ", DoubleToString(bestWinsD1 * 100.0 / r, 1), "%"); }
}

bool CheckCandleAndRSI(int shift, ENUM_TIMEFRAMES tf, double wSum, IndicatorParams &params)
{
   double close[], open[], rsi[];
   ArraySetAsSeries(close, true); ArraySetAsSeries(open, true); ArraySetAsSeries(rsi, true);
   if(CopyClose(_Symbol, tf, shift, 3, close) < 3) return false;
   if(CopyOpen(_Symbol, tf, shift, 3, open) < 3) return false;
   int hRSI = iRSI(_Symbol, tf, params.rsiPeriod, PRICE_CLOSE);
   if(hRSI == INVALID_HANDLE) return false;
   if(CopyBuffer(hRSI, 0, shift, 3, rsi) < 3) return false;
   bool candleOk = (wSum > 0 && close[1] > open[1]) || (wSum < 0 && close[1] < open[1]);
   bool rsiOk = (wSum > 0 && rsi[1] < RSI_FILTER_BUY_MAX) || (wSum < 0 && rsi[1] > RSI_FILTER_SELL_MIN);
   return (candleOk && rsiOk);
}

bool SimulateTradeWithFile(int shift, ENUM_TIMEFRAMES tf, double wSum, double atrMult,
                           int &totalTests, int &wins, int &losses, int &canceled,
                           IndicatorParams &params, datetime signalTime, int candlesForecast)
{
   int lifetimeMinutes = CalculateSignalLifetimeForBacktest(tf, wSum, candlesForecast);
   int lifetimeBars = (tf == PERIOD_H1) ? lifetimeMinutes / 60 : (tf == PERIOD_H4) ? lifetimeMinutes / 240 : lifetimeMinutes / 1440;
   if(lifetimeBars < 1) lifetimeBars = 1;
   
   double entry = iClose(_Symbol, tf, shift);
   if(entry == 0) return false;
   
   double atr[];
   ArraySetAsSeries(atr, true);
   int hATR = iATR(_Symbol, tf, params.atrPeriod);
   if(hATR == INVALID_HANDLE) return false;
   if(CopyBuffer(hATR, 0, shift, 2, atr) < 2) return false;
   double currentATR = atr[0];
   if(currentATR <= 0) return false;
   
   double sl = 0, tp = 0;
   string direction = (wSum > 0) ? "BUY" : "SELL";
   double slDistance = currentATR * atrMult;
   if(direction == "BUY") { sl = entry - slDistance; tp = entry + (slDistance * TP_MULTIPLIER); }
   else { sl = entry + slDistance; tp = entry - (slDistance * TP_MULTIPLIER); }
   
   bool entryReached = false, slHit = false, tpHit = false;
   double exitPrice = 0;
   string result = "";
   
   for(int i = 1; i <= lifetimeBars && (shift - i) >= 0; i++)
   {
      double barHigh = iHigh(_Symbol, tf, shift - i);
      double barLow = iLow(_Symbol, tf, shift - i);
      if(barHigh == 0 || barLow == 0) continue;
      
      if(!entryReached)
      {
         if((direction == "BUY" && barHigh >= entry) || (direction == "SELL" && barLow <= entry))
            entryReached = true;
      }
      else
      {
         if(direction == "BUY")
         {
            if(barLow <= sl) { slHit = true; exitPrice = sl; break; }
            if(barHigh >= tp) { tpHit = true; exitPrice = tp; break; }
         }
         else
         {
            if(barHigh >= sl) { slHit = true; exitPrice = sl; break; }
            if(barLow <= tp) { tpHit = true; exitPrice = tp; break; }
         }
      }
   }
   
   if(!entryReached) { canceled++; totalTests++; result = "CANCELED"; }
   else if(slHit) { losses++; totalTests++; result = "LOSS"; }
   else if(tpHit) { wins++; totalTests++; result = "WIN"; }
   else { canceled++; totalTests++; result = "TIMEOUT"; exitPrice = iClose(_Symbol, tf, MathMax(0, shift - lifetimeBars)); }
   
   double movement = (exitPrice > 0) ? ((direction == "BUY") ? (exitPrice - entry) : (entry - exitPrice)) : 0;
   string tfStr = (tf == PERIOD_H1) ? "H1" : (tf == PERIOD_H4) ? "H4" : "D1";
   
   string reportFile = FILE_BACKTEST_PREFIX + currentSymbol + "_" + TimeToString(TimeCurrent(), TIME_DATE) + FILE_CSV_EXT;
   int handle = FileOpen(reportFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(handle != INVALID_HANDLE)
   {
      if(FileSize(handle) == 0)
         FileWrite(handle, "SignalTime", "TF", "Direction", "Entry", "SL", "TP", "ExitPrice", "Result", "Movement", "Lifetime", "WeightedSum");
      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle, TimeToString(signalTime, TIME_DATE|TIME_MINUTES), tfStr, direction,
                DoubleToString(entry, symbolDigits), DoubleToString(sl, symbolDigits), DoubleToString(tp, symbolDigits),
                DoubleToString(exitPrice, symbolDigits), result, DoubleToString(movement, symbolDigits),
                IntegerToString(lifetimeMinutes), DoubleToString(wSum, 1));
      FileClose(handle);
   }
   return true;
}

void UpdateTabs()
{
   for(int i = 0; i < TAB_COUNT; i++)
   {
      string btnName = panelName+"_Tab_"+IntegerToString(i);
      if(i == currentTab)
      {
         ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, C'60,80,120');
         ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite);
      }
      else
      {
         ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, C'35,35,50');
         ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrLightGray);
      }
   }
}

void UpdateCollapseButton()
{
   if(isCollapsed) { ObjectSetString(0, buttonName, OBJPROP_TEXT, "▲"); ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrOrange); }
   else { ObjectSetString(0, buttonName, OBJPROP_TEXT, "▼"); ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrYellow); }
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YSIZE, isCollapsed ? panelHeightCollapsed : panelHeightExpanded);
}

void UpdatePanel()
{
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YSIZE, isCollapsed ? panelHeightCollapsed : panelHeightExpanded);
   int y = panelY + 10;
   int lineHeight = PANEL_LINE_HEIGHT;
   string priceFormat = "%." + IntegerToString(symbolDigits) + "f";
   string title = "═══ " + currentSymbol + " (" + symbolType + ") PRO ═══";
   CreateLabel(panelName+"_Title", title, panelX + 10, y, clrYellow, 11);
   if(isCollapsed)
   {
      string shortInfo = "";
      color shortColor = clrGray;
      if(resultH1.weightedSum >= SIGNAL_STRONG_THRESHOLD) { shortInfo = "▲ STRONG BUY"; shortColor = clrLime; }
      else if(resultH1.weightedSum >= SIGNAL_WEAK_THRESHOLD) { shortInfo = "▲ BUY"; shortColor = clrGreen; }
      else if(resultH1.weightedSum <= -SIGNAL_STRONG_THRESHOLD) { shortInfo = "▼ STRONG SELL"; shortColor = clrRed; }
      else if(resultH1.weightedSum <= -SIGNAL_WEAK_THRESHOLD) { shortInfo = "▼ SELL"; shortColor = clrDarkRed; }
      else { shortInfo = "● HOLD"; shortColor = clrGray; }
      CreateLabel(panelName+"_ShortInfo", shortInfo, panelX + 250, y, shortColor, 10);
      ClearTabContent();
   }
   else ShowAllDetails(y, lineHeight, priceFormat);
   ChartRedraw();
}

void ClearTabContent()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, panelName) != 0) continue;
      if(StringFind(name, "_BG") >= 0) continue;
      if(StringFind(name, "_Title") >= 0) continue;
      if(StringFind(name, "_ShortInfo") >= 0) continue;
      if(StringFind(name, "_Tab_") >= 0) continue;
      if(StringFind(name, "_Prev") >= 0) continue;
      if(StringFind(name, "_Next") >= 0) continue;
      if(name == buttonName) continue;
      ObjectDelete(0, name);
   }
}

void ShowAllDetails(int startY, int lineHeight, string priceFormat)
{
   ClearTabContent();
   UpdateTabs();
   int y = startY + 65;
   CreateLabel(panelName+"_SubInfo", currentSession + " | " + DetectDayOfWeek() + " | " + TimeToString(TimeCurrent(), TIME_MINUTES|TIME_SECONDS), panelX + 10, y, clrLightGray, 9);
   y += lineHeight;
   CreateLabel(panelName+"_Sep0", "═══════════════════════════════════════════════════════", panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   string pageInfo = StringFormat("📑 Стр. %d/%d: %s", currentTab + 1, TAB_COUNT, TAB_NAMES[currentTab]);
   CreateLabel(panelName+"_PageInfo", pageInfo, panelX + 10, y, clrWheat, 9);
   y += lineHeight + 3;
   
   switch(currentTab)
   {
      case 0: RenderTab_Analysis(y, lineHeight, priceFormat); break;
      case 1: RenderTab_Filters(y, lineHeight); break;
      case 2: RenderTab_Levels(y, lineHeight, priceFormat); break;
      case 3: RenderTab_Stats(y, lineHeight); break;
      case 4: RenderTab_History(y, lineHeight, priceFormat); break;
   }
}

void RenderTab_Analysis(int y, int lineHeight, string priceFormat)
{
   CreateLabel(panelName+"_Col1", "ТФ", panelX + 20, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col2", "СИГНАЛЫ", panelX + 80, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col3", "Σ", panelX + 280, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col4", "ПРОГНОЗ", panelX + 330, y, clrDodgerBlue, 10);
   y += lineHeight + 3;
   CreateLabel(panelName+"_Sep1", "─────────────────────────────────────────────────────────", panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   DrawTFRow("H1", resultH1, "H1", y, priceFormat, lineHeight);
   y += lineHeight * 3;
   if(recEntryH1 > 0)
   {
      CreateLabel(panelName+"_LevelsH1", StringFormat("🟢 Entry: %s | SL: %s | TP: %s", DoubleToString(recEntryH1, symbolDigits), DoubleToString(recSLH1, symbolDigits), DoubleToString(recTPH1, symbolDigits)), panelX + 25, y, clrLime, 8);
      y += lineHeight;
   }
   else { CreateLabel(panelName+"_LevelsH1", "🟢 H1: нет сигнала", panelX + 25, y, clrGray, 8); y += lineHeight; }
   y += 5;
   CreateLabel(panelName+"_Sep2", "─────────────────────────────────────────────────────────", panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   DrawTFRow("H4", resultH4, "H4", y, priceFormat, lineHeight);
   y += lineHeight * 3;
   if(recEntryH4 > 0)
   {
      CreateLabel(panelName+"_LevelsH4", StringFormat("🟡 Entry: %s | SL: %s | TP: %s", DoubleToString(recEntryH4, symbolDigits), DoubleToString(recSLH4, symbolDigits), DoubleToString(recTPH4, symbolDigits)), panelX + 25, y, clrYellow, 8);
      y += lineHeight;
   }
   else { CreateLabel(panelName+"_LevelsH4", "🟡 H4: нет сигнала", panelX + 25, y, clrGray, 8); y += lineHeight; }
   y += 5;
   CreateLabel(panelName+"_Sep3", "─────────────────────────────────────────────────────────", panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   DrawTFRow("D1", resultD1, "D1", y, priceFormat, lineHeight);
   y += lineHeight * 3;
   if(recEntryD1 > 0)
   {
      CreateLabel(panelName+"_LevelsD1", StringFormat("🔴 Entry: %s | SL: %s | TP: %s", DoubleToString(recEntryD1, symbolDigits), DoubleToString(recSLD1, symbolDigits), DoubleToString(recTPD1, symbolDigits)), panelX + 25, y, clrOrangeRed, 8);
      y += lineHeight;
   }
   else { CreateLabel(panelName+"_LevelsD1", "🔴 D1: нет сигнала", panelX + 25, y, clrGray, 8); y += lineHeight; }
   y += 5;
   CreateLabel(panelName+"_Sep4", "═══════════════════════════════════════════════════════", panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   string summary = "💡 ";
   color sumColor = clrGray;
   if(resultH1.weightedSum >= SIGNAL_STRONG_THRESHOLD && resultH4.weightedSum >= 2 && resultD1.weightedSum >= -4) { summary += "ВСЕ ТФ БЫЧЬИ — ищите BUY"; sumColor = clrLime; }
   else if(resultH1.weightedSum <= -SIGNAL_STRONG_THRESHOLD && resultH4.weightedSum <= -2 && resultD1.weightedSum <= 4) { summary += "ВСЕ ТФ МЕДВЕЖЬИ — ищите SELL"; sumColor = clrRed; }
   else if(MathAbs(resultH1.weightedSum) < SIGNAL_WEAK_THRESHOLD && MathAbs(resultH4.weightedSum) < SIGNAL_WEAK_THRESHOLD) { summary += "ФЛЭТ — ждём тренда"; sumColor = clrOrange; }
   else { summary += "СМЕШАННЫЙ сигнал — осторожно"; sumColor = clrYellow; }
   CreateLabel(panelName+"_Summary", summary, panelX + 20, y, sumColor, 10);
}

void RenderTab_Filters(int y, int lineHeight)
{
   string modesStr = "🎛️ Режимы: ";
   modesStr += UseSignalH1 ? "🟢H1 " : "⚫H1 ";
   modesStr += UseSignalH4 ? "🟡H4 " : "⚫H4 ";
   modesStr += UseSignalD1 ? "🔴D1 " : "⚫D1 ";
   CreateLabel(panelName+"_Modes", modesStr, panelX + 10, y, clrWheat, 9);
   y += lineHeight + 3;
   CreateLabel(panelName+"_FilterTitle", "🛡️ ФИЛЬТРЫ ТОЧНОСТИ:", panelX + 10, y, clrYellow, 11);
   y += lineHeight + 3;
   DrawFilterRow("News", "📰 Новости (±30 мин)", filterNews, y); y += lineHeight;
   DrawFilterRow("Vol", "📊 Волатильность (ATR)", filterVolatility, y); y += lineHeight;
   DrawFilterRow("Sess", "🕐 Сессия (8-22)", filterSession, y); y += lineHeight;
   DrawFilterRow("Cand", "🕯️ Свечной паттерн", filterCandle, y); y += lineHeight;
   DrawFilterRow("RSI", "📈 RSI (не экстремум)", filterRSI, y); y += lineHeight;
   DrawFilterRow("Str", "🧱 Структура (уровни)", filterStructure, y); y += lineHeight + 5;
   CreateLabel(panelName+"_Sep5", "═══════════════════════════════════════════════════════", panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   bool allFilters = filterNews && filterVolatility && filterSession && filterCandle && filterRSI && filterStructure;
   string confirmStatus = "";
   color confirmColor = clrGray;
   if(allFilters)
   {
      confirmStatus = (resultH1.weightedSum > 0) ? "🟢 CONFIRMED BUY 🔔" : "🔴 CONFIRMED SELL 🔔";
      confirmColor = (resultH1.weightedSum > 0) ? clrLime : clrRed;
   }
   else
   {
      int passed = 0;
      if(filterNews) passed++; if(filterVolatility) passed++; if(filterSession) passed++;
      if(filterCandle) passed++; if(filterRSI) passed++; if(filterStructure) passed++;
      confirmStatus = StringFormat("⏳ Фильтры: %d/6 пройдено", passed);
      confirmColor = clrOrange;
   }
   CreateLabel(panelName+"_Confirm", confirmStatus, panelX + 20, y, confirmColor, 11);
}

void RenderTab_Levels(int y, int lineHeight, string priceFormat)
{
   CreateLabel(panelName+"_LevelsTitle", "📊 РЕКОМЕНДУЕМЫЕ УРОВНИ:", panelX + 10, y, clrYellow, 11);
   y += lineHeight + 5;
   if(recEntry > 0)
   {
      color activeColor = (activeMode == "H1") ? clrLime : (activeMode == "H4") ? clrYellow : clrOrangeRed;
      string activePrefix = (activeMode == "H1") ? "🟢" : (activeMode == "H4") ? "🟡" : "🔴";
      CreateLabel(panelName+"_Entry", StringFormat("%s ВХОД (%s): %s", activePrefix, recOrderType, DoubleToString(recEntry, symbolDigits)), panelX + 20, y, activeColor, 10);
      y += lineHeight;
      double slDist = MathAbs(recEntry - recSL);
      string slPips = (resultH1.atrValue > 0) ? StringFormat(" (-%.1f ATR)", slDist / resultH1.atrValue) : "";
      CreateLabel(panelName+"_SL", StringFormat("🛑 STOP LOSS: %s", DoubleToString(recSL, symbolDigits)) + slPips, panelX + 20, y, SLColor, 10);
      y += lineHeight;
      double tpDist = MathAbs(recTP - recEntry);
      string rr = (slDist > 0) ? StringFormat(" (R:R 1:%.1f)", tpDist / slDist) : "";
      CreateLabel(panelName+"_TP", StringFormat("🎯 TAKE PROFIT: %s", DoubleToString(recTP, symbolDigits)) + rr, panelX + 20, y, TPColor, 10);
      y += lineHeight + 5;
      double rrRatio = (slDist > 0) ? tpDist / slDist : 0;
      color rrColor = (rrRatio >= 2.0) ? clrLime : (rrRatio >= 1.5) ? clrYellow : (rrRatio >= 1.0) ? clrOrange : clrRed;
      string rrText = StringFormat("💰 Risk/Reward = 1:%.2f %s", rrRatio, rrRatio >= 2.0 ? "✅ ОТЛИЧНО" : (rrRatio >= 1.5 ? "✅ ХОРОШО" : (rrRatio >= 1.0 ? "⚠️ НОРМ" : "❌ ПЛОХО")));
      CreateLabel(panelName+"_RR", rrText, panelX + 20, y, rrColor, 10);
      y += lineHeight + 5;
      CreateLabel(panelName+"_StructTitle", "🧱 Структурные уровни (H4):", panelX + 10, y, clrYellow, 10);
      y += lineHeight;
      if(nearestResistance > 0) { CreateLabel(panelName+"_Res", StringFormat("🔸 Сопротивление: %s", DoubleToString(nearestResistance, symbolDigits)), panelX + 20, y, clrOrange, 9); y += lineHeight; }
      else { CreateLabel(panelName+"_Res", "🔸 Сопротивление: не найдено", panelX + 20, y, clrGray, 9); y += lineHeight; }
      if(nearestSupport > 0) { CreateLabel(panelName+"_Sup", StringFormat("🔹 Поддержка: %s", DoubleToString(nearestSupport, symbolDigits)), panelX + 20, y, clrDeepSkyBlue, 9); y += lineHeight; }
      else { CreateLabel(panelName+"_Sup", "🔹 Поддержка: не найдена", panelX + 20, y, clrGray, 9); y += lineHeight; }
   }
   else
   {
      CreateLabel(panelName+"_NoLevels", "⏸ Уровни появятся при подтверждении сигнала", panelX + 20, y, clrGray, 10);
      y += lineHeight;
      CreateLabel(panelName+"_Hint", "💡 Ждите подтверждения сигнала", panelX + 20, y, clrWheat, 9);
      y += lineHeight + 5;
   }
}

void RenderTab_Stats(int y, int lineHeight)
{
   CreateLabel(panelName+"_StatTitle", "📈 СТАТИСТИКА ТОЧНОСТИ:", panelX + 10, y, clrYellow, 11);
   y += lineHeight + 5;
   CreateLabel(panelName+"_StatDate", "📅 Сбор начат: " + TimeToString(statsStartDate, TIME_DATE), panelX + 20, y, clrGray, 9);
   y += lineHeight;
   CreateLabel(panelName+"_Stat1", StringFormat("📊 Всего сигналов: %d", totalSignals), panelX + 20, y, clrLightGray, 10);
   y += lineHeight;
   CreateLabel(panelName+"_Stat2", StringFormat("✅ Верных: %d", winningSignals), panelX + 20, y, clrLime, 10);
   y += lineHeight;
   CreateLabel(panelName+"_Stat3", StringFormat("❌ Ошибок: %d", losingSignals), panelX + 20, y, clrRed, 10);
   y += lineHeight;
   CreateLabel(panelName+"_Stat4", StringFormat("⏸ Аннулировано: %d", canceledSignals), panelX + 20, y, clrGray, 10);
   y += lineHeight + 5;
   CreateLabel(panelName+"_Sep6", "═══════════════════════════════════════════════════════", panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight + 3;
   
   double accuracy = GetAccuracy();
   color accColor = (accuracy >= 70) ? clrLime : (accuracy >= 55) ? clrOrange : (totalSignals > 0 ? clrRed : clrGray);
   CreateLabel(panelName+"_Acc", StringFormat("🎯 ТОЧНОСТЬ: %.1f%%", accuracy), panelX + 20, y, accColor, 14);
   y += lineHeight + 5;
   
   string gradeStr = "";
   color gradeColor = clrGray;
   if(totalSignals == 0) { gradeStr = "⏳ Нет данных"; }
   else if(accuracy >= ACCURACY_EXCELLENT) { gradeStr = "🏆 ОТЛИЧНО"; gradeColor = clrLime; }
   else if(accuracy >= ACCURACY_GOOD) { gradeStr = "✅ ХОРОШО"; gradeColor = clrGreen; }
   else if(accuracy >= ACCURACY_NORMAL) { gradeStr = "⚠️ НОРМАЛЬНО"; gradeColor = clrOrange; }
   else { gradeStr = "❗ ТРЕБУЕТ НАСТРОЙКИ"; gradeColor = clrRed; }
   CreateLabel(panelName+"_Grade", gradeStr, panelX + 20, y, gradeColor, 11);
   y += lineHeight + 10;
   
   string resetBtn = panelName+"_Reset";
   if(ObjectFind(0, resetBtn) >= 0) ObjectDelete(0, resetBtn);
   ObjectCreate(0, resetBtn, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, resetBtn, OBJPROP_XDISTANCE, panelX + panelWidth - 110);
   ObjectSetInteger(0, resetBtn, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, resetBtn, OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, resetBtn, OBJPROP_YSIZE, 26);
   ObjectSetString(0, resetBtn, OBJPROP_TEXT, "🗑️ RESET");
   ObjectSetInteger(0, resetBtn, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, resetBtn, OBJPROP_BGCOLOR, C'140,40,40');
   ObjectSetInteger(0, resetBtn, OBJPROP_BORDER_COLOR, C'180,60,60');
   ObjectSetString(0, resetBtn, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, resetBtn, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, resetBtn, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, resetBtn, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, resetBtn, OBJPROP_STATE, false);
   
   y += 35;
   string testBtn = panelName+"_Backtest";
   if(ObjectFind(0, testBtn) >= 0) ObjectDelete(0, testBtn);
   ObjectCreate(0, testBtn, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, testBtn, OBJPROP_XDISTANCE, panelX + 20);
   ObjectSetInteger(0, testBtn, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, testBtn, OBJPROP_XSIZE, panelWidth - 40);
   ObjectSetInteger(0, testBtn, OBJPROP_YSIZE, 30);
   ObjectSetString(0, testBtn, OBJPROP_TEXT, isBacktestRunning ? "⏳ ТЕСТ ЗАПУЩЕН..." : "🧪 ЗАПУСТИТЬ БЭКТЕСТ");
   ObjectSetInteger(0, testBtn, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, testBtn, OBJPROP_BGCOLOR, isBacktestRunning ? C'100,100,50' : C'40,100,40');
   ObjectSetInteger(0, testBtn, OBJPROP_BORDER_COLOR, C'80,150,80');
   ObjectSetString(0, testBtn, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, testBtn, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, testBtn, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, testBtn, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, testBtn, OBJPROP_STATE, false);
}

void RenderTab_History(int y, int lineHeight, string priceFormat)
{
   CreateLabel(panelName+"_HistTitle", "📜 ИСТОРИЯ ПОСЛЕДНИХ СИГНАЛОВ:", panelX + 10, y, clrYellow, 11);
   y += lineHeight + 3;
   CreateLabel(panelName+"_HistH1", "ВРЕМЯ", panelX + 15, y, clrDodgerBlue, 9);
   CreateLabel(panelName+"_HistH2", "ТФ", panelX + 110, y, clrDodgerBlue, 9);
   CreateLabel(panelName+"_HistH3", "НАПР", panelX + 145, y, clrDodgerBlue, 9);
   CreateLabel(panelName+"_HistH4", "ВХОД", panelX + 190, y, clrDodgerBlue, 9);
   CreateLabel(panelName+"_HistH5", "СТАТУС", panelX + 290, y, clrDodgerBlue, 9);
   y += lineHeight;
   CreateLabel(panelName+"_HistSep", "─────────────────────────────────────────────────────────", panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   int realCount = 0;
   for(int i = 0; i < HISTORY_SIZE; i++) if(history[i].time > 0) realCount++;
   if(realCount == 0)
   {
      CreateLabel(panelName+"_HistEmpty", "⏸ История пуста — ждём первый сигнал", panelX + 20, y, clrGray, 10);
      return;
   }
   
   for(int i = HISTORY_SIZE - 1; i >= 0; i--)
   {
      if(history[i].time == 0) continue;
      string timeStr = TimeToString(history[i].time, TIME_DATE|TIME_MINUTES);
      StringSetCharacter(timeStr, 4, '-');
      StringSetCharacter(timeStr, 7, '-');
      CreateLabel(panelName+"_HistT_"+IntegerToString(i), timeStr, panelX + 15, y, clrLightGray, 8);
      color modeColor = (history[i].mode == "H1") ? clrLime : (history[i].mode == "H4") ? clrYellow : clrOrangeRed;
      CreateLabel(panelName+"_HistM_"+IntegerToString(i), history[i].mode, panelX + 115, y, modeColor, 9);
      color dirColor = (history[i].direction == "BUY") ? clrLime : clrRed;
      CreateLabel(panelName+"_HistD_"+IntegerToString(i), (history[i].direction == "BUY") ? "▲ BUY" : "▼ SELL", panelX + 145, y, dirColor, 8);
      CreateLabel(panelName+"_HistE_"+IntegerToString(i), DoubleToString(history[i].entry, symbolDigits), panelX + 190, y, clrWhite, 8);
      color statusColor = (StringFind(history[i].status, "WIN") >= 0) ? clrLime : (StringFind(history[i].status, "LOSS") >= 0) ? clrRed : clrOrange;
      CreateLabel(panelName+"_HistS_"+IntegerToString(i), history[i].status, panelX + 285, y, statusColor, 8);
      y += lineHeight - 2;
   }
}

void DrawFilterRow(string id, string label, bool passed, int y)
{
   CreateLabel(panelName+"_F_"+id, (passed ? "✅ " : "❌ ") + label, panelX + 25, y, passed ? clrLime : clrRed, 10);
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
   color sumColor = (result.weightedSum > 0) ? clrLime : (result.weightedSum < 0) ? clrRed : clrGray;
   CreateLabel(panelName+"_Sum"+prefix, StringFormat("%+.1f", result.weightedSum), panelX + 285, y, sumColor, 11);
   color sigColor = GetSignalColor(result.signal);
   CreateLabel(panelName+"_Signal"+prefix, result.signal, panelX + 330, y, sigColor, 10);
   y += lineHeight;
   CreateLabel(panelName+"_Forecast"+prefix, StringFormat("%d свечей", result.candlesForecast), panelX + 330, y, clrOrange, 9);
   y += lineHeight;
   string priceStr = StringFormat(priceFormat + " → " + priceFormat, result.currentPrice, result.targetPrice);
   color priceColor = (result.targetPrice > result.currentPrice) ? clrLime : (result.targetPrice < result.currentPrice) ? clrRed : clrGray;
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


