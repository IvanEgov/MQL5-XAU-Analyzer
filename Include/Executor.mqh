//+------------------------------------------------------------------+
//| Executor.mqh                                                     |
//| СЛОЙ 7: ИСПОЛНИТЕЛЬ — реальная торговля ордерами                |
//+------------------------------------------------------------------+
#ifndef EXECUTOR_MQH
#define EXECUTOR_MQH

#include <Config.mqh>
#include <DataStructures.mqh>
#include <Trade\Trade.mqh>

//--- Глобальный экземпляр торговли
CTrade g_trade;

//--- Состояние исполнителя
ulong  g_orderTicket = 0;        // Тикет выставленного ордера
bool   g_orderPlaced = false;     // Ордер выставлен
string g_orderComment = "";       // Комментарий ордера
datetime g_orderPlacedTime = 0;   // Время выставления

//+------------------------------------------------------------------+
//| Инициализация исполнителя                                        |
//+------------------------------------------------------------------+
bool Executor_Init(int magicNumber, string tradeComment)
{
   g_trade.SetExpertMagicNumber(magicNumber);
   g_trade.SetDeviationInPoints(20);
   g_trade.SetTypeFillingBySymbol(_Symbol);   // Важно: авто-подтип исполнения брокера
   g_orderTicket = 0;
   g_orderPlaced = false;
   g_orderComment = tradeComment;
   g_orderPlacedTime = 0;
   
   Print("✅ Executor инициализирован | Magic: ", magicNumber, 
         " | Торговля: ", (EnableTrading ? "🟢 ВКЛ" : "🔴 ВЫКЛ (только анализ)"));
   return true;
}

//+------------------------------------------------------------------+
//| Расчёт лота по риску в % от депозита                             |
//+------------------------------------------------------------------+
double Executor_CalculateLot(double entry, double sl)
{
   double lot = FixedLot;
   
   if(UseRiskPercent)
   {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskMoney = balance * (RiskPercent / 100.0);
      
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      
      if(tickValue <= 0 || tickSize <= 0) return FixedLot;
      
      double slDistance = MathAbs(entry - sl);
      if(slDistance <= 0) return FixedLot;
      
      double slTicks = slDistance / tickSize;
      double lossPerLot = slTicks * tickValue;
      
      if(lossPerLot <= 0) return FixedLot;
      
      lot = riskMoney / lossPerLot;
   }
   
   // Приведение к допустимым границам и шагу брокера
   double volMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(volStep > 0)
      lot = MathFloor(lot / volStep) * volStep;   // Округление ВНИЗ (безопаснее)
   
   lot = MathMax(volMin, MathMin(volMax, lot));
   
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Валидация ордера перед отправкой                                 |
//+------------------------------------------------------------------+
bool Executor_Validate(string orderType, double entry, double sl, double tp, 
                       double lot, string &errorMsg)
{
   errorMsg = "";
   
   // 1. Базовые проверки цен
   if(entry <= 0 || sl <= 0 || tp <= 0)
   { errorMsg = "Некорректные цены"; return false; }
   
   // 2. Лот
   double volMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(lot < volMin)
   { errorMsg = "Лот меньше минимального (" + DoubleToString(volMin, 2) + ")"; return false; }
   
   // 3. Спред
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(MaxSpreadPoints > 0 && spread > MaxSpreadPoints)
   { errorMsg = "Спред слишком большой: " + (string)spread + " > " + (string)MaxSpreadPoints; return false; }
   
   // 4. Минимальное расстояние до отложенного ордера (Stops Level)
   double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   if(orderType == "BUY LIMIT"  && entry > bid - stopLevel)
   { errorMsg = "BUY LIMIT слишком близко к цене (нужно ниже " + DoubleToString(bid - stopLevel, _Digits) + ")"; return false; }
   if(orderType == "BUY STOP"   && entry < ask + stopLevel)
   { errorMsg = "BUY STOP слишком близко к цене (нужно выше " + DoubleToString(ask + stopLevel, _Digits) + ")"; return false; }
   if(orderType == "SELL LIMIT" && entry < ask + stopLevel)
   { errorMsg = "SELL LIMIT слишком близко к цене (нужно выше " + DoubleToString(ask + stopLevel, _Digits) + ")"; return false; }
   if(orderType == "SELL STOP"  && entry > bid - stopLevel)
   { errorMsg = "SELL STOP слишком близко к цене (нужно ниже " + DoubleToString(bid - stopLevel, _Digits) + ")"; return false; }
   
   // 5. Направление SL/TP
   bool isBuy = (StringFind(orderType, "BUY") >= 0);
   if(isBuy  && (sl >= entry || tp <= entry)) { errorMsg = "SL/TP не соответствуют BUY"; return false; }
   if(!isBuy && (sl <= entry || tp >= entry)) { errorMsg = "SL/TP не соответствуют SELL"; return false; }
   
   // 6. Свободная маржа
   double marginRequired = 0;
   if(!OrderCalcMargin(isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, entry, marginRequired))
   { errorMsg = "Не удалось рассчитать маржу"; return false; }
   
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(marginRequired > freeMargin)
   { errorMsg = "Недостаточно маржи: нужно " + DoubleToString(marginRequired, 2) + ", есть " + DoubleToString(freeMargin, 2); return false; }
   
   // 7. Разрешена ли торговля у брокера
   long tradeMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED || tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY)
   { errorMsg = "Торговля по символу запрещена брокером"; return false; }
   
   return true;
}

//+------------------------------------------------------------------+
//| Количество активных позиций/ордеров по нашему магик-номеру       |
//+------------------------------------------------------------------+
int Executor_CountOpen()
{
   int count = 0;
   int total = PositionsTotal();
   
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      count++;
   }
   
   total = OrdersTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if((int)OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;
      count++;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| ВЫСТАВЛЕНИЕ ОТЛОЖЕННОГО ОРДЕРА                                   |
//+------------------------------------------------------------------+
bool Executor_OpenPosition(string orderType, double entry, double sl, double tp, 
                           string signalInfo, string &resultMsg)
{
   resultMsg = "";
   
   // Защита: торговля выключена?
   if(!EnableTrading)
   {
      resultMsg = "⚪ Торговля ВЫКЛЮЧЕНА (EnableTrading=false) — сигнал только показан";
      Print(resultMsg);
      return false;
   }
   
   // Защита: уже есть ордер?
   if(g_orderPlaced && g_orderTicket > 0)
   {
      resultMsg = "⚠️ Ордер уже выставлен (ticket: " + (string)g_orderTicket + ")";
      Print(resultMsg);
      return false;
   }
   
   // Защита: лимит открытых позиций
   int openCount = Executor_CountOpen();
   if(openCount >= MaxOpenPositions)
   {
      resultMsg = "⚠️ Достигнут лимит позиций: " + (string)openCount + "/" + (string)MaxOpenPositions;
      Print(resultMsg);
      return false;
   }
   
   // Расчёт лота и валидация
   double lot = Executor_CalculateLot(entry, sl);
   string errorMsg = "";
   
   if(!Executor_Validate(orderType, entry, sl, tp, lot, errorMsg))
   {
      resultMsg = "❌ Ордер ОТКЛОНЁН: " + errorMsg;
      Print(resultMsg);
      return false;
   }
   
   // Нормализация цен
   entry = NormalizeDouble(entry, _Digits);
   sl    = NormalizeDouble(sl, _Digits);
   tp    = NormalizeDouble(tp, _Digits);
   
   string comment = g_orderComment + " " + signalInfo;
   bool success = false;
   
   // Отправка ордера по типу
   if(orderType == "BUY LIMIT")
      success = g_trade.BuyLimit(lot, entry, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
   else if(orderType == "BUY STOP")
      success = g_trade.BuyStop(lot, entry, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
   else if(orderType == "SELL LIMIT")
      success = g_trade.SellLimit(lot, entry, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
   else if(orderType == "SELL STOP")
      success = g_trade.SellStop(lot, entry, _Symbol, sl, tp, ORDER_TIME_GTC, 0, comment);
   else
   {
      resultMsg = "❌ Неизвестный тип ордера: " + orderType;
      Print(resultMsg);
      return false;
   }
   
   if(success)
   {
      g_orderTicket = g_trade.ResultOrder();
      g_orderPlaced = true;
      g_orderPlacedTime = TimeCurrent();
      
      resultMsg = "✅ ОРДЕР ВЫСТАВЛЕН | " + orderType + " " + DoubleToString(lot, 2) + " лота" +
                  " @ " + DoubleToString(entry, _Digits) +
                  " | SL: " + DoubleToString(sl, _Digits) +
                  " | TP: " + DoubleToString(tp, _Digits) +
                  " | Ticket: " + (string)g_orderTicket;
      Print(resultMsg);
      return true;
   }
   
   uint retcode = g_trade.ResultRetcode();
   resultMsg = "❌ ОШИБКА ОТПРАВКИ | Code: " + (string)retcode + " | " + g_trade.ResultRetcodeDescription();
   Print(resultMsg);
   return false;
}

//+------------------------------------------------------------------+
//| Проверка: исполнен ли наш ордер (превратился в позицию)          |
//+------------------------------------------------------------------+
bool Executor_IsOrderExecuted()
{
   if(!g_orderPlaced || g_orderTicket == 0) return false;
   
   // Ищем позицию с нашим тикетом (или по магик-номеру)
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      return true;   // Позиция есть = ордер исполнен
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Проверка: ордер ещё жив (не удалён/не исполнен)                  |
//+------------------------------------------------------------------+
bool Executor_IsOrderActive()
{
   if(!g_orderPlaced || g_orderTicket == 0) return false;
   
   if(OrderSelect(g_orderTicket)) return true;
   
   // Ордера нет — возможно исполнился или удалён
   return false;
}

//+------------------------------------------------------------------+
//| СБРОС состояния исполнителя (после закрытия сделки)              |
//+------------------------------------------------------------------+
void Executor_Reset()
{
   g_orderTicket = 0;
   g_orderPlaced = false;
   g_orderPlacedTime = 0;
}

//+------------------------------------------------------------------+
//| ЗАКРЫТИЕ ВСЕХ ПОЗИЦИЙ И УДАЛЕНИЕ ОРДЕРОВ (для RESET)             |
//+------------------------------------------------------------------+
void Executor_CloseAll()
{
   if(!EnableTrading) { Print("⚪ Торговля выключена — закрывать нечего"); return; }
   
   // Удаляем отложенные ордера
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if((int)OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;
      g_trade.OrderDelete(ticket);
   }
   
   // Закрываем позиции
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      g_trade.PositionClose(ticket);
   }
   
   Executor_Reset();
   Print("🗑️ Все позиции и ордера закрыты/удалены");
}

#endif