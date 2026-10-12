//+------------------------------------------------------------------+
//| Analyzer.mqh                                                     |
//| СЛОЙ 3: ЯДРО АНАЛИЗА (MEAN REVERSION - BB + Stochastic)          |
//+------------------------------------------------------------------+
#ifndef ANALYZER_MQH
#define ANALYZER_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

//+------------------------------------------------------------------+
//| ЕДИНАЯ ФУНКЦИЯ АНАЛИЗА (MEAN REVERSION MODE)                     |
//| Логика: Возврат к средней линии Боллинджера                      |
//+------------------------------------------------------------------+
IndicatorVotes AnalyzeSignal(ENUM_TIMEFRAMES tf, int shift,
                             int hEMA50, int hEMA200, int hMACD, int hADX, int hRSI,
                             int hStoch, int hCCI, int hVol, int hOBV, int hBB, int hATR,
                             const IndicatorParams &params)
{
   IndicatorVotes result;
   result.Init();

   //=== 1. ПОЛУЧАЕМ ДАННЫЕ ===
   double close[], open[], high[], low[];
   ArraySetAsSeries(close, true); ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true); ArraySetAsSeries(low, true);
   if(CopyClose(_Symbol, tf, shift, 3, close) < 3) return result;
   if(CopyOpen(_Symbol, tf, shift, 3, open) < 3) return result;
   if(CopyHigh(_Symbol, tf, shift, 3, high) < 3) return result;
   if(CopyLow(_Symbol, tf, shift, 3, low) < 3) return result;
   
   double bbMid[], bbUp[], bbLow[], atr[];
   double stochK[], stochD[], rsi[];
   
   ArraySetAsSeries(bbMid, true); ArraySetAsSeries(bbUp, true); ArraySetAsSeries(bbLow, true);
   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(stochK, true); ArraySetAsSeries(stochD, true);
   ArraySetAsSeries(rsi, true);

   if(CopyBuffer(hBB, 0, shift, 3, bbMid) < 3) return result;
   if(CopyBuffer(hBB, 1, shift, 3, bbUp) < 3) return result;
   if(CopyBuffer(hBB, 2, shift, 3, bbLow) < 3) return result;
   if(CopyBuffer(hATR, 0, shift, 3, atr) < 3) return result;
   if(CopyBuffer(hStoch, 0, shift, 3, stochK) < 3) return result;
   if(CopyBuffer(hStoch, 1, shift, 3, stochD) < 3) return result;
   if(CopyBuffer(hRSI, 0, shift, 3, rsi) < 3) return result;

   result.atrValue = atr[1];
   result.currentPrice = close[1];

   //=== 2. ПРОВЕРКА УСЛОВИЙ ДЛЯ BUY ===
   // Условие 1: Цена касается или ниже нижней полосы BB
   bool buyBB = (close[1] <= bbLow[1] || low[1] <= bbLow[1]);
   
   // Условие 2: Stochastic в зоне перепроданности (< 20) И разворот (K пересекает D снизу вверх)
   bool buyStoch = (stochK[1] < 25.0 && stochK[1] > stochD[1] && stochK[2] <= stochD[2]);
   
   // Условие 3: RSI подтверждает перепроданность (< 35)
   bool buyRSI = (rsi[1] < 35.0);

   //=== 3. ПРОВЕРКА УСЛОВИЙ ДЛЯ SELL ===
   // Условие 1: Цена касается или выше верхней полосы BB
   bool sellBB = (close[1] >= bbUp[1] || high[1] >= bbUp[1]);
   
   // Условие 2: Stochastic в зоне перекупленности (> 75) И разворот вниз
   bool sellStoch = (stochK[1] > 75.0 && stochK[1] < stochD[1] && stochK[2] >= stochD[2]);
   
   // Условие 3: RSI подтверждает перекупленность (> 65)
   bool sellRSI = (rsi[1] > 65.0);

   //=== 4. ОПРЕДЕЛЕНИЕ СИГНАЛА ===
   // BUY: BB + Stochastic ОБЯЗАТЕЛЬНЫ, RSI опционален (но дает бонус)
   int buyScore = 0;
   if(buyBB) buyScore += 2;
   if(buyStoch) buyScore += 2;
   if(buyRSI) buyScore += 1;

   int sellScore = 0;
   if(sellBB) sellScore += 2;
   if(sellStoch) sellScore += 2;
   if(sellRSI) sellScore += 1;

   // Для сигнала нужны ОБА главных условия (BB + Stochastic) = минимум 4 балла
   // С RSI = 5 баллов (STRONG)
   if(buyScore >= 4) {
      result.signal = (buyScore == 5) ? "STRONG BUY" : "BUY";
      result.weightedSum = buyScore;
      result.targetPrice = bbMid[1]; // TP = средняя линия BB
   } 
   else if(sellScore >= 4) {
      result.signal = (sellScore == 5) ? "STRONG SELL" : "SELL";
      result.weightedSum = -sellScore;
      result.targetPrice = bbMid[1]; // TP = средняя линия BB
   } 
   else {
      result.signal = "HOLD";
      result.weightedSum = 0;
      result.targetPrice = close[1];
   }

   // Заполняем votes для UI
   for(int i = 0; i < 10; i++) {
      if(result.weightedSum > 0) result.votes[i] = 1;
      else if(result.weightedSum < 0) result.votes[i] = -1;
      else result.votes[i] = 0;
   }

   // Прогноз: 2-4 свечи до возврата к средней линии
   result.candlesForecast = (result.signal == "STRONG BUY" || result.signal == "STRONG SELL") ? 4 : 2;

   return result;
}

#endif