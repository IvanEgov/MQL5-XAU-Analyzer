//+------------------------------------------------------------------+
//|                                    XAU_Analyzer_PRO.mq5          |
//|           PRO-аналитик с вкладками (прокрутка страниц)           |
//+------------------------------------------------------------------+
#property strict

//=== ПОДКЛЮЧЕНИЕ СЛОЯ 1: КОНФИГУРАЦИЯ ===
#include <Config.mqh>

//=== ПОДКЛЮЧЕНИЕ СЛОЯ 2: СТРУКТУРЫ ДАННЫХ ===
#include <DataStructures.mqh>

//=== ПОДКЛЮЧЕНИЕ СЛОЯ 3: ЯДРО АНАЛИЗА ===
#include <Analyzer.mqh>

//=== ПОДКЛЮЧЕНИЕ СЛОЯ 4: МЕНЕДЖЕР СИГНАЛОВ ===
#include <SignalManager.mqh>

// Глобальные параметры (можно оптимизировать)
IndicatorParams optParams;





string historyFileName = "signal_history.dat";



//--- Бэктест на истории
bool isBacktestRunning = false;

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


bool isCollapsed = false;

int currentTab = 0;

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
input int    ResultCheckDelay  = 60;  // Задержка проверки результата (минуты). 180 = 3 часа. Поставьте 5 для быстрого теста.

//=== ОТКЛЮЧАЕМЫЕ ФИЛЬТРЫ ===
input group "══════ ФИЛЬТРЫ (включайте/выключайте) ══════"
input bool   FilterLag         = true;    // Фильтр запаздывания (не ловить хвост)
input bool   FilterStructure   = true;    // Фильтр структурных уровней
input bool   FilterRSI         = true;    // Фильтр RSI (не в экстремуме)
input bool   FilterCandle      = true;    // Фильтр свечного паттерна
input bool   FilterSession     = true;    // Фильтр сессии (0-5 часов)
input bool   FilterVolatility  = true;    // Фильтр волатильности
input bool   FilterNews        = true;    // Фильтр новостей
/*
Скальпинг/интрадей
H1 = true, H4 = false, D1 = false
Свинг-трейдинг
H1 = false, H4 = true, D1 = false
Позиционный трейдинг
H1 = false, H4 = false, D1 = true
Все сразу
H1 = true, H4 = true, D1 = true*/
//=== РЕЖИМЫ СИГНАЛОВ (включайте нужные) ===
input bool   UseSignalH1       = true;    // 🟢 Сигналы H1 (быстрые, 1-5 свечей)
input bool   UseSignalH4       = true;   // 🟡 Сигналы H4 (средние, 4-20 свечей)
input bool   UseSignalD1       = true;   // 🔴 Сигналы D1 (долгие, 1-10 дней)

//=== ОПТИМИЗИРУЕМЫЕ ПАРАМЕТРЫ ИНДИКАТОРОВ ===
input group "══════ ПАРАМЕТРЫ ИНДИКАТОРОВ (оптимизируются бэктестом) ══════"
input int    InpEmaFastPeriod  = 30;    // Период быстрой EMA (50 по умолчанию)
input int    InpEmaSlowPeriod  = 200;   // Период медленной EMA (200 по умолчанию)
input int    InpRsiPeriod      = 10;    // Период RSI (14 по умолчанию)
input double InpRsiOverbought  = 70.0;  // RSI перекупленность (70)
input double InpRsiOversold    = 30.0;  // RSI перепроданность (30)
input int    InpMacdFast       = 12;    // MACD быстрый период (12)
input int    InpMacdSlow       = 26;    // MACD медленный период (26)
input int    InpMacdSignal     = 9;     // MACD сигнальный период (9)
input int    InpAdxPeriod      = 14;    // Период ADX (14)
input double InpAdxThreshold   = 25.0;  // Порог силы тренда ADX (25)
input int    InpStochK         = 14;    // Stochastic %K (14)
input int    InpStochD         = 3;     // Stochastic %D (3)
input int    InpStochSlowing   = 3;     // Stochastic замедление (3)
input int    InpCciPeriod      = 20;    // Период CCI (20)
input double InpCciLevel       = 100.0; // Уровень CCI (100)
input int    InpBbPeriod       = 20;    // Bollinger Bands период (20)
input double InpBbDeviation    = 2.0;   // Bollinger Bands отклонение (2.0)
input int    InpAtrPeriod      = 14;    // Период ATR (14)
input double InpAtrSlMult      = 2.5;   // Множитель ATR для SL (1.5)
input double InpSignalThreshold= 8.0;   // Порог взвешенной суммы (6.0)

//=== НАСТРОЙКИ БЭКТЕСТА ===
input group "══════ НАСТРОЙКИ БЭКТЕСТА ══════"
input int    backtestBars      = 1000;  // Количество баров для теста
input bool   OptimizeParams    = true;  // Запускать авто-оптимизацию

//--- Статистика (сохранение в файл)
string statsFileName = "";  // Инициализируется в OnInit()
datetime statsStartDate = 0;
string statsSymbol = "";

//--- Лог сигналов в CSV
string logFileName = "";    // Инициализируется в OnInit()
string resultFileName = ""; // Инициализируется в OnInit()
datetime logMonthStart = 0;
//+------------------------------------------------------------------+
int OnInit()
{
   currentSymbol = _Symbol;
   
    //=== ИНИЦИАЛИЗАЦИЯ МЕНЕДЖЕРА СИГНАЛОВ ===
   SignalManager_Init();
   
      //=== ИНИЦИАЛИЗАЦИЯ ПАРАМЕТРОВ ИЗ INPUT НАСТРОЕК ===
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
   
   Print("📊 Текущие параметры индикаторов:");
   Print("   EMA: ", optParams.emaFastPeriod, "/", optParams.emaSlowPeriod);
   Print("   RSI: ", optParams.rsiPeriod, " (OB:", optParams.rsiOverbought, " OS:", optParams.rsiOversold, ")");
   Print("   ATR SL Mult: ", optParams.atrSLMult);
   Print("   Порог сигнала: ", optParams.signalThreshold);
   
   //=== УНИКАЛЬНЫЕ ИМЕНА ФАЙЛОВ ДЛЯ КАЖДОЙ ПАРЫ ===
   string cleanSymbol = currentSymbol;
   // Убираем недопустимые символы из имени файла
   StringReplace(cleanSymbol, "/", "_");
   StringReplace(cleanSymbol, "\\", "_");
   StringReplace(cleanSymbol, ":", "_");
   StringReplace(cleanSymbol, "*", "_");
   StringReplace(cleanSymbol, "?", "_");
   StringReplace(cleanSymbol, "\"", "_");
   StringReplace(cleanSymbol, "<", "_");
   StringReplace(cleanSymbol, ">", "_");
   StringReplace(cleanSymbol, "|", "_");
   
   statsFileName = "stats_" + cleanSymbol + ".json";
   logFileName = "signals_" + cleanSymbol + ".csv";
   resultFileName = "results_" + cleanSymbol + ".csv";
   historyFileName = "history_" + cleanSymbol + ".dat";
   
   Print("📂 Файлы для ", currentSymbol, ":");
   Print("   📊 Статистика: ", statsFileName);
   Print("   📝 Лог сигналов: ", logFileName);
   Print("   📋 Лог результатов: ", resultFileName);
   Print("   📜 История: ", historyFileName);
   
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
   
   CreatePanel();
   CreateCollapseButton();
   CreateTabs();
   EventSetTimer(60);
   
   Print("✅ ", currentSymbol, " (", symbolType, ") PRO-аналитик запущен");
   //=== СБРОС СОСТОЯНИЯ БЭКТЕСТА ПРИ СТАРТЕ ===
   isBacktestRunning = false;
   Print("📑 Используйте вкладки для навигации");
   
//=== ЗАГРУЗКА СТАТИСТИКИ ИЗ ФАЙЛА ===
LoadStats();
InitLogs(); 
LoadHistory();  
LoadActiveSignal();
return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Сохранение статистики в файл                                    |
//+------------------------------------------------------------------+
void SaveStats()
{
   Print("💾 Сохраняю статистику в файл: ", statsFileName);
   Print("   total=", totalSignals, " wins=", winningSignals, " losses=", losingSignals);
   
   int handle = FileOpen(statsFileName, FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Не удалось сохранить статистику");
      return;
   }
   
   string json = "{\n";
   json += "  \"symbol\": \"" + currentSymbol + "\",\n";
   json += "  \"startDate\": " + IntegerToString((int)statsStartDate) + ",\n";
   json += "  \"total\": " + IntegerToString(totalSignals) + ",\n";
   json += "  \"wins\": " + IntegerToString(winningSignals) + ",\n";
   json += "  \"losses\": " + IntegerToString(losingSignals) + "\n";
   json += "}";
   
   FileWriteString(handle, json);
   FileClose(handle);
   
   Print("💾 Статистика сохранена: ", totalSignals, " сигналов");
}

//+------------------------------------------------------------------+
//| Загрузка статистики из файла (С ДИАГНОСТИКОЙ)                   |
//+------------------------------------------------------------------+
void LoadStats()
{
   Print("🔍 Пытаюсь загрузить статистику из файла: ", statsFileName);
   
   if(!FileIsExist(statsFileName))
   {
      Print("📂 Файл статистики НЕ НАЙДЕН — начинаем с нуля");
      statsStartDate = TimeCurrent();
      statsSymbol = currentSymbol;
      return;
   }
   
   Print("✅ Файл найден, пытаюсь открыть...");
   
   int handle = FileOpen(statsFileName, FILE_READ|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Не удалось открыть файл статистики! Ошибка: ", GetLastError());
      statsStartDate = TimeCurrent();
      return;
   }
   
   Print("✅ Файл открыт успешно");
   
   string content = FileReadString(handle, FileSize(handle));
   FileClose(handle);
   
   Print("📄 Содержимое файла: ", content);
   
   // Простой парсинг JSON
   string savedSymbol = ExtractJsonString(content, "symbol");
   statsStartDate = (datetime)ExtractJsonInt(content, "startDate");
   totalSignals = ExtractJsonInt(content, "total");
   winningSignals = ExtractJsonInt(content, "wins");
   losingSignals = ExtractJsonInt(content, "losses");
   
   Print("📊 Загружено: symbol=", savedSymbol, " total=", totalSignals, 
         " wins=", winningSignals, " losses=", losingSignals);
   
   // Если пара сменилась — обнуляем статистику
   if(savedSymbol != currentSymbol)
   {
      Print("🔄 Пара сменилась (", savedSymbol, " → ", currentSymbol, ") — статистика обнулена");
      ResetStats();
      return;
   }
   
   statsSymbol = currentSymbol;
   Print("✅ Статистика загружена: ", totalSignals, " сигналов, точность ", 
         DoubleToString(GetAccuracy(), 1), "%");
   Print("📅 Сбор начат: ", TimeToString(statsStartDate, TIME_DATE));
}
//+------------------------------------------------------------------+
//| Обнуление статистики                                            |
//+------------------------------------------------------------------+
void ResetStats()
{
   totalSignals = 0;
   winningSignals = 0;
   losingSignals = 0;
   statsStartDate = TimeCurrent();
   statsSymbol = currentSymbol;
   lastEntryPrice = 0;
   signalChecked = false;
   
   SaveStats();
   Print("🗑️ Статистика обнулена");
}

//+------------------------------------------------------------------+
//| Инициализация лога (создание файла с заголовками)               |
//+------------------------------------------------------------------+
void InitLogs()
{
   logMonthStart = TimeCurrent();
   
   //=== ФАЙЛ СИГНАЛОВ ===
   if(!FileIsExist(logFileName))
   {
      int handle = FileOpen(logFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
      if(handle != INVALID_HANDLE)
      {
         FileWrite(handle, "DateTime", "Symbol", "Mode", "Direction", 
                   "Entry", "SL", "TP", "WeightedSum", "ATR", "RR_Ratio");
         FileClose(handle);
         Print("📄 Создан файл лога сигналов: ", logFileName);
      }
   }
   else
   {
      // Проверяем, не пора ли очистить (раз в месяц)
      CheckLogRotation();
   }
   
   //=== ФАЙЛ РЕЗУЛЬТАТОВ ===
   if(!FileIsExist(resultFileName))
   {
      int handle = FileOpen(resultFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
      if(handle != INVALID_HANDLE)
      {
         FileWrite(handle, "DateTime", "Symbol", "Mode", "Direction", 
                   "Entry", "ExitPrice", "Result", "Movement");
         FileClose(handle);
         Print("📄 Создан файл лога результатов: ", resultFileName);
      }
   }
}

//+------------------------------------------------------------------+
//| Добавление нового сигнала в историю                             |
//+------------------------------------------------------------------+
void AddToHistory(string mode, string direction, double entry, double sl, 
                  double tp, double weightedSum)
{
   // Сдвигаем все записи на одну позицию влево (старая удаляется)
   for(int i = 0; i < HISTORY_SIZE - 1; i++)
      history[i] = history[i + 1];
   
   // Добавляем новую запись в конец
   SignalRecord newRec;
   newRec.time = TimeCurrent();
   newRec.mode = mode;
   newRec.direction = direction;
   newRec.entry = entry;
   newRec.sl = sl;
   newRec.tp = tp;
   newRec.status = "⏳ ОЖИДАНИЕ";
   newRec.movement = 0;
   newRec.weightedSum = weightedSum;
   history[HISTORY_SIZE - 1] = newRec;
   
   SaveHistory();
}

//+------------------------------------------------------------------+
//| Обновление статуса последней записи (WIN/LOSS)                  |
//+------------------------------------------------------------------+
void UpdateHistoryResult(string result, double movement)
{
   // Ищем последнюю запись со статусом "ОЖИДАНИЕ"
   for(int i = HISTORY_SIZE - 1; i >= 0; i--)
   {
      if(StringFind(history[i].status, "ОЖИДАНИЕ") >= 0)
      {
         if(result == "WIN")
            history[i].status = "✅ WIN";
         else
            history[i].status = "❌ LOSS";
         history[i].movement = movement;
         break;
      }
   }
   SaveHistory();
}

//+------------------------------------------------------------------+
//| Сохранение истории в файл                                       |
//+------------------------------------------------------------------+
void SaveHistory()
{
   int handle = FileOpen(historyFileName, FILE_WRITE|FILE_BIN);
   if(handle == INVALID_HANDLE) return;
   
   // Записываем количество реальных записей
   int count = 0;
   for(int i = 0; i < HISTORY_SIZE; i++)
      if(history[i].time > 0) count++;
   FileWriteInteger(handle, count);
   
   // Записываем каждую запись
   for(int i = 0; i < HISTORY_SIZE; i++)
   {
      FileWriteInteger(handle, (int)history[i].time);
      FileWriteString(handle, history[i].mode);
      FileWriteString(handle, history[i].direction);
      FileWriteDouble(handle, history[i].entry);
      FileWriteDouble(handle, history[i].sl);
      FileWriteDouble(handle, history[i].tp);
      FileWriteString(handle, history[i].status);
      FileWriteDouble(handle, history[i].movement);
      FileWriteDouble(handle, history[i].weightedSum);
   }
   FileClose(handle);
}

//+------------------------------------------------------------------+
//| Загрузка истории из файла                                       |
//+------------------------------------------------------------------+
void LoadHistory()
{
   // Обнуляем историю
   for(int i = 0; i < HISTORY_SIZE; i++)
   {
      history[i].time = 0;
      history[i].mode = "";
      history[i].direction = "";
      history[i].entry = 0;
      history[i].sl = 0;
      history[i].tp = 0;
      history[i].status = "";
      history[i].movement = 0;
      history[i].weightedSum = 0;
   }
   
   if(!FileIsExist(historyFileName))
   {
      Print("📂 История сигналов пуста");
      return;
   }
   
   int handle = FileOpen(historyFileName, FILE_READ|FILE_BIN);
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Не удалось загрузить историю");
      return;
   }
   
   int count = FileReadInteger(handle);
   if(count < 0 || count > HISTORY_SIZE) count = 0;
   
   // Загружаем записи (с конца — самые свежие)
   int startPos = HISTORY_SIZE - count;
   for(int i = startPos; i < HISTORY_SIZE; i++)
   {
      history[i].time = (datetime)FileReadInteger(handle);
      history[i].mode = FileReadString(handle);
      history[i].direction = FileReadString(handle);
      history[i].entry = FileReadDouble(handle);
      history[i].sl = FileReadDouble(handle);
      history[i].tp = FileReadDouble(handle);
      history[i].status = FileReadString(handle);
      history[i].movement = FileReadDouble(handle);
      history[i].weightedSum = FileReadDouble(handle);
   }
   FileClose(handle);
   
   Print("📂 История загружена: ", count, " сигналов");
}
//+------------------------------------------------------------------+
//| Запись сигнала в лог                                            |
//+------------------------------------------------------------------+
void LogSignal(string mode, string direction, double entry, double sl, double tp, 
               double weightedSum, double atr)
{
   int handle = FileOpen(logFileName, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Не удалось записать сигнал в лог");
      return;
   }
   
   FileSeek(handle, 0, SEEK_END);
   
   double rrRatio = 0;
   double slDist = MathAbs(entry - sl);
   double tpDist = MathAbs(tp - entry);
   if(slDist > 0) rrRatio = tpDist / slDist;
   
   FileWrite(handle, 
             TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES),
             currentSymbol,
             mode,
             direction,
             DoubleToString(entry, symbolDigits),
             DoubleToString(sl, symbolDigits),
             DoubleToString(tp, symbolDigits),
             DoubleToString(weightedSum, 1),
             DoubleToString(atr, symbolDigits),
             DoubleToString(rrRatio, 2));
   
   FileClose(handle);
}

//+------------------------------------------------------------------+
//| Запись результата сигнала                                       |
//+------------------------------------------------------------------+
void LogResult(string mode, string direction, double entry, double exitPrice, 
               string result, double movement)
{
   int handle = FileOpen(resultFileName, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Не удалось записать результат в лог");
      return;
   }
   
   FileSeek(handle, 0, SEEK_END);
   
   FileWrite(handle,
             TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES),
             currentSymbol,
             mode,
             direction,
             DoubleToString(entry, symbolDigits),
             DoubleToString(exitPrice, symbolDigits),
             result,
             DoubleToString(movement, symbolDigits));
   
   FileClose(handle);
}

//+------------------------------------------------------------------+
//| Автоочистка лога раз в месяц                                    |
//+------------------------------------------------------------------+
void CheckLogRotation()
{
   MqlDateTime now, start;
   TimeCurrent(now);
   TimeToStruct(logMonthStart, start);
   
   // Если прошёл месяц — просто очищаем
   if(now.mon != start.mon || now.year != start.year)
   {
      // Удаляем старые файлы
      FileDelete(logFileName);
      FileDelete(resultFileName);
      
      // Пересоздаём файлы с заголовками
      int h1 = FileOpen(logFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
      if(h1 != INVALID_HANDLE)
      {
         FileWrite(h1, "DateTime", "Symbol", "Mode", "Direction", 
                   "Entry", "SL", "TP", "WeightedSum", "ATR", "RR_Ratio");
         FileClose(h1);
      }
      
      int h2 = FileOpen(resultFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
      if(h2 != INVALID_HANDLE)
      {
         FileWrite(h2, "DateTime", "Symbol", "Mode", "Direction", 
                   "Entry", "ExitPrice", "Result", "Movement");
         FileClose(h2);
      }
      
      logMonthStart = TimeCurrent();
      Print("🔄 Логи очищены (раз в месяц, без архивации)");
   }
}
//+------------------------------------------------------------------+
//| Вспомогательные функции парсинга JSON                           |
//+------------------------------------------------------------------+
string ExtractJsonString(string json, string key)
{
   string search = "\"" + key + "\": \"";
   int start = StringFind(json, search);
   if(start < 0) return "";
   start += StringLen(search);
   int end = StringFind(json, "\"", start);
   if(end < 0) return "";
   return StringSubstr(json, start, end - start);
}

int ExtractJsonInt(string json, string key)
{
   string search = "\"" + key + "\": ";
   int start = StringFind(json, search);
   if(start < 0) return 0;
   start += StringLen(search);
   int end = StringFind(json, ",", start);
   if(end < 0) end = StringFind(json, "\n", start);
   if(end < 0) end = StringFind(json, "}", start);
   if(end < 0) return 0;
   string val = StringSubstr(json, start, end - start);
   StringTrimRight(val);
   return (int)StringToInteger(val);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   isBacktestRunning = false; 
   DeletePanel();
   DeleteLevels();
   EventKillTimer();
}

//+------------------------------------------------------------------+
void OnTimer() { Analyze(); }
void OnTick()  
{ 
   Analyze(); 
   CheckSignalResult();
}

//+------------------------------------------------------------------+
//| Обработчик кликов по кнопкам                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
  /* //=== ВРЕМЕННАЯ ОТЛАДКА (удалить после проверки!) ===
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      Print("🖱️ КЛИК по объекту: [", sparam, "]");
   }
   //=== КОНЕЦ ОТЛАДКИ ===
   */
   
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Кнопка свернуть/развернуть
      if(sparam == buttonName)
      {
         isCollapsed = !isCollapsed;
         ObjectSetInteger(0, buttonName, OBJPROP_STATE, false);
         UpdateCollapseButton();
         UpdatePanel();
         ChartRedraw();
      }
      // Кнопки вкладок
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
      // Кнопка ◀ (предыдущая вкладка)
      else if(sparam == panelName+"_Prev")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         currentTab--;
         if(currentTab < 0) currentTab = TAB_COUNT - 1;
         UpdateTabs();
         UpdatePanel();
         ChartRedraw();
      }
      // Кнопка ▶ (следующая вкладка)
      else if(sparam == panelName+"_Next")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         currentTab++;
         if(currentTab >= TAB_COUNT) currentTab = 0;
         UpdateTabs();
         UpdatePanel();
         ChartRedraw();
      }
   
               // Кнопка сброса статистики
      else if(sparam == panelName+"_Reset")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         if(MessageBox("Обнулить всю статистику?\n\nЭто действие нельзя отменить.", 
                       "Подтверждение сброса", MB_YESNO|MB_ICONQUESTION) == IDYES)
         {
            ResetStats();
            UpdatePanel();
            ChartRedraw();
         }
      }
                   // Кнопка запуска бэктеста
      else if(StringFind(sparam, "_Backtest") >= 0)
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         
         if(isBacktestRunning)
         {
            Print("⏳ Бэктест уже запущен, подождите...");
            return;
         }
         
         Print("✅ Кнопка бэктеста АКТИВИРОВАНА — запускаю тест...");
         
         //=== ВАЖНО: обновляем панель ДО запуска теста ===
         isBacktestRunning = true;
         UpdatePanel();
         ChartRedraw();
         Sleep(100);  // Даём время на перерисовку
         
         // Запускаем бэктест
         RunBacktest();
         
         //=== Обновляем панель ПОСЛЕ завершения теста ===
         isBacktestRunning = false;
         UpdatePanel();
         ChartRedraw();
      }
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
//================ ФИЛЬТРЫ ===========================================
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
   if(ratio < 0.6 || ratio > 2.2) return false;
   return true;
}

bool IsGoodSession()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.day_of_week == 0 || dt.day_of_week == 6) return false; // Выходные
   if(dt.day_of_week == 5 && dt.hour >=20) return false; // Поздняя пятница
   
   // МЯГКИЙ ФИЛЬТР: блокируем только "мёртвую" азиатскую ночь (00:00 - 05:00)
   // Всё остальное время (включая азиатскую сессию с 05:00) разрешено для генерации сигналов
   if(dt.hour >= 0 && dt.hour < 5) return false;
   
   return true;
}

bool IsBullishPattern()
{
   double open[], close[], high[], low[];
   ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
   if(CopyOpen(_Symbol, PERIOD_H1, 0, 3, open) < 3) return false;
   if(CopyClose(_Symbol, PERIOD_H1, 0, 3, close) < 3) return false;
   if(CopyHigh(_Symbol, PERIOD_H1, 0, 3, high) < 3) return false;
   if(CopyLow(_Symbol, PERIOD_H1, 0, 3, low) < 3) return false;
   
   double body = MathAbs(close[1] - open[1]);
   double range = high[1] - low[1];
   if(range == 0) return false;
   
   if(close[2] < open[2] && close[1] > open[1] && close[1] > open[2] && open[1] < close[2]) return true;
   double lowerWick = MathMin(open[1], close[1]) - low[1];
   double upperWick = high[1] - MathMax(open[1], close[1]);
   if(lowerWick > body * 2 && upperWick < body * 0.5 && close[1] > open[1]) return true;
   if(close[1] > open[1] && body > range * 0.7) return true;
   if(close[1] > open[1]) return true;
   return false;
}

bool IsBearishPattern()
{
   double open[], close[], high[], low[];
   ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
   if(CopyOpen(_Symbol, PERIOD_H1, 0, 3, open) < 3) return false;
   if(CopyClose(_Symbol, PERIOD_H1, 0, 3, close) < 3) return false;
   if(CopyHigh(_Symbol, PERIOD_H1, 0, 3, high) < 3) return false;
   if(CopyLow(_Symbol, PERIOD_H1, 0, 3, low) < 3) return false;
   
   double body = MathAbs(close[1] - open[1]);
   double range = high[1] - low[1];
   if(range == 0) return false;
   
   if(close[2] > open[2] && close[1] < open[1] && close[1] < open[2] && open[1] > close[2]) return true;
   double upperWick = high[1] - MathMax(open[1], close[1]);
   double lowerWick = MathMin(open[1], close[1]) - low[1];
   if(upperWick > body * 2 && lowerWick < body * 0.5 && close[1] < open[1]) return true;
   if(close[1] < open[1] && body > range * 0.7) return true;
   if(close[1] < open[1]) return true;
   return false;
}

void FindStructureLevels()
{
   nearestResistance = 0;
   nearestSupport = 0;
   
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   if(CopyHigh(_Symbol, PERIOD_H4, 0, 100, high) < 100) return;
   if(CopyLow(_Symbol, PERIOD_H4, 0, 100, low) < 100) return;
   
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minResDist = 999999, minSupDist = 999999;
   
   for(int i = 2; i < 98; i++)
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


//+------------------------------------------------------------------+
//| Отправка Push-уведомления                                       |
//+------------------------------------------------------------------+
void SendPushNotification(string signal, double entry, double sl, double tp)
{
   string pushMsg = currentSymbol + " " + signal + "\n" +
                    "📍 Вход: " + DoubleToString(entry, symbolDigits) + "\n" +
                    "🛑 SL: " + DoubleToString(sl, symbolDigits) + "\n" +
                    "🎯 TP: " + DoubleToString(tp, symbolDigits) + "\n" +
                    "📊 Точность: " + DoubleToString(GetAccuracy(), 1) + "%";
   SendNotification(pushMsg);
}


//+------------------------------------------------------------------+
//| УМНЫЙ МУЛЬТИ-ТФ БЭКТЕСТ С ПОЛНОЙ ОПТИМИЗАЦИЕЙ И ЗАПИСЬЮ В ФАЙЛ  |
//+------------------------------------------------------------------+
void RunBacktest()
{
    Print("🚀 ФУНКЦИЯ RunBacktest ЗАПУЩЕНА!");
   // isBacktestRunning уже установлен в true в OnChartEvent
   
   Print("═══════════════════════════════════════════════════");
   Print("🧪 ЗАПУСК УМНОГО МУЛЬТИ-ТФ БЭКТЕСТА С ОПТИМИЗАЦИЕЙ");
   Print("═══════════════════════════════════════════════════");
   
   int availableBars = iBars(_Symbol, PERIOD_H1);
   if(availableBars < 200)
   {
      Print("❌ Недостаточно истории! Нужно минимум 200 баров H1.");
      isBacktestRunning = false;
      return;
   }
   
   int actualBars = MathMin(backtestBars, availableBars - 20);
   Print("📊 Будет проверено баров H1: ", actualBars);
   
   //=== ДИАПАЗОНЫ ОПТИМИЗАЦИИ (вокруг текущих input значений) ===
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
   int bestTotalTrades = 0;
   int bestWins = 0;
   
   //=== ПЕРЕМЕННЫЕ ДЛЯ СТАТИСТИКИ ПО ТФ (лучшей комбинации) ===
   int bestTotalH1 = 0, bestWinsH1 = 0, bestLossesH1 = 0;
   int bestTotalH4 = 0, bestWinsH4 = 0, bestLossesH4 = 0;
   int bestTotalD1 = 0, bestWinsD1 = 0, bestLossesD1 = 0;
   
   int totalCombinations = ArraySize(testThresholds) * ArraySize(testATRMultipliers) * 
                           ArraySize(testEMAPeriods) * ArraySize(testRSIPeriods);
   int currentCombination = 0;
   
   Print("🔄 Начало оптимизации: ", totalCombinations, " комбинаций...");
   
   //=== ЦИКЛ ОПТИМИЗАЦИИ ===
   for(int t = 0; t < ArraySize(testThresholds); t++)
   {
      for(int a = 0; a < ArraySize(testATRMultipliers); a++)
      {
         for(int e = 0; e < ArraySize(testEMAPeriods); e++)
         {
            for(int r = 0; r < ArraySize(testRSIPeriods); r++)
            {
               currentCombination++;
               if(currentCombination % 10 == 0)
                  Print("⏳ Оптимизация: ", currentCombination, " из ", totalCombinations);
               
               IndicatorParams testParams = optParams;
               testParams.signalThreshold = testThresholds[t];
               testParams.atrSLMult = testATRMultipliers[a];
               testParams.emaFastPeriod = testEMAPeriods[e];
               testParams.rsiPeriod = testRSIPeriods[r];
               
                              //=== РАЗДЕЛЬНАЯ СТАТИСТИКА ПО ТФ ===
               int totalH1 = 0, winsH1 = 0, lossesH1 = 0, canceledH1 = 0;
               int totalH4 = 0, winsH4 = 0, lossesH4 = 0, canceledH4 = 0;
               int totalD1 = 0, winsD1 = 0, lossesD1 = 0, canceledD1 = 0;
               
               // СЧЕТЧИКИ ДЛЯ ПРОВЕРКИ H4/D1 ТОЛЬКО 1 РАЗ ЗА БАР
               int lastCheckedH4 = -1;
               int lastCheckedD1 = -1;
               
               // Проход по истории
               for(int shift = actualBars; shift >= 5; shift--)
               {
                  if(shift % 4 != 0) continue; // Проверяем каждый 4-й бар H1 для скорости
                  
                  datetime barTime = iTime(_Symbol, PERIOD_H1, shift);
                  MqlDateTime dt;
                  TimeToStruct(barTime, dt);
                  
                  // МЯГКИЙ ФИЛЬТР СЕССИИ (пропускаем только мертвую ночь 00:00-05:00)
                  if(dt.hour >= 0 && dt.hour < 5) continue;
                  if(dt.day_of_week == 0 || dt.day_of_week == 6) continue;
                  if(dt.day_of_week == 5 && dt.hour >= 20) continue;
                  
                                    //=== ПРОВЕРКА H1 ===
                  if(UseSignalH1)
                  {
                     
                     double wSumH1 = AnalyzeSignal(PERIOD_H1, shift, hEMA50_H1, hEMA200_H1, hMACD_H1, hADX_H1, hRSI_H1,
                              hStoch_H1, hCCI_H1, hVol_H1, hOBV_H1, hBB_H1, hATR_H1, testParams).weightedSum;

                     if(MathAbs(wSumH1) >= testParams.signalThreshold && CheckCandleAndRSI(shift, PERIOD_H1, wSumH1, testParams))
                     {
                        SimulateTradeWithFile(shift, PERIOD_H1, wSumH1, testParams.atrSLMult, 
                         totalH1, winsH1, lossesH1, canceledH1, testParams, barTime, resultH1.candlesForecast);
                     }
                  }
                  
                  //=== ПРОВЕРКА H4 ===
                  if(UseSignalH4)
                  {
                     int currentH4 = iBarShift(_Symbol, PERIOD_H4, barTime);
                     if(currentH4 != lastCheckedH4 && currentH4 >= 2 && currentH4 < iBars(_Symbol, PERIOD_H4) - 3)
                     {
                        double wSumH4 = AnalyzeSignal(PERIOD_H4, currentH4, hEMA50_H4, hEMA200_H4, hMACD_H4, hADX_H4, hRSI_H4,
                              hStoch_H4, hCCI_H4, hVol_H4, hOBV_H4, hBB_H4, hATR_H4, testParams).weightedSum;

                        if(MathAbs(wSumH4) >= testParams.signalThreshold && CheckCandleAndRSI(currentH4, PERIOD_H4, wSumH4, testParams))
                        {
                           SimulateTradeWithFile(currentH4, PERIOD_H4, wSumH4, testParams.atrSLMult, 
                             totalH4, winsH4, lossesH4, canceledH4, testParams, barTime, resultH4.candlesForecast);
                        }
                        lastCheckedH4 = currentH4;
                     }
                  }
                  
                  //=== ПРОВЕРКА D1 ===
                  if(UseSignalD1)
                  {
                     int currentD1 = iBarShift(_Symbol, PERIOD_D1, barTime);
                     if(currentD1 != lastCheckedD1 && currentD1 >= 2 && currentD1 < iBars(_Symbol, PERIOD_D1) - 3)
                     {
                        double wSumD1 = AnalyzeSignal(PERIOD_D1, currentD1, hEMA50_D1, hEMA200_D1, hMACD_D1, hADX_D1, hRSI_D1,
                              hStoch_D1, hCCI_D1, hVol_D1, hOBV_D1, hBB_D1, hATR_D1, testParams).weightedSum;
                        if(MathAbs(wSumD1) >= testParams.signalThreshold && CheckCandleAndRSI(currentD1, PERIOD_D1, wSumD1, testParams))
                        {
                           SimulateTradeWithFile(currentD1, PERIOD_D1, wSumD1, testParams.atrSLMult, 
                             totalD1, winsD1, lossesD1, canceledD1, testParams, barTime, resultD1.candlesForecast);
                        }
                        lastCheckedD1 = currentD1;
                     }
                  }
               }
               
                              //=== ОБЩАЯ СТАТИСТИКА ===
               int totalTests = totalH1 + totalH4 + totalD1;
               int wins = winsH1 + winsH4 + winsD1;
               int losses = lossesH1 + lossesH4 + lossesD1;
               int canceled = canceledH1 + canceledH4 + canceledD1;
               
               // Реальная точность (без учёта аннулированных)
               int realTotal = wins + losses;
               
               if(realTotal >= 5)  // Минимум 5 реально исполненных сигналов
               {
                  double accuracy = wins * 100.0 / realTotal;  // Точность без аннулированных
                  if(accuracy > bestAccuracy || 
                     (accuracy == bestAccuracy && totalTests > bestTotalTrades))
                  {
                     bestAccuracy = accuracy;
                     bestParams = testParams;
                     bestTotalTrades = totalTests;
                     bestWins = wins;
                     
                     //=== СОХРАНЯЕМ СТАТИСТИКУ ПО ТФ ДЛЯ ЛУЧШЕЙ КОМБИНАЦИИ ===
                     bestTotalH1 = totalH1; bestWinsH1 = winsH1; bestLossesH1 = lossesH1;
                     bestTotalH4 = totalH4; bestWinsH4 = winsH4; bestLossesH4 = lossesH4;
                     bestTotalD1 = totalD1; bestWinsD1 = winsD1; bestLossesD1 = lossesD1;
                  }
               }
            }
         }
      }
   }
   
   //=== ВЫВОД РЕЗУЛЬТАТОВ ===
   Print("═══════════════════════════════════════════════════");
   Print("🏁 АВТО-ОПТИМИЗАЦИЯ ЗАВЕРШЕНА");
   Print("═══════════════════════════════════════════════════");
   Print("🏆 ЛУЧШАЯ КОНФИГУРАЦИЯ:");
   Print("   ▶ Порог взвешенной суммы: ", DoubleToString(bestParams.signalThreshold, 1));
   Print("   ▶ Множитель ATR для SL: ", DoubleToString(bestParams.atrSLMult, 1));
   Print("   ▶ Период EMA (быстрый): ", bestParams.emaFastPeriod);
   Print("   ▶ Период RSI: ", bestParams.rsiPeriod);
   Print("   ▶ Общая точность: ", DoubleToString(bestAccuracy, 1), "%");
   Print("   ▶ Сигналов: ", bestTotalTrades, " (WIN: ", bestWins, " | LOSS: ", bestTotalTrades - bestWins, ")");
   Print("═══════════════════════════════════════════════════");
   Print("📊 СТАТИСТИКА ПО ТАЙМФРЕЙМАМ (для ЛУЧШЕЙ комбинации):");
   if(bestTotalH1 > 0) 
   {
      int realH1 = bestWinsH1 + bestLossesH1;
      Print("   H1: ", DoubleToString(bestWinsH1 * 100.0 / realH1, 1), 
            "% (WIN:", bestWinsH1, " LOSS:", bestLossesH1, " CANCELED:", bestTotalH1 - realH1, ")");
   }
   if(bestTotalH4 > 0) 
   {
      int realH4 = bestWinsH4 + bestLossesH4;
      Print("   H4: ", DoubleToString(bestWinsH4 * 100.0 / realH4, 1), 
            "% (WIN:", bestWinsH4, " LOSS:", bestLossesH4, " CANCELED:", bestTotalH4 - realH4, ")");
   }
   if(bestTotalD1 > 0) 
   {
      int realD1 = bestWinsD1 + bestLossesD1;
      Print("   D1: ", DoubleToString(bestWinsD1 * 100.0 / realD1, 1), 
            "% (WIN:", bestWinsD1, " LOSS:", bestLossesD1, " CANCELED:", bestTotalD1 - realD1, ")");
   }
   
   Print("═══════════════════════════════════════════════════");
   Print("💡 КАК ПРИМЕНИТЬ ЛУЧШИЕ ПАРАМЕТРЫ:");
   Print("1. Кликните правой кнопкой по советнику → Свойства");
   Print("2. Вкладка 'Входные параметры' → установите значения:");
   Print("   ┌─────────────────────────────────────────────────────────┐");
   Print("   │ Порог взвешенной суммы:        ", DoubleToString(bestParams.signalThreshold, 1), "          │");
   Print("   │ Множитель ATR для SL:          ", DoubleToString(bestParams.atrSLMult, 1), "          │");
   Print("   │ Период быстрой EMA:            ", bestParams.emaFastPeriod, "            │");
   Print("   │ Период RSI:                    ", bestParams.rsiPeriod, "            │");
   Print("   └─────────────────────────────────────────────────────────┘");
   Print("3. Нажмите ОК — советник будет работать с лучшими параметрами");
   Print("═══════════════════════════════════════════════════");
   Print("📄 Отчёт сохранён в MQL5\\Files\\");
   Print("═══════════════════════════════════════════════════");
   
    // isBacktestRunning сбрасывается в OnChartEvent после завершения
   // UpdatePanel() и ChartRedraw() тоже вызываются там
}

//+------------------------------------------------------------------+
//| Проверка свечи и RSI на конкретном баре                          |
//+------------------------------------------------------------------+
bool CheckCandleAndRSI(int shift, ENUM_TIMEFRAMES tf, double wSum, IndicatorParams &params)
{
   double close[], open[], rsi[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(rsi, true);
   
   if(CopyClose(_Symbol, tf, shift, 3, close) < 3) return false;
   if(CopyOpen(_Symbol, tf, shift, 3, open) < 3) return false;
   
   int hRSI = iRSI(_Symbol, tf, params.rsiPeriod, PRICE_CLOSE);
   if(hRSI == INVALID_HANDLE) return false;
   if(CopyBuffer(hRSI, 0, shift, 3, rsi) < 3) return false;
   
   // Проверка свечи
   bool candleOk = false;
   if(wSum > 0 && close[1] > open[1]) candleOk = true;
   if(wSum < 0 && close[1] < open[1]) candleOk = true;
   
   // Проверка RSI
   bool rsiOk = false;
   if(wSum > 0 && rsi[1] < 85) rsiOk = true;
   if(wSum < 0 && rsi[1] > 25) rsiOk = true;
   
   return (candleOk && rsiOk);
}

//+------------------------------------------------------------------+
//| Симуляция сделки с ПРАВИЛЬНОЙ логикой "будущего"                 |
//+------------------------------------------------------------------+
bool SimulateTrade(int shift, ENUM_TIMEFRAMES tf, double wSum, double atrMult, 
                   int &totalTests, int &wins, int &losses, IndicatorParams &params)
{
   // Проверяем, что есть достаточно баров вперёд
   if(shift < 4) return false;
   
   //=== ПОЛУЧАЕМ ЦЕНУ ВХОДА (закрытие бара, на котором сигнал) ===
   double entry = iClose(_Symbol, tf, shift);
   if(entry == 0) return false;
   
   //=== ПОЛУЧАЕМ ATR на момент сигнала ===
   double atr[];
   ArraySetAsSeries(atr, true);
   int hATR = iATR(_Symbol, tf, params.atrPeriod);
   if(hATR == INVALID_HANDLE) return false;
   if(CopyBuffer(hATR, 0, shift, 2, atr) < 2) return false;
   double currentATR = atr[0];
   if(currentATR <= 0) return false;
   
   //=== ПОЛУЧАЕМ ЦЕНУ ЧЕРЕЗ 3 БАРА В БУДУЩЕМ ===
   // shift-3 = более новый бар (т.к. shift уменьшается к настоящему)
   double futureClose = iClose(_Symbol, tf, shift - 3);
   if(futureClose == 0) return false;
   
   //=== ОПРЕДЕЛЯЕМ НАПРАВЛЕНИЕ ===
   string direction = (wSum > 0) ? "BUY" : "SELL";
   
   //=== РАСЧЁТ ДВИЖЕНИЯ ЦЕНЫ ===
   // Для BUY: движение = futureClose - entry (положительное = цена выросла)
   // Для SELL: движение = entry - futureClose (положительное = цена упала)
   double movement = (direction == "BUY") ? 
                     (futureClose - entry) : 
                     (entry - futureClose);
   
   //=== КРИТЕРИЙ WIN/LOSS ===
   // WIN: цена прошла больше 1.5 ATR в нашу сторону
   // LOSS: цена прошла больше 1.5 ATR против нас
   double threshold = currentATR * atrMult * 1.5;
   
   if(movement > threshold) 
   { 
      wins++; 
      totalTests++; 
      return true; 
   }
   if(movement < -threshold) 
   { 
      losses++; 
      totalTests++; 
      return true; 
   }
   
   // Если движение в пределах порога — считаем нейтральным (не учитываем)
   return false;
}//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Расчёт срока жизни для бэктеста (копия основной функции)         |
//+------------------------------------------------------------------+
int CalculateSignalLifetimeForBacktest(ENUM_TIMEFRAMES tf, double weightedSum, int candlesForecast)
{
   int baseMinutes = 0;
   
   if(tf == PERIOD_H1) baseMinutes = 180;
   else if(tf == PERIOD_H4) baseMinutes = 480;
   else if(tf == PERIOD_D1) baseMinutes = 2880;
   else baseMinutes = 180;
   
   double absSum = MathAbs(weightedSum);
   double multiplier = 1.0;
   
   if(absSum >= 12.0) multiplier = 1.8;
   else if(absSum >= 10.0) multiplier = 1.6;
   else if(absSum >= 8.0) multiplier = 1.4;
   else if(absSum >= 6.0) multiplier = 1.2;
   else multiplier = 1.0;
   
   double forecastMultiplier = 0.8 + (candlesForecast * 0.07);
   if(forecastMultiplier > 1.5) forecastMultiplier = 1.5;
   if(forecastMultiplier < 0.8) forecastMultiplier = 0.8;
   
   int lifetime = (int)(baseMinutes * multiplier * forecastMultiplier);
   
   int minLifetime = 0, maxLifetime = 0;
   
   if(tf == PERIOD_H1)
   {
      minLifetime = 180;
      maxLifetime = 320;
   }
   else if(tf == PERIOD_H4)
   {
      minLifetime = 480;
      maxLifetime = 1200;
   }
   else if(tf == PERIOD_D1)
   {
      minLifetime = 2880;
      maxLifetime = 7440;
   }
   
   if(lifetime < minLifetime) lifetime = minLifetime;
   if(lifetime > maxLifetime) lifetime = maxLifetime;
   
   return lifetime;
}

//+------------------------------------------------------------------+
//| Симуляция сделки с ИСПРАВЛЕННОЙ логикой                          |
//+------------------------------------------------------------------+
bool SimulateTradeWithFile(int shift, ENUM_TIMEFRAMES tf, double wSum, double atrMult, 
                           int &totalTests, int &wins, int &losses, int &canceled,
                           IndicatorParams &params, datetime signalTime, int candlesForecast)
{
   //=== РАСЧЁТ ДИНАМИЧЕСКОГО СРОКА ЖИЗНИ ===
   int lifetimeMinutes = CalculateSignalLifetimeForBacktest(tf, wSum, candlesForecast);
   int lifetimeBars = 0;
   
   if(tf == PERIOD_H1) lifetimeBars = lifetimeMinutes / 60;
   else if(tf == PERIOD_H4) lifetimeBars = lifetimeMinutes / 240;
   else if(tf == PERIOD_D1) lifetimeBars = lifetimeMinutes / 1440;
   
   if(lifetimeBars < 1) lifetimeBars = 1;
   
   //=== ПОЛУЧАЕМ ЦЕНУ ВХОДА ===
   double entry = iClose(_Symbol, tf, shift);
   if(entry == 0) return false;
   
   //=== ПОЛУЧАЕМ ATR ===
   double atr[];
   ArraySetAsSeries(atr, true);
   int hATR = iATR(_Symbol, tf, params.atrPeriod);
   if(hATR == INVALID_HANDLE) return false;
   if(CopyBuffer(hATR, 0, shift, 2, atr) < 2) return false;
   double currentATR = atr[0];
   if(currentATR <= 0) return false;
   
   //=== РАСЧЁТ SL И TP ===
   double sl = 0, tp = 0;
   string direction = (wSum > 0) ? "BUY" : "SELL";
   double slDistance = currentATR * atrMult;
   
   if(direction == "BUY")
   {
      sl = entry - slDistance;
      tp = entry + (slDistance * 2.0);
   }
   else
   {
      sl = entry + slDistance;
      tp = entry - (slDistance * 2.0);
   }
   
   //=== ПРОВЕРКА В ПРЕДЕЛАХ СРОКА ЖИЗНИ ===
   bool entryReached = false;
   bool slHit = false;
   bool tpHit = false;
   double exitPrice = 0;
   string result = "";
   
   // Проверяем каждый бар в пределах срока жизни
   for(int i = 1; i <= lifetimeBars && (shift - i) >= 0; i++)
   {
      double barHigh = iHigh(_Symbol, tf, shift - i);
      double barLow = iLow(_Symbol, tf, shift - i);
      
      if(barHigh == 0 || barLow == 0) continue;
      
      //=== ЭТАП 1: ОЖИДАЕМ ДОСТИЖЕНИЯ ENTRY ===
      if(!entryReached)
      {
         if(direction == "BUY" && barHigh >= entry)
         {
            entryReached = true;
            // НЕ проверяем SL/TP на этом баре — ждём следующий бар
            // (ордер открылся в конце этого бара)
         }
         else if(direction == "SELL" && barLow <= entry)
         {
            entryReached = true;
            // НЕ проверяем SL/TP на этом баре — ждём следующий бар
         }
      }
      //=== ЭТАП 2: ОРДЕР ОТКРЫТ — ПРОВЕРЯЕМ SL/TP ===
      else
      {
         if(direction == "BUY")
         {
            // Приоритет: если на баре задеты и SL, и TP — считаем LOSS
            // (реалистичнее: SL ближе к entry, срабатывает первым)
            if(barLow <= sl)
            {
               slHit = true;
               exitPrice = sl;
               break;
            }
            if(barHigh >= tp)
            {
               tpHit = true;
               exitPrice = tp;
               break;
            }
         }
         else // SELL
         {
            if(barHigh >= sl)
            {
               slHit = true;
               exitPrice = sl;
               break;
            }
            if(barLow <= tp)
            {
               tpHit = true;
               exitPrice = tp;
               break;
            }
         }
      }
   }
   
   //=== ОПРЕДЕЛЕНИЕ РЕЗУЛЬТАТА ===
   if(!entryReached)
   {
      // Сигнал не исполнился за срок жизни
      canceled++;
      totalTests++;
      result = "CANCELED";
   }
   else if(slHit)
   {
      losses++;
      totalTests++;
      result = "LOSS";
   }
   else if(tpHit)
   {
      wins++;
      totalTests++;
      result = "WIN";
   }
   else
   {
      // Срок жизни истёк, но сигнал был исполнен и не закрылся
      // Считаем как нейтральный (не WIN и не LOSS)
      canceled++;
      totalTests++;
      result = "TIMEOUT";
      exitPrice = iClose(_Symbol, tf, MathMax(0, shift - lifetimeBars));
   }
   
   //=== ЗАПИСЬ В CSV ===
   string tfStr = "H1";
   if(tf == PERIOD_H4) tfStr = "H4";
   if(tf == PERIOD_D1) tfStr = "D1";
   
   double movement = 0;
   if(exitPrice > 0)
   {
      movement = (direction == "BUY") ? (exitPrice - entry) : (entry - exitPrice);
   }
   
   string reportFile = "backtest_" + currentSymbol + "_" + 
                       TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
   
   int handle = FileOpen(reportFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(handle != INVALID_HANDLE)
   {
      if(FileSize(handle) == 0)
      {
         FileWrite(handle, "SignalTime", "TF", "Direction", "Entry", "SL", "TP", 
                   "ExitPrice", "Result", "Movement", "Lifetime", "WeightedSum");
      }
      
      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle,
                TimeToString(signalTime, TIME_DATE|TIME_MINUTES),
                tfStr,
                direction,
                DoubleToString(entry, symbolDigits),
                DoubleToString(sl, symbolDigits),
                DoubleToString(tp, symbolDigits),
                DoubleToString(exitPrice, symbolDigits),
                result,
                DoubleToString(movement, symbolDigits),
                IntegerToString(lifetimeMinutes),
                DoubleToString(wSum, 1));
      
      FileClose(handle);
   }
   
   return true;
}



//+------------------------------------------------------------------+
//| Сохранение результата бэктеста                                  |
//+------------------------------------------------------------------+
void SaveBacktestResult(double accuracy, int total, int wins, int losses, double avgRR)
{
   string file = "backtest_results.csv";
   
   bool writeHeader = !FileIsExist(file);
   
   int handle = FileOpen(file, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE) return;
   
   FileSeek(handle, 0, SEEK_END);
   
   if(writeHeader)
      FileWrite(handle, "DateTime", "Symbol", "Bars", "Signals", "Wins", "Losses", "Accuracy", "AvgRR");
   
   FileWrite(handle,
             TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES),
             currentSymbol,
             IntegerToString(backtestBars),
             IntegerToString(total),
             IntegerToString(wins),
             IntegerToString(losses),
             DoubleToString(accuracy, 1),
             DoubleToString(avgRR, 2));
   
   FileClose(handle);
}

//+------------------------------------------------------------------+
//| Расчёт динамического срока жизни сигнала                         |
//+------------------------------------------------------------------+
int CalculateSignalLifetime(string mode, double weightedSum, int candlesForecast)
{
   //=== БАЗОВОЕ ВРЕМЯ ПО ТАЙМФРЕЙМУ ===
   int baseMinutes = 0;
   
   if(mode == "H1")
   {
      baseMinutes = 180;  // 3 часа для H1
   }
   else if(mode == "H4")
   {
      baseMinutes = 480;  // 8 часов для H4
   }
   else if(mode == "D1")
   {
      baseMinutes = 2880; // 48 часов (2 дня) для D1
   }
   else
   {
      baseMinutes = 180;  // По умолчанию 3 часа
   }
   
   //=== МНОЖИТЕЛЬ ОТ СИЛЫ СИГНАЛА ===
   // Чем сильнее сигнал (больше |weightedSum|), тем дольше живёт
   // Диапазон weightedSum: от 4.0 до ~15.0
   // Множитель: от 1.0 (слабый) до 1.8 (очень сильный)
   
   double absSum = MathAbs(weightedSum);
   double multiplier = 1.0;
   
   if(absSum >= 12.0) multiplier = 1.8;       // Очень сильный
   else if(absSum >= 10.0) multiplier = 1.6;  // Сильный
   else if(absSum >= 8.0) multiplier = 1.4;   // Выше среднего
   else if(absSum >= 6.0) multiplier = 1.2;   // Средний
   else multiplier = 1.0;                      // Слабый (порог 4.0)
   
   //=== МНОЖИТЕЛЬ ОТ ПРОГНОЗА ===
   // Чем больше свечей прогнозируется, тем дольше живёт
   // candlesForecast: от 1 до 10
   // Множитель: от 0.8 до 1.5
   
   double forecastMultiplier = 0.8 + (candlesForecast * 0.07);
   if(forecastMultiplier > 1.5) forecastMultiplier = 1.5;
   if(forecastMultiplier < 0.8) forecastMultiplier = 0.8;
   
   //=== ИТОГОВОЕ ВРЕМЯ ===
   int lifetime = (int)(baseMinutes * multiplier * forecastMultiplier);
   
   //=== ГРАНИЦЫ ===
   int minLifetime = 0, maxLifetime = 0;
   
   if(mode == "H1")
   {
      minLifetime = 180;   // Минимум 3 часа
      maxLifetime = 320;   // Максимум 5.3 часа
   }
   else if(mode == "H4")
   {
      minLifetime = 480;   // Минимум 8 часов
      maxLifetime = 1200;  // Максимум 20 часов
   }
   else if(mode == "D1")
   {
      minLifetime = 2880;  // Минимум 48 часов (2 дня)
      maxLifetime = 7440;  // Максимум 124 часа (5.2 дня)
   }
   
   if(lifetime < minLifetime) lifetime = minLifetime;
   if(lifetime > maxLifetime) lifetime = maxLifetime;
   
   return lifetime;
}

//+------------------------------------------------------------------+
//| Загрузка активного сигнала из файла при старте (ИСПРАВЛЕННАЯ)   |
//+------------------------------------------------------------------+
void LoadActiveSignal()
{
   Print("🔍 Проверяю активные сигналы в файле: ", logFileName);
   
   if(!FileIsExist(logFileName))
   {
      Print("📂 Файл сигналов не найден — активных сигналов нет");
      return;
   }
   
   int handle = FileOpen(logFileName, FILE_READ|FILE_CSV|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Не удалось открыть файл сигналов");
      return;
   }
   
   // Читаем заголовок
   string header = FileReadString(handle);
   
   // Читаем все строки и берём последнюю
   datetime lastTime = 0;
   string lastMode = "";
   string lastDir = "";
   double lastEntry = 0;
   double lastSL = 0;
   double lastTP = 0;
   double lastWeightedSum = 0;
   
   while(!FileIsEnding(handle))
   {
      string timeStr = FileReadString(handle);
      if(timeStr == "") break;
      
      string symbol = FileReadString(handle);
      string mode = FileReadString(handle);
      string dir = FileReadString(handle);
      string entryStr = FileReadString(handle);
      string slStr = FileReadString(handle);
      string tpStr = FileReadString(handle);
      string wsStr = FileReadString(handle);
      string atrStr = FileReadString(handle);
      string rrStr = FileReadString(handle);
      
      datetime sigTime = StringToTime(timeStr);
      
      lastTime = sigTime;
      lastMode = mode;
      lastDir = dir;
      lastEntry = StringToDouble(entryStr);
      lastSL = StringToDouble(slStr);
      lastTP = StringToDouble(tpStr);
      lastWeightedSum = StringToDouble(wsStr);
   }
   FileClose(handle);
   
   if(lastTime == 0 || lastEntry == 0)
   {
      Print("📂 Файл сигналов пустой");
      return;
   }
   
   Print("📊 Найден последний сигнал:");
   Print("   Время: ", TimeToString(lastTime, TIME_DATE|TIME_MINUTES));
   Print("   Режим: ", lastMode);
   Print("   Направление: ", lastDir);
   Print("   Entry: ", DoubleToString(lastEntry, symbolDigits));
   Print("   SL: ", DoubleToString(lastSL, symbolDigits));
   Print("   TP: ", DoubleToString(lastTP, symbolDigits));
   
   //=== ПРОВЕРКА: не был ли сигнал уже отработан ===
   if(IsSignalAlreadyProcessed(lastTime, lastMode, lastDir))
   {
      Print("⏭️ Сигнал уже был отработан — пропускаем");
      return;
   }
   
   //=== ПРОВЕРКА: не протух ли сигнал ===
   int hoursPassed = (int)((TimeCurrent() - lastTime) / 3600);
   if(hoursPassed > 24)
   {
      Print("⏰ Сигнал протух (прошло ", hoursPassed, " часов) — пропускаем");
      return;
   }
   
   //=== ВОССТАНАВЛИВАЕМ АКТИВНЫЙ СИГНАЛ ===
   lastEntryPrice = lastEntry;
   lastDirection = lastDir;
   lastSignalCheckTime = lastTime;
   signalChecked = false;
   signalWasExecuted = false;
   activeMode = lastMode;
   
   //=== УСТАНОВКА УРОВНЕЙ ДЛЯ ВСЕХ РЕЖИМОВ ===
   recEntry = lastEntry;
   recSL = lastSL;
   recTP = lastTP;
   recOrderType = (lastDir == "BUY") ? "BUY MARKET" : "SELL MARKET";
   
   // Устанавливаем уровни для конкретного режима
   if(lastMode == "H1")
   {
      recEntryH1 = lastEntry; recSLH1 = lastSL; recTPH1 = lastTP;
      recOrderTypeH1 = recOrderType;
      lastSignalH1 = (lastDir == "BUY") ? "CONFIRMED BUY 🟢 [H1]" : "CONFIRMED SELL 🔴 [H1]";
      signalFixedH1 = true;
   }
   else if(lastMode == "H4")
   {
      recEntryH4 = lastEntry; recSLH4 = lastSL; recTPH4 = lastTP;
      recOrderTypeH4 = recOrderType;
      lastSignalH4 = (lastDir == "BUY") ? "CONFIRMED BUY 🟢 [H4]" : "CONFIRMED SELL 🔴 [H4]";
      signalFixedH4 = true;
   }
   else if(lastMode == "D1")
   {
      recEntryD1 = lastEntry; recSLD1 = lastSL; recTPD1 = lastTP;
      recOrderTypeD1 = recOrderType;
      lastSignalD1 = (lastDir == "BUY") ? "CONFIRMED BUY 🟢 [D1]" : "CONFIRMED SELL 🔴 [D1]";
      signalFixedD1 = true;
   }
   
   //=== ДОБАВЛЯЕМ В ИСТОРИЮ ===
   AddToHistory(lastMode, lastDir, lastEntry, lastSL, lastTP, lastWeightedSum);
   
   //=== УВЕЛИЧИВАЕМ СЧЁТЧИК СИГНАЛОВ ===
   totalSignals++;
   
   // Проверяем, исполнился ли сигнал
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   if(lastDir == "BUY" && currentAsk >= lastEntry) signalWasExecuted = true;
   if(lastDir == "SELL" && currentBid <= lastEntry) signalWasExecuted = true;
   
   Print("✅ Активный сигнал восстановлен!");
   Print("   Исполнен: ", signalWasExecuted ? "ДА" : "НЕТ");
   Print("   Добавлен в историю");
   Print("   totalSignals = ", totalSignals);
}
//+------------------------------------------------------------------+
//| Проверка: был ли сигнал уже отработан                           |
//+------------------------------------------------------------------+
bool IsSignalAlreadyProcessed(datetime signalTime, string mode, string direction)
{
   if(!FileIsExist(resultFileName)) return false;
   
   int handle = FileOpen(resultFileName, FILE_READ|FILE_CSV|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE) return false;
   
   // Читаем заголовок
   string header = FileReadString(handle);
   
   // Ищем сигнал с таким же временем и режимом
   while(!FileIsEnding(handle))
   {
      string timeStr = FileReadString(handle);
      if(timeStr == "") break;
      
      string symbol = FileReadString(handle);
      string resMode = FileReadString(handle);
      string resDir = FileReadString(handle);
      // Остальные поля не важны
      
      datetime resTime = StringToTime(timeStr);
      
      // Если нашли совпадение по времени (с точностью до минуты) и режиму
      if(MathAbs((int)(resTime - signalTime)) < 60 && resMode == mode && resDir == direction)
      {
         FileClose(handle);
         return true;
      }
   }
   FileClose(handle);
   return false;
}

//+------------------------------------------------------------------+
//| Удаление сигнала из файла после отработки                        |
//+------------------------------------------------------------------+
void RemoveSignalFromLog(datetime signalTime, string mode, string direction)
{
   if(!FileIsExist(logFileName)) return;
   
   // Читаем все строки кроме той, что нужно удалить
   string lines[];
   int lineCount = 0;
   
   int readHandle = FileOpen(logFileName, FILE_READ|FILE_CSV|FILE_ANSI, ';');
   if(readHandle == INVALID_HANDLE) return;
   
   // Читаем заголовок
   string header = FileReadString(readHandle);
   
   while(!FileIsEnding(readHandle))
   {
      string timeStr = FileReadString(readHandle);
      if(timeStr == "") break;
      
      string symbol = FileReadString(readHandle);
      string resMode = FileReadString(readHandle);
      string resDir = FileReadString(readHandle);
      string entryStr = FileReadString(readHandle);
      string slStr = FileReadString(readHandle);
      string tpStr = FileReadString(readHandle);
      string wsStr = FileReadString(readHandle);
      string atrStr = FileReadString(readHandle);
      string rrStr = FileReadString(readHandle);
      
      datetime resTime = StringToTime(timeStr);
      
      // Пропускаем строку, которую нужно удалить
      if(MathAbs((int)(resTime - signalTime)) < 60 && resMode == mode && resDir == direction)
      {
         Print("🗑️ Удаляю отработанный сигнал из лога: ", timeStr, " ", mode, " ", direction);
         continue;
      }
      
      // Сохраняем остальные строки
      ArrayResize(lines, lineCount + 1);
      lines[lineCount] = timeStr + ";" + symbol + ";" + resMode + ";" + resDir + ";" +
                         entryStr + ";" + slStr + ";" + tpStr + ";" + wsStr + ";" + atrStr + ";" + rrStr;
      lineCount++;
   }
   FileClose(readHandle);
   
   // Перезаписываем файл
   int writeHandle = FileOpen(logFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(writeHandle == INVALID_HANDLE) return;
   
   FileWrite(writeHandle, "DateTime", "Symbol", "Mode", "Direction", 
             "Entry", "SL", "TP", "WeightedSum", "ATR", "RR_Ratio");
   
   for(int i = 0; i < lineCount; i++)
   {
      string parts[];
      int count = StringSplit(lines[i], ';', parts);
      if(count >= 10)
      {
         FileWrite(writeHandle, parts[0], parts[1], parts[2], parts[3],
                   parts[4], parts[5], parts[6], parts[7], parts[8], parts[9]);
      }
   }
   FileClose(writeHandle);
}

//+------------------------------------------------------------------+
//| ОСНОВНОЙ АНАЛИЗ (ИСПРАВЛЕННЫЙ — без дублей)                     |
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
   
   //=== АНАЛИЗ ТАЙМФРЕЙМОВ (на каждом тике — для отображения) ===
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
      signalFixedH1 = false;  // Сбрасываем фиксацию
      CalculateLevelsForMode("H1", resultH1, hEMA50_H1, hBB_H1, hRSI_H1,
                             recEntryH1, recSLH1, recTPH1, recOrderTypeH1);
      if(recEntryH1 > 0) signalFixedH1 = true;
   }
   if(newBarH4 && UseSignalH4)
   {
      signalFixedH4 = false;
      CalculateLevelsForMode("H4", resultH4, hEMA50_H4, hBB_H4, hRSI_H4,
                             recEntryH4, recSLH4, recTPH4, recOrderTypeH4);
      if(recEntryH4 > 0) signalFixedH4 = true;
   }
   if(newBarD1 && UseSignalD1)
   {
      signalFixedD1 = false;
      CalculateLevelsForMode("D1", resultD1, hEMA50_D1, hBB_D1, hRSI_D1,
                             recEntryD1, recSLD1, recTPD1, recOrderTypeD1);
      if(recEntryD1 > 0) signalFixedD1 = true;
   }
   
   UpdatePanel();
   
   //=== ПРОВЕРКА ИСПОЛНЕНИЯ АКТИВНОГО СИГНАЛА (на каждом тике) ===
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
   
   //=== H1 ===
   if(UseSignalH1 && newBarH1)
   {
      // Защита: если уже есть активный сигнал — не создаём новый
      if(lastEntryPrice == 0 || signalChecked)
      {
         string sigH1 = CheckEntryForTF(PERIOD_H1, resultH1, hRSI_H1, "H1");
         double currentStrengthH1 = resultH1.weightedSum;
         
         if(sigH1 != "" && sigH1 != lastSignalH1)
         {
            lastSignalH1 = sigH1;
            lastSignalStrengthH1 = currentStrengthH1;
            lastSignalTimeH1 = TimeCurrent();
            totalSignals++;
            lastEntryPrice = recEntryH1;
            lastDirection = (StringFind(sigH1, "BUY") >= 0) ? "BUY" : "SELL";
            lastSignalCheckTime = TimeCurrent();
            signalChecked = false;
            signalWasExecuted = false;
            activeMode = "H1";
            
            int lifetimeH1 = CalculateSignalLifetime("H1", currentStrengthH1, resultH1.candlesForecast);
            signalExpirationTime = TimeCurrent() + lifetimeH1 * 60;
            
            if(UseSoundAlert) PlaySound("alert.wav");
            if(UsePushNotify) SendPushNotification(sigH1, recEntryH1, recSLH1, recTPH1);
            
            Print("🔔 СИГНАЛ H1: ", sigH1, " (сила: ", DoubleToString(currentStrengthH1, 1), ")");
            Print("⏰ Срок жизни: ", lifetimeH1, " мин (", DoubleToString(lifetimeH1 / 60.0, 1), " часов)");
            
            AddToHistory("H1", lastDirection, recEntryH1, recSLH1, recTPH1, currentStrengthH1);
            LogSignal("H1", lastDirection, recEntryH1, recSLH1, recTPH1, 
                      currentStrengthH1, resultH1.atrValue);
         }
      }
   }
   
   //=== H4 ===
   if(UseSignalH4 && newBarH4)
   {
      if(lastEntryPrice == 0 || signalChecked)
      {
         string sigH4 = CheckEntryForTF(PERIOD_H4, resultH4, hRSI_H4, "H4");
         double currentStrengthH4 = resultH4.weightedSum;
         
         if(sigH4 != "" && sigH4 != lastSignalH4)
         {
            lastSignalH4 = sigH4;
            lastSignalStrengthH4 = currentStrengthH4;
            lastSignalTimeH4 = TimeCurrent();
            totalSignals++;
            lastEntryPrice = recEntryH4;
            lastDirection = (StringFind(sigH4, "BUY") >= 0) ? "BUY" : "SELL";
            lastSignalCheckTime = TimeCurrent();
            signalChecked = false;
            signalWasExecuted = false;
            activeMode = "H4";
            
            int lifetimeH4 = CalculateSignalLifetime("H4", currentStrengthH4, resultH4.candlesForecast);
            signalExpirationTime = TimeCurrent() + lifetimeH4 * 60;
            
            if(UseSoundAlert) PlaySound("alert2.wav");
            if(UsePushNotify) SendPushNotification(sigH4, recEntryH4, recSLH4, recTPH4);
            
            Print("🔔 СИГНАЛ H4: ", sigH4, " (сила: ", DoubleToString(currentStrengthH4, 1), ")");
            Print("⏰ Срок жизни: ", lifetimeH4, " мин (", DoubleToString(lifetimeH4 / 60.0, 1), " часов)");
            
            AddToHistory("H4", lastDirection, recEntryH4, recSLH4, recTPH4, currentStrengthH4);
            LogSignal("H4", lastDirection, recEntryH4, recSLH4, recTPH4, 
                      currentStrengthH4, resultH4.atrValue);
         }
      }
   }
   
   //=== D1 ===
   if(UseSignalD1 && newBarD1)
   {
      if(lastEntryPrice == 0 || signalChecked)
      {
         string sigD1 = CheckEntryForTF(PERIOD_D1, resultD1, hRSI_D1, "D1");
         double currentStrengthD1 = resultD1.weightedSum;
         
         if(sigD1 != "" && sigD1 != lastSignalD1)
         {
            lastSignalD1 = sigD1;
            lastSignalStrengthD1 = currentStrengthD1;
            lastSignalTimeD1 = TimeCurrent();
            totalSignals++;
            lastEntryPrice = recEntryD1;
            lastDirection = (StringFind(sigD1, "BUY") >= 0) ? "BUY" : "SELL";
            lastSignalCheckTime = TimeCurrent();
            signalChecked = false;
            signalWasExecuted = false;
            activeMode = "D1";
            
            int lifetimeD1 = CalculateSignalLifetime("D1", currentStrengthD1, resultD1.candlesForecast);
            signalExpirationTime = TimeCurrent() + lifetimeD1 * 60;
            
            if(UseSoundAlert) PlaySound("ok.wav");
            if(UsePushNotify) SendPushNotification(sigD1, recEntryD1, recSLD1, recTPD1);
            
            Print("🔔 СИГНАЛ D1: ", sigD1, " (сила: ", DoubleToString(currentStrengthD1, 1), ")");
            Print("⏰ Срок жизни: ", lifetimeD1, " мин (", DoubleToString(lifetimeD1 / 24.0 / 60.0, 1), " дней)");
            
            AddToHistory("D1", lastDirection, recEntryD1, recSLD1, recTPD1, currentStrengthD1);
            LogSignal("D1", lastDirection, recEntryD1, recSLD1, recTPD1, 
                      currentStrengthD1, resultD1.atrValue);
         }
      }
   }
   
   if(DrawLevels) DrawLevelsOnChart();
   ChartRedraw();
}
//+------------------------------------------------------------------+
//| Проверка результата сигнала по SL/TP (с проверкой исполнения)   |
//+------------------------------------------------------------------+
void CheckSignalResult()
{
   // Если нет активного сигнала — выходим
   if(lastEntryPrice == 0 || signalChecked) return;
   if(recSL == 0 || recTP == 0) return;
   
   if(TimeCurrent() > signalExpirationTime)
   {
      if(!signalWasExecuted)
      {
         canceledSignals++;
         totalSignals--;
         int elapsedMinutes = (int)((TimeCurrent() - lastSignalCheckTime) / 60);
         Print("⏰ Сигнал ИСТЁК (не исполнился за ", elapsedMinutes, " мин). Аннулирован.");
         Print("📊 Всего аннулировано: ", canceledSignals);
         
         //=== СБРОС СОСТОЯНИЯ ===
         lastEntryPrice = 0;
         signalChecked = false;
         signalWasExecuted = false;
         
         // Сбрасываем сигнал и фиксацию
         if(activeMode == "H1") { lastSignalH1 = ""; signalFixedH1 = false; }
         else if(activeMode == "H4") { lastSignalH4 = ""; signalFixedH4 = false; }
         else if(activeMode == "D1") { lastSignalD1 = ""; signalFixedD1 = false; }
         
         // Удаляем из лога
         RemoveSignalFromLog(lastSignalCheckTime, activeMode, lastDirection);
         
         activeMode = "";
         return;
      }
   }
   
   //=== ПРОВЕРКА ИСПОЛНЕНИЯ ===
   if(!signalWasExecuted)
   {
      // Сигнал ещё не исполнился — ждём
      return;
   }
   
   //=== ПРОВЕРКА SL/TP (только для исполненных сигналов) ===
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   if(CopyHigh(_Symbol, PERIOD_H1, 0, 5, high) < 5) return;
   if(CopyLow(_Symbol, PERIOD_H1, 0, 5, low) < 5) return;
   
   double maxHigh = high[0];
   double minLow = low[0];
   for(int i = 1; i < 5; i++)
   {
      if(high[i] > maxHigh) maxHigh = high[i];
      if(low[i] < minLow) minLow = low[i];
   }
   
   string result = "";
   double movement = 0;
   double exitPrice = 0;
   
   if(lastDirection == "BUY")
   {
      if(minLow <= recSL)
      {
         result = "LOSS";
         exitPrice = recSL;
         movement = recSL - lastEntryPrice;
         Print("🛑 BUY сигнал закрыт по STOP LOSS: ", DoubleToString(recSL, symbolDigits));
      }
      else if(maxHigh >= recTP)
      {
         result = "WIN";
         exitPrice = recTP;
         movement = recTP - lastEntryPrice;
         Print("🎯 BUY сигнал закрыт по TAKE PROFIT: ", DoubleToString(recTP, symbolDigits));
      }
   }
   else if(lastDirection == "SELL")
   {
      if(maxHigh >= recSL)
      {
         result = "LOSS";
         exitPrice = recSL;
         movement = lastEntryPrice - recSL;
         Print("🛑 SELL сигнал закрыт по STOP LOSS: ", DoubleToString(recSL, symbolDigits));
      }
      else if(minLow <= recTP)
      {
         result = "WIN";
         exitPrice = recTP;
         movement = lastEntryPrice - recTP;
         Print("🎯 SELL сигнал закрыт по TAKE PROFIT: ", DoubleToString(recTP, symbolDigits));
      }
   }
   
   if(result != "")
   {
      if(result == "WIN")
      {
         winningSignals++;
         Print("✅ СИГНАЛ ВЕРНЫЙ! Движение: ", DoubleToString(movement, symbolDigits));
      }
      else
      {
         losingSignals++;
         Print("❌ СИГНАЛ НЕВЕРНЫЙ! Движение: ", DoubleToString(movement, symbolDigits));
      }
      
      signalChecked = true;
      Print("📊 ТОЧНОСТЬ: ", DoubleToString(GetAccuracy(), 1), "% (", 
            winningSignals, "/", (winningSignals + losingSignals), ")");
      
      LogResult(activeMode, lastDirection, lastEntryPrice, exitPrice, result, movement);
      UpdateHistoryResult(result, movement);
      SaveStats();
      
      //=== НОВОЕ: удаляем отработанный сигнал из лога ===
      RemoveSignalFromLog(lastSignalCheckTime, activeMode, lastDirection);
      
      //=== СБРОС СОСТОЯНИЯ ===
      lastEntryPrice = 0;
      signalWasExecuted = false;
      
      // Сбрасываем сигнал и фиксацию для активного режима
      if(activeMode == "H1") { lastSignalH1 = ""; signalFixedH1 = false; }
      else if(activeMode == "H4") { lastSignalH4 = ""; signalFixedH4 = false; }
      else if(activeMode == "D1") { lastSignalD1 = ""; signalFixedD1 = false; }
      
      activeMode = "";
   }
}

double GetAccuracy()
{
   int totalDecided = winningSignals + losingSignals;
   if(totalDecided == 0) return 0;
   return winningSignals * 100.0 / totalDecided;
}

//+------------------------------------------------------------------+
//| ПРОВЕРКА ВХОДА С ОТКЛЮЧАЕМЫМИ ФИЛЬТРАМИ                         |
//+------------------------------------------------------------------+
string CheckEntryForTF(ENUM_TIMEFRAMES tf, IndicatorVotes &resultMain, 
                       int hRSI, string modeName)
{
   // Базовое правило: сильный сигнал
   if(resultMain.weightedSum < 4.0 && resultMain.weightedSum > -4.0) return "";
   
   //=== ФИЛЬТР RSI ===
   if(FilterRSI)
   {
      double rsi[];
      ArraySetAsSeries(rsi, true);
      if(CopyBuffer(hRSI, 0, 0, 3, rsi) < 3) return "";
      
      if(resultMain.weightedSum > 0 && rsi[1] > 85) return "";
      if(resultMain.weightedSum < 0 && rsi[1] < 15) return "";
   }
   
   //=== ФИЛЬТР СВЕЧНОГО ПАТТЕРНА ===
   if(FilterCandle)
   {
      double open[], close[], high[], low[];
      ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
      ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
      if(CopyOpen(_Symbol, tf, 0, 3, open) < 3) return "";
      if(CopyClose(_Symbol, tf, 0, 3, close) < 3) return "";
      if(CopyHigh(_Symbol, tf, 0, 3, high) < 3) return "";
      if(CopyLow(_Symbol, tf, 0, 3, low) < 3) return "";
      
      bool candleOk = false;
      if(resultMain.weightedSum > 0 && close[1] > open[1]) candleOk = true;
      if(resultMain.weightedSum < 0 && close[1] < open[1]) candleOk = true;
      
      if(!candleOk) return "";
   }
   
   //=== ФИЛЬТР ЗАПАЗДЫВАНИЯ ===
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
         
         // Если цена уже прошла больше 2.0 ATR от EMA50 — сигнал запаздывает
         if(resultMain.weightedSum > 0 && (currentPrice - ema50[0]) > atr * 2.0)
         {
            return "";
         }
         if(resultMain.weightedSum < 0 && (ema50[0] - currentPrice) > atr * 2.0)
         {
            return "";
         }
      }
   }
   
   //=== ФИЛЬТР СТРУКТУРНЫХ УРОВНЕЙ ===
   if(FilterStructure)
   {
      if(nearestResistance > 0 && nearestSupport > 0)
      {
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double roomUp = nearestResistance - currentPrice;
         double roomDown = currentPrice - nearestSupport;
         
         if(resultMain.weightedSum > 0 && roomUp < resultMain.atrValue * 1.0) return "";
         if(resultMain.weightedSum < 0 && roomDown < resultMain.atrValue * 1.0) return "";
      }
   }
   
   if(resultMain.weightedSum > 0)
      return "CONFIRMED BUY 🟢 [" + modeName + "]";
   else
      return "CONFIRMED SELL 🔴 [" + modeName + "]";
}


//+------------------------------------------------------------------+
//| ОБЩАЯ ПРОВЕРКА (вызывает проверку для каждого включённого ТФ)   |
//+------------------------------------------------------------------+
string CheckEntryConfirmation()
{
      //=== ОБЩИЕ ФИЛЬТРЫ (отключаемые) ===
   if(FilterNews)
   {
      if(IsNewsTime()) 
      {
         filterNews = false;
         return "";
      }
      filterNews = true;
   }
   else filterNews = true;
   
   if(FilterVolatility)
   {
      if(!IsVolatilityOk()) 
      {
         filterVolatility = false;
         return "";
      }
      filterVolatility = true;
   }
   else filterVolatility = true;
   
   if(FilterSession)
   {
      if(!IsGoodSession()) 
      {
         filterSession = false;
         return "";
      }
      filterSession = true;
   }
   else filterSession = true;
   
   filterCandle = FilterCandle;
   filterRSI = FilterRSI;
   filterStructure = FilterStructure;
    
   //=== ПРОВЕРКА КАЖДОГО РЕЖИМА ОТДЕЛЬНО ===
   string signal = "";
   
   if(UseSignalH1)
   {
      signal = CheckEntryForTF(PERIOD_H1, resultH1, hRSI_H1, "H1");
      if(signal != "") return signal;
   }
   
   if(UseSignalH4)
   {
      signal = CheckEntryForTF(PERIOD_H4, resultH4, hRSI_H4, "H4");
      if(signal != "") return signal;
   }
   
   if(UseSignalD1)
   {
      signal = CheckEntryForTF(PERIOD_D1, resultD1, hRSI_D1, "D1");
      if(signal != "") return signal;
   }
   
   return "";
}

//+------------------------------------------------------------------+
//| РАСЧЕТ УРОВНЕЙ: ОТЛОЖЕННЫЕ ОРДЕРА (статичные уровни)            |
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
   
   //=== ВАЖНО: используем ЦЕНУ ЗАКРЫТИЯ ПОСЛЕДНЕЙ СВЕЧИ (не текущую!) ===
   double close[];
   ArraySetAsSeries(close, true);
   if(CopyClose(_Symbol, tf, 0, 2, close) < 2) return;
   double lastClose = close[1];  // Цена закрытия последней ЗАКРЫТОЙ свечи
   
   double slDistance = result.atrValue * ATR_SL_Mult;
   
   //=== ЛОГИКА ОТЛОЖЕННЫХ ОРДЕРОВ ===
   if(StringFind(signal, "BUY") >= 0)
   {
      if(rsi[1] < 45)
      {
         //=== BUY LIMIT: вход на коррекции (ниже текущей цены) ===
         outType = "BUY LIMIT";
         double correctionEntry = MathMax(ema50[1], bbMiddle[1]);
         
         // Entry = зона коррекции (EMA50 или BB middle)
         outEntry = correctionEntry;
      }
      else
      {
         //=== BUY STOP: вход на пробое (выше текущей цены) ===
         outType = "BUY STOP";
         double high[];
         ArraySetAsSeries(high, true);
         if(CopyHigh(_Symbol, tf, 0, 3, high) < 3) return;
         
         // Entry = чуть выше последнего хая
         outEntry = high[1] + result.atrValue * 0.1;
      }
      
      // SL всегда ниже входа
      outSL = outEntry - slDistance;
      
      // TP с учётом прогноза свечей
      double tpMultiplier = 0;
      if(tf == PERIOD_H1) tpMultiplier = 1.0 + (result.candlesForecast * 0.3);
      else if(tf == PERIOD_H4) tpMultiplier = 1.5 + (result.candlesForecast * 0.4);
      else if(tf == PERIOD_D1) tpMultiplier = 2.0 + (result.candlesForecast * 0.5);
      else tpMultiplier = 1.5;
      
      outTP = outEntry + (slDistance * tpMultiplier);
      
      // Проверка R:R
      double rrRatio = MathAbs(outTP - outEntry) / slDistance;
      if(rrRatio < 1.5)
      {
         outEntry = 0; outSL = 0; outTP = 0; outType = "";
         return;
      }
   }
   else // SELL
   {
      if(rsi[1] > 55)
      {
         //=== SELL LIMIT: вход на коррекции (выше текущей цены) ===
         outType = "SELL LIMIT";
         double correctionEntry = MathMin(ema50[1], bbMiddle[1]);
         
         // Entry = зона коррекции
         outEntry = correctionEntry;
      }
      else
      {
         //=== SELL STOP: вход на пробое (ниже текущей цены) ===
         outType = "SELL STOP";
         double low[];
         ArraySetAsSeries(low, true);
         if(CopyLow(_Symbol, tf, 0, 3, low) < 3) return;
         
         // Entry = чуть ниже последнего лоу
         outEntry = low[1] - result.atrValue * 0.1;
      }
      
      // SL всегда выше входа
      outSL = outEntry + slDistance;
      
      // TP с учётом прогноза свечей
      double tpMultiplier = 0;
      if(tf == PERIOD_H1) tpMultiplier = 1.0 + (result.candlesForecast * 0.3);
      else if(tf == PERIOD_H4) tpMultiplier = 1.5 + (result.candlesForecast * 0.4);
      else if(tf == PERIOD_D1) tpMultiplier = 2.0 + (result.candlesForecast * 0.5);
      else tpMultiplier = 1.5;
      
      outTP = outEntry - (slDistance * tpMultiplier);
      
      // Проверка R:R
      double rrRatio = MathAbs(outEntry - outTP) / slDistance;
      if(rrRatio < 1.5)
      {
         outEntry = 0; outSL = 0; outTP = 0; outType = "";
         return;
      }
   }
   
   // Финальная проверка
   bool levelsOk = false;
   if(StringFind(signal, "BUY") >= 0)
      levelsOk = (outSL < outEntry && outTP > outEntry);
   else
      levelsOk = (outSL > outEntry && outTP < outEntry);
   
   if(!levelsOk)
   {
      outEntry = 0; outSL = 0; outTP = 0; outType = "";
      return;
   }
   
   outEntry = NormalizeDouble(outEntry, symbolDigits);
   outSL = NormalizeDouble(outSL, symbolDigits);
   outTP = NormalizeDouble(outTP, symbolDigits);
}

//+------------------------------------------------------------------+
//| РАСЧЕТ УРОВНЕЙ ДЛЯ ВСЕХ АКТИВНЫХ РЕЖИМОВ                        |
//+------------------------------------------------------------------+
void CalculateRecommendedLevels()
{
   // Сбрасываем
   recEntryH1 = 0; recSLH1 = 0; recTPH1 = 0; recOrderTypeH1 = "";
   recEntryH4 = 0; recSLH4 = 0; recTPH4 = 0; recOrderTypeH4 = "";
   recEntryD1 = 0; recSLD1 = 0; recTPD1 = 0; recOrderTypeD1 = "";
   
   // Считаем для каждого включённого режима
   if(UseSignalH1)
      CalculateLevelsForMode("H1", resultH1, hEMA50_H1, hBB_H1, hRSI_H1,
                             recEntryH1, recSLH1, recTPH1, recOrderTypeH1);
   
   if(UseSignalH4)
      CalculateLevelsForMode("H4", resultH4, hEMA50_H4, hBB_H4, hRSI_H4,
                             recEntryH4, recSLH4, recTPH4, recOrderTypeH4);
   
   if(UseSignalD1)
      CalculateLevelsForMode("D1", resultD1, hEMA50_D1, hBB_D1, hRSI_D1,
                             recEntryD1, recSLD1, recTPD1, recOrderTypeD1);
   
   // Активный режим — последний сработавший (приоритет: D1 > H4 > H1)
   activeMode = "";
   recEntry = 0; recSL = 0; recTP = 0; recOrderType = "";
   
   if(recEntryD1 > 0) { activeMode = "D1"; recEntry = recEntryD1; recSL = recSLD1; recTP = recTPD1; recOrderType = recOrderTypeD1; }
   else if(recEntryH4 > 0) { activeMode = "H4"; recEntry = recEntryH4; recSL = recSLH4; recTP = recTPH4; recOrderType = recOrderTypeH4; }
   else if(recEntryH1 > 0) { activeMode = "H1"; recEntry = recEntryH1; recSL = recSLH1; recTP = recTPH1; recOrderType = recOrderTypeH1; }
}

//+------------------------------------------------------------------+
//| Отрисовка уровней с РАЗНЫМИ ЦВЕТАМИ для каждого ТФ              |
//+------------------------------------------------------------------+
void DrawLevelsOnChart()
{
   //=== УДАЛЯЕМ СТАРЫЕ ЛИНИИ ===
   DeleteLevels();
   
   //=== H1: ЗЕЛЁНЫЕ ЛИНИИ ===
   if(UseSignalH1 && recEntryH1 > 0)
   {
      DrawHLine("EntryLine_H1", recEntryH1, clrLime, 3, STYLE_SOLID, "🟢 H1 ВХОД: " + recOrderTypeH1);
      DrawHLine("SLLine_H1", recSLH1, clrLime, 2, STYLE_DASH, "🟢 H1 SL");
      DrawHLine("TPLine_H1", recTPH1, clrLime, 2, STYLE_DASH, "🟢 H1 TP");
   }
   
   //=== H4: ЖЁЛТЫЕ ЛИНИИ ===
   if(UseSignalH4 && recEntryH4 > 0)
   {
      DrawHLine("EntryLine_H4", recEntryH4, clrYellow, 3, STYLE_SOLID, "🟡 H4 ВХОД: " + recOrderTypeH4);
      DrawHLine("SLLine_H4", recSLH4, clrYellow, 2, STYLE_DASH, "🟡 H4 SL");
      DrawHLine("TPLine_H4", recTPH4, clrYellow, 2, STYLE_DASH, "🟡 H4 TP");
   }
   
   //=== D1: ОРАНЖЕВЫЕ ЛИНИИ ===
   if(UseSignalD1 && recEntryD1 > 0)
   {
      DrawHLine("EntryLine_D1", recEntryD1, clrOrangeRed, 3, STYLE_SOLID, "🔴 D1 ВХОД: " + recOrderTypeD1);
      DrawHLine("SLLine_D1", recSLD1, clrOrangeRed, 2, STYLE_DASH, "🔴 D1 SL");
      DrawHLine("TPLine_D1", recTPD1, clrOrangeRed, 2, STYLE_DASH, "🔴 D1 TP");
   }
   
   //=== Структурные уровни: СЕРЫЕ ТОЧКИ ===
   if(nearestResistance > 0)
      DrawHLine("ResistLine", nearestResistance, clrGray, 1, STYLE_DOT, "🧱 Сопротивление");
   if(nearestSupport > 0)
      DrawHLine("SupportLine", nearestSupport, clrGray, 1, STYLE_DOT, "🧱 Поддержка");
}


void DrawHLine(string name, double price, color clr, int width, ENUM_LINE_STYLE style, string tip)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);        // Линия ЗА графиками
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);  // Нельзя выделить
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);       // Скрыта из списка
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);          // Максимально назад
   }
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tip + " @ " + DoubleToString(price, symbolDigits));
}


void DeleteLevels()
{
   ObjectDelete(0, "EntryLine_H1");
   ObjectDelete(0, "SLLine_H1");
   ObjectDelete(0, "TPLine_H1");
   ObjectDelete(0, "EntryLine_H4");
   ObjectDelete(0, "SLLine_H4");
   ObjectDelete(0, "TPLine_H4");
   ObjectDelete(0, "EntryLine_D1");
   ObjectDelete(0, "SLLine_D1");
   ObjectDelete(0, "TPLine_D1");
   ObjectDelete(0, "ResistLine");
   ObjectDelete(0, "SupportLine");
}


//+------------------------------------------------------------------+
//================ ПАНЕЛЬ + ВКЛАДКИ ==================================
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

//+------------------------------------------------------------------+
//| Создание вкладок + кнопки ◀ ▶                                   |
//+------------------------------------------------------------------+
void CreateTabs()
{
   // Кнопка ◀ (предыдущая)
   ObjectCreate(0, panelName+"_Prev", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_XDISTANCE, panelX + 5);
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_YDISTANCE, panelY + 35);
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_XSIZE, 25);
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_YSIZE, 22);
   ObjectSetString(0, panelName+"_Prev", OBJPROP_TEXT, "◀");
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_BGCOLOR, C'40,40,60');
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_BORDER_COLOR, C'80,80,100');
   ObjectSetString(0, panelName+"_Prev", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, panelName+"_Prev", OBJPROP_STATE, false);
   
   // Кнопки вкладок
   int tabWidth = (panelWidth - 70) / TAB_COUNT; // минус кнопки ◀ ▶
   for(int i = 0; i < TAB_COUNT; i++)
   {
      string btnName = panelName+"_Tab_"+IntegerToString(i);
      ObjectCreate(0, btnName, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, btnName, OBJPROP_XDISTANCE, panelX + 35 + i * tabWidth);
      ObjectSetInteger(0, btnName, OBJPROP_YDISTANCE, panelY + 35);
      ObjectSetInteger(0, btnName, OBJPROP_XSIZE, tabWidth - 2);
      ObjectSetInteger(0, btnName, OBJPROP_YSIZE, 22);
      ObjectSetString(0, btnName, OBJPROP_TEXT, TAB_NAMES[i]);
      ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrLightGray);
      ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, C'35,35,50');
      ObjectSetInteger(0, btnName, OBJPROP_BORDER_COLOR, C'80,80,100');
      ObjectSetString(0, btnName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, btnName, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, btnName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, btnName, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, btnName, OBJPROP_STATE, false);
   }
   
   // Кнопка ▶ (следующая)
   ObjectCreate(0, panelName+"_Next", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_XDISTANCE, panelX + panelWidth - 30);
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_YDISTANCE, panelY + 35);
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_XSIZE, 25);
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_YSIZE, 22);
   ObjectSetString(0, panelName+"_Next", OBJPROP_TEXT, "▶");
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_BGCOLOR, C'40,40,60');
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_BORDER_COLOR, C'80,80,100');
   ObjectSetString(0, panelName+"_Next", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, panelName+"_Next", OBJPROP_STATE, false);
      
}

//+------------------------------------------------------------------+
//| Обновление внешнего вида вкладок (активная подсвечивается)      |
//+------------------------------------------------------------------+
void UpdateTabs()
{
   for(int i = 0; i < TAB_COUNT; i++)
   {
      string btnName = panelName+"_Tab_"+IntegerToString(i);
      if(i == currentTab)
      {
         ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, C'60,80,120'); // Активная — синяя
         ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite);
      }
      else
      {
         ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, C'35,35,50'); // Неактивная — тёмная
         ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrLightGray);
      }
   }
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
   
   string title = "═══ " + currentSymbol + " (" + symbolType + ") PRO ═══";
   CreateLabel(panelName+"_Title", title, panelX + 10, y, clrYellow, 11);
   
   if(isCollapsed)
   {
      string shortInfo = "";
      color shortColor = clrGray;
      if(resultH1.weightedSum >= 6)       { shortInfo = "▲ STRONG BUY"; shortColor = clrLime; }
      else if(resultH1.weightedSum >= 3)  { shortInfo = "▲ BUY";        shortColor = clrGreen; }
      else if(resultH1.weightedSum <= -6) { shortInfo = "▼ STRONG SELL"; shortColor = clrRed; }
      else if(resultH1.weightedSum <= -3) { shortInfo = "▼ SELL";       shortColor = clrDarkRed; }
      else                                { shortInfo = "● HOLD";       shortColor = clrGray; }
      CreateLabel(panelName+"_ShortInfo", shortInfo, panelX + 250, y, shortColor, 10);
      HideAllDetails(); // Очищает весь контент
   }
   else
   {
      ShowAllDetails(y, lineHeight, priceFormat); // Очищает и рендерит заново
   }
   ChartRedraw();
}

void HideAllDetails()
{
   ClearTabContent();
   
}

//+------------------------------------------------------------------+
//| Очистка содержимого вкладок перед рендером новой                |
//+------------------------------------------------------------------+
void ClearTabContent()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      
      // Пропускаем служебные объекты (их не удаляем)
      if(StringFind(name, panelName) != 0) continue;
      if(StringFind(name, "_BG") >= 0) continue;
      if(StringFind(name, "_Title") >= 0) continue;
      if(StringFind(name, "_ShortInfo") >= 0) continue;
      if(StringFind(name, "_Tab_") >= 0) continue;
      if(StringFind(name, "_Prev") >= 0) continue;
      if(StringFind(name, "_Next") >= 0) continue;
      if(name == buttonName) continue;
      
      // Всё остальное — удаляем
      ObjectDelete(0, name);
   }
}


//+------------------------------------------------------------------+
//| Показ содержимого активной вкладки                              |
//+------------------------------------------------------------------+
void ShowAllDetails(int startY, int lineHeight, string priceFormat)
{
   //=== ГЛАВНОЕ: очищаем старый контент перед рендером ===
   ClearTabContent();
   
   UpdateTabs(); // Подсветить активную вкладку
   
   int y = startY + 65; // Отступ под вкладки
   
   //=== ПОДЗАГОЛОВОК: время и сессия ===
   CreateLabel(panelName+"_SubInfo", currentSession + " | " + DetectDayOfWeek() + " | " +
               TimeToString(TimeCurrent(), TIME_MINUTES|TIME_SECONDS), 
               panelX + 10, y, clrLightGray, 9);
   y += lineHeight;
   
   CreateLabel(panelName+"_Sep0", "═══════════════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   // Индикатор страницы
   string pageInfo = StringFormat("📑 Стр. %d/%d: %s", currentTab + 1, TAB_COUNT, TAB_NAMES[currentTab]);
   CreateLabel(panelName+"_PageInfo", pageInfo, panelX + 10, y, clrWheat, 9);
   y += lineHeight + 3;
   
      //=== РЕНДЕР АКТИВНОЙ ВКЛАДКИ ===
   switch(currentTab)
   {
      case 0: RenderTab_Analysis(y, lineHeight, priceFormat); break;
      case 1: RenderTab_Filters(y, lineHeight); break;
      case 2: RenderTab_Levels(y, lineHeight, priceFormat); break;
      case 3: RenderTab_Stats(y, lineHeight); break;
      case 4: RenderTab_History(y, lineHeight, priceFormat); break;
   }
}

//+------------------------------------------------------------------+
//| ВКЛАДКА 1: АНАЛИЗ (с правильными отступами)                     |
//+------------------------------------------------------------------+
void RenderTab_Analysis(int y, int lineHeight, string priceFormat)
{
   //=== ЯВНОЕ УДАЛЕНИЕ ВСЕХ ВОЗМОЖНЫХ ОБЪЕКТОВ ===
   ObjectDelete(0, panelName+"_Col1");
   ObjectDelete(0, panelName+"_Col2");
   ObjectDelete(0, panelName+"_Col3");
   ObjectDelete(0, panelName+"_Col4");
   ObjectDelete(0, panelName+"_Sep1");
   ObjectDelete(0, panelName+"_Sep2");
   ObjectDelete(0, panelName+"_Sep3");
   ObjectDelete(0, panelName+"_Sep4");
   ObjectDelete(0, panelName+"_Summary");
   ObjectDelete(0, panelName+"_LevelsH1");
   ObjectDelete(0, panelName+"_LevelsH4");
   ObjectDelete(0, panelName+"_LevelsD1");
   
   // Заголовки столбцов
   CreateLabel(panelName+"_Col1", "ТФ", panelX + 20, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col2", "СИГНАЛЫ", panelX + 80, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col3", "Σ", panelX + 280, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col4", "ПРОГНОЗ", panelX + 330, y, clrDodgerBlue, 10);
   y += lineHeight + 3;
   
   CreateLabel(panelName+"_Sep1", "─────────────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   //=== H1 БЛОК ===
   DrawTFRow("H1", resultH1, "H1", y, priceFormat, lineHeight);
   y += lineHeight * 3;  // DrawTFRow занимает 3 строки (TF, Forecast, Price)
   
   // Уровни H1 (если есть сигнал)
   if(recEntryH1 > 0)
   {
      string h1Levels = StringFormat("🟢 Entry: %s | SL: %s | TP: %s",
         DoubleToString(recEntryH1, symbolDigits),
         DoubleToString(recSLH1, symbolDigits),
         DoubleToString(recTPH1, symbolDigits));
      CreateLabel(panelName+"_LevelsH1", h1Levels, panelX + 25, y, clrLime, 8);
      y += lineHeight;
   }
   else
   {
      CreateLabel(panelName+"_LevelsH1", "🟢 H1: нет сигнала", panelX + 25, y, clrGray, 8);
      y += lineHeight;
   }
   
   y += 5;
   CreateLabel(panelName+"_Sep2", "─────────────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   //=== H4 БЛОК ===
   DrawTFRow("H4", resultH4, "H4", y, priceFormat, lineHeight);
   y += lineHeight * 3;
   
   if(recEntryH4 > 0)
   {
      string h4Levels = StringFormat("🟡 Entry: %s | SL: %s | TP: %s",
         DoubleToString(recEntryH4, symbolDigits),
         DoubleToString(recSLH4, symbolDigits),
         DoubleToString(recTPH4, symbolDigits));
      CreateLabel(panelName+"_LevelsH4", h4Levels, panelX + 25, y, clrYellow, 8);
      y += lineHeight;
   }
   else
   {
      CreateLabel(panelName+"_LevelsH4", "🟡 H4: нет сигнала", panelX + 25, y, clrGray, 8);
      y += lineHeight;
   }
   
   y += 5;
   CreateLabel(panelName+"_Sep3", "─────────────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   //=== D1 БЛОК ===
   DrawTFRow("D1", resultD1, "D1", y, priceFormat, lineHeight);
   y += lineHeight * 3;
   
   if(recEntryD1 > 0)
   {
      string d1Levels = StringFormat("🔴 Entry: %s | SL: %s | TP: %s",
         DoubleToString(recEntryD1, symbolDigits),
         DoubleToString(recSLD1, symbolDigits),
         DoubleToString(recTPD1, symbolDigits));
      CreateLabel(panelName+"_LevelsD1", d1Levels, panelX + 25, y, clrOrangeRed, 8);
      y += lineHeight;
   }
   else
   {
      CreateLabel(panelName+"_LevelsD1", "🔴 D1: нет сигнала", panelX + 25, y, clrGray, 8);
      y += lineHeight;
   }
   
   y += 5;
   CreateLabel(panelName+"_Sep4", "═══════════════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   // Итог
   string summary = "💡 ";
   color sumColor = clrGray;
   if(resultH1.weightedSum >= 6 && resultH4.weightedSum >= 2 && resultD1.weightedSum >= -4)
   { summary += "ВСЕ ТФ БЫЧЬИ — ищите BUY"; sumColor = clrLime; }
   else if(resultH1.weightedSum <= -6 && resultH4.weightedSum <= -2 && resultD1.weightedSum <= 4)
   { summary += "ВСЕ ТФ МЕДВЕЖЬИ — ищите SELL"; sumColor = clrRed; }
   else if(MathAbs(resultH1.weightedSum) < 3 && MathAbs(resultH4.weightedSum) < 3)
   { summary += "ФЛЭТ — ждём тренда"; sumColor = clrOrange; }
   else
   { summary += "СМЕШАННЫЙ сигнал — осторожно"; sumColor = clrYellow; }
   
   CreateLabel(panelName+"_Summary", summary, panelX + 20, y, sumColor, 10);
}

//+------------------------------------------------------------------+
//| ВКЛАДКА 2: ФИЛЬТРЫ                                              |
//+------------------------------------------------------------------+
void RenderTab_Filters(int y, int lineHeight)
{
   //=== АКТИВНЫЕ РЕЖИМЫ ===
   string modesStr = "🎛️ Режимы: ";
   modesStr += UseSignalH1 ? "🟢H1 " : "⚫H1 ";
   modesStr += UseSignalH4 ? "🟡H4 " : "⚫H4 ";
   modesStr += UseSignalD1 ? "🔴D1 " : "⚫D1 ";
   CreateLabel(panelName+"_Modes", modesStr, panelX + 10, y, clrWheat, 9);
   y += lineHeight + 3;
   
   CreateLabel(panelName+"_FilterTitle", "🛡️ ФИЛЬТРЫ ТОЧНОСТИ:", panelX + 10, y, clrYellow, 11);
   y += lineHeight + 3;
   
   DrawFilterRow("News", "📰 Новости (±30 мин)", filterNews, y);
   y += lineHeight;
   DrawFilterRow("Vol", "📊 Волатильность (ATR)", filterVolatility, y);
   y += lineHeight;
   DrawFilterRow("Sess", "🕐 Сессия (8-22)", filterSession, y);
   y += lineHeight;
   DrawFilterRow("Cand", "🕯️ Свечной паттерн", filterCandle, y);
   y += lineHeight;
   DrawFilterRow("RSI", "📈 RSI (не экстремум)", filterRSI, y);
   y += lineHeight;
   DrawFilterRow("Str", "🧱 Структура (уровни)", filterStructure, y);
   y += lineHeight + 5;
   
   CreateLabel(panelName+"_Sep5", "═══════════════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   // Итоговый статус
   string confirmStatus = "";
   color confirmColor = clrGray;
   
   bool allFilters = filterNews && filterVolatility && filterSession && 
                     filterCandle && filterRSI && filterStructure;
   
   if(allFilters)
   {
      confirmStatus = (resultH1.weightedSum > 0) ? "🟢 CONFIRMED BUY 🔔" : "🔴 CONFIRMED SELL 🔔";
      confirmColor = (resultH1.weightedSum > 0) ? clrLime : clrRed;
   }
   else
   {
      int passed = 0;
      if(filterNews) passed++;
      if(filterVolatility) passed++;
      if(filterSession) passed++;
      if(filterCandle) passed++;
      if(filterRSI) passed++;
      if(filterStructure) passed++;
      confirmStatus = StringFormat("⏳ Фильтры: %d/6 пройдено", passed);
      confirmColor = clrOrange;
   }
   
   CreateLabel(panelName+"_Confirm", confirmStatus, panelX + 20, y, confirmColor, 11);
   y += lineHeight + 5;
   
   // Базовые правила
   CreateLabel(panelName+"_Rules", "📋 Базовые правила:", panelX + 10, y, clrYellow, 10);
   y += lineHeight;
   
   bool r1 = (MathAbs(resultH1.weightedSum) >= 6);
   bool r2 = (resultH1.weightedSum > 0 && resultH4.weightedSum >= 2) || 
             (resultH1.weightedSum < 0 && resultH4.weightedSum <= -2);
   bool r3 = (resultH1.weightedSum > 0 && resultD1.weightedSum >= -4) || 
             (resultH1.weightedSum < 0 && resultD1.weightedSum <= 4);
   
   string r1s = r1 ? "✅" : "❌";
   color c1 = r1 ? clrLime : clrRed;
   CreateLabel(panelName+"_Rule1", r1s + " H1: STRONG (|Σ|≥6)", panelX + 20, y, c1, 9);
   y += lineHeight - 3;
   
   string r2s = r2 ? "✅" : "❌";
   color c2 = r2 ? clrLime : clrRed;
   CreateLabel(panelName+"_Rule2", r2s + " H4: подтверждение", panelX + 20, y, c2, 9);
   y += lineHeight - 3;
   
   string r3s = r3 ? "✅" : "❌";
   color c3 = r3 ? clrLime : clrRed;
   CreateLabel(panelName+"_Rule3", r3s + " D1: тренд не против", panelX + 20, y, c3, 9);
}

//+------------------------------------------------------------------+
//| ВКЛАДКА 3: УРОВНИ (с правильными отступами)                     |
//+------------------------------------------------------------------+
void RenderTab_Levels(int y, int lineHeight, string priceFormat)
{
   //=== ЯВНОЕ УДАЛЕНИЕ ВСЕХ ВОЗМОЖНЫХ ОБЪЕКТОВ ===
   ObjectDelete(0, panelName+"_LevelsTitle");
   ObjectDelete(0, panelName+"_Entry");
   ObjectDelete(0, panelName+"_SL");
   ObjectDelete(0, panelName+"_TP");
   ObjectDelete(0, panelName+"_StructTitle");
   ObjectDelete(0, panelName+"_Res");
   ObjectDelete(0, panelName+"_Sup");
   ObjectDelete(0, panelName+"_RR");
   ObjectDelete(0, panelName+"_NoLevels");
   ObjectDelete(0, panelName+"_Hint");
   ObjectDelete(0, panelName+"_LvlH1");
   ObjectDelete(0, panelName+"_LvlH4");
   ObjectDelete(0, panelName+"_LvlD1");
   
   CreateLabel(panelName+"_LevelsTitle", "📊 РЕКОМЕНДУЕМЫЕ УРОВНИ:", panelX + 10, y, clrYellow, 11);
   y += lineHeight + 5;
   
   if(recEntry > 0)
   {
      // Основной активный режим
      color activeColor = clrDodgerBlue;
      string activePrefix = "";
      if(activeMode == "H1") { activeColor = clrLime; activePrefix = "🟢"; }
      else if(activeMode == "H4") { activeColor = clrYellow; activePrefix = "🟡"; }
      else if(activeMode == "D1") { activeColor = clrOrangeRed; activePrefix = "🔴"; }
      
      string entryStr = StringFormat("%s ВХОД (%s): %s", activePrefix, recOrderType, DoubleToString(recEntry, symbolDigits));
      CreateLabel(panelName+"_Entry", entryStr, panelX + 20, y, activeColor, 10);
      y += lineHeight;
      
      string slStr = StringFormat("🛑 STOP LOSS: %s", DoubleToString(recSL, symbolDigits));
      double slDist = MathAbs(recEntry - recSL);
      string slPips = "";
      if(resultH1.atrValue > 0) slPips = StringFormat(" (-%.1f ATR)", slDist / resultH1.atrValue);
      CreateLabel(panelName+"_SL", slStr + slPips, panelX + 20, y, SLColor, 10);
      y += lineHeight;
      
      string tpStr = StringFormat("🎯 TAKE PROFIT: %s", DoubleToString(recTP, symbolDigits));
      double tpDist = MathAbs(recTP - recEntry);
      string rr = "";
      if(slDist > 0) rr = StringFormat(" (R:R 1:%.1f)", tpDist / slDist);
      CreateLabel(panelName+"_TP", tpStr + rr, panelX + 20, y, TPColor, 10);
      y += lineHeight + 5;
      
      // Risk/Reward
      double rrRatio = (slDist > 0) ? tpDist / slDist : 0;
      color rrColor = (rrRatio >= 2.0) ? clrLime : (rrRatio >= 1.5) ? clrYellow : (rrRatio >= 1.0) ? clrOrange : clrRed;
      string rrText = StringFormat("💰 Risk/Reward = 1:%.2f %s", rrRatio, 
                                   rrRatio >= 2.0 ? "✅ ОТЛИЧНО" : (rrRatio >= 1.5 ? "✅ ХОРОШО" : (rrRatio >= 1.0 ? "⚠️ НОРМ" : "❌ ПЛОХО")));
      CreateLabel(panelName+"_RR", rrText, panelX + 20, y, rrColor, 10);
      y += lineHeight + 5;
      
      // Структурные уровни
      CreateLabel(panelName+"_StructTitle", "🧱 Структурные уровни (H4):", panelX + 10, y, clrYellow, 10);
      y += lineHeight;
      
      if(nearestResistance > 0)
      {
         string resStr = StringFormat("🔸 Сопротивление: %s", DoubleToString(nearestResistance, symbolDigits));
         CreateLabel(panelName+"_Res", resStr, panelX + 20, y, clrOrange, 9);
         y += lineHeight;
      }
      else
      {
         CreateLabel(panelName+"_Res", "🔸 Сопротивление: не найдено", panelX + 20, y, clrGray, 9);
         y += lineHeight;
      }
      
      if(nearestSupport > 0)
      {
         string supStr = StringFormat("🔹 Поддержка: %s", DoubleToString(nearestSupport, symbolDigits));
         CreateLabel(panelName+"_Sup", supStr, panelX + 20, y, clrDeepSkyBlue, 9);
         y += lineHeight;
      }
      else
      {
         CreateLabel(panelName+"_Sup", "🔹 Поддержка: не найдена", panelX + 20, y, clrGray, 9);
         y += lineHeight;
      }
   }
   else
   {
      CreateLabel(panelName+"_NoLevels", "⏸ Уровни появятся при подтверждении сигнала", 
                  panelX + 20, y, clrGray, 10);
      y += lineHeight;
      CreateLabel(panelName+"_Hint", "💡 Ждите подтверждения сигнала", 
                  panelX + 20, y, clrWheat, 9);
      y += lineHeight + 5;
   }
   
   //=== УРОВНИ ДРУГИХ АКТИВНЫХ РЕЖИМОВ ===
   y += 5;
   CreateLabel(panelName+"_SepLevels", "─────────────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   CreateLabel(panelName+"_OtherTitle", "📋 Уровни других режимов:", panelX + 10, y, clrYellow, 10);
   y += lineHeight;
   
   if(UseSignalH1 && recEntryH1 > 0 && activeMode != "H1")
   {
      string h1Str = StringFormat("🟢 H1: %s @ %s | SL %s | TP %s", 
         recOrderTypeH1, DoubleToString(recEntryH1, symbolDigits),
         DoubleToString(recSLH1, symbolDigits), DoubleToString(recTPH1, symbolDigits));
      CreateLabel(panelName+"_LvlH1", h1Str, panelX + 20, y, clrLime, 8);
      y += lineHeight;
   }
   else if(UseSignalH1 && recEntryH1 == 0)
   {
      CreateLabel(panelName+"_LvlH1", "🟢 H1: нет сигнала", panelX + 20, y, clrGray, 8);
      y += lineHeight;
   }
   
   if(UseSignalH4 && recEntryH4 > 0 && activeMode != "H4")
   {
      string h4Str = StringFormat("🟡 H4: %s @ %s | SL %s | TP %s", 
         recOrderTypeH4, DoubleToString(recEntryH4, symbolDigits),
         DoubleToString(recSLH4, symbolDigits), DoubleToString(recTPH4, symbolDigits));
      CreateLabel(panelName+"_LvlH4", h4Str, panelX + 20, y, clrYellow, 8);
      y += lineHeight;
   }
   else if(UseSignalH4 && recEntryH4 == 0)
   {
      CreateLabel(panelName+"_LvlH4", "🟡 H4: нет сигнала", panelX + 20, y, clrGray, 8);
      y += lineHeight;
   }
   
   if(UseSignalD1 && recEntryD1 > 0 && activeMode != "D1")
   {
      string d1Str = StringFormat("🔴 D1: %s @ %s | SL %s | TP %s", 
         recOrderTypeD1, DoubleToString(recEntryD1, symbolDigits),
         DoubleToString(recSLD1, symbolDigits), DoubleToString(recTPD1, symbolDigits));
      CreateLabel(panelName+"_LvlD1", d1Str, panelX + 20, y, clrOrangeRed, 8);
      y += lineHeight;
   }
   else if(UseSignalD1 && recEntryD1 == 0)
   {
      CreateLabel(panelName+"_LvlD1", "🔴 D1: нет сигнала", panelX + 20, y, clrGray, 8);
      y += lineHeight;
   }
}

//+------------------------------------------------------------------+
//| ВКЛАДКА 4: СТАТИСТИКА                                           |
//+------------------------------------------------------------------+
void RenderTab_Stats(int y, int lineHeight)
{
   CreateLabel(panelName+"_StatTitle", "📈 СТАТИСТИКА ТОЧНОСТИ:", panelX + 10, y, clrYellow, 11);
   y += lineHeight + 5;
      // Дата начала сбора
   string dateStr = "📅 Сбор начат: " + TimeToString(statsStartDate, TIME_DATE);
   CreateLabel(panelName+"_StatDate", dateStr, panelX + 20, y, clrGray, 9);
   y += lineHeight;
   string stat1 = StringFormat("📊 Всего сигналов: %d", totalSignals);
   CreateLabel(panelName+"_Stat1", stat1, panelX + 20, y, clrLightGray, 10);
   y += lineHeight;
   
   string stat2 = StringFormat("✅ Верных: %d", winningSignals);
   CreateLabel(panelName+"_Stat2", stat2, panelX + 20, y, clrLime, 10);
   y += lineHeight;
   
   string stat3 = StringFormat("❌ Ошибок: %d", losingSignals);
      
   CreateLabel(panelName+"_Stat3", stat3, panelX + 20, y, clrRed, 10);
   y += lineHeight+5;
   string stat4 = StringFormat("⏸ Аннулировано: %d", canceledSignals);
   CreateLabel(panelName+"_Stat4", stat4, panelX + 20, y, clrGray, 10);
   y += lineHeight+10;
     
   
   CreateLabel(panelName+"_Sep6", "═══════════════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight + 3;
   
   double accuracy = GetAccuracy();
   color accColor = (accuracy >= 70) ? clrLime : (accuracy >= 55) ? clrOrange : 
                    (totalSignals > 0 ? clrRed : clrGray);
   
   string accStr = StringFormat("🎯 ТОЧНОСТЬ: %.1f%%", accuracy);
   CreateLabel(panelName+"_Acc", accStr, panelX + 20, y, accColor, 14);
   y += lineHeight + 5;
   
   string gradeStr = "";
   color gradeColor = clrGray;
   if(totalSignals == 0) { gradeStr = "⏳ Нет данных"; }
   else if(accuracy >= 75) { gradeStr = "🏆 ОТЛИЧНО"; gradeColor = clrLime; }
   else if(accuracy >= 65) { gradeStr = "✅ ХОРОШО"; gradeColor = clrGreen; }
   else if(accuracy >= 55) { gradeStr = "⚠️ НОРМАЛЬНО"; gradeColor = clrOrange; }
   else { gradeStr = "❗ ТРЕБУЕТ НАСТРОЙКИ"; gradeColor = clrRed; }
   
   CreateLabel(panelName+"_Grade", gradeStr, panelX + 20, y, gradeColor, 11);
   y += lineHeight + 5;
   
   // Подсказка
   CreateLabel(panelName+"_Hint", "💡 Статистика сбрасывается при перезапуске советника", 
               panelX + 20, y, clrGray, 8);
   y += lineHeight - 3;
   CreateLabel(panelName+"_Hint2", "💡 Для объективной оценки нужно минимум 20-30 сигналов", 
               panelX + 20, y, clrGray, 8);
      //=== КНОПКА RESET (создаётся динамически на этой вкладке) ===
   y += 5;
   string resetBtn = panelName+"_Reset";
   
   // Удаляем если уже есть (чтобы пересоздать с новыми координатами)
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
   ObjectSetString(0, resetBtn, OBJPROP_TOOLTIP, "Обнулить статистику");
      //=== КНОПКА БЭКТЕСТА ===
   y += 35;
   string testBtn = panelName+"_Backtest";
   if(ObjectFind(0, testBtn) >= 0) ObjectDelete(0, testBtn);
   
   ObjectCreate(0, testBtn, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, testBtn, OBJPROP_XDISTANCE, panelX + 20);
   ObjectSetInteger(0, testBtn, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, testBtn, OBJPROP_XSIZE, panelWidth - 40);
   ObjectSetInteger(0, testBtn, OBJPROP_YSIZE, 30);
   
   string btnText = isBacktestRunning ? "⏳ ТЕСТ ЗАПУЩЕН..." : "🧪 ЗАПУСТИТЬ БЭКТЕСТ";
   ObjectSetString(0, testBtn, OBJPROP_TEXT, btnText);
   ObjectSetInteger(0, testBtn, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, testBtn, OBJPROP_BGCOLOR, isBacktestRunning ? C'100,100,50' : C'40,100,40');
   ObjectSetInteger(0, testBtn, OBJPROP_BORDER_COLOR, C'80,150,80');
   ObjectSetString(0, testBtn, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, testBtn, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, testBtn, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, testBtn, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, testBtn, OBJPROP_STATE, false);
}

//+------------------------------------------------------------------+
//| ВКЛАДКА 5: ИСТОРИЯ ПОСЛЕДНИХ СИГНАЛОВ                           |
//+------------------------------------------------------------------+
void RenderTab_History(int y, int lineHeight, string priceFormat)
{
   CreateLabel(panelName+"_HistTitle", "📜 ИСТОРИЯ ПОСЛЕДНИХ СИГНАЛОВ:", panelX + 10, y, clrYellow, 11);
   y += lineHeight + 3;
   
   // Заголовки
   CreateLabel(panelName+"_HistH1", "ВРЕМЯ", panelX + 15, y, clrDodgerBlue, 9);
   CreateLabel(panelName+"_HistH2", "ТФ", panelX + 110, y, clrDodgerBlue, 9);
   CreateLabel(panelName+"_HistH3", "НАПР", panelX + 145, y, clrDodgerBlue, 9);
   CreateLabel(panelName+"_HistH4", "ВХОД", panelX + 190, y, clrDodgerBlue, 9);
   CreateLabel(panelName+"_HistH5", "СТАТУС", panelX + 290, y, clrDodgerBlue, 9);
   CreateLabel(panelName+"_HistH6", "Δ", panelX + 400, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   CreateLabel(panelName+"_HistSep", "─────────────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   // Подсчёт реальных записей
   int realCount = 0;
   for(int i = 0; i < HISTORY_SIZE; i++)
      if(history[i].time > 0) realCount++;
   
   if(realCount == 0)
   {
      CreateLabel(panelName+"_HistEmpty", "⏸ История пуста — ждём первый сигнал", 
                  panelX + 20, y, clrGray, 10);
      y += lineHeight;
      CreateLabel(panelName+"_HistHint", "💡 Сигналы появятся здесь автоматически", 
                  panelX + 20, y, clrWheat, 9);
      return;
   }
   
   // Отображаем записи (от новых к старым)
   for(int i = HISTORY_SIZE - 1; i >= 0; i--)
   {
      if(history[i].time == 0) continue;
      
      // Время
      string timeStr = TimeToString(history[i].time, TIME_DATE|TIME_MINUTES);
      StringSetCharacter(timeStr, 4, '-');
      StringSetCharacter(timeStr, 7, '-');
      CreateLabel(panelName+"_HistT_"+IntegerToString(i), timeStr, panelX + 15, y, clrLightGray, 8);
      
      // Режим (H1/H4/D1) с цветом
      color modeColor = clrGray;
      if(history[i].mode == "H1") modeColor = clrLime;
      else if(history[i].mode == "H4") modeColor = clrYellow;
      else if(history[i].mode == "D1") modeColor = clrOrangeRed;
      CreateLabel(panelName+"_HistM_"+IntegerToString(i), history[i].mode, panelX + 115, y, modeColor, 9);
      
      // Направление
      color dirColor = (history[i].direction == "BUY") ? clrLime : clrRed;
      string dirStr = (history[i].direction == "BUY") ? "▲ BUY" : "▼ SELL";
      CreateLabel(panelName+"_HistD_"+IntegerToString(i), dirStr, panelX + 145, y, dirColor, 8);
      
      // Цена входа
      string entryStr = DoubleToString(history[i].entry, symbolDigits);
      CreateLabel(panelName+"_HistE_"+IntegerToString(i), entryStr, panelX + 190, y, clrWhite, 8);
      
      // Статус
      color statusColor = clrGray;
      if(StringFind(history[i].status, "WIN") >= 0) statusColor = clrLime;
      else if(StringFind(history[i].status, "LOSS") >= 0) statusColor = clrRed;
      else statusColor = clrOrange;
      CreateLabel(panelName+"_HistS_"+IntegerToString(i), history[i].status, panelX + 285, y, statusColor, 8);
      
      // Движение цены
      string movStr = "";
      color movColor = clrGray;
      if(history[i].movement != 0)
      {
         movStr = StringFormat("%+.2f", history[i].movement);
         movColor = (history[i].movement > 0) ? clrLime : clrRed;
      }
      else
      {
         movStr = "—";
      }
      CreateLabel(panelName+"_HistV_"+IntegerToString(i), movStr, panelX + 400, y, movColor, 8);
      
      y += lineHeight - 2;
      
      // Разделитель между записями
      if(i > 0 && history[i-1].time > 0)
      {
         CreateLabel(panelName+"_HistLS_"+IntegerToString(i), "· · · · · · · · · · · · · · · · · · · · · · · · · · · ·", 
                     panelX + 15, y, clrDarkSlateGray, 8);
         y += lineHeight - 8;
      }
   }
   
   // Итоговая статистика по истории
   y += 5;
   CreateLabel(panelName+"_HistSep2", "═══════════════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   int histWins = 0, histLosses = 0, histWait = 0;
   for(int i = 0; i < HISTORY_SIZE; i++)
   {
      if(history[i].time == 0) continue;
      if(StringFind(history[i].status, "WIN") >= 0) histWins++;
      else if(StringFind(history[i].status, "LOSS") >= 0) histLosses++;
      else histWait++;
   }
   
   string summaryStr = StringFormat("📊 В истории: %d | ✅ %d | ❌ %d | ⏳ %d", 
                                     realCount, histWins, histLosses, histWait);
   CreateLabel(panelName+"_HistSummary", summaryStr, panelX + 20, y, clrLightGray, 9);
   y += lineHeight - 3;
   
   if(histWins + histLosses > 0)
   {
      double histAcc = histWins * 100.0 / (histWins + histLosses);
      color accColor = (histAcc >= 70) ? clrLime : (histAcc >= 55) ? clrOrange : clrRed;
      string accStr = StringFormat("🎯 Точность за последние сигналы: %.1f%%", histAcc);
      CreateLabel(panelName+"_HistAcc", accStr, panelX + 20, y, accColor, 10);
   }
}
//+------------------------------------------------------------------+
void DrawFilterRow(string id, string label, bool passed, int y)
{
   string mark = passed ? "✅" : "❌";
   color c = passed ? clrLime : clrRed;
   CreateLabel(panelName+"_F_"+id, mark + " " + label, panelX + 25, y, c, 10);
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
   
   CreateLabel(panelName+"_Forecast"+prefix, StringFormat("%d свечей", result.candlesForecast), 
               panelX + 330, y, clrOrange, 9);
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