//+------------------------------------------------------------------+
//| TabFilters.mqh                                                   |
//+------------------------------------------------------------------+
#ifndef UI_TAB_FILTERS_MQH
#define UI_TAB_FILTERS_MQH

void UI_DrawTabFilters(int &y, int lineHeight)
{
   string prefix = PANEL_NAME + "_C1_";
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "🛡️ ФИЛЬТРЫ ТОЧНОСТИ:", clrYellow, 11, true); y += lineHeight + 3;
   
   UI_CreateLabel(prefix + "F1", PANEL_X + 25, y, (filterNews ? "✅ " : "❌ ") + "📰 Новости", filterNews ? clrLime : clrRed, 10, false); y += lineHeight;
   UI_CreateLabel(prefix + "F2", PANEL_X + 25, y, (filterVolatility ? "✅ " : "❌ ") + "📊 Волатильность", filterVolatility ? clrLime : clrRed, 10, false); y += lineHeight;
   UI_CreateLabel(prefix + "F3", PANEL_X + 25, y, (filterSession ? "✅ " : "❌ ") + "🕐 Сессия", filterSession ? clrLime : clrRed, 10, false); y += lineHeight;
   UI_CreateLabel(prefix + "F4", PANEL_X + 25, y, (filterCandle ? "✅ " : "❌ ") + "🕯️ Свечи", filterCandle ? clrLime : clrRed, 10, false); y += lineHeight;
   UI_CreateLabel(prefix + "F5", PANEL_X + 25, y, (filterRSI ? "✅ " : "❌ ") + "📈 RSI", filterRSI ? clrLime : clrRed, 10, false); y += lineHeight;
   UI_CreateLabel(prefix + "F6", PANEL_X + 25, y, (filterStructure ? "✅ " : "❌ ") + "🧱 Структура", filterStructure ? clrLime : clrRed, 10, false); y += lineHeight + 5;
   
   UI_CreateLabel(prefix + "Sep", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false); y += lineHeight;
   
   int passed = (filterNews?1:0) + (filterVolatility?1:0) + (filterSession?1:0) + (filterCandle?1:0) + (filterRSI?1:0) + (filterStructure?1:0);
   string status = (passed == 6) ? ((g_resultH1.weightedSum > 0) ? "🟢 CONFIRMED BUY" : "🔴 CONFIRMED SELL") : "⏳ Фильтры: " + (string)passed + "/6";
   color col = (passed == 6) ? ((g_resultH1.weightedSum > 0) ? clrLime : clrRed) : clrOrange;
   UI_CreateLabel(prefix + "Confirm", PANEL_X + 20, y, status, col, 11, true);
}
#endif