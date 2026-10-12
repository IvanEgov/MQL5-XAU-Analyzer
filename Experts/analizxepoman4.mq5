//+------------------------------------------------------------------+
//|                                    XAU_Analyzer_PRO.mq5          |
//|           PRO-аналитик с вкладками (прокрутка страниц)           |
//+------------------------------------------------------------------+
#property strict

struct IndicatorVotes
{
   int votes[10];
   double weightedSum;
   int totalSum;
   string signal;
   int candlesForecast;
   double currentPrice;
   double targetPrice;
   double atrValue;
};
//--- Структура для хранения записи сигнала в истории
struct SignalRecord
{
   datetime time;        // Время сигнала
   string mode;          // H1, H4, D1
   string direction;     // BUY, SELL
   double entry;         // Цена входа
   double sl;            // Стоп-лосс
   double tp;            // Тейк-профит
   string status;        // "⏳", "✅ WIN", "❌ LOSS"
   double movement;      // Движение цены
   double weightedSum;   // Сила сигнала
};

//--- История последних 5 сигналов
#define HISTORY_SIZE 5
SignalRecord history[HISTORY_SIZE];
string historyFileName = "signal_history.dat";

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
string panelName = "AnalysisPanel";
string buttonName = "CollapseButton";
int panelX = 20, panelY = 30;
int panelWidth = 500;
int panelHeightExpanded = 500;  // Чуть выше для истории
int panelHeightCollapsed = 35;
bool isCollapsed = false;

//=== ВКЛАДКИ ===
#define TAB_COUNT 5
string tabNames[] = {"📊 АНАЛИЗ", "🛡️ ФИЛЬТРЫ", "📍 УРОВНИ", "📈 СТАТИСТИКА", "📜 ИСТОРИЯ"};
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



//--- ВЕСА ИНДИКАТОРОВ
const double IND_WEIGHTS[10] = {2.0, 3.0, 1.5, 2.0, 1.5, 1.0, 1.0, 1.5, 1.5, 1.0};

//--- Состояние для каждого режима
string lastSignalH1 = "", lastSignalH4 = "", lastSignalD1 = "";
datetime lastSignalTimeH1 = 0, lastSignalTimeH4 = 0, lastSignalTimeD1 = 0;

// Уровни для каждого режима (отдельно)
double recEntryH1 = 0, recSLH1 = 0, recTPH1 = 0;
double recEntryH4 = 0, recSLH4 = 0, recTPH4 = 0;
double recEntryD1 = 0, recSLD1 = 0, recTPD1 = 0;
string recOrderTypeH1 = "", recOrderTypeH4 = "", recOrderTypeD1 = "";

// Активный режим для отображения уровней (последний сработавший)
string activeMode = "";  // "H1", "H4" или "D1"
double recEntry = 0, recSL = 0, recTP = 0;
string recOrderType = "";
//--- Статусы фильтров
bool filterNews = false, filterVolatility = false, filterSession = false;
bool filterCandle = false, filterRSI = false, filterStructure = false;

//--- Структурные уровни
double nearestResistance = 0, nearestSupport = 0;

//--- Статистика
int totalSignals = 0, winningSignals = 0, losingSignals = 0;
double lastEntryPrice = 0;
string lastDirection = "";
datetime lastSignalCheckTime = 0;
bool signalChecked = false;
//--- Статистика (сохранение в файл)
string statsFileName = "XAU_stats.json";
datetime statsStartDate = 0;  // Когда начали собирать статистику
string statsSymbol = "";      // Для какой пары собрана

//--- Лог сигналов в CSV
string logFileName = "signals_log.csv";
string resultFileName = "results_log.csv";
datetime logMonthStart = 0;  // Для автоочистки раз в месяц
//+------------------------------------------------------------------+
int OnInit()
{
   currentSymbol = _Symbol;
   symbolDigits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   symbolPoint = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   symbolSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   symbolType = DetectSymbolType(_Symbol);
   
   // H1
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
   
   // H4
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
   
   // D1
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
   Print("📑 Используйте вкладки для навигации");
   
//=== ЗАГРУЗКА СТАТИСТИКИ ИЗ ФАЙЛА ===
LoadStats();
InitLogs(); 
LoadHistory();  
return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Сохранение статистики в файл                                    |
//+------------------------------------------------------------------+
void SaveStats()
{
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
//| Загрузка статистики из файла                                    |
//+------------------------------------------------------------------+
void LoadStats()
{
   if(!FileIsExist(statsFileName))
   {
      Print("📂 Файл статистики не найден — начинаем с нуля");
      statsStartDate = TimeCurrent();
      statsSymbol = currentSymbol;
      return;
   }
   
   int handle = FileOpen(statsFileName, FILE_READ|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Не удалось открыть файл статистики");
      statsStartDate = TimeCurrent();
      return;
   }
   
   string content = FileReadString(handle, FileSize(handle));
   FileClose(handle);
   
   // Простой парсинг JSON
   string savedSymbol = ExtractJsonString(content, "symbol");
   statsStartDate = (datetime)ExtractJsonInt(content, "startDate");
   totalSignals = ExtractJsonInt(content, "total");
   winningSignals = ExtractJsonInt(content, "wins");
   losingSignals = ExtractJsonInt(content, "losses");
   
   // Если пара сменилась — обнуляем статистику
   if(savedSymbol != currentSymbol)
   {
      Print("🔄 Пара сменилась (", savedSymbol, " → ", currentSymbol, ") — статистика обнулена");
      ResetStats();
      return;
   }
   
   statsSymbol = currentSymbol;
   Print("📂 Статистика загружена: ", totalSignals, " сигналов, точность ", 
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
   if(dt.day_of_week == 0 || dt.day_of_week == 6) return false;
   if(dt.day_of_week == 5 && dt.hour >= 20) return false;
   if(dt.hour >= 8 && dt.hour < 22) return true;
   if(MathAbs(resultD1.totalSum) >= 8) return true;
   return false;
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
//================ ОСНОВНОЙ АНАЛИЗ ===================================
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
   
   FindStructureLevels();
   CalculateRecommendedLevels();
   UpdatePanel();
   
      string entrySignal = CheckEntryConfirmation();
   
   //=== ОБРАБОТКА СИГНАЛОВ ДЛЯ КАЖДОГО РЕЖИМА ===
   // H1
   if(UseSignalH1)
   {
      string sigH1 = CheckEntryForTF(PERIOD_H1, resultH1, hRSI_H1, "H1");
      if(sigH1 != "" && sigH1 != lastSignalH1)
      {
         lastSignalH1 = sigH1;
         lastSignalTimeH1 = TimeCurrent();
         totalSignals++;
         lastEntryPrice = recEntryH1;
         lastDirection = (StringFind(sigH1, "BUY") >= 0) ? "BUY" : "SELL";
         lastSignalCheckTime = TimeCurrent();
         signalChecked = false;
         
         if(UseSoundAlert) PlaySound("alert.wav");
         if(UsePushNotify) SendPushNotification(sigH1, recEntryH1, recSLH1, recTPH1);
         
         Print("🔔 СИГНАЛ H1: ", sigH1);
                  AddToHistory("H1", lastDirection, recEntryH1, recSLH1, recTPH1, resultH1.weightedSum);
                  LogSignal("H1", lastDirection, recEntryH1, recSLH1, recTPH1, 
                   resultH1.weightedSum, resultH1.atrValue);
      }
   }
   
   // H4
   if(UseSignalH4)
   {
      string sigH4 = CheckEntryForTF(PERIOD_H4, resultH4, hRSI_H4, "H4");
      if(sigH4 != "" && sigH4 != lastSignalH4)
      {
         lastSignalH4 = sigH4;
         lastSignalTimeH4 = TimeCurrent();
         totalSignals++;
         lastEntryPrice = recEntryH4;
         lastDirection = (StringFind(sigH4, "BUY") >= 0) ? "BUY" : "SELL";
         lastSignalCheckTime = TimeCurrent();
         signalChecked = false;
         
         if(UseSoundAlert) PlaySound("alert2.wav");
         if(UsePushNotify) SendPushNotification(sigH4, recEntryH4, recSLH4, recTPH4);
         
         Print("🔔 СИГНАЛ H4: ", sigH4);
                  AddToHistory("H4", lastDirection, recEntryH4, recSLH4, recTPH4, resultH4.weightedSum);
                  LogSignal("H4", lastDirection, recEntryH4, recSLH4, recTPH4, 
                   resultH4.weightedSum, resultH4.atrValue);
      }
   }
   
   // D1
   if(UseSignalD1)
   {
      string sigD1 = CheckEntryForTF(PERIOD_D1, resultD1, hRSI_D1, "D1");
      if(sigD1 != "" && sigD1 != lastSignalD1)
      {
         lastSignalD1 = sigD1;
         lastSignalTimeD1 = TimeCurrent();
         totalSignals++;
         lastEntryPrice = recEntryD1;
         lastDirection = (StringFind(sigD1, "BUY") >= 0) ? "BUY" : "SELL";
         lastSignalCheckTime = TimeCurrent();
         signalChecked = false;
         
         if(UseSoundAlert) PlaySound("ok.wav");
         if(UsePushNotify) SendPushNotification(sigD1, recEntryD1, recSLD1, recTPD1);
         
         Print("🔔 СИГНАЛ D1: ", sigD1);
                  AddToHistory("D1", lastDirection, recEntryD1, recSLD1, recTPD1, resultD1.weightedSum);
                  LogSignal("D1", lastDirection, recEntryD1, recSLD1, recTPD1, 
                   resultD1.weightedSum, resultD1.atrValue);
      }
   }
   
   if(DrawLevels) DrawLevelsOnChart();
   ChartRedraw();
}

void CheckSignalResult()
{
   if(lastEntryPrice == 0 || signalChecked) return;
   if(TimeCurrent() - lastSignalCheckTime < 3 * 3600) return;
   
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double movement = (lastDirection == "BUY") ? 
                     (currentPrice - lastEntryPrice) : 
                     (lastEntryPrice - currentPrice);
   
   if(movement > resultH1.atrValue * 1.5)
   {
      winningSignals++;
      signalChecked = true;
      Print("✅ СИГНАЛ ВЕРНЫЙ! Точность: ", DoubleToString(GetAccuracy(), 1), "%");
      LogResult(activeMode, lastDirection, lastEntryPrice, currentPrice, "WIN", movement);
      UpdateHistoryResult("WIN", movement);
      lastEntryPrice = 0;
      
      SaveStats();
   }
   else if(movement < -resultH1.atrValue * 1.5)
   {
      losingSignals++;
      signalChecked = true;
      Print("❌ СИГНАЛ НЕВЕРНЫЙ! Точность: ", DoubleToString(GetAccuracy(), 1), "%");
      LogResult(activeMode, lastDirection, lastEntryPrice, currentPrice, "LOSS", movement);
      UpdateHistoryResult("LOSS", movement);
      lastEntryPrice = 0;
      
      SaveStats();
   }
}

double GetAccuracy()
{
   if(totalSignals == 0) return 0;
   return winningSignals * 100.0 / totalSignals;
}

//+------------------------------------------------------------------+
//| ПРОВЕРКА ВХОДА ДЛЯ КОНКРЕТНОГО ТАЙМФРЕЙМА                       |
//+------------------------------------------------------------------+
string CheckEntryForTF(ENUM_TIMEFRAMES tf, IndicatorVotes &resultMain, 
                       int hRSI, string modeName)
{
   // Базовое правило: сильный сигнал на этом ТФ
   if(resultMain.weightedSum < 6 && resultMain.weightedSum > -6) return "";
   
   // RSI не в экстремуме
   double rsi[];
   ArraySetAsSeries(rsi, true);
   if(CopyBuffer(hRSI, 0, 0, 3, rsi) < 3) return "";
   
   if(resultMain.weightedSum > 0 && rsi[1] > 75) return "";
   if(resultMain.weightedSum < 0 && rsi[1] < 25) return "";
   
   // Свечной паттерн на этом ТФ
   double open[], close[], high[], low[];
   ArraySetAsSeries(open, true); ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
   if(CopyOpen(_Symbol, tf, 0, 3, open) < 3) return "";
   if(CopyClose(_Symbol, tf, 0, 3, close) < 3) return "";
   if(CopyHigh(_Symbol, tf, 0, 3, high) < 3) return "";
   if(CopyLow(_Symbol, tf, 0, 3, low) < 3) return "";
   
   double body = MathAbs(close[1] - open[1]);
   double range = high[1] - low[1];
   if(range == 0) return "";
   
   bool candleOk = false;
   if(resultMain.weightedSum > 0)
   {
      // Бычье поглощение
      if(close[2] < open[2] && close[1] > open[1] && close[1] > open[2] && open[1] < close[2]) 
         candleOk = true;
      // Молот
      double lowerWick = MathMin(open[1], close[1]) - low[1];
      double upperWick = high[1] - MathMax(open[1], close[1]);
      if(lowerWick > body * 2 && upperWick < body * 0.5 && close[1] > open[1]) 
         candleOk = true;
      // Сильная бычья
      if(close[1] > open[1] && body > range * 0.7) candleOk = true;
      // Просто бычья
      if(close[1] > open[1]) candleOk = true;
   }
   else
   {
      // Медвежье поглощение
      if(close[2] > open[2] && close[1] < open[1] && close[1] < open[2] && open[1] > close[2]) 
         candleOk = true;
      // Падающая звезда
      double upperWick = high[1] - MathMax(open[1], close[1]);
      double lowerWick = MathMin(open[1], close[1]) - low[1];
      if(upperWick > body * 2 && lowerWick < body * 0.5 && close[1] < open[1]) 
         candleOk = true;
      // Сильная медвежья
      if(close[1] < open[1] && body > range * 0.7) candleOk = true;
      // Просто медвежья
      if(close[1] < open[1]) candleOk = true;
   }
   
   if(!candleOk) return "";
   
   // Структурные уровни — достаточно места для движения
   if(nearestResistance > 0 && nearestSupport > 0)
   {
      double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double roomUp = nearestResistance - currentPrice;
      double roomDown = currentPrice - nearestSupport;
      if(resultMain.weightedSum > 0 && roomUp < resultMain.atrValue * 1.0) return "";
      if(resultMain.weightedSum < 0 && roomDown < resultMain.atrValue * 1.0) return "";
   }
   
   // Всё прошло — возвращаем сигнал
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
   //=== ОБЩИЕ ФИЛЬТРЫ (работают для всех режимов) ===
   if(IsNewsTime()) 
   {
      filterNews = false;
      return "";
   }
   filterNews = true;
   
   if(!IsVolatilityOk()) 
   {
      filterVolatility = false;
      return "";
   }
   filterVolatility = true;
   
   if(!IsGoodSession()) 
   {
      filterSession = false;
      return "";
   }
   filterSession = true;
   
   filterCandle = true;   // Проверяется внутри CheckEntryForTF
   filterRSI = true;      // Проверяется внутри CheckEntryForTF
   filterStructure = true; // Проверяется внутри CheckEntryForTF
   
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
//| РАСЧЕТ УРОВНЕЙ ДЛЯ КОНКРЕТНОГО РЕЖИМА                           |
//+------------------------------------------------------------------+
void CalculateLevelsForMode(string mode, IndicatorVotes &result, 
                            int hEMA50, int hBB, int hRSI,
                            double &outEntry, double &outSL, double &outTP, string &outType)
{
   outEntry = 0; outSL = 0; outTP = 0; outType = "";
   
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
   double tpPrice = result.targetPrice;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   if(StringFind(signal, "BUY") >= 0)
   {
      if(rsi[1] < 45)
      {
         outType = "BUY LIMIT";
         outEntry = MathMax(ema50[1], bbMiddle[1]);
         if(outEntry >= bid) outEntry = bid - result.atrValue * 0.5;
      }
      else
      {
         double high[];
         ArraySetAsSeries(high, true);
         if(CopyHigh(_Symbol, tf, 0, 5, high) < 5) return;
         outType = "BUY STOP";
         outEntry = high[1] + result.atrValue * 0.2;
      }
      outSL = outEntry - slDistance;
      outTP = tpPrice;
      if(outTP <= outEntry) outTP = outEntry + slDistance * 2;
      
      if(nearestResistance > 0 && outTP > nearestResistance)
         outTP = nearestResistance - result.atrValue * 0.3;
      if(nearestSupport > 0 && outSL < nearestSupport)
         outSL = nearestSupport - result.atrValue * 0.5;
   }
   else
   {
      if(rsi[1] > 55)
      {
         outType = "SELL LIMIT";
         outEntry = MathMin(ema50[1], bbMiddle[1]);
         if(outEntry <= ask) outEntry = ask + result.atrValue * 0.5;
      }
      else
      {
         double low[];
         ArraySetAsSeries(low, true);
         if(CopyLow(_Symbol, tf, 0, 5, low) < 5) return;
         outType = "SELL STOP";
         outEntry = low[1] - result.atrValue * 0.2;
      }
      outSL = outEntry + slDistance;
      outTP = tpPrice;
      if(outTP >= outEntry) outTP = outEntry - slDistance * 2;
      
      if(nearestSupport > 0 && outTP < nearestSupport)
         outTP = nearestSupport + result.atrValue * 0.3;
      if(nearestResistance > 0 && outSL > nearestResistance)
         outSL = nearestResistance + result.atrValue * 0.5;
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

void DrawLevelsOnChart()
{
   if(recEntry == 0) { DeleteLevels(); return; }
   DrawHLine("EntryLine", recEntry, EntryColor, 2, STYLE_SOLID, "📍 ВХОД: " + recOrderType);
   DrawHLine("SLLine", recSL, SLColor, 2, STYLE_DASH, "🛑 SL");
   DrawHLine("TPLine", recTP, TPColor, 2, STYLE_DASH, "🎯 TP");
   if(nearestResistance > 0)
      DrawHLine("ResistLine", nearestResistance, clrOrange, 1, STYLE_DOT, "🧱 Сопротивление");
   if(nearestSupport > 0)
      DrawHLine("SupportLine", nearestSupport, clrDeepSkyBlue, 1, STYLE_DOT, "🧱 Поддержка");
}

void DrawHLine(string name, double price, color clr, int width, ENUM_LINE_STYLE style, string tip)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tip + " @ " + DoubleToString(price, symbolDigits));
}

void DeleteLevels()
{
   ObjectDelete(0, "EntryLine");
   ObjectDelete(0, "SLLine");
   ObjectDelete(0, "TPLine");
   ObjectDelete(0, "ResistLine");
   ObjectDelete(0, "SupportLine");
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
   
   result.weightedSum = 0;
   for(int i = 0; i < 10; i++)
      result.weightedSum += result.votes[i] * IND_WEIGHTS[i];
   
   result.totalSum = (int)result.weightedSum;
   
   if(result.weightedSum >= 6)       result.signal = "STRONG BUY";
   else if(result.weightedSum >= 3)  result.signal = "BUY";
   else if(result.weightedSum <= -6) result.signal = "STRONG SELL";
   else if(result.weightedSum <= -3) result.signal = "SELL";
   else                              result.signal = "HOLD";
   
   double atrValue = bufATR[1];
   result.atrValue = atrValue;
   double priceRange = bufBBUpper[1] - bufBBLower[1];
   
   int baseCandles = (int)MathAbs(result.weightedSum / 2);
   double volatilityFactor = (priceRange > 0) ? atrValue / (priceRange * 0.1) : 1.0;
   
   if(volatilityFactor > 1.5) result.candlesForecast = (int)(baseCandles * 0.7);
   else if(volatilityFactor < 0.5) result.candlesForecast = (int)(baseCandles * 1.5);
   else result.candlesForecast = baseCandles;
   
   if(result.candlesForecast < 1) result.candlesForecast = 1;
   if(result.candlesForecast > 10) result.candlesForecast = 10;
   
   result.currentPrice = bufClose[1];
   
   double multiplier = 0;
   if(result.weightedSum >= 6) multiplier = 2.5;
   else if(result.weightedSum >= 3) multiplier = 1.8;
   else if(result.weightedSum <= -6) multiplier = 2.5;
   else if(result.weightedSum <= -3) multiplier = 1.8;
   
   multiplier *= (result.candlesForecast / 5.0);
   
   if(result.weightedSum > 0)
   {
      result.targetPrice = result.currentPrice + (atrValue * multiplier);
      if(result.targetPrice > bufBBUpper[1] * 1.02) result.targetPrice = bufBBUpper[1] * 1.02;
   }
   else if(result.weightedSum < 0)
   {
      result.targetPrice = result.currentPrice - (atrValue * multiplier);
      if(result.targetPrice < bufBBLower[1] * 0.98) result.targetPrice = bufBBLower[1] * 0.98;
   }
   else result.targetPrice = result.currentPrice;
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
      ObjectSetString(0, btnName, OBJPROP_TEXT, tabNames[i]);
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
      if(StringFind(name, "_BG") >= 0) continue;           // Фон
      if(StringFind(name, "_Title") >= 0) continue;         // Заголовок
      if(StringFind(name, "_ShortInfo") >= 0) continue;     // Краткая инфа
      if(StringFind(name, "_Tab_") >= 0) continue;          // Кнопки вкладок
      if(StringFind(name, "_Prev") >= 0) continue;          // Стрелка ◀
      if(StringFind(name, "_Next") >= 0) continue;          // Стрелка ▶
    //  if(StringFind(name, "_Reset") >= 0) continue;
      if(name == buttonName) continue;                      // Кнопка ▼
      
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
   string pageInfo = StringFormat("📑 Стр. %d/%d: %s", currentTab + 1, TAB_COUNT, tabNames[currentTab]);
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
//| ВКЛАДКА 1: АНАЛИЗ (таблица H1/H4/D1)                            |
//+------------------------------------------------------------------+
void RenderTab_Analysis(int y, int lineHeight, string priceFormat)
{
   CreateLabel(panelName+"_Col1", "ТФ", panelX + 20, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col2", "СИГНАЛЫ", panelX + 80, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col3", "Σ", panelX + 280, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col4", "ПРОГНОЗ", panelX + 330, y, clrDodgerBlue, 10);
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
   
   // Краткий итог
   CreateLabel(panelName+"_Sep4", "═══════════════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
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
//| ВКЛАДКА 3: УРОВНИ                                               |
//+------------------------------------------------------------------+
void RenderTab_Levels(int y, int lineHeight, string priceFormat)
{
   CreateLabel(panelName+"_LevelsTitle", "📊 РЕКОМЕНДУЕМЫЕ УРОВНИ:", panelX + 10, y, clrYellow, 11);
   y += lineHeight + 3;
   
   if(recEntry > 0)
   {
      string entryStr = StringFormat("📍 ВХОД (%s): %s", recOrderType, DoubleToString(recEntry, symbolDigits));
      CreateLabel(panelName+"_Entry", entryStr, panelX + 20, y, EntryColor, 10);
      y += lineHeight;
      
      string slStr = StringFormat("🛑 STOP LOSS: %s", DoubleToString(recSL, symbolDigits));
      double slDist = MathAbs(recEntry - recSL);
      string slPips = StringFormat("(-%.1f ATR)", slDist / resultH1.atrValue);
      CreateLabel(panelName+"_SL", slStr + "  " + slPips, panelX + 20, y, SLColor, 10);
      y += lineHeight;
      
      string tpStr = StringFormat("🎯 TAKE PROFIT: %s", DoubleToString(recTP, symbolDigits));
      double tpDist = MathAbs(recTP - recEntry);
      string rr = StringFormat("(R:R 1:%.1f)", (slDist > 0) ? tpDist / slDist : 0);
      CreateLabel(panelName+"_TP", tpStr + "  " + rr, panelX + 20, y, TPColor, 10);
      y += lineHeight + 5;
      
      // Структурные уровни
      CreateLabel(panelName+"_StructTitle", "🧱 Структурные уровни (H4):", panelX + 10, y, clrYellow, 10);
      y += lineHeight;
      
      if(nearestResistance > 0)
      {
         string resStr = StringFormat("🔸 Сопротивление: %s", DoubleToString(nearestResistance, symbolDigits));
         CreateLabel(panelName+"_Res", resStr, panelX + 20, y, clrOrange, 9);
         y += lineHeight - 2;
      }
      else
      {
         CreateLabel(panelName+"_Res", "🔸 Сопротивление: не найдено", panelX + 20, y, clrGray, 9);
         y += lineHeight - 2;
      }
      
      if(nearestSupport > 0)
      {
         string supStr = StringFormat("🔹 Поддержка: %s", DoubleToString(nearestSupport, symbolDigits));
         CreateLabel(panelName+"_Sup", supStr, panelX + 20, y, clrDeepSkyBlue, 9);
         y += lineHeight - 2;
      }
      else
      {
         CreateLabel(panelName+"_Sup", "🔹 Поддержка: не найдена", panelX + 20, y, clrGray, 9);
         y += lineHeight - 2;
      }
      y += 3;
      
      // Risk/Reward
      double rrRatio = (slDist > 0) ? tpDist / slDist : 0;
      color rrColor = (rrRatio >= 2.0) ? clrLime : (rrRatio >= 1.0) ? clrOrange : clrRed;
      string rrText = StringFormat("💰 Risk/Reward = 1:%.2f %s", rrRatio, 
                                   rrRatio >= 2.0 ? "✅ ОТЛИЧНО" : (rrRatio >= 1.0 ? "⚠️ НОРМ" : "❌ ПЛОХО"));
      CreateLabel(panelName+"_RR", rrText, panelX + 20, y, rrColor, 10);
   }
   else
   {
      CreateLabel(panelName+"_NoLevels", "⏸ Уровни появятся при подтверждении сигнала", 
                  panelX + 20, y, clrGray, 10);
      y += lineHeight;
      CreateLabel(panelName+"_Hint", "💡 Ждите 6/6 фильтров на вкладке 🛡️ ФИЛЬТРЫ", 
                  panelX + 20, y, clrWheat, 9);
   }
         // Показываем уровни других активных режимов
      y += 5;
      if(UseSignalH1 && recEntryH1 > 0 && activeMode != "H1")
      {
         string h1Str = StringFormat("🟢 H1: %s @ %s | SL %s | TP %s", 
            recOrderTypeH1, DoubleToString(recEntryH1, symbolDigits),
            DoubleToString(recSLH1, symbolDigits), DoubleToString(recTPH1, symbolDigits));
         CreateLabel(panelName+"_LvlH1", h1Str, panelX + 20, y, clrLime, 8);
         y += lineHeight - 3;
      }
      if(UseSignalH4 && recEntryH4 > 0 && activeMode != "H4")
      {
         string h4Str = StringFormat("🟡 H4: %s @ %s | SL %s | TP %s", 
            recOrderTypeH4, DoubleToString(recEntryH4, symbolDigits),
            DoubleToString(recSLH4, symbolDigits), DoubleToString(recTPH4, symbolDigits));
         CreateLabel(panelName+"_LvlH4", h4Str, panelX + 20, y, clrYellow, 8);
         y += lineHeight - 3;
      }
      if(UseSignalD1 && recEntryD1 > 0 && activeMode != "D1")
      {
         string d1Str = StringFormat("🔴 D1: %s @ %s | SL %s | TP %s", 
            recOrderTypeD1, DoubleToString(recEntryD1, symbolDigits),
            DoubleToString(recSLD1, symbolDigits), DoubleToString(recTPD1, symbolDigits));
         CreateLabel(panelName+"_LvlD1", d1Str, panelX + 20, y, clrOrangeRed, 8);
         y += lineHeight - 3;
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
   y += lineHeight + 5;
   
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