


#include <B63/Generic.mqh>

#include "trade_mt4.mqh"
#include "app.mqh"

CIntervalTrade interval_trade;
CIntervalApp interval_app(interval_trade, UI_X, UI_Y, UI_WIDTH, UI_HEIGHT);




int OnInit()
  {
//---
   #ifdef __MQL5__
   Trade.SetExpertMagicNumber(InpMagic);
   #endif 
   interval_trade.InitHistory();
   interval_trade.SetRiskProfile();
   interval_trade.SetFundedProfile();
   //set_deadline();
   
   interval_trade.OrdersEA();
   interval_trade.SetNextTradeWindow();
   interval_app.InitializeUIElements();
   // DRAW UI HERE
   
   //interval_trade.InitHistory();
   // add provision to check for open orders, in case ea gets deactivated
   //Print("interval_trade.risk_amount: ", interval_trade.risk_amount);
//---
   return(INIT_SUCCEEDED);

  }
  
  
  
void OnDeinit(const int reason)
  {
//---
   Print("Test Finished");
   PrintFormat("In Drawdown: %i, DD Percent: %f, Max DD Percent: %f, Losing Streak: %i, Last Consecutive: %i, Max Consecutive: %i, Peak: %f, Current: %f", 
      PORTFOLIO.in_drawdown, 
      PORTFOLIO.current_drawdown_percent, 
      PORTFOLIO.max_drawdown_percent,
      PORTFOLIO.is_losing_streak, 
      PORTFOLIO.last_consecutive_losses,
      PORTFOLIO.max_consecutive_losses,
      PORTFOLIO.peak_equity, 
      interval_trade.account_balance());
   ObjectsDeleteAll(0, 0, -1);
  }
  
  
void OnTick()
  {
   if (IsNewCandle() && interval_trade.CorrectPeriod() && interval_trade.MinimumEquity()){
      // CONDITION 1: New interval, Correct Timeframe, Minimum Equity Requirements.
      // check here for time interval 
      if (interval_trade.ValidTradeOpen()){
         // time is in between open and close time 
         if (interval_trade.SendMarketOrder() == -1) { 
            // add recusrion here? 
            // store last open price, and use it as reference, for delayed entry
            //interval_trade.set_delayed_entry(last_candle_open());
            
         }
            //send_limit_order();

      }
      else{
         if (interval_trade.EquityReachedProfitTarget() && InpAccountType != Personal) {
            interval_trade.logger("Order Close By Profit Target");
            interval_trade.CloseOrder();
         }
         if ((TimeCurrent() >= TRADE_QUEUE.curr_trade_close) && (InpTradeMgt != Trailing && InpTradeMgt != OpenTrailing)) {
            interval_trade.logger("Order Close by Deadline");
            interval_trade.CloseOrder();      
         }
      }
      // check order here. if order is active, increment
      interval_trade.SetNextTradeWindow();
      interval_trade.CheckOrderDeadline();
      int positions_added = interval_trade.OrdersEA();
      if (interval_trade.IsTradeWindow()){
         interval_trade.logger(StringFormat("Checked Order Pool. %i Positions Found.", positions_added));
         interval_trade.logger(StringFormat("%i Orders in Active List", interval_trade.NumActivePositions()));
      }
      if (interval_trade.IsNewDay()) { 
         interval_trade.ClearOrdersToday();
         
      }
         
      interval_trade.ModifyOrder();
      interval_app.InitializeUIElements();
      if (TimeMinute(TimeCurrent()) == 0 && TimeHour(TimeCurrent()) == 15){
         //interval_trade.ClearHistory();
         //interval_trade.InitHistory();
         //interval_trade.AppendToHistory();
         interval_trade.UpdateHistoryWithLastValue();
      }
   }
   
  }
  
  
void OnChartEvent(const int id, const long &lparam, const double &daram, const string &sparam){
   if (CHARTEVENT_OBJECT_CLICK){
      if (interval_app.ObjectIsButton(sparam, interval_app.BASE_BUTTONS)){
         interval_app.EVENT_BUTTON_PRESS(sparam);
      }
   }
}
//+------------------------------------------------------------------+
