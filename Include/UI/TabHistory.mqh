//+------------------------------------------------------------------+
//| TabHistory.mqh                                                   |
//| СЛОЙ 6: UI - Вкладка ИСТОРИЯ (профессиональный вид)              |
//+------------------------------------------------------------------+
#ifndef UI_TAB_HISTORY_MQH
#define UI_TAB_HISTORY_MQH

//+------------------------------------------------------------------+
//| Главная функция отрисовки вкладки ИСТОРИЯ                        |
//+------------------------------------------------------------------+
void UI_DrawTabHistory(int &y, int lineHeight, int digits)
{
   string prefix = PANEL_NAME + "_C4_";
   
   //=== ЗАГОЛОВОК ===
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "📜 ИСТОРИЯ ПОСЛЕДНИХ СИГНАЛОВ", clrYellow, 11, true);
   y += lineHeight + 5;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep1", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== ПОСЛЕДНИЕ 5 СИГНАЛОВ ===
   UI_CreateLabel(prefix + "ListTitle", PANEL_X + 15, y, "📋 ПОСЛЕДНИЕ 5 СИГНАЛОВ", clrWheat, 10, true);
   y += lineHeight + 2;
   
   // Заголовки колонок
   UI_CreateLabel(prefix + "H_Time", PANEL_X + 15, y, "ВРЕМЯ", clrDodgerBlue, 8, true);
   UI_CreateLabel(prefix + "H_TF", PANEL_X + 140, y, "ТФ", clrDodgerBlue, 8, true);
   UI_CreateLabel(prefix + "H_Dir", PANEL_X + 180, y, "НАПР", clrDodgerBlue, 8, true);
   UI_CreateLabel(prefix + "H_Entry", PANEL_X + 230, y, "ВХОД", clrDodgerBlue, 8, true);
   UI_CreateLabel(prefix + "H_Status", PANEL_X + 340, y, "СТАТУС", clrDodgerBlue, 8, true);
   y += lineHeight;
   
   UI_CreateLabel(prefix + "Sep2", PANEL_X + 10, y, "───────────────────────────────────────────", clrGray, 8, false);
   y += lineHeight - 2;
   
   // Подсчёт реальных записей
   int realCount = 0;
   int histSize = ArraySize(history);
   for(int i = 0; i < histSize; i++) {
      if(history[i].time > 0) realCount++;
   }
   
   // Если история пуста
   if(realCount == 0) {
      UI_CreateLabel(prefix + "Empty", PANEL_X + 20, y, "⏸ История пуста — ждём первый сигнал", clrGray, 10, false);
      y += lineHeight;
      UI_CreateLabel(prefix + "EmptyHint", PANEL_X + 20, y, "💡 Сигналы появятся после подтверждения", clrWheat, 9, false);
      y += lineHeight + 10;
   } else {
      // Отрисовка записей (от новых к старым)
      int displayed = 0;
      for(int i = histSize - 1; i >= 0 && displayed < 5; i--) {
         if(history[i].time == 0) continue;
         
         // Время
         string timeStr = TimeToString(history[i].time, TIME_DATE|TIME_MINUTES);
         StringSetCharacter(timeStr, 4, '-');
         StringSetCharacter(timeStr, 7, '-');
         UI_CreateLabel(prefix + "T_" + (string)i, PANEL_X + 15, y, timeStr, clrLightGray, 8, false);
         
         // ТФ с цветом
         color modeColor = (history[i].mode == "H1") ? clrLime : ((history[i].mode == "H4") ? clrYellow : clrOrangeRed);
         string modeIcon = (history[i].mode == "H1") ? "🟢H1" : ((history[i].mode == "H4") ? "🟡H4" : "🔴D1");
         UI_CreateLabel(prefix + "M_" + (string)i, PANEL_X + 140, y, modeIcon, modeColor, 9, true);
         
         // Направление
         color dirColor = (history[i].direction == "BUY") ? clrLime : clrRed;
         string dirStr = (history[i].direction == "BUY") ? "▲ BUY" : "▼ SELL";
         UI_CreateLabel(prefix + "D_" + (string)i, PANEL_X + 180, y, dirStr, dirColor, 8, true);
         
         // Цена входа
         UI_CreateLabel(prefix + "E_" + (string)i, PANEL_X + 230, y, DoubleToString(history[i].entry, digits), clrWhite, 8, false);
         
         // Статус
         color statusColor = clrOrange;
         string statusStr = history[i].status;
         if(StringFind(history[i].status, "WIN") >= 0) { statusColor = clrLime; statusStr = "✅ WIN"; }
         else if(StringFind(history[i].status, "LOSS") >= 0) { statusColor = clrRed; statusStr = "❌ LOSS"; }
         else if(StringFind(history[i].status, "ОЖИДАНИЕ") >= 0) { statusColor = clrOrange; statusStr = "⏳ ОЖИДАНИЕ"; }
         UI_CreateLabel(prefix + "S_" + (string)i, PANEL_X + 340, y, statusStr, statusColor, 8, true);
         
         y += lineHeight - 2;
         displayed++;
      }
      y += 5;
   }
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep3", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== СВОДКА ПО ИСТОРИИ ===
   UI_CreateLabel(prefix + "SummaryTitle", PANEL_X + 15, y, "📊 СВОДКА ПО ИСТОРИИ", clrWheat, 10, true);
   y += lineHeight + 2;
   
   // Подсчёт по истории
   int histWins = 0, histLosses = 0, histWaiting = 0;
   for(int i = 0; i < histSize; i++) {
      if(history[i].time == 0) continue;
      if(StringFind(history[i].status, "WIN") >= 0) histWins++;
      else if(StringFind(history[i].status, "LOSS") >= 0) histLosses++;
      else if(StringFind(history[i].status, "ОЖИДАНИЕ") >= 0) histWaiting++;
   }
   
   string summaryStr = "Последних " + (string)realCount + " сигналов:  " + 
                       (string)histWins + " ✅ WIN  |  " + 
                       (string)histLosses + " ❌ LOSS  |  " + 
                       (string)histWaiting + " ⏳";
   UI_CreateLabel(prefix + "Summary", PANEL_X + 20, y, summaryStr, clrLightGray, 9, false);
   y += lineHeight;
   
   // Точность по истории (без ожидания)
   int histDecided = histWins + histLosses;
   double histAcc = (histDecided > 0) ? (histWins * 100.0 / histDecided) : 0;
   color histAccColor = (histAcc >= 70) ? clrLime : ((histAcc >= 55) ? clrYellow : ((histDecided > 0) ? clrRed : clrGray));
   string histAccStr = "Точность (без ожидания): " + DoubleToString(histAcc, 1) + "%";
   UI_CreateLabel(prefix + "HistAcc", PANEL_X + 20, y, histAccStr, histAccColor, 10, true);
   
   ChartRedraw();
}

#endif