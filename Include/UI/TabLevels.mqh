//+------------------------------------------------------------------+
//| TabLevels.mqh                                                    |
//+------------------------------------------------------------------+
#ifndef UI_TAB_LEVELS_MQH
#define UI_TAB_LEVELS_MQH

void UI_DrawTabLevels(int &y, int lineHeight, int digits)
{
   string prefix = PANEL_NAME + "_C2_";
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "📊 РЕКОМЕНДУЕМЫЕ УРОВНИ:", clrYellow, 11, true); y += lineHeight + 5;
   
   if(recEntry > 0) {
      color ac = (activeMode=="H1")?clrLime:((activeMode=="H4")?clrYellow:clrOrangeRed);
      UI_CreateLabel(prefix + "Entry", PANEL_X + 20, y, "🎯 ВХОД: " + DoubleToString(recEntry, digits), ac, 10, true); y += lineHeight;
      UI_CreateLabel(prefix + "SL", PANEL_X + 20, y, "🛑 STOP LOSS: " + DoubleToString(recSL, digits), SLColor, 10, true); y += lineHeight;
      UI_CreateLabel(prefix + "TP", PANEL_X + 20, y, "🎯 TAKE PROFIT: " + DoubleToString(recTP, digits), TPColor, 10, true); y += lineHeight + 5;
      
      UI_CreateLabel(prefix + "Res", PANEL_X + 20, y, (nearestResistance>0) ? "🔸 Сопротивление: " + DoubleToString(nearestResistance, digits) : "🔸 Сопротивление: нет", (nearestResistance>0)?clrOrange:clrGray, 9, false); y += lineHeight;
      UI_CreateLabel(prefix + "Sup", PANEL_X + 20, y, (nearestSupport>0) ? "🔹 Поддержка: " + DoubleToString(nearestSupport, digits) : "🔹 Поддержка: нет", (nearestSupport>0)?clrDeepSkyBlue:clrGray, 9, false);
   } else {
      UI_CreateLabel(prefix + "No", PANEL_X + 20, y, "⏸ Уровни появятся при сигнале", clrGray, 10, false);
   }
}
#endif