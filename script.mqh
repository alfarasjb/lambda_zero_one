


#include <B63/Generic.mqh>

#include "trade_mt4.mqh"


CIntervalTrade interval_trade;




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
   create_comments();
   // add provision to check for open orders, in case ea gets deactivated
   //Print("interval_trade.risk_amount: ", interval_trade.risk_amount);
//---
   return(INIT_SUCCEEDED);

  }
  
  
  
void OnDeinit(const int reason)
  {
//---
   
  }
  
  
void OnTick()
  {
   if (IsNewCandle() && interval_trade.CorrectPeriod()){
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
      create_comments();
   }
  }
//+------------------------------------------------------------------+

void create_comments(){
   double true_lot = interval_trade.CalcLot();
   double true_risk = InpRiskAmount * InpAllocation;
   int ea_positions = ArraySize(TRADES_ACTIVE.active_positions);
   Comment(
      "Symbol Tick Value: ", interval_trade.TICK_VALUE(), "\n",
      "Symbol Trade Points: ", interval_trade.TRADE_POINTS(), "\n",
      "Risk Profile Lot: ", RISK_PROFILE.RP_lot, "\n",
      "Risk Profile Risk: ", RISK_PROFILE.RP_amount, "\n",
      "Risk Profile Hold Time: ", RISK_PROFILE.RP_holdtime, "\n",
      "Risk Profile Order Type: ", RISK_PROFILE.RP_order_type, "\n",
      "Risk Profile Timeframe: ", RISK_PROFILE.RP_timeframe, "\n",
      "True Lot: ", true_lot, "\n",
      "True Risk: ", interval_trade.TRUE_RISK(), "\n",
      "Allocation: ", InpAllocation, "\n",
      "EA Positions: ", interval_trade.NumActivePositions(), "\n",
      "Entry Hour: ", InpEntryHour, "\n",
      "Entry Minute: ", InpEntryMin, "\n",
      "Magic: ", InpMagic, "\n",
      "Last Recorded Time: ", TimeCurrent(), "\n",
      "Current Trade Entry: ", TRADE_QUEUE.curr_trade_open, "\n",
      "Current Trade Close: ", TRADE_QUEUE.curr_trade_close, "\n",
      "Next Trade Entry: ", TRADE_QUEUE.next_trade_open, "\n",
      "Next Trade Close: ", TRADE_QUEUE.next_trade_close, "\n",
      "Active Position Entry Time: ", TRADES_ACTIVE.trade_open_datetime, "\n",
      "Active Position Close Time: ", TRADES_ACTIVE.trade_close_datetime, "\n"
   );
}

