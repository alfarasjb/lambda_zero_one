


#include <B63/Generic.mqh>
#include <B63/CExport.mqh>
#include <MAIN/Loader.mqh>
CExport export_hist("lambda_zero_one");
#ifdef __MQL4__
#include "trade_mt4.mqh"
#endif 

#ifdef __MQL5__
#include "trade_mt5.mqh"
#endif

#include "forex_factory.mqh"
#include "app.mqh"

CIntervalTrade interval_trade;
CNewsEvents news_events;
CIntervalApp interval_app(interval_trade, news_events, UI_X, UI_Y, UI_WIDTH, UI_HEIGHT);
CCalendarHistoryLoader calendar_loader;


int OnInit()
  {
//---
   #ifdef __MQL5__
   Trade.SetExpertMagicNumber(InpMagic);
   #endif 
   
   
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
   
   if (IsTesting()) Print("NUM: ", calendar_loader.LoadCSV(HIGH)); 
   
   
   return(INIT_SUCCEEDED);

  }
  
  
  
void OnDeinit(const int reason)
  {
//---
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
         bool backtest_events_in_window = InpTradeOnNews ? false : calendar_loader.EventInWindow(TRADE_QUEUE.curr_trade_open, TRADE_QUEUE.curr_trade_close);
         interval_trade.logger(StringFormat("Events In Entry Window: %s, Backtest Events In Window: %s", (string)EventsInEntryWindow, (string)backtest_events_in_window), __FUNCTION__, false, InpDebugLogging);
  
         if (!backtest_events_in_window && !EventsInEntryWindow) {
            
            // sends market order
            int order_send_result = interval_trade.SendOrder();
            
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
         if (TimeCurrent() >= TRADE_QUEUE.curr_trade_early_close && TimeCurrent() < TRADE_QUEUE.curr_trade_close) { 
            int num_early_close = interval_trade.CloseTradesInProfit();
            interval_trade.logger(StringFormat("%i trades close early. ", num_early_close), __FUNCTION__);
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
         if (IsTesting()) {
            // RESET
            if (calendar_loader.IsNewYear()) calendar_loader.LoadCSV(HIGH);
            
            int num_news_loaded = calendar_loader.LoadDatesToday(HIGH);
            interval_trade.logger(StringFormat("NEWS LOADED: %i", num_news_loaded), __FUNCTION__, false, InpDebugLogging);
            calendar_loader.UpdateToday();
         }
         
         TerminalStatus();
         
         LotsStatus();
         
         RefreshNews();
         
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
   ), __FUNCTION__,true, InpDebugLogging);   
}

void TerminalStatus(){
   interval_trade.logger(StringFormat(
      "Terminal Status \n\nTrading: %s \nExpert: %s \nConnection: %s",
      IsTradeAllowed() ? "Enabled" : "Disabled",
      IsExpertEnabled() ? "Enabled" : "Disabled", 
      IsConnected() ? "Connected" : "Not Connected"
      ), __FUNCTION__, true, InpDebugLogging);   
}


void RefreshNews() {
   int num_news_data = news_events.FetchData();
   interval_trade.logger(StringFormat("%i news events added. %i events today.", num_news_data, news_events.NumNewsToday()), __FUNCTION__);
   
   
}

void EventsSymbolToday(){
   interval_trade.logger(StringFormat("High Impact News Today: %s \nNum News Today: %i",
      (string)news_events.HighImpactNewsToday(), 
      news_events.GetNewsSymbolToday()
      ), __FUNCTION__, false, InpDebugLogging);
}

void EventsInWindow(){
   int events_in_window = news_events.GetHighImpactNewsInEntryWindow(TRADE_QUEUE.curr_trade_open, TRADE_QUEUE.curr_trade_close);
   interval_trade.logger(StringFormat("Entry Window: %s - %s, Num Events: %i",
      TimeToString(TRADE_QUEUE.curr_trade_open),
      TimeToString(TRADE_QUEUE.curr_trade_close),
      events_in_window), __FUNCTION__, true, InpDebugLogging);
}


void Accounts(bool notify = false){
   interval_trade.UpdateAccounts();
   
   interval_trade.logger(StringFormat("Balance: %s \nProfit: %s \nRemaining: %s \nTP Points: %s", 
      DoubleToString(interval_trade.account_balance(), 2), 
      DoubleToString(interval_trade.ACCOUNT_GAIN, 2),
      DoubleToString(interval_trade.FUNDED_REMAINING_TARGET, 2),
      DoubleToString(interval_trade.CalcTP(interval_trade.CalcCommission()), 5)), __FUNCTION__, notify, notify);
}

/*
VIEW: 

Lot calculation 
Points to target
Remaining target

*/

