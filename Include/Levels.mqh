//+------------------------------------------------------------------+
//| Levels.mqh                                                       |
//| СЛОЙ 5: ПОИСК И ОТРИСОВКА УРОВНЕЙ ЗОНАМИ (прямоугольники)       |
//+------------------------------------------------------------------+
#ifndef LEVELS_MQH
#define LEVELS_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

//--- Доступ к хендлам ATR из главного файла
extern int hATR_H1;
extern int hATR_H4;

//--- Структура уровня
struct PriceLevel {
   double price;
   int strength;        // Сила уровня (1-5)
   int touches;         // Количество касаний
   ENUM_TIMEFRAMES tf;  // ТФ, на котором найден
   datetime time;       // Время последнего касания
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
//| Поиск уровней методом свингов (Fractal-like)                     |
//+------------------------------------------------------------------+
void Levels_FindSwingLevels(ENUM_TIMEFRAMES tf, int lookback = 100)
{
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if(CopyHigh(_Symbol, tf, 0, lookback, high) < lookback) return;
   if(CopyLow(_Symbol, tf, 0, lookback, low) < lookback) return;
   
   int leftBars = 3;
   int rightBars = 3;
   
   // Ищем свинг-хаи (сопротивление)
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
   
   // Ищем свинг-лоу (поддержка)
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
//| Добавление уровня (с объединением близких)                       |
//+------------------------------------------------------------------+
void Levels_AddLevel(double price, string type, ENUM_TIMEFRAMES tf, datetime time)
{
   double atr = Levels_GetATR(tf);
   if(atr <= 0) atr = 10.0; // fallback
   double tolerance = atr * 0.3; // Зона 0.3 ATR для объединения
   
   // Ищем существующий уровень рядом
   for(int i = 0; i < g_levelsCount; i++) {
      if(MathAbs(g_levels[i].price - price) < tolerance && g_levels[i].type == type) {
         g_levels[i].strength++;
         g_levels[i].touches++;
         if(time > g_levels[i].time) g_levels[i].time = time;
         // Усредняем цену для большей точности
         g_levels[i].price = (g_levels[i].price + price) / 2.0;
         return;
      }
   }
   
   // Добавляем новый уровень
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
//| Найти ближайший уровень к текущей цене                           |
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
//| Проверка: цена у уровня? (в зоне отскока)                        |
//+------------------------------------------------------------------+
bool Levels_IsNearLevel(double currentPrice, string type, double zoneATR = 0.3)
{
   double atr = Levels_GetATR(PERIOD_H1);
   if(atr <= 0) return false;
   double zone = atr * zoneATR;
   
   for(int i = 0; i < g_levelsCount; i++) {
      if(g_levels[i].type != type) continue;
      if(g_levels[i].strength < 2) continue; // Только уровни с 2+ касаниями
      
      if(MathAbs(g_levels[i].price - currentPrice) < zone) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Отрисовка уровней ЗОНАМИ (прямоугольники)                        |
//+------------------------------------------------------------------+
void Levels_DrawOnChart()
{
   // Удаляем старые зоны
   for(int i = ObjectsTotal(0, 0, OBJ_RECTANGLE) - 1; i >= 0; i--) {
      string name = ObjectName(0, i, 0, OBJ_RECTANGLE);
      if(StringFind(name, "LevelZone_") == 0) ObjectDelete(0, name);
   }
   
   // Рисуем новые зоны (только сильные уровни)
   int drawn = 0;
   datetime timeRight = TimeCurrent() + PeriodSeconds(PERIOD_H1) * 20; // +20 баров вправо
   
   for(int i = 0; i < g_levelsCount && drawn < 15; i++) {
      if(g_levels[i].strength < 2) continue; // Только уровни с 2+ касаниями
      
      double atr = Levels_GetATR(g_levels[i].tf);
      if(atr <= 0) continue;
      
      // Ширина зоны = 0.3 ATR в обе стороны от цены
      double zoneHalf = atr * 0.3;
      double topPrice = g_levels[i].price + zoneHalf;
      double bottomPrice = g_levels[i].price - zoneHalf;
      
      datetime timeLeft = g_levels[i].time;
      
      string name = "LevelZone_" + IntegerToString(i);
      
      // Цвет зависит от типа и силы
      color baseColor = (g_levels[i].type == "SUPPORT") ? clrDodgerBlue : clrOrangeRed;
      
      // Прозрачность зависит от силы уровня (2 касания = 30%, 3 = 40%, 4+ = 50%)
      int alpha = 40 + g_levels[i].strength * 10;
      if(alpha > 80) alpha = 80;
      color zoneColor = ColorToARGB(baseColor, alpha);
      
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, timeLeft, topPrice, timeRight, bottomPrice);
      ObjectSetInteger(0, name, OBJPROP_COLOR, zoneColor);
      ObjectSetInteger(0, name, OBJPROP_FILL, true); // Заливка цветом
      ObjectSetInteger(0, name, OBJPROP_BACK, true); // Под свечами
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      
      // Тултип с информацией
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
//| Инициализация: поиск уровней на H1 и H4                          |
//+------------------------------------------------------------------+
void Levels_Init()
{
   g_levelsCount = 0;
   ArrayResize(g_levels, 0);
   
   Levels_FindSwingLevels(PERIOD_H1, 200);
   Levels_FindSwingLevels(PERIOD_H4, 100);
   
   Print("📊 Найдено уровней: ", g_levelsCount);
   
   int support = 0, resistance = 0;
   for(int i = 0; i < g_levelsCount; i++) {
      if(g_levels[i].type == "SUPPORT") support++;
      else resistance++;
   }
   Print("   • Поддержек: ", support);
   Print("   • Сопротивлений: ", resistance);
}

#endif