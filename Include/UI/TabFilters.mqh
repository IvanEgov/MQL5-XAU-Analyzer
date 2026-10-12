//+------------------------------------------------------------------+
//| TabFilters.mqh                                                   |
//| СЛОЙ 6: UI - Вкладка ФИЛЬТРЫ (компактный вид)                    |
//+------------------------------------------------------------------+
#ifndef UI_TAB_FILTERS_MQH
#define UI_TAB_FILTERS_MQH

//+------------------------------------------------------------------+
//| Главная функция отрисовки вкладки ФИЛЬТРЫ                        |
//+------------------------------------------------------------------+
void UI_DrawTabFilters(int &y, int lineHeight)
{
   string prefix = PANEL_NAME + "_C1_";
   
   //=== ЗАГОЛОВОК ===
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "🛡️ ФИЛЬТРЫ ТОЧНОСТИ", clrYellow, 11, true);
   y += lineHeight + 5;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep1", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== РЕЖИМЫ СИГНАЛОВ ===
   UI_CreateLabel(prefix + "ModesTitle", PANEL_X + 15, y, "🎛️ РЕЖИМЫ СИГНАЛОВ", clrWheat, 10, true);
   UI_CreateLabel(prefix + "ModesStatus", PANEL_X + 380, y, "СТАТУС", clrWheat, 9, true);
   y += lineHeight + 2;
   
   string h1Status = UseSignalH1 ? "✅ ВКЛ" : "❌ ВЫКЛ";
   color h1Color = UseSignalH1 ? clrLime : clrGray;
   UI_CreateLabel(prefix + "H1", PANEL_X + 25, y, "🟢 H1 (1 час)", h1Color, 9, false);
   UI_CreateLabel(prefix + "H1_Status", PANEL_X + 380, y, h1Status, h1Color, 9, true);
   y += lineHeight;
   
   string h4Status = UseSignalH4 ? "✅ ВКЛ" : "❌ ВЫКЛ";
   color h4Color = UseSignalH4 ? clrLime : clrGray;
   UI_CreateLabel(prefix + "H4", PANEL_X + 25, y, "🟡 H4 (4 часа)", h4Color, 9, false);
   UI_CreateLabel(prefix + "H4_Status", PANEL_X + 380, y, h4Status, h4Color, 9, true);
   y += lineHeight;
   
   string d1Status = UseSignalD1 ? "✅ ВКЛ" : "❌ ВЫКЛ";
   color d1Color = UseSignalD1 ? clrLime : clrGray;
   UI_CreateLabel(prefix + "D1", PANEL_X + 25, y, "🔴 D1 (1 день)", d1Color, 9, false);
   UI_CreateLabel(prefix + "D1_Status", PANEL_X + 380, y, d1Status, d1Color, 9, true);
   y += lineHeight + 5;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep2", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== СОСТОЯНИЕ ФИЛЬТРОВ ===
   UI_CreateLabel(prefix + "FiltersTitle", PANEL_X + 15, y, "🔍 ФИЛЬТРЫ", clrWheat, 10, true);
   UI_CreateLabel(prefix + "FiltersStatus", PANEL_X + 380, y, "СТАТУС", clrWheat, 9, true);
   y += lineHeight + 2;
   
   // Фильтр новостей
   string newsStatus = filterNews ? "✅ ВКЛ" : "❌ ВЫКЛ";
   color newsColor = filterNews ? clrLime : clrRed;
   UI_CreateLabel(prefix + "F1", PANEL_X + 20, y, "📰 Новости (±30 мин)", newsColor, 9, false);
   UI_CreateLabel(prefix + "F1_Status", PANEL_X + 380, y, newsStatus, newsColor, 9, true);
   y += lineHeight;
   
   // Фильтр волатильности
   string volStatus = filterVolatility ? "✅ ВКЛ" : "❌ ВЫКЛ";
   color volColor = filterVolatility ? clrLime : clrRed;
   UI_CreateLabel(prefix + "F2", PANEL_X + 20, y, "📊 Волатильность (ATR)", volColor, 9, false);
   UI_CreateLabel(prefix + "F2_Status", PANEL_X + 380, y, volStatus, volColor, 9, true);
   y += lineHeight;
   
   // Фильтр сессии
   string sessStatus = filterSession ? "✅ ВКЛ" : "❌ ВЫКЛ";
   color sessColor = filterSession ? clrLime : clrRed;
   UI_CreateLabel(prefix + "F3", PANEL_X + 20, y, "🕐 Сессия (8-22)", sessColor, 9, false);
   UI_CreateLabel(prefix + "F3_Status", PANEL_X + 380, y, sessStatus, sessColor, 9, true);
   y += lineHeight;
   
   // Фильтр свечного паттерна
   string candleStatus = filterCandle ? "✅ ВКЛ" : "❌ ВЫКЛ";
   color candleColor = filterCandle ? clrLime : clrRed;
   UI_CreateLabel(prefix + "F4", PANEL_X + 20, y, "🕯️ Свечной паттерн", candleColor, 9, false);
   UI_CreateLabel(prefix + "F4_Status", PANEL_X + 380, y, candleStatus, candleColor, 9, true);
   y += lineHeight;
   
   // Фильтр RSI
   string rsiStatus = filterRSI ? "✅ ВКЛ" : "❌ ВЫКЛ";
   color rsiColor = filterRSI ? clrLime : clrRed;
   UI_CreateLabel(prefix + "F5", PANEL_X + 20, y, "📈 RSI (не экстремум)", rsiColor, 9, false);
   UI_CreateLabel(prefix + "F5_Status", PANEL_X + 380, y, rsiStatus, rsiColor, 9, true);
   y += lineHeight;
   
   // Фильтр структуры
   string structStatus = filterStructure ? "✅ ВКЛ" : "❌ ВЫКЛ";
   color structColor = filterStructure ? clrLime : clrRed;
   UI_CreateLabel(prefix + "F6", PANEL_X + 20, y, "🧱 Структура (уровни)", structColor, 9, false);
   UI_CreateLabel(prefix + "F6_Status", PANEL_X + 380, y, structStatus, structColor, 9, true);
   y += lineHeight + 5;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep3", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== ИТОГ ===
   int passedCount = (filterNews?1:0) + (filterVolatility?1:0) + (filterSession?1:0) + 
                     (filterCandle?1:0) + (filterRSI?1:0) + (filterStructure?1:0);
   
   string summaryTitle = "🎯 ИТОГ: " + (string)passedCount + "/6 ПРОЙДЕНО";
   color summaryColor = (passedCount == 6) ? clrLime : ((passedCount >= 4) ? clrYellow : clrOrange);
   UI_CreateLabel(prefix + "Summary", PANEL_X + 15, y, summaryTitle, summaryColor, 11, true);
   y += lineHeight + 3;
   
   // Финальный вердикт
   if(passedCount == 6)
   {
      string finalStatus = (g_resultH1.weightedSum > 0) ? "🟢 CONFIRMED BUY 🔔" : "🔴 CONFIRMED SELL 🔔";
      color finalColor = (g_resultH1.weightedSum > 0) ? clrLime : clrRed;
      UI_CreateLabel(prefix + "Final", PANEL_X + 20, y, finalStatus, finalColor, 11, true);
   }
   else
   {
      UI_CreateLabel(prefix + "Final", PANEL_X + 20, y, "⏳ ОЖИДАНИЕ ПОДТВЕРЖДЕНИЯ", clrOrange, 11, true);
   }
   
   ChartRedraw();
}

#endif