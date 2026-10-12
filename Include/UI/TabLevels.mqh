//+------------------------------------------------------------------+
//| TabLevels.mqh                                                    |
//| СЛОЙ 6: UI - Вкладка УРОВНИ (профессиональный вид)               |
//+------------------------------------------------------------------+
#ifndef UI_TAB_LEVELS_MQH
#define UI_TAB_LEVELS_MQH

//+------------------------------------------------------------------+
//| Главная функция отрисовки вкладки УРОВНИ                         |
//+------------------------------------------------------------------+
void UI_DrawTabLevels(int &y, int lineHeight, int digits)
{
   string prefix = PANEL_NAME + "_C2_";
   
   //=== ЗАГОЛОВОК ===
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "📊 РЕКОМЕНДУЕМЫЕ УРОВНИ", clrYellow, 11, true);
   y += lineHeight + 5;
   
   //=== ПРОВЕРКА НАЛИЧИЯ СИГНАЛА ===
   if(recEntry <= 0)
   {
      UI_CreateLabel(prefix + "NoSignal", PANEL_X + 20, y, "⏸ Нет активного сигнала", clrGray, 10, false);
      y += lineHeight;
      UI_CreateLabel(prefix + "Hint", PANEL_X + 20, y, "💡 Дождитесь подтверждения на вкладке АНАЛИЗ", clrWheat, 9, false);
      y += lineHeight;
      UI_CreateLabel(prefix + "Hint2", PANEL_X + 20, y, "   и фильтрации на вкладке ФИЛЬТРЫ", clrWheat, 9, false);
      return;
   }
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep1", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== АКТИВНЫЙ СИГНАЛ ===
   color activeColor = (activeMode == "H1") ? clrLime : ((activeMode == "H4") ? clrYellow : clrOrangeRed);
   string activePrefix = (activeMode == "H1") ? "🟢" : ((activeMode == "H4") ? "🟡" : "🔴");
   UI_CreateLabel(prefix + "ActiveSignal", PANEL_X + 15, y, "🎯 АКТИВНЫЙ СИГНАЛ: " + activeMode + " " + recOrderType, activeColor, 11, true);
   y += lineHeight;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep2", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight + 3;
   
   //=== ЦЕНЫ ВХОДА/SL/TP ===
   UI_CreateLabel(prefix + "EntryLabel", PANEL_X + 20, y, "💰 ВХОД:", clrWhite, 10, true);
   UI_CreateLabel(prefix + "EntryValue", PANEL_X + 120, y, DoubleToString(recEntry, digits), activeColor, 10, true);
   y += lineHeight;
   
   // Stop Loss
   double slDistance = MathAbs(recEntry - recSL);
   string slDistanceStr = DoubleToString(slDistance, digits) + " pts";
   UI_CreateLabel(prefix + "SLLabel", PANEL_X + 20, y, "🛑 STOP LOSS:", SLColor, 10, true);
   UI_CreateLabel(prefix + "SLValue", PANEL_X + 120, y, DoubleToString(recSL, digits), SLColor, 10, true);
   UI_CreateLabel(prefix + "SLDist", PANEL_X + 280, y, "(" + slDistanceStr + ")", clrLightGray, 9, false);
   y += lineHeight;
   
   // Take Profit
   double tpDistance = MathAbs(recTP - recEntry);
   string tpDistanceStr = DoubleToString(tpDistance, digits) + " pts";
   UI_CreateLabel(prefix + "TPLabel", PANEL_X + 20, y, "🎯 TAKE PROFIT:", TPColor, 10, true);
   UI_CreateLabel(prefix + "TPValue", PANEL_X + 120, y, DoubleToString(recTP, digits), TPColor, 10, true);
   UI_CreateLabel(prefix + "TPDist", PANEL_X + 280, y, "(" + tpDistanceStr + ")", clrLightGray, 9, false);
   y += lineHeight + 5;
   
   //=== RISK/REWARD ===
   double rrRatio = (slDistance > 0) ? tpDistance / slDistance : 0;
   string rrText = "💰 Risk/Reward: 1:" + DoubleToString(rrRatio, 2);
   color rrColor = (rrRatio >= 2.0) ? clrLime : ((rrRatio >= 1.5) ? clrYellow : ((rrRatio >= 1.0) ? clrOrange : clrRed));
   string rrGrade = (rrRatio >= 2.0) ? "✅ ОТЛИЧНО" : ((rrRatio >= 1.5) ? "✅ ХОРОШО" : ((rrRatio >= 1.0) ? "⚠️ НОРМ" : "❌ ПЛОХО"));
   UI_CreateLabel(prefix + "RR", PANEL_X + 20, y, rrText + " " + rrGrade, rrColor, 10, true);
   y += lineHeight;
   
   //=== ВРЕМЯ ЖИЗНИ СИГНАЛА ===
   int lifetimeMinutes = CalculateSignalLifetime(activeMode, 
      (activeMode == "H1") ? g_resultH1.weightedSum : ((activeMode == "H4") ? g_resultH4.weightedSum : g_resultD1.weightedSum),
      (activeMode == "H1") ? g_resultH1.candlesForecast : ((activeMode == "H4") ? g_resultH4.candlesForecast : g_resultD1.candlesForecast));
   
   string lifetimeStr = "";
   if(lifetimeMinutes >= 60)
   {
      int hours = lifetimeMinutes / 60;
      int mins = lifetimeMinutes % 60;
      lifetimeStr = (string)hours + " ч " + (string)mins + " мин";
   }
   else
   {
      lifetimeStr = (string)lifetimeMinutes + " мин";
   }
   UI_CreateLabel(prefix + "Lifetime", PANEL_X + 20, y, "⏱️ Время жизни: " + lifetimeStr, clrLightGray, 9, false);
   y += lineHeight + 5;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep3", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== СТРУКТУРНЫЕ УРОВНИ ===
   UI_CreateLabel(prefix + "StructTitle", PANEL_X + 15, y, "🧱 СТРУКТУРНЫЕ УРОВНИ (H4)", clrYellow, 10, true);
   y += lineHeight + 3;
   
   // Сопротивление
   if(nearestResistance > 0)
   {
      double resDistance = nearestResistance - g_resultH1.currentPrice;
      string resDistStr = DoubleToString(resDistance, digits) + " pts ↑";
      double resATR = (g_resultH1.atrValue > 0) ? resDistance / g_resultH1.atrValue : 0;
      string resATRStr = DoubleToString(resATR, 1) + "× ATR";
      color resColor = (resATR >= 2.0) ? clrLime : ((resATR >= 1.0) ? clrYellow : clrOrange);
      
      UI_CreateLabel(prefix + "ResLabel", PANEL_X + 20, y, "🔸 Сопротивление:", clrOrange, 9, true);
      UI_CreateLabel(prefix + "ResValue", PANEL_X + 150, y, DoubleToString(nearestResistance, digits), clrOrange, 9, true);
      UI_CreateLabel(prefix + "ResDist", PANEL_X + 280, y, "(" + resDistStr + ")", clrLightGray, 8, false);
      y += lineHeight;
      UI_CreateLabel(prefix + "ResATR", PANEL_X + 30, y, "Расстояние: " + resATRStr, resColor, 8, false);
      y += lineHeight;
   }
   else
   {
      UI_CreateLabel(prefix + "ResNone", PANEL_X + 20, y, "🔸 Сопротивление: не найдено", clrGray, 9, false);
      y += lineHeight;
   }
   
   // Поддержка
   if(nearestSupport > 0)
   {
      double supDistance = g_resultH1.currentPrice - nearestSupport;
      string supDistStr = DoubleToString(supDistance, digits) + " pts ↓";
      double supATR = (g_resultH1.atrValue > 0) ? supDistance / g_resultH1.atrValue : 0;
      string supATRStr = DoubleToString(supATR, 1) + "× ATR";
      color supColor = (supATR >= 2.0) ? clrLime : ((supATR >= 1.0) ? clrYellow : clrOrange);
      
      UI_CreateLabel(prefix + "SupLabel", PANEL_X + 20, y, "🔹 Поддержка:", clrDeepSkyBlue, 9, true);
      UI_CreateLabel(prefix + "SupValue", PANEL_X + 150, y, DoubleToString(nearestSupport, digits), clrDeepSkyBlue, 9, true);
      UI_CreateLabel(prefix + "SupDist", PANEL_X + 280, y, "(" + supDistStr + ")", clrLightGray, 8, false);
      y += lineHeight;
      UI_CreateLabel(prefix + "SupATR", PANEL_X + 30, y, "Расстояние: " + supATRStr, supColor, 8, false);
      y += lineHeight;
   }
   else
   {
      UI_CreateLabel(prefix + "SupNone", PANEL_X + 20, y, "🔹 Поддержка: не найдена", clrGray, 9, false);
      y += lineHeight;
   }
   
   ChartRedraw();
}

#endif