//+------------------------------------------------------------------+
//| TabAnalysis.mqh                                                  |
//| СЛОЙ 6: UI - Вкладка АНАЛИЗ                                      |
//+------------------------------------------------------------------+
#ifndef UI_TAB_ANALYSIS_MQH
#define UI_TAB_ANALYSIS_MQH

#include <Config.mqh>
#include <DataStructures.mqh>

//+------------------------------------------------------------------+
//| Отрисовка вкладки АНАЛИЗ                                         |
//+------------------------------------------------------------------+
void UI_DrawTabAnalysis(const IndicatorVotes &resH1, 
                        const IndicatorVotes &resH4, 
                        const IndicatorVotes &resD1,
                        const string &symName,
                        const double &symPoint)
{
   string prefix = PANEL_NAME + "_Content_0_";
   int yOffset = PANEL_Y + 70;
   int lineHeight = PANEL_LINE_HEIGHT;
   
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, yOffset, "📊 АНАЛИЗ РЫНКА", clrYellow, 11, true);
   yOffset += lineHeight + 5;
   
   string priceStr = DoubleToString(resH1.currentPrice, (int)SymbolInfoInteger(symName, SYMBOL_DIGITS));
   UI_CreateLabel(prefix + "Price", PANEL_X + 10, yOffset, "Цена: " + priceStr, clrWhite, 10, false);
   yOffset += lineHeight + 5;
   
   UI_CreateLabel(prefix + "Sep1", PANEL_X + 10, yOffset, "─────────────────────────────────", clrGray, 8, false);
   yOffset += lineHeight;
   
   color h1Color = (resH1.signal == "STRONG BUY" || resH1.signal == "BUY") ? clrLime : ((resH1.signal == "STRONG SELL" || resH1.signal == "SELL") ? clrRed : clrGray);
   UI_CreateLabel(prefix + "H1_Title", PANEL_X + 10, yOffset, "H1 (1 час):", clrDodgerBlue, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H1_Signal", PANEL_X + 20, yOffset, "Сигнал: " + resH1.signal, h1Color, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H1_Sum", PANEL_X + 20, yOffset, "Сила: " + DoubleToString(resH1.weightedSum, 1), clrWhite, 9, false);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H1_Candles", PANEL_X + 20, yOffset, "Прогноз: " + IntegerToString(resH1.candlesForecast) + " свечей", clrWhite, 9, false);
   yOffset += lineHeight + 5;
   
   color h4Color = (resH4.signal == "STRONG BUY" || resH4.signal == "BUY") ? clrLime : ((resH4.signal == "STRONG SELL" || resH4.signal == "SELL") ? clrRed : clrGray);
   UI_CreateLabel(prefix + "H4_Title", PANEL_X + 10, yOffset, "H4 (4 часа):", clrYellow, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H4_Signal", PANEL_X + 20, yOffset, "Сигнал: " + resH4.signal, h4Color, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H4_Sum", PANEL_X + 20, yOffset, "Сила: " + DoubleToString(resH4.weightedSum, 1), clrWhite, 9, false);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H4_Candles", PANEL_X + 20, yOffset, "Прогноз: " + IntegerToString(resH4.candlesForecast) + " свечей", clrWhite, 9, false);
   yOffset += lineHeight + 5;
   
   color d1Color = (resD1.signal == "STRONG BUY" || resD1.signal == "BUY") ? clrLime : ((resD1.signal == "STRONG SELL" || resD1.signal == "SELL") ? clrRed : clrGray);
   UI_CreateLabel(prefix + "D1_Title", PANEL_X + 10, yOffset, "D1 (1 день):", clrOrangeRed, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "D1_Signal", PANEL_X + 20, yOffset, "Сигнал: " + resD1.signal, d1Color, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "D1_Sum", PANEL_X + 20, yOffset, "Сила: " + DoubleToString(resD1.weightedSum, 1), clrWhite, 9, false);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "D1_Candles", PANEL_X + 20, yOffset, "Прогноз: " + IntegerToString(resD1.candlesForecast) + " свечей", clrWhite, 9, false);
   
   ChartRedraw();
}

#endif