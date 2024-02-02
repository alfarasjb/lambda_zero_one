


#include <B63/Generic.mqh>
#include <B63/CExport.mqh>
CExport export_hist("lambda_zero_one");
#ifdef __MQL4__
#include "trade_mt4.mqh"
#endif 

#ifdef __MQL5__
#include "trade_mt5.mqh"
#endif

#include "forex_factory.mqh"
#include "app.mqh"
#include "loader.mqh"

CIntervalTrade interval_trade;
CLoader loader;
CNewsEvents news_events;
CIntervalApp interval_app(interval_trade, news_events, UI_X, UI_Y, UI_WIDTH, UI_HEIGHT);





int OnInit()
  {
//---
   #ifdef __MQL5__
   Trade.SetExpertMagicNumber(InpMagic);
   #endif 
   
   
   if (InpMode == MODE_BACKTEST) interval_trade.logger(StringFormat("Num Dates Loaded: %i", loader.LoadFromFile()), __FUNCTION__, false, InpDebugLogging);
   interval_trade.InitializeSymbolProperties();
   interval_trade.InitHistory();
   interval_trade.SetRiskProfile();
   interval_trade.SetFundedProfile();
   interval_trade.UpdateAccounts();
   //set_deadline();
   int num_news_data = news_events.FetchData();
   interval_trade.logger(StringFormat("%i news events added. %i events today.", num_news_data, news_events.NumNewsToday()), __FUNCTION__);
   interval_trade.logger(StringFormat("High Impact News Today: %s", (string) news_events.HighImpactNewsToday()), __FUNCTION__);
   interval_trade.logger(StringFormat("Num High Impact News Today: %i", news_events.GetNewsSymbolToday()), __FUNCTION__);
   
   interval_app.RefreshClass(interval_trade, news_events);
   interval_trade.OrdersEA();
   interval_trade.SetNextTradeWindow();
   
   // DRAW UI HERE
   
   int events_in_window = news_events.GetHighImpactNewsInEntryWindow(TRADE_QUEUE.curr_trade_open, TRADE_QUEUE.curr_trade_close);
   
   
            
   interval_trade.logger(StringFormat("Events In Window: %i", news_events.NumNewsInWindow()), __FUNCTION__);
   /*
   INIT INFO: 
   Symbol Properties 
   Risk Properties
   History 
   */
   
   interval_app.InitializeUIElements();
   interval_trade.logger(StringFormat("Symbol Properties | Tick Value: %.2f, Trade Points: %s", interval_trade.tick_value, interval_trade.util_norm_price(interval_trade.trade_points)), __FUNCTION__);
   
   interval_trade.logger(StringFormat("Sizing | Lot: %.2f, VAR: %.2f, Risk Scaling: %.2f, In Drawdown: %s", 
      interval_trade.CalcLot(), 
      interval_trade.ValueAtRisk(), 
      interval_trade.RiskScaling(), 
      (string)interval_trade.AccountInDrawdown()), __FUNCTION__);
      
   interval_trade.logger(StringFormat("Datapoints: %i, In Drawdown: %s, DD Percent: %.2f, Max DD Percent: %.2f, Losing Streak: %i, Last Consecutive: %i, Max Consecutive: %i, Peak: %.2f, Current: %.2f", 
      interval_trade.PortfolioHistorySize(),
      (string)PORTFOLIO.in_drawdown, 
      PORTFOLIO.current_drawdown_percent, 
      PORTFOLIO.max_drawdown_percent,
      PORTFOLIO.is_losing_streak, 
      PORTFOLIO.last_consecutive_losses,
      PORTFOLIO.max_consecutive_losses,
      PORTFOLIO.peak_equity, 
      interval_trade.account_balance()), __FUNCTION__, false, InpDebugLogging);
//---

   interval_trade.logger(StringFormat(
      "Terminal Status \n\nTrading: %s \nExpert: %s \nConnection: %s",
      IsTradeAllowed() ? "Enabled" : "Disabled",
      IsExpertEnabled() ? "Enabled" : "Disabled", 
      IsConnected() ? "Connected" : "Not Connected"
   ), __FUNCTION__, true, true);
   
   interval_trade.logger(StringFormat("Entry Window: %s - %s \nNum Events: %i",
            TimeToString(TRADE_QUEUE.curr_trade_open),
            TimeToString(TRADE_QUEUE.curr_trade_close),
            events_in_window), __FUNCTION__, true, true);
   
   Accounts(true);
   
   interval_trade.LastEntry();
   
   
   interval_trade.BrokerCommission();
   Print("COMM: ", interval_trade.CalcCommission());
   return(INIT_SUCCEEDED);

  }
  
  
  
void OnDeinit(const int reason)
  {
//---
   //PrintFormat("REASON: %i", reason);
   interval_trade.logger(StringFormat("Num Dates Processed: %i", loader.NUM_LOADED_HISTORY), __FUNCTION__, false, InpDebugLogging);
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
      interval_trade.account_balance()), __FUNCTION__, false, InpDebugLogging);
      
   interval_trade.ClearHistory();
  if (IsTesting()) export_hist.ExportAccountHistory();
  }
  
  
void OnTick()
  {
   if (IsNewCandle() && interval_trade.CorrectPeriod() && interval_trade.MinimumEquity()){
      
      
      bool ValidTradeOpen = interval_trade.ValidTradeOpen();
      
      //interval_trade.logger(StringFormat("Valid Trade Open: %s", (string)ValidTradeOpen), __FUNCTION__, false, true);
      
      if (ValidTradeOpen){
            
         bool EventsInEntryWindow = news_events.HighImpactNewsInEntryWindow(); 
         bool IsNewsDate = loader.IsNewsDate();
         
         interval_trade.logger(StringFormat("High Impact News in Entry Window: %s, Is News Date: %s", (string)EventsInEntryWindow, (string)IsNewsDate), __FUNCTION__);
         
         if (!IsNewsDate && !EventsInEntryWindow){
            
            // sends market order
            int order_send_result = interval_trade.SendMarketOrder();
            
            if (order_send_result < 0) interval_trade.logger(StringFormat("Order Send Failed. Configuration: %s, Reason: %s, Code: %i", 
               EnumToString(InpSpreadMgt), 
               EnumToString((EnumOrderSendError)order_send_result), 
               order_send_result), __FUNCTION__);       
   
         }
      }
      else{
         if (interval_trade.EquityReachedProfitTarget() && InpAccountType != Personal) {
        
            interval_trade.CloseOrder();
         }
         if ((TimeCurrent() >= TRADE_QUEUE.curr_trade_close) && (InpTradeMgt != OpenTrailing)) {
            interval_trade.CloseOrder();      
         }
      }
      // check order here. if order is active, increment
      interval_trade.SetNextTradeWindow();
      interval_trade.CheckOrderDeadline();
      int positions_added = interval_trade.OrdersEA();
      if (interval_trade.IsTradeWindow()){
         interval_trade.logger(StringFormat("Checked Order Pool. %i Positions Found.", positions_added), __FUNCTION__);
         interval_trade.logger(StringFormat("%i Orders in Active List", interval_trade.NumActivePositions()), __FUNCTION__);
      }
      if (interval_trade.IsNewDay()) { 
         interval_trade.ClearOrdersToday();
         //EventsInWindow();
         
      }
      if (interval_trade.PreEntry()){
         
         TerminalStatus();
         
         LotsStatus();
         
         EventsSymbolToday();
            
         EventsInWindow();
         
         Accounts(true);
      }
         
      interval_trade.ModifyOrder();
      //interval_app.InitializeUIElements();
      
      // UPDATE ACCOUNTS HERE 
      interval_trade.UpdateAccounts();
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


// ======== MISC LOGS ======== // 

void LotsStatus(){
   interval_trade.logger(StringFormat("Pre-Entry \n\nRisk: %.2f \nLot: %.2f \nMax Lot: %.2f",
      interval_trade.TRUE_RISK(),
      interval_trade.CalcLot(),
      InpMaxLot
   ), __FUNCTION__,true, true);   
}

void TerminalStatus(){
   interval_trade.logger(StringFormat(
      "Terminal Status \n\nTrading: %s \nExpert: %s \nConnection: %s",
      IsTradeAllowed() ? "Enabled" : "Disabled",
      IsExpertEnabled() ? "Enabled" : "Disabled", 
      IsConnected() ? "Connected" : "Not Connected"
      ), __FUNCTION__, true, true);   
}

void EventsSymbolToday(){
   interval_trade.logger(StringFormat("High Impact News Today: %s \nNum News Today: %i",
      (string)news_events.HighImpactNewsToday(), 
      news_events.GetNewsSymbolToday()
      ), __FUNCTION__, false, true);
}

void EventsInWindow(){
   int events_in_window = news_events.GetHighImpactNewsInEntryWindow(TRADE_QUEUE.curr_trade_open, TRADE_QUEUE.curr_trade_close);
   interval_trade.logger(StringFormat("Entry Window: %s - %s, Num Events: %i",
      TimeToString(TRADE_QUEUE.curr_trade_open),
      TimeToString(TRADE_QUEUE.curr_trade_close),
      events_in_window), __FUNCTION__, true, true);
}


void Accounts(bool notify = false){
   interval_trade.UpdateAccounts();
   
   interval_trade.logger(StringFormat("Balance: %s \nProfit: %s \nRemaining: %s", 
      DoubleToString(interval_trade.account_balance(), 2), 
      DoubleToString(interval_trade.ACCOUNT_GAIN, 2),
      DoubleToString(interval_trade.FUNDED_REMAINING_TARGET, 2)), __FUNCTION__, notify, notify);
}

/*
VIEW: 

Lot calculation 
Points to target
Remaining target

*/
