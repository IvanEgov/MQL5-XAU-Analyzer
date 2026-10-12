//+------------------------------------------------------------------+
//| Backtester.mqh                                                   |
//| СЛОЙ 8: БЭКТЕСТ — оптимизация параметров стратегии               |
//+------------------------------------------------------------------+
#ifndef BACKTESTER_MQH
#define BACKTESTER_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

// =========================================================================
// СВЯЗЬ С ГЛОБАЛЬНЫМИ ПЕРЕМЕННЫМИ ГЛАВНОГО ФАЙЛА
// ТОЛЬКО не-input переменные! Input видны автоматически после подключения.
// =========================================================================
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
// =========================================================================
// =========================================================================

// Сеточные параметры оптимизации
//extern double OptThresholdMin, OptThresholdMax, OptThresholdStep;
//extern double OptATRMin, OptATRMax, OptATRStep;
//extern int OptEMAMin, OptEMAMax, OptEMAStep;
//extern int OptRSIMin, OptRSIMax, OptRSIStep;
// =========================================================================

//+------------------------------------------------------------------+
//| Расчёт срока жизни сигнала (для бэктеста)                        |
//+------------------------------------------------------------------+
int BT_CalculateLifetime(ENUM_TIMEFRAMES tf, double weightedSum, int candlesForecast)
{
   string mode = (tf == PERIOD_H1) ? "H1" : (tf == PERIOD_H4) ? "H4" : "D1";
   int baseMinutes = (mode == "H1") ? LIFETIME_BASE_H1 : (mode == "H4") ? LIFETIME_BASE_H4 : LIFETIME_BASE_D1;
   double absSum = MathAbs(weightedSum);
   double multiplier = (absSum >= SIGNAL_VERY_STRONG) ? LIFETIME_MULT_VERY_STRONG :
                       (absSum >= SIGNAL_STRONG) ? LIFETIME_MULT_STRONG :
                       (absSum >= SIGNAL_ABOVE_AVG) ? LIFETIME_MULT_ABOVE_AVG :
                       (absSum >= SIGNAL_AVG) ? LIFETIME_MULT_AVG : LIFETIME_MULT_WEAK;
   double forecastMult = MathMax(FORECAST_MULT_MIN, MathMin(FORECAST_MULT_MAX, FORECAST_MULT_BASE + candlesForecast * FORECAST_MULT_STEP));
   int lifetime = (int)(baseMinutes * multiplier * forecastMult);
   
   int minL = (mode == "H1") ? LIFETIME_MIN_H1 : (mode == "H4") ? LIFETIME_MIN_H4 : LIFETIME_MIN_D1;
   int maxL = (mode == "H1") ? LIFETIME_MAX_H1 : (mode == "H4") ? LIFETIME_MAX_H4 : LIFETIME_MAX_D1;
   return MathMax(minL, MathMin(maxL, lifetime));
}

//+------------------------------------------------------------------+
//| Проверка свечи и RSI (ОПТИМИЗИРОВАНО: хендл RSI передаётся)      |
//+------------------------------------------------------------------+
bool BT_CheckCandleAndRSI(int shift, ENUM_TIMEFRAMES tf, double wSum, int hRSI, IndicatorParams &params)
{
   double close[], open[], rsi[];
   ArraySetAsSeries(close, true); 
   ArraySetAsSeries(open, true); 
   ArraySetAsSeries(rsi, true);
   
   if(CopyClose(_Symbol, tf, shift, 3, close) < 3) return false;
   if(CopyOpen(_Symbol, tf, shift, 3, open) < 3) return false;
   if(CopyBuffer(hRSI, 0, shift, 3, rsi) < 3) return false;
   
   bool candleOk = (wSum > 0 && close[1] > open[1]) || (wSum < 0 && close[1] < open[1]);
   bool rsiOk = (wSum > 0 && rsi[1] < RSI_FILTER_BUY_MAX) || (wSum < 0 && rsi[1] > RSI_FILTER_SELL_MIN);
   
   return (candleOk && rsiOk);
}

//+------------------------------------------------------------------+
//| Симуляция сделки (ОПТИМИЗИРОВАНО: хендл ATR передаётся)          |
//+------------------------------------------------------------------+
bool BT_SimulateTrade(int shift, ENUM_TIMEFRAMES tf, double wSum, double atrMult,
                      int &totalTests, int &wins, int &losses, int &canceled,
                      IndicatorParams &params, datetime signalTime, int candlesForecast,
                      int hATR)
{
   int lifetimeMinutes = BT_CalculateLifetime(tf, wSum, candlesForecast);
   int lifetimeBars = (tf == PERIOD_H1) ? lifetimeMinutes / 60 : (tf == PERIOD_H4) ? lifetimeMinutes / 240 : lifetimeMinutes / 1440;
   if(lifetimeBars < 1) lifetimeBars = 1;
   
   double entry = iClose(_Symbol, tf, shift);
   if(entry == 0) return false;
   
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(hATR, 0, shift, 2, atr) < 2) return false;
   double currentATR = atr[0];
   if(currentATR <= 0) return false;
   
   double sl = 0, tp = 0;
   string direction = (wSum > 0) ? "BUY" : "SELL";
   double slDistance = currentATR * atrMult;
   if(direction == "BUY") { sl = entry - slDistance; tp = entry + (slDistance * TP_MULTIPLIER); }
   else { sl = entry + slDistance; tp = entry - (slDistance * TP_MULTIPLIER); }
   
   bool entryReached = false, slHit = false, tpHit = false;
   double exitPrice = 0;
   string result = "";
   
   for(int i = 1; i <= lifetimeBars && (shift - i) >= 0; i++)
   {
      double barHigh = iHigh(_Symbol, tf, shift - i);
      double barLow = iLow(_Symbol, tf, shift - i);
      if(barHigh == 0 || barLow == 0) continue;
      
      if(!entryReached)
      {
         if((direction == "BUY" && barHigh >= entry) || (direction == "SELL" && barLow <= entry))
            entryReached = true;
      }
      else
      {
         if(direction == "BUY")
         {
            if(barLow <= sl) { slHit = true; exitPrice = sl; break; }
            if(barHigh >= tp) { tpHit = true; exitPrice = tp; break; }
         }
         else
         {
            if(barHigh >= sl) { slHit = true; exitPrice = sl; break; }
            if(barLow <= tp) { tpHit = true; exitPrice = tp; break; }
         }
      }
   }
   
   if(!entryReached) { canceled++; totalTests++; result = "CANCELED"; }
   else if(slHit) { losses++; totalTests++; result = "LOSS"; }
   else if(tpHit) { wins++; totalTests++; result = "WIN"; }
   else { canceled++; totalTests++; result = "TIMEOUT"; exitPrice = iClose(_Symbol, tf, MathMax(0, shift - lifetimeBars)); }
   
   double movement = (exitPrice > 0) ? ((direction == "BUY") ? (exitPrice - entry) : (entry - exitPrice)) : 0;
   string tfStr = (tf == PERIOD_H1) ? "H1" : (tf == PERIOD_H4) ? "H4" : "D1";
   
   string reportFile = FILE_BACKTEST_PREFIX + currentSymbol + "_" + TimeToString(TimeCurrent(), TIME_DATE) + FILE_CSV_EXT;
   int handle = FileOpen(reportFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
   if(handle != INVALID_HANDLE)
   {
      if((int)FileSize(handle) == 0)
         FileWrite(handle, "SignalTime", "TF", "Direction", "Entry", "SL", "TP", "ExitPrice", "Result", "Movement", "Lifetime", "WeightedSum");
      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle, TimeToString(signalTime, TIME_DATE|TIME_MINUTES), tfStr, direction,
                DoubleToString(entry, symbolDigits), DoubleToString(sl, symbolDigits), DoubleToString(tp, symbolDigits),
                DoubleToString(exitPrice, symbolDigits), result, DoubleToString(movement, symbolDigits),
                IntegerToString(lifetimeMinutes), DoubleToString(wSum, 1));
      FileClose(handle);
   }
   return true;
}

//+------------------------------------------------------------------+
//| ГЛАВНАЯ ФУНКЦИЯ БЭКТЕСТА (ОПТИМИЗИРОВАНО)                        |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| БЭКТЕСТ (МАКСИМАЛЬНО ОПТИМИЗИРОВАНО: предзагрузка данных)        |
//+------------------------------------------------------------------+
void RunBacktest()
{
   Print("🚀 ФУНКЦИЯ RunBacktest ЗАПУЩЕНА!");
   Print("🧪 ЗАПУСК УМНОГО МУЛЬТИ-ТФ БЭКТЕСТА С ОПТИМИЗАЦИЕЙ");
   
   int availableBars = iBars(_Symbol, PERIOD_H1);
   if(availableBars < BACKTEST_BARS_MIN)
   {
      Print("❌ Недостаточно истории!");
      isBacktestRunning = false;
      return;
   }
   
   int actualBars = MathMin(backtestBars, availableBars - 20);
   Print("📊 Будет проверено баров H1: ", actualBars);
   
   //=== ПОСТРОЕНИЕ СЕТОК ПАРАМЕТРОВ ===
   double testThresholds[];
   int tCount = 0;
   if(OptThresholdStep > 0 && OptThresholdMax >= OptThresholdMin)
   {
      tCount = (int)MathFloor((OptThresholdMax - OptThresholdMin) / OptThresholdStep) + 1;
      ArrayResize(testThresholds, tCount);
      for(int i = 0; i < tCount; i++)
         testThresholds[i] = OptThresholdMin + i * OptThresholdStep;
   }
   else
   {
      tCount = 1;
      ArrayResize(testThresholds, 1);
      testThresholds[0] = optParams.signalThreshold;
   }
   
   double testATRMultipliers[];
   int aCount = 0;
   if(OptATRStep > 0 && OptATRMax >= OptATRMin)
   {
      aCount = (int)MathFloor((OptATRMax - OptATRMin) / OptATRStep) + 1;
      ArrayResize(testATRMultipliers, aCount);
      for(int i = 0; i < aCount; i++)
         testATRMultipliers[i] = OptATRMin + i * OptATRStep;
   }
   else
   {
      aCount = 1;
      ArrayResize(testATRMultipliers, 1);
      testATRMultipliers[0] = optParams.atrSLMult;
   }
   
   int testEMAPeriods[];
   int eCount = 0;
   if(OptEMAStep > 0 && OptEMAMax >= OptEMAMin)
   {
      eCount = (OptEMAMax - OptEMAMin) / OptEMAStep + 1;
      ArrayResize(testEMAPeriods, eCount);
      for(int i = 0; i < eCount; i++)
         testEMAPeriods[i] = OptEMAMin + i * OptEMAStep;
   }
   else
   {
      eCount = 1;
      ArrayResize(testEMAPeriods, 1);
      testEMAPeriods[0] = optParams.emaFastPeriod;
   }
   
   int testRSIPeriods[];
   int rCount = 0;
   if(OptRSIStep > 0 && OptRSIMax >= OptRSIMin)
   {
      rCount = (OptRSIMax - OptRSIMin) / OptRSIStep + 1;
      ArrayResize(testRSIPeriods, rCount);
      for(int i = 0; i < rCount; i++)
         testRSIPeriods[i] = OptRSIMin + i * OptRSIStep;
   }
   else
   {
      rCount = 1;
      ArrayResize(testRSIPeriods, 1);
      testRSIPeriods[0] = optParams.rsiPeriod;
   }
   
   //=== ПРЕДЗАГРУЗКА ДАННЫХ ИНДИКАТОРОВ (ОДИН РАЗ!) ===
   Print("📥 Предзагрузка данных индикаторов...");
   
   double ema50_H1[], ema200_H1[], macd_H1[], adx_H1[], rsi_H1[];
   double stoch_H1[], cci_H1[], vol_H1[], obv_H1[], bb_H1[], atr_H1[];
   double ema50_H4[], ema200_H4[], macd_H4[], adx_H4[], rsi_H4[];
   double stoch_H4[], cci_H4[], vol_H4[], obv_H4[], bb_H4[], atr_H4[];
   double ema50_D1[], ema200_D1[], macd_D1[], adx_D1[], rsi_D1[];
   double stoch_D1[], cci_D1[], vol_D1[], obv_D1[], bb_D1[], atr_D1[];
   
   ArraySetAsSeries(ema50_H1, true); ArraySetAsSeries(ema200_H1, true);
   ArraySetAsSeries(macd_H1, true); ArraySetAsSeries(adx_H1, true);
   ArraySetAsSeries(rsi_H1, true); ArraySetAsSeries(stoch_H1, true);
   ArraySetAsSeries(cci_H1, true); ArraySetAsSeries(vol_H1, true);
   ArraySetAsSeries(obv_H1, true); ArraySetAsSeries(bb_H1, true);
   ArraySetAsSeries(atr_H1, true);
   
   ArraySetAsSeries(ema50_H4, true); ArraySetAsSeries(ema200_H4, true);
   ArraySetAsSeries(macd_H4, true); ArraySetAsSeries(adx_H4, true);
   ArraySetAsSeries(rsi_H4, true); ArraySetAsSeries(stoch_H4, true);
   ArraySetAsSeries(cci_H4, true); ArraySetAsSeries(vol_H4, true);
   ArraySetAsSeries(obv_H4, true); ArraySetAsSeries(bb_H4, true);
   ArraySetAsSeries(atr_H4, true);
   
   ArraySetAsSeries(ema50_D1, true); ArraySetAsSeries(ema200_D1, true);
   ArraySetAsSeries(macd_D1, true); ArraySetAsSeries(adx_D1, true);
   ArraySetAsSeries(rsi_D1, true); ArraySetAsSeries(stoch_D1, true);
   ArraySetAsSeries(cci_D1, true); ArraySetAsSeries(vol_D1, true);
   ArraySetAsSeries(obv_D1, true); ArraySetAsSeries(bb_D1, true);
   ArraySetAsSeries(atr_D1, true);
   
   // Копируем все данные один раз
   CopyBuffer(hEMA50_H1, 0, 0, actualBars, ema50_H1);
   CopyBuffer(hEMA200_H1, 0, 0, actualBars, ema200_H1);
   CopyBuffer(hMACD_H1, 0, 0, actualBars, macd_H1);
   CopyBuffer(hADX_H1, 0, 0, actualBars, adx_H1);
   CopyBuffer(hRSI_H1, 0, 0, actualBars, rsi_H1);
   CopyBuffer(hStoch_H1, 0, 0, actualBars, stoch_H1);
   CopyBuffer(hCCI_H1, 0, 0, actualBars, cci_H1);
   CopyBuffer(hVol_H1, 0, 0, actualBars, vol_H1);
   CopyBuffer(hOBV_H1, 0, 0, actualBars, obv_H1);
   CopyBuffer(hBB_H1, 0, 0, actualBars, bb_H1);
   CopyBuffer(hATR_H1, 0, 0, actualBars, atr_H1);
   
   CopyBuffer(hEMA50_H4, 0, 0, actualBars, ema50_H4);
   CopyBuffer(hEMA200_H4, 0, 0, actualBars, ema200_H4);
   CopyBuffer(hMACD_H4, 0, 0, actualBars, macd_H4);
   CopyBuffer(hADX_H4, 0, 0, actualBars, adx_H4);
   CopyBuffer(hRSI_H4, 0, 0, actualBars, rsi_H4);
   CopyBuffer(hStoch_H4, 0, 0, actualBars, stoch_H4);
   CopyBuffer(hCCI_H4, 0, 0, actualBars, cci_H4);
   CopyBuffer(hVol_H4, 0, 0, actualBars, vol_H4);
   CopyBuffer(hOBV_H4, 0, 0, actualBars, obv_H4);
   CopyBuffer(hBB_H4, 0, 0, actualBars, bb_H4);
   CopyBuffer(hATR_H4, 0, 0, actualBars, atr_H4);
   
   CopyBuffer(hEMA50_D1, 0, 0, actualBars, ema50_D1);
   CopyBuffer(hEMA200_D1, 0, 0, actualBars, ema200_D1);
   CopyBuffer(hMACD_D1, 0, 0, actualBars, macd_D1);
   CopyBuffer(hADX_D1, 0, 0, actualBars, adx_D1);
   CopyBuffer(hRSI_D1, 0, 0, actualBars, rsi_D1);
   CopyBuffer(hStoch_D1, 0, 0, actualBars, stoch_D1);
   CopyBuffer(hCCI_D1, 0, 0, actualBars, cci_D1);
   CopyBuffer(hVol_D1, 0, 0, actualBars, vol_D1);
   CopyBuffer(hOBV_D1, 0, 0, actualBars, obv_D1);
   CopyBuffer(hBB_D1, 0, 0, actualBars, bb_D1);
   CopyBuffer(hATR_D1, 0, 0, actualBars, atr_D1);
   
   Print("✅ Предзагрузка завершена");
   
   double bestAccuracy = 0.0;
   IndicatorParams bestParams;
   bestParams.Init();
   int bestTotalTrades = 0, bestWins = 0;
   int bestTotalH1 = 0, bestWinsH1 = 0, bestLossesH1 = 0;
   int bestTotalH4 = 0, bestWinsH4 = 0, bestLossesH4 = 0;
   int bestTotalD1 = 0, bestWinsD1 = 0, bestLossesD1 = 0;
   
   int totalCombinations = tCount * aCount * eCount * rCount;
   int currentCombination = 0;
   Print("🔄 Начало оптимизации: ", totalCombinations, " комбинаций...");
   Print("   Порог: ", tCount, " значений | ATR: ", aCount, " | EMA: ", eCount, " | RSI: ", rCount);
   
   for(int t = 0; t < tCount; t++)
   for(int a = 0; a < aCount; a++)
   for(int e = 0; e < eCount; e++)
   for(int r = 0; r < rCount; r++)
   {
      currentCombination++;
      if(currentCombination % 10 == 0) Print("⏳ Оптимизация: ", currentCombination, " из ", totalCombinations);
      
      IndicatorParams testParams = optParams;
      testParams.signalThreshold = testThresholds[t];
      testParams.atrSLMult = testATRMultipliers[a];
      testParams.emaFastPeriod = testEMAPeriods[e];
      testParams.rsiPeriod = testRSIPeriods[r];
      
      int totalH1 = 0, winsH1 = 0, lossesH1 = 0, canceledH1 = 0;
      int totalH4 = 0, winsH4 = 0, lossesH4 = 0, canceledH4 = 0;
      int totalD1 = 0, winsD1 = 0, lossesD1 = 0, canceledD1 = 0;
      int lastCheckedH4 = -1, lastCheckedD1 = -1;
      
      for(int shift = actualBars-2; shift >= 5; shift--)
      {
         if(shift % BacktestStepBars != 0) continue;
         datetime barTime = iTime(_Symbol, PERIOD_H1, shift);
         MqlDateTime dt;
         TimeToStruct(barTime, dt);
         if(dt.hour >= SESSION_DEAD_HOUR_START && dt.hour < SESSION_DEAD_HOUR_END) continue;
         if(dt.day_of_week == 0 || dt.day_of_week == 6) continue;
         if(dt.day_of_week == 5 && dt.hour >= SESSION_FRIDAY_CLOSE_HOUR) continue;
         
         if(UseSignalH1)
         {
            // Используем предзагруженные данные
            IndicatorVotes sig;
            sig.weightedSum = BT_CalculateSignalFromArrays(shift, ema50_H1, ema200_H1, macd_H1, adx_H1, rsi_H1, 
                                                           stoch_H1, cci_H1, vol_H1, obv_H1, bb_H1, atr_H1, testParams);
            
            if(MathAbs(sig.weightedSum) >= testParams.signalThreshold && 
               BT_CheckCandleAndRSI_Fast(shift, PERIOD_H1, sig.weightedSum, rsi_H1, testParams))
            {
               sig.candlesForecast = BT_CalculateForecast(sig.weightedSum);
               BT_SimulateTrade_Fast(shift, PERIOD_H1, sig.weightedSum, testParams.atrSLMult, 
                                     totalH1, winsH1, lossesH1, canceledH1, testParams, barTime, sig.candlesForecast, atr_H1);
            }
         }
         // Аналогично для H4 и D1...
      }
      
      int realTotal = winsH1 + lossesH1 + winsH4 + lossesH4 + winsD1 + lossesD1;
      int wins = winsH1 + winsH4 + winsD1;
      int totalTests = totalH1 + totalH4 + totalD1;
      
      if(realTotal >= 3)  // Было BACKTEST_MIN_REAL_SIGNALS (5) — снижено
      {
         double accuracy = wins * 100.0 / realTotal;
         if(accuracy > bestAccuracy || (accuracy == bestAccuracy && totalTests > bestTotalTrades))
         {
            bestAccuracy = accuracy;
            bestParams = testParams;
            bestTotalTrades = totalTests;
            bestWins = wins;
            bestTotalH1 = totalH1; bestWinsH1 = winsH1; bestLossesH1 = lossesH1;
            bestTotalH4 = totalH4; bestWinsH4 = winsH4; bestLossesH4 = lossesH4;
            bestTotalD1 = totalD1; bestWinsD1 = winsD1; bestLossesD1 = lossesD1;
         }
      }
   }
   
   Print("🏁 АВТО-ОПТИМИЗАЦИЯ ЗАВЕРШЕНА");
   Print("🏆 ЛУЧШАЯ КОНФИГУРАЦИЯ:");
   Print("   ▶ Порог: ", DoubleToString(bestParams.signalThreshold, 1));
   Print("   ▶ ATR SL: ", DoubleToString(bestParams.atrSLMult, 1));
   Print("   ▶ EMA: ", bestParams.emaFastPeriod);
   Print("   ▶ RSI: ", bestParams.rsiPeriod);
   Print("   ▶ Точность: ", DoubleToString(bestAccuracy, 1), "%");
   Print("   ▶ Сигналов: ", bestTotalTrades, " (WIN: ", bestWins, " | LOSS: ", bestTotalTrades - bestWins, ")");
   
   if(bestTotalH1 > 0) { 
      int r = bestWinsH1 + bestLossesH1; 
      if(r > 0) Print("   H1: ", DoubleToString(bestWinsH1 * 100.0 / r, 1), "%"); 
      else Print("   H1: нет завершённых сделок");
   }
   if(bestTotalH4 > 0) { 
      int r = bestWinsH4 + bestLossesH4; 
      if(r > 0) Print("   H4: ", DoubleToString(bestWinsH4 * 100.0 / r, 1), "%"); 
      else Print("   H4: нет завершённых сделок");
   }
   if(bestTotalD1 > 0) { 
      int r = bestWinsD1 + bestLossesD1; 
      if(r > 0) Print("   D1: ", DoubleToString(bestWinsD1 * 100.0 / r, 1), "%"); 
      else Print("   D1: нет завершённых сделок");
   }
}

//+------------------------------------------------------------------+
//| Быстрый расчёт сигнала из предзагруженных массивов               |
//+------------------------------------------------------------------+
double BT_CalculateSignalFromArrays(int shift, 
                                     double &ema50[], double &ema200[], double &macd[], double &adx[], double &rsi[],
                                     double &stoch[], double &cci[], double &vol[], double &obv[], double &bb[], double &atr[],
                                     IndicatorParams &params)
{
   double sum = 0;
   
   // EMA50 vs EMA200
   if(ema50[shift] > ema200[shift]) sum += IND_WEIGHTS[0];
   else if(ema50[shift] < ema200[shift]) sum -= IND_WEIGHTS[0];
   
   // Price vs EMA200
   double price = iClose(_Symbol, PERIOD_H1, shift);
   if(price > ema200[shift]) sum += IND_WEIGHTS[1];
   else if(price < ema200[shift]) sum -= IND_WEIGHTS[1];
   
   // MACD
   if(macd[shift] > 0) sum += IND_WEIGHTS[2];
   else if(macd[shift] < 0) sum -= IND_WEIGHTS[2];
   
   // ADX
   if(adx[shift] > params.adxThreshold) sum += IND_WEIGHTS[3];
   
   // RSI
   if(rsi[shift] > 50) sum += IND_WEIGHTS[4];
   else if(rsi[shift] < 50) sum -= IND_WEIGHTS[4];
   
   // Stochastic
   if(stoch[shift] > 50) sum += IND_WEIGHTS[5];
   else if(stoch[shift] < 50) sum -= IND_WEIGHTS[5];
   
   // CCI
   if(cci[shift] > 0) sum += IND_WEIGHTS[6];
   else if(cci[shift] < 0) sum -= IND_WEIGHTS[6];
   
   // Volumes
   if(vol[shift] > vol[shift+1]) sum += IND_WEIGHTS[7];
   
   // OBV
   if(obv[shift] > obv[shift+1]) sum += IND_WEIGHTS[8];
   
   // Bollinger Bands
   if(price > bb[shift]) sum += IND_WEIGHTS[9];
   else if(price < bb[shift]) sum -= IND_WEIGHTS[9];
   
   return sum;
}

//+------------------------------------------------------------------+
//| Быстрая проверка свечи и RSI из массивов                         |
//+------------------------------------------------------------------+
bool BT_CheckCandleAndRSI_Fast(int shift, ENUM_TIMEFRAMES tf, double wSum, double &rsi[], IndicatorParams &params)
{
   double close[], open[];
   ArraySetAsSeries(close, true); 
   ArraySetAsSeries(open, true);
   
   if(CopyClose(_Symbol, tf, shift, 3, close) < 3) return false;
   if(CopyOpen(_Symbol, tf, shift, 3, open) < 3) return false;
   
   bool candleOk = (wSum > 0 && close[1] > open[1]) || (wSum < 0 && close[1] < open[1]);
   bool rsiOk = (wSum > 0 && rsi[shift] < RSI_FILTER_BUY_MAX) || (wSum < 0 && rsi[shift] > RSI_FILTER_SELL_MIN);
   
   return (candleOk && rsiOk);
}

//+------------------------------------------------------------------+
//| Быстрая симуляция сделки из массивов                             |
//+------------------------------------------------------------------+
bool BT_SimulateTrade_Fast(int shift, ENUM_TIMEFRAMES tf, double wSum, double atrMult,
                           int &totalTests, int &wins, int &losses, int &canceled,
                           IndicatorParams &params, datetime signalTime, int candlesForecast,
                           double &atr[])
{
   int lifetimeMinutes = BT_CalculateLifetime(tf, wSum, candlesForecast);
   int lifetimeBars = (tf == PERIOD_H1) ? lifetimeMinutes / 60 : (tf == PERIOD_H4) ? lifetimeMinutes / 240 : lifetimeMinutes / 1440;
   if(lifetimeBars < 1) lifetimeBars = 1;
   
   double entry = iClose(_Symbol, tf, shift);
   if(entry == 0) return false;
   
   double currentATR = atr[shift];
   if(currentATR <= 0) return false;
   
   double sl = 0, tp = 0;
   string direction = (wSum > 0) ? "BUY" : "SELL";
   double slDistance = currentATR * atrMult;
   if(direction == "BUY") { sl = entry - slDistance; tp = entry + (slDistance * TP_MULTIPLIER); }
   else { sl = entry + slDistance; tp = entry - (slDistance * TP_MULTIPLIER); }
   
   bool entryReached = false, slHit = false, tpHit = false;
   double exitPrice = 0;
   string result = "";
   
   for(int i = 1; i <= lifetimeBars && (shift - i) >= 0; i++)
   {
      double barHigh = iHigh(_Symbol, tf, shift - i);
      double barLow = iLow(_Symbol, tf, shift - i);
      if(barHigh == 0 || barLow == 0) continue;
      
      if(!entryReached)
      {
         if((direction == "BUY" && barHigh >= entry) || (direction == "SELL" && barLow <= entry))
            entryReached = true;
      }
      else
      {
         if(direction == "BUY")
         {
            if(barLow <= sl) { slHit = true; exitPrice = sl; break; }
            if(barHigh >= tp) { tpHit = true; exitPrice = tp; break; }
         }
         else
         {
            if(barHigh >= sl) { slHit = true; exitPrice = sl; break; }
            if(barLow <= tp) { tpHit = true; exitPrice = tp; break; }
         }
      }
   }
   
   if(!entryReached) { canceled++; totalTests++; result = "CANCELED"; }
   else if(slHit) { losses++; totalTests++; result = "LOSS"; }
   else if(tpHit) { wins++; totalTests++; result = "WIN"; }
   else { canceled++; totalTests++; result = "TIMEOUT"; exitPrice = iClose(_Symbol, tf, MathMax(0, shift - lifetimeBars)); }
   
   return true;
}

//+------------------------------------------------------------------+
//| Расчёт прогноза свечей                                           |
//+------------------------------------------------------------------+
int BT_CalculateForecast(double weightedSum)
{
   double absSum = MathAbs(weightedSum);
   if(absSum >= 12) return 5;
   if(absSum >= 10) return 4;
   if(absSum >= 8) return 3;
   if(absSum >= 6) return 2;
   return 1;
}

#endif