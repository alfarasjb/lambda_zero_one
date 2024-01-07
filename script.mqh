


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
   interval_trade.SetRiskProfile();
   //set_deadline();
   
   interval_trade.OrdersEA();
   interval_trade.SetNextTradeWindow();
   interval_app.InitializeUIElements();
   // DRAW UI HERE
   
   
   // add provision to check for open orders, in case ea gets deactivated
   //Print("interval_trade.risk_amount: ", interval_trade.risk_amount);
//---
   return(INIT_SUCCEEDED);

  }
  
  
  
void OnDeinit(const int reason)
  {
//---
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
         if (TimeCurrent() >= TRADE_QUEUE.curr_trade_close) { interval_trade.CloseOrder(); }
         
      }
      // check order here. if order is active, increment
      interval_trade.SetNextTradeWindow();
      interval_trade.CheckOrderDeadline();
      int positions_added = interval_trade.OrdersEA();
      if (interval_trade.IsTradeWindow()){
         interval_trade.logger(StringFormat("Checked Order Pool. %i Positions Found.", positions_added));
         interval_trade.logger(StringFormat("%i Orders in Active List", interval_trade.NumActivePositions()));
      }
      
      if (interval_trade.IsNewDay()) { interval_trade.ClearOrdersToday(); }
      interval_trade.ModifyOrder();
      interval_app.InitializeUIElements();
   }
  }
//+------------------------------------------------------------------+

