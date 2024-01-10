// UI

#include <B63/ui/CInterface.mqh>
#include "trade_mt4.mqh"


class CIntervalApp : public CInterface{
   protected:
   private:
      int      APP_COL_1, APP_COL_2, APP_ROW_1;
   public: 
      CIntervalApp(CIntervalTrade &trade, int ui_x, int ui_y, int ui_width, int ui_height);
      ~CIntervalApp(){};
      
      Terminal terminal;
      CIntervalTrade TRADE;
      void     InitializeUIElements();
      void     DrawRow(string base_name, int row_number, string value);
};

CIntervalApp::CIntervalApp(CIntervalTrade &trade, int ui_x, int ui_y, int ui_width, int ui_height){
   UI_X = ui_x; 
   UI_Y = ui_y;
   UI_WIDTH = 235;
   UI_HEIGHT = UI_Y - 5;
   
   APP_COL_1 = 15;
   APP_COL_2 = 125;
   
   DefFontStyle = UI_FONT;
   DefFontStyleBold = UI_FONT_BOLD;
   DefFontSize = DEF_FONT_SIZE;
   
   APP_ROW_1 = UI_Y - 20;
   
   TRADE = trade;
   
}



void CIntervalApp::InitializeUIElements(void){
   UI_Terminal(terminal,"MAIN");

   DrawRow("Tick Value", 1, TRADE.tick_value);
   DrawRow("Trade Points", 2, TRADE.trade_points);
   DrawRow("RP Lot", 3, RISK_PROFILE.RP_lot);
   DrawRow("RP Risk", 4, RISK_PROFILE.RP_amount);
   DrawRow("RP Hold", 5, RISK_PROFILE.RP_holdtime);
   DrawRow("RP Order", 6, EnumToString(RISK_PROFILE.RP_order_type));
   DrawRow("RP Timeframe", 7, RISK_PROFILE.RP_timeframe);
   DrawRow("True Lot", 8, TRADE.CalcLot());
   DrawRow("True Risk", 9, InpRiskAmount * InpAllocation);
   DrawRow("Allocation", 10, InpAllocation);
   DrawRow("EA Positions", 11, TRADE.NumActivePositions());
   DrawRow("Hour", 12, InpEntryHour);
   DrawRow("Minute", 13, InpEntryMin);
   DrawRow("Magic", 14, InpMagic);
   DrawRow("Last Time", 15, TimeToString(TimeCurrent()));
   DrawRow("Current Entry", 16, TimeToString(TRADE_QUEUE.curr_trade_open));
   DrawRow("Current Close", 17, TimeToString(TRADE_QUEUE.curr_trade_close));
   DrawRow("Next Entry", 18, TimeToString(TRADE_QUEUE.next_trade_open));
   DrawRow("Next Close", 19, TimeToString(TRADE_QUEUE.next_trade_close));
   DrawRow("Active Entry", 20, TimeToString(TRADES_ACTIVE.trade_open_datetime));
   DrawRow("Active Close", 21, TimeToString(TRADES_ACTIVE.trade_close_datetime));
   DrawRow("Min Equity", 22, InpMinimumEquity);
   DrawRow("Max Lot", 23, InpMaxLot);
   DrawRow("Initial Deposit", 24, TRADE.account_deposit());
   DrawRow("Sizing", 25, EnumToString(InpSizing));
   
   

}

void CIntervalApp::DrawRow(string base_name, int row_number, string value){
   
   string identifier = "LABEL-"+base_name;
   string value_identifier = "VALUE"+base_name;
   int x_offset = 15;
   int spacing = 10;
   int row = APP_ROW_1 - ((row_number - 1) * (DefFontSize + spacing));
   
   CTextLabel(identifier, x_offset, row, base_name, 10, DefFontStyle);
   CTextLabel(value_identifier, APP_COL_2, row, value, 10, DefFontStyle);
   
}

