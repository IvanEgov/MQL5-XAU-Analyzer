//+------------------------------------------------------------------+
//| TabAnalysis.mqh                                                  |
//+------------------------------------------------------------------+
#ifndef UI_TAB_ANALYSIS_MQH
#define UI_TAB_ANALYSIS_MQH

void UI_DrawTabAnalysis(int &y, int lineHeight, int digits)
{
   string prefix = PANEL_NAME + "_C0_";
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "📊 АНАЛИЗ РЫНКА", clrYellow, 11, true); y += lineHeight + 5;
   
   string priceStr = DoubleToString(g_resultH1.currentPrice, digits);
   UI_CreateLabel(prefix + "Price", PANEL_X + 10, y, "Цена: " + priceStr, clrWhite, 10, false); y += lineHeight + 5;
   UI_CreateLabel(prefix + "Sep", PANEL_X + 10, y, "─────────────────────────────────", clrGray, 8, false); y += lineHeight;

   // H1
   color c1 = (g_resultH1.weightedSum > 0) ? clrLime : ((g_resultH1.weightedSum < 0) ? clrRed : clrGray);
   UI_CreateLabel(prefix + "H1_T", PANEL_X + 10, y, "H1:", clrDodgerBlue, 10, true);
   UI_CreateLabel(prefix + "H1_S", PANEL_X + 50, y, g_resultH1.signal, c1, 10, true);
   UI_CreateLabel(prefix + "H1_V", PANEL_X + 150, y, "Σ: " + DoubleToString(g_resultH1.weightedSum, 1), clrWhite, 9, false); y += lineHeight;

   // H4
   color c4 = (g_resultH4.weightedSum > 0) ? clrLime : ((g_resultH4.weightedSum < 0) ? clrRed : clrGray);
   UI_CreateLabel(prefix + "H4_T", PANEL_X + 10, y, "H4:", clrYellow, 10, true);
   UI_CreateLabel(prefix + "H4_S", PANEL_X + 50, y, g_resultH4.signal, c4, 10, true);
   UI_CreateLabel(prefix + "H4_V", PANEL_X + 150, y, "Σ: " + DoubleToString(g_resultH4.weightedSum, 1), clrWhite, 9, false); y += lineHeight;

   // D1
   color cd = (g_resultD1.weightedSum > 0) ? clrLime : ((g_resultD1.weightedSum < 0) ? clrRed : clrGray);
   UI_CreateLabel(prefix + "D1_T", PANEL_X + 10, y, "D1:", clrOrangeRed, 10, true);
   UI_CreateLabel(prefix + "D1_S", PANEL_X + 50, y, g_resultD1.signal, cd, 10, true);
   UI_CreateLabel(prefix + "D1_V", PANEL_X + 150, y, "Σ: " + DoubleToString(g_resultD1.weightedSum, 1), clrWhite, 9, false); y += lineHeight + 5;
   
   ChartRedraw();
}
#endif