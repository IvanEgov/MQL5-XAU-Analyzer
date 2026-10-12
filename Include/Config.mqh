//+------------------------------------------------------------------+
//|                                                    Config.mqh    |
//|           СЛОЙ 1: КОНФИГУРАЦИЯ — все константы в одном месте     |
//+------------------------------------------------------------------+
#ifndef CONFIG_MQH
#define CONFIG_MQH

//+------------------------------------------------------------------+
//| ВЕСА ИНДИКАТОРОВ (сумма = 16.0)                                  |
//| 0: EMA50, 1: EMA200, 2: MACD, 3: ADX, 4: RSI,                   |
//| 5: Stochastic, 6: CCI, 7: Volumes, 8: OBV, 9: Bollinger Bands   |
//+------------------------------------------------------------------+
const double IND_WEIGHTS[10] = {
   2.0,  // EMA50
   3.0,  // EMA200
   1.5,  // MACD
   2.0,  // ADX
   1.5,  // RSI
   1.0,  // Stochastic
   1.0,  // CCI
   1.5,  // Volumes
   1.5,  // OBV
   1.0   // Bollinger Bands
};

//+------------------------------------------------------------------+
//| ПОРОГИ СИГНАЛОВ                                                  |
//+------------------------------------------------------------------+
const double SIGNAL_THRESHOLD_MIN      = 4.0;   // Минимальный порог для сигнала
const double SIGNAL_THRESHOLD_DEFAULT  = 6.0;   // Порог по умолчанию
const double SIGNAL_STRONG_THRESHOLD   = 6.0;   // Порог "STRONG" сигнала
const double SIGNAL_WEAK_THRESHOLD     = 3.0;   // Порог слабого сигнала

//+------------------------------------------------------------------+
//| ФИЛЬТР RSI                                                       |
//+------------------------------------------------------------------+
const double RSI_OVERBOUGHT_DEFAULT    = 70.0;
const double RSI_OVERSOLD_DEFAULT      = 30.0;
const double RSI_FILTER_BUY_MAX        = 85.0;  // BUY: RSI не выше
const double RSI_FILTER_SELL_MIN       = 15.0;  // SELL: RSI не ниже
const double RSI_CORRECTION_BUY_MAX    = 45.0;  // Для входа на коррекции BUY
const double RSI_CORRECTION_SELL_MIN   = 55.0;  // Для входа на коррекции SELL

//+------------------------------------------------------------------+
//| ФИЛЬТР ЗАПАЗДЫВАНИЯ                                              |
//+------------------------------------------------------------------+
const double LAG_FILTER_ATR_MULTIPLIER = 2.0;   // Цена не должна уходить дальше N × ATR от EMA50

//+------------------------------------------------------------------+
//| ФИЛЬТР СТРУКТУРНЫХ УРОВНЕЙ                                       |
//+------------------------------------------------------------------+
const double STRUCTURE_ROOM_ATR        = 1.0;   // Минимум места для движения (ATR)

//+------------------------------------------------------------------+
//| SL/TP И RISK/REWARD                                              |
//+------------------------------------------------------------------+
const double ATR_SL_MULTIPLIER_DEFAULT = 1.5;   // Множитель ATR для SL по умолчанию
const double RR_RATIO_MIN              = 1.5;   // Минимальный R:R
const double RR_RATIO_TARGET           = 2.0;   // Целевой R:R
const double TP_MULTIPLIER             = 2.0;   // TP = SL × этот множитель

//+------------------------------------------------------------------+
//| ПРОГНОЗ ПО ТАЙМФРЕЙМАМ (количество свечей)                       |
//+------------------------------------------------------------------+
// Базовые значения
const int BASE_CANDLES_H1              = 4;     // H1: базово 4 свечи
const int BASE_CANDLES_H4              = 3;     // H4: базово 3 свечи
const int BASE_CANDLES_D1              = 2;     // D1: базово 2 свечи

// Границы по ТФ
const int MIN_CANDLES_H1               = 3;
const int MAX_CANDLES_H1               = 5;
const int MIN_CANDLES_H4               = 2;
const int MAX_CANDLES_H4               = 4;
const int MIN_CANDLES_D1               = 1;
const int MAX_CANDLES_D1               = 2;

// Множители TP по ТФ (формула: base + candles × step)
const double TP_MULT_H1_BASE           = 1.0;
const double TP_MULT_H1_STEP           = 0.3;
const double TP_MULT_H4_BASE           = 1.5;
const double TP_MULT_H4_STEP           = 0.4;
const double TP_MULT_D1_BASE           = 2.0;
const double TP_MULT_D1_STEP           = 0.5;

//+------------------------------------------------------------------+
//| СРОКИ ЖИЗНИ СИГНАЛОВ (в минутах)                                 |
//+------------------------------------------------------------------+
// Базовое время
const int LIFETIME_BASE_H1             = 180;   // 3 часа
const int LIFETIME_BASE_H4             = 480;   // 8 часов
const int LIFETIME_BASE_D1             = 2880;  // 48 часов (2 дня)

// Минимум/максимум
const int LIFETIME_MIN_H1              = 180;
const int LIFETIME_MAX_H1              = 320;
const int LIFETIME_MIN_H4              = 480;
const int LIFETIME_MAX_H4              = 1200;
const int LIFETIME_MIN_D1              = 2880;
const int LIFETIME_MAX_D1              = 7440;

// Множители от силы сигнала
const double LIFETIME_MULT_VERY_STRONG = 1.8;   // |Σ| >= 12
const double LIFETIME_MULT_STRONG      = 1.6;   // |Σ| >= 10
const double LIFETIME_MULT_ABOVE_AVG   = 1.4;   // |Σ| >= 8
const double LIFETIME_MULT_AVG         = 1.2;   // |Σ| >= 6
const double LIFETIME_MULT_WEAK        = 1.0;   // |Σ| < 6

// Пороги силы сигнала для множителей
const double SIGNAL_VERY_STRONG        = 12.0;
const double SIGNAL_STRONG             = 10.0;
const double SIGNAL_ABOVE_AVG          = 8.0;
const double SIGNAL_AVG                = 6.0;

// Множитель от прогноза свечей
const double FORECAST_MULT_BASE        = 0.8;
const double FORECAST_MULT_STEP        = 0.07;
const double FORECAST_MULT_MIN         = 0.8;
const double FORECAST_MULT_MAX         = 1.5;

//+------------------------------------------------------------------+
//| ЗАМЕНА СИГНАЛА БОЛЕЕ СИЛЬНЫМ                                     |
//+------------------------------------------------------------------+
const double STRONGER_SIGNAL_RATIO     = 1.2;   // Новый сигнал должен быть сильнее на 20%

//+------------------------------------------------------------------+
//| ПРОВЕРКА ИСПОЛНЕНИЯ                                              |
//+------------------------------------------------------------------+
const int EXECUTION_CHECK_CANDLES      = 5;     // Проверять High/Low последних N свечей
const int SIGNAL_EXPIRATION_HOURS      = 24;    // Сигнал протухает через N часов

//+------------------------------------------------------------------+
//| БЭКТЕСТ                                                          |
//+------------------------------------------------------------------+
const int BACKTEST_BARS_DEFAULT        = 1000;
const int BACKTEST_BARS_MIN            = 200;
const int BACKTEST_STEP_DEFAULT        = 4;     // Проверять каждый N-й бар
const int BACKTEST_MIN_REAL_SIGNALS    = 5;     // Минимум сигналов для стат. значимости
const int BACKTEST_NEUTRAL_ATR         = 1;     // Нейтральное движение: < N × ATR

//+------------------------------------------------------------------+
//| ПАРАМЕТРЫ ПАНЕЛИ                                                 |
//+------------------------------------------------------------------+
const string PANEL_NAME                = "AnalysisPanel";
const string BUTTON_NAME               = "CollapseButton";
const int    PANEL_X                   = 20;
const int    PANEL_Y                   = 30;
const int    PANEL_WIDTH               = 500;
const int    PANEL_HEIGHT_EXPANDED     = 520;
const int    PANEL_HEIGHT_COLLAPSED    = 35;
const int    PANEL_LINE_HEIGHT         = 20;

//+------------------------------------------------------------------+
//| ВКЛАДКИ                                                          |
//+------------------------------------------------------------------+
#define TAB_COUNT 5
const string TAB_NAMES[TAB_COUNT] = {"📊 АНАЛИЗ", "🛡️ ФИЛЬТРЫ", "📍 УРОВНИ", "📈 СТАТИСТИКА", "📜 ИСТОРИЯ"};

//+------------------------------------------------------------------+
//| ИСТОРИЯ СИГНАЛОВ                                                 |
//+------------------------------------------------------------------+
#define HISTORY_SIZE 5
const string HISTORY_STATUS_WAITING    = "⏳ ОЖИДАНИЕ";
const string HISTORY_STATUS_WIN        = "✅ WIN";
const string HISTORY_STATUS_LOSS       = "❌ LOSS";

//+------------------------------------------------------------------+
//| ЦВЕТА ЛИНИЙ ПО ТАЙМФРЕЙМАМ                                       |
//+------------------------------------------------------------------+
const color  COLOR_H1_ENTRY            = clrLime;
const color  COLOR_H1_LEVELS           = clrLime;
const color  COLOR_H4_ENTRY            = clrYellow;
const color  COLOR_H4_LEVELS           = clrYellow;
const color  COLOR_D1_ENTRY            = clrOrangeRed;
const color  COLOR_D1_LEVELS           = clrOrangeRed;
const color  COLOR_ENTRY_DEFAULT       = clrDodgerBlue;
const color  COLOR_SL_DEFAULT          = clrRed;
const color  COLOR_TP_DEFAULT          = clrLime;
const color  COLOR_RESISTANCE          = clrOrange;
const color  COLOR_SUPPORT             = clrDeepSkyBlue;
const color  COLOR_STRUCTURE           = clrGray;

//+------------------------------------------------------------------+
//| ТОЛЩИНА ЛИНИЙ                                                    |
//+------------------------------------------------------------------+
const int    LINE_WIDTH_ENTRY          = 3;
const int    LINE_WIDTH_SL_TP          = 2;
const int    LINE_WIDTH_STRUCTURE      = 1;

//+------------------------------------------------------------------+
//| ИМЕНА ФАЙЛОВ (шаблоны)                                           |
//+------------------------------------------------------------------+
const string FILE_STATS_PREFIX         = "stats_";
const string FILE_SIGNALS_PREFIX       = "signals_";
const string FILE_RESULTS_PREFIX       = "results_";
const string FILE_HISTORY_PREFIX       = "history_";
const string FILE_BACKTEST_PREFIX      = "backtest_";
const string FILE_BACKTEST_RESULTS     = "backtest_results.csv";
const string FILE_STATS_EXT            = ".json";
const string FILE_HISTORY_EXT          = ".dat";
const string FILE_CSV_EXT              = ".csv";

//+------------------------------------------------------------------+
//| ФИЛЬТР СЕССИИ                                                    |
//+------------------------------------------------------------------+
const int    SESSION_DEAD_HOUR_START   = 0;     // Мёртвая зона начало
const int    SESSION_DEAD_HOUR_END     = 5;     // Мёртвая зона конец
const int    SESSION_FRIDAY_CLOSE_HOUR = 20;    // Закрытие в пятницу
const int    NEWS_MINUTES_BEFORE        = 30;
const int    NEWS_MINUTES_AFTER         = 30;

//+------------------------------------------------------------------+
//| ФИЛЬТР ВОЛАТИЛЬНОСТИ                                             |
//+------------------------------------------------------------------+
const double VOLATILITY_RATIO_MIN      = 0.6;
const double VOLATILITY_RATIO_MAX      = 2.2;
const int    VOLATILITY_AVG_PERIOD     = 50;

//+------------------------------------------------------------------+
//| СТРУКТУРНЫЕ УРОВНИ                                               |
//+------------------------------------------------------------------+
const int    STRUCTURE_LOOKBACK        = 100;   // Смотрим назад N свечей H4
const int    STRUCTURE_PEAK_OFFSET      = 2;    // Пик должен быть выше N свечей с каждой стороны
const double STRUCTURE_BUFFER_ATR      = 0.3;   // Буфер от уровня (ATR)
const double STRUCTURE_SL_BUFFER_ATR   = 0.5;   // Буфер для SL (ATR)

//+------------------------------------------------------------------+
//| ТОЧНОСТЬ ОТОБРАЖЕНИЯ                                             |
//+------------------------------------------------------------------+
const int    ACCURACY_EXCELLENT        = 75;
const int    ACCURACY_GOOD             = 65;
const int    ACCURACY_NORMAL           = 55;

#endif