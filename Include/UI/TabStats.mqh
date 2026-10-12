//+------------------------------------------------------------------+
//| TabStats.mqh                                                     |
//| СЛОЙ 6: UI - Вкладка СТАТИСТИКА (профессиональный вид)           |
//+------------------------------------------------------------------+
#ifndef UI_TAB_STATS_MQH
#define UI_TAB_STATS_MQH

//+------------------------------------------------------------------+
//| Главная функция отрисовки вкладки СТАТИСТИКА                     |
//+------------------------------------------------------------------+
void UI_DrawTabStats(int &y, int lineHeight)
{
   string prefix = PANEL_NAME + "_C3_";
   
   //=== ЗАГОЛОВОК ===
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "📈 СТАТИСТИКА ТОЧНОСТИ", clrYellow, 11, true);
   y += lineHeight + 5;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep1", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== ОБЩАЯ СТАТИСТИКА ===
   UI_CreateLabel(prefix + "GenTitle", PANEL_X + 15, y, "📊 ОБЩАЯ СТАТИСТИКА", clrWheat, 10, true);
   y += lineHeight + 2;
   
   UI_CreateLabel(prefix + "S1_Label", PANEL_X + 25, y, "Всего сигналов:", clrLightGray, 9, false);
   UI_CreateLabel(prefix + "S1_Value", PANEL_X + 280, y, (string)totalSignals, clrWhite, 10, true);
   y += lineHeight;
   
   double winPercent = (totalSignals > 0) ? (winningSignals * 100.0 / totalSignals) : 0;
   UI_CreateLabel(prefix + "S2_Label", PANEL_X + 25, y, "✅ Верных:", clrLime, 9, false);
   string winStr = (string)winningSignals + "  (" + DoubleToString(winPercent, 1) + "%)";
   UI_CreateLabel(prefix + "S2_Value", PANEL_X + 280, y, winStr, clrLime, 10, true);
   y += lineHeight;
   
   double lossPercent = (totalSignals > 0) ? (losingSignals * 100.0 / totalSignals) : 0;
   UI_CreateLabel(prefix + "S3_Label", PANEL_X + 25, y, "❌ Ошибок:", clrRed, 9, false);
   string lossStr = (string)losingSignals + "  (" + DoubleToString(lossPercent, 1) + "%)";
   UI_CreateLabel(prefix + "S3_Value", PANEL_X + 280, y, lossStr, clrRed, 10, true);
   y += lineHeight;
   
   UI_CreateLabel(prefix + "S4_Label", PANEL_X + 25, y, "⏸ Аннулировано:", clrGray, 9, false);
   UI_CreateLabel(prefix + "S4_Value", PANEL_X + 280, y, (string)canceledSignals, clrGray, 10, true);
   y += lineHeight + 5;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep2", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== ТОЧНОСТЬ ===
   int decided = winningSignals + losingSignals;
   double accuracy = (decided > 0) ? (winningSignals * 100.0 / decided) : 0;
   
   string accTitle = "🎯 ТОЧНОСТЬ: " + DoubleToString(accuracy, 1) + "%";
   color accColor = (accuracy >= 70) ? clrLime : ((accuracy >= 55) ? clrYellow : ((totalSignals > 0) ? clrRed : clrGray));
   UI_CreateLabel(prefix + "AccTitle", PANEL_X + 15, y, accTitle, accColor, 12, true);
   y += lineHeight + 2;
   
   // Оценка
   string gradeStr = "";
   color gradeColor = clrGray;
   if(totalSignals == 0) { gradeStr = "⏳ Нет данных"; gradeColor = clrGray; }
   else if(accuracy >= 75) { gradeStr = "🏆 ОТЛИЧНО"; gradeColor = clrLime; }
   else if(accuracy >= 65) { gradeStr = "✅ ХОРОШО"; gradeColor = clrGreen; }
   else if(accuracy >= 55) { gradeStr = "⚠️ НОРМАЛЬНО"; gradeColor = clrOrange; }
   else { gradeStr = "❗ ТРЕБУЕТ НАСТРОЙКИ"; gradeColor = clrRed; }
   UI_CreateLabel(prefix + "Grade", PANEL_X + 25, y, gradeStr, gradeColor, 10, true);
   y += lineHeight + 3;
   
   // Визуальный прогресс-бар
   int barWidth = PANEL_WIDTH - 40;
   int filledWidth = (int)(barWidth * accuracy / 100.0);
   
   // Фон бара
   string barBg = prefix + "BarBg";
   if(ObjectFind(0, barBg) < 0) {
      ObjectCreate(0, barBg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, barBg, OBJPROP_XDISTANCE, PANEL_X + 20);
      ObjectSetInteger(0, barBg, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, barBg, OBJPROP_XSIZE, barWidth);
      ObjectSetInteger(0, barBg, OBJPROP_YSIZE, 15);
      ObjectSetInteger(0, barBg, OBJPROP_BGCOLOR, C'40, 40, 50');
      ObjectSetInteger(0, barBg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, barBg, OBJPROP_COLOR, C'60, 60, 70');
      ObjectSetInteger(0, barBg, OBJPROP_BACK, false);
      ObjectSetInteger(0, barBg, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, barBg, OBJPROP_HIDDEN, true);
   }
   
   // Заполненная часть
   string barFill = prefix + "BarFill";
   if(ObjectFind(0, barFill) < 0) {
      ObjectCreate(0, barFill, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, barFill, OBJPROP_XDISTANCE, PANEL_X + 20);
      ObjectSetInteger(0, barFill, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, barFill, OBJPROP_YSIZE, 15);
      ObjectSetInteger(0, barFill, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, barFill, OBJPROP_BACK, false);
      ObjectSetInteger(0, barFill, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, barFill, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, barFill, OBJPROP_XSIZE, filledWidth);
   color barColor = (accuracy >= 70) ? C'0, 200, 0' : ((accuracy >= 55) ? C'200, 200, 0' : C'200, 0, 0');
   ObjectSetInteger(0, barFill, OBJPROP_BGCOLOR, barColor);
   ObjectSetInteger(0, barFill, OBJPROP_COLOR, barColor);
   
   y += 20;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep3", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== ПО ТАЙМФРЕМАМ ===
   UI_CreateLabel(prefix + "TF_Title", PANEL_X + 15, y, "📊 ПО ТАЙМФРЕМАМ", clrWheat, 10, true);
   y += lineHeight + 2;
   
   // H1
   int h1Total = 0, h1Wins = 0;
   for(int i = 0; i < ArraySize(history); i++) {
      if(history[i].mode == "H1") {
         h1Total++;
         if(StringFind(history[i].status, "WIN") >= 0) h1Wins++;
      }
   }
   int h1Losses = h1Total - h1Wins;
   double h1Acc = (h1Total > 0) ? (h1Wins * 100.0 / h1Total) : 0;
   string h1Str = (string)h1Total + " сигналов  |  " + (string)h1Wins + " ✅  |  " + (string)h1Losses + " ❌  |  " + DoubleToString(h1Acc, 1) + "%";
   UI_CreateLabel(prefix + "TF_H1", PANEL_X + 25, y, "🟢 H1:  " + h1Str, clrLime, 9, false);
   y += lineHeight;
   
   // H4
   int h4Total = 0, h4Wins = 0;
   for(int i = 0; i < ArraySize(history); i++) {
      if(history[i].mode == "H4") {
         h4Total++;
         if(StringFind(history[i].status, "WIN") >= 0) h4Wins++;
      }
   }
   int h4Losses = h4Total - h4Wins;
   double h4Acc = (h4Total > 0) ? (h4Wins * 100.0 / h4Total) : 0;
   string h4Str = (string)h4Total + " сигналов  |  " + (string)h4Wins + " ✅  |  " + (string)h4Losses + " ❌  |  " + DoubleToString(h4Acc, 1) + "%";
   UI_CreateLabel(prefix + "TF_H4", PANEL_X + 25, y, "🟡 H4:  " + h4Str, clrYellow, 9, false);
   y += lineHeight;
   
   // D1
   int d1Total = 0, d1Wins = 0;
   for(int i = 0; i < ArraySize(history); i++) {
      if(history[i].mode == "D1") {
         d1Total++;
         if(StringFind(history[i].status, "WIN") >= 0) d1Wins++;
      }
   }
   int d1Losses = d1Total - d1Wins;
   double d1Acc = (d1Total > 0) ? (d1Wins * 100.0 / d1Total) : 0;
   string d1Str = (string)d1Total + " сигналов  |  " + (string)d1Wins + " ✅  |  " + (string)d1Losses + " ❌  |  " + DoubleToString(d1Acc, 1) + "%";
   UI_CreateLabel(prefix + "TF_D1", PANEL_X + 25, y, "🔴 D1:  " + d1Str, clrOrangeRed, 9, false);
   y += lineHeight + 10;
   
   //=== КНОПКИ ===
   // Кнопка RESET
   string rBtn = prefix + "Reset";
   if(ObjectFind(0, rBtn) < 0) {
      ObjectCreate(0, rBtn, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, rBtn, OBJPROP_XDISTANCE, PANEL_X + 20);
      ObjectSetInteger(0, rBtn, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, rBtn, OBJPROP_XSIZE, 100);
      ObjectSetInteger(0, rBtn, OBJPROP_YSIZE, 28);
      ObjectSetString(0, rBtn, OBJPROP_TEXT, "🗑️ RESET");
      ObjectSetInteger(0, rBtn, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, rBtn, OBJPROP_BGCOLOR, C'140, 40, 40');
      ObjectSetInteger(0, rBtn, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, rBtn, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, rBtn, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, rBtn, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, rBtn, OBJPROP_BACK, false);
   }
   
   // Кнопка БЭКТЕСТ
   string bBtn = prefix + "Backtest";
   if(ObjectFind(0, bBtn) < 0) {
      ObjectCreate(0, bBtn, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, bBtn, OBJPROP_XDISTANCE, PANEL_X + PANEL_WIDTH - 180);
      ObjectSetInteger(0, bBtn, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, bBtn, OBJPROP_XSIZE, 160);
      ObjectSetInteger(0, bBtn, OBJPROP_YSIZE, 28);
      ObjectSetString(0, bBtn, OBJPROP_TEXT, isBacktestRunning ? "⏳ ТЕСТ..." : "🧪 БЭКТЕСТ");
      ObjectSetInteger(0, bBtn, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, bBtn, OBJPROP_BGCOLOR, isBacktestRunning ? C'100, 100, 50' : C'40, 100, 40');
      ObjectSetInteger(0, bBtn, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, bBtn, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, bBtn, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bBtn, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, bBtn, OBJPROP_BACK, false);
   }
   
   ChartRedraw();
}

#endif