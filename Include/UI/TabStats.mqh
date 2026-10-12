//+------------------------------------------------------------------+
//| TabStats.mqh                                                     |
//+------------------------------------------------------------------+
#ifndef UI_TAB_STATS_MQH
#define UI_TAB_STATS_MQH

void UI_DrawTabStats(int &y, int lineHeight)
{
   string prefix = PANEL_NAME + "_C3_";
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "📈 СТАТИСТИКА:", clrYellow, 11, true); y += lineHeight + 5;
   
   UI_CreateLabel(prefix + "S1", PANEL_X + 20, y, "📊 Всего: " + (string)totalSignals, clrLightGray, 10, false); y += lineHeight;
   UI_CreateLabel(prefix + "S2", PANEL_X + 20, y, "✅ Верных: " + (string)winningSignals, clrLime, 10, false); y += lineHeight;
   UI_CreateLabel(prefix + "S3", PANEL_X + 20, y, "❌ Ошибок: " + (string)losingSignals, clrRed, 10, false); y += lineHeight;
   UI_CreateLabel(prefix + "S4", PANEL_X + 20, y, "⏸ Аннулировано: " + (string)canceledSignals, clrGray, 10, false); y += lineHeight + 5;
   
   int decided = winningSignals + losingSignals;
   double acc = (decided == 0) ? 0 : (winningSignals * 100.0 / decided);
   color accCol = (acc >= 70) ? clrLime : ((acc >= 55) ? clrOrange : ((totalSignals > 0) ? clrRed : clrGray));
   UI_CreateLabel(prefix + "Acc", PANEL_X + 20, y, "🎯 ТОЧНОСТЬ: " + DoubleToString(acc, 1) + "%", accCol, 14, true); y += lineHeight + 10;
   
   // Кнопка RESET
   string rBtn = prefix + "Reset";
   if(ObjectFind(0, rBtn) < 0) {
      ObjectCreate(0, rBtn, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, rBtn, OBJPROP_XDISTANCE, PANEL_X + PANEL_WIDTH - 110);
      ObjectSetInteger(0, rBtn, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, rBtn, OBJPROP_XSIZE, 100); ObjectSetInteger(0, rBtn, OBJPROP_YSIZE, 26);
      ObjectSetString(0, rBtn, OBJPROP_TEXT, "🗑️ RESET");
      ObjectSetInteger(0, rBtn, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, rBtn, OBJPROP_BGCOLOR, C'140,40,40');
      ObjectSetInteger(0, rBtn, OBJPROP_FONTSIZE, 10); ObjectSetString(0, rBtn, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, rBtn, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, rBtn, OBJPROP_HIDDEN, true); ObjectSetInteger(0, rBtn, OBJPROP_BACK, false);
   }
   y += 35;
   
   // Кнопка БЭКТЕСТ
   string bBtn = prefix + "Backtest";
   if(ObjectFind(0, bBtn) < 0) {
      ObjectCreate(0, bBtn, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, bBtn, OBJPROP_XDISTANCE, PANEL_X + 20); ObjectSetInteger(0, bBtn, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, bBtn, OBJPROP_XSIZE, PANEL_WIDTH - 40); ObjectSetInteger(0, bBtn, OBJPROP_YSIZE, 30);
      ObjectSetString(0, bBtn, OBJPROP_TEXT, isBacktestRunning ? "⏳ ТЕСТ..." : "🧪 БЭКТЕСТ");
      ObjectSetInteger(0, bBtn, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, bBtn, OBJPROP_BGCOLOR, isBacktestRunning ? C'100,100,50' : C'40,100,40');
      ObjectSetInteger(0, bBtn, OBJPROP_FONTSIZE, 10); ObjectSetString(0, bBtn, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, bBtn, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, bBtn, OBJPROP_HIDDEN, true); ObjectSetInteger(0, bBtn, OBJPROP_BACK, false);
   }
}
#endif