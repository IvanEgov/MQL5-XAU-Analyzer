//+------------------------------------------------------------------+
//| Panel.mqh                                                        |
//+------------------------------------------------------------------+
#ifndef UI_PANEL_MQH
#define UI_PANEL_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

// =========================================================================
// СВЯЗЬ С ГЛОБАЛЬНЫМИ ПЕРЕМЕННЫМИ ФИЛЬТРОВ ИЗ ГЛАВНОГО ФАЙЛА
// =========================================================================
extern bool filterNews;
extern bool filterVolatility;
extern bool filterSession;
extern bool filterCandle;
extern bool filterRSI;
extern bool filterStructure;
// =========================================================================

// Глобальные переменные состояния UI
int currentTab = 0;
bool isCollapsed = false;
IndicatorVotes g_resultH1, g_resultH4, g_resultD1;
string g_currentSymbol;
double g_symbolPoint;

// --- Вспомогательная функция создания метки (ВСЕГДА ПОВЕРХ СВЕЧЕЙ) ---
void UI_CreateLabel(string name, int x, int y, string text, color clr, int fontSize, bool bold)
{
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, false); // !!! ПОВЕРХ СВЕЧЕЙ !!!
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
}

// Подключаем вкладки
#include <UI/TabAnalysis.mqh>
#include <UI/TabFilters.mqh>
#include <UI/TabLevels.mqh>
#include <UI/TabStats.mqh>
#include <UI/TabHistory.mqh>

// --- Создание панели и кнопок ---
void UI_CreateBasePanel()
{
   ObjectCreate(0, PANEL_NAME, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XDISTANCE, PANEL_X);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YDISTANCE, PANEL_Y);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XSIZE, PANEL_WIDTH);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YSIZE, isCollapsed ? PANEL_HEIGHT_COLLAPSED : PANEL_HEIGHT_EXPANDED);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BGCOLOR, C'25, 25, 35');
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BORDER_TYPE, BORDER_RAISED);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_COLOR, C'60, 100, 160');
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BACK, false); // !!! ПОВЕРХ СВЕЧЕЙ !!!
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_HIDDEN, true);

   string btn = PANEL_NAME + "_CollapseBtn";
   ObjectCreate(0, btn, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, btn, OBJPROP_XDISTANCE, PANEL_X + PANEL_WIDTH - 30);
   ObjectSetInteger(0, btn, OBJPROP_YDISTANCE, PANEL_Y + 5);
   ObjectSetInteger(0, btn, OBJPROP_XSIZE, 25); ObjectSetInteger(0, btn, OBJPROP_YSIZE, 25);
   ObjectSetString(0, btn, OBJPROP_TEXT, isCollapsed ? "+" : "−");
   ObjectSetInteger(0, btn, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, btn, OBJPROP_BGCOLOR, C'60, 100, 160');
   ObjectSetInteger(0, btn, OBJPROP_FONTSIZE, 14); ObjectSetString(0, btn, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, btn, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, btn, OBJPROP_HIDDEN, true); ObjectSetInteger(0, btn, OBJPROP_BACK, false);
}

void UI_CreateTabs()
{
   if(isCollapsed) return;
   int yOff = PANEL_Y + 35;
   int tWidth = PANEL_WIDTH / TAB_COUNT;
   for(int i = 0; i < TAB_COUNT; i++) {
      string tName = PANEL_NAME + "_Tab_" + (string)i;
      ObjectCreate(0, tName, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, tName, OBJPROP_XDISTANCE, PANEL_X + (i * tWidth));
      ObjectSetInteger(0, tName, OBJPROP_YDISTANCE, yOff);
      ObjectSetInteger(0, tName, OBJPROP_XSIZE, tWidth); ObjectSetInteger(0, tName, OBJPROP_YSIZE, 25);
      ObjectSetString(0, tName, OBJPROP_TEXT, TAB_NAMES[i]);
      if(i == currentTab) {
         ObjectSetInteger(0, tName, OBJPROP_COLOR, clrBlack); ObjectSetInteger(0, tName, OBJPROP_BGCOLOR, C'100, 160, 220');
      } else {
         ObjectSetInteger(0, tName, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, tName, OBJPROP_BGCOLOR, C'40, 45, 60');
      }
      ObjectSetInteger(0, tName, OBJPROP_FONTSIZE, 9); ObjectSetString(0, tName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, tName, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, tName, OBJPROP_HIDDEN, true); ObjectSetInteger(0, tName, OBJPROP_BACK, false);
   }
   UI_DrawCurrentTab();
}

// --- Диспетчер отрисовки ---
void UI_DrawCurrentTab()
{
   UI_DeleteTabContent(currentTab);
   int y = PANEL_Y + 70;
   int lh = PANEL_LINE_HEIGHT;
   int digits = (int)SymbolInfoInteger(g_currentSymbol, SYMBOL_DIGITS);
   
   string pInfo = "📑 Стр. " + (string)(currentTab + 1) + "/" + (string)TAB_COUNT + ": " + TAB_NAMES[currentTab];
   UI_CreateLabel(PANEL_NAME + "_PageInfo", PANEL_X + 10, y, pInfo, clrWheat, 9, false); y += lh + 5;
   
   if(currentTab == 0) UI_DrawTabAnalysis(y, lh, digits);
   else if(currentTab == 1) UI_DrawTabFilters(y, lh);
   else if(currentTab == 2) UI_DrawTabLevels(y, lh, digits);
   else if(currentTab == 3) UI_DrawTabStats(y, lh);
   else if(currentTab == 4) UI_DrawTabHistory(y, lh, digits);
   
   ChartRedraw();
}

// --- Очистка ---
void UI_DeleteAll()
{
   ObjectDelete(0, PANEL_NAME + "_CollapseBtn");
   for(int i = 0; i < TAB_COUNT; i++) ObjectDelete(0, PANEL_NAME + "_Tab_" + (string)i);
   for(int i = 0; i < 5; i++) UI_DeleteTabContent(i);
   ObjectDelete(0, PANEL_NAME);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Очистка содержимого вкладки                                      |
//+------------------------------------------------------------------+
void UI_DeleteTabContent(int idx)
{
   string pfx = PANEL_NAME + "_C" + (string)idx + "_";
   
   // Удаляем текстовые метки (OBJ_LABEL)
   int totalLabels = ObjectsTotal(0, 0, OBJ_LABEL);
   for(int i = totalLabels - 1; i >= 0; i--) {
      string name = ObjectName(0, i, 0, OBJ_LABEL);
      if(StringFind(name, pfx) == 0) ObjectDelete(0, name);
   }
   
   // Удаляем кнопки (OBJ_BUTTON)
   int totalButtons = ObjectsTotal(0, 0, OBJ_BUTTON);
   for(int i = totalButtons - 1; i >= 0; i--) {
      string name = ObjectName(0, i, 0, OBJ_BUTTON);
      if(StringFind(name, pfx) == 0) ObjectDelete(0, name);
   }
   
   // Удаляем прямоугольники (OBJ_RECTANGLE_LABEL) — прогресс-бар и т.д.
   int totalRects = ObjectsTotal(0, 0, OBJ_RECTANGLE_LABEL);
   for(int i = totalRects - 1; i >= 0; i--) {
      string name = ObjectName(0, i, 0, OBJ_RECTANGLE_LABEL);
      if(StringFind(name, pfx) == 0) ObjectDelete(0, name);
   }
}

// --- Обработка кликов ---
//+------------------------------------------------------------------+
//| Обработка кликов (ИСПРАВЛЕНО: добавлены const)                   |
//+------------------------------------------------------------------+
bool UI_OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK) 
   {
      // Клик по кнопке сворачивания
      if(sparam == PANEL_NAME + "_CollapseBtn") 
      {
         isCollapsed = !isCollapsed; 
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         UI_DeleteAll(); 
         UI_CreateBasePanel(); 
         if(!isCollapsed) UI_CreateTabs(); 
         ChartRedraw(); 
         return true;
      }
      
      // Клик по вкладкам
      for(int i = 0; i < TAB_COUNT; i++) 
      {
         if(sparam == PANEL_NAME + "_Tab_" + (string)i) 
         {
            if(currentTab != i) 
            {
               currentTab = i; 
               ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
               UI_DeleteAll(); 
               UI_CreateBasePanel(); 
               UI_CreateTabs(); 
               ChartRedraw();
            }
            return true;
         }
      }
      
      // Клик по кнопке RESET
      if(StringFind(sparam, PANEL_NAME + "_C3_Reset") >= 0) 
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         if(MessageBox("Обнулить статистику И закрыть все позиции/ордера?\n\n⚠️ Это реальная операция с вашим счётом!", 
                       "Подтверждение", MB_YESNO|MB_ICONWARNING) == IDYES) 
         {
            Executor_CloseAll();      // ← Закрываем всё реальное
            Storage_ResetStats();  
            UI_DeleteAll(); 
            UI_CreateBasePanel(); 
            if(!isCollapsed) UI_CreateTabs(); 
            ChartRedraw();
         }
         return true;
      }
      
      // Клик по кнопке БЭКТЕСТ
      if(StringFind(sparam, PANEL_NAME + "_C3_Backtest") >= 0) 
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         if(isBacktestRunning) { Print("⏳ Бэктест уже запущен"); return true; }
         
         isBacktestRunning = true; 
         UI_DeleteAll(); 
         UI_CreateBasePanel(); 
         if(!isCollapsed) UI_CreateTabs(); 
         ChartRedraw();
         
         RunBacktest(); 
         
         isBacktestRunning = false; 
         UI_DeleteAll(); 
         UI_CreateBasePanel(); 
         if(!isCollapsed) UI_CreateTabs(); 
         ChartRedraw();
         return true;
      }
   }
   return false;
}
#endif