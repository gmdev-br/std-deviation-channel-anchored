//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Anchored Standard Deviation Channel"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 51
#property indicator_plots   51

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum MY_TIMEFRAME {
   M1      = PERIOD_M1,       // 1 minuto
   M5      = PERIOD_M5,       // 5 minutos
   M15     = PERIOD_M15,      // 15 minutos
   M30     = PERIOD_M30,      // 30 minutos
   H1      = PERIOD_H1,       // 1 hora
   H2      = PERIOD_H2,       // 2 horas
   H3      = PERIOD_H3,       // 3 horas
   H4      = PERIOD_H4,       // 4 horas
   H6      = PERIOD_H6,       // 6 horas
   H8      = PERIOD_H8,       // 8 horas
   H12     = PERIOD_H12,       // 12 horas
   D1      = PERIOD_D1,       // Diário
   W1      = PERIOD_W1,       // Semanal
   MN1     = PERIOD_MN1       // Mensal
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input group "****************************  Configurações  ****************************"
input datetime data_inicial = "2021.11.1 9:00:00";         // Data inicial
input datetime data_final = "2021.11.03 9:00:00";         // Data final
input double step = 1; // Tamanho do desvio
input double numero_desvios = 1; // Número de desvios a serem exibidos
input double primeiro_desvio  = 0; // Offset para início do canal
input double dolpt = 0; // Cotação do dólar

input group "****************************  Exibição  ****************************"
input   bool        enable_rays  = true; // Exibe extensão à direita
input ENUM_ANCHOR_POINT InpAnchor = ANCHOR_LEFT; // Tipo de ancoragem

input group "****************************  Cor da linha  ****************************"
input color             ColorUpFull = clrLime;    // Banda superior - inteira
input color             ColorUpHalf = clrDarkGray;    // Banda superior - metade
input color             ColorCenter = clrYellow;    // Linha central
input color             ColorDownHalf = clrDarkGray;    // Banda inferior - metade
input color             ColorDownFull = clrRed;    // Banda inferior - inteira

input group "****************************  Tipo da linha  ****************************"
input ENUM_LINE_STYLE StyleUpFull             = STYLE_SOLID; // Banda superior - inteira
input ENUM_LINE_STYLE StyleUpHalf             = STYLE_DOT; // Banda superior - metade
input ENUM_LINE_STYLE StyleCenter            = STYLE_SOLID; // Linha central
input ENUM_LINE_STYLE StyleDownHalf            = STYLE_DOT; // Banda superior - metade
input ENUM_LINE_STYLE StyleDownFull            = STYLE_SOLID; // Banda superior - inteira

input group "****************************  Espessura da linha  ****************************"
input int            WidthUpFull              = 1; // Banda superior - inteira
input int            WidthUpHalf              = 1; // Banda superior - metade
input int            WidthCenter              = 1; // Linha central
input int            WidthDownHalf              = 1; // Banda superior - metade
input int            WidthDownFull              = 1; // Banda superior - inteira

input group "****************************  Projeção  ****************************"
input   bool        exibe_projecao  = true; // Exibe uma projeção percentual
input double            projsup1              = 1.5; // Banda superior - inteira
input double            projsup2              = 2; // Banda superior - inteira
input double            projsup3              = 2.5; // Banda superior - inteira
input double            projsup4              = 3; // Banda superior - inteira
input double            projsup5              = 4; // Banda superior - inteira
input double            projinf1              = -1.5; // Banda superior - inteira
input double            projinf2              = -2; // Banda superior - inteira
input double            projinf3              = -2.5; // Banda superior - inteira
input double            projinf4              = -3; // Banda superior - inteira
input double            projinf5              = -4; // Banda superior - inteira

input group "****************************  Cor da linha  ****************************"
input color             ColorProjUp = clrLime;    // Banda superior - inteira
input color             ColorProjDown = clrRed;    // Banda superior - metade

input group "****************************  Tipo da linha  ****************************"
input ENUM_LINE_STYLE StyleProjUp             = STYLE_SOLID; // Banda superior - inteira
input ENUM_LINE_STYLE StyleProjDown            = STYLE_SOLID; // Banda superior - metade

input group "****************************  Espessura da linha  ****************************"
input int            WidthProjUp              = 1; // Banda superior - inteira
input int            WidthProjDown              = 1; // Banda superior - inteira

input int   ThrottleRedraw           = 30;      // ThrottleRedraw: delay (in seconds) for updating Market Profile.

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//--- indicator buffers
double      midBuffer[];
double      supBuffer1[],  supBuffer2[], supBuffer3[], supBuffer4[], supBuffer5[], supBuffer6[], supBuffer7[], supBuffer8[], supBuffer9[], supBuffer10[];
double      supBuffer11[],  supBuffer12[], supBuffer13[], supBuffer14[], supBuffer15[], supBuffer16[], supBuffer17[], supBuffer18[], supBuffer19[], supBuffer20[];
double      infBuffer1[], infBuffer2[], infBuffer3[], infBuffer4[], infBuffer5[], infBuffer6[], infBuffer7[], infBuffer8[], infBuffer9[], infBuffer10[];
double      infBuffer11[], infBuffer12[], infBuffer13[], infBuffer14[], infBuffer15[], infBuffer16[], infBuffer17[], infBuffer18[], infBuffer19[], infBuffer20[];

double      projsupBuffer1[], projsupBuffer2[], projsupBuffer3[], projsupBuffer4[], projsupBuffer5[];
double      projinfBuffer1[], projinfBuffer2[], projinfBuffer3[], projinfBuffer4[], projinfBuffer5[];

double      sample[];//sample data for calculating linear regression
//---
int         StartBar = 0;
int         CalcBars = 0;
int         limite_inicial;
int         limite_final;
int         n;
datetime    tempo;

//---- declaration of the integer variables for the start of data calculation
//int min_rates_total;
int         min_rates_inicial;
int         min_rates_final;
int         TimerDP = 0;                      // For throttling updates of market profiles in slow systems.

//+------------------------------------------------------------------+
//| iBarShift2() function                                             |
//+------------------------------------------------------------------+
int iBarShift2(string symbol, ENUM_TIMEFRAMES timeframe, datetime time) {
   if(time < 0) {
      return(-1);
   }
   datetime Arr[], time1;

   time1 = (datetime)SeriesInfoInteger(symbol, timeframe, SERIES_LASTBAR_DATE);

   if(CopyTime(symbol, timeframe, time, time1, Arr) > 0) {
      int size = ArraySize(Arr);
      return(size - 1);
   } else {
      return(-1);
   }
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

//bool setTimer = EventSetTimer(60);
//---- initializations of a variable for the indicator short name
   string shortname = "Canal de desvio-padrão ancorado";
//---- creating a name for displaying in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME, shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);

   StartBar  = 0;

   if(CalcBars < 2)
      CalcBars = 100;

   if(StartBar < 0)
      StartBar = 0;

   ArrayResize(sample, CalcBars);

   min_rates_inicial = 1;

   SetIndexBuffer(20, supBuffer20, INDICATOR_DATA);
   PlotIndexSetInteger(20, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(20, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(20, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer20, true);
   PlotIndexSetInteger(20, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(20, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(20, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(20, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(20, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(19, supBuffer19, INDICATOR_DATA);
   PlotIndexSetInteger(19, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(19, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(19, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer19, true);
   PlotIndexSetInteger(19, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(19, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(19, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(19, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(19, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(18, supBuffer18, INDICATOR_DATA);
   PlotIndexSetInteger(18, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(18, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(18, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer18, true);
   PlotIndexSetInteger(18, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(18, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(18, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(18, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(18, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(17, supBuffer17, INDICATOR_DATA);
   PlotIndexSetInteger(17, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(17, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(17, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer17, true);
   PlotIndexSetInteger(17, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(17, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(17, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(17, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(17, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(16, supBuffer16, INDICATOR_DATA);
   PlotIndexSetInteger(16, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(16, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(16, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer16, true);
   PlotIndexSetInteger(16, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(16, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(16, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(16, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(16, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(15, supBuffer15, INDICATOR_DATA);
   PlotIndexSetInteger(15, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(15, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(15, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer15, true);
   PlotIndexSetInteger(15, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(15, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(15, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(15, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(15, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(14, supBuffer14, INDICATOR_DATA);
   PlotIndexSetInteger(14, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(14, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(14, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer14, true);
   PlotIndexSetInteger(14, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(14, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(14, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(14, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(14, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(13, supBuffer13, INDICATOR_DATA);
   PlotIndexSetInteger(13, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(13, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(13, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer13, true);
   PlotIndexSetInteger(13, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(13, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(13, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(13, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(13, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(12, supBuffer12, INDICATOR_DATA);
   PlotIndexSetInteger(12, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(12, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(12, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer12, true);
   PlotIndexSetInteger(12, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(12, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(12, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(12, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(12, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(11, supBuffer11, INDICATOR_DATA);
   PlotIndexSetInteger(11, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(11, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(11, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer11, true);
   PlotIndexSetInteger(11, PLOT_LINE_COLOR, ColorUpHalf);
   PlotIndexSetDouble(11, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(11, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(11, PLOT_LINE_WIDTH, WidthUpHalf);
   PlotIndexSetInteger(11, PLOT_LINE_STYLE, StyleUpHalf);

   SetIndexBuffer(10, supBuffer10, INDICATOR_DATA);
   PlotIndexSetInteger(10, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(10, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(10, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer10, true);
   PlotIndexSetInteger(10, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(10, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(10, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(10, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(10, PLOT_LINE_STYLE, StyleUpFull);

   SetIndexBuffer(9, supBuffer9, INDICATOR_DATA);
   PlotIndexSetInteger(9, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(9, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(9, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer9, true);
   PlotIndexSetInteger(9, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(9, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(9, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(9, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(9, PLOT_LINE_STYLE, StyleUpFull);

   SetIndexBuffer(8, supBuffer8, INDICATOR_DATA);
   PlotIndexSetInteger(8, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(8, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(8, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer8, true);
   PlotIndexSetInteger(8, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(8, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(8, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(8, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(8, PLOT_LINE_STYLE, StyleUpFull);

   SetIndexBuffer(7, supBuffer7, INDICATOR_DATA);
   PlotIndexSetInteger(7, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(7, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(7, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer7, true);
   PlotIndexSetInteger(7, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(7, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(7, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(7, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(7, PLOT_LINE_STYLE, StyleUpFull);

   SetIndexBuffer(6, supBuffer6, INDICATOR_DATA);
   PlotIndexSetInteger(6, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(6, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(6, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer6, true);
   PlotIndexSetInteger(6, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(6, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(6, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(6, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(6, PLOT_LINE_STYLE, StyleUpFull);

   SetIndexBuffer(5, supBuffer5, INDICATOR_DATA);
   PlotIndexSetInteger(5, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(5, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer5, true);
   PlotIndexSetInteger(5, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(5, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(5, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(5, PLOT_LINE_STYLE, StyleUpFull);

   SetIndexBuffer(4, supBuffer4, INDICATOR_DATA);
   PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(4, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer4, true);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(4, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(4, PLOT_LINE_STYLE, StyleUpFull);

   SetIndexBuffer(3, supBuffer3, INDICATOR_DATA);
   PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(3, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer3, true);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(3, PLOT_LINE_STYLE, StyleUpFull);

   SetIndexBuffer(2, supBuffer2, INDICATOR_DATA);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(2, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer2, true);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(2, PLOT_LINE_STYLE, StyleUpFull);

   SetIndexBuffer(1, supBuffer1, INDICATOR_DATA);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(1, PLOT_SHIFT, 0);
   ArraySetAsSeries(supBuffer1, true);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, ColorUpFull);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, WidthUpFull);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, StyleUpFull);

//---- set midBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0, midBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(0, PLOT_SHIFT, 0);
   ArraySetAsSeries(midBuffer, true);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, ColorCenter);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, WidthCenter);
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, StyleCenter);

   SetIndexBuffer(21, infBuffer1, INDICATOR_DATA);
   PlotIndexSetInteger(21, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(21, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(21, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer1, true);
   PlotIndexSetInteger(21, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(21, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(21, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(21, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(21, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(22, infBuffer2, INDICATOR_DATA);
   PlotIndexSetInteger(22, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(22, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(22, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer2, true);
   PlotIndexSetInteger(22, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(22, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(22, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(22, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(22, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(23, infBuffer3, INDICATOR_DATA);
   PlotIndexSetInteger(23, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(23, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(23, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer3, true);
   PlotIndexSetInteger(23, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(23, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(23, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(23, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(23, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(24, infBuffer4, INDICATOR_DATA);
   PlotIndexSetInteger(24, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(24, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(24, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer4, true);
   PlotIndexSetInteger(24, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(24, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(24, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(24, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(24, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(25, infBuffer5, INDICATOR_DATA);
   PlotIndexSetInteger(25, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(25, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(25, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer5, true);
   PlotIndexSetInteger(25, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(25, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(25, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(25, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(25, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(26, infBuffer6, INDICATOR_DATA);
   PlotIndexSetInteger(26, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(26, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(26, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer6, true);
   PlotIndexSetInteger(26, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(26, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(26, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(26, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(26, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(27, infBuffer7, INDICATOR_DATA);
   PlotIndexSetInteger(27, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(27, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(27, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer7, true);
   PlotIndexSetInteger(27, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(27, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(27, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(27, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(27, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(28, infBuffer8, INDICATOR_DATA);
   PlotIndexSetInteger(28, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(28, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(28, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer8, true);
   PlotIndexSetInteger(28, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(28, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(28, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(28, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(28, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(29, infBuffer9, INDICATOR_DATA);
   PlotIndexSetInteger(29, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(29, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(29, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer9, true);
   PlotIndexSetInteger(29, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(29, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(29, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(29, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(29, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(30, infBuffer10, INDICATOR_DATA);
   PlotIndexSetInteger(30, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(30, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(30, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer10, true);
   PlotIndexSetInteger(30, PLOT_LINE_COLOR, ColorDownFull);
   PlotIndexSetDouble(30, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(30, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(30, PLOT_LINE_WIDTH, WidthDownFull);
   PlotIndexSetInteger(30, PLOT_LINE_STYLE, StyleDownFull);

   SetIndexBuffer(31, infBuffer11, INDICATOR_DATA);
   PlotIndexSetInteger(31, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(31, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(31, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer11, true);
   PlotIndexSetInteger(31, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(31, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(31, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(31, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(31, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(32, infBuffer12, INDICATOR_DATA);
   PlotIndexSetInteger(32, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(32, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(32, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer12, true);
   PlotIndexSetInteger(32, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(32, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(32, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(32, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(32, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(33, infBuffer13, INDICATOR_DATA);
   PlotIndexSetInteger(33, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(33, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(33, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer13, true);
   PlotIndexSetInteger(33, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(33, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(33, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(33, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(33, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(34, infBuffer14, INDICATOR_DATA);
   PlotIndexSetInteger(34, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(34, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(34, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer14, true);
   PlotIndexSetInteger(34, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(34, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(34, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(34, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(34, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(35, infBuffer15, INDICATOR_DATA);
   PlotIndexSetInteger(35, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(35, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(35, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer15, true);
   PlotIndexSetInteger(35, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(35, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(35, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(35, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(35, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(36, infBuffer16, INDICATOR_DATA);
   PlotIndexSetInteger(36, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(36, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(36, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer16, true);
   PlotIndexSetInteger(36, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(36, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(36, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(36, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(36, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(37, infBuffer17, INDICATOR_DATA);
   PlotIndexSetInteger(37, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(37, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(37, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer17, true);
   PlotIndexSetInteger(37, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(37, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(37, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(37, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(37, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(38, infBuffer18, INDICATOR_DATA);
   PlotIndexSetInteger(38, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(38, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(38, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer18, true);
   PlotIndexSetInteger(38, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(38, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(38, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(38, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(38, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(39, infBuffer19, INDICATOR_DATA);
   PlotIndexSetInteger(39, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(39, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(39, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer19, true);
   PlotIndexSetInteger(39, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(39, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(39, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(39, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(39, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(40, infBuffer20, INDICATOR_DATA);
   PlotIndexSetInteger(40, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(40, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(40, PLOT_SHIFT, 0);
   ArraySetAsSeries(infBuffer20, true);
   PlotIndexSetInteger(40, PLOT_LINE_COLOR, ColorDownHalf);
   PlotIndexSetDouble(40, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(40, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(40, PLOT_LINE_WIDTH, WidthDownHalf);
   PlotIndexSetInteger(40, PLOT_LINE_STYLE, StyleDownHalf);

   SetIndexBuffer(41, projsupBuffer1, INDICATOR_DATA);
   PlotIndexSetInteger(41, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(41, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(41, PLOT_SHIFT, 0);
   ArraySetAsSeries(projsupBuffer1, true);
   PlotIndexSetInteger(41, PLOT_LINE_COLOR, ColorProjUp);
   PlotIndexSetDouble(41, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(41, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(41, PLOT_LABEL, "projeção " + projsup1 * 100 + "%");
   PlotIndexSetInteger(41, PLOT_LINE_WIDTH, WidthProjUp);
   PlotIndexSetInteger(41, PLOT_LINE_STYLE, StyleProjUp);

   SetIndexBuffer(42, projsupBuffer2, INDICATOR_DATA);
   PlotIndexSetInteger(42, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(42, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(42, PLOT_SHIFT, 0);
   ArraySetAsSeries(projsupBuffer2, true);
   PlotIndexSetInteger(42, PLOT_LINE_COLOR, ColorProjUp);
   PlotIndexSetDouble(42, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(42, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(42, PLOT_LABEL, "projeção " + projsup2 * 100 + "%");
   PlotIndexSetInteger(42, PLOT_LINE_WIDTH, WidthProjUp);
   PlotIndexSetInteger(42, PLOT_LINE_STYLE, StyleProjUp);

   SetIndexBuffer(43, projsupBuffer3, INDICATOR_DATA);
   PlotIndexSetInteger(43, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(43, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(43, PLOT_SHIFT, 0);
   ArraySetAsSeries(projsupBuffer3, true);
   PlotIndexSetInteger(43, PLOT_LINE_COLOR, ColorProjUp);
   PlotIndexSetDouble(43, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(43, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(43, PLOT_LABEL, "projeção " + projsup3 * 100 + "%");
   PlotIndexSetInteger(43, PLOT_LINE_WIDTH, WidthProjUp);
   PlotIndexSetInteger(43, PLOT_LINE_STYLE, StyleProjUp);

   SetIndexBuffer(44, projsupBuffer4, INDICATOR_DATA);
   PlotIndexSetInteger(44, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(44, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(44, PLOT_SHIFT, 0);
   ArraySetAsSeries(projsupBuffer4, true);
   PlotIndexSetInteger(44, PLOT_LINE_COLOR, ColorProjUp);
   PlotIndexSetDouble(44, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(44, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(44, PLOT_LABEL, "projeção " + projsup4 * 100 + "%");
   PlotIndexSetInteger(44, PLOT_LINE_WIDTH, WidthProjUp);
   PlotIndexSetInteger(44, PLOT_LINE_STYLE, StyleProjUp);

   SetIndexBuffer(45, projsupBuffer5, INDICATOR_DATA);
   PlotIndexSetInteger(45, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(45, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(45, PLOT_SHIFT, 0);
   ArraySetAsSeries(projsupBuffer5, true);
   PlotIndexSetInteger(45, PLOT_LINE_COLOR, ColorProjUp);
   PlotIndexSetDouble(45, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(45, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(45, PLOT_LABEL, "projeção " + projsup5 * 100 + "%");
   PlotIndexSetInteger(45, PLOT_LINE_WIDTH, WidthProjUp);
   PlotIndexSetInteger(45, PLOT_LINE_STYLE, StyleProjUp);

   SetIndexBuffer(46, projinfBuffer1, INDICATOR_DATA);
   PlotIndexSetInteger(46, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(46, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(46, PLOT_SHIFT, 0);
   ArraySetAsSeries(projinfBuffer1, true);
   PlotIndexSetInteger(46, PLOT_LINE_COLOR, ColorProjDown);
   PlotIndexSetDouble(46, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(46, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(46, PLOT_LABEL, "projeção " + projinf1 * 100 + "%");
   PlotIndexSetInteger(46, PLOT_LINE_WIDTH, WidthProjDown);
   PlotIndexSetInteger(46, PLOT_LINE_STYLE, StyleProjDown);


   SetIndexBuffer(47, projinfBuffer2, INDICATOR_DATA);
   PlotIndexSetInteger(47, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(47, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(47, PLOT_SHIFT, 0);
   ArraySetAsSeries(projinfBuffer2, true);
   PlotIndexSetInteger(47, PLOT_LINE_COLOR, ColorProjDown);
   PlotIndexSetDouble(47, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(47, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(47, PLOT_LABEL, "projeção " + projinf2 * 100 + "%");
   PlotIndexSetInteger(47, PLOT_LINE_WIDTH, WidthProjDown);
   PlotIndexSetInteger(47, PLOT_LINE_STYLE, StyleProjDown);

   SetIndexBuffer(48, projinfBuffer3, INDICATOR_DATA);
   PlotIndexSetInteger(48, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(48, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(48, PLOT_SHIFT, 0);
   ArraySetAsSeries(projinfBuffer3, true);
   PlotIndexSetInteger(48, PLOT_LINE_COLOR, ColorProjDown);
   PlotIndexSetDouble(48, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(48, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(48, PLOT_LABEL, "projeção " + projinf3 * 100 + "%");
   PlotIndexSetInteger(48, PLOT_LINE_WIDTH, WidthProjDown);
   PlotIndexSetInteger(48, PLOT_LINE_STYLE, StyleProjDown);

   SetIndexBuffer(49, projinfBuffer4, INDICATOR_DATA);
   PlotIndexSetInteger(49, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(49, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(49, PLOT_SHIFT, 0);
   ArraySetAsSeries(projinfBuffer4, true);
   PlotIndexSetInteger(49, PLOT_LINE_COLOR, ColorProjDown);
   PlotIndexSetDouble(49, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(49, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(49, PLOT_LABEL, "projeção " + projinf4 * 100 + "%");
   PlotIndexSetInteger(49, PLOT_LINE_WIDTH, WidthProjDown);
   PlotIndexSetInteger(49, PLOT_LINE_STYLE, StyleProjDown);

   SetIndexBuffer(50, projinfBuffer5, INDICATOR_DATA);
   PlotIndexSetInteger(50, PLOT_DRAW_BEGIN, 0);
   PlotIndexSetDouble(50, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(50, PLOT_SHIFT, 0);
   ArraySetAsSeries(projinfBuffer5, true);
   PlotIndexSetInteger(50, PLOT_LINE_COLOR, ColorProjDown);
   PlotIndexSetDouble(50, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetInteger(50, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetString(50, PLOT_LABEL, "projeção " + projinf5 * 100 + "%");
   PlotIndexSetInteger(50, PLOT_LINE_WIDTH, WidthProjDown);
   PlotIndexSetInteger(50, PLOT_LINE_STYLE, StyleProjDown);

   return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {

   int i;
   limite_inicial = prev_calculated;
   limite_final;

//periodo;
   double A = 0.0, B = 0.0, stdev = 0.0;

// Delay the update of Market Profile if ThrottleRedraw is given.
   if ((ThrottleRedraw > 0) && (TimerDP > 0)) {
      if ((int)TimeLocal() - TimerDP < ThrottleRedraw)
         return rates_total;
   }

//---- checking the number of bars to be enough for the calculation
   if(rates_total < min_rates_inicial)
      return(0);

//---- indexing elements in arrays as timeseries
   ArraySetAsSeries(time, true);
   if(rates_total == prev_calculated) {
      return(rates_total);
   } else {
      min_rates_inicial = iBarShift2(Symbol(), PERIOD_CURRENT, data_inicial) + 1;
      if(!min_rates_inicial) {
         min_rates_inicial = rates_total;
      }
      limite_inicial = min_rates_inicial - 1;
      min_rates_final = iBarShift2(Symbol(), PERIOD_CURRENT, data_final) + 1;
      if(!min_rates_final) {
         min_rates_final = rates_total;
      }
      limite_final = min_rates_final - 1;
   }

//---- indexing elements in arrays as timeseries
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   StartBar = limite_final;
   CalcBars = limite_inicial - StartBar;

   if(StartBar + CalcBars > rates_total - 1)
      return(0);

//explicitly initialize array buffer to zero
   if(prev_calculated > rates_total || prev_calculated <= 0) {

      //---- set the position, from which the indicator drawing starts
      // 41 buffers total
      PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(5, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(6, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(7, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(8, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(9, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(10, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(11, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(12, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(13, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(14, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(15, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(16, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(17, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(18, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(19, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(20, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(21, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(22, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(23, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(24, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(25, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(26, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(27, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(28, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(29, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(30, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(31, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(32, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(33, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(34, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(35, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(36, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(37, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(38, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(39, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(40, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);

      PlotIndexSetInteger(41, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(42, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(43, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(44, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(45, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(46, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(47, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(48, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(49, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);
      PlotIndexSetInteger(50, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);

      PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, rates_total - limite_inicial - 1);

   }

// queremos apagar todas as barras, sem exceção
   for(int n = 0; n < rates_total; n++) {

      supBuffer20[n] = 0.0;
      supBuffer19[n] = 0.0;
      supBuffer18[n] = 0.0;
      supBuffer17[n] = 0.0;
      supBuffer16[n] = 0.0;
      supBuffer15[n] = 0.0;
      supBuffer14[n] = 0.0;
      supBuffer13[n] = 0.0;
      supBuffer12[n] = 0.0;
      supBuffer11[n] = 0.0;
      supBuffer10[n] = 0.0;
      supBuffer9[n] = 0.0;
      supBuffer8[n] = 0.0;
      supBuffer7[n] = 0.0;
      supBuffer6[n] = 0.0;
      supBuffer5[n] = 0.0;
      supBuffer4[n] = 0.0;
      supBuffer3[n] = 0.0;
      supBuffer2[n] = 0.0;
      supBuffer1[n] = 0.0;

      midBuffer[n] = 0.0;

      infBuffer1[n] = 0.0;
      infBuffer2[n] = 0.0;
      infBuffer3[n] = 0.0;
      infBuffer4[n] = 0.0;
      infBuffer5[n] = 0.0;
      infBuffer6[n] = 0.0;
      infBuffer7[n] = 0.0;
      infBuffer8[n] = 0.0;
      infBuffer9[n] = 0.0;
      infBuffer10[n] = 0.0;
      infBuffer11[n] = 0.0;
      infBuffer12[n] = 0.0;
      infBuffer13[n] = 0.0;
      infBuffer14[n] = 0.0;
      infBuffer15[n] = 0.0;
      infBuffer16[n] = 0.0;
      infBuffer17[n] = 0.0;
      infBuffer18[n] = 0.0;
      infBuffer19[n] = 0.0;
      infBuffer20[n] = 0.0;

      projsupBuffer1[n] = 0.0;
      projsupBuffer2[n] = 0.0;
      projsupBuffer3[n] = 0.0;
      projsupBuffer4[n] = 0.0;
      projsupBuffer5[n] = 0.0;

      projsupBuffer1[n] = 0.0;
      projinfBuffer2[n] = 0.0;
      projinfBuffer3[n] = 0.0;
      projinfBuffer4[n] = 0.0;
      projinfBuffer5[n] = 0.0;

   }

//--- copy close data to sample array
   if(CopyClose(Symbol(), PERIOD_CURRENT, StartBar, CalcBars, sample) != CalcBars)
      return(0);

//--- use sample data to calculate linear regression,to get the coefficient a and b
   CalcAB(sample, CalcBars, A, B);
   stdev = GetStdDev(sample, CalcBars); //calculate standand deviation

//define os labels do indicador
   PlotIndexSetString(1, PLOT_LABEL, "" + (1 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(2, PLOT_LABEL, (2 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(3, PLOT_LABEL, (3 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(4, PLOT_LABEL, (4 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(5, PLOT_LABEL, (5 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(6, PLOT_LABEL, (6 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(7, PLOT_LABEL, (7 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(8, PLOT_LABEL, (8 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(9, PLOT_LABEL, (9 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(10, PLOT_LABEL, (10 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(11, PLOT_LABEL, (11 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(12, PLOT_LABEL, (12 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(13, PLOT_LABEL, (13 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(14, PLOT_LABEL, (14 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(15, PLOT_LABEL, (15 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(16, PLOT_LABEL, (16 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(17, PLOT_LABEL, (17 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(18, PLOT_LABEL, (18 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(19, PLOT_LABEL, (19 + primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(20, PLOT_LABEL, (20 + primeiro_desvio)  * step + " \x03C3");

   PlotIndexSetString(0, PLOT_LABEL, "Ponto central ");

   PlotIndexSetString(21, PLOT_LABEL, (-1 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(22, PLOT_LABEL, (-2 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(23, PLOT_LABEL, (-3 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(24, PLOT_LABEL, (-4 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(25, PLOT_LABEL, (-5 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(26, PLOT_LABEL, (-6 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(27, PLOT_LABEL, (-7 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(28, PLOT_LABEL, (-8 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(29, PLOT_LABEL, (-9 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(30, PLOT_LABEL, (-10 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(31, PLOT_LABEL, (-11 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(32, PLOT_LABEL, (-12 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(33, PLOT_LABEL, (-13 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(34, PLOT_LABEL, (-14 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(35, PLOT_LABEL, (-15 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(36, PLOT_LABEL, (-16 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(37, PLOT_LABEL, (-17 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(38, PLOT_LABEL, (-18 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(39, PLOT_LABEL, (-19 - primeiro_desvio)  * step + " \x03C3");
   PlotIndexSetString(40, PLOT_LABEL, (-20 - primeiro_desvio)  * step + " \x03C3");

   if (enable_rays == true) {
      StartBar = 0;
   } else {
      StartBar = limite_final;
   }

   for(i = StartBar; i < rates_total; i++) {
      //começamos a contar da barra definida como limite final
      midBuffer[i] = A * (limite_final + CalcBars -  i - 1) + B;    // y =f(x) =a*x+b;
      if (exibe_projecao == true) {
         if (projsup1 > 0) projsupBuffer1[i] = (A * (projsup1 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projsupBuffer1[i] = A * (projsup1 + 2) * (limite_final + CalcBars -  i - 1) + B;
         if (projsup2 > 0) projsupBuffer2[i] = (A * (projsup2 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projsupBuffer2[i] = A * (projsup2 + 2) * (limite_final + CalcBars -  i - 1) + B;
         if (projsup3 > 0) projsupBuffer3[i] = (A * (projsup3 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projsupBuffer3[i] = A * (projsup3 + 2) * (limite_final + CalcBars -  i - 1) + B;
         if (projsup4 > 0) projsupBuffer4[i] = (A * (projsup4 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projsupBuffer4[i] = A * (projsup4 + 2) * (limite_final + CalcBars -  i - 1) + B;
         if (projsup5 > 0) projsupBuffer5[i] = (A * (projsup5 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projsupBuffer5[i] = A * (projsup5 + 2) * (limite_final + CalcBars -  i - 1) + B;

         if (projinf1 > 0) projinfBuffer1[i] = (A * (projinf1 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projinfBuffer1[i] = A * (projinf1 + 2) * (limite_final + CalcBars -  i - 1) + B;
         if (projinf2 > 0) projinfBuffer2[i] = (A * (projinf2 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projinfBuffer2[i] = A * (projinf2 + 2) * (limite_final + CalcBars -  i - 1) + B;
         if (projinf3 > 0) projinfBuffer3[i] = (A * (projinf3 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projinfBuffer3[i] = A * (projinf3 + 2) * (limite_final + CalcBars -  i - 1) + B;
         if (projinf4 > 0) projinfBuffer4[i] = (A * (projinf4 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projinfBuffer4[i] = A * (projinf4 + 2) * (limite_final + CalcBars -  i - 1) + B;
         if (projinf5 > 0) projinfBuffer5[i] = (A * (projinf5 + 1)) * (limite_final + CalcBars -  i - 1) + B;
         else projinfBuffer5[i] = A * (projinf5 + 2) * (limite_final + CalcBars -  i - 1) + B;

      }
   }

//--- draw channel

   for(n = StartBar; n < rates_total; n++) {

      if (numero_desvios >= 20) supBuffer20[n] = midBuffer[n] + (20 + primeiro_desvio) * step * stdev;
      if (numero_desvios >= 19) supBuffer19[n] = midBuffer[n] + (19 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 18) supBuffer18[n] = midBuffer[n] + (18 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 17) supBuffer17[n] = midBuffer[n] + (17 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 16) supBuffer16[n] = midBuffer[n] + (16 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 15) supBuffer15[n] = midBuffer[n] + (15 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 14) supBuffer14[n] = midBuffer[n] + (14 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 13) supBuffer13[n] = midBuffer[n] + (13 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 12) supBuffer12[n] = midBuffer[n] + (12 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 11) supBuffer11[n] = midBuffer[n] + (11 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 10) supBuffer10[n] = midBuffer[n] + (10 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 9) supBuffer9[n] = midBuffer[n] + (9 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 8) supBuffer8[n] = midBuffer[n] + (8 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 7) supBuffer7[n] = midBuffer[n] + (7 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 6) supBuffer6[n] = midBuffer[n] + (6 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 5) supBuffer5[n] = midBuffer[n] + (5 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 4) supBuffer4[n] = midBuffer[n] + (4 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 3) supBuffer3[n] = midBuffer[n] + (3 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 2) supBuffer2[n] = midBuffer[n] + (2 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 1) supBuffer1[n] = midBuffer[n] + (1 + primeiro_desvio) * step  * stdev;

      if (numero_desvios >= 1) infBuffer1[n] = midBuffer[n] - (1 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 2) infBuffer2[n] = midBuffer[n] - (2 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 3) infBuffer3[n] = midBuffer[n] - (3 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 4) infBuffer4[n] = midBuffer[n] - (4 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 5) infBuffer5[n] = midBuffer[n] - (5 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 6) infBuffer6[n] = midBuffer[n] - (6 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 7) infBuffer7[n] = midBuffer[n] - (7 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 8) infBuffer8[n] = midBuffer[n] - (8 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 9) infBuffer9[n] = midBuffer[n] - (9 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 10) infBuffer10[n] = midBuffer[n] - (10 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 11) infBuffer11[n] = midBuffer[n] - (11 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 12) infBuffer12[n] = midBuffer[n] - (12 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 13) infBuffer13[n] = midBuffer[n] - (13 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 14) infBuffer14[n] = midBuffer[n] - (14 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 15) infBuffer15[n] = midBuffer[n] - (15 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 16) infBuffer16[n] = midBuffer[n] - (16 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 17) infBuffer17[n] = midBuffer[n] - (17 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 18) infBuffer18[n] = midBuffer[n] - (18 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 19) infBuffer19[n] = midBuffer[n] - (19 + primeiro_desvio) * step  * stdev;
      if (numero_desvios >= 20) infBuffer20[n] = midBuffer[n] - (20 + primeiro_desvio) * step  * stdev;

   }

//---if a new bar occurs,the last value should be set to EMPTY VALUE
   static int LastTotalBars = 0;
   if(n < rates_total && LastTotalBars != rates_total) {
      supBuffer20[n] = 0.0;
      supBuffer19[n] = 0.0;
      supBuffer18[n] = 0.0;
      supBuffer17[n] = 0.0;
      supBuffer16[n] = 0.0;
      supBuffer15[n] = 0.0;
      supBuffer14[n] = 0.0;
      supBuffer13[n] = 0.0;
      supBuffer12[n] = 0.0;
      supBuffer11[n] = 0.0;
      supBuffer10[n] = 0.0;
      supBuffer9[n] = 0.0;
      supBuffer8[n] = 0.0;
      supBuffer7[n] = 0.0;
      supBuffer6[n] = 0.0;
      supBuffer5[n] = 0.0;
      supBuffer4[n] = 0.0;
      supBuffer3[n] = 0.0;
      supBuffer2[n] = 0.0;
      supBuffer1[n] = 0.0;

      midBuffer[n] = 0.0;

      infBuffer1[n] = 0.0;
      infBuffer2[n] = 0.0;
      infBuffer3[n] = 0.0;
      infBuffer4[n] = 0.0;
      infBuffer5[n] = 0.0;
      infBuffer6[n] = 0.0;
      infBuffer7[n] = 0.0;
      infBuffer8[n] = 0.0;
      infBuffer9[n] = 0.0;
      infBuffer10[n] = 0.0;
      infBuffer11[n] = 0.0;
      infBuffer12[n] = 0.0;
      infBuffer13[n] = 0.0;
      infBuffer14[n] = 0.0;
      infBuffer15[n] = 0.0;
      infBuffer16[n] = 0.0;
      infBuffer17[n] = 0.0;
      infBuffer18[n] = 0.0;
      infBuffer19[n] = 0.0;
      infBuffer20[n] = 0.0;
      LastTotalBars = rates_total;

   }

   TimerDP = (int)TimeLocal();

//--- return value of prev_calculated for next call
   return (rates_total);
}
//+------------------------------------------------------------------+

//Linear Regression Calculation for sample data: arr[]
//line equation  y = f(x)  = ax + b
void CalcAB(const double& arr[], int size, double& a, double& b) {
   a = 0.0;
   b = 0.0;
   if(size < 2)
      return;

   double sumxy = 0.0, sumx = 0.0, sumy = 0.0, sumx2 = 0.0;
   for(int i = 0; i < size; i++) {
      sumxy += i * arr[i];
      sumy += arr[i];
      sumx += i;
      sumx2 += i * i;
   }

   double M = size * sumx2 - sumx * sumx;
   if(M == 0.0)
      return;

   a = (size * sumxy - sumx * sumy) / M;
   b = (sumy - a * sumx) / size;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetStdDev(const double &arr[], int size) {
   if(size < 2)
      return(0.0);

   double sum = 0.0;
   for(int i = 0; i < size; i++) {
      sum = sum + arr[i];
   }

   sum = sum / size;

   double sum2 = 0.0;
   for(int i = 0; i < size; i++) {
      sum2 = sum2 + (arr[i] - sum) * (arr[i] - sum);
   }

   sum2 = sum2 / (size - 1);
   sum2 = MathSqrt(sum2);

   return(sum2);
}
//+------------------------------------------------------------------+
