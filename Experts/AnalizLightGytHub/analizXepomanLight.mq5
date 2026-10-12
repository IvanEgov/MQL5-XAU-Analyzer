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
#include <Executor.mqh>      // ← СЛОЙ 7: ИСПОЛНИТЕЛЬ

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

//--- Результаты анализа по ТФ (локальные копии для логики)
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

//=== ЧУВСТВИТЕЛЬНОСТЬ СИГНАЛОВ ===
input group "══════ ЧУВСТВИТЕЛЬНОСТЬ СИГНАЛОВ ══════"
input int    MinBarsBetweenSignals = 4;   // Минимум часов между сигналами одного ТФ
input bool   AllowRepeatSignals    = true; // Разрешить повторные сигналы (BUY после BUY)
input int    BacktestStepBars      = 1;   // Шаг проверки в бэктесте (1=каждый бар, 4=каждый 4-й)

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

//=== ТОРГЛЯ (РЕАЛЬНОЕ ИСПОЛНЕНИЕ) ===
input group "══════ ТОРГЛЯ (⚠️ ВКЛЮЧАЙ ОСОЗНАННО) ══════"
 bool   EnableTrading     = false;    // ⚠️ Реальная торговля (по умолчанию ВЫКЛ)
input int    MagicNumber       = 20261012; // Магик-номер советника
input string TradeComment      = "XAU-AI"; // Комментарий ордера
input bool   UseRiskPercent    = true;     // Расчёт лота от риска в %
input double RiskPercent       = 1.0;      // Риск на сделку, %
input double FixedLot          = 0.01;     // Фиксированный лот (если риск выключен)
input int    MaxSpreadPoints   = 35;       // Максимальный спред (0 = без лимита)
input int    MaxOpenPositions  = 1;        // Максимум одновременных позиций
//=== НАСТРОЙКИ БЭКТЕСТА ===
input group "══════ НАСТРОЙКИ БЭКТЕСТА ══════"
input int    backtestBars      = 1000;
input bool   OptimizeParams    = true;

//=== СЕТКА ОПТИМИЗАЦИИ (min / max / step) ===
input group "══════ СЕТКА ОПТИМИЗАЦИИ (min/max/step) ══════"
input double OptThresholdMin   = 4.0;    // Порог сигнала: МИН
input double OptThresholdMax   = 10.0;   // Порог сигнала: МАКС
input double OptThresholdStep  = 1.0;    // Порог сигнала: ШАГ

input double OptATRMin         = 1.0;    // ATR SL множитель: МИН
input double OptATRMax         = 3.0;    // ATR SL множитель: МАКС
input double OptATRStep        = 0.5;    // ATR SL множитель: ШАГ

input int    OptEMAMin         = 20;     // EMA период: МИН
input int    OptEMAMax         = 60;     // EMA период: МАКС
input int    OptEMAStep        = 10;     // EMA период: ШАГ

input int    OptRSIMin         = 7;      // RSI период: МИН
input int    OptRSIMax         = 21;     // RSI период: МАКС
input int    OptRSIStep        = 2;      // RSI период: ШАГ
#include <Backtester.mqh>


//+------------------------------------------------------------------+
int OnInit()
{
   currentSymbol = _Symbol;
   
   //=== ИНИЦИАЛИЗАЦИЯ МЕНЕДЖЕРА ===
   SignalManager_Init();
      //=== ИНИЦИАЛИЗАЦИЯ ИСПОЛНИТЕЛЯ ===
   Executor_Init(MagicNumber, TradeComment);
   
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
   
   //=== ИНИЦИАЛИЗАЦИЯ UI (Добавить в конец OnInit) ===
   g_currentSymbol = currentSymbol;
   g_symbolPoint = symbolPoint;
   UI_CreateBasePanel();
   if(!isCollapsed) UI_CreateTabs();
   
   Print("✅ ", currentSymbol, " (", symbolType, ") PRO-аналитик запущен");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   isBacktestRunning = false;
   DeleteLevels();
   EventKillTimer(); 
   UI_DeleteAll();   
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
   // Передаем константные ссылки в UI модуль
   if(UI_OnChartEvent(id, lparam, dparam, sparam)) return;
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
   
   //=== СИНХРОНИЗАЦИЯ ДАННЫХ С UI МОДУЛЕМ (ОБЯЗАТЕЛЬНО) ===
   g_resultH1 = resultH1;
   g_resultH4 = resultH4;
   g_resultD1 = resultD1;
   g_currentSymbol = currentSymbol;
   g_symbolPoint = symbolPoint;
   
   // Перерисовка текущей вкладки, если панель не свернута
   if(!isCollapsed)
   {
      UI_DeleteTabContent(currentTab); // Очищаем старое содержимое
      UI_DrawCurrentTab();             // Рисуем новое с актуальными данными
   }
   
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
      
      // Проверка интервала между сигналами
      bool canPlaceH1 = false;
      if(sigH1 != "")
      {
         if(AllowRepeatSignals)
         {
            // Разрешаем повторные, но с интервалом
            datetime timeSinceLast = TimeCurrent() - lastSignalCheckTime;
            canPlaceH1 = (timeSinceLast >= MinBarsBetweenSignals * 3600) || (lastSignalCheckTime == 0);
         }
         else
         {
            // Старая логика — запрет повторов
            canPlaceH1 = (sigH1 != lastSignalH1);
         }
      }
      
      if(canPlaceH1)
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
                  //=== ВЫСТАВЛЕНИЕ РЕАЛЬНОГО ОРДЕРА ===
         string orderResult = "";
         Executor_OpenPosition(recOrderTypeH1, recEntryH1, recSLH1, recTPH1, "H1", orderResult);
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
                  //=== ВЫСТАВЛЕНИЕ РЕАЛЬНОГО ОРДЕРА ===
         string orderResult = "";
         Executor_OpenPosition(recOrderTypeH4, recEntryH4, recSLH4, recTPH4, "H4", orderResult);
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
                  //=== ВЫСТАВЛЕНИЕ РЕАЛЬНОГО ОРДЕРА ===
         string orderResult = "";
         Executor_OpenPosition(recOrderTypeD1, recEntryD1, recSLD1, recTPD1, "D1", orderResult);
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
      Executor_Reset();   // Сбрасываем состояние исполнителя
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
//| РАСЧЁТ СРОКА ЖИЗНИ                                               |
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

