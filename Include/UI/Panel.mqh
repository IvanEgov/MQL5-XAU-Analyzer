//+------------------------------------------------------------------+
//| Panel.mqh                                                        |
//| СЛОЙ 6: UI - Управление панелью и ВСЕМИ вкладками                |
//+------------------------------------------------------------------+
#ifndef UI_PANEL_MQH
#define UI_PANEL_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

//--- Состояние UI
int currentTab = 0;
bool isCollapsed = false;

//--- Данные для отрисовки (заполняются главным файлом)
IndicatorVotes g_resultH1;
IndicatorVotes g_resultH4;
IndicatorVotes g_resultD1;
string g_currentSymbol;
double g_symbolPoint;

//+------------------------------------------------------------------+
//| Создание текстовой метки (ОБЩАЯ для всех вкладок)                |
//+------------------------------------------------------------------+
void UI_CreateLabel(const string name, int x, int y, const string text, color clr, int fontSize, bool bold)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, false); // ПОВЕРХ СВЕЧЕЙ!
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
}

#include <UI/TabAnalysis.mqh>

//+------------------------------------------------------------------+
//| Диспетчер отрисовки вкладок (ИСПРАВЛЕНО: все вкладки активны)    |
//+------------------------------------------------------------------+
void UI_DrawCurrentTab()
{
   UI_DeleteTabContent(currentTab); // Очищаем старое
   
   int y = PANEL_Y + 70;
   int lineHeight = PANEL_LINE_HEIGHT;
   string priceFormat = "%." + IntegerToString((int)SymbolInfoInteger(g_currentSymbol, SYMBOL_DIGITS)) + "f";
   
   string pageInfo = StringFormat("📑 Стр. %d/%d: %s", currentTab + 1, TAB_COUNT, TAB_NAMES[currentTab]);
   UI_CreateLabel(PANEL_NAME + "_PageInfo", pageInfo, PANEL_X + 10, y, clrWheat, 9);
   y += lineHeight + 5;
   
   if(currentTab == 0) UI_DrawTabAnalysis(g_resultH1, g_resultH4, g_resultD1, g_currentSymbol, g_symbolPoint);
   else if(currentTab == 1) UI_DrawTabFilters(y, lineHeight);
   else if(currentTab == 2) UI_DrawTabLevels(y, lineHeight, priceFormat);
   else if(currentTab == 3) UI_DrawTabStats(y, lineHeight);
   else if(currentTab == 4) UI_DrawTabHistory(y, lineHeight, priceFormat);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Вкладка 1: ФИЛЬТРЫ                                               |
//+------------------------------------------------------------------+
void UI_DrawTabFilters(int y, int lineHeight)
{
   string modesStr = "🎛️ Режимы: " + (UseSignalH1?"🟢H1 ":"⚫H1 ") + (UseSignalH4?"🟡H4 ":"⚫H4 ") + (UseSignalD1?"🔴D1 ":"⚫D1 ");
   UI_CreateLabel(PANEL_NAME+"_C1_Modes", modesStr, PANEL_X+10, y, clrWheat, 9); y += lineHeight+3;
   UI_CreateLabel(PANEL_NAME+"_C1_Title", "🛡️ ФИЛЬТРЫ ТОЧНОСТИ:", PANEL_X+10, y, clrYellow, 11); y += lineHeight+3;
   
   UI_CreateLabel(PANEL_NAME+"_C1_F1", (filterNews?"✅ ":"❌ ")+"📰 Новости (±30 мин)", PANEL_X+25, y, filterNews?clrLime:clrRed, 10); y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C1_F2", (filterVolatility?"✅ ":"❌ ")+"📊 Волатильность (ATR)", PANEL_X+25, y, filterVolatility?clrLime:clrRed, 10); y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C1_F3", (filterSession?"✅ ":"❌ ")+"🕐 Сессия (8-22)", PANEL_X+25, y, filterSession?clrLime:clrRed, 10); y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C1_F4", (filterCandle?"✅ ":"❌ ")+"🕯️ Свечной паттерн", PANEL_X+25, y, filterCandle?clrLime:clrRed, 10); y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C1_F5", (filterRSI?"✅ ":"❌ ")+"📈 RSI (не экстремум)", PANEL_X+25, y, filterRSI?clrLime:clrRed, 10); y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C1_F6", (filterStructure?"✅ ":"❌ ")+"🧱 Структура (уровни)", PANEL_X+25, y, filterStructure?clrLime:clrRed, 10); y += lineHeight+5;
   
   UI_CreateLabel(PANEL_NAME+"_C1_Sep", "═══════════════════════════════════════════════════════", PANEL_X+10, y, clrDodgerBlue, 9); y += lineHeight;
   
   bool allFilters = filterNews && filterVolatility && filterSession && filterCandle && filterRSI && filterStructure;
   string confirmStatus = allFilters ? ((g_resultH1.weightedSum>0)?"🟢 CONFIRMED BUY 🔔":"🔴 CONFIRMED SELL 🔔") : StringFormat("⏳ Фильтры: %d/6 пройдено", (filterNews+filterVolatility+filterSession+filterCandle+filterRSI+filterStructure));
   color confirmColor = allFilters ? ((g_resultH1.weightedSum>0)?clrLime:clrRed) : clrOrange;
   UI_CreateLabel(PANEL_NAME+"_C1_Confirm", confirmStatus, PANEL_X+20, y, confirmColor, 11);
}

//+------------------------------------------------------------------+
//| Вкладка 2: УРОВНИ                                                |
//+------------------------------------------------------------------+
void UI_DrawTabLevels(int y, int lineHeight, string priceFormat)
{
   UI_CreateLabel(PANEL_NAME+"_C2_Title", "📊 РЕКОМЕНДУЕМЫЕ УРОВНИ:", PANEL_X+10, y, clrYellow, 11); y += lineHeight+5;
   
   if(recEntry > 0)
   {
      color activeColor = (activeMode=="H1")?clrLime:((activeMode=="H4")?clrYellow:clrOrangeRed);
      string activePrefix = (activeMode=="H1")?"🟢":((activeMode=="H4")?"🟡":"🔴");
      UI_CreateLabel(PANEL_NAME+"_C2_Entry", StringFormat("%s ВХОД (%s): %s", activePrefix, recOrderType, DoubleToString(recEntry, symbolDigits)), PANEL_X+20, y, activeColor, 10); y += lineHeight;
      
      double slDist = MathAbs(recEntry - recSL);
      string slPips = (g_resultH1.atrValue>0) ? StringFormat(" (-%.1f ATR)", slDist/g_resultH1.atrValue) : "";
      UI_CreateLabel(PANEL_NAME+"_C2_SL", StringFormat("🛑 STOP LOSS: %s", DoubleToString(recSL, symbolDigits))+slPips, PANEL_X+20, y, SLColor, 10); y += lineHeight;
      
      double tpDist = MathAbs(recTP - recEntry);
      string rr = (slDist>0) ? StringFormat(" (R:R 1:%.1f)", tpDist/slDist) : "";
      UI_CreateLabel(PANEL_NAME+"_C2_TP", StringFormat("🎯 TAKE PROFIT: %s", DoubleToString(recTP, symbolDigits))+rr, PANEL_X+20, y, TPColor, 10); y += lineHeight+5;
      
      double rrRatio = (slDist>0) ? tpDist/slDist : 0;
      color rrColor = (rrRatio>=2.0)?clrLime:((rrRatio>=1.5)?clrYellow:((rrRatio>=1.0)?clrOrange:clrRed));
      UI_CreateLabel(PANEL_NAME+"_C2_RR", StringFormat("💰 Risk/Reward = 1:%.2f %s", rrRatio, rrRatio>=2.0?"✅ ОТЛИЧНО":(rrRatio>=1.5?"✅ ХОРОШО":(rrRatio>=1.0?"⚠️ НОРМ":"❌ ПЛОХО"))), PANEL_X+20, y, rrColor, 10); y += lineHeight+5;
      
      UI_CreateLabel(PANEL_NAME+"_C2_Struct", "🧱 Структурные уровни (H4):", PANEL_X+10, y, clrYellow, 10); y += lineHeight;
      UI_CreateLabel(PANEL_NAME+"_C2_Res", (nearestResistance>0)?StringFormat("🔸 Сопротивление: %s", DoubleToString(nearestResistance, symbolDigits)):"🔸 Сопротивление: не найдено", PANEL_X+20, y, (nearestResistance>0)?clrOrange:clrGray, 9); y += lineHeight;
      UI_CreateLabel(PANEL_NAME+"_C2_Sup", (nearestSupport>0)?StringFormat("🔹 Поддержка: %s", DoubleToString(nearestSupport, symbolDigits)):"🔹 Поддержка: не найдена", PANEL_X+20, y, (nearestSupport>0)?clrDeepSkyBlue:clrGray, 9);
   }
   else
   {
      UI_CreateLabel(PANEL_NAME+"_C2_No", "⏸ Уровни появятся при подтверждении сигнала", PANEL_X+20, y, clrGray, 10); y += lineHeight;
      UI_CreateLabel(PANEL_NAME+"_C2_Hint", "💡 Ждите подтверждения сигнала", PANEL_X+20, y, clrWheat, 9);
   }
}

//+------------------------------------------------------------------+
//| Вкладка 3: СТАТИСТИКА                                            |
//+------------------------------------------------------------------+
void UI_DrawTabStats(int y, int lineHeight)
{
   UI_CreateLabel(PANEL_NAME+"_C3_Title", "📈 СТАТИСТИКА ТОЧНОСТИ:", PANEL_X+10, y, clrYellow, 11); y += lineHeight+5;
   UI_CreateLabel(PANEL_NAME+"_C3_Date", "📅 Сбор начат: " + TimeToString(statsStartDate, TIME_DATE), PANEL_X+20, y, clrGray, 9); y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C3_S1", StringFormat("📊 Всего сигналов: %d", totalSignals), PANEL_X+20, y, clrLightGray, 10); y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C3_S2", StringFormat("✅ Верных: %d", winningSignals), PANEL_X+20, y, clrLime, 10); y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C3_S3", StringFormat("❌ Ошибок: %d", losingSignals), PANEL_X+20, y, clrRed, 10); y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C3_S4", StringFormat("⏸ Аннулировано: %d", canceledSignals), PANEL_X+20, y, clrGray, 10); y += lineHeight+5;
   
   UI_CreateLabel(PANEL_NAME+"_C3_Sep", "═══════════════════════════════════════════════════════", PANEL_X+10, y, clrDodgerBlue, 9); y += lineHeight+3;
   
   double accuracy = (totalSignals==0) ? 0 : (winningSignals * 100.0 / (winningSignals + losingSignals));
   color accColor = (accuracy>=70)?clrLime:((accuracy>=55)?clrOrange:(totalSignals>0?clrRed:clrGray));
   UI_CreateLabel(PANEL_NAME+"_C3_Acc", StringFormat("🎯 ТОЧНОСТЬ: %.1f%%", accuracy), PANEL_X+20, y, accColor, 14); y += lineHeight+5;
   
   string gradeStr = (totalSignals==0)?"⏳ Нет данных":((accuracy>=ACCURACY_EXCELLENT)?"🏆 ОТЛИЧНО":((accuracy>=ACCURACY_GOOD)?"✅ ХОРОШО":((accuracy>=ACCURACY_NORMAL)?"⚠️ НОРМАЛЬНО":"❗ ТРЕБУЕТ НАСТРОЙКИ")));
   color gradeColor = (totalSignals==0)?clrGray:((accuracy>=ACCURACY_EXCELLENT)?clrLime:((accuracy>=ACCURACY_GOOD)?clrGreen:((accuracy>=ACCURACY_NORMAL)?clrOrange:clrRed)));
   UI_CreateLabel(PANEL_NAME+"_C3_Grade", gradeStr, PANEL_X+20, y, gradeColor, 11); y += lineHeight+10;
   
   // Кнопка RESET
   string resetBtn = PANEL_NAME+"_C3_Reset";
   if(ObjectFind(0, resetBtn) < 0) {
      ObjectCreate(0, resetBtn, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, resetBtn, OBJPROP_XDISTANCE, PANEL_X+PANEL_WIDTH-110);
      ObjectSetInteger(0, resetBtn, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, resetBtn, OBJPROP_XSIZE, 100); ObjectSetInteger(0, resetBtn, OBJPROP_YSIZE, 26);
      ObjectSetString(0, resetBtn, OBJPROP_TEXT, "🗑️ RESET");
      ObjectSetInteger(0, resetBtn, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, resetBtn, OBJPROP_BGCOLOR, C'140,40,40');
      ObjectSetInteger(0, resetBtn, OBJPROP_FONTSIZE, 10); ObjectSetString(0, resetBtn, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, resetBtn, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, resetBtn, OBJPROP_HIDDEN, true); ObjectSetInteger(0, resetBtn, OBJPROP_BACK, false);
   }
   y += 35;
   
   // Кнопка БЭКТЕСТ
   string testBtn = PANEL_NAME+"_C3_Backtest";
   if(ObjectFind(0, testBtn) < 0) {
      ObjectCreate(0, testBtn, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, testBtn, OBJPROP_XDISTANCE, PANEL_X+20);
      ObjectSetInteger(0, testBtn, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, testBtn, OBJPROP_XSIZE, PANEL_WIDTH-40); ObjectSetInteger(0, testBtn, OBJPROP_YSIZE, 30);
      ObjectSetString(0, testBtn, OBJPROP_TEXT, isBacktestRunning ? "⏳ ТЕСТ ЗАПУЩЕН..." : "🧪 ЗАПУСТИТЬ БЭКТЕСТ");
      ObjectSetInteger(0, testBtn, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, testBtn, OBJPROP_BGCOLOR, isBacktestRunning ? C'100,100,50' : C'40,100,40');
      ObjectSetInteger(0, testBtn, OBJPROP_FONTSIZE, 10); ObjectSetString(0, testBtn, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, testBtn, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, testBtn, OBJPROP_HIDDEN, true); ObjectSetInteger(0, testBtn, OBJPROP_BACK, false);
   }
}

//+------------------------------------------------------------------+
//| Вкладка 4: ИСТОРИЯ                                               |
//+------------------------------------------------------------------+
void UI_DrawTabHistory(int y, int lineHeight, string priceFormat)
{
   UI_CreateLabel(PANEL_NAME+"_C4_Title", "📜 ИСТОРИЯ ПОСЛЕДНИХ СИГНАЛОВ:", PANEL_X+10, y, clrYellow, 11); y += lineHeight+3;
   UI_CreateLabel(PANEL_NAME+"_C4_H1", "ВРЕМЯ", PANEL_X+15, y, clrDodgerBlue, 9);
   UI_CreateLabel(PANEL_NAME+"_C4_H2", "ТФ", PANEL_X+110, y, clrDodgerBlue, 9);
   UI_CreateLabel(PANEL_NAME+"_C4_H3", "НАПР", PANEL_X+145, y, clrDodgerBlue, 9);
   UI_CreateLabel(PANEL_NAME+"_C4_H4", "ВХОД", PANEL_X+190, y, clrDodgerBlue, 9);
   UI_CreateLabel(PANEL_NAME+"_C4_H5", "СТАТУС", PANEL_X+290, y, clrDodgerBlue, 9);
   y += lineHeight;
   UI_CreateLabel(PANEL_NAME+"_C4_Sep", "─────────────────────────────────────────────────────────", PANEL_X+10, y, clrGray, 9); y += lineHeight;
   
   int realCount = 0;
   for(int i = 0; i < HISTORY_SIZE; i++) if(history[i].time > 0) realCount++;
   
   if(realCount == 0) {
      UI_CreateLabel(PANEL_NAME+"_C4_Empty", "⏸ История пуста — ждём первый сигнал", PANEL_X+20, y, clrGray, 10);
      return;
   }
   
   for(int i = HISTORY_SIZE - 1; i >= 0; i--)
   {
      if(history[i].time == 0) continue;
      string timeStr = TimeToString(history[i].time, TIME_DATE|TIME_MINUTES);
      StringSetCharacter(timeStr, 4, '-'); StringSetCharacter(timeStr, 7, '-');
      
      UI_CreateLabel(PANEL_NAME+"_C4_T_"+IntegerToString(i), timeStr, PANEL_X+15, y, clrLightGray, 8);
      color modeColor = (history[i].mode=="H1")?clrLime:((history[i].mode=="H4")?clrYellow:clrOrangeRed);
      UI_CreateLabel(PANEL_NAME+"_C4_M_"+IntegerToString(i), history[i].mode, PANEL_X+115, y, modeColor, 9);
      color dirColor = (history[i].direction=="BUY")?clrLime:clrRed;
      UI_CreateLabel(PANEL_NAME+"_C4_D_"+IntegerToString(i), (history[i].direction=="BUY")?"▲ BUY":"▼ SELL", PANEL_X+145, y, dirColor, 8);
      UI_CreateLabel(PANEL_NAME+"_C4_E_"+IntegerToString(i), DoubleToString(history[i].entry, symbolDigits), PANEL_X+190, y, clrWhite, 8);
      color statusColor = (StringFind(history[i].status, "WIN")>=0)?clrLime:((StringFind(history[i].status, "LOSS")>=0)?clrRed:clrOrange);
      UI_CreateLabel(PANEL_NAME+"_C4_S_"+IntegerToString(i), history[i].status, PANEL_X+285, y, statusColor, 8);
      y += lineHeight - 2;
   }
}

//+------------------------------------------------------------------+
//| Создать основную панель                                          |
//+------------------------------------------------------------------+
void UI_CreateBasePanel()
{
   ObjectCreate(0, PANEL_NAME, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XDISTANCE, PANEL_X);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YDISTANCE, PANEL_Y);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XSIZE, PANEL_WIDTH);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YSIZE, isCollapsed ? PANEL_HEIGHT_COLLAPSED : PANEL_HEIGHT_EXPANDED);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BGCOLOR, C'25, 25, 35'); // Красивый темный фон
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BORDER_TYPE, BORDER_RAISED);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_COLOR, C'60, 100, 160'); // Синяя рамка
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BACK, false); // !!! ПОВЕРХ СВЕЧЕЙ !!!
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_HIDDEN, true);

   string btnName = PANEL_NAME + "_CollapseBtn";
   ObjectCreate(0, btnName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, btnName, OBJPROP_XDISTANCE, PANEL_X + PANEL_WIDTH - 30);
   ObjectSetInteger(0, btnName, OBJPROP_YDISTANCE, PANEL_Y + 5);
   ObjectSetInteger(0, btnName, OBJPROP_XSIZE, 25); ObjectSetInteger(0, btnName, OBJPROP_YSIZE, 25);
   ObjectSetString(0, btnName, OBJPROP_TEXT, isCollapsed ? "+" : "−");
   ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, C'60, 100, 160');
   ObjectSetInteger(0, btnName, OBJPROP_FONTSIZE, 14); ObjectSetString(0, btnName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, btnName, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, btnName, OBJPROP_HIDDEN, true); ObjectSetInteger(0, btnName, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Создать вкладки                                                  |
//+------------------------------------------------------------------+
void UI_CreateTabs()
{
   if(isCollapsed) return;
   int yOffset = PANEL_Y + 35;
   int tabWidth = PANEL_WIDTH / TAB_COUNT;
   
   for(int i = 0; i < TAB_COUNT; i++)
   {
      string tabName = PANEL_NAME + "_Tab_" + IntegerToString(i);
      ObjectCreate(0, tabName, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, tabName, OBJPROP_XDISTANCE, PANEL_X + (i * tabWidth));
      ObjectSetInteger(0, tabName, OBJPROP_YDISTANCE, yOffset);
      ObjectSetInteger(0, tabName, OBJPROP_XSIZE, tabWidth); ObjectSetInteger(0, tabName, OBJPROP_YSIZE, 25);
      ObjectSetString(0, tabName, OBJPROP_TEXT, TAB_NAMES[i]);
      
      if(i == currentTab) {
         ObjectSetInteger(0, tabName, OBJPROP_COLOR, clrBlack);
         ObjectSetInteger(0, tabName, OBJPROP_BGCOLOR, C'100, 160, 220'); // Активная вкладка
      } else {
         ObjectSetInteger(0, tabName, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, tabName, OBJPROP_BGCOLOR, C'40, 45, 60');    // Неактивная вкладка
      }
      ObjectSetInteger(0, tabName, OBJPROP_FONTSIZE, 9); ObjectSetString(0, tabName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, tabName, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, tabName, OBJPROP_HIDDEN, true); ObjectSetInteger(0, tabName, OBJPROP_BACK, false);
   }
   UI_DrawCurrentTab();
}

//+------------------------------------------------------------------+
//| Удалить все элементы панели                                      |
//+------------------------------------------------------------------+
void UI_DeleteAll()
{
   ObjectDelete(0, PANEL_NAME + "_CollapseBtn");
   for(int i = 0; i < TAB_COUNT; i++) ObjectDelete(0, PANEL_NAME + "_Tab_" + IntegerToString(i));
   UI_DeleteTabContent(0); UI_DeleteTabContent(1); UI_DeleteTabContent(2); UI_DeleteTabContent(3); UI_DeleteTabContent(4);
   ObjectDelete(0, PANEL_NAME);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Очистка содержимого вкладки (метки и кнопки)                     |
//+------------------------------------------------------------------+
void UI_DeleteTabContent(int tabIdx)
{
   string prefix = PANEL_NAME + "_Content_" + IntegerToString(tabIdx) + "_";
   
   int totalLabels = ObjectsTotal(0, 0, OBJ_LABEL);
   for(int i = totalLabels - 1; i >= 0; i--) {
      string name = ObjectName(0, i, 0, OBJ_LABEL);
      if(StringFind(name, prefix) == 0) ObjectDelete(0, name);
   }
   int totalButtons = ObjectsTotal(0, 0, OBJ_BUTTON);
   for(int i = totalButtons - 1; i >= 0; i--) {
      string name = ObjectName(0, i, 0, OBJ_BUTTON);
      if(StringFind(name, prefix) == 0) ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+
//| Обработка кликов                                                 |
//+------------------------------------------------------------------+
bool UI_OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == PANEL_NAME + "_CollapseBtn") {
         isCollapsed = !isCollapsed;
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         UI_DeleteAll(); UI_CreateBasePanel();
         if(!isCollapsed) UI_CreateTabs();
         ChartRedraw(); return true;
      }
      
      for(int i = 0; i < TAB_COUNT; i++) {
         if(sparam == PANEL_NAME + "_Tab_" + IntegerToString(i)) {
            if(currentTab != i) {
               currentTab = i;
               ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
               UI_DeleteAll(); UI_CreateBasePanel(); UI_CreateTabs();
               ChartRedraw();
            }
            return true;
         }
      }
      
      // Клик по кнопке RESET
      if(StringFind(sparam, PANEL_NAME + "_C3_Reset") >= 0) {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         if(MessageBox("Обнулить всю статистику?\n\nЭто действие нельзя отменить.", "Подтверждение", MB_YESNO|MB_ICONQUESTION) == IDYES) {
            Storage_ResetStats();
            UI_DeleteAll(); UI_CreateBasePanel(); if(!isCollapsed) UI_CreateTabs();
            ChartRedraw();
         }
         return true;
      }
      
      // Клик по кнопке БЭКТЕСТ
      if(StringFind(sparam, PANEL_NAME + "_C3_Backtest") >= 0) {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         if(isBacktestRunning) { Print("⏳ Бэктест уже запущен"); return true; }
         isBacktestRunning = true;
         UI_DeleteAll(); UI_CreateBasePanel(); if(!isCollapsed) UI_CreateTabs(); ChartRedraw();
         RunBacktest(); 
         isBacktestRunning = false;
         UI_DeleteAll(); UI_CreateBasePanel(); if(!isCollapsed) UI_CreateTabs(); ChartRedraw();
         return true;
      }
   }
   return false;
}

#endif