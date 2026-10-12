//+------------------------------------------------------------------+
//|                                                     Analyzer.mqh |
//|           СЛОЙ 3: ЯДРО АНАЛИЗА (единая логика для реала и теста) |
//+------------------------------------------------------------------+
#ifndef ANALYZER_MQH
#define ANALYZER_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

//+------------------------------------------------------------------+
//| ЕДИНАЯ ФУНКЦИЯ АНАЛИЗА ТАЙМФРЕЙМА                               |
//| Вызывается и в OnTick (shift=0), и в цикле бэктеста (shift=N)    |
//+------------------------------------------------------------------+
IndicatorVotes AnalyzeSignal(ENUM_TIMEFRAMES tf, int shift,
                             int hEMA50, int hEMA200, int hMACD, int hADX, int hRSI,
                             int hStoch, int hCCI, int hVol, int hOBV, int hBB, int hATR,
                             const IndicatorParams &params)
{
   IndicatorVotes result;
   result.Init(); // Инициализация нулями из DataStructures
   
   //=== 1. ПОЛУЧАЕМ ЦЕНОВЫЕ ДАННЫЕ ===
   double close[], open[], high[], low[];
   ArraySetAsSeries(close, true); ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
   
   if(CopyClose(_Symbol, tf, shift, 3, close) < 3) return result;
   if(CopyOpen(_Symbol, tf, shift, 3, open) < 3) return result;
   if(CopyHigh(_Symbol, tf, shift, 3, high) < 3) return result;
   if(CopyLow(_Symbol, tf, shift, 3, low) < 3) return result;
   
   //=== 2. ПОЛУЧАЕМ ДАННЫЕ ИНДИКАТОРОВ ===
   double ema50[], ema200[], macdMain[], macdSig[], adx[], plusDI[], minusDI[];
   double rsi[], stochK[], stochD[], cci[], vol[], obv[], bbMid[], bbUp[], bbLow[], atr[];
   
   ArraySetAsSeries(ema50, true); ArraySetAsSeries(ema200, true);
   ArraySetAsSeries(macdMain, true); ArraySetAsSeries(macdSig, true);
   ArraySetAsSeries(adx, true); ArraySetAsSeries(plusDI, true); ArraySetAsSeries(minusDI, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(stochK, true); ArraySetAsSeries(stochD, true);
   ArraySetAsSeries(cci, true); ArraySetAsSeries(vol, true); ArraySetAsSeries(obv, true);
   ArraySetAsSeries(bbMid, true); ArraySetAsSeries(bbUp, true); ArraySetAsSeries(bbLow, true);
   ArraySetAsSeries(atr, true);
   
   if(CopyBuffer(hEMA50, 0, shift, 3, ema50) < 3) return result;
   if(CopyBuffer(hEMA200, 0, shift, 3, ema200) < 3) return result;
   if(CopyBuffer(hMACD, 0, shift, 3, macdMain) < 3) return result;
   if(CopyBuffer(hMACD, 1, shift, 3, macdSig) < 3) return result;
   if(CopyBuffer(hADX, 0, shift, 3, adx) < 3) return result;
   if(CopyBuffer(hADX, 1, shift, 3, plusDI) < 3) return result;
   if(CopyBuffer(hADX, 2, shift, 3, minusDI) < 3) return result;
   if(CopyBuffer(hRSI, 0, shift, 3, rsi) < 3) return result;
   if(CopyBuffer(hStoch, 0, shift, 3, stochK) < 3) return result;
   if(CopyBuffer(hStoch, 1, shift, 3, stochD) < 3) return result;
   if(CopyBuffer(hCCI, 0, shift, 3, cci) < 3) return result;
   if(CopyBuffer(hVol, 0, shift, 3, vol) < 3) return result;
   if(CopyBuffer(hOBV, 0, shift, 3, obv) < 3) return result;
   if(CopyBuffer(hBB, 0, shift, 3, bbMid) < 3) return result;
   if(CopyBuffer(hBB, 1, shift, 3, bbUp) < 3) return result;
   if(CopyBuffer(hBB, 2, shift, 3, bbLow) < 3) return result;
   if(CopyBuffer(hATR, 0, shift, 3, atr) < 3) return result;
   
   //=== 3. РАСЧЁТ ГОЛОСОВ (используем параметры из struct) ===
   int votes[10];
   votes[0] = (close[1] > ema50[1]) ? 1 : -1;
   votes[1] = (close[1] > ema200[1]) ? 1 : -1;
   
   if(macdMain[2] < macdSig[2] && macdMain[1] > macdSig[1]) votes[2] = 1;
   else if(macdMain[2] > macdSig[2] && macdMain[1] < macdSig[1]) votes[2] = -1;
   else votes[2] = (macdMain[1] > macdSig[1]) ? 1 : -1;
   
   if(adx[1] > params.adxThreshold)
      votes[3] = (plusDI[1] > minusDI[1]) ? 1 : -1;
   else
      votes[3] = 0;
   
   if(rsi[1] > params.rsiOverbought) votes[4] = -1;
   else if(rsi[1] < params.rsiOversold) votes[4] = 1;
   else votes[4] = (rsi[1] > 50) ? 1 : -1;
   
   if(stochK[2] < stochD[2] && stochK[1] > stochD[1] && stochK[1] < 30) votes[5] = 1;
   else if(stochK[2] > stochD[2] && stochK[1] < stochD[1] && stochK[1] > 70) votes[5] = -1;
   else votes[5] = 0;
   
   if(cci[1] > params.cciLevel) votes[6] = 1;
   else if(cci[1] < -params.cciLevel) votes[6] = -1;
   else votes[6] = 0;
   
   if(vol[1] > vol[2] * 1.2)
      votes[7] = (close[1] > close[2]) ? 1 : -1;
   else
      votes[7] = 0;
   
   votes[8] = (obv[1] > obv[2]) ? 1 : -1;
   
   if(close[1] <= bbLow[1]) votes[9] = 1;
   else if(close[1] >= bbUp[1]) votes[9] = -1;
   else votes[9] = 0;
   
   //=== 4. ВЗВЕШЕННАЯ СУММА (берём веса из Config.mqh) ===
   double weightedSum = 0;
   for(int i = 0; i < 10; i++)
      weightedSum += votes[i] * IND_WEIGHTS[i];
   
   result.weightedSum = weightedSum;
   result.totalSum = (int)weightedSum;
   
   // Копируем голоса для отображения на панели
   for(int i = 0; i < 10; i++) result.votes[i] = votes[i];
   
   //=== 5. ОПРЕДЕЛЕНИЕ СИГНАЛА ===
   if(weightedSum >= params.signalThreshold)       result.signal = "STRONG BUY";
   else if(weightedSum >= SIGNAL_WEAK_THRESHOLD)    result.signal = "BUY";
   else if(weightedSum <= -params.signalThreshold)  result.signal = "STRONG SELL";
   else if(weightedSum <= -SIGNAL_WEAK_THRESHOLD)   result.signal = "SELL";
   else                                             result.signal = "HOLD";
   
   //=== 6. РАСЧЁТ ATR И ПРОГНОЗА ===
   result.atrValue = atr[1];
   result.currentPrice = close[1];
   double priceRange = bbUp[1] - bbLow[1];
   
   // Базовые свечи по ТФ
   int baseCandlesTF = (tf == PERIOD_H1) ? BASE_CANDLES_H1 : 
                       (tf == PERIOD_H4) ? BASE_CANDLES_H4 : 
                       (tf == PERIOD_D1) ? BASE_CANDLES_D1 : 3;
   
   int baseCandles = baseCandlesTF;
   double signalStrength = MathAbs(weightedSum);
   
   if(signalStrength >= SIGNAL_STRONG) baseCandles = baseCandlesTF + 1;
   else if(signalStrength >= SIGNAL_ABOVE_AVG) baseCandles = baseCandlesTF;
   else baseCandles = MathMax(1, baseCandlesTF - 1);
   
   double volatilityFactor = (priceRange > 0) ? result.atrValue / (priceRange * 0.1) : 1.0;
   if(volatilityFactor > 1.5) baseCandles = (int)(baseCandles * 0.8);
   else if(volatilityFactor < 0.5) baseCandles = (int)(baseCandles * 1.2);
   
   // Границы по ТФ
   int minC = (tf == PERIOD_H1) ? MIN_CANDLES_H1 : (tf == PERIOD_H4) ? MIN_CANDLES_H4 : MIN_CANDLES_D1;
   int maxC = (tf == PERIOD_H1) ? MAX_CANDLES_H1 : (tf == PERIOD_H4) ? MAX_CANDLES_H4 : MAX_CANDLES_D1;
   
   result.candlesForecast = MathMax(minC, MathMin(maxC, baseCandles));
   
   //=== 7. РАСЧЁТ ЦЕЛЕВОЙ ЦЕНЫ (Target Price) ===
   double multiplier = 0;
   if(tf == PERIOD_H1)      multiplier = TP_MULT_H1_BASE + (result.candlesForecast * TP_MULT_H1_STEP);
   else if(tf == PERIOD_H4) multiplier = TP_MULT_H4_BASE + (result.candlesForecast * TP_MULT_H4_STEP);
   else if(tf == PERIOD_D1) multiplier = TP_MULT_D1_BASE + (result.candlesForecast * TP_MULT_D1_STEP);
   else                     multiplier = 1.5;
   
   if(weightedSum > 0)
      result.targetPrice = result.currentPrice + (result.atrValue * multiplier);
   else if(weightedSum < 0)
      result.targetPrice = result.currentPrice - (result.atrValue * multiplier);
   else
      result.targetPrice = result.currentPrice;
   
   return result;
}

#endif