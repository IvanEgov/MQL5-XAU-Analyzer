//+------------------------------------------------------------------+
//|                                    XAU_Analyzer_Collapsible.mq5  |
//|              Универсальный анализ с кнопкой свернуть/развернуть  |
//+------------------------------------------------------------------+
#property strict

struct IndicatorVotes
{
   int votes[10];
   int totalSum;
   string signal;
   int candlesForecast;
   double currentPrice;
   double targetPrice;
};

IndicatorVotes resultH1, resultH4, resultD1;

//--- Хендлы индикаторов
int hEMA50_H1, hEMA200_H1, hMACD_H1, hADX_H1, hRSI_H1;
int hStoch_H1, hCCI_H1, hVol_H1, hOBV_H1, hBB_H1, hATR_H1;
int hEMA50_H4, hEMA200_H4, hMACD_H4, hADX_H4, hRSI_H4;
int hStoch_H4, hCCI_H4, hVol_H4, hOBV_H4, hBB_H4, hATR_H4;
int hEMA50_D1, hEMA200_D1, hMACD_D1, hADX_D1, hRSI_D1;
int hStoch_D1, hCCI_D1, hVol_D1, hOBV_D1, hBB_D1, hATR_D1;

//--- Информация о паре
string currentSymbol = "";
string symbolType = "";
int symbolDigits = 0;
double symbolPoint = 0;
long symbolSpread = 0;
string currentSession = "";

//--- Параметры панели
string panelName = "AnalysisPanel";
string buttonName = "CollapseButton";
int panelX = 20, panelY = 30;
int panelWidth = 450;
int panelHeightExpanded = 480;   // Полная высота
int panelHeightCollapsed = 35;   // Высота в свернутом виде
bool isCollapsed = false;        // Состояние панели

//+------------------------------------------------------------------+
int OnInit()
{
   currentSymbol = _Symbol;
   symbolDigits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   symbolPoint = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   symbolSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   symbolType = DetectSymbolType(_Symbol);
   
   //=== H1 ===
   hEMA50_H1  = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   hEMA200_H1 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
   hMACD_H1   = iMACD(_Symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE);
   hADX_H1    = iADX(_Symbol, PERIOD_H1, 14);
   hRSI_H1    = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);
   hStoch_H1  = iStochastic(_Symbol, PERIOD_H1, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
   hCCI_H1    = iCCI(_Symbol, PERIOD_H1, 20, PRICE_CLOSE);
   hVol_H1    = iVolumes(_Symbol, PERIOD_H1, VOLUME_TICK);
   hOBV_H1    = iOBV(_Symbol, PERIOD_H1, VOLUME_TICK);
   hBB_H1     = iBands(_Symbol, PERIOD_H1, 20, 0, 2.0, PRICE_CLOSE);
   hATR_H1    = iATR(_Symbol, PERIOD_H1, 14);
   
   //=== H4 ===
   hEMA50_H4  = iMA(_Symbol, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE);
   hEMA200_H4 = iMA(_Symbol, PERIOD_H4, 200, 0, MODE_EMA, PRICE_CLOSE);
   hMACD_H4   = iMACD(_Symbol, PERIOD_H4, 12, 26, 9, PRICE_CLOSE);
   hADX_H4    = iADX(_Symbol, PERIOD_H4, 14);
   hRSI_H4    = iRSI(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);
   hStoch_H4  = iStochastic(_Symbol, PERIOD_H4, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
   hCCI_H4    = iCCI(_Symbol, PERIOD_H4, 20, PRICE_CLOSE);
   hVol_H4    = iVolumes(_Symbol, PERIOD_H4, VOLUME_TICK);
   hOBV_H4    = iOBV(_Symbol, PERIOD_H4, VOLUME_TICK);
   hBB_H4     = iBands(_Symbol, PERIOD_H4, 20, 0, 2.0, PRICE_CLOSE);
   hATR_H4    = iATR(_Symbol, PERIOD_H4, 14);
   
   //=== D1 ===
   hEMA50_D1  = iMA(_Symbol, PERIOD_D1, 50, 0, MODE_EMA, PRICE_CLOSE);
   hEMA200_D1 = iMA(_Symbol, PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE);
   hMACD_D1   = iMACD(_Symbol, PERIOD_D1, 12, 26, 9, PRICE_CLOSE);
   hADX_D1    = iADX(_Symbol, PERIOD_D1, 14);
   hRSI_D1    = iRSI(_Symbol, PERIOD_D1, 14, PRICE_CLOSE);
   hStoch_D1  = iStochastic(_Symbol, PERIOD_D1, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
   hCCI_D1    = iCCI(_Symbol, PERIOD_D1, 20, PRICE_CLOSE);
   hVol_D1    = iVolumes(_Symbol, PERIOD_D1, VOLUME_TICK);
   hOBV_D1    = iOBV(_Symbol, PERIOD_D1, VOLUME_TICK);
   hBB_D1     = iBands(_Symbol, PERIOD_D1, 20, 0, 2.0, PRICE_CLOSE);
   hATR_D1    = iATR(_Symbol, PERIOD_D1, 14);
   
   CreatePanel();
   CreateCollapseButton();
   EventSetTimer(60);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeletePanel();
   EventKillTimer();
}

//+------------------------------------------------------------------+
void OnTimer() { Analyze(); }
void OnTick()  { Analyze(); }

//+------------------------------------------------------------------+
//| Обработчик кликов по графическим объектам                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == buttonName)
      {
         // Переключаем состояние
         isCollapsed = !isCollapsed;
         
         // Сбрасываем нажатое состояние кнопки (чтобы она не оставалась "вдавленной")
         ObjectSetInteger(0, buttonName, OBJPROP_STATE, false);
         
         // Обновляем кнопку и панель
         UpdateCollapseButton();
         UpdatePanel();
         
         ChartRedraw();
      }
   }
}

//+------------------------------------------------------------------+
string DetectSymbolType(string symbol)
{
   string sym = symbol;
   StringToUpper(sym);
   if(StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0) return "ЗОЛОТО 🥇";
   if(StringFind(sym, "XAG") >= 0 || StringFind(sym, "SILVER") >= 0) return "СЕРЕБРО 🥈";
   if(StringFind(sym, "XPT") >= 0) return "ПЛАТИНА";
   if(StringFind(sym, "XPD") >= 0) return "ПАЛЛАДИЙ";
   if(StringFind(sym, "BTC") >= 0) return "КРИПТО ₿";
   if(StringFind(sym, "ETH") >= 0) return "КРИПТО Ξ";
   if(StringFind(sym, "US30") >= 0 || StringFind(sym, "DJ30") >= 0) return "ИНДЕКС 📊";
   if(StringFind(sym, "SPX") >= 0 || StringFind(sym, "US500") >= 0) return "ИНДЕКС 📊";
   if(StringFind(sym, "NAS") >= 0 || StringFind(sym, "USTECH") >= 0) return "ИНДЕКС 📊";
   if(StringFind(sym, "DAX") >= 0 || StringFind(sym, "GER40") >= 0) return "ИНДЕКС 📊";
   if(StringFind(sym, "OIL") >= 0 || StringFind(sym, "WTI") >= 0 || StringFind(sym, "XTI") >= 0) return "НЕФТЬ 🛢";
   if(StringFind(sym, "BRENT") >= 0) return "НЕФТЬ 🛢";
   string currencies[] = {"USD", "EUR", "GBP", "JPY", "CHF", "AUD", "CAD", "NZD"};
   for(int i = 0; i < 8; i++)
      if(StringFind(sym, currencies[i]) >= 0) return "ФОРЕКС 💱";
   return "ДРУГОЕ";
}

//+------------------------------------------------------------------+
string DetectSession()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   int hour = dt.hour;
   if(hour >= 0 && hour < 8)   return "АЗИЯ 🌏";
   if(hour >= 8 && hour < 13)  return "ЕВРОПА 🇪🇺";
   if(hour >= 13 && hour < 21) return "АМЕРИКА 🇺🇸";
   return "ТИХИЙ ОКЕАН 🌊";
}

//+------------------------------------------------------------------+
string DetectDayOfWeek()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   string days[] = {"ВС", "ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ"};
   return days[dt.day_of_week];
}

//+------------------------------------------------------------------+
void Analyze()
{
   currentSession = DetectSession();
   symbolSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   
   AnalyzeTimeframe(PERIOD_H1, hEMA50_H1, hEMA200_H1, hMACD_H1, hADX_H1, hRSI_H1,
                    hStoch_H1, hCCI_H1, hVol_H1, hOBV_H1, hBB_H1, hATR_H1, resultH1);
   AnalyzeTimeframe(PERIOD_H4, hEMA50_H4, hEMA200_H4, hMACD_H4, hADX_H4, hRSI_H4,
                    hStoch_H4, hCCI_H4, hVol_H4, hOBV_H4, hBB_H4, hATR_H4, resultH4);
   AnalyzeTimeframe(PERIOD_D1, hEMA50_D1, hEMA200_D1, hMACD_D1, hADX_D1, hRSI_D1,
                    hStoch_D1, hCCI_D1, hVol_D1, hOBV_D1, hBB_D1, hATR_D1, resultD1);
   
   UpdatePanel();
   ChartRedraw();
}

//+------------------------------------------------------------------+
void AnalyzeTimeframe(ENUM_TIMEFRAMES tf, int hEMA50, int hEMA200, int hMACD, int hADX, int hRSI,
                      int hStoch, int hCCI, int hVol, int hOBV, int hBB, int hATR, IndicatorVotes &result)
{
   double bufEMA50[], bufEMA200[], bufClose[];
   double bufMACDMain[], bufMACDSig[];
   double bufADX[], bufPlusDI[], bufMinusDI[];
   double bufRSI[], bufStochK[], bufStochD[], bufCCI[];
   double bufVol[], bufOBV[];
   double bufBBUpper[], bufBBMiddle[], bufBBLower[];
   double bufATR[];
   
   ArraySetAsSeries(bufEMA50, true);   ArraySetAsSeries(bufEMA200, true);
   ArraySetAsSeries(bufMACDMain, true); ArraySetAsSeries(bufMACDSig, true);
   ArraySetAsSeries(bufADX, true);     ArraySetAsSeries(bufPlusDI, true); ArraySetAsSeries(bufMinusDI, true);
   ArraySetAsSeries(bufRSI, true);
   ArraySetAsSeries(bufStochK, true);  ArraySetAsSeries(bufStochD, true);
   ArraySetAsSeries(bufCCI, true);
   ArraySetAsSeries(bufVol, true);
   ArraySetAsSeries(bufOBV, true);
   ArraySetAsSeries(bufBBUpper, true); ArraySetAsSeries(bufBBMiddle, true); ArraySetAsSeries(bufBBLower, true);
   ArraySetAsSeries(bufClose, true);
   ArraySetAsSeries(bufATR, true);
   
   if(CopyBuffer(hEMA50, 0, 0, 3, bufEMA50) < 3) return;
   if(CopyBuffer(hEMA200, 0, 0, 3, bufEMA200) < 3) return;
   if(CopyBuffer(hMACD, 0, 0, 3, bufMACDMain) < 3) return;
   if(CopyBuffer(hMACD, 1, 0, 3, bufMACDSig) < 3) return;
   if(CopyBuffer(hADX, 0, 0, 3, bufADX) < 3) return;
   if(CopyBuffer(hADX, 1, 0, 3, bufPlusDI) < 3) return;
   if(CopyBuffer(hADX, 2, 0, 3, bufMinusDI) < 3) return;
   if(CopyBuffer(hRSI, 0, 0, 3, bufRSI) < 3) return;
   if(CopyBuffer(hStoch, 0, 0, 3, bufStochK) < 3) return;
   if(CopyBuffer(hStoch, 1, 0, 3, bufStochD) < 3) return;
   if(CopyBuffer(hCCI, 0, 0, 3, bufCCI) < 3) return;
   if(CopyBuffer(hVol, 0, 0, 3, bufVol) < 3) return;
   if(CopyBuffer(hOBV, 0, 0, 3, bufOBV) < 3) return;
   if(CopyBuffer(hBB, 0, 0, 3, bufBBMiddle) < 3) return;
   if(CopyBuffer(hBB, 1, 0, 3, bufBBUpper) < 3) return;
   if(CopyBuffer(hBB, 2, 0, 3, bufBBLower) < 3) return;
   if(CopyBuffer(hATR, 0, 0, 3, bufATR) < 3) return;
   if(CopyClose(_Symbol, tf, 0, 3, bufClose) < 3) return;
   
   result.votes[0] = (bufClose[1] > bufEMA50[1]) ? 1 : -1;
   result.votes[1] = (bufClose[1] > bufEMA200[1]) ? 1 : -1;
   
   if(bufMACDMain[2] < bufMACDSig[2] && bufMACDMain[1] > bufMACDSig[1]) result.votes[2] = 1;
   else if(bufMACDMain[2] > bufMACDSig[2] && bufMACDMain[1] < bufMACDSig[1]) result.votes[2] = -1;
   else result.votes[2] = (bufMACDMain[1] > bufMACDSig[1]) ? 1 : -1;
   
   if(bufADX[1] > 25)
      result.votes[3] = (bufPlusDI[1] > bufMinusDI[1]) ? 1 : -1;
   else
      result.votes[3] = 0;
   
   if(bufRSI[1] > 70) result.votes[4] = -1;
   else if(bufRSI[1] < 30) result.votes[4] = 1;
   else result.votes[4] = (bufRSI[1] > 50) ? 1 : -1;
   
   if(bufStochK[2] < bufStochD[2] && bufStochK[1] > bufStochD[1] && bufStochK[1] < 30) result.votes[5] = 1;
   else if(bufStochK[2] > bufStochD[2] && bufStochK[1] < bufStochD[1] && bufStochK[1] > 70) result.votes[5] = -1;
   else result.votes[5] = 0;
   
   if(bufCCI[1] > 100) result.votes[6] = 1;
   else if(bufCCI[1] < -100) result.votes[6] = -1;
   else result.votes[6] = 0;
   
   if(bufVol[1] > bufVol[2] * 1.2)
      result.votes[7] = (bufClose[1] > bufClose[2]) ? 1 : -1;
   else
      result.votes[7] = 0;
   
   result.votes[8] = (bufOBV[1] > bufOBV[2]) ? 1 : -1;
   
   if(bufClose[1] <= bufBBLower[1]) result.votes[9] = 1;
   else if(bufClose[1] >= bufBBUpper[1]) result.votes[9] = -1;
   else result.votes[9] = 0;
   
   result.totalSum = 0;
   for(int i = 0; i < 10; i++) result.totalSum += result.votes[i];
   
   if(result.totalSum >= 5)       result.signal = "STRONG BUY";
   else if(result.totalSum >= 3)  result.signal = "BUY";
   else if(result.totalSum <= -5) result.signal = "STRONG SELL";
   else if(result.totalSum <= -3) result.signal = "SELL";
   else                           result.signal = "HOLD";
   
   double atrValue = bufATR[1];
   double priceRange = bufBBUpper[1] - bufBBLower[1];
   
   int baseCandles = MathAbs(result.totalSum);
   double volatilityFactor = (priceRange > 0) ? atrValue / (priceRange * 0.1) : 1.0;
   
   if(volatilityFactor > 1.5)
      result.candlesForecast = (int)(baseCandles * 0.7);
   else if(volatilityFactor < 0.5)
      result.candlesForecast = (int)(baseCandles * 1.5);
   else
      result.candlesForecast = baseCandles;
   
   if(result.candlesForecast < 1) result.candlesForecast = 1;
   if(result.candlesForecast > 10) result.candlesForecast = 10;
   
   result.currentPrice = bufClose[1];
   
   double multiplier = 0;
   if(result.totalSum >= 5) multiplier = 2.5;
   else if(result.totalSum >= 3) multiplier = 1.8;
   else if(result.totalSum <= -5) multiplier = 2.5;
   else if(result.totalSum <= -3) multiplier = 1.8;
   
   multiplier *= (result.candlesForecast / 5.0);
   
   if(result.totalSum > 0)
   {
      result.targetPrice = result.currentPrice + (atrValue * multiplier);
      if(result.targetPrice > bufBBUpper[1] * 1.02)
         result.targetPrice = bufBBUpper[1] * 1.02;
   }
   else if(result.totalSum < 0)
   {
      result.targetPrice = result.currentPrice - (atrValue * multiplier);
      if(result.targetPrice < bufBBLower[1] * 0.98)
         result.targetPrice = bufBBLower[1] * 0.98;
   }
   else
   {
      result.targetPrice = result.currentPrice;
   }
}

//+------------------------------------------------------------------+
void CreatePanel()
{
   ObjectCreate(0, panelName+"_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_XDISTANCE, panelX);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YDISTANCE, panelY);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YSIZE, panelHeightExpanded);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_BGCOLOR, C'20,20,30');
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_COLOR, C'60,60,80');
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_BACK, false);
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Создание кнопки свернуть/развернуть                             |
//+------------------------------------------------------------------+
void CreateCollapseButton()
{
   ObjectCreate(0, buttonName, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, buttonName, OBJPROP_XDISTANCE, panelX + panelWidth - 35);
   ObjectSetInteger(0, buttonName, OBJPROP_YDISTANCE, panelY + 3);
   ObjectSetInteger(0, buttonName, OBJPROP_XSIZE, 30);
   ObjectSetInteger(0, buttonName, OBJPROP_YSIZE, 28);
   ObjectSetString(0, buttonName, OBJPROP_TEXT, "▼");
   ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, buttonName, OBJPROP_BGCOLOR, C'40,40,60');
   ObjectSetInteger(0, buttonName, OBJPROP_BORDER_COLOR, C'80,80,100');
   ObjectSetString(0, buttonName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, buttonName, OBJPROP_FONTSIZE, 12);
   ObjectSetInteger(0, buttonName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, buttonName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, buttonName, OBJPROP_STATE, false);
}

//+------------------------------------------------------------------+
//| Обновление состояния кнопки                                     |
//+------------------------------------------------------------------+
void UpdateCollapseButton()
{
   if(isCollapsed)
   {
      ObjectSetString(0, buttonName, OBJPROP_TEXT, "▲");
      ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrOrange);
   }
   else
   {
      ObjectSetString(0, buttonName, OBJPROP_TEXT, "▼");
      ObjectSetInteger(0, buttonName, OBJPROP_COLOR, clrYellow);
   }
   
   // Меняем размер фона панели
   int newHeight = isCollapsed ? panelHeightCollapsed : panelHeightExpanded;
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YSIZE, newHeight);
}

//+------------------------------------------------------------------+
void UpdatePanel()
{
   // Обновляем размер фона
   int currentHeight = isCollapsed ? panelHeightCollapsed : panelHeightExpanded;
   ObjectSetInteger(0, panelName+"_BG", OBJPROP_YSIZE, currentHeight);
   
   int y = panelY + 10;
   int lineHeight = 20;
   string priceFormat = "%." + IntegerToString(symbolDigits) + "f";
   
   //=== ВСЕГДА ПОКАЗЫВАЕМ ЗАГОЛОВОК ===
   string title = "═══ " + currentSymbol + " (" + symbolType + ") ═══";
   CreateLabel(panelName+"_Title", title, panelX + 10, y, clrYellow, 11);
   
   if(isCollapsed)
   {
      //=== СВЕРНУТОЕ СОСТОЯНИЕ ===
      // Показываем только краткую информацию: текущий сигнал H1
      string shortInfo = "";
      color shortColor = clrGray;
      
      if(resultH1.totalSum >= 5)       { shortInfo = "▲ STRONG BUY"; shortColor = clrLime; }
      else if(resultH1.totalSum >= 3)  { shortInfo = "▲ BUY";        shortColor = clrGreen; }
      else if(resultH1.totalSum <= -5) { shortInfo = "▼ STRONG SELL"; shortColor = clrRed; }
      else if(resultH1.totalSum <= -3) { shortInfo = "▼ SELL";       shortColor = clrDarkRed; }
      else                             { shortInfo = "● HOLD";       shortColor = clrGray; }
      
      CreateLabel(panelName+"_ShortInfo", shortInfo, panelX + 250, y, shortColor, 10);
      
      // Скрываем все остальные элементы
      HideAllDetails();
   }
   else
   {
      //=== РАЗВЕРНУТОЕ СОСТОЯНИЕ ===
      ShowAllDetails(y, lineHeight, priceFormat);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Скрывает все детальные элементы панели                          |
//+------------------------------------------------------------------+
void HideAllDetails()
{
   string prefixes[] = {"_Time", "_Type", "_Session", "_Spread", "_Point", "_Sep0",
                        "_Col1", "_Col2", "_Col3", "_Col4", "_Sep1",
                        "_TF_", "_Sum", "_Signal", "_Forecast", "_Price",
                        "_Sep2", "_Sep3", "_Sep4"};
   
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, panelName) == 0 && StringFind(name, "_BG") < 0 && StringFind(name, "_Title") < 0)
      {
         // Проверяем, не является ли это элементом краткой информации
         if(StringFind(name, "_ShortInfo") < 0)
         {
            // Скрываем H1, H4, D1 элементы и разделители
            bool shouldHide = false;
            for(int p = 0; p < ArraySize(prefixes); p++)
            {
               if(StringFind(name, prefixes[p]) >= 0)
               {
                  // Исключаем заголовок и кнопку
                  if(StringFind(name, "_TF_H1") < 0 && StringFind(name, "_TF_H4") < 0 && StringFind(name, "_TF_D1") < 0)
                  {
                     shouldHide = true;
                     break;
                  }
               }
            }
            // Скрываем все H1/H4/D1 элементы
            if(StringFind(name, "_H1_") >= 0 || StringFind(name, "_H4_") >= 0 || StringFind(name, "_D1_") >= 0)
               shouldHide = true;
               
            if(shouldHide)
               ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS); // Скрываем
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Показывает все детальные элементы панели                        |
//+------------------------------------------------------------------+
void ShowAllDetails(int startY, int lineHeight, string priceFormat)
{
   // Сначала показываем все скрытые объекты
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, panelName) == 0)
         ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
   }
   
   // Скрываем краткую информацию
   ObjectSetInteger(0, panelName+"_ShortInfo", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
   
   int y = startY + lineHeight + 3;
   
   //=== БЛОК ИНФОРМАЦИИ О ПАРЕ ===
   CreateLabel(panelName+"_Type", "Тип: " + symbolType, panelX + 10, y, clrLightSkyBlue, 9);
   CreateLabel(panelName+"_Session", currentSession + " | " + DetectDayOfWeek(), 
               panelX + 230, y, clrWheat, 9);
   y += lineHeight;
   
   string spreadStr = "Спред: " + IntegerToString(symbolSpread) + " pts";
   CreateLabel(panelName+"_Spread", spreadStr, panelX + 10, y, clrLightGray, 9);
   
   string pointStr = "Point: " + DoubleToString(symbolPoint, symbolDigits);
   CreateLabel(panelName+"_Point", pointStr, panelX + 230, y, clrLightGray, 9);
   y += lineHeight;
   
   CreateLabel(panelName+"_Time", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS), 
               panelX + 10, y, clrGray, 9);
   y += lineHeight + 5;
   
   CreateLabel(panelName+"_Sep0", "═══════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
   y += lineHeight;
   
   CreateLabel(panelName+"_Col1", "ТФ", panelX + 20, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col2", "СИГНАЛЫ", panelX + 80, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col3", "Σ", panelX + 255, y, clrDodgerBlue, 10);
   CreateLabel(panelName+"_Col4", "ПРОГНОЗ", panelX + 290, y, clrDodgerBlue, 10);
   y += lineHeight + 5;
   
   CreateLabel(panelName+"_Sep1", "─────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   DrawTFRow("H1", resultH1, "H1", y, priceFormat, lineHeight);
   y += lineHeight * 3 + 5;
   
   CreateLabel(panelName+"_Sep2", "─────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   DrawTFRow("H4", resultH4, "H4", y, priceFormat, lineHeight);
   y += lineHeight * 3 + 5;
   
   CreateLabel(panelName+"_Sep3", "─────────────────────────────────────────────────", 
               panelX + 10, y, clrGray, 9);
   y += lineHeight;
   
   DrawTFRow("D1", resultD1, "D1", y, priceFormat, lineHeight);
   y += lineHeight * 3 + 5;
   
   CreateLabel(panelName+"_Sep4", "═══════════════════════════════════════════════", 
               panelX + 10, y, clrDodgerBlue, 9);
}

//+------------------------------------------------------------------+
void DrawTFRow(string tfLabel, IndicatorVotes &result, string prefix, int y, string priceFormat, int lineHeight)
{
   CreateLabel(panelName+"_TF_"+prefix, tfLabel, panelX + 25, y, clrWhite, 11);
   
   int xSignals = panelX + 80;
   for(int i = 0; i < 10; i++)
   {
      color c = (result.votes[i] > 0) ? clrLime : (result.votes[i] < 0) ? clrRed : clrGray;
      string s = (result.votes[i] > 0) ? "▲" : (result.votes[i] < 0) ? "▼" : "●";
      CreateLabel(panelName+"_"+prefix+"_"+IntegerToString(i), s, xSignals + i*16, y, c, 10);
   }
   
   color sumColor = (result.totalSum > 0) ? clrLime : (result.totalSum < 0) ? clrRed : clrGray;
   CreateLabel(panelName+"_Sum"+prefix, StringFormat("%+d", result.totalSum), panelX + 255, y, sumColor, 11);
   
   color sigColor = GetSignalColor(result.signal);
   CreateLabel(panelName+"_Signal"+prefix, result.signal, panelX + 290, y, sigColor, 10);
   y += lineHeight;
   
   CreateLabel(panelName+"_Forecast"+prefix, StringFormat("%d свечей", result.candlesForecast), 
               panelX + 290, y, clrOrange, 9);
   y += lineHeight;
   
   string priceStr = StringFormat(priceFormat + " → " + priceFormat, result.currentPrice, result.targetPrice);
   color priceColor = (result.targetPrice > result.currentPrice) ? clrLime : 
                      (result.targetPrice < result.currentPrice) ? clrRed : clrGray;
   CreateLabel(panelName+"_Price"+prefix, priceStr, panelX + 80, y, priceColor, 9);
}

//+------------------------------------------------------------------+
color GetSignalColor(string signal)
{
   if(signal == "STRONG BUY") return clrLime;
   if(signal == "BUY") return clrGreen;
   if(signal == "STRONG SELL") return clrRed;
   if(signal == "SELL") return clrDarkRed;
   return clrGray;
}

//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
}

//+------------------------------------------------------------------+
void DeletePanel()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, panelName) == 0 || name == buttonName)
         ObjectDelete(0, name);
   }
}
//+------------------------------------------------------------------+