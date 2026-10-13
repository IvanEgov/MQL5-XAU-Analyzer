//+------------------------------------------------------------------+
//| Levels.mqh                                                       |
//| СЛОЙ 5: ПОИСК И ОТРИСОВКА УРОВНЕЙ ЗОНАМИ (с фильтрацией)         |
//+------------------------------------------------------------------+
#ifndef LEVELS_MQH
#define LEVELS_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

//--- Доступ к хендлам ATR из главного файла
extern int hATR_H1;
extern int hATR_H4;

//--- Настраиваемые параметры (из input в главном файле)
// Они автоматически видны после подключения модуля

//--- Структура уровня
struct PriceLevel {
   double price;
   int strength;
   int touches;
   ENUM_TIMEFRAMES tf;
   datetime time;
   string type;         // "SUPPORT" или "RESISTANCE"
};

//--- Глобальные массивы уровней
PriceLevel g_levels[];
int g_levelsCount = 0;

//+------------------------------------------------------------------+
//| Получить значение ATR через существующий хендл                   |
//+------------------------------------------------------------------+
double Levels_GetATR(ENUM_TIMEFRAMES tf)
{
   int handle = (tf == PERIOD_H1) ? hATR_H1 : hATR_H4;
   if(handle == INVALID_HANDLE) return 0;
   
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(handle, 0, 0, 1, atr) < 1) return 0;
   return atr[0];
}

//+------------------------------------------------------------------+
//| Поиск уровней методом свингов                                    |
//+------------------------------------------------------------------+
void Levels_FindSwingLevels(ENUM_TIMEFRAMES tf, int lookback)
{
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if(CopyHigh(_Symbol, tf, 0, lookback, high) < lookback) return;
   if(CopyLow(_Symbol, tf, 0, lookback, low) < lookback) return;
   
   int leftBars = 5;
   int rightBars = 5;
   
   // Свинг-хаи (сопротивление)
   for(int i = leftBars; i < lookback - rightBars; i++) {
      bool isSwingHigh = true;
      for(int j = 1; j <= leftBars; j++) {
         if(high[i] <= high[i+j]) { isSwingHigh = false; break; }
      }
      if(isSwingHigh) {
         for(int j = 1; j <= rightBars; j++) {
            if(high[i] <= high[i-j]) { isSwingHigh = false; break; }
         }
      }
      
      if(isSwingHigh) {
         Levels_AddLevel(high[i], "RESISTANCE", tf, iTime(_Symbol, tf, i));
      }
   }
   
   // Свинг-лоу (поддержка)
   for(int i = leftBars; i < lookback - rightBars; i++) {
      bool isSwingLow = true;
      for(int j = 1; j <= leftBars; j++) {
         if(low[i] >= low[i+j]) { isSwingLow = false; break; }
      }
      if(isSwingLow) {
         for(int j = 1; j <= rightBars; j++) {
            if(low[i] >= low[i-j]) { isSwingLow = false; break; }
         }
      }
      
      if(isSwingLow) {
         Levels_AddLevel(low[i], "SUPPORT", tf, iTime(_Symbol, tf, i));
      }
   }
}

//+------------------------------------------------------------------+
//| Добавление уровня                                                |
//+------------------------------------------------------------------+
void Levels_AddLevel(double price, string type, ENUM_TIMEFRAMES tf, datetime time)
{
   double atr = Levels_GetATR(tf);
   if(atr <= 0) atr = 10.0;
   double tolerance = atr * LevelsMergeATR;
   
   for(int i = 0; i < g_levelsCount; i++) {
      if(MathAbs(g_levels[i].price - price) < tolerance && g_levels[i].type == type) {
         g_levels[i].strength++;
         g_levels[i].touches++;
         if(time > g_levels[i].time) g_levels[i].time = time;
         g_levels[i].price = (g_levels[i].price * (g_levels[i].touches - 1) + price) / g_levels[i].touches;
         return;
      }
   }
   
   g_levelsCount++;
   ArrayResize(g_levels, g_levelsCount);
   g_levels[g_levelsCount-1].price = price;
   g_levels[g_levelsCount-1].type = type;
   g_levels[g_levelsCount-1].tf = tf;
   g_levels[g_levelsCount-1].time = time;
   g_levels[g_levelsCount-1].strength = 1;
   g_levels[g_levelsCount-1].touches = 1;
}

//+------------------------------------------------------------------+
//| ФИЛЬТРАЦИЯ: Удаление пересекающихся уровней                      |
//+------------------------------------------------------------------+
void Levels_FilterConflicts()
{
   double atr = Levels_GetATR(PERIOD_H1);
   if(atr <= 0) return;
   double conflictZone = atr * LevelsConflictATR;
   
   for(int i = 0; i < g_levelsCount; i++) {
      for(int j = i + 1; j < g_levelsCount; j++) {
         if(g_levels[i].type != g_levels[j].type) {
            double dist = MathAbs(g_levels[i].price - g_levels[j].price);
            if(dist < conflictZone) {
               if(g_levels[i].strength < g_levels[j].strength) {
                  for(int k = i; k < g_levelsCount - 1; k++) {
                     g_levels[k] = g_levels[k+1];
                  }
                  g_levelsCount--;
                  ArrayResize(g_levels, g_levelsCount);
                  i--;
                  break;
               } else {
                  for(int k = j; k < g_levelsCount - 1; k++) {
                     g_levels[k] = g_levels[k+1];
                  }
                  g_levelsCount--;
                  ArrayResize(g_levels, g_levelsCount);
                  j--;
               }
            }
         }
      }
   }
   
   int newCount = 0;
   for(int i = 0; i < g_levelsCount; i++) {
      if(g_levels[i].strength >= LevelsMinStrength) {
         if(newCount != i) g_levels[newCount] = g_levels[i];
         newCount++;
      }
   }
   g_levelsCount = newCount;
   ArrayResize(g_levels, g_levelsCount);
}

//+------------------------------------------------------------------+
//| Найти ближайший уровень                                          |
//+------------------------------------------------------------------+
int Levels_FindNearest(double currentPrice, string type, double maxDistanceATR = 2.0)
{
   double atr = Levels_GetATR(PERIOD_H1);
   if(atr <= 0) return -1;
   double maxDist = atr * maxDistanceATR;
   
   int nearestIdx = -1;
   double minDist = 999999;
   
   for(int i = 0; i < g_levelsCount; i++) {
      if(g_levels[i].type != type) continue;
      
      double dist = MathAbs(g_levels[i].price - currentPrice);
      if(dist < minDist && dist < maxDist) {
         minDist = dist;
         nearestIdx = i;
      }
   }
   
   return nearestIdx;
}

//+------------------------------------------------------------------+
//| Проверка: цена у уровня?                                         |
//+------------------------------------------------------------------+
bool Levels_IsNearLevel(double currentPrice, string type, double zoneATR = 0.3)
{
   double atr = Levels_GetATR(PERIOD_H1);
   if(atr <= 0) return false;
   double zone = atr * zoneATR;
   
   for(int i = 0; i < g_levelsCount; i++) {
      if(g_levels[i].type != type) continue;
      
      if(MathAbs(g_levels[i].price - currentPrice) < zone) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Отрисовка уровней ЗОНАМИ                                         |
//+------------------------------------------------------------------+
void Levels_DrawOnChart()
{
   for(int i = ObjectsTotal(0, 0, OBJ_RECTANGLE) - 1; i >= 0; i--) {
      string name = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if(StringFind(name, "LevelZone_") == 0) ObjectDelete(0, name);
   }
   
   int drawn = 0;
   datetime timeRight = TimeCurrent() + PeriodSeconds(PERIOD_H1) * 30;
   
   for(int i = 0; i < g_levelsCount && drawn < 10; i++) {
      double atr = Levels_GetATR(g_levels[i].tf);
      if(atr <= 0) continue;
      
      double zoneHalf = atr * LevelsZoneATR;
      double topPrice = g_levels[i].price + zoneHalf;
      double bottomPrice = g_levels[i].price - zoneHalf;
      
      datetime timeLeft = g_levels[i].time;
      
      string name = "LevelZone_" + IntegerToString(i);
      
      color baseColor = (g_levels[i].type == "SUPPORT") ? clrDodgerBlue : clrOrangeRed;
      
      int alpha = 30 + (g_levels[i].strength - LevelsMinStrength) * 15;
      if(alpha < 30) alpha = 30;
      if(alpha > 80) alpha = 80;
      
      color zoneColor = (color)ColorToARGB(baseColor, (uchar)alpha);
      
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, timeLeft, topPrice, timeRight, bottomPrice);
      ObjectSetInteger(0, name, OBJPROP_COLOR, zoneColor);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      
      string tooltip = g_levels[i].type + " @ " + DoubleToString(g_levels[i].price, _Digits) +
                       " | Сила: " + IntegerToString(g_levels[i].strength) +
                       " | Касаний: " + IntegerToString(g_levels[i].touches) +
                       " | ТФ: " + EnumToString(g_levels[i].tf);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
      
      drawn++;
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Инициализация                                                    |
//+------------------------------------------------------------------+
void Levels_Init()
{
   g_levelsCount = 0;
   ArrayResize(g_levels, 0);
   
   Levels_FindSwingLevels(PERIOD_H1, LevelsLookbackH1);
   Levels_FindSwingLevels(PERIOD_H4, LevelsLookbackH4);
   
   int beforeFilter = g_levelsCount;
   Levels_FilterConflicts();
   
   Print("📊 Найдено уровней: ", beforeFilter, " → после фильтрации: ", g_levelsCount);
   
   int support = 0, resistance = 0;
   for(int i = 0; i < g_levelsCount; i++) {
      if(g_levels[i].type == "SUPPORT") support++;
      else resistance++;
   }
   Print("   • Поддержек: ", support);
   Print("   • Сопротивлений: ", resistance);
   Print("   • Удалено конфликтов: ", beforeFilter - g_levelsCount);
}

#endif