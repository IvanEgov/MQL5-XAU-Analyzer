//+------------------------------------------------------------------+
//| Analyzer.mqh                                                     |
//| СЛОЙ 3: PULLBACK ENGINE - Вход на отскок от уровней              |
//+------------------------------------------------------------------+
#ifndef ANALYZER_MQH
#define ANALYZER_MQH

#include <Config.mqh>
#include <DataStructures.mqh>
#include <Levels.mqh>

//+------------------------------------------------------------------+
//| ЕДИНАЯ ФУНКЦИЯ АНАЛИЗА (PULLBACK MODE)                           |
//+------------------------------------------------------------------+
IndicatorVotes AnalyzeSignal(ENUM_TIMEFRAMES tf, int shift,
                             int hEMA50, int hEMA200, int hMACD, int hADX, int hRSI,
                             int hStoch, int hCCI, int hVol, int hOBV, int hBB, int hATR,
                             const IndicatorParams &params)
{
   IndicatorVotes result;
   result.Init();

   //=== 1. ПОЛУЧАЕМ ЦЕНОВЫЕ ДАННЫЕ ===
   double close[], open[], high[], low[];
   ArraySetAsSeries(close, true); ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
   if(CopyClose(_Symbol, tf, shift, 3, close) < 3) return result;
   if(CopyOpen(_Symbol, tf, shift, 3, open) < 3) return result;
   if(CopyHigh(_Symbol, tf, shift, 3, high) < 3) return result;
   if(CopyLow(_Symbol, tf, shift, 3, low) < 3) return result;

   //=== 2. ПОЛУЧАЕМ ДАННЫЕ ИНДИКАТОРОВ ===
   double rsi[], stochK[], stochD[], atr[];
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(stochK, true); ArraySetAsSeries(stochD, true);
   ArraySetAsSeries(atr, true);

   if(CopyBuffer(hRSI, 0, shift, 3, rsi) < 3) return result;
   if(CopyBuffer(hStoch, 0, shift, 3, stochK) < 3) return result;
   if(CopyBuffer(hStoch, 1, shift, 3, stochD) < 3) return result;
   if(CopyBuffer(hATR, 0, shift, 3, atr) < 3) return result;

   result.atrValue = atr[1];
   result.currentPrice = close[1];

   //=== 3. ПРОВЕРКА: ЦЕНА У УРОВНЯ? ===
   double currentPrice = close[1];
   double zoneATR = 0.3; // Зона отскока = 0.3 ATR
   
   bool nearSupport = Levels_IsNearLevel(currentPrice, "SUPPORT", zoneATR);
   bool nearResistance = Levels_IsNearLevel(currentPrice, "RESISTANCE", zoneATR);

   //=== 4. ПРОВЕРКА УСЛОВИЙ ОТСКОКА ===
   
   // BUY: цена у поддержки + подтверждение
   bool buyCondition1 = nearSupport;                                    // Цена у поддержки
   bool buyCondition2 = (close[1] > open[1]);                           // Бычья свеча
   bool buyCondition3 = (rsi[1] < 40.0);                                // RSI перепродан
   bool buyCondition4 = (stochK[1] < 25.0 && stochK[1] > stochD[1] && stochK[2] <= stochD[2]); // Stoch разворот вверх
   
   // SELL: цена у сопротивления + подтверждение
   bool sellCondition1 = nearResistance;                                // Цена у сопротивления
   bool sellCondition2 = (close[1] < open[1]);                          // Медвежья свеча
   bool sellCondition3 = (rsi[1] > 60.0);                               // RSI перекуплен
   bool sellCondition4 = (stochK[1] > 75.0 && stochK[1] < stochD[1] && stochK[2] >= stochD[2]); // Stoch разворот вниз

   //=== 5. ОПРЕДЕЛЕНИЕ СИГНАЛА ===
   // Для BUY нужны ВСЕ 4 условия
   if(buyCondition1 && buyCondition2 && buyCondition3 && buyCondition4) {
      result.signal = "STRONG BUY";
      result.weightedSum = 4.0;
      
      // Находим ближайший уровень сопротивления для TP
      int resIdx = Levels_FindNearest(currentPrice, "RESISTANCE", 3.0);
      if(resIdx >= 0) {
         result.targetPrice = g_levels[resIdx].price;
      } else {
         // Если нет сопротивления, TP = 2× расстояние до SL
         double slDist = atr[1] * 1.0;
         result.targetPrice = currentPrice + (slDist * 2.0);
      }
   }
   // Для SELL нужны ВСЕ 4 условия
   else if(sellCondition1 && sellCondition2 && sellCondition3 && sellCondition4) {
      result.signal = "STRONG SELL";
      result.weightedSum = -4.0;
      
      // Находим ближайший уровень поддержки для TP
      int supIdx = Levels_FindNearest(currentPrice, "SUPPORT", 3.0);
      if(supIdx >= 0) {
         result.targetPrice = g_levels[supIdx].price;
      } else {
         double slDist = atr[1] * 1.0;
         result.targetPrice = currentPrice - (slDist * 2.0);
      }
   }
   else {
      result.signal = "HOLD";
      result.weightedSum = 0;
      result.targetPrice = currentPrice;
   }

   // Заполняем votes для UI
   for(int i = 0; i < 10; i++) {
      if(result.weightedSum > 0) result.votes[i] = 1;
      else if(result.weightedSum < 0) result.votes[i] = -1;
      else result.votes[i] = 0;
   }

   // Прогноз: 3-5 свечей до достижения TP
   result.candlesForecast = (MathAbs(result.weightedSum) >= 4.0) ? 5 : 3;

   return result;
}

#endif