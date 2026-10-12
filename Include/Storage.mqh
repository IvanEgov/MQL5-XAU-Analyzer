//+------------------------------------------------------------------+
//|                                                    Storage.mqh   |
//|           СЛОЙ 5: ХРАНИЛИЩЕ (Работа с файлами)                   |
//+------------------------------------------------------------------+
#ifndef STORAGE_MQH
#define STORAGE_MQH

#include <SignalManager.mqh> // Доступ к глобальным переменным состояния и структурам

//+------------------------------------------------------------------+
//| Инициализация имен файлов                                        |
//+------------------------------------------------------------------+
void Storage_InitFiles(string symbol)
{
   string cleanSymbol = symbol;
   StringReplace(cleanSymbol, "/", "_");
   StringReplace(cleanSymbol, "\\", "_");
   StringReplace(cleanSymbol, ":", "_");
   StringReplace(cleanSymbol, "*", "_");
   StringReplace(cleanSymbol, "?", "_");
   StringReplace(cleanSymbol, "\"", "_");
   StringReplace(cleanSymbol, "<", "_");
   StringReplace(cleanSymbol, ">", "_");
   StringReplace(cleanSymbol, "|", "_");
   
   statsFileName = FILE_STATS_PREFIX + cleanSymbol + FILE_STATS_EXT;
   logFileName = FILE_SIGNALS_PREFIX + cleanSymbol + FILE_CSV_EXT;
   resultFileName = FILE_RESULTS_PREFIX + cleanSymbol + FILE_CSV_EXT;
   historyFileName = FILE_HISTORY_PREFIX + cleanSymbol + FILE_HISTORY_EXT;
}

//+------------------------------------------------------------------+
//| Сохранение статистики в файл                                     |
//+------------------------------------------------------------------+
void Storage_SaveStats()
{
   int handle = FileOpen(statsFileName, FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE) { Print("❌ Не удалось сохранить статистику"); return; }
   
   string json = "{\n";
   json += "  \"symbol\": \"" + currentSymbol + "\",\n";
   json += "  \"startDate\": " + IntegerToString((int)statsStartDate) + ",\n";
   json += "  \"total\": " + IntegerToString(totalSignals) + ",\n";
   json += "  \"wins\": " + IntegerToString(winningSignals) + ",\n";
   json += "  \"losses\": " + IntegerToString(losingSignals) + "\n";
   json += "}";
   
   FileWriteString(handle, json);
   FileClose(handle);
}

//+------------------------------------------------------------------+
//| Загрузка статистики из файла                                     |
//+------------------------------------------------------------------+
void Storage_LoadStats()
{
   if(!FileIsExist(statsFileName))
   {
      statsStartDate = TimeCurrent();
      statsSymbol = currentSymbol;
      return;
   }
   
   int handle = FileOpen(statsFileName, FILE_READ|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE) { statsStartDate = TimeCurrent(); return; }
   
   string content = FileReadString(handle, (int)FileSize(handle));
   FileClose(handle);
   
   string savedSymbol = ExtractJsonString(content, "symbol");
   statsStartDate = (datetime)ExtractJsonInt(content, "startDate");
   totalSignals = ExtractJsonInt(content, "total");
   winningSignals = ExtractJsonInt(content, "wins");
   losingSignals = ExtractJsonInt(content, "losses");
   
   if(savedSymbol != currentSymbol) { Storage_ResetStats(); return; }
   
   statsSymbol = currentSymbol;
}

//+------------------------------------------------------------------+
//| Обнуление статистики                                             |
//+------------------------------------------------------------------+
void Storage_ResetStats()
{
   totalSignals = 0; winningSignals = 0; losingSignals = 0; canceledSignals = 0;
   statsStartDate = TimeCurrent(); statsSymbol = currentSymbol;
   lastEntryPrice = 0; signalChecked = false;
   Storage_SaveStats();
}

//+------------------------------------------------------------------+
//| Инициализация логов                                              |
//+------------------------------------------------------------------+
void Storage_InitLogs()
{
   logMonthStart = TimeCurrent();
   if(!FileIsExist(logFileName))
   {
      int handle = FileOpen(logFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
      if(handle != INVALID_HANDLE) { FileWrite(handle, "DateTime", "Symbol", "Mode", "Direction", "Entry", "SL", "TP", "WeightedSum", "ATR", "RR_Ratio"); FileClose(handle); }
   }
   else { Storage_CheckLogRotation(); }
   
   if(!FileIsExist(resultFileName))
   {
      int handle = FileOpen(resultFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
      if(handle != INVALID_HANDLE) { FileWrite(handle, "DateTime", "Symbol", "Mode", "Direction", "Entry", "ExitPrice", "Result", "Movement"); FileClose(handle); }
   }
}

//+------------------------------------------------------------------+
//| Автоочистка лога раз в месяц                                     |
//+------------------------------------------------------------------+
void Storage_CheckLogRotation()
{
   MqlDateTime now, start;
   TimeCurrent(now); TimeToStruct(logMonthStart, start);
   if(now.mon != start.mon || now.year != start.year)
   {
      FileDelete(logFileName); FileDelete(resultFileName);
      int h1 = FileOpen(logFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
      if(h1 != INVALID_HANDLE) { FileWrite(h1, "DateTime", "Symbol", "Mode", "Direction", "Entry", "SL", "TP", "WeightedSum", "ATR", "RR_Ratio"); FileClose(h1); }
      int h2 = FileOpen(resultFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
      if(h2 != INVALID_HANDLE) { FileWrite(h2, "DateTime", "Symbol", "Mode", "Direction", "Entry", "ExitPrice", "Result", "Movement"); FileClose(h2); }
      logMonthStart = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Добавление нового сигнала в историю                              |
//+------------------------------------------------------------------+
void Storage_AddToHistory(string mode, string direction, double entry, double sl, double tp, double weightedSum)
{
   for(int i = 0; i < HISTORY_SIZE - 1; i++) history[i] = history[i + 1];
   history[HISTORY_SIZE - 1].time = TimeCurrent();
   history[HISTORY_SIZE - 1].mode = mode;
   history[HISTORY_SIZE - 1].direction = direction;
   history[HISTORY_SIZE - 1].entry = entry;
   history[HISTORY_SIZE - 1].sl = sl;
   history[HISTORY_SIZE - 1].tp = tp;
   history[HISTORY_SIZE - 1].status = HISTORY_STATUS_WAITING;
   history[HISTORY_SIZE - 1].movement = 0;
   history[HISTORY_SIZE - 1].weightedSum = weightedSum;
   Storage_SaveHistory();
}

//+------------------------------------------------------------------+
//| Обновление статуса последней записи (WIN/LOSS)                   |
//+------------------------------------------------------------------+
void Storage_UpdateHistoryResult(string result, double movement)
{
   for(int i = HISTORY_SIZE - 1; i >= 0; i--)
   {
      if(StringFind(history[i].status, "ОЖИДАНИЕ") >= 0)
      {
         history[i].status = (result == "WIN") ? HISTORY_STATUS_WIN : HISTORY_STATUS_LOSS;
         history[i].movement = movement;
         break;
      }
   }
   Storage_SaveHistory();
}

//+------------------------------------------------------------------+
//| Сохранение истории в файл                                        |
//+------------------------------------------------------------------+
void Storage_SaveHistory()
{
   int handle = FileOpen(historyFileName, FILE_WRITE|FILE_BIN);
   if(handle == INVALID_HANDLE) return;
   int count = 0;
   for(int i = 0; i < HISTORY_SIZE; i++) if(history[i].time > 0) count++;
   FileWriteInteger(handle, count);
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
//| Загрузка истории из файла                                        |
//+------------------------------------------------------------------+
void Storage_LoadHistory()
{
   for(int i = 0; i < HISTORY_SIZE; i++) history[i].Init();
   if(!FileIsExist(historyFileName)) return;
   int handle = FileOpen(historyFileName, FILE_READ|FILE_BIN);
   if(handle == INVALID_HANDLE) return;
   int count = FileReadInteger(handle);
   if(count < 0 || count > HISTORY_SIZE) count = 0;
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
}

//+------------------------------------------------------------------+
//| Запись сигнала в лог                                             |
//+------------------------------------------------------------------+
void Storage_LogSignal(string mode, string direction, double entry, double sl, double tp, double weightedSum, double atr)
{
   int handle = FileOpen(logFileName, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE) return;
   FileSeek(handle, 0, SEEK_END);
   double rrRatio = (MathAbs(entry - sl) > 0) ? MathAbs(tp - entry) / MathAbs(entry - sl) : 0;
   FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES), currentSymbol, mode, direction,
             DoubleToString(entry, symbolDigits), DoubleToString(sl, symbolDigits), DoubleToString(tp, symbolDigits),
             DoubleToString(weightedSum, 1), DoubleToString(atr, symbolDigits), DoubleToString(rrRatio, 2));
   FileClose(handle);
}

//+------------------------------------------------------------------+
//| Запись результата сигнала                                        |
//+------------------------------------------------------------------+
void Storage_LogResult(string mode, string direction, double entry, double exitPrice, string result, double movement)
{
   int handle = FileOpen(resultFileName, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE) return;
   FileSeek(handle, 0, SEEK_END);
   FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES), currentSymbol, mode, direction,
             DoubleToString(entry, symbolDigits), DoubleToString(exitPrice, symbolDigits), result, DoubleToString(movement, symbolDigits));
   FileClose(handle);
}

//+------------------------------------------------------------------+
//| Вспомогательные функции парсинга JSON                            |
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
//| Загрузка активного сигнала из файла при старте                   |
//+------------------------------------------------------------------+
void Storage_LoadActiveSignal()
{
   if(!FileIsExist(logFileName)) return;
   int handle = FileOpen(logFileName, FILE_READ|FILE_CSV|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE) return;
   
   string header = FileReadString(handle);
   datetime lastTime = 0; string lastMode = ""; string lastDir = "";
   double lastEntry = 0, lastSL = 0, lastTP = 0;
   
   while(!FileIsEnding(handle))
   {
      string timeStr = FileReadString(handle); if(timeStr == "") break;
      FileReadString(handle); // symbol
      string mode = FileReadString(handle);
      string dir = FileReadString(handle);
      double entry = StringToDouble(FileReadString(handle));
      double sl = StringToDouble(FileReadString(handle));
      double tp = StringToDouble(FileReadString(handle));
      FileReadString(handle); FileReadString(handle); FileReadString(handle); // ws, atr, rr
      
      lastTime = StringToTime(timeStr);
      lastMode = mode; lastDir = dir;
      lastEntry = entry; lastSL = sl; lastTP = tp;
   }
   FileClose(handle);
   
   if(lastTime == 0 || lastEntry == 0) return;
   if(Storage_IsSignalAlreadyProcessed(lastTime, lastMode, lastDir)) return;
   if((int)((TimeCurrent() - lastTime) / 3600) > 24) return;
   
   lastEntryPrice = lastEntry; lastDirection = lastDir; lastSignalCheckTime = lastTime;
   signalChecked = false; signalWasExecuted = false; activeMode = lastMode;
   
   recEntry = lastEntry; recSL = lastSL; recTP = lastTP;
   recOrderType = (lastDir == "BUY") ? "BUY MARKET" : "SELL MARKET";
   
   if(lastMode == "H1") { recEntryH1 = lastEntry; recSLH1 = lastSL; recTPH1 = lastTP; recOrderTypeH1 = recOrderType; lastSignalH1 = (lastDir == "BUY") ? "CONFIRMED BUY 🟢 [H1]" : "CONFIRMED SELL 🔴 [H1]"; signalFixedH1 = true; }
   else if(lastMode == "H4") { recEntryH4 = lastEntry; recSLH4 = lastSL; recTPH4 = lastTP; recOrderTypeH4 = recOrderType; lastSignalH4 = (lastDir == "BUY") ? "CONFIRMED BUY 🟢 [H4]" : "CONFIRMED SELL 🔴 [H4]"; signalFixedH4 = true; }
   else if(lastMode == "D1") { recEntryD1 = lastEntry; recSLD1 = lastSL; recTPD1 = lastTP; recOrderTypeD1 = recOrderType; lastSignalD1 = (lastDir == "BUY") ? "CONFIRMED BUY 🟢 [D1]" : "CONFIRMED SELL 🔴 [D1]"; signalFixedD1 = true; }
   
   Storage_AddToHistory(lastMode, lastDir, lastEntry, lastSL, lastTP, 0);
   totalSignals++;
   
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(lastDir == "BUY" && currentAsk >= lastEntry) signalWasExecuted = true;
   if(lastDir == "SELL" && currentBid <= lastEntry) signalWasExecuted = true;
}

//+------------------------------------------------------------------+
//| Проверка: был ли сигнал уже отработан                            |
//+------------------------------------------------------------------+
bool Storage_IsSignalAlreadyProcessed(datetime signalTime, string mode, string direction)
{
   if(!FileIsExist(resultFileName)) return false;
   int handle = FileOpen(resultFileName, FILE_READ|FILE_CSV|FILE_ANSI, ';');
   if(handle == INVALID_HANDLE) return false;
   FileReadString(handle); // header
   while(!FileIsEnding(handle))
   {
      string timeStr = FileReadString(handle); if(timeStr == "") break;
      FileReadString(handle); // symbol
      string resMode = FileReadString(handle);
      string resDir = FileReadString(handle);
      if(MathAbs((int)(StringToTime(timeStr) - signalTime)) < 60 && resMode == mode && resDir == direction) { FileClose(handle); return true; }
   }
   FileClose(handle);
   return false;
}

//+------------------------------------------------------------------+
//| Удаление сигнала из файла после отработки                        |
//+------------------------------------------------------------------+
void Storage_RemoveSignalFromLog(datetime signalTime, string mode, string direction)
{
   if(!FileIsExist(logFileName)) return;
   string lines[]; int lineCount = 0;
   int readHandle = FileOpen(logFileName, FILE_READ|FILE_CSV|FILE_ANSI, ';');
   if(readHandle == INVALID_HANDLE) return;
   FileReadString(readHandle); // header
   while(!FileIsEnding(readHandle))
   {
      string timeStr = FileReadString(readHandle); if(timeStr == "") break;
      string symbol = FileReadString(readHandle);
      string resMode = FileReadString(readHandle);
      string resDir = FileReadString(readHandle);
      string entryStr = FileReadString(readHandle);
      string slStr = FileReadString(readHandle);
      string tpStr = FileReadString(readHandle);
      string wsStr = FileReadString(readHandle);
      string atrStr = FileReadString(readHandle);
      string rrStr = FileReadString(readHandle);
      
      if(MathAbs((int)(StringToTime(timeStr) - signalTime)) < 60 && resMode == mode && resDir == direction) continue;
      
      ArrayResize(lines, lineCount + 1);
      lines[lineCount] = timeStr + ";" + symbol + ";" + resMode + ";" + resDir + ";" + entryStr + ";" + slStr + ";" + tpStr + ";" + wsStr + ";" + atrStr + ";" + rrStr;
      lineCount++;
   }
   FileClose(readHandle);
   
   int writeHandle = FileOpen(logFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(writeHandle == INVALID_HANDLE) return;
   FileWrite(writeHandle, "DateTime", "Symbol", "Mode", "Direction", "Entry", "SL", "TP", "WeightedSum", "ATR", "RR_Ratio");
   for(int i = 0; i < lineCount; i++)
   {
      string parts[];
      if(StringSplit(lines[i], ';', parts) >= 10)
         FileWrite(writeHandle, parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9]);
   }
   FileClose(writeHandle);
}

#endif