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
void UI_DrawTabAnalysis(const IndicatorVotes &resultH1, 
                        const IndicatorVotes &resultH4, 
                        const IndicatorVotes &resultD1,
                        const string &currentSymbol,
                        const double &symbolPoint)
{
   string prefix = PANEL_NAME + "_Content_0_";
   int yOffset = PANEL_Y + 70;
   int lineHeight = PANEL_LINE_HEIGHT;
   
   UI_CreateLabel(prefix + "Title", PANEL_X + 10, yOffset, "📊 АНАЛИЗ РЫНКА", clrYellow, 11, true);
   yOffset += lineHeight + 5;
   
   string priceStr = DoubleToString(resultH1.currentPrice, (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS));
   UI_CreateLabel(prefix + "Price", PANEL_X + 10, yOffset, "Цена: " + priceStr, clrWhite, 10, false);
   yOffset += lineHeight + 5;
   
   UI_CreateLabel(prefix + "Sep1", PANEL_X + 10, yOffset, "─────────────────────────────────", clrDarkGray, 8, false);
   yOffset += lineHeight;
   
   color h1Color = UI_GetSignalColor(resultH1.signal);
   UI_CreateLabel(prefix + "H1_Title", PANEL_X + 10, yOffset, "H1 (1 час):", clrDodgerBlue, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H1_Signal", PANEL_X + 20, yOffset, "Сигнал: " + resultH1.signal, h1Color, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H1_Sum", PANEL_X + 20, yOffset, "Сила: " + DoubleToString(resultH1.weightedSum, 1), clrWhite, 9, false);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H1_Candles", PANEL_X + 20, yOffset, "Прогноз: " + IntegerToString(resultH1.candlesForecast) + " свечей", clrWhite, 9, false);
   yOffset += lineHeight + 5;
   
   color h4Color = UI_GetSignalColor(resultH4.signal);
   UI_CreateLabel(prefix + "H4_Title", PANEL_X + 10, yOffset, "H4 (4 часа):", clrYellow, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H4_Signal", PANEL_X + 20, yOffset, "Сигнал: " + resultH4.signal, h4Color, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H4_Sum", PANEL_X + 20, yOffset, "Сила: " + DoubleToString(resultH4.weightedSum, 1), clrWhite, 9, false);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "H4_Candles", PANEL_X + 20, yOffset, "Прогноз: " + IntegerToString(resultH4.candlesForecast) + " свечей", clrWhite, 9, false);
   yOffset += lineHeight + 5;
   
   color d1Color = UI_GetSignalColor(resultD1.signal);
   UI_CreateLabel(prefix + "D1_Title", PANEL_X + 10, yOffset, "D1 (1 день):", clrOrangeRed, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "D1_Signal", PANEL_X + 20, yOffset, "Сигнал: " + resultD1.signal, d1Color, 10, true);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "D1_Sum", PANEL_X + 20, yOffset, "Сила: " + DoubleToString(resultD1.weightedSum, 1), clrWhite, 9, false);
   yOffset += lineHeight;
   UI_CreateLabel(prefix + "D1_Candles", PANEL_X + 20, yOffset, "Прогноз: " + IntegerToString(resultD1.candlesForecast) + " свечей", clrWhite, 9, false);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Цвет сигнала                                                     |
//+------------------------------------------------------------------+
color UI_GetSignalColor(const string &signal)
{
   if(signal == "STRONG BUY") return clrLime;
   if(signal == "BUY") return clrDodgerBlue;
   if(signal == "STRONG SELL") return clrRed;
   if(signal == "SELL") return clrOrangeRed;
   return clrGray;
}

//+------------------------------------------------------------------+
//| Создание текстовой метки                                         |
//+------------------------------------------------------------------+
void UI_CreateLabel(const string &name, int x, int y, const string &text, color clr, int fontSize, bool bold)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

#endif