//+------------------------------------------------------------------+
//| Panel.mqh                                                        |
//| СЛОЙ 6: UI - Управление основной панелью и вкладками             |
//+------------------------------------------------------------------+
#ifndef UI_PANEL_MQH
#define UI_PANEL_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

//--- Глобальные переменные состояния UI (доступны главному файлу)
int currentTab = 0;
bool isCollapsed = false;

//+------------------------------------------------------------------+
//| Создать основную панель и кнопку сворачивания                    |
//+------------------------------------------------------------------+
void UI_CreateBasePanel()
{
   // Фон панели
   ObjectCreate(0, PANEL_NAME, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XDISTANCE, PANEL_X);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YDISTANCE, PANEL_Y);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XSIZE, PANEL_WIDTH);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YSIZE, isCollapsed ? PANEL_HEIGHT_COLLAPSED : PANEL_HEIGHT_EXPANDED);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BACK, true);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_HIDDEN, true);

   // Кнопка сворачивания/разворачивания
   string btnName = PANEL_NAME + "_CollapseBtn";
   ObjectCreate(0, btnName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, btnName, OBJPROP_XDISTANCE, PANEL_X + PANEL_WIDTH - 30);
   ObjectSetInteger(0, btnName, OBJPROP_YDISTANCE, PANEL_Y + 5);
   ObjectSetInteger(0, btnName, OBJPROP_XSIZE, 25);
   ObjectSetInteger(0, btnName, OBJPROP_YSIZE, 25);
   ObjectSetString(0, btnName, OBJPROP_TEXT, isCollapsed ? "+" : "−");
   ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, clrDarkGray);
   ObjectSetInteger(0, btnName, OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, btnName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, btnName, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Создать вкладки (заглушка для детальной реализации)              |
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
      ObjectSetInteger(0, tabName, OBJPROP_XSIZE, tabWidth);
      ObjectSetInteger(0, tabName, OBJPROP_YSIZE, 25);
      ObjectSetString(0, tabName, OBJPROP_TEXT, TAB_NAMES[i]);
      ObjectSetInteger(0, tabName, OBJPROP_COLOR, (i == currentTab) ? clrBlack : clrWhite);
      ObjectSetInteger(0, tabName, OBJPROP_BGCOLOR, (i == currentTab) ? clrWhite : clrDarkGray);
      ObjectSetInteger(0, tabName, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, tabName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, tabName, OBJPROP_HIDDEN, true);
   }
   
   // Здесь позже вызовем UI_UpdateTabContent(currentTab);
}

//+------------------------------------------------------------------+
//| Удалить все элементы панели                                      |
//+------------------------------------------------------------------+
void UI_DeleteAll()
{
   // Удаляем кнопку сворачивания
   ObjectDelete(0, PANEL_NAME + "_CollapseBtn");
   
   // Удаляем вкладки
   for(int i = 0; i < TAB_COUNT; i++)
   {
      ObjectDelete(0, PANEL_NAME + "_Tab_" + IntegerToString(i));
   }
   
   // Удаляем содержимое вкладок (будет расширено)
   UI_DeleteTabContent(0);
   UI_DeleteTabContent(1);
   UI_DeleteTabContent(2);
   UI_DeleteTabContent(3);
   UI_DeleteTabContent(4);
   
   // Удаляем фон панели
   ObjectDelete(0, PANEL_NAME);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Очистка содержимого конкретной вкладки                           |
//+------------------------------------------------------------------+
void UI_DeleteTabContent(int tabIdx)
{
   string prefix = PANEL_NAME + "_Content_" + IntegerToString(tabIdx) + "_";
   int total = ObjectsTotal(0, 0, OBJ_LABEL);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, OBJ_LABEL);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
         
      name = ObjectName(0, i, 0, OBJ_RECTANGLE_LABEL);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+
//| Обработка кликов по элементам UI (вызывать из OnChartEvent)      |
//+------------------------------------------------------------------+
bool UI_OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Клик по кнопке сворачивания
      if(sparam == PANEL_NAME + "_CollapseBtn")
      {
         isCollapsed = !isCollapsed;
         UI_DeleteAll();
         UI_CreateBasePanel();
         if(!isCollapsed)
            UI_CreateTabs();
         ChartRedraw();
         return true;
      }
      
      // Клик по вкладкам
      for(int i = 0; i < TAB_COUNT; i++)
      {
         if(sparam == PANEL_NAME + "_Tab_" + IntegerToString(i))
         {
            if(currentTab != i)
            {
               currentTab = i;
               UI_DeleteAll(); // Перерисовка всей панели для простоты
               UI_CreateBasePanel();
               UI_CreateTabs();
               // Здесь будет вызов UI_DrawTab(currentTab);
               ChartRedraw();
            }
            return true;
         }
      }
   }
   return false;
}

#endif