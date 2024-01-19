


#include <B63/Generic.mqh>

#ifdef __MQL4__
#include "trade_mt4.mqh"
#endif 

#ifdef __MQL5__
#include "trade_mt5.mqh"
#endif

#include "app.mqh"
#include "loader.mqh"

CIntervalTrade interval_trade;
CIntervalApp interval_app(interval_trade, UI_X, UI_Y, UI_WIDTH, UI_HEIGHT);
CLoader loader;



int OnInit()
  {
//---
   #ifdef __MQL5__
   Trade.SetExpertMagicNumber(InpMagic);
   #endif 
   
   if (InpMode == MODE_BACKTEST) interval_trade.logger(StringFormat("Num Dates Loaded: %i", loader.LoadFromFile()), false, InpDebugLogging);
   
   interval_trade.InitializeSymbolProperties();
   interval_trade.InitHistory();
   interval_trade.SetRiskProfile();
   interval_trade.SetFundedProfile();
   //set_deadline();
   
   interval_app.RefreshClass(interval_trade);
   interval_trade.OrdersEA();
   interval_trade.SetNextTradeWindow();
   interval_app.InitializeUIElements();
   // DRAW UI HERE
   
   //Print("NEWS DATE: ", loader.IsNewsDate());
   //interval_trade.InitHistory();
   // add provision to check for open orders, in case ea gets deactivated
   //Print("interval_trade.risk_amount: ", interval_trade.risk_amount);
   
   /*
   INIT INFO: 
   Symbol Properties 
   Risk Properties
   History 
   */
   interval_trade.logger(StringFormat("Symbol Properties | Tick Value: %f, Trade Points: %f", interval_trade.tick_value, interval_trade.trade_points));
   
   interval_trade.logger(StringFormat("Sizing | Lot: %f, VAR: %f, Risk Scaling: %f, In Drawdown: %s", 
      interval_trade.CalcLot(), 
      interval_trade.ValueAtRisk(), 
      interval_trade.RiskScaling(), 
      (string)interval_trade.AccountInDrawdown()));
      
   interval_trade.logger(StringFormat("Datapoints: %i, In Drawdown: %i, DD Percent: %f, Max DD Percent: %f, Losing Streak: %i, Last Consecutive: %i, Max Consecutive: %i, Peak: %f, Current: %f", 
      interval_trade.PortfolioHistorySize(),
      PORTFOLIO.in_drawdown, 
      PORTFOLIO.current_drawdown_percent, 
      PORTFOLIO.max_drawdown_percent,
      PORTFOLIO.is_losing_streak, 
      PORTFOLIO.last_consecutive_losses,
      PORTFOLIO.max_consecutive_losses,
      PORTFOLIO.peak_equity, 
      interval_trade.account_balance()), false, InpDebugLogging);
//---
   return(INIT_SUCCEEDED);

  }
  
  
  
void OnDeinit(const int reason)
  {
//---
   //PrintFormat("REASON: %i", reason);
   interval_trade.logger(StringFormat("Num Dates Processed: %i", loader.NUM_LOADED_HISTORY), false, InpDebugLogging);
   ObjectsDeleteAll(0, 0, -1);
   
   if (InpMode == MODE_LIVE) return;
   
   interval_trade.logger(StringFormat("Datapoints: %i, In Drawdown: %i, DD Percent: %f, Max DD Percent: %f, Losing Streak: %i, Last Consecutive: %i, Max Consecutive: %i, Peak: %f, Current: %f", 
      interval_trade.PortfolioHistorySize(),
      PORTFOLIO.in_drawdown, 
      PORTFOLIO.current_drawdown_percent, 
      PORTFOLIO.max_drawdown_percent,
      PORTFOLIO.is_losing_streak, 
      PORTFOLIO.last_consecutive_losses,
      PORTFOLIO.max_consecutive_losses,
      PORTFOLIO.peak_equity, 
      interval_trade.account_balance()), false, InpDebugLogging);
      
   interval_trade.ClearHistory();
  
   

  }
  
  
void OnTick()
  {
   if (IsNewCandle() && interval_trade.CorrectPeriod() && interval_trade.MinimumEquity()){
      if (interval_trade.ValidTradeOpen() && !loader.IsNewsDate()){
         
         // sends market order
         int order_send_result = interval_trade.SendMarketOrder();
         
         if (order_send_result < 0) interval_trade.logger(StringFormat("Order Send Failed. Configuration: %s, Reason: %s, Code: %i", 
            EnumToString(InpSpreadMgt), 
            EnumToString((EnumOrderSendError)order_send_result), 
            order_send_result));       

      }
      else{
         if (interval_trade.EquityReachedProfitTarget() && InpAccountType != Personal) {
         
            interval_trade.logger("Order Close By Profit Target");
            interval_trade.CloseOrder();
         }
         if ((TimeCurrent() >= TRADE_QUEUE.curr_trade_close) && (InpTradeMgt != OpenTrailing)) {
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
      //interval_app.InitializeUIElements();
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
