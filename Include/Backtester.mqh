//+------------------------------------------------------------------+
//| Backtester.mqh                                                   |
//| СЛОЙ 8: БЭКТЕСТ ДЛЯ ГИБРИДНОЙ СТРАТЕГИИ                          |
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
//| БЭКТЕСТ ДЛЯ ГИБРИДНОЙ СТРАТЕГИИ                                  |
//+------------------------------------------------------------------+
void RunBacktest()
{
   Print("🚀 ЗАПУСК ГИБРИДНОГО БЭКТЕСТА (индикаторы + отскок от уровней)");
   
   // Инициализируем уровни
   Levels_Init();
   
   int availableBars = iBars(_Symbol, PERIOD_H1);
   if(availableBars < 500) { Print("❌ Мало истории"); isBacktestRunning = false; return; }
   
   int actualBars = MathMin(backtestBars, availableBars - 30);
   Print("📊 Баров H1: ", actualBars);

   //=== СЕТКИ ОПТИМИЗАЦИИ ===
   double testThresholds[];
   int tCount = BuildGridDouble(2.0, 5.0, 0.5, testThresholds);
   
   double testSLMult[];
   int sCount = BuildGridDouble(0.8, 1.5, 0.2, testSLMult);

   int totalCombinations = tCount * sCount;
   Print("🔄 Оптимизация: ", totalCombinations, " комбинаций...");

   double bestFitness = -999.0;
   IndicatorParams bestParams; bestParams.Init();
   int bestTrades = 0, bestWins = 0, bestLosses = 0;
   double bestAcc = 0.0;
   double bestSignalsPerDay = 0.0;

   double testDays = actualBars / 24.0;
   int comboCount = 0;

   for(int t = 0; t < tCount; t++)
   for(int s = 0; s < sCount; s++)
   {
      comboCount++;
      if(comboCount % 3 == 0) Print("⏳ Комбинация ", comboCount, " / ", totalCombinations);
      
      IndicatorParams testParams = optParams;
      testParams.signalThreshold = testThresholds[t];
      testParams.atrSLMult = testSLMult[s];
      
      int trades = 0, wins = 0, losses = 0;
      int lastTradeBar = -1;
      
      //=== ТЕСТ H1 ===
      for(int shift = actualBars; shift >= 10; shift--)
      {
         if(shift % BacktestStepBars != 0) continue;
         if(lastTradeBar > 0 && shift >= lastTradeBar - 4) continue;
         
         IndicatorVotes sig = AnalyzeSignal(PERIOD_H1, shift, hEMA50_H1, hEMA200_H1, hMACD_H1, hADX_H1, hRSI_H1,
                                            hStoch_H1, hCCI_H1, hVol_H1, hOBV_H1, hBB_H1, hATR_H1, testParams);
         
         if(sig.signal != "BUY" && sig.signal != "STRONG BUY" && 
            sig.signal != "SELL" && sig.signal != "STRONG SELL") continue;
         
         double entry = iOpen(_Symbol, PERIOD_H1, shift - 1);
         if(entry <= 0) continue;
         
         double atr[];
         ArraySetAsSeries(atr, true);
         if(CopyBuffer(hATR_H1, 0, shift - 1, 2, atr) < 2) continue;
         if(atr[0] <= 0) continue;
         
         string dir = (sig.weightedSum > 0) ? "BUY" : "SELL";
         double sl = (dir == "BUY") ? entry - (atr[0] * testParams.atrSLMult) : entry + (atr[0] * testParams.atrSLMult);
         double tp = sig.targetPrice; // TP из Analyzer (к следующему уровню)
         
         double slDist = MathAbs(entry - sl);
         double tpDist = MathAbs(tp - entry);
         if(slDist <= 0 || tpDist / slDist < 1.0) continue;
         
         bool win = false, hit = false;
         for(int i = 2; i <= 48 && (shift - i) >= 0; i++) {
            double h = iHigh(_Symbol, PERIOD_H1, shift - i);
            double l = iLow(_Symbol, PERIOD_H1, shift - i);
            if(h == 0 || l == 0) continue;
            
            if(dir == "BUY") {
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
      
      //=== ТЕСТ H4 ===
      int actualBars_H4 = iBars(_Symbol, PERIOD_H4);
      int lastTradeBar_H4 = -1;
      
      for(int shift = actualBars_H4; shift >= 5; shift--)
      {
         if(lastTradeBar_H4 > 0 && shift >= lastTradeBar_H4 - 2) continue;
         
         IndicatorVotes sig = AnalyzeSignal(PERIOD_H4, shift, hEMA50_H4, hEMA200_H4, hMACD_H4, hADX_H4, hRSI_H4,
                                            hStoch_H4, hCCI_H4, hVol_H4, hOBV_H4, hBB_H4, hATR_H4, testParams);
         
         if(sig.signal != "BUY" && sig.signal != "STRONG BUY" && 
            sig.signal != "SELL" && sig.signal != "STRONG SELL") continue;
         
         double entry = iOpen(_Symbol, PERIOD_H4, shift - 1);
         if(entry <= 0) continue;
         
         double atr[];
         ArraySetAsSeries(atr, true);
         if(CopyBuffer(hATR_H4, 0, shift - 1, 2, atr) < 2) continue;
         if(atr[0] <= 0) continue;
         
         string dir = (sig.weightedSum > 0) ? "BUY" : "SELL";
         double sl = (dir == "BUY") ? entry - (atr[0] * testParams.atrSLMult) : entry + (atr[0] * testParams.atrSLMult);
         double tp = sig.targetPrice;
         
         double slDist = MathAbs(entry - sl);
         double tpDist = MathAbs(tp - entry);
         if(slDist <= 0 || tpDist / slDist < 1.0) continue;
         
         bool win = false, hit = false;
         for(int i = 2; i <= 60 && (shift - i) >= 0; i++) {
            double h = iHigh(_Symbol, PERIOD_H4, shift - i);
            double l = iLow(_Symbol, PERIOD_H4, shift - i);
            if(h == 0 || l == 0) continue;
            
            if(dir == "BUY") {
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
            lastTradeBar_H4 = shift;
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
            bestParams = testParams;
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
   Print("⚙️ Signal Threshold: ", DoubleToString(bestParams.signalThreshold, 1));
   Print("⚙️ ATR SL Multiplier: ", DoubleToString(bestParams.atrSLMult, 1));
   Print("-----------------------------------------------------------------");
   Print("📊 Сделки (H1+H4): ", bestTrades, " | WIN: ", bestWins, " | LOSS: ", bestLosses);
   Print("🎯 ТОЧНОСТЬ: ", DoubleToString(bestAcc, 1), "%");
   Print("📈 Сигналов в день: ", DoubleToString(bestSignalsPerDay, 2));
   Print("=================================================================");
   
   isBacktestRunning = false;
}

int BuildGridDouble(double minVal, double maxVal, double step, double &grid[]) {
   if(step <= 0) step = 0.5;
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