//+------------------------------------------------------------------+
//| TabHistory.mqh                                                   |
//+------------------------------------------------------------------+
#ifndef UI_TAB_HISTORY_MQH
#define UI_TAB_HISTORY_MQH

void UI_DrawTabHistory(int &y, int lineHeight, int digits)
{
   string prefix = PANEL_NAME + "_C4_";
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "📜 ИСТОРИЯ:", clrYellow, 11, true); y += lineHeight + 3;
   UI_CreateLabel(prefix + "H1", PANEL_X + 15, y, "ВРЕМЯ", clrDodgerBlue, 9, true);
   UI_CreateLabel(prefix + "H2", PANEL_X + 110, y, "ТФ", clrDodgerBlue, 9, true);
   UI_CreateLabel(prefix + "H3", PANEL_X + 145, y, "НАПР", clrDodgerBlue, 9, true);
   UI_CreateLabel(prefix + "H4", PANEL_X + 190, y, "ВХОД", clrDodgerBlue, 9, true);
   UI_CreateLabel(prefix + "H5", PANEL_X + 280, y, "СТАТУС", clrDodgerBlue, 9, true);
   y += lineHeight;
   UI_CreateLabel(prefix + "Sep", PANEL_X + 10, y, "──────────────────────────────────────", clrGray, 9, false); y += lineHeight;
   
   int realCount = 0;
   for(int i = 0; i < ArraySize(history); i++) if(history[i].time > 0) realCount++;
   if(realCount == 0) { UI_CreateLabel(prefix + "Empty", PANEL_X + 20, y, "⏸ Пуста", clrGray, 10, false); return; }
   
   for(int i = ArraySize(history) - 1; i >= 0; i--) {
      if(history[i].time == 0) continue;
      string tStr = TimeToString(history[i].time, TIME_DATE|TIME_MINUTES);
      StringSetCharacter(tStr, 4, '-'); StringSetCharacter(tStr, 7, '-');
      UI_CreateLabel(prefix + "T_" + (string)i, PANEL_X + 15, y, tStr, clrLightGray, 8, false);
      
      color mCol = (history[i].mode=="H1")?clrLime:((history[i].mode=="H4")?clrYellow:clrOrangeRed);
      UI_CreateLabel(prefix + "M_" + (string)i, PANEL_X + 115, y, history[i].mode, mCol, 9, false);
      
      color dCol = (history[i].direction=="BUY")?clrLime:clrRed;
      UI_CreateLabel(prefix + "D_" + (string)i, PANEL_X + 145, y, (history[i].direction=="BUY")?"▲":"▼", dCol, 9, false);
      
      UI_CreateLabel(prefix + "E_" + (string)i, PANEL_X + 180, y, DoubleToString(history[i].entry, digits), clrWhite, 8, false);
      
      color sCol = (StringFind(history[i].status, "WIN")>=0)?clrLime:((StringFind(history[i].status, "LOSS")>=0)?clrRed:clrOrange);
      UI_CreateLabel(prefix + "S_" + (string)i, PANEL_X + 280, y, history[i].status, sCol, 8, false);
      y += lineHeight - 2;
   }
}
#endif