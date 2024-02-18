// UI

#include <B63/ui/CInterface.mqh>
#include "forex_factory.mqh"
#ifdef __MQL4__
#include "trade_mt4.mqh"
#endif

#ifdef __MQL5__ 
#include "trade_mt5.mqh"
#endif

class CIntervalApp : public CInterface{
   protected:
   private:
      int      APP_COL_1, APP_COL_2, APP_ROW_1;
      int      SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR, SW_HEADER_FONTSIZE, SW_HEADER_X, SW_HEADER_Y, SW_ROW_1;
      color    THEME_BUTTON_BORDER_COLOR, THEME_FONT_COLOR;
   public: 
      Button   BASE_BUTTONS[];
      Button   RP_BUTTON, EN_BUTTON, RM_BUTTON, FN_BUTTON, MS_BUTTON, LG_BUTTON, PORT_BUTTON, NEWS_BUTTON, TARGETS_BUTTON, ACC_BUTTON;
      SCalendarEvent NEWS_EVENT[];
      
      string   ACTIVE_SUBWINDOW; 
      
      CIntervalApp(CIntervalTrade &trade, CNewsEvents &news, int ui_x, int ui_y, int ui_width, int ui_height);
      ~CIntervalApp(){};
      
      
      
      Terminal terminal, RP_terminal, EN_terminal, FN_terminal, MS_terminal, LG_terminal, PORT_terminal, RM_terminal, NEWS_terminal, ACC_terminal, TARG_terminal;
      CIntervalTrade TRADE;
      CNewsEvents    NEWS;
      void     InitializeUIElements();
      void     InitializeSubwindowProperties();
      void     RefreshClass(CIntervalTrade &trade_class, CNewsEvents &news);
      void     DrawRow(string prefix, string base_name, int row_number, string value);
      void     DrawTerminalButton(Button &button, string name, string parent,int x,int y_adjust, string label_name, double width_factor = 1, double height_factor = 1, color button_color = clrGray);
      void     DrawCloseButton();
      
      void     RPSubWindow(string prefix);
      void     ENSubWindow(string prefix);
      void     FNSubWindow(string prefix);
      void     MSSubWindow(string prefix);
      void     LGSubWindow(string prefix);
      void     PORTSubWindow(string prefix);
      void     RMSubWindow(string prefix);
      void     NEWSSubWindow(string prefix);
      void     ACCSubWindow(string prefix);
      void     TARGSubWindow(string prefix);
      
      // UTILITIES 
      bool     ObjectIsButton(string name, Button &list[]);
      void     AddObjectToList(Button &base_button, Button &list[]);
      string   UpdateSubwindow(string new_subwindow);
      string   SubWindowTerminalName(string prefix);
      
      // EVENT
      void     EVENT_BUTTON_PRESS(string button_name);
};

CIntervalApp::CIntervalApp(CIntervalTrade &trade, CNewsEvents &news, int ui_x, int ui_y, int ui_width, int ui_height){
   UI_X = ui_x; 
   UI_Y = ui_y;
   UI_WIDTH = 270;
   UI_HEIGHT = UI_Y - 5;
   
   APP_COL_1 = 15;
   APP_COL_2 = 150;
   
   DefFontStyle = UI_FONT;
   DefFontStyleBold = UI_FONT_BOLD;
   DefFontSize = DEF_FONT_SIZE;
   
   APP_ROW_1 = UI_Y - 20;
   
   RefreshClass(trade, news);
   
   THEME_BUTTON_BORDER_COLOR     = clrGray;
   THEME_FONT_COLOR              = clrWhite;
   
   InitializeSubwindowProperties();
}

void CIntervalApp::RefreshClass(CIntervalTrade &trade_class, CNewsEvents &news){
   TRADE = trade_class;
   NEWS = news;
}

void CIntervalApp::InitializeUIElements(void){
   if (!InpShowUI) return;
   UI_Terminal(terminal, "MAIN");
   int col_1 = 15; 
   int col_2 = 100;
   int col_3 = 185; 
   
   int row_1 = 30;
   int row_2 = 58;
   int row_3 = 86;
   int row_4 = 114;
   
   DrawTerminalButton(RP_BUTTON, "RP", "BASE", col_1, row_1, "Profile");
   DrawTerminalButton(EN_BUTTON, "EN", "BASE", col_2, row_1, "Entries");
   
   DrawTerminalButton(MS_BUTTON, "MS", "BASE", col_1, row_2, "Misc");
   DrawTerminalButton(LG_BUTTON, "LG", "BASE", col_2, row_2, "Logging");
   DrawTerminalButton(PORT_BUTTON, "PORT", "BASE", col_3, row_2, "Portfolio");
   
   DrawTerminalButton(ACC_BUTTON, "ACC", "BASE", col_1, row_3, "Accounts");
   DrawTerminalButton(FN_BUTTON, "FN", "BASE", col_2, row_3, "Funded");
   DrawTerminalButton(TARGETS_BUTTON, "TARG", "BASE", col_3, row_3, "Targets");
   
   DrawTerminalButton(RM_BUTTON, "RM", "BASE", col_1, row_4, "Risk Management", 2.0625);
   DrawTerminalButton(NEWS_BUTTON, "NEWS", "BASE", col_3, row_4, "News");
   
   //RPSubWindow("RP");
   
   
}

void CIntervalApp::InitializeSubwindowProperties(void){
   SW_X = UI_X;
   SW_Y = UI_Y + 250;
   SW_WIDTH = 270;
   SW_HEIGHT = 250;
   SW_COLOR = clrBlack;
   
   SW_HEADER_FONTSIZE = 12; 
   SW_HEADER_X = SW_X + 10;
   SW_HEADER_Y = SW_Y - 15;
   
   SW_ROW_1 = SW_Y - 40;
}

void CIntervalApp::DrawTerminalButton(
   Button      &button, 
   string      name, 
   string      parent,
   int         x,
   int         y_adjust, 
   string      label_name,
   double      width_factor = 1,
   double      height_factor = 1, 
   color       button_color = clrGray){
   /*
   button - struct containing button properties (sparam)
   parent - source/prefix
   
   button name = prefix + name
   */
   
   int DefButtonWidth = 80;
   int DefButtonHeight = 20; 
   
   int APP_YOffset = DefButtonHeight + UI_Y;
   int y = APP_YOffset - y_adjust; 
   
   int width = (int)(DefButtonWidth * width_factor);
   int height = (int)(DefButtonHeight * height_factor);
   
   long ZOrder = 5;
   
   button.button_name = StringFormat("%s_%s", parent, name);
   AddObjectToList(button, BASE_BUTTONS);
   
   CButton(button.button_name, x, y, width, height, DefFontSize, DefFontStyle, label_name, THEME_FONT_COLOR, button_color, THEME_BUTTON_BORDER_COLOR, DefCorner, DefHidden, ZOrder);
   
   
}

void CIntervalApp::DrawRow(string prefix, string base_name, int row_number, string value){
   
   string identifier = prefix+"-LABEL-"+base_name;
   string value_identifier = prefix+"-VALUE"+base_name;
   int x_offset = 15;
   int spacing = 8;
   int row = SW_ROW_1 - ((row_number - 1) * (DefFontSize + spacing));
   
   CTextLabel(identifier, x_offset, row, base_name, DefFontSize, DefFontStyle);
   
   
   // returns chart id. 
   // returns -1 if not yet created.
   
   int object_found = ObjectFind(0, value_identifier); 
   switch(object_found){
      case 0: 
         ObjectSetString(0, value_identifier, OBJPROP_TEXT, value);
         break; 
      case -1:
         CTextLabel(value_identifier, APP_COL_2, row,value, DefFontSize, DefFontStyle);
         break;
      default:
         CTextLabel(value_identifier, APP_COL_2, row,value, DefFontSize, DefFontStyle);
         break;
   }
   //CTextLabel(value_identifier, APP_COL_2, row,value, 10, DefFontStyle);
   
}

bool CIntervalApp::ObjectIsButton(string name,Button &list[]){
   
   int num_elements = ArraySize(list);
   
   for (int i = 0; i < num_elements; i++){
      
      string element_name = list[i].button_name;
      if (name == element_name) return true;
   }
   
   return false; 
   
}

void CIntervalApp::AddObjectToList(Button &base_button, Button &list[]){
   int num_elements = ArraySize(list);
   
   ArrayResize(list, num_elements + 1);
   
   list[num_elements] = base_button;
}


void CIntervalApp::EVENT_BUTTON_PRESS(string button_name){
   
   string substrings[];
   ushort separator = StringGetCharacter("_", 0);
   
   StringSplit(button_name, separator, substrings);
   
   string prefix = substrings[1]; // PREFIX FOR SUBWINDOW
   
   
   UI_Reset_Object(button_name);
   if (button_name == RP_BUTTON.button_name){
      RPSubWindow(prefix);
      
      return;
   }
   if (button_name == EN_BUTTON.button_name){
      ENSubWindow(prefix);
      return;
   }
   if (button_name == FN_BUTTON.button_name){
      FNSubWindow(prefix);
      return;
   }
   if (button_name == MS_BUTTON.button_name){
      MSSubWindow(prefix);
      return;
   }
   if (button_name == LG_BUTTON.button_name){
      LGSubWindow(prefix);
      return;
   }
   if (button_name == PORT_BUTTON.button_name){
      PORTSubWindow(prefix);
      return;
   }
   
   if (button_name == ACC_BUTTON.button_name){
      ACCSubWindow(prefix);
      return;
   }
   
   if (button_name == TARGETS_BUTTON.button_name){
      TARGSubWindow(prefix);
      return;
   }
   
   if (button_name == RM_BUTTON.button_name){
      RMSubWindow(prefix);
      return;
   }
   if (button_name == NEWS_BUTTON.button_name){
      NEWSSubWindow(prefix);
      return;
   }
}

void CIntervalApp::RPSubWindow(string prefix){
   string name = StringFormat("%s_terminal", prefix);
   string text_label_name = StringFormat("%s_label", prefix);
   
   if (UpdateSubwindow(prefix) != prefix) return;
   UI_SubWindow(RP_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, "Risk Profile", SW_HEADER_FONTSIZE);
   DrawRow(prefix, "RP Lot", 1, RISK_PROFILE.RP_lot);
   DrawRow(prefix, "RP Risk", 2, RISK_PROFILE.RP_amount);
   DrawRow(prefix, "RP Hold", 3, RISK_PROFILE.RP_holdtime);
   DrawRow(prefix, "RP Order", 4, EnumToString(RISK_PROFILE.RP_order_type));
   DrawRow(prefix, "RP Timeframe", 5, RISK_PROFILE.RP_timeframe);
   DrawRow(prefix, "RP Spread", 6, RISK_PROFILE.RP_spread);
   DrawRow(prefix, "RP Order Method", 7, EnumToString(RISK_PROFILE.RP_order_method));
}
void CIntervalApp::ENSubWindow(string prefix){
   string name = StringFormat("%s_terminal", prefix);
   string text_label_name = StringFormat("%s_label", prefix);
   
   if (UpdateSubwindow(prefix) != prefix) return;
   UI_SubWindow(EN_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, "Entries", SW_HEADER_FONTSIZE);
   
   DrawRow(prefix, "EA Positions", 1, TRADE.NumActivePositions());
   DrawRow(prefix, "Hour", 2, InpEntryHour);
   DrawRow(prefix, "Minute", 3, InpEntryMin);
   DrawRow(prefix, "Magic", 4, InpMagic);
   DrawRow(prefix, "Last Time", 5, TimeToString(TimeCurrent()));
   DrawRow(prefix, "Current Entry", 6, TimeToString(TRADE_QUEUE.curr_trade_open));
   DrawRow(prefix, "Current Close", 7, TimeToString(TRADE_QUEUE.curr_trade_close));
   DrawRow(prefix, "Next Entry", 8, TimeToString(TRADE_QUEUE.next_trade_open));
   DrawRow(prefix, "Next Close", 9, TimeToString(TRADE_QUEUE.next_trade_close));
   DrawRow(prefix, "Active Entry", 10, TimeToString(TRADES_ACTIVE.trade_open_datetime));
   DrawRow(prefix, "Active Close", 11, TimeToString(TRADES_ACTIVE.trade_close_datetime));
}

void CIntervalApp::FNSubWindow(string prefix){
   string name = SubWindowTerminalName(prefix);
   string text_label_name = StringFormat("%s_label", prefix);
   
   if (UpdateSubwindow(prefix) != prefix) return;
   
   double current_profit = NormalizeDouble(TRADE.account_balance() - TRADE.ACCOUNT_DEPOSIT, 2);
   
   UI_SubWindow(FN_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, "Funded", SW_HEADER_FONTSIZE);
   DrawRow(prefix, "Chall Scaling", 1, InpChallScale);
   DrawRow(prefix, "Chall DD Scaling", 2, InpChallDDScale);
   DrawRow(prefix, "Live Scaling", 3, InpLiveScale);
   DrawRow(prefix, "Live DD Scaling", 4, InpLiveDDScale);
   DrawRow(prefix, "Min Target Points", 5, InpMinTargetPts);
   DrawRow(prefix, "Chall DD Threshold", 6, InpPropDDThresh+"%");
   
   /*
   ProfitTargetReached
   BelowAbsoluteDrawdownThreshold
   BelowEquityDrawdownThreshold
   BreachedConsecutiveLossesThreshold
   BreachedEquityDrawdownThreshold
   */
   DrawRow(prefix, "Target Reached", 7, (string)TRADE.ProfitTargetReached());
   DrawRow(prefix, "Abs DD Thresh", 8, (string)TRADE.BelowAbsoluteDrawdownThreshold());
   DrawRow(prefix, "Equity DD Thresh", 9, (string)TRADE.BelowEquityDrawdownThreshold());
   DrawRow(prefix, "Lose Streak", 10, (string)TRADE.BreachedConsecutiveLossesThreshold());
   DrawRow(prefix, "Equity DD", 11, (string)TRADE.BreachedEquityDrawdownThreshold());
   
}

void CIntervalApp::MSSubWindow(string prefix){
   string name = SubWindowTerminalName(prefix);
   string text_label_name = StringFormat("%s_label", prefix);
   
   if (UpdateSubwindow(prefix) != prefix) return;
   UI_SubWindow(MS_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, "Miscellaneous", SW_HEADER_FONTSIZE);
   
   DrawRow(prefix, "Spread Mgt", 1, EnumToString(InpSpreadMgt));
   DrawRow(prefix, "Spread Delay", 2, InpSpreadDelay+" seconds");
   DrawRow(prefix, "Magic Number", 3, InpMagic);
   DrawRow(prefix, "Tick Value", 4, DoubleToString(TRADE.tick_value, 2));
   DrawRow(prefix, "Trade Points", 5, TRADE.trade_points);
   
}

void CIntervalApp::LGSubWindow(string prefix){
   string name = SubWindowTerminalName(prefix);
   string text_label_name = StringFormat("%s_label", prefix);
   
   if (UpdateSubwindow(prefix) != prefix) return;
   UI_SubWindow(LG_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, "Logging", SW_HEADER_FONTSIZE);
   
   DrawRow(prefix, "Logging", 1, InpLogging ? "Enabled" : "Disabled");
   DrawRow(prefix, "Terminal", 2, InpTerminalMsg ? "Enabled" : "Disabled");
   DrawRow(prefix, "Push Notifications", 3, InpPushNotifs ? "Enabled" : "Disabled");
}

void CIntervalApp::PORTSubWindow(string prefix){
   string name = SubWindowTerminalName(prefix);
   string text_label_name = StringFormat("%s_label", prefix);
   
   if (UpdateSubwindow(prefix) != prefix) return;
   UI_SubWindow(PORT_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, "Portfolio", SW_HEADER_FONTSIZE);
   
   
   
   DrawRow(prefix, "In Drawdown", 1, (string)PORTFOLIO.in_drawdown);
   DrawRow(prefix, "In Losing Streak", 2, (string)PORTFOLIO.is_losing_streak);
   DrawRow(prefix, "Curr DD %", 3, DoubleToString(PORTFOLIO.current_drawdown_percent,2)+" %");
   DrawRow(prefix, "Max DD %", 4, DoubleToString(PORTFOLIO.max_drawdown_percent,2)+" %");
   DrawRow(prefix, "Peak Equity", 5, (string)("$"+PORTFOLIO.peak_equity));
   DrawRow(prefix, "Max Consecutive", 6, (string)PORTFOLIO.max_consecutive_losses);
   DrawRow(prefix, "Last Consecutive", 7, (string)PORTFOLIO.last_consecutive_losses);
   DrawRow(prefix,"Initial Deposit", 8, TRADE.account_deposit());
   DrawRow(prefix, "Data Points", 9, PORTFOLIO.data_points);
   DrawRow(prefix, "Latest", 10, TRADE.PortfolioLatestTradeTicket());
   
}

void CIntervalApp::ACCSubWindow(string prefix){
   
   string name = SubWindowTerminalName(prefix);
   string text_label_name = StringFormat("%s_label", prefix); 
   
   if (UpdateSubwindow(prefix) != prefix) return; 
   
   TRADE.UpdateAccounts();
   
   UI_SubWindow(ACC_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, "Accounts", SW_HEADER_FONTSIZE);
   
   DrawRow(prefix, "Balance", 1, TRADE.account_balance());
   DrawRow(prefix, "Deposit", 2, TRADE.ACCOUNT_DEPOSIT);
   DrawRow(prefix, "Profit", 3, DoubleToString(TRADE.ACCOUNT_GAIN, 2));
   
}

void CIntervalApp::TARGSubWindow(string prefix){
   
   string name = SubWindowTerminalName(prefix);
   string text_label_name = StringFormat("%s_label", prefix);
   
   if (UpdateSubwindow(prefix) != prefix) return;
   
   TRADE.UpdateAccounts();
   
   UI_SubWindow(TARG_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, "Targets", SW_HEADER_FONTSIZE);
   
   DrawRow(prefix, "Profit Target", 1, "$" + (int)TRADE.funded_target_usd);
   DrawRow(prefix, "Current Profit" , 2, "$" + DoubleToString(TRADE.ACCOUNT_GAIN, 2));
   DrawRow(prefix, "Remaining", 3, "$" + DoubleToString(TRADE.FUNDED_REMAINING_TARGET, 2));
   DrawRow(prefix, "True Lot", 4, TRADE.CalcLot());
   DrawRow(prefix, "True Risk", 5, TRADE.ValueAtRisk());
   DrawRow(prefix, "Commission", 6, TRADE.CalcCommission());
   DrawRow(prefix, "TP Points", 7, DoubleToString(TRADE.CalcTP(TRADE.CalcCommission()) / TRADE.trade_points, 2));
   
}

void CIntervalApp::RMSubWindow(string prefix){

   string name = SubWindowTerminalName(prefix);
   string text_label_name = StringFormat("%s_label", prefix);
   
   if (UpdateSubwindow(prefix) != prefix) return;
   UI_SubWindow(RM_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, "Risk Management", SW_HEADER_FONTSIZE);
   
   DrawRow(prefix, "Account Type", 1, EnumToString(InpAccountType));
   DrawRow(prefix, "Base Risk Amount", 2, "$"+DoubleToString(InpRiskAmount, 2));
   DrawRow(prefix, "Allocation", 3, (InpAllocation*100)+"%");
   DrawRow(prefix, "Trade Management", 4, EnumToString(InpTradeMgt));
   DrawRow(prefix, "Trail Interval", 5, InpTrailInterval + " points");
   DrawRow(prefix, "Cutoff", 6, "$" +TRADE.ACCOUNT_CUTOFF);
   DrawRow(prefix, "Max Lot", 7, InpMaxLot);
   DrawRow(prefix, "Sizing", 8, EnumToString(InpSizing));
   DrawRow(prefix, "Drawdown Scale", 9, InpDDScale);
   DrawRow(prefix, "Abs DD Threshold", 10, InpAbsDDThresh+"%");
   DrawRow(prefix, "Equity DD Threshold", 11, InpEquityDDThresh +"%");
   DrawRow(prefix, "History Interval", 12, EnumToString(InpHistInterval));
   DrawRow(prefix, "Consecutive Loss", 13, InpMinLoseStreak + " trades");
   
}

void CIntervalApp::NEWSSubWindow(string prefix){
   
   string name = SubWindowTerminalName(prefix);
   string text_label_name = StringFormat("%s_label", prefix);
   
   if (UpdateSubwindow(prefix) != prefix) return;
   UI_SubWindow(NEWS_terminal, name, SW_X, SW_Y, SW_WIDTH, SW_HEIGHT, SW_COLOR);
   CTextLabel(text_label_name, SW_HEADER_X, SW_HEADER_Y, StringFormat("High Impact News | %s", TimeToString(TimeCurrent(), TIME_DATE)), SW_HEADER_FONTSIZE);
   
   int size = NEWS.GetNewsSymbolToday();
   //int size = NEWS.NumNews();
   //int size = NEWS.GetHighImpactNewsInEntryWindow(TRADE_QUEUE.curr_trade_open, TRADE_QUEUE.curr_trade_close);
   for (int i = 0; i < size; i ++){
      SCalendarEvent news_today = NEWS.NEWS_SYMBOL_TODAY[i];
      //SCalendarEvent news_today = NEWS.NEWS_IN_TRADING_WINDOW[i]; 
      string title = StringSubstr(news_today.title, 0, 25);
      DrawRow(prefix, title, i+1, StringFormat("             %s %s", TimeToString(news_today.time, TIME_MINUTES), news_today.impact));
      
   }
   
}

string CIntervalApp::UpdateSubwindow(string new_subwindow){

   if (ACTIVE_SUBWINDOW != NULL && ACTIVE_SUBWINDOW != "") ObjectsDeleteAll(0, ACTIVE_SUBWINDOW);
   if (ACTIVE_SUBWINDOW == new_subwindow) ObjectsDeleteAll(0, new_subwindow);
   ACTIVE_SUBWINDOW = ACTIVE_SUBWINDOW == new_subwindow ? "" : new_subwindow;
   return ACTIVE_SUBWINDOW;
}

string CIntervalApp::SubWindowTerminalName(string prefix) { return StringFormat("%s_terminal", prefix); }