//+------------------------------------------------------------------+
//| Analyzer.mqh                                                     |
//| СЛОЙ 3: 10 ИНДИКАТОРОВ + МЯГКИЙ ФИЛЬТР УРОВНЕЙ                   |
//+------------------------------------------------------------------+
#ifndef ANALYZER_MQH
#define ANALYZER_MQH

#include <Config.mqh>
#include <DataStructures.mqh>
#include <Levels.mqh>

//+------------------------------------------------------------------+
//| ЕДИНАЯ ФУНКЦИЯ АНАЛИЗА (ИНДИКАТОРЫ + МЯГКИЙ ФИЛЬТР УРОВНЕЙ)      |
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

   //=== 3. РАСЧЁТ ГОЛОСОВ (10 ИНДИКАТОРОВ) ===
   int votes[10];
   int bullVotes = 0, bearVotes = 0;

   votes[0] = (close[1] > ema50[1]) ? 1 : -1;
   if(votes[0] > 0) bullVotes++; else bearVotes++;

   votes[1] = (close[1] > ema200[1]) ? 1 : -1;
   if(votes[1] > 0) bullVotes++; else bearVotes++;

   if(macdMain[1] > macdSig[1]) { votes[2] = 1; bullVotes++; }
   else { votes[2] = -1; bearVotes++; }

   if(adx[1] > 20.0) {
      votes[3] = (plusDI[1] > minusDI[1]) ? 1 : -1;
      if(votes[3] > 0) bullVotes++; else bearVotes++;
   } else {
      votes[3] = 0;
   }

   if(rsi[1] > 55.0) { votes[4] = 1; bullVotes++; }
   else if(rsi[1] < 45.0) { votes[4] = -1; bearVotes++; }
   else { votes[4] = 0; }

   if(stochK[1] > 50.0) { votes[5] = 1; bullVotes++; }
   else if(stochK[1] < 50.0) { votes[5] = -1; bearVotes++; }
   else { votes[5] = 0; }

   if(cci[1] > 50.0) { votes[6] = 1; bullVotes++; }
   else if(cci[1] < -50.0) { votes[6] = -1; bearVotes++; }
   else { votes[6] = 0; }

   if(vol[1] > vol[2] * 1.1) {
      votes[7] = (close[1] > open[1]) ? 1 : -1;
      if(votes[7] > 0) bullVotes++; else bearVotes++;
   } else {
      votes[7] = 0;
   }

   votes[8] = (obv[1] > obv[2]) ? 1 : -1;
   if(votes[8] > 0) bullVotes++; else bearVotes++;

   votes[9] = (close[1] > bbMid[1]) ? 1 : -1;
   if(votes[9] > 0) bullVotes++; else bearVotes++;

   //=== 4. ПРОВЕРКА КОНФЛЮЭНСА ===
   if(bullVotes < 3 && bearVotes < 3) {
      result.signal = "HOLD";
      result.weightedSum = 0;
      result.totalSum = 0;
      for(int i=0; i<10; i++) result.votes[i] = votes[i];
      result.atrValue = atr[1];
      result.currentPrice = close[1];
      result.targetPrice = close[1];
      result.candlesForecast = 0;
      return result;
   }

   //=== 5. ВЗВЕШЕННАЯ СУММА ===
   double weightedSum = 0;
   for(int i = 0; i < 10; i++) {
      weightedSum += votes[i] * IND_WEIGHTS[i];
   }
   
   if(adx[1] < 20.0) {
      weightedSum *= 0.5;
   }

   //=== 6. 🆕 МЯГКИЙ ФИЛЬТР УРОВНЕЙ (бонус/штраф) ===
   double currentPrice = close[1];
   double levelZoneATR = 0.5; // Широкая зона — 0.5 ATR
   
   bool nearSupport = Levels_IsNearLevel(currentPrice, "SUPPORT", levelZoneATR);
   bool nearResistance = Levels_IsNearLevel(currentPrice, "RESISTANCE", levelZoneATR);
   
   // Бонус за совпадение направления с уровнем
   if(weightedSum > 0 && nearSupport) {
      weightedSum += 1.5; // BUY у поддержки = бонус
   }
   else if(weightedSum < 0 && nearResistance) {
      weightedSum -= 1.5; // SELL у сопротивления = бонус
   }
   // Штраф за торговлю против уровня
   else if(weightedSum > 0 && nearResistance) {
      weightedSum -= 1.0; // BUY у сопротивления = штраф
   }
   else if(weightedSum < 0 && nearSupport) {
      weightedSum += 1.0; // SELL у поддержки = штраф
   }

   result.weightedSum = weightedSum;
   result.totalSum = (int)weightedSum;
   for(int i = 0; i < 10; i++) result.votes[i] = votes[i];

   //=== 7. ОПРЕДЕЛЕНИЕ СИГНАЛА ===
   if(weightedSum >= params.signalThreshold) result.signal = "STRONG BUY";
   else if(weightedSum >= SIGNAL_WEAK_THRESHOLD) result.signal = "BUY";
   else if(weightedSum <= -params.signalThreshold) result.signal = "STRONG SELL";
   else if(weightedSum <= -SIGNAL_WEAK_THRESHOLD) result.signal = "SELL";
   else result.signal = "HOLD";

   //=== 8. РАСЧЁТ ATR И ПРОГНОЗА ===
   result.atrValue = atr[1];
   result.currentPrice = close[1];
   
   int baseCandlesTF = (tf == PERIOD_H1) ? BASE_CANDLES_H1 : 
                       (tf == PERIOD_H4) ? BASE_CANDLES_H4 : BASE_CANDLES_D1;
   
   double signalStrength = MathAbs(weightedSum);
   int baseCandles = baseCandlesTF;
   if(signalStrength >= SIGNAL_STRONG) baseCandles = baseCandlesTF + 1;
   else if(signalStrength < SIGNAL_WEAK_THRESHOLD) baseCandles = MathMax(1, baseCandlesTF - 1);

   int minC = (tf == PERIOD_H1) ? MIN_CANDLES_H1 : (tf == PERIOD_H4) ? MIN_CANDLES_H4 : MIN_CANDLES_D1;
   int maxC = (tf == PERIOD_H1) ? MAX_CANDLES_H1 : (tf == PERIOD_H4) ? MAX_CANDLES_H4 : MAX_CANDLES_D1;
   result.candlesForecast = MathMax(minC, MathMin(maxC, baseCandles));

   //=== 9. РАСЧЁТ ЦЕЛЕВОЙ ЦЕНЫ ===
   double multiplier = 0;
   if(tf == PERIOD_H1) multiplier = TP_MULT_H1_BASE + (result.candlesForecast * TP_MULT_H1_STEP);
   else if(tf == PERIOD_H4) multiplier = TP_MULT_H4_BASE + (result.candlesForecast * TP_MULT_H4_STEP);
   else if(tf == PERIOD_D1) multiplier = TP_MULT_D1_BASE + (result.candlesForecast * TP_MULT_D1_STEP);
   else multiplier = 1.5;

   if(weightedSum > 0)
      result.targetPrice = result.currentPrice + (result.atrValue * multiplier);
   else if(weightedSum < 0)
      result.targetPrice = result.currentPrice - (result.atrValue * multiplier);
   else
      result.targetPrice = result.currentPrice;

   return result;
}

#endif