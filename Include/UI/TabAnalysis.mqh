//+------------------------------------------------------------------+
//| TabAnalysis.mqh                                                  |
//| СЛОЙ 6: UI - Вкладка АНАЛИЗ (профессиональный вид)               |
//+------------------------------------------------------------------+
#ifndef UI_TAB_ANALYSIS_MQH
#define UI_TAB_ANALYSIS_MQH

//+------------------------------------------------------------------+
//| Главная функция отрисовки вкладки АНАЛИЗ                         |
//+------------------------------------------------------------------+
void UI_DrawTabAnalysis(int &y, int lineHeight, int digits)
{
   string prefix = PANEL_NAME + "_C0_";
   
   //=== ЗАГОЛОВОК ===
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, y, "📊 АНАЛИЗ РЫНКА", clrYellow, 11, true);
   UI_CreateLabel(prefix + "Symbol", PANEL_X + PANEL_WIDTH - 120, y, g_currentSymbol + " 💰", clrWheat, 10, true);
   y += lineHeight + 3;
   
   //=== ЦЕНА И ATR ===
   string priceStr = DoubleToString(g_resultH1.currentPrice, digits);
   string atrStr = (g_resultH1.atrValue > 0) ? DoubleToString(g_resultH1.atrValue, digits) : "—";
   UI_CreateLabel(prefix + "Price", PANEL_X + 15, y, "💰 Цена: " + priceStr, clrWhite, 10, true);
   UI_CreateLabel(prefix + "ATR", PANEL_X + 200, y, "📏 ATR(H1): " + atrStr, clrLightGray, 9, false);
   y += lineHeight + 5;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep1", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight;
   
   //=== ОБЩИЙ ВЕРДИКТ ===
   string verdict = "";
   color verdictColor = clrGray;
   string verdictDesc = "";
   
   int bullCount = 0, bearCount = 0;
   if(g_resultH1.weightedSum > 2) bullCount++; else if(g_resultH1.weightedSum < -2) bearCount++;
   if(g_resultH4.weightedSum > 2) bullCount++; else if(g_resultH4.weightedSum < -2) bearCount++;
   if(g_resultD1.weightedSum > 2) bullCount++; else if(g_resultD1.weightedSum < -2) bearCount++;
   
   if(bullCount == 3) { verdict = "🟢 СИЛЬНЫЙ БЫЧИЙ ТРЕНД"; verdictColor = clrLime; verdictDesc = "Все ТФ подтверждают BUY"; }
   else if(bearCount == 3) { verdict = "🔴 СИЛЬНЫЙ МЕДВЕЖИЙ ТРЕНД"; verdictColor = clrRed; verdictDesc = "Все ТФ подтверждают SELL"; }
   else if(bullCount >= 2) { verdict = "🟢 БЫЧИЙ УКЛОН"; verdictColor = clrGreen; verdictDesc = "Преимущественно BUY"; }
   else if(bearCount >= 2) { verdict = "🔴 МЕДВЕЖИЙ УКЛОН"; verdictColor = clrDarkRed; verdictDesc = "Преимущественно SELL"; }
   else { verdict = "🟡 ФЛЭТ / НЕОПРЕДЕЛЁННОСТЬ"; verdictColor = clrOrange; verdictDesc = "Ждём подтверждения тренда"; }
   
   UI_CreateLabel(prefix + "Verdict", PANEL_X + 15, y, "🎯 " + verdict, verdictColor, 11, true);
   y += lineHeight;
   UI_CreateLabel(prefix + "VerdictDesc", PANEL_X + 25, y, verdictDesc, clrLightGray, 9, false);
   y += lineHeight;
   
   //=== РАЗДЕЛИТЕЛЬ ===
   UI_CreateLabel(prefix + "Sep2", PANEL_X + 10, y, "═══════════════════════════════════════════", clrDodgerBlue, 9, false);
   y += lineHeight + 3;
   
   //=== ДЕТАЛИЗАЦИЯ ПО ТАЙМФРЕЙМАМ ===
   UI_DrawTFRow_Analysis(prefix + "H1_", y, lineHeight, digits, "H1 (1 час)", g_resultH1, clrDodgerBlue);
   y += 5;
   UI_CreateLabel(prefix + "Sep3", PANEL_X + 10, y, "───────────────────────────────────────────", clrGray, 8, false);
   y += lineHeight - 2;
   
   UI_DrawTFRow_Analysis(prefix + "H4_", y, lineHeight, digits, "H4 (4 часа)", g_resultH4, clrYellow);
   y += 5;
   UI_CreateLabel(prefix + "Sep4", PANEL_X + 10, y, "───────────────────────────────────────────", clrGray, 8, false);
   y += lineHeight - 2;
   
   UI_DrawTFRow_Analysis(prefix + "D1_", y, lineHeight, digits, "D1 (1 день)", g_resultD1, clrOrangeRed);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Отрисовка одной строки таймфрейма с голосами индикаторов         |
//+------------------------------------------------------------------+
void UI_DrawTFRow_Analysis(string rowPrefix, int &y, int lineHeight, int digits, 
                           string tfName, const IndicatorVotes &result, color tfColor)
{
   // Заголовок строки ТФ
   UI_CreateLabel(rowPrefix + "Name", PANEL_X + 15, y, tfName, tfColor, 10, true);
   
   // Σ (сумма) и сигнал справа
   string sumStr = (result.weightedSum >= 0 ? "+" : "") + DoubleToString(result.weightedSum, 1);
   color sumColor = (result.weightedSum > 2) ? clrLime : ((result.weightedSum < -2) ? clrRed : clrGray);
   UI_CreateLabel(rowPrefix + "Sum", PANEL_X + 180, y, "Σ: " + sumStr, sumColor, 10, true);
   
   color sigColor = UI_GetAnalysisColor(result.signal);
   UI_CreateLabel(rowPrefix + "Signal", PANEL_X + 280, y, result.signal, sigColor, 10, true);
   y += lineHeight;
   
   // Голоса 10 индикаторов (визуально)
   int bullVotes = 0, bearVotes = 0;
   string votesStr = "";
   for(int i = 0; i < 10; i++)
   {
      if(result.votes[i] > 0) { votesStr += "▲"; bullVotes++; }
      else if(result.votes[i] < 0) { votesStr += "▼"; bearVotes++; }
      else votesStr += "●";
   }
   
   // Рисуем каждый голос отдельным цветом
   int xVotes = PANEL_X + 25;
   for(int i = 0; i < 10; i++)
   {
      string voteChar = (result.votes[i] > 0) ? "▲" : ((result.votes[i] < 0) ? "▼" : "●");
      color voteColor = (result.votes[i] > 0) ? clrLime : ((result.votes[i] < 0) ? clrRed : clrDarkGray);
      UI_CreateLabel(rowPrefix + "V" + (string)i, xVotes + i * 14, y, voteChar, voteColor, 9, false);
   }
   
   // Счётчик голосов
   string votesCount = "(" + (string)bullVotes + "↑ / " + (string)bearVotes + "↓)";
   UI_CreateLabel(rowPrefix + "VotesCount", PANEL_X + 180, y, votesCount, clrLightGray, 8, false);
   y += lineHeight;
   
   // Прогноз и целевая цена
   string forecastStr = "🕯️ Прогноз: " + (string)result.candlesForecast + " свечей";
   UI_CreateLabel(rowPrefix + "Forecast", PANEL_X + 25, y, forecastStr, clrOrange, 9, false);
   
   if(result.targetPrice > 0)
   {
      string targetStr = "→ " + DoubleToString(result.targetPrice, digits);
      color targetColor = (result.targetPrice > result.currentPrice) ? clrLime : ((result.targetPrice < result.currentPrice) ? clrRed : clrGray);
      UI_CreateLabel(rowPrefix + "Target", PANEL_X + 200, y, "🎯 Цель: " + targetStr, targetColor, 9, true);
   }
   y += lineHeight;
}

//+------------------------------------------------------------------+
//| Цвет для типа сигнала                                            |
//+------------------------------------------------------------------+
color UI_GetAnalysisColor(string signal)
{
   if(signal == "STRONG BUY") return clrLime;
   if(signal == "BUY") return clrGreen;
   if(signal == "STRONG SELL") return clrRed;
   if(signal == "SELL") return clrDarkRed;
   return clrGray; // HOLD
}

#endif