//+------------------------------------------------------------------+
//|                                               DataStructures.mqh |
//|           СЛОЙ 2: СТРУКТУРЫ ДАННЫХ — единые для всех слоёв       |
//+------------------------------------------------------------------+
#ifndef DATA_STRUCTURES_MQH
#define DATA_STRUCTURES_MQH

#include <Config.mqh>

//+------------------------------------------------------------------+
//| Статус сигнала (машина состояний)                                |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_STATUS
{
   SIGNAL_STATUS_IDLE = 0,           // Нет активного сигнала
   SIGNAL_STATUS_WAITING_ENTRY,      // Ждём достижения Entry
   SIGNAL_STATUS_EXECUTED,           // Сигнал исполнен, ждём SL/TP
   SIGNAL_STATUS_WIN,                // Закрыт по TP
   SIGNAL_STATUS_LOSS,               // Закрыт по SL
   SIGNAL_STATUS_CANCELED,           // Аннулирован (не исполнился)
   SIGNAL_STATUS_TIMEOUT,            // Истёк срок жизни
   SIGNAL_STATUS_REPLACED            // Заменён более сильным
};

//+------------------------------------------------------------------+
//| Голоса индикаторов и результат анализа ТФ                        |
//+------------------------------------------------------------------+
struct IndicatorVotes
{
   int    votes[10];           // Голоса 10 индикаторов (+1/0/-1)
   double weightedSum;         // Взвешенная сумма
   int    totalSum;            // Целочисленная сумма
   string signal;              // "STRONG BUY", "BUY", "HOLD", "SELL", "STRONG SELL"
   int    candlesForecast;     // Прогноз количества свечей
   double currentPrice;        // Текущая цена
   double targetPrice;         // Целевая цена
   double atrValue;            // Значение ATR
   
   // Конструктор по умолчанию
   void Init()
   {
      ArrayInitialize(votes, 0);
      weightedSum = 0;
      totalSum = 0;
      signal = "HOLD";
      candlesForecast = 0;
      currentPrice = 0;
      targetPrice = 0;
      atrValue = 0;
   }
};

//+------------------------------------------------------------------+
//| Параметры индикаторов (для оптимизации)                          |
//+------------------------------------------------------------------+
struct IndicatorParams
{
   // EMA
   int    emaFastPeriod;
   int    emaSlowPeriod;
   
   // RSI
   int    rsiPeriod;
   double rsiOverbought;
   double rsiOversold;
   
   // MACD
   int    macdFast;
   int    macdSlow;
   int    macdSignal;
   
   // ADX
   int    adxPeriod;
   double adxThreshold;
   
   // Stochastic
   int    stochK;
   int    stochD;
   int    stochSlowing;
   
   // CCI
   int    cciPeriod;
   double cciLevel;
   
   // Bollinger Bands
   int    bbPeriod;
   double bbDeviation;
   
   // ATR
   int    atrPeriod;
   double atrSLMult;
   
   // Порог сигнала
   double signalThreshold;
   
   // Конструктор: инициализация значениями по умолчанию из Config
   void Init()
   {
      emaFastPeriod   = 30;
      emaSlowPeriod   = 200;
      rsiPeriod       = 10;
      rsiOverbought   = RSI_OVERBOUGHT_DEFAULT;
      rsiOversold     = RSI_OVERSOLD_DEFAULT;
      macdFast        = 12;
      macdSlow        = 26;
      macdSignal      = 9;
      adxPeriod       = 14;
      adxThreshold    = 25.0;
      stochK          = 14;
      stochD          = 3;
      stochSlowing    = 3;
      cciPeriod       = 20;
      cciLevel        = 100.0;
      bbPeriod        = 20;
      bbDeviation     = 2.0;
      atrPeriod       = 14;
      atrSLMult       = ATR_SL_MULTIPLIER_DEFAULT;
      signalThreshold = SIGNAL_THRESHOLD_DEFAULT;
   }
};

//+------------------------------------------------------------------+
//| Запись сигнала в истории (для вкладки ИСТОРИЯ)                   |
//+------------------------------------------------------------------+
struct SignalRecord
{
   datetime time;            // Время сигнала
   string   mode;            // "H1", "H4", "D1"
   string   direction;       // "BUY", "SELL"
   double   entry;           // Цена входа
   double   sl;              // Стоп-лосс
   double   tp;              // Тейк-профит
   string   status;          // "⏳ ОЖИДАНИЕ", "✅ WIN", "❌ LOSS"
   double   movement;        // Движение цены
   double   weightedSum;     // Сила сигнала
   
   void Init()
   {
      time = 0;
      mode = "";
      direction = "";
      entry = 0;
      sl = 0;
      tp = 0;
      status = HISTORY_STATUS_WAITING;
      movement = 0;
      weightedSum = 0;
   }
};

//+------------------------------------------------------------------+
//| ЕДИНОЕ СОСТОЯНИЕ СИГНАЛА — источник истины для всех слоёв        |
//| (используется в SignalManager, UI, Storage)                      |
//+------------------------------------------------------------------+
struct SignalState
{
   //=== ИДЕНТИФИКАЦИЯ ===
   ENUM_SIGNAL_STATUS status;      // Текущий статус (машина состояний)
   string             mode;        // "H1", "H4", "D1"
   string             direction;   // "BUY", "SELL"
   string             orderType;   // "BUY LIMIT", "BUY STOP", "SELL LIMIT", "SELL STOP"
   
   //=== ЦЕНЫ ===
   double entry;                   // Цена входа
   double sl;                      // Стоп-лосс
   double tp;                      // Тейк-профит
   double atrAtSignal;             // ATR на момент сигнала
   
   //=== ВРЕМЯ ===
   datetime createdAt;             // Время создания сигнала
   datetime expiresAt;             // Время истечения срока жизни
   datetime executedAt;            // Время исполнения (когда цена дошла до Entry)
   datetime closedAt;              // Время закрытия (SL/TP)
   
   //=== СИЛА СИГНАЛА ===
   double weightedSum;             // Взвешенная сумма индикаторов
   int    candlesForecast;         // Прогноз свечей
   
   //=== ФЛАГИ ===
   bool   wasExecuted;             // Достигла ли цена Entry
   bool   isChecked;               // Обработан ли результат
   
   //=== МЕТАДАННЫЕ ===
   double exitPrice;               // Цена выхода (SL/TP)
   double movement;                // Движение цены
   string result;                  // "WIN", "LOSS", "CANCELED", "TIMEOUT"
   
   //=== МЕТОДЫ ===
   void Init()
   {
      status = SIGNAL_STATUS_IDLE;
      mode = "";
      direction = "";
      orderType = "";
      entry = 0;
      sl = 0;
      tp = 0;
      atrAtSignal = 0;
      createdAt = 0;
      expiresAt = 0;
      executedAt = 0;
      closedAt = 0;
      weightedSum = 0;
      candlesForecast = 0;
      wasExecuted = false;
      isChecked = false;
      exitPrice = 0;
      movement = 0;
      result = "";
   }
   
   // Проверка: есть ли активный сигнал
   bool IsActive() const
   {
      return (status == SIGNAL_STATUS_WAITING_ENTRY || 
              status == SIGNAL_STATUS_EXECUTED);
   }
   
   // Проверка: сигнал завершён
   bool IsFinished() const
   {
      return (status == SIGNAL_STATUS_WIN || 
              status == SIGNAL_STATUS_LOSS || 
              status == SIGNAL_STATUS_CANCELED || 
              status == SIGNAL_STATUS_TIMEOUT ||
              status == SIGNAL_STATUS_REPLACED);
   }
   
   // Расчёт R:R
   double GetRiskReward() const
   {
      double slDist = MathAbs(entry - sl);
      double tpDist = MathAbs(tp - entry);
      if(slDist <= 0) return 0;
      return tpDist / slDist;
   }
   
   // Время жизни в минутах
   int GetLifetimeMinutes() const
   {
      if(expiresAt == 0 || createdAt == 0) return 0;
      return (int)((expiresAt - createdAt) / 60);
   }
   
   // Прошло минут с создания
   int GetElapsedMinutes() const
   {
      if(createdAt == 0) return 0;
      return (int)((TimeCurrent() - createdAt) / 60);
   }
};

//+------------------------------------------------------------------+
//| Значения индикаторов на конкретном баре (для бэктеста)           |
//+------------------------------------------------------------------+
struct IndicatorValues
{
   double ema50, ema200;
   double macdMain, macdSignal;
   double adx, plusDI, minusDI;
   double rsi;
   double stochK, stochD;
   double cci;
   double volume;
   double obv;
   double bbUpper, bbMiddle, bbLower;
   double atr;
   double close, open, high, low;
   
   void Init()
   {
      ema50 = ema200 = 0;
      macdMain = macdSignal = 0;
      adx = plusDI = minusDI = 0;
      rsi = 0;
      stochK = stochD = 0;
      cci = 0;
      volume = 0;
      obv = 0;
      bbUpper = bbMiddle = bbLower = 0;
      atr = 0;
      close = open = high = low = 0;
   }
};

//+------------------------------------------------------------------+
//| Результат симуляции сделки (для бэктеста)                        |
//+------------------------------------------------------------------+
struct BacktestResult
{
   datetime signalTime;
   string   mode;              // "H1", "H4", "D1"
   string   direction;         // "BUY", "SELL"
   double   entry;
   double   sl;
   double   tp;
   double   exitPrice;
   string   result;            // "WIN", "LOSS", "CANCELED", "TIMEOUT"
   double   movement;
   int      lifetimeMinutes;
   double   weightedSum;
   
   void Init()
   {
      signalTime = 0;
      mode = "";
      direction = "";
      entry = sl = tp = 0;
      exitPrice = 0;
      result = "";
      movement = 0;
      lifetimeMinutes = 0;
      weightedSum = 0;
   }
};

//+------------------------------------------------------------------+
//| Статистика бэктеста                                              |
//+------------------------------------------------------------------+
struct BacktestStats
{
   int totalSignals;
   int wins;
   int losses;
   int canceled;
   int timeouts;
   
   // По таймфреймам
   int totalH1, winsH1, lossesH1, canceledH1;
   int totalH4, winsH4, lossesH4, canceledH4;
   int totalD1, winsD1, lossesD1, canceledD1;
   
   void Init()
   {
      totalSignals = wins = losses = canceled = timeouts = 0;
      totalH1 = winsH1 = lossesH1 = canceledH1 = 0;
      totalH4 = winsH4 = lossesH4 = canceledH4 = 0;
      totalD1 = winsD1 = lossesD1 = canceledD1 = 0;
   }
   
   double GetAccuracy() const
   {
      int realTotal = wins + losses;
      if(realTotal == 0) return 0;
      return wins * 100.0 / realTotal;
   }
   
   int GetRealTotal() const
   {
      return wins + losses;
   }
};

#endif