//+------------------------------------------------------------------+
//| Backtester.mqh                                                   |
//| СЛОЙ 8: БЭКТЕСТ ДЛЯ PULLBACK STRATEGY                            |
//+------------------------------------------------------------------+
#ifndef BACKTESTER_MQH
#define BACKTESTER_MQH

#include <Config.mqh>
#include <DataStructures.mqh>
#include <Levels.mqh>

extern IndicatorParams optParams;
extern int hEMA50_H1, hEMA200_H1, hMACD_H1, hADX_H1, hRSI_H1;
extern int hStoch_H1, hCCI_H1, hVol_H1, hOBV_H1, hBB_H1, hATR_H1;
extern int hEMA50_H4, hEMA200_H4, hMACD_H4, hADX_H4, hRSI_H4;
extern int hStoch_H4, hCCI_H4, hVol_H4, hOBV_H4, hBB_H4, hATR_H4;
extern int hEMA50_D1, hEMA200_D1, hMACD_D1, hADX_D1, hRSI_D1;
extern int hStoch_D1, hCCI_D1, hVol_D1, hOBV_D1, hBB_D1, hATR_D1;
extern bool isBacktestRunning;
extern string currentSymbol;
extern int symbolDigits;

//+------------------------------------------------------------------+
//| БЭКТЕСТ ДЛЯ PULLBACK STRATEGY                                    |
//+------------------------------------------------------------------+
void RunBacktest()
{
   Print("🚀 ЗАПУСК PULLBACK БЭКТЕСТА (отскок от уровней)");
   
   // Инициализируем уровни
   Levels_Init();
   
   int availableBars = iBars(_Symbol, PERIOD_H1);
   if(availableBars < 500) { Print("❌ Мало истории"); isBacktestRunning = false; return; }
   
   int actualBars = MathMin(backtestBars, availableBars - 30);
   Print("📊 Баров H1: ", actualBars);

   //=== СЕТКИ ОПТИМИЗАЦИИ ===
   // Оптимизируем зоны отскока и SL множители
   double testZoneATR[];
   int zCount = BuildGridDouble(0.2, 0.5, 0.1, testZoneATR);
   
   double testSLMult[];
   int sCount = BuildGridDouble(0.8, 1.5, 0.2, testSLMult);

   int totalCombinations = zCount * sCount;
   Print("🔄 Оптимизация: ", totalCombinations, " комбинаций...");

   double bestFitness = -999.0;
   double bestZoneATR = 0.3;
   double bestSLMult = 1.0;
   int bestTrades = 0, bestWins = 0, bestLosses = 0;
   double bestAcc = 0.0;
   double bestSignalsPerDay = 0.0;

   double testDays = actualBars / 24.0;
   int comboCount = 0;

   for(int z = 0; z < zCount; z++)
   for(int s = 0; s < sCount; s++)
   {
      comboCount++;
      if(comboCount % 3 == 0) Print("⏳ Комбинация ", comboCount, " / ", totalCombinations);
      
      double zoneATR = testZoneATR[z];
      double slMult = testSLMult[s];
      
      int trades = 0, wins = 0, losses = 0;
      int lastTradeBar = -1;
      
      //=== ТЕСТ H1 ===
      for(int shift = actualBars; shift >= 10; shift--)
      {
         if(shift % BacktestStepBars != 0) continue;
         if(lastTradeBar > 0 && shift >= lastTradeBar - 4) continue;
         
         // Получаем данные
         double close[], open[], high[], low[];
         ArraySetAsSeries(close, true); ArraySetAsSeries(open, true);
         ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
         if(CopyClose(_Symbol, PERIOD_H1, shift, 3, close) < 3) continue;
         if(CopyOpen(_Symbol, PERIOD_H1, shift, 3, open) < 3) continue;
         if(CopyHigh(_Symbol, PERIOD_H1, shift, 3, high) < 3) continue;
         if(CopyLow(_Symbol, PERIOD_H1, shift, 3, low) < 3) continue;
         
         double rsi[], stK[], stD[], atr[];
         ArraySetAsSeries(rsi, true); ArraySetAsSeries(stK, true);
         ArraySetAsSeries(stD, true); ArraySetAsSeries(atr, true);
         if(CopyBuffer(hRSI_H1, 0, shift, 3, rsi) < 3) continue;
         if(CopyBuffer(hStoch_H1, 0, shift, 3, stK) < 3) continue;
         if(CopyBuffer(hStoch_H1, 1, shift, 3, stD) < 3) continue;
         if(CopyBuffer(hATR_H1, 0, shift, 3, atr) < 3) continue;
         
         double currentPrice = close[1];
         
         // Проверяем условия BUY
         bool nearSupport = Levels_IsNearLevel(currentPrice, "SUPPORT", zoneATR);
         bool buyCond1 = nearSupport;
         bool buyCond2 = (close[1] > open[1]);
         bool buyCond3 = (rsi[1] < 40.0);
         bool buyCond4 = (stK[1] < 25.0 && stK[1] > stD[1] && stK[2] <= stD[2]);
         
         // Проверяем условия SELL
         bool nearResistance = Levels_IsNearLevel(currentPrice, "RESISTANCE", zoneATR);
         bool sellCond1 = nearResistance;
         bool sellCond2 = (close[1] < open[1]);
         bool sellCond3 = (rsi[1] > 60.0);
         bool sellCond4 = (stK[1] > 75.0 && stK[1] < stD[1] && stK[2] >= stD[2]);
         
         string direction = "";
         if(buyCond1 && buyCond2 && buyCond3 && buyCond4) direction = "BUY";
         else if(sellCond1 && sellCond2 && sellCond3 && sellCond4) direction = "SELL";
         
         if(direction == "") continue;
         
         // Вход на следующем баре
         double entry = iOpen(_Symbol, PERIOD_H1, shift - 1);
         if(entry <= 0) continue;
         
         double sl = (direction == "BUY") ? entry - (atr[1] * slMult) : entry + (atr[1] * slMult);
         
         // TP: к следующему уровню или 2× SL
         double tp = 0;
         if(direction == "BUY") {
            int resIdx = Levels_FindNearest(currentPrice, "RESISTANCE", 3.0);
            if(resIdx >= 0) tp = g_levels[resIdx].price;
            else tp = entry + (atr[1] * slMult * 2.0);
         } else {
            int supIdx = Levels_FindNearest(currentPrice, "SUPPORT", 3.0);
            if(supIdx >= 0) tp = g_levels[supIdx].price;
            else tp = entry - (atr[1] * slMult * 2.0);
         }
         
         // Проверка R:R
         double slDist = MathAbs(entry - sl);
         double tpDist = MathAbs(tp - entry);
         if(slDist <= 0 || tpDist / slDist < 1.0) continue;
         
         // Симуляция
         bool win = false, hit = false;
         for(int i = 2; i <= 48 && (shift - i) >= 0; i++) {
            double h = iHigh(_Symbol, PERIOD_H1, shift - i);
            double l = iLow(_Symbol, PERIOD_H1, shift - i);
            if(h == 0 || l == 0) continue;
            
            if(direction == "BUY") {
               if(l <= sl) { hit = true; break; }
               if(h >= tp) { win = true; hit = true; break; }
            } else {
               if(h >= sl) { hit = true; break; }
               if(l <= tp) { win = true; hit = true; break; }
            }
         }
         
         if(hit) {
            trades++;
            if(win) wins++; else losses++;
            lastTradeBar = shift;
         }
      }
      
      // ФИТНЕС-ФУНКЦИЯ
      if(trades >= 3) {
         double acc = (trades > 0) ? (wins * 100.0 / trades) : 0;
         double signalsPerDay = trades / testDays;
         
         double fitness = acc;
         
         if(acc >= 70.0) fitness += 30.0;
         else if(acc >= 60.0) fitness += 20.0;
         else if(acc >= 50.0) fitness += 10.0;
         
         if(signalsPerDay >= 1.0 && signalsPerDay <= 5.0) fitness += 25.0;
         else if(signalsPerDay >= 0.5 && signalsPerDay < 1.0) fitness += 15.0;
         else if(signalsPerDay > 5.0) fitness -= 10.0;
         
         if(fitness > bestFitness) {
            bestFitness = fitness;
            bestZoneATR = zoneATR;
            bestSLMult = slMult;
            bestTrades = trades;
            bestWins = wins;
            bestLosses = losses;
            bestAcc = acc;
            bestSignalsPerDay = signalsPerDay;
         }
      }
   }

   Print("=================================================================");
   Print("🏆 НАЙДЕНЫ ЛУЧШИЕ НАСТРОЙКИ (Score: ", DoubleToString(bestFitness, 1), ")");
   Print("⚙️ Зона отскока (ATR): ", DoubleToString(bestZoneATR, 2));
   Print("⚙️ SL множитель (ATR): ", DoubleToString(bestSLMult, 2));
   Print("-----------------------------------------------------------------");
   Print("📊 Сделки: ", bestTrades, " | WIN: ", bestWins, " | LOSS: ", bestLosses);
   Print("🎯 ТОЧНОСТЬ: ", DoubleToString(bestAcc, 1), "%");
   Print("📈 Сигналов в день: ", DoubleToString(bestSignalsPerDay, 2));
   Print("=================================================================");
   
   isBacktestRunning = false;
}

int BuildGridDouble(double minVal, double maxVal, double step, double &grid[]) {
   if(step <= 0) step = 0.1;
   int count = (int)MathFloor((maxVal - minVal) / step) + 1;
   ArrayResize(grid, count);
   for(int i = 0; i < count; i++) grid[i] = minVal + i * step;
   return count;
}

int BuildGridInt(int minVal, int maxVal, int step, int &grid[]) {
   if(step <= 0) step = 1;
   int count = (maxVal - minVal) / step + 1;
   ArrayResize(grid, count);
   for(int i = 0; i < count; i++) grid[i] = minVal + i * step;
   return count;
}

#endif