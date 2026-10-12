//+------------------------------------------------------------------+
//|                                                SignalManager.mqh |
//|           СЛОЙ 4: МЕНЕДЖЕР СИГНАЛОВ (Единый источник истины)     |
//+------------------------------------------------------------------+
#ifndef SIGNAL_MANAGER_MQH
#define SIGNAL_MANAGER_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

//=== ЕДИНЫЙ ИСТОЧНИК ИСТИНЫ (Всё состояние советника в одном месте) ===

// 1. История сигналов
SignalRecord history[HISTORY_SIZE];

// 2. Контроль новых свечей (для генерации сигналов только на закрытии)
datetime lastBarTimeH1 = 0;
datetime lastBarTimeH4 = 0;
datetime lastBarTimeD1 = 0;
bool signalFixedH1 = false;
bool signalFixedH4 = false;
bool signalFixedD1 = false;

// 3. Состояние для каждого режима (защита от дублей)
string lastSignalH1 = "", lastSignalH4 = "", lastSignalD1 = "";
datetime lastSignalTimeH1 = 0, lastSignalTimeH4 = 0, lastSignalTimeD1 = 0;
double lastSignalStrengthH1 = 0;
double lastSignalStrengthH4 = 0;
double lastSignalStrengthD1 = 0;

// 4. Уровни для каждого режима
double recEntryH1 = 0, recSLH1 = 0, recTPH1 = 0;
double recEntryH4 = 0, recSLH4 = 0, recTPH4 = 0;
double recEntryD1 = 0, recSLD1 = 0, recTPD1 = 0;
string recOrderTypeH1 = "", recOrderTypeH4 = "", recOrderTypeD1 = "";

// 5. Активный режим (последний сработавший)
string activeMode = "";
double recEntry = 0, recSL = 0, recTP = 0;
string recOrderType = "";

// 6. Статусы фильтров
bool filterNews = false, filterVolatility = false, filterSession = false;
bool filterCandle = false, filterRSI = false, filterStructure = false;

// 7. Структурные уровни
double nearestResistance = 0, nearestSupport = 0;

// 8. Статистика и состояние исполнения
int totalSignals = 0, winningSignals = 0, losingSignals = 0;
int canceledSignals = 0;
double lastEntryPrice = 0;
string lastDirection = "";
datetime lastSignalCheckTime = 0;
bool signalChecked = false;
datetime signalExpirationTime = 0;
bool signalWasExecuted = false;

//=== ФУНКЦИИ МЕНЕДЖЕРА ===

//+------------------------------------------------------------------+
//| Инициализация менеджера при старте                               |
//+------------------------------------------------------------------+
void SignalManager_Init()
{
   for(int i = 0; i < HISTORY_SIZE; i++) 
      history[i].Init();
}

#endif