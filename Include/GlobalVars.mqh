//+------------------------------------------------------------------+
//| GlobalVars.mqh                                                   |
//| ЕДИНСТВЕННЫЙ ИСТОЧНИК ИСТИНЫ: Все глобальные переменные          |
//| ВАЖНО: Этот файл подключается ТОЛЬКО в главном .mq5 файле!       |
//+------------------------------------------------------------------+
#ifndef GLOBAL_VARS_MQH
#define GLOBAL_VARS_MQH

#include <DataStructures.mqh>

// =========================================================================
// 1. ИНФОРМАЦИЯ О ПАРЕ И СЕССИИ
// =========================================================================
string currentSymbol = "";
string symbolType = "";
int symbolDigits = 0;
double symbolPoint = 0;
long symbolSpread = 0;
string currentSession = "";

// =========================================================================
// 2. ИСТОРИЯ И СТАТИСТИКА
// =========================================================================
SignalRecord history[HISTORY_SIZE];
int totalSignals = 0;
int winningSignals = 0;
int losingSignals = 0;
int canceledSignals = 0;
datetime statsStartDate = 0;

// =========================================================================
// 3. СОСТОЯНИЕ ФИЛЬТРОВ
// =========================================================================
bool filterNews = true;
bool filterVolatility = true;
bool filterSession = true;
bool filterCandle = true;
bool filterRSI = true;
bool filterStructure = true;

// =========================================================================
// 4. УРОВНИ И АКТИВНЫЙ СИГНАЛ (ОБЩИЕ)
// =========================================================================
double recEntry = 0, recSL = 0, recTP = 0;
string recOrderType = "";
string activeMode = "";
double nearestResistance = 0, nearestSupport = 0;

// =========================================================================
// 5. УРОВНИ ПО ТАЙМФРЕЙМАМ
// =========================================================================
double recEntryH1 = 0, recSLH1 = 0, recTPH1 = 0;
string recOrderTypeH1 = "";
double recEntryH4 = 0, recSLH4 = 0, recTPH4 = 0;
string recOrderTypeH4 = "";
double recEntryD1 = 0, recSLD1 = 0, recTPD1 = 0;
string recOrderTypeD1 = "";

// =========================================================================
// 6. ВНУТРЕННЕЕ СОСТОЯНИЕ И ФЛАГИ
// =========================================================================
datetime lastBarTimeH1 = 0, lastBarTimeH4 = 0, lastBarTimeD1 = 0;
bool signalFixedH1 = false, signalFixedH4 = false, signalFixedD1 = false;
string lastSignalH1 = "", lastSignalH4 = "", lastSignalD1 = "";
double lastSignalStrengthH1 = 0, lastSignalStrengthH4 = 0, lastSignalStrengthD1 = 0;
datetime lastSignalCheckTime = 0;
datetime signalExpirationTime = 0;
bool signalChecked = false;
bool signalWasExecuted = false;
double lastEntryPrice = 0;
string lastDirection = "";
bool isBacktestRunning = false;

#endif